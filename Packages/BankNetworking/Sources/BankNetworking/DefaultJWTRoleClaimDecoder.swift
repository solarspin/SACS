import Foundation
import BankCore

/// Decodes the `role` claim from the gateway's HS256, JWT-shaped tokens
/// (`header.payload.signature`, base64url segments — see `Gateway/server.js`'s
/// `sign`/`verify`). Does not verify the signature: the app trusts the
/// gateway it just received the token from over a connection it
/// initiated: the wire format's authenticity isn't this decoder's job,
/// only reading the claim already inside a token the app itself holds.
public struct DefaultJWTRoleClaimDecoder: JWTRoleClaimDecoding {
    private struct RoleClaim: Decodable {
        let role: String
    }

    public init() {}

    public func role(fromJWT token: String) throws -> Role {
        let segments = token.split(separator: ".", omittingEmptySubsequences: false)
        guard segments.count == 3 else {
            throw AuthError.transport(.decoding("malformed JWT: expected 3 dot-separated segments"))
        }
        guard let payloadData = Self.base64URLDecode(String(segments[1])) else {
            throw AuthError.transport(.decoding("malformed JWT: unreadable payload segment"))
        }

        let claim: RoleClaim
        do {
            claim = try JSONDecoder().decode(RoleClaim.self, from: payloadData)
        } catch {
            throw AuthError.transport(.decoding("JWT payload has no readable role claim"))
        }

        guard let role = Role(rawValue: claim.role) else {
            throw AuthError.transport(.decoding("unrecognized role claim: \(claim.role)"))
        }
        return role
    }

    private static func base64URLDecode(_ value: String) -> Data? {
        var base64 = value
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        while base64.count % 4 != 0 {
            base64.append("=")
        }
        return Data(base64Encoded: base64)
    }
}
