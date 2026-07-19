// QA Agent — Sprint 1 (sprint-1-front-door).
// Story 7 (no-biometric devices), smoke-tested against
// `LiveBiometricCapabilityChecking`'s public interface only.
//
// This is deliberately a smoke test, not a branch-coverage test: the type
// queries real OS/hardware biometric state (LAContext), which this
// package-level unit test has no ability to control in either direction.
// Exercising both the `.available` and `.unavailable` branches requires
// device/simulator-level control over enrolled biometrics — out of reach
// here, and consistent with AC-2.2's own evidence column in the
// requirements file ("Seam 2 sign-off plus Sprint 1 device
// verification"). See the evidence package's UNCOVERED section.

import Testing
import Foundation
import BankAuth

@Suite("QA Story 7 — BiometricCapabilityChecking (smoke)")
struct QABiometricCapabilityCheckingTests {

    @Test("The live capability check returns a known BiometricCapability case without crashing")
    func liveCapabilityCheckReturnsAKnownCase() async {
        let checker = LiveBiometricCapabilityChecking()

        let result = await checker.capability

        #expect(result == .available || result == .unavailable)
    }
}
