import Foundation

/// A password in transit from the sign-in form to the gateway.
///
/// Same precedent as `Money` refusing to be built from a `Double`: when a
/// mistake is cheap to prevent structurally, the type prevents it rather
/// than leaning on review alone (S9 — no sensitive values in logs).
/// Deliberately not `Codable` — nothing may serialize a `Credential` to
/// a cache, a plist, or a request log, because nothing in this contract
/// set ever needs to. It exists for exactly one hop —
/// `SignInViewModeling` converts its raw `String` password into a
/// `Credential` only at the call into `AuthSessionRepository`/
/// `AuthGatewayClient` — and is discarded immediately after.
public struct Credential: Equatable, Sendable {
    public let value: String

    public init(_ value: String) {
        self.value = value
    }
}

extension Credential: CustomStringConvertible, CustomDebugStringConvertible {
    /// Redacted on purpose: an accidental `print(credential)` or a
    /// careless `"\(credential)"` inside a future error message must
    /// never leak the password (S9).
    public var description: String { "<redacted>" }
    public var debugDescription: String { "<redacted>" }
}
