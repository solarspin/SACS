import BankCore

/// Errors specific to the auth gateway calls, distinct from the general
/// `AppError` (BankCore) because a login failure and a session-expiry
/// failure mean different things to a caller and must be countable
/// differently toward the Story 4 lockout window.
///
/// Owned by: BankNetworking. May be depended on by: BankAuth.
public enum AuthError: Error, Equatable, Sendable {
    /// `POST /auth/login` → `401 { "error": "invalid credentials" }`
    /// (AC-1.3). Counts toward the Story 4 rolling lockout window
    /// (DECISION Q5).
    case invalidCredentials

    /// `POST /auth/refresh` → either 401 variant — "unknown or
    /// already-used refresh token" (AC-6.4) or "refresh token expired"
    /// (AC-6.5). Both require the identical app-side response (fall
    /// back to `POST /auth/login`), so this contract does not
    /// distinguish them. Never counts toward the Story 4 lockout window
    /// (DECISION Q9).
    case refreshFailed

    /// Any other transport-level failure (offline, timeout, 5xx,
    /// malformed response). Wraps the general-purpose `AppError`.
    case transport(AppError)
}
