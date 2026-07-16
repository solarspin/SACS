import Foundation

/// Persists which of the three `BiometricEnrollmentChoice` states this
/// device is in. Not sensitive data (S1) — it's a UI preference, not a
/// credential or token.
public actor LiveBiometricEnrollmentPreferenceStoring: BiometricEnrollmentPreferenceStoring {
    private let defaults: UserDefaults
    private let key: String

    public init(
        defaults: UserDefaults = .standard,
        key: String = "com.banksmartai.auth.biometricEnrollmentChoice"
    ) {
        self.defaults = defaults
        self.key = key
    }

    public var choice: BiometricEnrollmentChoice {
        get async {
            switch defaults.string(forKey: key) {
            case "enrolled": return .enrolled
            case "declined": return .declined
            default: return .notYetOffered
            }
        }
    }

    public func recordEnrolled() async {
        defaults.set("enrolled", forKey: key)
    }

    public func recordDeclined() async {
        defaults.set("declined", forKey: key)
    }
}
