import Testing
import Foundation
import BankCore
import BankNetworking
@testable import BankAuth

@Suite
struct LiveAuthSessionRepositoryTests {
    @Test func signInSuccessResetsLockoutAndReturnsRole() async throws {
        let gateway = FakeAuthGatewayClient()
        await gateway.setSignInResult(.success(makeSession(role: .owner)))
        let lockout = FakeLockoutPolicy()
        let repository = LiveAuthSessionRepository(gatewayClient: gateway, lockoutPolicy: lockout)

        let role = try await repository.signIn(email: "owner@banksmart.test", password: Credential("owner-demo-1"))

        #expect(role == .owner)
        #expect(await lockout.resetCallCount == 1)
        #expect(await lockout.recordedFailures.isEmpty)
    }

    @Test func signInInvalidCredentialsRecordsLockoutFailureAndRethrows() async {
        let gateway = FakeAuthGatewayClient()
        await gateway.setSignInResult(.failure(.invalidCredentials))
        let lockout = FakeLockoutPolicy()
        let repository = LiveAuthSessionRepository(gatewayClient: gateway, lockoutPolicy: lockout)

        do {
            _ = try await repository.signIn(email: "x@banksmart.test", password: Credential("wrong"))
            Issue.record("expected AuthError.invalidCredentials")
        } catch let error as AuthError {
            #expect(error == .invalidCredentials)
        } catch {
            Issue.record("expected AuthError, got \(error)")
        }
        #expect(await lockout.recordedFailures == [.invalidLoginCredentials])
    }

    @Test func signInTransportFailureDoesNotRecordLockoutFailure() async {
        let gateway = FakeAuthGatewayClient()
        await gateway.setSignInResult(.failure(.transport(.offline)))
        let lockout = FakeLockoutPolicy()
        let repository = LiveAuthSessionRepository(gatewayClient: gateway, lockoutPolicy: lockout)

        do {
            _ = try await repository.signIn(email: "x@banksmart.test", password: Credential("whatever"))
            Issue.record("expected AuthError.transport")
        } catch let error as AuthError {
            guard case .transport = error else {
                Issue.record("expected .transport, got \(error)")
                return
            }
        } catch {
            Issue.record("expected AuthError, got \(error)")
        }
        #expect(await lockout.recordedFailures.isEmpty)
    }

    @Test func refreshFailureNeverRecordsLockoutFailure() async {
        // DECISION Q9.
        let gateway = FakeAuthGatewayClient()
        await gateway.setRefreshResult(.failure(.refreshFailed))
        let lockout = FakeLockoutPolicy()
        let repository = LiveAuthSessionRepository(gatewayClient: gateway, lockoutPolicy: lockout)

        do {
            _ = try await repository.refreshSession()
            Issue.record("expected AuthError.refreshFailed")
        } catch let error as AuthError {
            #expect(error == .refreshFailed)
        } catch {
            Issue.record("expected AuthError, got \(error)")
        }
        #expect(await lockout.recordedFailures.isEmpty)
    }

    @Test func currentRoleIsNilWithNoSession() async {
        let gateway = FakeAuthGatewayClient()
        let repository = LiveAuthSessionRepository(gatewayClient: gateway, lockoutPolicy: FakeLockoutPolicy())
        #expect(await repository.currentRole == nil)
    }

    @Test func currentRoleIsNilOnceExpired() async {
        let gateway = FakeAuthGatewayClient()
        await gateway.setStoredSession(makeSession(role: .staff, expiresIn: -1))
        let repository = LiveAuthSessionRepository(gatewayClient: gateway, lockoutPolicy: FakeLockoutPolicy())
        #expect(await repository.currentRole == nil)
    }

    @Test func currentRoleReflectsAValidSession() async {
        let gateway = FakeAuthGatewayClient()
        await gateway.setStoredSession(makeSession(role: .staff))
        let repository = LiveAuthSessionRepository(gatewayClient: gateway, lockoutPolicy: FakeLockoutPolicy())
        #expect(await repository.currentRole == .staff)
    }
}
