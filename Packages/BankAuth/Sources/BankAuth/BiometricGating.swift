/// The outcome of one biometric-gate presentation (Stories 2, 3).
///
/// Owned by: BankAuth. Not exposed to any other package.
public enum BiometricGateOutcome: Equatable, Sendable {
    /// Biometric match, or a successful OS passcode fallback (AC-3.2) —
    /// both are treated identically by every caller.
    case success
    /// A biometric or passcode mismatch (AC-3.3). Every `.failed` must
    /// be recorded via `LockoutPolicy.recordFailure`.
    case failed(AuthFailureKind)
    /// The user dismissed the OS prompt without a match or a failure —
    /// not counted toward lockout; the app remains gated.
    case canceled
}

/// Presents the OS's own Face ID / Touch ID prompt, backed by
/// Secure-Enclave-generated, non-exportable keys (S2, AC-2.2). After 3
/// consecutive biometric mismatches, the OS's own device-passcode
/// fallback sheet is offered (AC-3.1) — this is the operating system's
/// sheet, not one BankSmartAI builds; nothing here specifies a custom
/// PIN UI, because none exists (Story 3 scope-out).
///
/// Must never be called when `BiometricCapabilityChecking.capability`
/// is `.unavailable` (Story 7) — that path uses
/// `AuthSessionRepository.signIn` instead. Deliberately internal, not
/// public: `ReentryGateRepository`'s implementation is the only thing
/// that may call `evaluate()`, since it is the only thing that checks
/// capability and lockout first. Making this type invisible outside
/// BankAuth — including to the App composition root — turns that
/// precondition from a doc comment into something the compiler enforces
/// for every package boundary; only a same-module caller inside BankAuth
/// could still get it wrong, which is a QA/code-review concern from here.
///
/// Owned by: BankAuth. Not exposed to any other package — enforced by
/// the compiler, not just this comment.
protocol BiometricGating: Sendable {
    func evaluate() async -> BiometricGateOutcome
}
