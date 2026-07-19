// QA Agent — Sprint 1 (sprint-1-front-door).
// Story 8 (opt-in enrollment), the prompt view model's own accept/decline
// wiring, tested against `LiveBiometricEnrollmentPromptViewModel`'s
// public interface only.

import Testing
import Foundation
import BankAuth

@Suite("QA Story 8 — BiometricEnrollmentPromptViewModel")
@MainActor
struct QABiometricEnrollmentPromptViewModelTests {

    // AC-8.3: accept() calls ReentryGateRepository.acceptBiometricEnrollment().
    @Test("AC-8.3: accept() calls acceptBiometricEnrollment() on the repository")
    func acceptCallsReentryRepositoryAccept() async {
        let reentry = QAFakeReentryGateRepository()
        let vm = LiveBiometricEnrollmentPromptViewModel(reentryRepository: reentry)

        await vm.accept()

        #expect(await reentry.acceptCallCount == 1)
    }

    // AC-8.2/DECISION Q11: decline() calls
    // ReentryGateRepository.declineBiometricEnrollment(), which is itself
    // responsible for discarding the stored refresh token (covered
    // directly against LiveReentryGateRepository in
    // QA_Story7And8_ReentryGateRepositoryTests.swift).
    @Test("AC-8.2: decline() calls declineBiometricEnrollment() on the repository")
    func declineCallsReentryRepositoryDecline() async {
        let reentry = QAFakeReentryGateRepository()
        let vm = LiveBiometricEnrollmentPromptViewModel(reentryRepository: reentry)

        await vm.decline()

        #expect(await reentry.declineCallCount == 1)
    }
}
