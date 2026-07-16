import Observation
import BankCore

@Observable
@MainActor
public final class LiveBiometricGateViewModel: BiometricGateViewModeling {
    public private(set) var phase: SessionPhase = .signedOut
    public private(set) var lockedOutMessage: String?

    private let sessionRepository: AuthSessionRepository
    private let reentryRepository: ReentryGateRepository

    public init(sessionRepository: AuthSessionRepository, reentryRepository: ReentryGateRepository) {
        self.sessionRepository = sessionRepository
        self.reentryRepository = reentryRepository
    }

    /// Precedence fixed by `SessionPhase`'s own doc comment: lockout,
    /// then session validity, then idle timeout / capability, then the
    /// gate itself. Runs identically on cold launch and
    /// return-from-background (AC-2.1, AC-2.4) — the caller invokes
    /// this the same way in both cases.
    public func presentGateIfNeeded() async {
        if await reentryRepository.isLockedOut {
            enterLockedOut()
            return
        }

        guard let role = await sessionRepository.currentRole else {
            phase = .signedOut
            lockedOutMessage = nil
            return
        }

        guard await reentryRepository.biometricGateRequired else {
            phase = .signedIn(role: role)
            lockedOutMessage = nil
            return
        }

        guard await reentryRepository.biometricCapable else {
            // Story 7: never present a biometric/passcode prompt on an
            // incapable device — fall back to password sign-in.
            phase = .signedOut
            lockedOutMessage = nil
            return
        }

        phase = .awaitingBiometricGate(role: role)
        let outcome = await reentryRepository.presentBiometricGate()

        if await reentryRepository.isLockedOut {
            enterLockedOut()
            return
        }

        switch outcome {
        case .success:
            if let refreshedRole = await sessionRepository.currentRole {
                // AC-2.3/AC-6.2: reuse the still-valid session, or the
                // one `presentBiometricGate()` just refreshed.
                phase = .signedIn(role: refreshedRole)
            } else {
                // AC-6.4/6.5: biometric succeeded but the session
                // couldn't be refreshed — no valid session exists, so a
                // fresh sign-in is required.
                phase = .signedOut
            }
        case .failed, .canceled:
            // AC-2.1: a failed or canceled prompt must never fall
            // through to signed-in content, even if the underlying
            // token is technically still unexpired — only a
            // successful gate does. Not yet locked out (checked
            // above), so remain gated for another attempt.
            phase = .awaitingBiometricGate(role: role)
        }
        lockedOutMessage = nil
    }

    private func enterLockedOut() {
        phase = .lockedOut
        // AC-4.2: a visible, never-silent explanation.
        lockedOutMessage = "Biometric sign-in is disabled after repeated failed attempts. Sign in with your email and password to continue."
    }
}
