import Testing
@testable import BankAuth

@Suite
struct LiveIdleTimeoutPolicyTests {
    @Test func elapsedIsTrueBeforeAnyActivityIsRecorded() async {
        // AC-2.4: cold launch (no prior active moment on record) must
        // gate exactly as return-from-background — never skip the gate.
        let policy = LiveIdleTimeoutPolicy(timeoutSeconds: 300)
        #expect(await policy.idleTimeoutElapsed == true)
    }

    @Test func notElapsedImmediatelyAfterRecordingActivity() async {
        let policy = LiveIdleTimeoutPolicy(timeoutSeconds: 300)
        await policy.recordActive()
        #expect(await policy.idleTimeoutElapsed == false)
    }

    @Test func elapsedOnceTheTimeoutPasses() async throws {
        let policy = LiveIdleTimeoutPolicy(timeoutSeconds: 0.05)
        await policy.recordActive()
        try await Task.sleep(nanoseconds: 150_000_000)
        #expect(await policy.idleTimeoutElapsed == true)
    }
}
