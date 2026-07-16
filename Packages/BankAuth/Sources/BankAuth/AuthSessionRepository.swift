import BankCore
import BankNetworking

/// The repository `SignInViewModeling` and `LandingViewModeling` call —
/// per `architecture/PLAN.md`'s layer rule, view models call
/// repositories and never construct URLs or touch tokens themselves.
/// Wraps `AuthGatewayClient` (BankNetworking) and integrates the Story 4
/// lockout window; covers Stories 1, 5, and 6.
///
/// An implementation MUST share its `LockoutPolicy` instance with the
/// `ReentryGateRepository` implementation — see that protocol's note.
///
/// Owned by: BankAuth. May be depended on by: view models within
/// BankAuth only (not exposed outside the package).
public protocol AuthSessionRepository: Sendable {
    /// AC-1.1–1.6. On an `AuthError.invalidCredentials` failure, records
    /// `AuthFailureKind.invalidLoginCredentials` via `LockoutPolicy`
    /// before rethrowing (DECISION Q5) — the 401 is never swallowed
    /// (S7). On success, calls `LockoutPolicy.reset()` (AC-4.3, DECISION
    /// Q6) and returns the decoded role.
    func signIn(email: String, password: Credential) async throws -> Role

    /// AC-6.2–6.5. Wraps `AuthGatewayClient.refreshSession()`. Never
    /// records a lockout failure on any `AuthError.refreshFailed`
    /// (DECISION Q9) — the caller must fall back to `signIn`.
    func refreshSession() async throws -> Role

    /// AC-2.3, AC-6.1: the role of the current, still-valid session
    /// without any network call — `nil` if there is none or it has
    /// expired.
    var currentRole: Role? { get async }
}
