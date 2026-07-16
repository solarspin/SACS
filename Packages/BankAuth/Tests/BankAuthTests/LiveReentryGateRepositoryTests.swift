import Testing
import Foundation
import BankCore
import BankNetworking
@testable import BankAuth

@Suite
struct LiveReentryGateRepositoryTests {
    private func makeRepository(
        gateway: FakeAuthGatewayClient,
        capability: BiometricCapability = .available,
        gating: FakeBiometricGating,
        idleTimeoutPolicy: FakeIdleTimeoutPolicy,
        lockoutPolicy: FakeLockoutPolicy,
        enrollmentPreference: FakeBiometricEnrollmentPreferenceStoring
    ) -> LiveReentryGateRepository {
        LiveReentryGateRepository(
            gatewayClient: gateway,
            capabilityChecker: FakeBiometricCapabilityChecking(value: capability),
            gating: gating,
            idleTimeoutPolicy: idleTimeoutPolicy,
            lockoutPolicy: lockoutPolicy,
            enrollmentPreference: enrollmentPreference
        )
    }

    @Test func successReusesAnUnexpiredSessionWithoutRefreshing() async {
        let gateway = FakeAuthGatewayClient()
        await gateway.setStoredSession(makeSession(role: .owner))
        let gating = FakeBiometricGating()
        await gating.setOutcome(.success)
        let idle = FakeIdleTimeoutPolicy()
        let repository = makeRepository(
            gateway: gateway, gating: gating, idleTimeoutPolicy: idle,
            lockoutPolicy: FakeLockoutPolicy(), enrollmentPreference: FakeBiometricEnrollmentPreferenceStoring()
        )

        let outcome = await repository.presentBiometricGate()

        #expect(outcome == .success)
        #expect(await gateway.refreshCallCount == 0)
        #expect(await idle.recordActiveCallCount == 1)
    }

    @Test func successRefreshesAnExpiredSession() async {
        let gateway = FakeAuthGatewayClient()
        await gateway.setStoredSession(makeSession(role: .owner, expiresIn: -1))
        await gateway.setRefreshResult(.success(makeSession(role: .owner)))
        let gating = FakeBiometricGating()
        await gating.setOutcome(.success)
        let repository = makeRepository(
            gateway: gateway, gating: gating, idleTimeoutPolicy: FakeIdleTimeoutPolicy(),
            lockoutPolicy: FakeLockoutPolicy(), enrollmentPreference: FakeBiometricEnrollmentPreferenceStoring()
        )

        _ = await repository.presentBiometricGate()

        #expect(await gateway.refreshCallCount == 1)
    }

    @Test func successButFailedRefreshNeverRecordsALockoutFailure() async {
        // DECISION Q9: a dead refresh token after a successful biometric
        // match is not a biometric/passcode failure.
        let gateway = FakeAuthGatewayClient()
        await gateway.setStoredSession(makeSession(role: .owner, expiresIn: -1))
        await gateway.setRefreshResult(.failure(.refreshFailed))
        let gating = FakeBiometricGating()
        await gating.setOutcome(.success)
        let lockout = FakeLockoutPolicy()
        let repository = makeRepository(
            gateway: gateway, gating: gating, idleTimeoutPolicy: FakeIdleTimeoutPolicy(),
            lockoutPolicy: lockout, enrollmentPreference: FakeBiometricEnrollmentPreferenceStoring()
        )

        let outcome = await repository.presentBiometricGate()

        #expect(outcome == .success)
        #expect(await lockout.recordedFailures.isEmpty)
    }

    @Test func failedGateRecordsTheReportedFailureKind() async {
        let gateway = FakeAuthGatewayClient()
        let gating = FakeBiometricGating()
        await gating.setOutcome(.failed(.passcodeMismatch))
        let lockout = FakeLockoutPolicy()
        let repository = makeRepository(
            gateway: gateway, gating: gating, idleTimeoutPolicy: FakeIdleTimeoutPolicy(),
            lockoutPolicy: lockout, enrollmentPreference: FakeBiometricEnrollmentPreferenceStoring()
        )

        let outcome = await repository.presentBiometricGate()

        #expect(outcome == .failed(.passcodeMismatch))
        #expect(await lockout.recordedFailures == [.passcodeMismatch])
    }

    @Test func canceledNeverRecordsAFailure() async {
        let gateway = FakeAuthGatewayClient()
        let gating = FakeBiometricGating()
        await gating.setOutcome(.canceled)
        let lockout = FakeLockoutPolicy()
        let repository = makeRepository(
            gateway: gateway, gating: gating, idleTimeoutPolicy: FakeIdleTimeoutPolicy(),
            lockoutPolicy: lockout, enrollmentPreference: FakeBiometricEnrollmentPreferenceStoring()
        )

        let outcome = await repository.presentBiometricGate()

        #expect(outcome == .canceled)
        #expect(await lockout.recordedFailures.isEmpty)
    }

    @Test func declineDiscardsTheRefreshTokenAndRecordsThePreference() async {
        let gateway = FakeAuthGatewayClient()
        let enrollment = FakeBiometricEnrollmentPreferenceStoring()
        let repository = makeRepository(
            gateway: gateway, gating: FakeBiometricGating(), idleTimeoutPolicy: FakeIdleTimeoutPolicy(),
            lockoutPolicy: FakeLockoutPolicy(), enrollmentPreference: enrollment
        )

        await repository.declineBiometricEnrollment()

        #expect(await enrollment.choiceValue == .declined)
        #expect(await gateway.discardCallCount == 1)
    }

    @Test func acceptNeverTouchesTheRefreshToken() async {
        let gateway = FakeAuthGatewayClient()
        let enrollment = FakeBiometricEnrollmentPreferenceStoring()
        let repository = makeRepository(
            gateway: gateway, gating: FakeBiometricGating(), idleTimeoutPolicy: FakeIdleTimeoutPolicy(),
            lockoutPolicy: FakeLockoutPolicy(), enrollmentPreference: enrollment
        )

        await repository.acceptBiometricEnrollment()

        #expect(await enrollment.choiceValue == .enrolled)
        #expect(await gateway.discardCallCount == 0)
    }
}
