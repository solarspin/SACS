import BankCore

/// The app-wide phase driving what a user can see. Precedence is fixed
/// and must be evaluated in this order — a later check never overrides
/// an earlier one:
///
/// 1. `LockoutPolicy.isLockedOut` → `.lockedOut`, regardless of idle
///    timeout or token validity (AC-4.4: no cached token grants entry
///    while locked out).
/// 2. No valid `AuthGatewayClient.currentSession` → `.signedOut`.
/// 3. A valid session, `IdleTimeoutPolicy.idleTimeoutElapsed` (true on
///    cold launch per AC-2.4) or `BiometricGateOutcome` not yet
///    satisfied this launch → `.awaitingBiometricGate`.
/// 4. Otherwise → `.signedIn`.
///
/// Owned by: BankAuth. Not exposed to any other package.
public enum SessionPhase: Equatable, Sendable {
    case signedOut
    case awaitingBiometricGate(role: Role)
    case signedIn(role: Role)
    case lockedOut
}
