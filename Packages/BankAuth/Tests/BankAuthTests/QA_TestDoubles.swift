// QA Agent — Sprint 1 (sprint-1-front-door) evidence package.
//
// These doubles are written independently of the Feature Engineer's own
// `TestDoubles.swift` in this same target: the QA Agent's first rule is
// that it never reads `Sources/BankAuth/Live*.swift`, so nothing here was
// shaped by looking at how the implementation happens to call its
// collaborators. Every method here exists because a public protocol
// (`AuthSessionRepository`, `ReentryGateRepository`, `LockoutPolicy`,
// `IdleTimeoutPolicy`, `BiometricCapabilityChecking`,
// `BiometricEnrollmentPreferenceStoring`, `AuthGatewayClient`) requires it.
//
// All QA-authored symbols are prefixed `QAFake…` to avoid colliding with
// the Feature Engineer's `Fake…` types compiled into the same test module.
// This file also deliberately does NOT `@testable import BankAuth` —
// every test built on these doubles exercises only the genuinely public
// interface, per the ASSIGNMENT's "public interface, not that diff".

import Foundation
import BankCore
import BankNetworking
import BankAuth

// MARK: - AuthGatewayClient (BankNetworking, public protocol)

actor QAFakeAuthGatewayClient: AuthGatewayClient {
    enum StubResult {
        case success(AuthSession)
        case failure(AuthError)
    }

    private var signInResult: StubResult
    private var refreshResult: StubResult
    private var storedSession: AuthSession?

    private(set) var signInCallCount = 0
    private(set) var refreshCallCount = 0
    private(set) var discardRefreshTokenCallCount = 0
    private(set) var clearSessionCallCount = 0

    init(
        currentSession: AuthSession? = nil,
        signInResult: StubResult = .failure(.invalidCredentials),
        refreshResult: StubResult = .failure(.refreshFailed)
    ) {
        self.storedSession = currentSession
        self.signInResult = signInResult
        self.refreshResult = refreshResult
    }

    func setSignInResult(_ result: StubResult) { signInResult = result }
    func setRefreshResult(_ result: StubResult) { refreshResult = result }
    func setCurrentSession(_ session: AuthSession?) { storedSession = session }

    func signIn(email: String, password: Credential) async throws -> AuthSession {
        signInCallCount += 1
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
        discardRefreshTokenCallCount += 1
    }

    func clearSession() async {
        clearSessionCallCount += 1
        storedSession = nil
    }

    var currentSession: AuthSession? {
        get async { storedSession }
    }
}

// MARK: - LockoutPolicy (BankAuth, public protocol)

actor QAFakeLockoutPolicy: LockoutPolicy {
    private(set) var recordedFailures: [AuthFailureKind] = []
    private(set) var resetCallCount = 0
    private var isLockedOutOverride: Bool

    init(isLockedOut: Bool = false) {
        self.isLockedOutOverride = isLockedOut
    }

    func setLockedOut(_ value: Bool) { isLockedOutOverride = value }

    func recordFailure(_ kind: AuthFailureKind) async {
        recordedFailures.append(kind)
    }

    var isLockedOut: Bool {
        get async { isLockedOutOverride }
    }

    func reset() async {
        resetCallCount += 1
        recordedFailures.removeAll()
        isLockedOutOverride = false
    }
}

// MARK: - IdleTimeoutPolicy (BankAuth, public protocol)

actor QAFakeIdleTimeoutPolicy: IdleTimeoutPolicy {
    private var elapsedValue: Bool
    private(set) var recordActiveCallCount = 0

    init(elapsed: Bool) {
        self.elapsedValue = elapsed
    }

    func setElapsed(_ value: Bool) { elapsedValue = value }

    func recordActive() async {
        recordActiveCallCount += 1
    }

    var idleTimeoutElapsed: Bool {
        get async { elapsedValue }
    }
}

// MARK: - BiometricCapabilityChecking (BankAuth, public protocol)

struct QAFakeBiometricCapabilityChecking: BiometricCapabilityChecking {
    let value: BiometricCapability

    var capability: BiometricCapability {
        get async { value }
    }
}

// MARK: - BiometricEnrollmentPreferenceStoring (BankAuth, public protocol)

actor QAFakeBiometricEnrollmentPreferenceStoring: BiometricEnrollmentPreferenceStoring {
    private var choiceValue: BiometricEnrollmentChoice
    private(set) var recordEnrolledCallCount = 0
    private(set) var recordDeclinedCallCount = 0

    init(choice: BiometricEnrollmentChoice = .notYetOffered) {
        self.choiceValue = choice
    }

    var choice: BiometricEnrollmentChoice {
        get async { choiceValue }
    }

    func recordEnrolled() async {
        recordEnrolledCallCount += 1
        choiceValue = .enrolled
    }

    func recordDeclined() async {
        recordDeclinedCallCount += 1
        choiceValue = .declined
    }
}

// MARK: - AuthSessionRepository (BankAuth, public protocol)

actor QAFakeAuthSessionRepository: AuthSessionRepository {
    enum StubResult {
        case success(Role)
        case failure(Error)
    }

    private var signInResult: StubResult
    private var refreshResult: StubResult
    private var role: Role?

    private(set) var signInCallCount = 0
    private(set) var refreshCallCount = 0

    init(
        currentRole: Role? = nil,
        signInResult: StubResult = .failure(AuthError.invalidCredentials),
        refreshResult: StubResult = .failure(AuthError.refreshFailed)
    ) {
        self.role = currentRole
        self.signInResult = signInResult
        self.refreshResult = refreshResult
    }

    func setSignInResult(_ result: StubResult) { signInResult = result }
    func setCurrentRole(_ role: Role?) { self.role = role }

    func signIn(email: String, password: Credential) async throws -> Role {
        signInCallCount += 1
        switch signInResult {
        case .success(let role):
            self.role = role
            return role
        case .failure(let error):
            throw error
        }
    }

    func refreshSession() async throws -> Role {
        refreshCallCount += 1
        switch refreshResult {
        case .success(let role):
            self.role = role
            return role
        case .failure(let error):
            throw error
        }
    }

    var currentRole: Role? {
        get async { role }
    }

    private(set) var signOutCallCount = 0

    func signOut() async {
        signOutCallCount += 1
        role = nil
    }
}

// MARK: - ReentryGateRepository (BankAuth, public protocol)

actor QAFakeReentryGateRepository: ReentryGateRepository {
    private var biometricCapableValue: Bool
    private var biometricGateRequiredValue: Bool
    private var isLockedOutValue: Bool
    private var presentGateOutcome: BiometricGateOutcome
    private var enrollmentChoiceValue: BiometricEnrollmentChoice

    private(set) var presentBiometricGateCallCount = 0
    private(set) var acceptCallCount = 0
    private(set) var declineCallCount = 0

    init(
        biometricCapable: Bool = true,
        biometricGateRequired: Bool = false,
        isLockedOut: Bool = false,
        enrollmentChoice: BiometricEnrollmentChoice = .notYetOffered
    ) {
        self.biometricCapableValue = biometricCapable
        self.biometricGateRequiredValue = biometricGateRequired
        self.isLockedOutValue = isLockedOut
        self.presentGateOutcome = .success
        self.enrollmentChoiceValue = enrollmentChoice
    }

    func setPresentGateOutcome(_ outcome: BiometricGateOutcome) { presentGateOutcome = outcome }
    func setLockedOut(_ value: Bool) { isLockedOutValue = value }
    func setGateRequired(_ value: Bool) { biometricGateRequiredValue = value }
    func setCapable(_ value: Bool) { biometricCapableValue = value }

    var biometricCapable: Bool {
        get async { biometricCapableValue }
    }

    var biometricGateRequired: Bool {
        get async { biometricGateRequiredValue }
    }

    var isLockedOut: Bool {
        get async { isLockedOutValue }
    }

    func presentBiometricGate() async -> BiometricGateOutcome {
        presentBiometricGateCallCount += 1
        return presentGateOutcome
    }

    var enrollmentChoice: BiometricEnrollmentChoice {
        get async { enrollmentChoiceValue }
    }

    func acceptBiometricEnrollment() async {
        acceptCallCount += 1
        enrollmentChoiceValue = .enrolled
    }

    func declineBiometricEnrollment() async {
        declineCallCount += 1
        enrollmentChoiceValue = .declined
    }
}
