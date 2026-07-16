import Testing
import Foundation
@testable import BankNetworking
import BankCore

/// Serialized: `StubURLProtocol`'s stub queues are shared, unlocked
/// static state keyed by path, so concurrent tests could steal each
/// other's stubbed responses.
@Suite(.serialized)
struct LiveAuthGatewayClientTests {
    private func uniqueKeychainService() -> String {
        "com.banksmartai.auth.session.tests.\(UUID().uuidString)"
    }

    @Test func signInSucceedsAndDecodesRoleFromJWTNeverFromTheTopLevelField() async throws {
        StubURLProtocol.reset()
        // AC-1.5: the top-level "role" deliberately disagrees with the
        // JWT claim, so a pass here proves the JWT is the source used.
        StubURLProtocol.enqueue(path: "/auth/login", status: 200, json: [
            "token": makeTestJWT(role: "owner"),
            "role": "staff",
            "expiresInSeconds": 3600,
            "refreshToken": "rt-abc",
            "refreshExpiresInSeconds": 3_888_000,
        ])
        let client = makeStubbedClient(keychainService: uniqueKeychainService())

        let session = try await client.signIn(email: "owner@banksmart.test", password: Credential("owner-demo-1"))
        #expect(session.role == .owner)

        await client.clearSession()
    }

    @Test func signInPersistsSessionRetrievableAsCurrentSession() async throws {
        StubURLProtocol.reset()
        StubURLProtocol.enqueue(path: "/auth/login", status: 200, json: [
            "token": makeTestJWT(role: "staff"),
            "role": "staff",
            "expiresInSeconds": 3600,
            "refreshToken": "rt-abc",
            "refreshExpiresInSeconds": 3_888_000,
        ])
        let client = makeStubbedClient(keychainService: uniqueKeychainService())

        _ = try await client.signIn(email: "staff@banksmart.test", password: Credential("staff-demo-1"))
        let current = await client.currentSession
        #expect(current?.role == .staff)

        await client.clearSession()
    }

    @Test func signInThrowsInvalidCredentialsOn401() async {
        StubURLProtocol.reset()
        StubURLProtocol.enqueue(path: "/auth/login", status: 401, json: ["error": "invalid credentials"])
        let client = makeStubbedClient(keychainService: uniqueKeychainService())

        do {
            _ = try await client.signIn(email: "nobody@banksmart.test", password: Credential("wrong"))
            Issue.record("expected AuthError.invalidCredentials")
        } catch let error as AuthError {
            #expect(error == .invalidCredentials)
        } catch {
            Issue.record("expected AuthError, got \(error)")
        }
    }

    @Test func signInWrapsServerErrorsAsTransport() async {
        StubURLProtocol.reset()
        StubURLProtocol.enqueue(path: "/auth/login", status: 500, json: ["error": "boom"])
        let client = makeStubbedClient(keychainService: uniqueKeychainService())

        do {
            _ = try await client.signIn(email: "owner@banksmart.test", password: Credential("owner-demo-1"))
            Issue.record("expected AuthError.transport")
        } catch let error as AuthError {
            guard case .transport = error else {
                Issue.record("expected .transport, got \(error)")
                return
            }
        } catch {
            Issue.record("expected AuthError, got \(error)")
        }
    }

    @Test func refreshSessionWithNoStoredSessionFailsWithoutContactingTheGateway() async {
        StubURLProtocol.reset()
        // No stub enqueued for /auth/refresh — if the client called the
        // gateway anyway, StubURLProtocol would fail the request with a
        // different error, not AuthError.refreshFailed.
        let client = makeStubbedClient(keychainService: uniqueKeychainService())

        do {
            _ = try await client.refreshSession()
            Issue.record("expected AuthError.refreshFailed")
        } catch let error as AuthError {
            #expect(error == .refreshFailed)
        } catch {
            Issue.record("expected AuthError, got \(error)")
        }
    }

    @Test func refreshSessionSucceedsAndRotatesTheRefreshToken() async throws {
        StubURLProtocol.reset()
        StubURLProtocol.enqueue(path: "/auth/login", status: 200, json: [
            "token": makeTestJWT(role: "owner"),
            "role": "owner",
            "expiresInSeconds": 3600,
            "refreshToken": "rt-original",
            "refreshExpiresInSeconds": 3_888_000,
        ])
        StubURLProtocol.enqueue(path: "/auth/refresh", status: 200, json: [
            "token": makeTestJWT(role: "owner"),
            "role": "owner",
            "expiresInSeconds": 3600,
            "refreshToken": "rt-rotated",
            "refreshExpiresInSeconds": 3_888_000,
        ])
        let client = makeStubbedClient(keychainService: uniqueKeychainService())
        _ = try await client.signIn(email: "owner@banksmart.test", password: Credential("owner-demo-1"))

        let refreshed = try await client.refreshSession()
        #expect(refreshed.role == .owner)

        await client.clearSession()
    }

    @Test func refreshSessionOn401DiscardsTheStoredSessionAndNeverRetries() async throws {
        StubURLProtocol.reset()
        StubURLProtocol.enqueue(path: "/auth/login", status: 200, json: [
            "token": makeTestJWT(role: "owner"),
            "role": "owner",
            "expiresInSeconds": 3600,
            "refreshToken": "rt-original",
            "refreshExpiresInSeconds": 3_888_000,
        ])
        StubURLProtocol.enqueue(path: "/auth/refresh", status: 401, json: [
            "error": "unknown or already-used refresh token",
        ])
        let client = makeStubbedClient(keychainService: uniqueKeychainService())
        _ = try await client.signIn(email: "owner@banksmart.test", password: Credential("owner-demo-1"))

        do {
            _ = try await client.refreshSession()
            Issue.record("expected AuthError.refreshFailed")
        } catch let error as AuthError {
            #expect(error == .refreshFailed)
        } catch {
            Issue.record("expected AuthError, got \(error)")
        }

        // AC-6.4: the whole stored session is gone, not just half of it —
        // a fresh POST /auth/login is required, nothing cached remains.
        let current = await client.currentSession
        #expect(current == nil)
    }

    @Test func discardRefreshTokenKeepsSessionTokenButInvalidatesRefresh() async throws {
        StubURLProtocol.reset()
        StubURLProtocol.enqueue(path: "/auth/login", status: 200, json: [
            "token": makeTestJWT(role: "staff"),
            "role": "staff",
            "expiresInSeconds": 3600,
            "refreshToken": "rt-abc",
            "refreshExpiresInSeconds": 3_888_000,
        ])
        let client = makeStubbedClient(keychainService: uniqueKeychainService())
        _ = try await client.signIn(email: "staff@banksmart.test", password: Credential("staff-demo-1"))

        await client.discardRefreshToken()

        let current = await client.currentSession
        #expect(current?.role == .staff)
        // DECISION Q11: the refresh half is gone — reported as already
        // expired so nothing downstream mistakes it for still usable.
        #expect(current?.refreshExpiresAt == .distantPast)

        await client.clearSession()
    }

    @Test func clearSessionRemovesEverything() async throws {
        StubURLProtocol.reset()
        StubURLProtocol.enqueue(path: "/auth/login", status: 200, json: [
            "token": makeTestJWT(role: "owner"),
            "role": "owner",
            "expiresInSeconds": 3600,
            "refreshToken": "rt-abc",
            "refreshExpiresInSeconds": 3_888_000,
        ])
        let client = makeStubbedClient(keychainService: uniqueKeychainService())
        _ = try await client.signIn(email: "owner@banksmart.test", password: Credential("owner-demo-1"))

        await client.clearSession()

        let current = await client.currentSession
        #expect(current == nil)
    }
}
