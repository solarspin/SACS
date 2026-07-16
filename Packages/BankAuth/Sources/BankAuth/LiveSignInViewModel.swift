import Foundation
import Observation
import BankCore
import BankNetworking

/// What the caller (a coordinator/App composition root — outside this
/// package's contracted surface) should do once `signIn()` completes.
/// `SignInViewModeling` itself has no such signal; this is additive,
/// concrete-class-only API, not a substitute for a missing contract —
/// see this assignment's SELF-REPORT.
public enum SignInOutcome: Equatable, Sendable {
    case none
    case offerBiometricEnrollment
    case signedIn(Role)
}

@Observable
@MainActor
public final class LiveSignInViewModel: SignInViewModeling {
    public var email: String = ""
    public var password: String = ""
    public private(set) var isSubmitting = false
    public private(set) var errorMessage: String?
    public private(set) var outcome: SignInOutcome = .none

    private let sessionRepository: AuthSessionRepository
    private let reentryRepository: ReentryGateRepository

    public init(sessionRepository: AuthSessionRepository, reentryRepository: ReentryGateRepository) {
        self.sessionRepository = sessionRepository
        self.reentryRepository = reentryRepository
    }

    public func signIn() async {
        isSubmitting = true
        errorMessage = nil
        outcome = .none
        defer { isSubmitting = false }

        let credential = Credential(password)
        do {
            let role = try await sessionRepository.signIn(email: email, password: credential)
            password = ""

            // AC-8.1: offer Story 8's opt-in exactly when no choice has
            // been recorded yet and the device is even capable of it —
            // a declined or already-enrolled choice, or a Story 7
            // device, goes straight to the landing state instead.
            let capable = await reentryRepository.biometricCapable
            let choice = await reentryRepository.enrollmentChoice
            if capable, choice == .notYetOffered {
                outcome = .offerBiometricEnrollment
            } else {
                outcome = .signedIn(role)
            }
        } catch AuthError.invalidCredentials {
            // AC-1.3: a visible failure, never swallowed (S7). The 401
            // already counted toward Story 4's lockout window inside
            // AuthSessionRepository.signIn.
            errorMessage = "Incorrect email or password."
        } catch {
            errorMessage = "Couldn't sign in. Check your connection and try again."
        }
    }
}
