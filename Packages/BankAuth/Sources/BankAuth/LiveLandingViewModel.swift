import Observation
import BankCore

/// A simple, caller-supplied data holder — `LandingViewModeling` has no
/// methods, only properties, so whoever constructs this (the App
/// composition root) is responsible for resolving `role` (from
/// `AuthSessionRepository.currentRole`) before creating it. See this
/// assignment's SELF-REPORT for why `signedInEmail` has no reliable
/// source in the current contracts.
@Observable
@MainActor
public final class LiveLandingViewModel: LandingViewModeling {
    public let role: Role?
    public let signedInEmail: String?

    public init(role: Role?, signedInEmail: String? = nil) {
        self.role = role
        self.signedInEmail = signedInEmail
    }
}
