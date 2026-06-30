# Innitial — convenções do projeto

App iOS SwiftUI modular (TMDB), composto por Swift packages locais em `Models/`
(`AppConfiguration`, `Database`, `Services`, `DesignSystem`, `Features`, …) com DI no
estilo **struct of closures** + **swift-dependencies** (Point-Free): cada service é um
`DependencyKey` com `liveValue` próprio; view models resolvem via `@Dependency`, sem
threading nem container.

## Padrão de teste de serviço

Ao testar um service, cubra **cada request/método** com **um teste de sucesso e um de
falha — um `@Test` separado para cada** (não junte os métodos num único loop). No teste
de **sucesso**, verifique que a resposta **decodou por completo** (todos os campos, não
só alguns).

- Dirija o `.live` com um `NetworkService` mockado (`data`/`status` canned); falha =
  status não-2xx (ex.: 500) → espere `throw`.
- Fatore as asserções de decode num helper que repassa
  `sourceLocation: SourceLocation = #_sourceLocation`, pra a falha apontar pro teste.
- **Fixtures JSON não ficam inline**: coloque numa pasta `Mocks/` do test target, como
  `Data` (ex.: `let popularPageMock = Data("""…""".utf8)`), igual a
  `Models/Services/Tests/NetworkLayerTests/Mocks/DummyMock.swift`.
- Referência: `Models/Services/Tests/MovieListServiceTests/` (+ `Mocks/MovieListMocks.swift`).

## Rodar os testes (Swift Testing) headless

A máquina tem **só CommandLineTools** (sem Xcode.app). `swift test` puro falha com
`no such module 'Testing'`. O framework existe no CommandLineTools — aponte compilador,
linker e runtime pra ele:

```sh
FW=/Library/Developer/CommandLineTools/Library/Developer/Frameworks
LIB=/Library/Developer/CommandLineTools/Library/Developer/usr/lib
DYLD_LIBRARY_PATH="$LIB" DYLD_FRAMEWORK_PATH="$FW" swift test \
  -Xswiftc -F -Xswiftc "$FW" -Xlinker -F -Xlinker "$FW" \
  -Xlinker -rpath -Xlinker "$FW" -Xlinker -rpath -Xlinker "$LIB"
```

Rode de dentro do diretório do package (ex.: `Models/Services`); `--filter <Suite>` pra
escopar. Os macros `#Preview` do SwiftUI ainda falham headless (plugin `PreviewsMacros`
ausente), então para targets com previews use `swift build` ou desabilite os previews.
```
