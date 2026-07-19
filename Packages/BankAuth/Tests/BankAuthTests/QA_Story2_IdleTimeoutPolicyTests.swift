// QA Agent — Sprint 1 (sprint-1-front-door).
// Story 2 (biometric re-entry gates the app), the idle-timeout half,
// tested against `LiveIdleTimeoutPolicy`'s public interface only.
//
// No `Task.sleep`: `timeoutSeconds` on the public initializer is used as
// the extremization knob instead of waiting on the real clock.

import Testing
import Foundation
import BankAuth

@Suite("QA Story 2 — IdleTimeoutPolicy")
struct QAIdleTimeoutPolicyTests {

    // AC-2.4: cold launch — no active moment on record yet — must be
    // treated as elapsed, never as "nothing has gone idle yet."
    @Test("AC-2.4: a fresh instance with no recorded active moment is elapsed")
    func coldLaunchIsTreatedAsElapsed() async {
        let policy = LiveIdleTimeoutPolicy(timeoutSeconds: 300)

        #expect(await policy.idleTimeoutElapsed == true)
    }

    // AC-2.1: immediately after recording activity, the idle timeout has
    // not elapsed (assuming a real, non-zero timeout).
    @Test("AC-2.1: immediately after recordActive(), the timeout has not elapsed")
    func recentlyActiveIsNotElapsed() async {
        let policy = LiveIdleTimeoutPolicy(timeoutSeconds: 300)

        await policy.recordActive()

        #expect(await policy.idleTimeoutElapsed == false)
    }

    // AC-2.1: a zero-second timeout is elapsed the instant activity is
    // recorded — this exercises the "has elapsed" branch deterministically
    // without waiting 300 real seconds.
    @Test("AC-2.1: a zero-second timeout is elapsed immediately after recordActive()")
    func zeroTimeoutElapsesImmediately() async {
        let policy = LiveIdleTimeoutPolicy(timeoutSeconds: 0)

        await policy.recordActive()

        #expect(await policy.idleTimeoutElapsed == true)
    }
}
