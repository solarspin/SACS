import Foundation

/// The gateway's two business roles. Decoded from the JWT role claim
/// (Sprint 1 AC-1.5, AC-5.3) — this is the single source of truth for a
/// user's role everywhere in the app; nothing stores a second copy.
///
/// Owned by: BankCore. May be depended on by: every package (BankCore
/// has no dependencies and every other package depends on it directly
/// or transitively), because both BankNetworking (decodes the claim)
/// and every feature package (renders/enforces the role) need it
/// without any feature package depending on another.
public enum Role: String, Codable, Sendable, Equatable {
    case owner
    case staff
}
