import BankCore

/// The Story 5 landing state's view model contract. Shows identity and
/// role and nothing else (AC-5.4, DECISION Q3) — no account data,
/// balance, or navigation affordance toward money-movement screens
/// exists on this contract because none may be reachable in Sprint 1.
///
/// Owned by: BankAuth. Consumed by: the landing view only.
@MainActor
public protocol LandingViewModeling: AnyObject {
    /// Sourced only from `AuthSessionRepository.currentRole`, itself
    /// sourced only from the JWT claim — never a second stored copy
    /// (AC-5.3, AC-1.5).
    var role: Role? { get }
    var signedInEmail: String? { get }
}
