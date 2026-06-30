import Foundation
import Testing
import Connectivity
import DesignSystem
import Dependencies
@testable import Home

@MainActor
@Suite struct ConnectivityViewModelTests {

    /// Builds the SUT with the connectivity dependency driven by a finite stream
    /// that emits `values` and then closes, so `observe()` returns when done.
    private func makeSUT(
        emitting values: [Bool],
        reconnectedDisplay: Duration = .zero
    ) -> ConnectivityViewModel {
        withDependencies {
            $0.connectivity = .mock {
                AsyncStream { continuation in
                    for value in values { continuation.yield(value) }
                    continuation.finish()
                }
            }
        } operation: {
            ConnectivityViewModel(reconnectedDisplay: reconnectedDisplay)
        }
    }

    @Test func `shows the offline banner when the connection drops`() async {
        let sut = makeSUT(emitting: [true, false])

        await sut.observe()

        #expect(sut.bannerState == .offline)
    }

    @Test func `clears the banner after reconnecting`() async {
        let sut = makeSUT(emitting: [false, true])

        await sut.observe()

        // offline → reconnected flash → auto-dismiss back to nil.
        #expect(sut.bannerState == nil)
    }

    @Test func `stays clear while connected the whole time`() async {
        let sut = makeSUT(emitting: [true])

        await sut.observe()

        #expect(sut.bannerState == nil)
    }
}
