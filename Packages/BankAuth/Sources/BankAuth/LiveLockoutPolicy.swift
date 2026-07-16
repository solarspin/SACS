import Foundation

/// Persists the rolling failure window in `UserDefaults`. Not a
/// security violation of S1: a failure count and its timestamps reveal
/// nothing about a credential, a token, or an account — S1 is about
/// tokens/credentials/PII, not an attempt counter.
public actor LiveLockoutPolicy: LockoutPolicy {
    private let defaults: UserDefaults
    private let key: String
    private let windowSeconds: TimeInterval
    private let failureThreshold: Int

    public init(
        defaults: UserDefaults = .standard,
        key: String = "com.banksmartai.auth.lockoutFailureTimestamps",
        windowSeconds: TimeInterval = 15 * 60,
        failureThreshold: Int = 6
    ) {
        self.defaults = defaults
        self.key = key
        self.windowSeconds = windowSeconds
        self.failureThreshold = failureThreshold
    }

    public func recordFailure(_ kind: AuthFailureKind) async {
        var timestamps = prunedTimestamps()
        timestamps.append(Date().timeIntervalSince1970)
        defaults.set(timestamps, forKey: key)
    }

    public var isLockedOut: Bool {
        get async { prunedTimestamps().count >= failureThreshold }
    }

    public func reset() async {
        defaults.removeObject(forKey: key)
    }

    /// Prunes anything outside the rolling window on every read/write so
    /// `isLockedOut` never over-counts stale failures, and re-persists
    /// the pruned result so the stored array doesn't grow forever.
    private func prunedTimestamps() -> [TimeInterval] {
        let cutoff = Date().addingTimeInterval(-windowSeconds).timeIntervalSince1970
        let stored = defaults.array(forKey: key) as? [TimeInterval] ?? []
        let pruned = stored.filter { $0 >= cutoff }
        if pruned.count != stored.count {
            defaults.set(pruned, forKey: key)
        }
        return pruned
    }
}
