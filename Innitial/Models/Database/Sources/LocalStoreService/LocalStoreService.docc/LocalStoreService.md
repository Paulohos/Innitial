# ``LocalStoreService``

Guarde dados do seu app no lugar certo — UserDefaults, Keychain ou arquivos —
com **uma API só**, tipada e testável.

## Overview

`LocalStoreService` é uma camadinha de persistência local. A ideia é simples:
em vez de você lembrar "isso aqui vai no UserDefaults, aquilo no Keychain, e o
JSON da API vai num arquivo", você declara **uma chave** dizendo onde a coisa
mora, e o serviço cuida do resto.

Pensa nele como um **porteiro de prédio**: você entrega um pacote (o valor) e diz
o número do apartamento (a chave). O porteiro sabe se aquele apartamento fica na
torre A (UserDefaults), na torre B (Keychain, o cofre) ou no depósito (arquivos no
disco). Você não precisa saber o caminho — só o número.

### O modelo mental (1 fachada, 3 backends)

```
                         ┌─────────────────────┐
   seu código  ───────►  │  LocalStoreService  │   ◄── é isso que você usa
                         │     (a fachada)     │
                         └──────────┬──────────┘
                                    │ roteia pela chave
                ┌───────────────────┼───────────────────┐
                ▼                   ▼                   ▼
        ┌──────────────┐   ┌──────────────┐   ┌──────────────┐
        │ UserDefaults │   │   Keychain   │   │  FileSystem  │
        │ preferências │   │   segredos   │   │  JSON/cache  │
        └──────────────┘   └──────────────┘   └──────────────┘
```

Cada caixa dessas é um ``KeyValueStore`` (o "motor" de baixo nível). Você
raramente mexe nele direto — fala com a fachada ``LocalStoreService``.

### Quando usar cada backend

| Backend | Use para | Exemplos | Sensível? |
|---|---|---|---|
| `.userDefaults` | preferências pequenas | último e-mail, flag de onboarding | não |
| `.keychain` | segredos | token de auth, senha, refresh token | **sim** |
| `.fileSystem` | blobs grandes / cache offline | JSON de resposta da API | não |

Regra de bolso: **token e senha → Keychain**. **Preferência simples → UserDefaults**.
**Resposta de API pra modo offline → FileSystem**.

## Começando em 3 passos

### Passo 1 — Crie o serviço (uma vez, na raiz do app)

```swift
import LocalStoreService

// Produção: usa UserDefaults real, Keychain real e arquivos em Caches/
let store = LocalStoreService.live(keychainService: "com.suaempresa.SeuApp")

// Testes / previews: tudo em memória, não toca em disco nenhum
let store = LocalStoreService.inMemory()
```

> Importante: crie **uma instância só** e passe ela adiante (injeção de dependência).
> Não saia criando `LocalStoreService.live(...)` em todo lugar.

### Passo 2 — Declare suas chaves

As chaves vivem no próprio módulo, estendendo ``StorageKeys``. Cada chave carrega
**o nome**, **o tipo do valor** e **o backend**. (Esse arquivo já existe:
`StorageKeys+Keys.swift`.)

```swift
public extension StorageKeys {
    var lastUsedLoginEmail: StorageKey<String> { .init("lastUsedLoginEmail", in: .userDefaults) }
    var authToken: StorageKey<String>          { .init("authToken", in: .keychain) }
    var hasSeenOnboarding: StorageKey<Bool>    { .init("hasSeenOnboarding", in: .userDefaults) }
}
```

Decifrando `StorageKey<String>("authToken", in: .keychain)`:
- `<String>` → o tipo do valor que essa chave guarda.
- `"authToken"` → o nome interno (a "etiqueta" no armazenamento).
- `in: .keychain` → onde mora.

### Passo 3 — Salve, leia e remova

Você acessa a chave por **key path** (o `\.` na frente). O compilador não deixa
você errar o tipo nem o backend.

```swift
// salvar
try store.save("paulo@email.com", for: \.lastUsedLoginEmail)
try store.save(true, for: \.hasSeenOnboarding)

// ler (retorna opcional — nil se nunca foi salvo)
let email: String? = try store.load(\.lastUsedLoginEmail)

// remover
try store.remove(\.lastUsedLoginEmail)
```

Pronto. Isso é 90% do uso no dia a dia.

## Guia detalhado

### Lendo valores: três sabores

Existem três formas de ler, dependendo do que "não existe" significa **naquele contexto**:

| Método | Devolve | Quando faltar |
|---|---|---|
| ``LocalStoreService/load(_:)`` | `Value?` | retorna `nil` (ausência é normal) |
| ``LocalStoreService/require(_:)`` | `Value` | lança ``LocalStoreError/valueNotFound(key:)`` |
| ``LocalStoreService/load(_:orThrow:)`` | `Value` | lança **o erro que você passar** |

**1) `load` — ausência é normal.** É o caso de conveniências (último e-mail, flag de
onboarding): não ter ainda é esperado, não é erro.

```swift
guard let email = try? store.load(\.lastUsedLoginEmail) else {
    // nunca foi salvo (ou deu erro) → trate o "vazio"
    return
}
// aqui 'email' é String (não-opcional) 👍
```

Por que `email` sai como `String` e não `String??`? Porque o `try?` do Swift
**achata** o opcional: `load` já devolve `String?`, e o `try?` não empilha outro
nível. Então `guard let` te dá o `String` direto.

**2) `require` — tem que existir.** Para chaves que, naquele contexto, são
obrigatórias (ex.: o token numa request autenticada). Você recebe um valor
**não-opcional**; se faltar, ele **lança**:

```swift
do {
    let token = try store.require(\.authToken)   // String (não-opcional)
    // ...
} catch {
    // caiu aqui = token não estava salvo (LocalStoreError.valueNotFound)
}
```

**3) `load(_:orThrow:)` — você escolhe o erro.** Igual ao `require`, mas em vez do
erro genérico do módulo, lança um erro **seu** (do seu domínio):

```swift
let token = try store.load(\.authToken, orThrow: NetworkServiceError.noAuthTokenInStorage)
```

> Regra de bolso: **ausência é normal → `load`**. **Ausência é erro → `require`**
> (ou `load(_:orThrow:)` quando você quer mapear pro seu próprio tipo de erro).

### Tipos suportados

Qualquer coisa `Codable` funciona — porque por baixo tudo vira `Data` via JSON:

```swift
// primitivos
try store.save(42, for: \.someInt)
try store.save(true, for: \.someBool)

// objeto customizado
struct Profile: Codable { let id: Int; let name: String }
// declare a chave:  var profile: StorageKey<Profile> { .init("profile", in: .userDefaults) }
try store.save(Profile(id: 1, name: "Paulo"), for: \.profile)
let p = try store.load(\.profile)   // Profile?
```

`Int`, `String`, `Bool`, `Date`, arrays, structs... todos são `Codable`, então a
mesma API atende todos.

### Cache de respostas offline (arquivos + validade)

Aqui é o pulo do gato pro **modo offline**. Resposta de API não vai pro
UserDefaults (ele é pra coisinhas pequenas) — vai pra **arquivo no disco**, e a
**chave é a URL** que você bateu.

```swift
let url = URL(string: "https://api.exemplo.com/movies?page=1")!

// 1) quando a request der certo, cacheie os bytes crus do servidor:
try store.cacheResponse(jsonData, for: url)

// 2) mais tarde (talvez offline), leia de volta — com prazo de validade (TTL):
//    'maxAge' em segundos. Se a resposta tiver mais de 1h, vira nil.
if let bytes = try store.cachedResponseData(for: url, maxAge: 3600) {
    // usa o JSON do cache
}

// 3) ou já decodifica direto no seu modelo:
let page = try store.cachedResponse(MoviesPage.self, for: url, maxAge: 3600)

// 4) apagar manualmente (ex.: no logout):
try store.removeCachedResponse(for: url)
```

Como funciona por dentro:
- Os bytes são embrulhados num envelope `{ data, storedAt }` e gravados num arquivo
  (o nome do arquivo é o hash SHA-256 da URL, pra virar um nome válido).
- Na leitura, se `agora - storedAt > maxAge`, a entrada está **vencida**: o serviço
  devolve `nil` **e apaga** o arquivo velho.
- O parâmetro `now:` existe pra você **testar a validade** sem esperar o tempo real
  passar (veja a seção de Testes).

> O diretório é `Caches/ResponsesCache`. O iOS pode limpar a pasta `Caches` quando
> falta espaço — então trate o cache como "pode não estar lá" (é o que o `nil` já
> te força a fazer).

### Padrão típico no NetworkLayer: cache-then-network

```swift
func fetchMovies(page: Int) async throws -> MoviesPage {
    let url = moviesURL(page: page)
    do {
        let (data, _) = try await URLSession.shared.data(from: url)
        try? store.cacheResponse(data, for: url)        // atualiza o cache
        return try JSONDecoder().decode(MoviesPage.self, from: data)
    } catch {
        // sem rede? tenta o cache (válido por, digamos, 1 dia)
        if let cached = try store.cachedResponse(MoviesPage.self, for: url, maxAge: 86_400) {
            return cached
        }
        throw error
    }
}
```

### Logout e reset (limpeza em massa)

Dois métodos, com escopos bem diferentes:

```swift
// LOGOUT — cirúrgico. Remove o token (Keychain) e todo o cache de respostas.
// Mantém conveniências como o último e-mail e a flag de onboarding.
try store.clearSession()

// RESET DE FÁBRICA — arrasa tudo: UserDefaults, Keychain e arquivos.
try store.removeAll()
```

⚠️ **Cuidado com o `removeAll()`**: a parte do UserDefaults usa
`removePersistentDomain`, que limpa o **domínio inteiro do app** — não só as chaves
que você gravou por aqui, mas qualquer coisa no UserDefaults do app (inclusive de
SDKs de terceiros). Por isso ele é pra **reset/teste**, não pra logout. Para logout,
use ``clearSession()``, que é cirúrgico.

| Método | UserDefaults | Keychain | Arquivos (cache) | Quando usar |
|---|---|---|---|---|
| ``clearSession()`` | mantém | só remove `authToken` | apaga tudo | logout |
| ``removeAll()`` | **apaga o domínio todo** | apaga o service todo | apaga tudo | reset de fábrica / testes |

## Como o app injeta tudo isso

A `LocalStoreService` não é criada dentro da tela — ela é montada na raiz do app e
**injetada** para baixo. No projeto isso vive no container `AppDependencies`:

```swift
// AppDependencies (montado uma vez)
let dependencies = AppDependencies.live()   // tem .configuration, .localStore, etc.

// a tela recebe só o que precisa:
let viewModel = LoginViewModel(store: dependencies.localStore)
```

Vantagem: a `LoginViewModel` depende de `LocalStoreService` (uma abstração), não de
UserDefaults/Keychain direto. Nos testes você troca por `.inMemory()` e pronto.

## Testes

Use sempre ``LocalStoreService/inMemory()`` — é rápido, determinístico e não suja o
UserDefaults/Keychain reais da máquina.

```swift
@Test func salvaEbusca() throws {
    let store = LocalStoreService.inMemory()
    try store.save("a@b.com", for: \.lastUsedLoginEmail)
    #expect(try store.load(\.lastUsedLoginEmail) == "a@b.com")
}

@Test func cacheVence() throws {
    let store = LocalStoreService.inMemory()
    let url = URL(string: "https://x.com/a")!
    let t0 = Date(timeIntervalSince1970: 0)

    try store.cacheResponse(Data("oi".utf8), for: url, now: t0)
    // 2h depois, com validade de 1h → vencido
    let bytes = try store.cachedResponseData(for: url, maxAge: 3600, now: t0.addingTimeInterval(7200))
    #expect(bytes == nil)
}
```

Repare como injetar `now:` deixa o teste de validade **instantâneo e confiável** —
nada de `sleep`.

## Tratamento de erros

A API é `throws` porque o **Keychain pode falhar de verdade** (retorna um `OSStatus`
do sistema). Esses erros chegam como ``KeychainError``:

```swift
do {
    try store.save(token, for: \.authToken)
} catch let error as KeychainError {
    // ex.: .unexpectedStatus(-34018) — entitlement faltando
    print("Keychain falhou: \(error)")
}
```

UserDefaults não lança; o FileSystem lança erros de I/O do Foundation. Na maioria
dos casos um `try?` resolve, mas o `throws` está aí quando você quiser tratar.

Além disso, ``require(_:)`` lança ``LocalStoreError/valueNotFound(key:)`` quando uma
chave obrigatória está vazia (veja "Lendo valores: três sabores").

## Perguntas frequentes (e pegadinhas)

**"Posso usar a mesma chave em backends diferentes?"**
Pode — `"token"` no Keychain e `"token"` no UserDefaults são coisas separadas, não
colidem. O backend faz parte da identidade da chave.

**"O Keychain não funciona no meu teste / no Mac via linha de comando."**
Normal. Keychain real precisa de entitlements e roda bem no **simulador/device**.
Em testes de lógica, use `.inMemory()`.

**"Meu cache offline sumiu."**
A pasta `Caches` pode ser esvaziada pelo iOS sob pressão de espaço. Por isso a
leitura sempre pode devolver `nil` — seu código já lida com isso.

**"Salvei um Int e quando abro o UserDefaults no Xcode aparece um blob, não o número."**
Esperado: tudo é serializado para `Data` (JSON) por uniformidade. O valor está lá,
só não em formato "nativo" do plist.

**"Onde declaro chave nova?"**
Em `StorageKeys+Keys.swift`, dentro de `extension StorageKeys`. Uma linha por chave.

## Topics

### Tipo principal
- ``LocalStoreService``

### Chaves
- ``StorageKey``
- ``StorageKeys``
- ``StorageBackend``

### Motor de baixo nível
- ``KeyValueStore``

### Erros
- ``KeychainError``
- ``LocalStoreError``
