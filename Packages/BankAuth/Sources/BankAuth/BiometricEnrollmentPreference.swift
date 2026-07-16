/// A device's standing decision about Story 8's opt-in biometric
/// re-entry offer. Never assumed, never silently enabled (AC-8.1).
///
/// Owned by: BankAuth. Not exposed to any other package.
public enum BiometricEnrollmentChoice: Equatable, Sendable {
    /// No decision recorded yet. `SignInViewModeling` must offer the
    /// Story 8 prompt after the next successful login on a capable
    /// device (AC-8.1) whenever the choice is in this state — which is
    /// exactly "first login on this device" the first time, and
    /// remains the trigger state until the user answers.
    case notYetOffered
    /// AC-8.3: Story 2's biometric re-entry gate applies.
    case enrolled
    /// AC-8.2: re-entry follows Story 7's password-login path. Per
    /// DECISION Q12, the prompt is never auto-re-offered from this
    /// state — only a manual action from Settings may change it.
    case declined
}

/// Stores the choice above. This protocol only records the decision —
/// it does not itself talk to `AuthGatewayClient`. DECISION Q11 requires
/// that declining also discard the stored refreshToken; that is a
/// two-step sequence the caller (a `SignInViewModeling` or
/// `BiometricEnrollmentPromptViewModeling` conformance) must perform
/// explicitly: call `recordDeclined()` here AND
/// `AuthGatewayClient.discardRefreshToken()` — keeping single
/// responsibility per protocol rather than reaching across the
/// BankAuth/BankNetworking boundary inside a storage type.
///
/// Owned by: BankAuth. Not exposed to any other package.
public protocol BiometricEnrollmentPreferenceStoring: Sendable {
    var choice: BiometricEnrollmentChoice { get async }

    /// AC-8.3. Only valid on a capable device (Story 7 conditions not
    /// met) — the prompt this answers is never shown otherwise.
    func recordEnrolled() async

    /// AC-8.2. See the discard-sequencing note above (DECISION Q11).
    func recordDeclined() async
}
