import Testing
import BankCore
@testable import BankAuth

@MainActor
@Suite
struct LiveBiometricGateViewModelTests {
    @Test func lockedOutWinsOverEverythingElse() async {
        let sessionRepo = FakeAuthSessionRepository()
        sessionRepo.roleValue = .owner
        let reentryRepo = FakeReentryGateRepository()
        reentryRepo.lockedOut = true
        let viewModel = LiveBiometricGateViewModel(sessionRepository: sessionRepo, reentryRepository: reentryRepo)

        await viewModel.presentGateIfNeeded()

        #expect(viewModel.phase == .lockedOut)
        #expect(viewModel.lockedOutMessage != nil)
    }

    @Test func noSessionMeansSignedOut() async {
        let sessionRepo = FakeAuthSessionRepository()
        sessionRepo.roleValue = nil
        let reentryRepo = FakeReentryGateRepository()
        let viewModel = LiveBiometricGateViewModel(sessionRepository: sessionRepo, reentryRepository: reentryRepo)

        await viewModel.presentGateIfNeeded()

        #expect(viewModel.phase == .signedOut)
    }

    @Test func validSessionWithNoGateRequiredGoesStraightToSignedIn() async {
        let sessionRepo = FakeAuthSessionRepository()
        sessionRepo.roleValue = .staff
        let reentryRepo = FakeReentryGateRepository()
        reentryRepo.gateRequired = false
        let viewModel = LiveBiometricGateViewModel(sessionRepository: sessionRepo, reentryRepository: reentryRepo)

        await viewModel.presentGateIfNeeded()

        #expect(viewModel.phase == .signedIn(role: .staff))
        #expect(reentryRepo.presentCallCount == 0)
    }

    @Test func incapableDeviceFallsBackToSignedOutRatherThanPromptingBiometrics() async {
        // Story 7.
        let sessionRepo = FakeAuthSessionRepository()
        sessionRepo.roleValue = .owner
        let reentryRepo = FakeReentryGateRepository()
        reentryRepo.gateRequired = true
        reentryRepo.capable = false
        let viewModel = LiveBiometricGateViewModel(sessionRepository: sessionRepo, reentryRepository: reentryRepo)

        await viewModel.presentGateIfNeeded()

        #expect(viewModel.phase == .signedOut)
        #expect(reentryRepo.presentCallCount == 0)
    }

    @Test func successfulGateShowsSignedIn() async {
        let sessionRepo = FakeAuthSessionRepository()
        sessionRepo.roleValue = .owner
        let reentryRepo = FakeReentryGateRepository()
        reentryRepo.gateRequired = true
        reentryRepo.capable = true
        reentryRepo.gateOutcome = .success
        let viewModel = LiveBiometricGateViewModel(sessionRepository: sessionRepo, reentryRepository: reentryRepo)

        await viewModel.presentGateIfNeeded()

        #expect(viewModel.phase == .signedIn(role: .owner))
    }

    @Test func failedGateNeverFallsThroughToSignedInEvenWithAnUnexpiredToken() async {
        // Regression: a wrong Face ID match must never show signed-in
        // content just because the underlying token happens to still
        // be unexpired.
        let sessionRepo = FakeAuthSessionRepository()
        sessionRepo.roleValue = .owner
        let reentryRepo = FakeReentryGateRepository()
        reentryRepo.gateRequired = true
        reentryRepo.capable = true
        reentryRepo.gateOutcome = .failed(.biometricMismatch)
        let viewModel = LiveBiometricGateViewModel(sessionRepository: sessionRepo, reentryRepository: reentryRepo)

        await viewModel.presentGateIfNeeded()

        if case .awaitingBiometricGate(let role) = viewModel.phase {
            #expect(role == .owner)
        } else {
            Issue.record("expected .awaitingBiometricGate, got \(viewModel.phase)")
        }
    }

    @Test func successfulGateButUnrecoverableSessionFallsBackToSignedOut() async {
        // AC-6.4/6.5: biometric itself succeeded but nothing usable
        // remained (e.g. the refresh token was already dead). Modeled
        // by having the session vanish as a direct side effect of the
        // gate running, the same way a failed background refresh would
        // leave AuthSessionRepository.currentRole reporting nil.
        let sessionRepo = FakeAuthSessionRepository()
        sessionRepo.roleValue = .owner
        let reentryRepo = FakeReentryGateRepository()
        reentryRepo.gateRequired = true
        reentryRepo.capable = true
        reentryRepo.gateOutcome = .success
        reentryRepo.onPresent = { sessionRepo.roleValue = nil }
        let viewModel = LiveBiometricGateViewModel(sessionRepository: sessionRepo, reentryRepository: reentryRepo)

        await viewModel.presentGateIfNeeded()

        #expect(viewModel.phase == .signedOut)
    }
}
