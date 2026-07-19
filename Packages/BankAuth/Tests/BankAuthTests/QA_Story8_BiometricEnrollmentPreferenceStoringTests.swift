// QA Agent — Sprint 1 (sprint-1-front-door).
// Story 8 (opt-in enrollment) persistence, tested against
// `LiveBiometricEnrollmentPreferenceStoring`'s public interface only.

import Testing
import Foundation
import BankAuth

@Suite("QA Story 8 — BiometricEnrollmentPreferenceStoring")
struct QABiometricEnrollmentPreferenceStoringTests {

    private func freshDefaults() -> UserDefaults {
        UserDefaults(suiteName: "qa.enroll.\(UUID().uuidString)")!
    }

    /// See the identical helper's doc comment in
    /// QA_Story4_LockoutPolicyTests.swift: two `UserDefaults(suiteName:)`
    /// calls for the same name share on-disk storage without sending the
    /// same instance to two actor-isolated initializers.
    private func freshSuiteName() -> String {
        "qa.enroll.\(UUID().uuidString)"
    }

    // AC-8.1: a device that has never answered starts at .notYetOffered —
    // the trigger state for offering the prompt in the first place.
    @Test("AC-8.1: a fresh device defaults to notYetOffered")
    func freshDeviceDefaultsToNotYetOffered() async {
        let store = LiveBiometricEnrollmentPreferenceStoring(defaults: freshDefaults(), key: "qa-key")

        #expect(await store.choice == .notYetOffered)
    }

    // AC-8.3: recordEnrolled() persists across what a relaunch would look
    // like (a second instance backed by the same storage).
    @Test("AC-8.3: recordEnrolled() persists across separate instances sharing storage")
    func recordEnrolledPersistsAcrossInstances() async {
        let suiteName = freshSuiteName()
        let key = "qa-key"
        let store = LiveBiometricEnrollmentPreferenceStoring(defaults: UserDefaults(suiteName: suiteName)!, key: key)

        await store.recordEnrolled()
        #expect(await store.choice == .enrolled)

        let reloaded = LiveBiometricEnrollmentPreferenceStoring(defaults: UserDefaults(suiteName: suiteName)!, key: key)
        #expect(await reloaded.choice == .enrolled)
    }

    // AC-8.2/DECISION Q12: recordDeclined() persists, and the decision
    // stays declined — this type has no re-offer mechanism of its own,
    // consistent with "never re-prompted automatically."
    @Test("AC-8.2/Q12: recordDeclined() persists across separate instances sharing storage")
    func recordDeclinedPersistsAcrossInstances() async {
        let suiteName = freshSuiteName()
        let key = "qa-key"
        let store = LiveBiometricEnrollmentPreferenceStoring(defaults: UserDefaults(suiteName: suiteName)!, key: key)

        await store.recordDeclined()
        #expect(await store.choice == .declined)

        let reloaded = LiveBiometricEnrollmentPreferenceStoring(defaults: UserDefaults(suiteName: suiteName)!, key: key)
        #expect(await reloaded.choice == .declined)
    }
}
