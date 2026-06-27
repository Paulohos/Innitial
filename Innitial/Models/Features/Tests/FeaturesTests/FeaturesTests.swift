import Testing
import LocalStoreService
@testable import Login

@MainActor
@Suite struct LoginViewModelTests {

    @Test func prefillsLastUsedEmail() throws {
        let store = LocalStoreService.inMemory()
        try store.save("paulo@mail.com", for: \.lastUsedLoginEmail)

        let viewModel = LoginViewModel(store: store)
        #expect(viewModel.email == "paulo@mail.com")
    }

    @Test func loginPersistsEmailAndToken() async throws {
        let store = LocalStoreService.inMemory()
        let viewModel = LoginViewModel(store: store)
        viewModel.email = "new@mail.com"

        await viewModel.login()

        #expect(viewModel.isLoggedIn)
        // email salvo (UserDefaults) e token salvo (Keychain), via as keys tipadas
        #expect(try store.load(\.lastUsedLoginEmail) == "new@mail.com")
        #expect(try store.load(\.authToken) == "token-for-new@mail.com")
    }

    @Test func onboardingDefaultsToFalse() throws {
        let store = LocalStoreService.inMemory()
        let viewModel = LoginViewModel(store: store)
        #expect(viewModel.hasSeenOnboarding == false)

        try store.save(true, for: \.hasSeenOnboarding)
        #expect(viewModel.hasSeenOnboarding == true)
    }
}
