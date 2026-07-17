import Foundation
import BankCore
import BankNetworking
import os

public actor LiveReentryGateRepository: ReentryGateRepository {
    private static let logger = Logger(subsystem: "com.banksmartai.BankAuth", category: "Auth")

    private let gatewayClient: AuthGatewayClient
    private let capabilityChecker: BiometricCapabilityChecking
    private let gating: BiometricGating
    private let idleTimeoutPolicy: IdleTimeoutPolicy
    private let lockoutPolicy: LockoutPolicy
    private let enrollmentPreference: BiometricEnrollmentPreferenceStoring

    init(
        gatewayClient: AuthGatewayClient,
        capabilityChecker: BiometricCapabilityChecking,
        gating: BiometricGating,
        idleTimeoutPolicy: IdleTimeoutPolicy,
        lockoutPolicy: LockoutPolicy,
        enrollmentPreference: BiometricEnrollmentPreferenceStoring
    ) {
        self.gatewayClient = gatewayClient
        self.capabilityChecker = capabilityChecker
        self.gating = gating
        self.idleTimeoutPolicy = idleTimeoutPolicy
        self.lockoutPolicy = lockoutPolicy
        self.enrollmentPreference = enrollmentPreference
    }

    /// `BiometricGating` is package-internal, so this initializer (the
    /// only one that can supply it) is too — public callers use
    /// `LiveReentryGateRepository.live(...)` instead.
    public static func live(
        gatewayClient: AuthGatewayClient,
        capabilityChecker: BiometricCapabilityChecking = LiveBiometricCapabilityChecking(),
        idleTimeoutPolicy: IdleTimeoutPolicy,
        lockoutPolicy: LockoutPolicy,
        enrollmentPreference: BiometricEnrollmentPreferenceStoring
    ) -> LiveReentryGateRepository {
        LiveReentryGateRepository(
            gatewayClient: gatewayClient,
            capabilityChecker: capabilityChecker,
            gating: LiveBiometricGating(),
            idleTimeoutPolicy: idleTimeoutPolicy,
            lockoutPolicy: lockoutPolicy,
            enrollmentPreference: enrollmentPreference
        )
    }

    public var biometricCapable: Bool {
        get async { await capabilityChecker.capability == .available }
    }

    public var biometricGateRequired: Bool {
        get async { await idleTimeoutPolicy.idleTimeoutElapsed }
    }

    public var isLockedOut: Bool {
        get async { await lockoutPolicy.isLockedOut }
    }

    public func presentBiometricGate() async -> BiometricGateOutcome {
        let outcome = await gating.evaluate()
        switch outcome {
        case .success:
            await idleTimeoutPolicy.recordActive()
            if let session = await gatewayClient.currentSession, session.expiresAt > Date() {
                // AC-2.3: still within its stated expiry — reuse as-is,
                // no network call.
            } else {
                do {
                    _ = try await gatewayClient.refreshSession()
                } catch {
                    // AC-6.4/6.5, DECISION Q9: a failed refresh here is
                    // not a biometric or passcode failure and must not
                    // be recorded via LockoutPolicy. The biometric
                    // prompt itself did succeed (what `.success`
                    // reports); whether a valid session now exists is a
                    // separate question — AuthSessionRepository.currentRole
                    // will correctly report `nil`, routing the caller
                    // back to a fresh sign-in. Logged (not silent) so a
                    // future edit to either method can't lose this
                    // outcome without a local signal — no token or
                    // credential in the message (S9). Logs a fixed
                    // category string, never the raw error description:
                    // AppError.serverError/.unknown carry gateway-
                    // supplied text that this app doesn't control, and
                    // a `.public` log line must stay within a bounded,
                    // client-defined content space regardless of what a
                    // future gateway response might contain.
                    Self.logger.debug("presentBiometricGate: refreshSession failed after a successful gate — \(Self.logCategory(for: error), privacy: .public)")
                }
            }
        case .failed(let kind):
            await lockoutPolicy.recordFailure(kind)
        case .canceled:
            break
        }
        return outcome
    }

    public var enrollmentChoice: BiometricEnrollmentChoice {
        get async { await enrollmentPreference.choice }
    }

    public func acceptBiometricEnrollment() async {
        await enrollmentPreference.recordEnrolled()
    }

    public func declineBiometricEnrollment() async {
        await enrollmentPreference.recordDeclined()
        // DECISION Q11: an unguarded refresh token must not persist
        // once biometric re-entry is declined.
        await gatewayClient.discardRefreshToken()
    }

    /// A closed switch over every known `AuthError`/`AppError` case,
    /// returning only fixed, client-defined strings — never an
    /// associated message. `refreshSession()` only ever throws
    /// `AuthError` (see `AuthGatewayClient`'s doc comment), so `nil`
    /// below should be unreachable in practice; it's kept only so this
    /// switch stays exhaustive and safe against a future error type
    /// this method doesn't yet know about.
    private static func logCategory(for error: Error) -> String {
        guard let authError = error as? AuthError else {
            return "unknownErrorType"
        }
        switch authError {
        case .invalidCredentials:
            return "invalidCredentials"
        case .refreshFailed:
            return "refreshFailed"
        case .transport(let appError):
            switch appError {
            case .offline:
                return "transport-offline"
            case .timeout:
                return "transport-timeout"
            case .serverUnreachable:
                return "transport-serverUnreachable"
            case .unauthorized:
                return "transport-unauthorized"
            case .forbidden:
                return "transport-forbidden"
            case .serverError:
                return "transport-serverError"
            case .decoding:
                return "transport-decoding"
            case .unknown:
                return "transport-unknown"
            }
        }
    }
}
