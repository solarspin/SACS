import Testing
@testable import BankNetworking
import BankCore

@Suite
struct DefaultJWTRoleClaimDecoderTests {
    private let decoder = DefaultJWTRoleClaimDecoder()

    @Test func decodesOwnerRole() throws {
        #expect(try decoder.role(fromJWT: makeTestJWT(role: "owner")) == .owner)
    }

    @Test func decodesStaffRole() throws {
        #expect(try decoder.role(fromJWT: makeTestJWT(role: "staff")) == .staff)
    }

    @Test func throwsOnMalformedTokenShape() {
        do {
            _ = try decoder.role(fromJWT: "not-a-jwt")
            Issue.record("expected a decoding error for a non-JWT-shaped string")
        } catch let error as AuthError {
            guard case .transport(.decoding) = error else {
                Issue.record("expected AuthError.transport(.decoding), got \(error)")
                return
            }
        } catch {
            Issue.record("expected AuthError, got \(error)")
        }
    }

    @Test func throwsOnUnrecognizedRoleClaim() {
        let token = makeTestJWT(role: "superuser")
        do {
            _ = try decoder.role(fromJWT: token)
            Issue.record("expected a decoding error for an unrecognized role claim")
        } catch let error as AuthError {
            guard case .transport(.decoding) = error else {
                Issue.record("expected AuthError.transport(.decoding), got \(error)")
                return
            }
        } catch {
            Issue.record("expected AuthError, got \(error)")
        }
    }
}
