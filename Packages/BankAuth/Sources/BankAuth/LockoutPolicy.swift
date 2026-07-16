/// The Story 4 rolling lockout window: 6 combined failures (login,
/// biometric, and passcode — AC-4.1) within a rolling 15 minutes
/// disables biometric re-entry until a fresh, successful
/// `POST /auth/login` resets it (AC-4.3, DECISION Q6).
///
/// A single `LockoutPolicy` instance must be shared by every collaborator
/// that can record a failure or must observe lockout state — Story 4
/// requires ONE combined window, not a separate count per call site.
/// Concretely: the same instance is injected into both
/// `AuthSessionRepository` and `ReentryGateRepository`'s implementations.
///
/// Persists across app relaunch and device restart (AC-4.5) — an
/// in-memory-only conformance does not satisfy this contract.
///
/// Owned by: BankAuth. Not exposed to any other package.
public protocol LockoutPolicy: Sendable {
    /// Records one failure toward the rolling window (AC-4.1).
    func recordFailure(_ kind: AuthFailureKind) async

    /// True once 6 combined failures have accumulated within the
    /// current rolling 15-minute window. While true, no cached token or
    /// biometric prompt may grant entry (AC-4.4) — only a fresh
    /// `POST /auth/login` can change this back to false.
    var isLockedOut: Bool { get async }

    /// Clears the rolling window and lifts lockout immediately. The
    /// only caller is a just-succeeded `POST /auth/login` (AC-4.3,
    /// DECISION Q6) — never called on its own from a UI action.
    func reset() async
}
