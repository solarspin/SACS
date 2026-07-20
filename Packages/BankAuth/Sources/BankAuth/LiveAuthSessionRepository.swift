import Foundation
import BankCore
import BankNetworking

public actor LiveAuthSessionRepository: AuthSessionRepository {
    private let gatewayClient: AuthGatewayClient
    private let lockoutPolicy: LockoutPolicy

    public init(gatewayClient: AuthGatewayClient, lockoutPolicy: LockoutPolicy) {
        self.gatewayClient = gatewayClient
        self.lockoutPolicy = lockoutPolicy
    }

    public func signIn(email: String, password: Credential) async throws -> Role {
        do {
            let session = try await gatewayClient.signIn(email: email, password: password)
            await lockoutPolicy.reset()
            return session.role
        } catch AuthError.invalidCredentials {
            // DECISION Q5: every failed login 401 counts toward Story
            // 4's combined lockout window.
            await lockoutPolicy.recordFailure(.invalidLoginCredentials)
            throw AuthError.invalidCredentials
        }
        // Any other thrown error (AuthError.transport, etc.) propagates
        // untouched — only a wrong-credentials 401 is a lockout failure.
    }

    public func refreshSession() async throws -> Role {
        // DECISION Q9: refresh failures never reach LockoutPolicy —
        // nothing to record here regardless of outcome.
        let session = try await gatewayClient.refreshSession()
        return session.role
    }

    public var currentRole: Role? {
        get async {
            guard
                let session = await gatewayClient.currentSession,
                session.expiresAt > Date()
            else {
                return nil
            }
            return session.role
        }
    }

    public func signOut() async {
        await gatewayClient.clearSession()
    }
}
