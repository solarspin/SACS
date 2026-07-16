import Foundation
import BankCore

/// The sole seam through which any package reaches `POST /auth/login`
/// and `POST /auth/refresh`. Per `architecture/PLAN.md`'s layer rule,
/// only BankNetworking speaks HTTP and only BankNetworking owns the
/// auth token — this protocol is that ownership made concrete: no
/// method here returns a raw token string, and no other package can
/// construct the request or touch the Keychain entry storing it.
///
/// An implementation of this protocol is responsible for, on every
/// success: storing `token`, `refreshToken`, `expiresInSeconds`, and
/// `refreshExpiresInSeconds` in the Keychain with
/// `kSecAttrAccessibleAfterFirstUnlock` (S3, AC-1.4, AC-1.6, AC-6.3),
/// decoding the role via `JWTRoleClaimDecoding` (AC-1.5), and never
/// writing any of it to UserDefaults, a plist, or a log (S1, S9).
///
/// Owned by: BankNetworking. May be depended on by: BankAuth.
public protocol AuthGatewayClient: Sendable {
    /// Calls `POST /auth/login`. AC-1.1, AC-1.2.
    /// - Throws: `AuthError.invalidCredentials` on a 401
    ///   (AC-1.3), `AuthError.transport` otherwise.
    func signIn(email: String, password: String) async throws -> AuthSession

    /// Calls `POST /auth/refresh` with the Keychain-stored
    /// `refreshToken` — never a password (AC-6.2). On success,
    /// atomically replaces all four stored token fields; the prior
    /// refreshToken is never presented to the gateway again (AC-6.3),
    /// since the gateway itself invalidates it as one-time-use.
    /// - Throws: `AuthError.refreshFailed` on either 401 variant
    ///   (AC-6.4, AC-6.5), `AuthError.transport` otherwise.
    func refreshSession() async throws -> AuthSession

    /// Discards the stored refreshToken without contacting the gateway.
    /// The only caller is the Story 8 decline path (DECISION Q11): a
    /// refresh token left unguarded by biometric proof must not persist.
    /// Must never be called for a Story 7 (no-biometric-capability)
    /// device — AC-7.2 requires that device to keep its refreshToken.
    func discardRefreshToken() async

    /// Clears all stored session material (both tokens and their
    /// expiries). Called on an unrecoverable auth failure (AC-6.4,
    /// AC-6.5 fall back to a fresh login) and on explicit sign-out.
    func clearSession() async

    /// The currently stored session, if any — no network call. A `nil`
    /// or expired-`expiresAt` result means no cached token may grant
    /// entry (AC-4.4, AC-6.1).
    var currentSession: AuthSession? { get async }
}
