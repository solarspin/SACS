import Foundation
import BankCore
import BankNetworking
@testable import BankAuth

actor FakeAuthGatewayClient: AuthGatewayClient {
    enum StubResult {
        case success(AuthSession)
        case failure(AuthError)
    }

    var signInResult: StubResult = .failure(.invalidCredentials)
    var refreshResult: StubResult = .failure(.refreshFailed)
    var storedSession: AuthSession?

    private(set) var refreshCallCount = 0
    private(set) var discardCallCount = 0
    private(set) var clearCallCount = 0

    func signIn(email: String, password: Credential) async throws -> AuthSession {
        switch signInResult {
        case .success(let session):
            storedSession = session
            return session
        case .failure(let error):
            throw error
        }
    }

    func refreshSession() async throws -> AuthSession {
        refreshCallCount += 1
        switch refreshResult {
        case .success(let session):
            storedSession = session
            return session
        case .failure(let error):
            throw error
        }
    }

    func discardRefreshToken() async {
        discardCallCount += 1
    }

    func clearSession() async {
        clearCallCount += 1
        storedSession = nil
    }

    func setSignInResult(_ result: StubResult) {
        signInResult = result
    }

    func setRefreshResult(_ result: StubResult) {
        refreshResult = result
    }

    func setStoredSession(_ session: AuthSession?) {
        storedSession = session
    }

    var currentSession: AuthSession? {
        get async { storedSession }
    }
}

actor FakeLockoutPolicy: LockoutPolicy {
    private(set) var recordedFailures: [AuthFailureKind] = []
    private(set) var resetCallCount = 0
    var isLockedOutValue = false

    func recordFailure(_ kind: AuthFailureKind) async {
        recordedFailures.append(kind)
    }

    var isLockedOut: Bool {
        get async { isLockedOutValue }
    }

    func reset() async {
        resetCallCount += 1
        recordedFailures = []
    }
}

actor FakeIdleTimeoutPolicy: IdleTimeoutPolicy {
    var elapsed = true
    private(set) var recordActiveCallCount = 0

    func recordActive() async {
        recordActiveCallCount += 1
    }

    var idleTimeoutElapsed: Bool {
        get async { elapsed }
    }
}

struct FakeBiometricCapabilityChecking: BiometricCapabilityChecking {
    let value: BiometricCapability
    var capability: BiometricCapability {
        get async { value }
    }
}

actor FakeBiometricGating: BiometricGating {
    var outcome: BiometricGateOutcome = .success

    func setOutcome(_ outcome: BiometricGateOutcome) {
        self.outcome = outcome
    }

    func evaluate() async -> BiometricGateOutcome {
        outcome
    }
}

actor FakeBiometricEnrollmentPreferenceStoring: BiometricEnrollmentPreferenceStoring {
    var choiceValue: BiometricEnrollmentChoice = .notYetOffered
    private(set) var enrolledCallCount = 0
    private(set) var declinedCallCount = 0

    var choice: BiometricEnrollmentChoice {
        get async { choiceValue }
    }

    func recordEnrolled() async {
        enrolledCallCount += 1
        choiceValue = .enrolled
    }

    func recordDeclined() async {
        declinedCallCount += 1
        choiceValue = .declined
    }
}

/// A plain class, not an actor: the `LiveBiometricGateViewModel` tests
/// that use this need synchronous property mutation between calls to
/// `presentGateIfNeeded()` to model a session changing mid-flow.
/// `@unchecked Sendable` is safe here because these tests only ever
/// touch it from the suite's single `@MainActor` context.
final class FakeAuthSessionRepository: AuthSessionRepository, @unchecked Sendable {
    var roleValue: Role?

    func signIn(email: String, password: Credential) async throws -> Role {
        fatalError("not exercised by these tests")
    }

    func refreshSession() async throws -> Role {
        fatalError("not exercised by these tests")
    }

    var currentRole: Role? {
        get async { roleValue }
    }
}

/// See `FakeAuthSessionRepository`'s note on why this is a class, not
/// an actor.
final class FakeReentryGateRepository: ReentryGateRepository, @unchecked Sendable {
    var capable = true
    var gateRequired = true
    var lockedOut = false
    var gateOutcome: BiometricGateOutcome = .success
    var choiceValue: BiometricEnrollmentChoice = .notYetOffered
    private(set) var presentCallCount = 0
    private(set) var acceptCallCount = 0
    private(set) var declineCallCount = 0
    /// Lets a test simulate a side effect happening as a direct
    /// consequence of the gate running — e.g. a session becoming
    /// unrecoverable because its refresh failed.
    var onPresent: (() -> Void)?

    var biometricCapable: Bool {
        get async { capable }
    }

    var biometricGateRequired: Bool {
        get async { gateRequired }
    }

    var isLockedOut: Bool {
        get async { lockedOut }
    }

    func presentBiometricGate() async -> BiometricGateOutcome {
        presentCallCount += 1
        onPresent?()
        return gateOutcome
    }

    var enrollmentChoice: BiometricEnrollmentChoice {
        get async { choiceValue }
    }

    func acceptBiometricEnrollment() async {
        acceptCallCount += 1
        choiceValue = .enrolled
    }

    func declineBiometricEnrollment() async {
        declineCallCount += 1
        choiceValue = .declined
    }
}

func makeSession(role: Role, expiresIn: TimeInterval = 3600) -> AuthSession {
    AuthSession(
        role: role,
        expiresAt: Date().addingTimeInterval(expiresIn),
        refreshExpiresAt: Date().addingTimeInterval(3_888_000)
    )
}
