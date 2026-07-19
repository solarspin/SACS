// QA Agent — Sprint 1 (sprint-1-front-door).
// Story 7 (no-biometric devices fall back to password) and Story 8
// (opt-in enrollment), tested against `LiveReentryGateRepository`'s
// public interface only — via the public `.live(...)` factory.
//
// Deliberately NOT covered here: `presentBiometricGate()`'s own
// success/failure outcome. `LiveReentryGateRepository.live(...)` has no
// parameter accepting a fake for the internal `BiometricGating` type — by
// design (see that protocol's doc comment: "Deliberately internal, not
// public... enforced by the compiler, not just this comment"). Reaching
// around that with `@testable import` would defeat a boundary the
// contract states is intentional, and would also mean actually driving
// Face ID / Touch ID, which no package-level unit test can do. Stories
// 2/3's outcome-handling logic IS fully covered, black-box, in
// QA_Story2And3And4_BiometricGateViewModelTests.swift, which depends on
// `ReentryGateRepository` only as a protocol and so accepts a fake
// `presentBiometricGate()` outcome directly. See the evidence package's
// UNCOVERED section for what that leaves untested.

import Testing
import Foundation
import BankAuth

@Suite("QA Story 7 & 8 — ReentryGateRepository")
struct QAReentryGateRepositoryTests {

    private func makeRepository(
        capability: BiometricCapability = .available,
        idleElapsed: Bool = false,
        lockedOut: Bool = false,
        enrollmentChoice: BiometricEnrollmentChoice = .notYetOffered
    ) -> (LiveReentryGateRepository, QAFakeAuthGatewayClient, QAFakeBiometricEnrollmentPreferenceStoring) {
        let gateway = QAFakeAuthGatewayClient()
        let enrollment = QAFakeBiometricEnrollmentPreferenceStoring(choice: enrollmentChoice)
        let repo = LiveReentryGateRepository.live(
            gatewayClient: gateway,
            capabilityChecker: QAFakeBiometricCapabilityChecking(value: capability),
            idleTimeoutPolicy: QAFakeIdleTimeoutPolicy(elapsed: idleElapsed),
            lockoutPolicy: QAFakeLockoutPolicy(isLockedOut: lockedOut),
            enrollmentPreference: enrollment
        )
        return (repo, gateway, enrollment)
    }

    // AC-7.1: an incapable device (no hardware / not enrolled / no
    // passcode) must never be offered a biometric path.
    @Test("AC-7.1: biometricCapable reflects an unavailable BiometricCapabilityChecking")
    func incapableDeviceReportsNotCapable() async {
        let (repo, _, _) = makeRepository(capability: .unavailable)

        #expect(await repo.biometricCapable == false)
    }

    @Test("AC-7.1: biometricCapable reflects an available BiometricCapabilityChecking")
    func capableDeviceReportsCapable() async {
        let (repo, _, _) = makeRepository(capability: .available)

        #expect(await repo.biometricCapable == true)
    }

    // AC-2.1/2.4: biometricGateRequired reflects the idle-timeout policy's
    // elapsed state, including the cold-launch case.
    @Test("AC-2.1/2.4: biometricGateRequired reflects an elapsed idle timeout")
    func gateRequiredWhenIdleElapsed() async {
        let (repo, _, _) = makeRepository(idleElapsed: true)

        #expect(await repo.biometricGateRequired == true)
    }

    @Test("AC-2.3: biometricGateRequired is false when idle has not elapsed")
    func gateNotRequiredWhenIdleHasNotElapsed() async {
        let (repo, _, _) = makeRepository(idleElapsed: false)

        #expect(await repo.biometricGateRequired == false)
    }

    // AC-4.1/4.4: isLockedOut reflects the shared LockoutPolicy.
    @Test("AC-4.1/4.4: isLockedOut reflects the injected LockoutPolicy")
    func isLockedOutReflectsLockoutPolicy() async {
        let (repo, _, _) = makeRepository(lockedOut: true)

        #expect(await repo.isLockedOut == true)
    }

    // AC-8.1/DECISION Q12: enrollmentChoice starts at .notYetOffered on a
    // device that has never answered the prompt — the trigger state for
    // offering it.
    @Test("AC-8.1: enrollmentChoice reflects notYetOffered on a fresh device")
    func enrollmentChoiceStartsNotYetOffered() async {
        let (repo, _, _) = makeRepository(enrollmentChoice: .notYetOffered)

        #expect(await repo.enrollmentChoice == .notYetOffered)
    }

    // AC-8.3: accepting enrollment records it via
    // BiometricEnrollmentPreferenceStoring.recordEnrolled().
    @Test("AC-8.3: acceptBiometricEnrollment() records enrollment")
    func acceptEnrollmentRecordsEnrolled() async {
        let (repo, _, enrollment) = makeRepository(capability: .available, enrollmentChoice: .notYetOffered)

        await repo.acceptBiometricEnrollment()

        #expect(await enrollment.recordEnrolledCallCount == 1)
        #expect(await repo.enrollmentChoice == .enrolled)
    }

    // AC-8.2 + DECISION Q11: declining enrollment must both record the
    // decline AND discard the stored refresh token — an unguarded refresh
    // token must not persist once biometric re-entry is declined.
    @Test("AC-8.2/Q11: declineBiometricEnrollment() records decline and discards the refresh token")
    func declineEnrollmentRecordsDeclineAndDiscardsRefreshToken() async {
        let (repo, gateway, enrollment) = makeRepository(capability: .available, enrollmentChoice: .notYetOffered)

        await repo.declineBiometricEnrollment()

        #expect(await enrollment.recordDeclinedCallCount == 1)
        #expect(await repo.enrollmentChoice == .declined)
        #expect(await gateway.discardRefreshTokenCallCount == 1)
    }
}
