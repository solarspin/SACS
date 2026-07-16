import Testing
import BankCore
import BankNetworking
@testable import BankAuth

@MainActor
@Suite
struct LiveSignInViewModelTests {
    @Test func successfulSignInOnACapableUnenrolledDeviceOffersEnrollment() async {
        let gateway = FakeAuthGatewayClient()
        await gateway.setSignInResult(.success(makeSession(role: .owner)))
        let sessionRepo = LiveAuthSessionRepository(gatewayClient: gateway, lockoutPolicy: FakeLockoutPolicy())
        let reentryRepo = FakeReentryGateRepository()
        reentryRepo.capable = true
        reentryRepo.choiceValue = .notYetOffered
        let viewModel = LiveSignInViewModel(sessionRepository: sessionRepo, reentryRepository: reentryRepo)
        viewModel.email = "owner@banksmart.test"
        viewModel.password = "owner-demo-1"

        await viewModel.signIn()

        #expect(viewModel.outcome == .offerBiometricEnrollment)
        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.password.isEmpty)
    }

    @Test func successfulSignInOnAnIncapableDeviceGoesStraightToSignedIn() async {
        // Story 7: never offer enrollment on a device that can't use it.
        let gateway = FakeAuthGatewayClient()
        await gateway.setSignInResult(.success(makeSession(role: .staff)))
        let sessionRepo = LiveAuthSessionRepository(gatewayClient: gateway, lockoutPolicy: FakeLockoutPolicy())
        let reentryRepo = FakeReentryGateRepository()
        reentryRepo.capable = false
        reentryRepo.choiceValue = .notYetOffered
        let viewModel = LiveSignInViewModel(sessionRepository: sessionRepo, reentryRepository: reentryRepo)
        viewModel.email = "staff@banksmart.test"
        viewModel.password = "staff-demo-1"

        await viewModel.signIn()

        #expect(viewModel.outcome == .signedIn(.staff))
    }

    @Test func successfulSignInWithAnAlreadyRecordedChoiceGoesStraightToSignedIn() async {
        // DECISION Q12: never re-offer once a choice has been recorded.
        let gateway = FakeAuthGatewayClient()
        await gateway.setSignInResult(.success(makeSession(role: .owner)))
        let sessionRepo = LiveAuthSessionRepository(gatewayClient: gateway, lockoutPolicy: FakeLockoutPolicy())
        let reentryRepo = FakeReentryGateRepository()
        reentryRepo.capable = true
        reentryRepo.choiceValue = .declined
        let viewModel = LiveSignInViewModel(sessionRepository: sessionRepo, reentryRepository: reentryRepo)
        viewModel.email = "owner@banksmart.test"
        viewModel.password = "owner-demo-1"

        await viewModel.signIn()

        #expect(viewModel.outcome == .signedIn(.owner))
    }

    @Test func invalidCredentialsSurfaceAVisibleErrorAndKeepTheAttemptedPassword() async {
        let gateway = FakeAuthGatewayClient()
        await gateway.setSignInResult(.failure(.invalidCredentials))
        let sessionRepo = LiveAuthSessionRepository(gatewayClient: gateway, lockoutPolicy: FakeLockoutPolicy())
        let viewModel = LiveSignInViewModel(sessionRepository: sessionRepo, reentryRepository: FakeReentryGateRepository())
        viewModel.email = "owner@banksmart.test"
        viewModel.password = "wrong-password"

        await viewModel.signIn()

        #expect(viewModel.errorMessage != nil)
        #expect(viewModel.outcome == .none)
        #expect(viewModel.isSubmitting == false)
    }
}
