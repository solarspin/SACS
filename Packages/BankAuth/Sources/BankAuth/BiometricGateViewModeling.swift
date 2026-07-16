/// The re-entry gate's view model contract — covers Story 2's biometric
/// gate, Story 3's passcode fallback, and Story 4's locked-out state,
/// since all three are one screen's worth of state (`SessionPhase`).
///
/// Owned by: BankAuth. Consumed by: the re-entry gate view only.
@MainActor
public protocol BiometricGateViewModeling: AnyObject {
    var phase: SessionPhase { get }

    /// Non-nil only in `.lockedOut` — the visible, never-silent
    /// explanation that biometric entry is disabled and a fresh email +
    /// password sign-in is required (AC-4.2).
    var lockedOutMessage: String? { get }

    /// Runs on return-from-background and on cold launch alike (AC-2.1,
    /// AC-2.4). Evaluates `ReentryGateRepository` in the precedence
    /// order fixed by `SessionPhase`'s documentation: lockout, then
    /// session validity, then idle timeout / capability, then gate.
    /// Never re-authenticates silently — a `.awaitingBiometricGate`
    /// phase always means a prompt is about to show or has just failed,
    /// never a background retry.
    func presentGateIfNeeded() async
}
