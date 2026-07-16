import Foundation

/// In-memory only, deliberately: a fresh process (cold launch) has no
/// prior active moment on record, and `idleTimeoutElapsed` returning
/// `true` in that state is exactly AC-2.4's requirement — persisting
/// this across launches would work against that, not for it.
public actor LiveIdleTimeoutPolicy: IdleTimeoutPolicy {
    private let timeoutSeconds: TimeInterval
    private var lastActive: Date?

    public init(timeoutSeconds: TimeInterval = 300) {
        self.timeoutSeconds = timeoutSeconds
    }

    public func recordActive() async {
        lastActive = Date()
    }

    public var idleTimeoutElapsed: Bool {
        get async {
            guard let lastActive else { return true }
            return Date().timeIntervalSince(lastActive) >= timeoutSeconds
        }
    }
}
