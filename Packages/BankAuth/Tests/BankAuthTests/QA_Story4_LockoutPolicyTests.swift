// QA Agent — Sprint 1 (sprint-1-front-door).
// Story 4 (lockout after 6 failures), tested against `LiveLockoutPolicy`'s
// public interface only.
//
// Source of every assertion: requirements/sprint-1-front-door-stories.md
// and Packages/BankAuth/Sources/BankAuth/LockoutPolicy.swift's doc
// comments — never the implementation.
//
// No `Task.sleep` appears anywhere in this file (role rule). Where the
// contract's behavior is defined in terms of elapsed time (the rolling
// 15-minute window), the `windowSeconds` parameter on the public
// initializer is used as an extremization knob instead: a window of `-1`
// makes every already-recorded failure unambiguously "outside the
// window" the instant it is recorded, without waiting on the clock.

import Testing
import Foundation
import BankAuth

@Suite("QA Story 4 — LockoutPolicy")
struct QALockoutPolicyTests {

    private func freshDefaults() -> UserDefaults {
        UserDefaults(suiteName: "qa.lockout.\(UUID().uuidString)")!
    }

    /// A fresh, independent suite name — used when a test needs to open
    /// the same underlying storage more than once (simulating separate
    /// launches), since handing the same `UserDefaults` *instance* to two
    /// actor-isolated initializers trips Swift 6's sending-risk check.
    /// Two `UserDefaults(suiteName:)` calls for the same name still read
    /// and write the same on-disk suite.
    private func freshSuiteName() -> String {
        "qa.lockout.\(UUID().uuidString)"
    }

    // AC-4.1: fewer than 6 combined failures does not lock out.
    @Test("AC-4.1: 5 failures within the window does not lock out")
    func notLockedOutBelowThreshold() async {
        let policy = LiveLockoutPolicy(
            defaults: freshDefaults(), key: "qa-key", windowSeconds: 900, failureThreshold: 6
        )
        for _ in 0..<5 {
            await policy.recordFailure(.invalidLoginCredentials)
        }

        #expect(await policy.isLockedOut == false)
    }

    // AC-4.1: 6 combined failures — login, biometric, and passcode mixed —
    // locks out. The window must count kinds together, not per call site.
    @Test("AC-4.1: 6 failures combining all three AuthFailureKind cases locks out")
    func lockedOutAtThresholdCombiningAllFailureKinds() async {
        let policy = LiveLockoutPolicy(
            defaults: freshDefaults(), key: "qa-key", windowSeconds: 900, failureThreshold: 6
        )
        await policy.recordFailure(.invalidLoginCredentials)
        await policy.recordFailure(.invalidLoginCredentials)
        await policy.recordFailure(.biometricMismatch)
        await policy.recordFailure(.biometricMismatch)
        await policy.recordFailure(.passcodeMismatch)
        await policy.recordFailure(.passcodeMismatch)

        #expect(await policy.isLockedOut == true)
    }

    // AC-4.3 / DECISION Q6: reset() clears the window and lifts lockout
    // immediately.
    @Test("AC-4.3/Q6: reset() immediately lifts a lockout")
    func resetClearsTheWindowImmediately() async {
        let policy = LiveLockoutPolicy(
            defaults: freshDefaults(), key: "qa-key", windowSeconds: 900, failureThreshold: 6
        )
        for _ in 0..<6 {
            await policy.recordFailure(.invalidLoginCredentials)
        }
        #expect(await policy.isLockedOut == true)

        await policy.reset()

        #expect(await policy.isLockedOut == false)
    }

    // AC-4.5 / DECISION Q4: lockout state persists across what a relaunch
    // or device restart would look like — a second policy instance backed
    // by the same UserDefaults suite/key must see the same state.
    @Test("AC-4.5/Q4: lockout persists across separate instances sharing storage")
    func persistsAcrossSeparateInstancesSharingTheSameDefaults() async {
        let suiteName = freshSuiteName()
        let key = "qa-persist-key"
        let policyA = LiveLockoutPolicy(
            defaults: UserDefaults(suiteName: suiteName)!, key: key, windowSeconds: 900, failureThreshold: 6
        )
        for _ in 0..<6 {
            await policyA.recordFailure(.invalidLoginCredentials)
        }
        #expect(await policyA.isLockedOut == true)

        let policyB = LiveLockoutPolicy(
            defaults: UserDefaults(suiteName: suiteName)!, key: key, windowSeconds: 900, failureThreshold: 6
        )

        #expect(await policyB.isLockedOut == true)
    }

    // AC-4.1: the window is rolling — failures outside it don't count.
    // A window of `-1` guarantees every failure, no matter how recently
    // recorded, is already outside it (elapsed time is never negative),
    // so this is deterministic without any real wait.
    @Test("AC-4.1: failures outside the rolling window do not count toward lockout")
    func failuresOutsideTheRollingWindowDoNotCount() async {
        let policy = LiveLockoutPolicy(
            defaults: freshDefaults(), key: "qa-key", windowSeconds: -1, failureThreshold: 1
        )

        await policy.recordFailure(.invalidLoginCredentials)

        #expect(await policy.isLockedOut == false)
    }
}
