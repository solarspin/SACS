// QA Agent — Sprint 1 (sprint-1-front-door).
// Stories 2 (biometric re-entry gate), 3 (passcode fallback) and 4
// (lockout), tested against `LiveBiometricGateViewModel`'s public
// interface only. Both collaborators (`AuthSessionRepository`,
// `ReentryGateRepository`) are public protocols, so `presentBiometricGate()`'s
// outcome is fully controllable here via a QA-authored fake — this is
// where Stories 2/3's success/failed/canceled handling gets real
// coverage, without ever touching Face ID/Touch ID or the internal
// `BiometricGating` type. `SessionPhase`'s fixed precedence order (its own
// doc comment) is the source for every ordering assertion below.

import Testing
import Foundation
import BankCore
import BankAuth

@Suite("QA Story 2, 3 & 4 — BiometricGateViewModel")
@MainActor
struct QABiometricGateViewModelTests {

    // AC-4.1/4.4: lockout takes precedence over everything else — even an
    // unexpired session and a gate that would otherwise not be required.
    // "No cached token or biometric prompt may grant entry" while locked
    // out (LockoutPolicy's own doc comment).
    @Test("AC-4.1/4.4: isLockedOut takes precedence over a valid, ungated session")
    func lockedOutTakesPrecedenceOverEverythingElse() async {
        let session = QAFakeAuthSessionRepository(currentRole: .owner)
        let reentry = QAFakeReentryGateRepository(biometricCapable: true, biometricGateRequired: false, isLockedOut: true)
        let vm = LiveBiometricGateViewModel(sessionRepository: session, reentryRepository: reentry)

        await vm.presentGateIfNeeded()

        #expect(vm.phase == .lockedOut)
        #expect(await reentry.presentBiometricGateCallCount == 0)
    }

    // AC-4.2: the locked-out state is never silent.
    @Test("AC-4.2: the locked-out state carries a non-nil, visible message")
    func lockedOutStateHasAVisibleMessage() async {
        let session = QAFakeAuthSessionRepository(currentRole: .owner)
        let reentry = QAFakeReentryGateRepository(isLockedOut: true)
        let vm = LiveBiometricGateViewModel(sessionRepository: session, reentryRepository: reentry)

        await vm.presentGateIfNeeded()

        #expect(vm.lockedOutMessage != nil)
    }

    @Test("lockedOutMessage is nil outside the locked-out phase")
    func lockedOutMessageIsNilWhenNotLockedOut() async {
        let session = QAFakeAuthSessionRepository(currentRole: nil)
        let reentry = QAFakeReentryGateRepository(isLockedOut: false)
        let vm = LiveBiometricGateViewModel(sessionRepository: session, reentryRepository: reentry)

        await vm.presentGateIfNeeded()

        #expect(vm.lockedOutMessage == nil)
    }

    // SessionPhase precedence #2: no valid session -> signedOut.
    @Test("No stored session, not locked out -> signedOut")
    func noSessionIsSignedOut() async {
        let session = QAFakeAuthSessionRepository(currentRole: nil)
        let reentry = QAFakeReentryGateRepository(isLockedOut: false)
        let vm = LiveBiometricGateViewModel(sessionRepository: session, reentryRepository: reentry)

        await vm.presentGateIfNeeded()

        #expect(vm.phase == .signedOut)
    }

    // AC-2.3: an unexpired token within the idle window is reused as-is —
    // no biometric prompt is presented.
    @Test("AC-2.3: a valid session with no gate required reuses the session without prompting")
    func validSessionWithoutGateRequiredReusesSessionWithoutPrompting() async {
        let session = QAFakeAuthSessionRepository(currentRole: .owner)
        let reentry = QAFakeReentryGateRepository(biometricCapable: true, biometricGateRequired: false, isLockedOut: false)
        let vm = LiveBiometricGateViewModel(sessionRepository: session, reentryRepository: reentry)

        await vm.presentGateIfNeeded()

        #expect(vm.phase == .signedIn(role: .owner))
        #expect(await reentry.presentBiometricGateCallCount == 0)
    }

    // AC-2.1/2.4 + AC-3.2: a required gate that succeeds (biometric match
    // OR passcode fallback — the view model treats both identically per
    // BiometricGateOutcome's doc comment) reaches signedIn.
    @Test("AC-2.1/3.2: a required gate that succeeds reaches signedIn")
    func gateRequiredAndSuccessfulOutcomeReachesSignedIn() async {
        let session = QAFakeAuthSessionRepository(currentRole: .staff)
        let reentry = QAFakeReentryGateRepository(biometricCapable: true, biometricGateRequired: true, isLockedOut: false)
        await reentry.setPresentGateOutcome(.success)
        let vm = LiveBiometricGateViewModel(sessionRepository: session, reentryRepository: reentry)

        await vm.presentGateIfNeeded()

        #expect(vm.phase == .signedIn(role: .staff))
        #expect(await reentry.presentBiometricGateCallCount == 1)
    }

    // State-machine negative test: a failed gate outcome must NEVER reach
    // signedIn — the transition that must not exist, per the role prompt's
    // non-negotiable rule and AC-2.1 ("never re-authenticates silently").
    @Test("AC-2.1/3.3: a failed gate outcome never falls through to signedIn")
    func failedGateOutcomeNeverReachesSignedIn() async {
        let session = QAFakeAuthSessionRepository(currentRole: .owner)
        let reentry = QAFakeReentryGateRepository(biometricCapable: true, biometricGateRequired: true, isLockedOut: false)
        await reentry.setPresentGateOutcome(.failed(.biometricMismatch))
        let vm = LiveBiometricGateViewModel(sessionRepository: session, reentryRepository: reentry)

        await vm.presentGateIfNeeded()

        if case .signedIn = vm.phase {
            Issue.record("a failed biometric gate must never fall through to signedIn, even with an unexpired token")
        }
    }

    // Same negative test for a passcode-fallback failure specifically
    // (AC-3.3: biometric and passcode failures are both counted/handled
    // identically as gate failures).
    @Test("AC-3.3: a failed passcode-fallback outcome never falls through to signedIn")
    func failedPasscodeOutcomeNeverReachesSignedIn() async {
        let session = QAFakeAuthSessionRepository(currentRole: .owner)
        let reentry = QAFakeReentryGateRepository(biometricCapable: true, biometricGateRequired: true, isLockedOut: false)
        await reentry.setPresentGateOutcome(.failed(.passcodeMismatch))
        let vm = LiveBiometricGateViewModel(sessionRepository: session, reentryRepository: reentry)

        await vm.presentGateIfNeeded()

        if case .signedIn = vm.phase {
            Issue.record("a failed passcode fallback must never fall through to signedIn")
        }
    }

    // A canceled gate (user dismissed the OS prompt) is not a failure, but
    // must also never grant entry — "the app remains gated"
    // (BiometricGateOutcome's own doc comment).
    @Test("A canceled gate leaves the app gated, never signedIn")
    func canceledGateLeavesAppGated() async {
        let session = QAFakeAuthSessionRepository(currentRole: .owner)
        let reentry = QAFakeReentryGateRepository(biometricCapable: true, biometricGateRequired: true, isLockedOut: false)
        await reentry.setPresentGateOutcome(.canceled)
        let vm = LiveBiometricGateViewModel(sessionRepository: session, reentryRepository: reentry)

        await vm.presentGateIfNeeded()

        if case .signedIn = vm.phase {
            Issue.record("a canceled gate must never fall through to signedIn")
        }
    }
}
