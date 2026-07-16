import Testing
import Foundation
@testable import BankAuth

@Suite
struct LiveLockoutPolicyTests {
    private func makePolicy(windowSeconds: TimeInterval = 60, threshold: Int = 6) -> LiveLockoutPolicy {
        LiveLockoutPolicy(
            defaults: UserDefaults(suiteName: "bankauth-tests-\(UUID().uuidString)")!,
            key: "lockout",
            windowSeconds: windowSeconds,
            failureThreshold: threshold
        )
    }

    @Test func notLockedOutBelowThreshold() async {
        let policy = makePolicy(threshold: 6)
        for _ in 0..<5 {
            await policy.recordFailure(.invalidLoginCredentials)
        }
        #expect(await policy.isLockedOut == false)
    }

    @Test func lockedOutAtThresholdCombiningAllFailureKinds() async {
        // AC-4.1: login, biometric, and passcode failures combine into
        // one count — this test deliberately mixes all three kinds.
        let policy = makePolicy(threshold: 6)
        await policy.recordFailure(.invalidLoginCredentials)
        await policy.recordFailure(.invalidLoginCredentials)
        await policy.recordFailure(.biometricMismatch)
        await policy.recordFailure(.biometricMismatch)
        await policy.recordFailure(.passcodeMismatch)
        await policy.recordFailure(.passcodeMismatch)
        #expect(await policy.isLockedOut == true)
    }

    @Test func resetClearsTheWindowImmediately() async {
        let policy = makePolicy(threshold: 6)
        for _ in 0..<6 {
            await policy.recordFailure(.invalidLoginCredentials)
        }
        #expect(await policy.isLockedOut == true)

        await policy.reset()
        #expect(await policy.isLockedOut == false)
    }

    @Test func failuresOutsideTheRollingWindowDoNotCount() async throws {
        // A near-zero window means every failure "ages out" almost
        // immediately, proving old failures are pruned rather than
        // accumulating forever.
        let policy = makePolicy(windowSeconds: 0.05, threshold: 6)
        for _ in 0..<6 {
            await policy.recordFailure(.invalidLoginCredentials)
        }
        try await Task.sleep(nanoseconds: 150_000_000)
        #expect(await policy.isLockedOut == false)
    }

    @Test func persistsAcrossSeparateInstancesSharingTheSameDefaults() async {
        // AC-4.5: lockout state must survive relaunch — modeled here as
        // a second policy instance reading the same UserDefaults suite.
        let suiteName = "bankauth-tests-\(UUID().uuidString)"
        let first = LiveLockoutPolicy(
            defaults: UserDefaults(suiteName: suiteName)!, key: "lockout", windowSeconds: 60, failureThreshold: 6
        )
        for _ in 0..<6 {
            await first.recordFailure(.invalidLoginCredentials)
        }

        // A second instance pointing at the same suite name reads the
        // same underlying storage — modeling a fresh process reopening
        // the same on-device persistence.
        let second = LiveLockoutPolicy(
            defaults: UserDefaults(suiteName: suiteName)!, key: "lockout", windowSeconds: 60, failureThreshold: 6
        )
        #expect(await second.isLockedOut == true)
    }
}
