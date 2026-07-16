/// The failure kinds that count toward the Story 4 rolling 15-minute,
/// 6-failure lockout window (AC-4.1). Deliberately has no case for a
/// failed `POST /auth/refresh` — DECISION Q9 excludes it; a refresh
/// failure is a stale/stolen-token signal, not a wrong-credentials
/// guess, and must never reach `LockoutPolicy.recordFailure`.
///
/// Owned by: BankAuth. Not exposed to any other package.
public enum AuthFailureKind: Equatable, Sendable {
    /// A `POST /auth/login` 401 (AC-1.3, DECISION Q5).
    case invalidLoginCredentials
    /// A failed Face ID / Touch ID match (AC-3.3).
    case biometricMismatch
    /// A failed OS passcode-fallback entry (AC-3.3).
    case passcodeMismatch
}
