/// Whether this device can present a biometric/passcode re-entry gate
/// at all (Story 7).
///
/// Owned by: BankAuth. Not exposed to any other package.
public enum BiometricCapability: Equatable, Sendable {
    /// No biometric hardware, no biometrics enrolled at the OS level,
    /// or no device passcode set (AC-7.1). Re-entry must use
    /// `AuthSessionRepository.signIn`, never a biometric prompt.
    case unavailable
    case available
}

/// Owned by: BankAuth. Not exposed to any other package.
public protocol BiometricCapabilityChecking: Sendable {
    var capability: BiometricCapability { get async }
}
