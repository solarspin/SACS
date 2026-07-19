// QA Agent — Sprint 1 (sprint-1-front-door).
// Story 1 (sign-in establishes a session) and Story 6 (sessions expire
// honestly; refresh never replays a password), tested against
// `LiveAuthSessionRepository`'s public interface only.
//
// Source of every assertion: requirements/sprint-1-front-door-stories.md
// and Packages/BankAuth/Sources/BankAuth/AuthSessionRepository.swift's
// doc comments (the signed contract) — never the implementation.

import Testing
import Foundation
import BankCore
import BankNetworking
import BankAuth

@Suite("QA Story 1 & 6 — AuthSessionRepository")
struct QAAuthSessionRepositoryTests {

    // AC-1.1 / AC-1.2: a successful sign-in returns the decoded role.
    @Test("AC-1.1: owner credentials decode to the owner role")
    func ownerSignInReturnsOwnerRole() async throws {
        let session = AuthSession(role: .owner, expiresAt: .distantFuture, refreshExpiresAt: .distantFuture)
        let gateway = QAFakeAuthGatewayClient(signInResult: .success(session))
        let repo = LiveAuthSessionRepository(gatewayClient: gateway, lockoutPolicy: QAFakeLockoutPolicy())

        let role = try await repo.signIn(email: "owner@banksmart.test", password: Credential("owner-demo-1"))

        #expect(role == .owner)
    }

    @Test("AC-1.2: staff credentials decode to the staff role")
    func staffSignInReturnsStaffRole() async throws {
        let session = AuthSession(role: .staff, expiresAt: .distantFuture, refreshExpiresAt: .distantFuture)
        let gateway = QAFakeAuthGatewayClient(signInResult: .success(session))
        let repo = LiveAuthSessionRepository(gatewayClient: gateway, lockoutPolicy: QAFakeLockoutPolicy())

        let role = try await repo.signIn(email: "staff@banksmart.test", password: Credential("staff-demo-1"))

        #expect(role == .staff)
    }

    // AC-4.3 / DECISION Q6: a successful login resets the lockout window.
    @Test("AC-4.3/Q6: a successful sign-in resets the shared LockoutPolicy")
    func successfulSignInResetsLockoutPolicy() async throws {
        let session = AuthSession(role: .owner, expiresAt: .distantFuture, refreshExpiresAt: .distantFuture)
        let gateway = QAFakeAuthGatewayClient(signInResult: .success(session))
        let lockout = QAFakeLockoutPolicy()
        let repo = LiveAuthSessionRepository(gatewayClient: gateway, lockoutPolicy: lockout)

        _ = try await repo.signIn(email: "owner@banksmart.test", password: Credential("owner-demo-1"))

        #expect(await lockout.resetCallCount == 1)
    }

    // AC-1.3 / DECISION Q5: a 401 is rethrown (never swallowed, S7) and
    // counts toward the Story 4 lockout window as invalidLoginCredentials.
    @Test("AC-1.3/Q5: invalid credentials rethrow and record a lockout failure")
    func invalidCredentialsRethrowAndRecordFailure() async {
        let gateway = QAFakeAuthGatewayClient(signInResult: .failure(.invalidCredentials))
        let lockout = QAFakeLockoutPolicy()
        let repo = LiveAuthSessionRepository(gatewayClient: gateway, lockoutPolicy: lockout)

        do {
            _ = try await repo.signIn(email: "owner@banksmart.test", password: Credential("wrong-password"))
            Issue.record("expected AuthError.invalidCredentials to be thrown")
        } catch let error as AuthError {
            #expect(error == .invalidCredentials)
        } catch {
            Issue.record("unexpected error type: \(error)")
        }

        #expect(await lockout.recordedFailures == [.invalidLoginCredentials])
        #expect(await lockout.resetCallCount == 0)
    }

    // AC-6.2/6.3: refreshSession wraps AuthGatewayClient.refreshSession and
    // returns the freshly decoded role on success.
    @Test("AC-6.2/6.3: a successful refresh returns the new session's role")
    func successfulRefreshReturnsRole() async throws {
        let session = AuthSession(role: .staff, expiresAt: .distantFuture, refreshExpiresAt: .distantFuture)
        let gateway = QAFakeAuthGatewayClient(refreshResult: .success(session))
        let repo = LiveAuthSessionRepository(gatewayClient: gateway, lockoutPolicy: QAFakeLockoutPolicy())

        let role = try await repo.refreshSession()

        #expect(role == .staff)
    }

    // AC-6.4/6.5 + DECISION Q9: a refresh failure rethrows but must NEVER
    // be recorded toward the Story 4 lockout window — it is a
    // stale/stolen-token signal, not a wrong-credentials guess.
    @Test("AC-6.4/6.5 + Q9: a refresh failure rethrows and never touches the lockout window")
    func refreshFailureNeverRecordsLockoutFailure() async {
        let gateway = QAFakeAuthGatewayClient(refreshResult: .failure(.refreshFailed))
        let lockout = QAFakeLockoutPolicy()
        let repo = LiveAuthSessionRepository(gatewayClient: gateway, lockoutPolicy: lockout)

        do {
            _ = try await repo.refreshSession()
            Issue.record("expected AuthError.refreshFailed to be thrown")
        } catch let error as AuthError {
            #expect(error == .refreshFailed)
        } catch {
            Issue.record("unexpected error type: \(error)")
        }

        #expect(await lockout.recordedFailures.isEmpty)
    }

    // AC-2.3/AC-6.1: currentRole reflects the current, still-valid session
    // with no network call — nil if there is none.
    @Test("AC-2.3/6.1: currentRole is nil when there is no stored session")
    func currentRoleIsNilWithNoSession() async {
        let gateway = QAFakeAuthGatewayClient(currentSession: nil)
        let repo = LiveAuthSessionRepository(gatewayClient: gateway, lockoutPolicy: QAFakeLockoutPolicy())

        #expect(await repo.currentRole == nil)
        #expect(await gateway.signInCallCount == 0)
        #expect(await gateway.refreshCallCount == 0)
    }

    @Test("AC-2.3: currentRole reflects an unexpired stored session")
    func currentRoleReflectsUnexpiredSession() async {
        let session = AuthSession(
            role: .owner,
            expiresAt: Date().addingTimeInterval(3600),
            refreshExpiresAt: .distantFuture
        )
        let gateway = QAFakeAuthGatewayClient(currentSession: session)
        let repo = LiveAuthSessionRepository(gatewayClient: gateway, lockoutPolicy: QAFakeLockoutPolicy())

        #expect(await repo.currentRole == .owner)
    }

    // AC-6.1: "the app never presents that token to the gateway again and
    // never shows signed-in content on its basis" once 3600s have elapsed —
    // the contract doc for currentRole is explicit: "nil if there is none
    // or it has expired."
    @Test("AC-6.1: currentRole is nil once the stored session has expired")
    func currentRoleIsNilForExpiredSession() async {
        let expiredSession = AuthSession(
            role: .owner,
            expiresAt: Date().addingTimeInterval(-1),
            refreshExpiresAt: .distantFuture
        )
        let gateway = QAFakeAuthGatewayClient(currentSession: expiredSession)
        let repo = LiveAuthSessionRepository(gatewayClient: gateway, lockoutPolicy: QAFakeLockoutPolicy())

        #expect(await repo.currentRole == nil)
    }
}
