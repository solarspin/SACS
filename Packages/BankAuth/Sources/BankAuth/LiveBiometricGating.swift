import LocalAuthentication

/// Uses `.deviceOwnerAuthentication` — the OS bundles biometric and
/// passcode fallback into ONE evaluation (Face ID/Touch ID first, then
/// the system's own passcode sheet after failures) and returns a single
/// final result. This is deliberate, not a shortcut: Story 3 requires
/// the OS's own fallback sheet, never a custom PIN UI, and
/// `.deviceOwnerAuthentication` is the only LocalAuthentication policy
/// that presents it.
///
/// Not `public`: `BiometricGating` itself is package-internal (see its
/// own doc comment) — only `LiveReentryGateRepository` may reach this.
struct LiveBiometricGating: BiometricGating {
    private let localizedReason: String

    init(localizedReason: String = "Sign back in to BankSmartAI") {
        self.localizedReason = localizedReason
    }

    func evaluate() async -> BiometricGateOutcome {
        let context = LAContext()
        do {
            let success = try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: localizedReason)
            return success ? .success : .failed(.biometricMismatch)
        } catch let error as LAError {
            switch error.code {
            case .userCancel, .systemCancel, .appCancel:
                return .canceled
            default:
                // The OS does not expose which sub-mechanism (biometric
                // vs. passcode) actually failed for a single
                // .deviceOwnerAuthentication evaluation — see this
                // assignment's SELF-REPORT. Both AuthFailureKind cases
                // count identically toward Story 4's lockout window
                // (AC-3.3), so this default has no behavioral effect.
                return .failed(.biometricMismatch)
            }
        } catch {
            return .failed(.biometricMismatch)
        }
    }
}
