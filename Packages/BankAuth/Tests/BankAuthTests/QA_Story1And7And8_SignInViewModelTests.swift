// QA Agent — Sprint 1 (sprint-1-front-door).
// Story 1 (visible sign-in failure), Story 7 (incapable devices skip the
// enrollment offer) and Story 8 (opt-in enrollment offer), tested against
// `LiveSignInViewModel`'s public interface only. `AuthSessionRepository`
// and `ReentryGateRepository` are both public protocols, so both
// collaborators are QA-authored fakes — no need to touch anything in
// Sources/BankAuth/Live*.swift to exercise this view model's full
// decision tree.

import Testing
import Foundation
import BankCore
import BankNetworking
import BankAuth

@Suite("QA Story 1, 7 & 8 — SignInViewModel")
@MainActor
struct QASignInViewModelTests {

    // AC-7.1/8.2: a successful sign-in on an incapable device goes
    // straight to the signed-in outcome — Story 8's offer never appears
    // where Story 7 applies.
    @Test("AC-7.1/8.2: successful sign-in on an incapable device goes straight to signedIn")
    func successfulSignInOnIncapableDeviceSkipsEnrollmentOffer() async {
        let session = QAFakeAuthSessionRepository(signInResult: .success(.owner))
        let reentry = QAFakeReentryGateRepository(biometricCapable: false, enrollmentChoice: .notYetOffered)
        let vm = LiveSignInViewModel(sessionRepository: session, reentryRepository: reentry)
        vm.email = "owner@banksmart.test"
        vm.password = "owner-demo-1"

        await vm.signIn()

        #expect(vm.outcome == .signedIn(.owner))
        #expect(vm.errorMessage == nil)
    }

    // AC-8.1/DECISION Q8: a successful first login on a capable,
    // not-yet-decided device must offer the opt-in prompt — never assumed,
    // never silently enabled.
    @Test("AC-8.1: successful sign-in on a capable, undecided device offers enrollment")
    func successfulSignInOnCapableUndecidedDeviceOffersEnrollment() async {
        let session = QAFakeAuthSessionRepository(signInResult: .success(.staff))
        let reentry = QAFakeReentryGateRepository(biometricCapable: true, enrollmentChoice: .notYetOffered)
        let vm = LiveSignInViewModel(sessionRepository: session, reentryRepository: reentry)
        vm.email = "staff@banksmart.test"
        vm.password = "staff-demo-1"

        await vm.signIn()

        #expect(vm.outcome == .offerBiometricEnrollment)
    }

    // DECISION Q12: once a choice is already recorded (enrolled or
    // declined), the prompt is never re-offered automatically — sign-in
    // goes straight to signedIn.
    @Test("Q12: sign-in with an already-decided choice goes straight to signedIn (enrolled)")
    func successfulSignInWithEnrolledChoiceSkipsOffer() async {
        let session = QAFakeAuthSessionRepository(signInResult: .success(.owner))
        let reentry = QAFakeReentryGateRepository(biometricCapable: true, enrollmentChoice: .enrolled)
        let vm = LiveSignInViewModel(sessionRepository: session, reentryRepository: reentry)
        vm.email = "owner@banksmart.test"
        vm.password = "owner-demo-1"

        await vm.signIn()

        #expect(vm.outcome == .signedIn(.owner))
    }

    @Test("Q12: sign-in with an already-decided choice goes straight to signedIn (declined)")
    func successfulSignInWithDeclinedChoiceSkipsOffer() async {
        let session = QAFakeAuthSessionRepository(signInResult: .success(.owner))
        let reentry = QAFakeReentryGateRepository(biometricCapable: true, enrollmentChoice: .declined)
        let vm = LiveSignInViewModel(sessionRepository: session, reentryRepository: reentry)
        vm.email = "owner@banksmart.test"
        vm.password = "owner-demo-1"

        await vm.signIn()

        #expect(vm.outcome == .signedIn(.owner))
    }

    // AC-1.3/S7: a 401 surfaces a visible failure — never swallowed — and
    // establishes no session.
    @Test("AC-1.3/S7: invalid credentials surface a visible error and establish no session")
    func invalidCredentialsSurfaceVisibleErrorAndNoSession() async {
        let session = QAFakeAuthSessionRepository(signInResult: .failure(AuthError.invalidCredentials))
        let reentry = QAFakeReentryGateRepository()
        let vm = LiveSignInViewModel(sessionRepository: session, reentryRepository: reentry)
        vm.email = "owner@banksmart.test"
        vm.password = "wrong-password"

        await vm.signIn()

        #expect(vm.errorMessage != nil)
        #expect(vm.outcome == .none)
        #expect(vm.isSubmitting == false)
    }

    // Non-negotiable rule: isSubmitting must not be left true after the
    // call resolves, on either path.
    @Test("isSubmitting is false after signIn() completes, on the success path")
    func isSubmittingResetsAfterSuccess() async {
        let session = QAFakeAuthSessionRepository(signInResult: .success(.owner))
        let reentry = QAFakeReentryGateRepository(biometricCapable: false)
        let vm = LiveSignInViewModel(sessionRepository: session, reentryRepository: reentry)
        vm.email = "owner@banksmart.test"
        vm.password = "owner-demo-1"

        await vm.signIn()

        #expect(vm.isSubmitting == false)
    }
}
