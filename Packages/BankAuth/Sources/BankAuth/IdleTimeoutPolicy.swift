/// Tracks the Story 2 idle timeout: 300 seconds (DECISION Q1). Once
/// elapsed, returning from background (AC-2.1) or cold-launching
/// (AC-2.4) both require a fresh biometric gate before any signed-in
/// content shows — the app never re-authenticates silently.
///
/// Owned by: BankAuth. Not exposed to any other package.
public protocol IdleTimeoutPolicy: Sendable {
    /// Marks "now" as the last known active/foregrounded moment.
    func recordActive() async

    /// True once 300 seconds have elapsed since the last recorded
    /// active moment (AC-2.1). A conformance with no active moment on
    /// record yet (i.e. cold launch) must also return true — AC-2.4
    /// requires cold launch to gate exactly as return-from-background,
    /// never to skip the gate because "nothing has gone idle yet."
    var idleTimeoutElapsed: Bool { get async }
}
