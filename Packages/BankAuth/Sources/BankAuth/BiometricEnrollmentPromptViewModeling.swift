/// The Story 8 opt-in prompt's view model contract. Shown once, on the
/// device's first successful login while `enrollmentChoice` is
/// `.notYetOffered` and the device is biometric-capable (AC-8.1);
/// re-offerable later only from Settings, never re-prompted
/// automatically (DECISION Q12) — that later Settings entry point reuses
/// this same contract, it does not need one of its own.
///
/// Owned by: BankAuth. Consumed by: the enrollment-prompt view only.
@MainActor
public protocol BiometricEnrollmentPromptViewModeling: AnyObject {
    /// AC-8.3: calls `ReentryGateRepository.acceptBiometricEnrollment()`.
    func accept() async

    /// AC-8.2, DECISION Q11: calls
    /// `ReentryGateRepository.declineBiometricEnrollment()`, which
    /// itself discards the stored refreshToken.
    func decline() async
}
