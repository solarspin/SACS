import Foundation
import BankCore

/// The decoded, canonical result of a successful `POST /auth/login` or
/// `POST /auth/refresh` call.
///
/// Deliberately does NOT expose the raw `token` or `refreshToken`
/// strings. Only BankNetworking's implementation ever holds those
/// values — it reads them off the wire, decodes the role claim from the
/// JWT itself (never the response's separate top-level `role` field, so
/// AC-1.5/AC-5.3's "single source of truth" holds even if the two were
/// ever to disagree), stores both tokens in the Keychain
/// (`kSecAttrAccessibleAfterFirstUnlock`, S3), and attaches the bearer
/// token to outgoing requests itself. No other package can log, cache,
/// or otherwise mishandle a token it never receives.
///
/// Owned by: BankNetworking. May be depended on by: BankAuth (the only
/// feature package in Sprint 1 scope).
public struct AuthSession: Equatable, Sendable {
    public let role: Role
    /// Wall-clock instant the session token stops being valid
    /// (issuance + `expiresInSeconds`, AC-6.1). Computed once at decode
    /// time so no consumer re-derives it from a raw integer.
    public let expiresAt: Date
    /// Wall-clock instant the refresh token stops being valid
    /// (issuance + `refreshExpiresInSeconds`, 45 days per Gateway/README.md).
    public let refreshExpiresAt: Date

    public init(role: Role, expiresAt: Date, refreshExpiresAt: Date) {
        self.role = role
        self.expiresAt = expiresAt
        self.refreshExpiresAt = refreshExpiresAt
    }
}
