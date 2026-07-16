import BankCore

/// The sign-in screen's view model contract (Story 1). `@MainActor` per
/// `architecture/PLAN.md`'s layer rule — async/await only, no completion
/// handlers.
///
/// Owned by: BankAuth. Consumed by: the sign-in view only (views observe
/// view models, never call repositories directly).
@MainActor
public protocol SignInViewModeling: AnyObject {
    var email: String { get set }
    /// A plain `String` deliberately: this is the one place a password
    /// legitimately stays raw, because it is bound directly to SwiftUI's
    /// `SecureField`. `signIn()` must wrap it in a `Credential` (BankCore)
    /// at the call into `AuthSessionRepository` — nothing past that
    /// point in the app may see the raw `String` again.
    var password: String { get set }
    var isSubmitting: Bool { get }
    /// Non-nil after a 401 (AC-1.3) — the failure is surfaced visibly,
    /// never swallowed (S7).
    var errorMessage: String? { get }

    /// Calls `AuthSessionRepository.signIn`. On success: if
    /// `ReentryGateRepository.enrollmentChoice` is `.notYetOffered` and
    /// `biometricCapable` is true, the caller must present Story 8's
    /// enrollment offer before any signed-in content shows (AC-8.1) —
    /// on a Story 7 device, or once a choice is already recorded, it
    /// goes straight to the Story 5 landing state.
    func signIn() async
}
