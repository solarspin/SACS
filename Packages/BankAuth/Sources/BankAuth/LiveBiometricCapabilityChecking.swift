import LocalAuthentication

/// `canEvaluatePolicy(.deviceOwnerAuthentication, error:)` returns
/// `false` precisely when there is no biometric hardware, no biometrics
/// enrolled, AND no device passcode set — the exact three conditions
/// AC-7.1 names for `.unavailable`.
public struct LiveBiometricCapabilityChecking: BiometricCapabilityChecking {
    public init() {}

    public var capability: BiometricCapability {
        get async {
            var error: NSError?
            let canEvaluate = LAContext().canEvaluatePolicy(.deviceOwnerAuthentication, error: &error)
            return canEvaluate ? .available : .unavailable
        }
    }
}
