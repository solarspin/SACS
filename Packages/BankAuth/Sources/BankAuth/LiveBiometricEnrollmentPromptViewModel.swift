import Observation

@Observable
@MainActor
public final class LiveBiometricEnrollmentPromptViewModel: BiometricEnrollmentPromptViewModeling {
    private let reentryRepository: ReentryGateRepository

    public init(reentryRepository: ReentryGateRepository) {
        self.reentryRepository = reentryRepository
    }

    public func accept() async {
        await reentryRepository.acceptBiometricEnrollment()
    }

    public func decline() async {
        // DECISION Q11: discarding the refresh token happens inside
        // ReentryGateRepository.declineBiometricEnrollment itself.
        await reentryRepository.declineBiometricEnrollment()
    }
}
