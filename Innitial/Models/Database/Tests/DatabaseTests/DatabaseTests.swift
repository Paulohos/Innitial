import Testing
import Foundation
@testable import LocalStoreService

private struct User: Codable, Equatable {
    let id: Int
    let name: String
}

@Suite struct KeyValueStoreTests {

    // MARK: In-memory backend (primary, deterministic)

    @Test func stringRoundTrip() throws {
        let store = KeyValueStore.inMemory()
        try store.set("hello", forKey: "greeting")
        #expect(try store.value(String.self, forKey: "greeting") == "hello")
    }

    @Test func intRoundTrip() throws {
        let store = KeyValueStore.inMemory()
        try store.set(42, forKey: "answer")
        #expect(try store.value(Int.self, forKey: "answer") == 42)
    }

    @Test func customObjectRoundTrip() throws {
        let store = KeyValueStore.inMemory()
        let user = User(id: 1, name: "Paulo")
        try store.set(user, forKey: "user")
        #expect(try store.value(User.self, forKey: "user") == user)
    }

    @Test func missingKeyReturnsNil() throws {
        let store = KeyValueStore.inMemory()
        #expect(try store.value(String.self, forKey: "absent") == nil)
    }

    @Test func removeAllClearsStore() throws {
        let store = KeyValueStore.inMemory()
        try store.set("a", forKey: "k1")
        try store.set("b", forKey: "k2")
        try store.removeAll()
        #expect(try store.value(String.self, forKey: "k1") == nil)
        #expect(try store.value(String.self, forKey: "k2") == nil)
    }

    // MARK: UserDefaults backend (smoke test on an isolated suite)

    @Test func userDefaultsRoundTrip() throws {
        let suiteName = "KeyValueStoreTests"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)

        let store = KeyValueStore.userDefaults(defaults, domainName: suiteName)
        defer { try? store.removeAll() }

        try store.set(User(id: 7, name: "Souza"), forKey: "user")
        #expect(try store.value(User.self, forKey: "user") == User(id: 7, name: "Souza"))
    }

    // MARK: File-system backend (real files in a temporary directory)

    @Test func fileSystemRoundTrip() throws {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("KeyValueStoreTests-\(UUID().uuidString)", isDirectory: true)
        let store = KeyValueStore.fileSystem(directory: dir)
        defer { try? store.removeAll() }

        // arbitrary key with slashes/colons (like a URL) must be a valid key
        let key = "https://api.example.com/movies?page=1"
        let payload = Data("[{\"id\":1}]".utf8)

        #expect(try store.loadData(key) == nil)
        try store.saveData(payload, key)
        #expect(try store.loadData(key) == payload)

        try store.removeValue(key)
        #expect(try store.loadData(key) == nil)
    }
}

// Keys declared via extension, exactly like the module's real keys.
extension StorageKeys {
    fileprivate var testEmail: StorageKey<String> { .init("testEmail", in: .userDefaults) }
    fileprivate var testToken: StorageKey<String> { .init("testToken", in: .keychain) }
}

@Suite struct LocalStoreServiceTests {

    @Test func typedKeyRoundTrips() throws {
        let store = LocalStoreService.inMemory()
        try store.save("a@b.com", for: \.testEmail)
        try store.save("secret-token", for: \.testToken)

        #expect(try store.load(\.testEmail) == "a@b.com")
        #expect(try store.load(\.testToken) == "secret-token")
    }

    @Test func backendsAreIsolated() throws {
        let store = LocalStoreService.inMemory()
        try store.save("from-defaults", for: \.testEmail)   // userDefaults
        try store.save("from-keychain", for: \.testToken)   // keychain
        #expect(try store.load(\.testEmail) == "from-defaults")
        #expect(try store.load(\.testToken) == "from-keychain")
    }

    @Test func removeAllWipesEveryBackend() throws {
        let store = LocalStoreService.inMemory()
        let url = URL(string: "https://api.example.com/x")!

        try store.save("a@b.com", for: \.lastUsedLoginEmail)  // userDefaults
        try store.save("token", for: \.authToken)             // keychain
        try store.cacheResponse(Data("body".utf8), for: url)  // fileSystem

        try store.removeAll()

        #expect(try store.load(\.lastUsedLoginEmail) == nil)
        #expect(try store.load(\.authToken) == nil)
        #expect(try store.cachedResponseData(for: url, maxAge: .infinity) == nil)
    }

    @Test func clearSessionKeepsConvenienceData() throws {
        let store = LocalStoreService.inMemory()
        let url = URL(string: "https://api.example.com/x")!

        try store.save("a@b.com", for: \.lastUsedLoginEmail)
        try store.save("token", for: \.authToken)
        try store.cacheResponse(Data("body".utf8), for: url)

        try store.clearSession()

        // sessão limpa: token e cache somem
        #expect(try store.load(\.authToken) == nil)
        #expect(try store.cachedResponseData(for: url, maxAge: .infinity) == nil)
        // conveniência preservada:
        #expect(try store.load(\.lastUsedLoginEmail) == "a@b.com")
    }
}

@Suite struct ResponseCacheTests {
    private let url = URL(string: "https://api.example.com/movies?page=1")!
    private let body = Data("{\"results\":[{\"id\":1,\"title\":\"Dune\"}]}".utf8)

    @Test func freshHitReturnsBytes() throws {
        let store = LocalStoreService.inMemory()
        let t0 = Date(timeIntervalSince1970: 1_000)

        try store.cacheResponse(body, for: url, now: t0)
        // 30s later, within a 60s maxAge → hit
        let read = try store.cachedResponseData(for: url, maxAge: 60, now: t0.addingTimeInterval(30))
        #expect(read == body)
    }

    @Test func staleEntryReturnsNilAndIsDeleted() throws {
        let store = LocalStoreService.inMemory()
        let t0 = Date(timeIntervalSince1970: 1_000)

        try store.cacheResponse(body, for: url, now: t0)
        // 90s later, past a 60s maxAge → stale
        let stale = try store.cachedResponseData(for: url, maxAge: 60, now: t0.addingTimeInterval(90))
        #expect(stale == nil)
        // and it was dropped: even a fresh read finds nothing
        #expect(try store.cachedResponseData(for: url, maxAge: 60, now: t0.addingTimeInterval(91)) == nil)
    }

    @Test func typedDecodeOnRead() throws {
        struct Movie: Codable, Equatable { let id: Int; let title: String }
        struct Page: Codable, Equatable { let results: [Movie] }

        let store = LocalStoreService.inMemory()
        let t0 = Date(timeIntervalSince1970: 1_000)

        try store.cacheResponse(body, for: url, now: t0)
        let page = try store.cachedResponse(Page.self, for: url, maxAge: 60, now: t0)
        #expect(page == Page(results: [Movie(id: 1, title: "Dune")]))
    }

    @Test func missingReturnsNil() throws {
        let store = LocalStoreService.inMemory()
        #expect(try store.cachedResponseData(for: url, maxAge: 60) == nil)
    }
}
