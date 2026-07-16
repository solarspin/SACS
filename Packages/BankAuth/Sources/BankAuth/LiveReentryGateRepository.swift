import Foundation
import BankCore
import BankNetworking

public actor LiveReentryGateRepository: ReentryGateRepository {
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
                    // back to a fresh sign-in.
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
}
