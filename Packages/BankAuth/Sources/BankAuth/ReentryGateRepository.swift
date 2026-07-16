import BankCore
import BankNetworking

/// The repository `BiometricGateViewModeling` and
/// `BiometricEnrollmentPromptViewModeling` call. Composes
/// `BiometricCapabilityChecking`, `BiometricGating`, `IdleTimeoutPolicy`,
/// `LockoutPolicy`, `BiometricEnrollmentPreferenceStoring`, and
/// `AuthGatewayClient` into the single Story 2/3/4/7/8 re-entry
/// decision, per `SessionPhase`'s fixed precedence order.
///
/// An implementation MUST share its `LockoutPolicy` instance with the
/// `AuthSessionRepository` implementation — Story 4's 6-failure window
/// is one combined count across login, biometric, and passcode
/// failures, never a per-repository count.
///
/// Owned by: BankAuth. May be depended on by: view models within
/// BankAuth only (not exposed outside the package).
public protocol ReentryGateRepository: Sendable {
    /// AC-7.1: false disables every biometric/passcode code path below —
    /// re-entry must go through `AuthSessionRepository.signIn` instead.
    var biometricCapable: Bool { get async }

    /// AC-2.1, AC-2.4: true when the idle timeout has elapsed (or on
    /// cold launch) and the gate must run before any signed-in content
    /// shows.
    var biometricGateRequired: Bool { get async }

    /// AC-4.1, AC-4.4: true once Story 4's combined 6-failure rolling
    /// window is active. Must be checked BEFORE `biometricGateRequired`
    /// — a locked-out device shows the Story 4 locked-out state even if
    /// the idle timeout has not separately elapsed.
    var isLockedOut: Bool { get async }

    /// AC-2.1–2.3, AC-3.1–3.3. Must not be called when
    /// `biometricCapable` is false or `isLockedOut` is true. On
    /// `.success` reuses the existing session if unexpired (AC-2.3) or
    /// calls `AuthGatewayClient.refreshSession()` if expired (AC-6.2).
    /// On `.failed`, records the given `AuthFailureKind` via
    /// `LockoutPolicy` (AC-3.3).
    func presentBiometricGate() async -> BiometricGateOutcome

    /// AC-8.1–8.3, DECISION Q12.
    var enrollmentChoice: BiometricEnrollmentChoice { get async }

    /// AC-8.3. Only valid when `biometricCapable` is true.
    func acceptBiometricEnrollment() async

    /// AC-8.2, DECISION Q11: records the decline AND discards the
    /// stored refreshToken via `AuthGatewayClient.discardRefreshToken()`
    /// — an unguarded refresh token must not persist once biometric
    /// re-entry is declined.
    func declineBiometricEnrollment() async
}
