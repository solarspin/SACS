import BankCore

/// Decodes the `role` claim out of a raw JWT string. Kept as its own
/// seam (rather than inlined in `AuthGatewayClient`) so QA can unit-test
/// claim decoding — including malformed/missing-claim tokens — without
/// a network call.
///
/// Owned by: BankNetworking (internal collaborator of the
/// `AuthGatewayClient` implementation). Not consumed by any other
/// package directly — BankAuth only ever sees the already-decoded
/// `Role` on an `AuthSession`, never a raw token.
public protocol JWTRoleClaimDecoding: Sendable {
    /// Throws `AuthError.transport(.decoding(_:))` on a token with no
    /// readable role claim. Never guesses a default role.
    func role(fromJWT token: String) throws -> Role
}
