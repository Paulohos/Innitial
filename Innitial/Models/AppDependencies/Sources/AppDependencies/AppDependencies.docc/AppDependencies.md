# ``AppDependencies``

O **container de dependências** do app: monta uma instância de cada serviço, uma
vez só, e entrega para os módulos.

## Overview

Todo app tem serviços compartilhados: configuração, storage local, rede,
analytics... A pergunta é: **quem cria essas coisas e como elas chegam nas telas?**

A resposta ruim é cada tela criar o seu (`LocalStoreService.live(...)` espalhado por
todo lugar) — vira bagunça, e nos testes você não consegue trocar por um mock.

A resposta boa é o **composition root**: um único lugar, na raiz do app, que monta
tudo e injeta para baixo. Esse lugar é o ``AppDependencies``.

Pensa nele como a **caixa de ferramentas do app**: você monta a caixa uma vez (com
as ferramentas de verdade), e passa a caixa para quem precisa. Nos testes, monta uma
caixa com ferramentas de mentira.

### O que tem dentro

```swift
public struct AppDependencies: Sendable {
    public var configuration: EnvironmentConfigurationService  // baseURL, bundleID, URLs...
    public var localStore: LocalStoreService                   // UserDefaults + Keychain + cache
    public var network: NetworkService                         // chamadas de API
    // analytics, etc. entram aqui depois
}
```

É um `struct` `Sendable` — leve, copiável, seguro para concorrência. Só guarda as
instâncias prontas; não tem lógica de negócio.

## As duas formas de montar

### `live()` — produção

Lê o Info.plist de verdade, usa UserDefaults/Keychain reais, e fia a rede com config
+ store. Repare que tudo é construído a partir das **mesmas instâncias** (a config e o
store são criados uma vez e reaproveitados):

```swift
public static func live() -> Self {
    let configuration = EnvironmentConfigurationService.live(bundle: .main)
    let localStore = LocalStoreService.live(keychainService: configuration.bundleID())
    return .init(
        configuration: configuration,
        localStore: localStore,
        network: NetworkService(appConfiguration: configuration, localStorageService: localStore)
    )
}
```

### `mock()` — testes e previews

Config de mentira + storage em memória. Não toca em disco, Keychain ou rede reais:

```swift
let dependencies = AppDependencies.mock()
```

Use `.mock()` em `#Preview` e nos testes; `.live()` só na raiz do app.

## Como o app usa (composition root)

A raiz cria o container **uma vez** (`let`, instância única) e injeta:

```swift
import SwiftUI
import AppDependencies

@main
struct InnitialApp: App {
    private let dependencies = AppDependencies.live()   // ← criado UMA vez

    var body: some Scene {
        WindowGroup {
            ContentView(dependencies: dependencies)
        }
    }
}
```

E a tela pega só o **pedaço** que precisa — não o container inteiro:

```swift
struct ContentView: View {
    @State private var loginViewModel: LoginViewModel

    init(dependencies: AppDependencies) {
        // a ViewModel recebe só o store, não o container todo
        _loginViewModel = State(initialValue: LoginViewModel(store: dependencies.localStore))
    }

    var body: some View { LoginView(viewModel: loginViewModel) }
}
```

> **Princípio**: o container é montado em cima e desce. Cada feature depende só do que
> usa (`LocalStoreService`, `NetworkService`...), nunca do `AppDependencies` inteiro.
> Isso mantém as features desacopladas e testáveis.

### Injeção via Environment (alternativa)

Também dá para injetar pelo SwiftUI Environment (definido em
`AppDependencies+Environment.swift`):

```swift
ContentView()
    .environment(\.dependencies, dependencies)   // na raiz

// em qualquer view filha:
@Environment(\.dependencies) private var dependencies
```

O valor padrão do Environment é `.mock()`, então previews funcionam sem configurar nada.

## Adicionando um serviço novo (passo a passo)

Digamos que você criou um `AnalyticsService`. Para colocá-lo no container:

1. **Importe** o módulo no topo de `AppDependencies.swift`:
   ```swift
   import AnalyticsKit
   ```
2. **Adicione a propriedade** no struct:
   ```swift
   public var analytics: AnalyticsService
   ```
3. **Adicione no `init`** (parâmetro + atribuição).
4. **Construa em `live()` e `mock()`**:
   ```swift
   analytics: AnalyticsService.live()   // e .mock() no mock()
   ```
5. **Declare a dependência** no `Package.swift` (pacote + produto no target `AppDependencies`).

Pronto — todo mundo que recebe o container passa a ter `dependencies.analytics`.

## A regra de ouro das dependências (evita ciclo)

```
AppConfiguration ─┐
Database ─────────┤→ Services/NetworkLayer ─┐
                  │                          ├─→ AppDependencies ─→ App
AppConfiguration, Database ──────────────────┘   (monta tudo)
```

O ``AppDependencies`` fica **no topo** e conhece todos os serviços. Os serviços (rede,
storage, config) ficam **embaixo** e **nunca importam o container**.

⚠️ Se um serviço de baixo (ex.: `NetworkLayer`) importar `AppDependencies`, vira um
**ciclo** assim que o container precisar montar aquele serviço — e o SwiftPM quebra o
build. Regra: serviço importa serviço; só o container importa todo mundo.

## Por que `Sendable`?

O container é passado entre a raiz, o Environment e (potencialmente) contextos
assíncronos. Ser `Sendable` garante que isso é seguro. Por isso cada serviço guardado
também precisa ser `Sendable` — é o caso de `EnvironmentConfigurationService` (struct),
`LocalStoreService` (struct) e `NetworkService` (`final class` com só `let`s `Sendable`).

## Testes

```swift
@Test func usaMockContainer() {
    let deps = AppDependencies.mock()
    let viewModel = LoginViewModel(store: deps.localStore)   // store em memória
    // ... exercita a tela sem tocar em disco/rede reais
}
```

## Topics

### Tipo principal
- ``AppDependencies``
