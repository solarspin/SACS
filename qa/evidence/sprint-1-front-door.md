# QA Evidence Package — sprint-1-front-door

- **Package under test:** `Packages/BankAuth` (public interface only — see the
  ASSIGNMENT block in `prompts/roles/qa.md`: "QA tests against the public
  interface, not that diff"). Compiler-verified at `6f57c23` (33/33 tests);
  independently re-verified by this Agent against current `main` @ `e410d51`
  (see Test Results below) — the package has moved forward through two more
  SecOps-driven hardening passes since the assignment's pinned SHA and is
  still green.
- **Inputs used, in the order read:** `requirements/sprint-1-front-door-stories.md`,
  the public protocol/contract files under `Packages/BankAuth/Sources/BankAuth`,
  `Packages/BankNetworking/Sources/BankNetworking`, `Packages/BankCore/Sources/BankCore`,
  and `Packages/BankDesign/Sources/BankDesign` (every file *not* prefixed `Live`
  or `Default`), `Gateway/README.md`, this sprint's Compiler and SecOps reports,
  and the ASSIGNMENT block itself.
- **What was never read:** any `Live*.swift` or `Default*.swift` file under
  `Packages/BankAuth/Sources/BankAuth` or `Packages/BankNetworking/Sources/BankNetworking`
  — the implementations under test. The public initializer/method signatures
  needed to construct and drive those types from a black-box test came from
  `swift package dump-symbol-graph --minimum-access-level public` (the built
  artifact's public interface), not from opening their source. The Feature
  Engineer's own `Tests/BankAuthTests/TestDoubles.swift` was also not read
  beyond its top-of-file import list and type-declaration lines (build-system
  metadata needed to avoid symbol collisions in the same test target) — no
  QA test scenario in this package borrows a scenario, assertion, or fake
  shape from it. Every QA-authored fake lives in `QA_TestDoubles.swift`,
  built solely from the public protocol contracts.

## Test files added (branch `qa/sprint-1-front-door`)

All under `Packages/BankAuth/Tests/BankAuthTests/`, additive only — nothing
in the Feature Engineer's existing 6 suites / 33 tests was modified, weakened,
or deleted:

| File | Suite | Tests |
|---|---|---|
| `QA_TestDoubles.swift` | — (fakes only) | 0 |
| `QA_Story1And6_AuthSessionRepositoryTests.swift` | QA Story 1 & 6 — AuthSessionRepository | 9 |
| `QA_Story2_IdleTimeoutPolicyTests.swift` | QA Story 2 — IdleTimeoutPolicy | 3 |
| `QA_Story4_LockoutPolicyTests.swift` | QA Story 4 — LockoutPolicy | 5 |
| `QA_Story5_LandingViewModelTests.swift` | QA Story 5 — LandingViewModel | 3 |
| `QA_Story7And8_ReentryGateRepositoryTests.swift` | QA Story 7 & 8 — ReentryGateRepository | 8 |
| `QA_Story7_BiometricCapabilityCheckingTests.swift` | QA Story 7 — BiometricCapabilityChecking (smoke) | 1 |
| `QA_Story1And7And8_SignInViewModelTests.swift` | QA Story 1, 7 & 8 — SignInViewModel | 6 |
| `QA_Story2And3And4_BiometricGateViewModelTests.swift` | QA Story 2, 3 & 4 — BiometricGateViewModel | 9 |
| `QA_Story8_BiometricEnrollmentPromptViewModelTests.swift` | QA Story 8 — BiometricEnrollmentPromptViewModel | 2 |
| `QA_Story8_BiometricEnrollmentPreferenceStoringTests.swift` | QA Story 8 — BiometricEnrollmentPreferenceStoring | 3 |
| **Total new** | | **49** |

## Test Results

```
swift test  (Packages/BankAuth, main @ e410d51)
Test run with 82 tests in 16 suites passed after 0.172 seconds.
```

82 = 33 pre-existing (Feature Engineer, unchanged) + 49 new (this QA suite).
Zero failures, zero skips. No `Task.sleep` appears anywhere in the new
suite (role rule) — time-dependent contracts (`IdleTimeoutPolicy`,
`LockoutPolicy`) are exercised by extremizing their public
`timeoutSeconds`/`windowSeconds` initializer parameters instead of waiting
on the real clock; see the doc comments at the top of
`QA_Story2_IdleTimeoutPolicyTests.swift` and `QA_Story4_LockoutPolicyTests.swift`.

## Coverage summary — acceptance criteria to tests

| AC | Covered by | Notes |
|---|---|---|
| AC-1.1 | `ownerSignInReturnsOwnerRole`, `successfulSignInOnIncapableDeviceGoesStraightToSignedIn` | |
| AC-1.2 | `staffSignInReturnsStaffRole` | |
| AC-1.3 | `invalidCredentialsRethrowAndRecordFailure`, `invalidCredentialsSurfaceVisibleErrorAndNoSession` | error path — the 401 is never swallowed |
| AC-1.4 | **UNCOVERED** here | BankNetworking's contract responsibility (Keychain), not BankAuth's — see UNCOVERED |
| AC-1.5 | Structural + `QA_Story5_LandingViewModelTests` | role flows in as a parameter, never a second store |
| AC-1.6 | **UNCOVERED** here | BankNetworking/Keychain — see UNCOVERED |
| AC-2.1 | `recentlyActiveIsNotElapsed`, `zeroTimeoutElapsesImmediately`, `gateRequiredAndSuccessfulOutcomeReachesSignedIn`, `failedGateOutcomeNeverReachesSignedIn` | |
| AC-2.2 | **UNCOVERED** — device verification | Secure Enclave / hardware; requirements file's own evidence column names Seam 2 + device verification, not a package unit test |
| AC-2.3 | `validSessionWithoutGateRequiredReusesSessionWithoutPrompting`, `currentRoleReflectsUnexpiredSession` | asserts zero calls to `presentBiometricGate()` |
| AC-2.4 | `coldLaunchIsTreatedAsElapsed`, `gateRequiredWhenIdleElapsed` | |
| AC-3.1 | **UNCOVERED** — device verification | lives inside the internal (deliberately non-public) `BiometricGating` type and ultimately the OS's own sheet |
| AC-3.2 | `gateRequiredAndSuccessfulOutcomeReachesSignedIn` | `.success` outcome is handled identically regardless of biometric-vs-passcode origin, per contract |
| AC-3.3 | `lockedOutAtThresholdCombiningAllFailureKinds`, `failedGateOutcomeNeverReachesSignedIn`, `failedPasscodeOutcomeNeverReachesSignedIn` | |
| AC-4.1 | `notLockedOutBelowThreshold`, `lockedOutAtThresholdCombiningAllFailureKinds`, `failuresOutsideTheRollingWindowDoNotCount`, `isLockedOutReflectsLockoutPolicy` | |
| AC-4.2 | `lockedOutStateHasAVisibleMessage`, `lockedOutMessageIsNilWhenNotLockedOut` | never silent |
| AC-4.3 | `resetClearsTheWindowImmediately`, `successfulSignInResetsLockoutPolicy` | |
| AC-4.4 | `lockedOutTakesPrecedenceOverEverythingElse` | state-machine negative test: lockout beats an otherwise-valid, ungated session |
| AC-4.5 | `persistsAcrossSeparateInstancesSharingTheSameDefaults` | simulates relaunch via a second instance sharing the same `UserDefaults` suite |
| AC-5.1 | `ownerLandingShowsOwnerRoleAndEmail` | |
| AC-5.2 | `staffLandingShowsStaffRoleAndEmail` | |
| AC-5.3 | Structural (see `QA_Story5_LandingViewModelTests.swift` header) | `LiveLandingViewModel.init(role:signedInEmail:)` takes the claim directly; no second store reachable on this contract |
| AC-5.4 | Structural (see same file header) | public symbol graph shows exactly two properties on the contract — nothing else exists to show |
| AC-6.1 | `currentRoleIsNilForExpiredSession` | |
| AC-6.2 | `successfulRefreshReturnsRole` (BankAuth's part: calls `refreshSession()`, never `signIn()`, on this path) | the wire-level "never the password" guarantee is BankNetworking's — UNCOVERED here |
| AC-6.3 | **UNCOVERED** here | Keychain atomic replace — BankNetworking |
| AC-6.4 | `refreshFailureNeverRecordsLockoutFailure` | contract (`AuthError.swift`) deliberately collapses both refresh-401 variants into `.refreshFailed` — this test covers the collapsed case |
| AC-6.5 | Same as AC-6.4 | contract does not distinguish the two; see AuthError.swift's own doc comment |
| AC-6.6 | Covered indirectly by the AC-1.3 and AC-6.4/6.5 tests | no separate generic-401 code path exists in this contract set to test independently |
| AC-7.1 | `incapableDeviceReportsNotCapable`, `successfulSignInOnIncapableDeviceGoesStraightToSignedIn` | |
| AC-7.2 | Structural | same `signIn()` call path as Story 1 — no separate password-path API exists to diverge; Keychain storage itself is BankNetworking's — UNCOVERED here |
| AC-8.1 | `enrollmentChoiceStartsNotYetOffered`, `successfulSignInOnCapableUndecidedDeviceOffersEnrollment`, `freshDeviceDefaultsToNotYetOffered` | |
| AC-8.2 | `declineEnrollmentRecordsDeclineAndDiscardsRefreshToken`, `declineCallsReentryRepositoryDecline`, `recordDeclinedPersistsAcrossInstances` | |
| AC-8.3 | `acceptEnrollmentRecordsEnrolled`, `acceptCallsReentryRepositoryAccept`, `recordEnrolledPersistsAcrossInstances` | |

## Non-negotiable rules — how each was addressed

- **Every AC gets at least one test:** table above; the handful marked
  UNCOVERED are explicitly named and reasoned, not silently skipped.
- **Every error path gets a test:** AC-1.3 (401), AC-6.4/6.5 (refresh 401,
  collapsed per contract), `.failed`/`.canceled` gate outcomes — all tested.
- **Money assertions compare exact decimals, never Doubles/strings:**
  N/A this sprint. `Money` does not appear anywhere in Sprint 1's reachable
  surface — Story 1's own framing: "the $10,000.00 approval threshold
  applies to nothing in this sprint."
- **Role boundaries tested from both sides:** N/A this sprint per Story 5's
  own "Role-failure note" — no owner-only action is reachable yet, so there
  is no staff-403 case to test. Both roles ARE tested for the one thing that
  IS reachable (AC-5.1/AC-5.2).
- **State machines tested for transitions that must NOT exist:**
  `lockedOutTakesPrecedenceOverEverythingElse` (locked-out state is never
  bypassed by an otherwise-valid cached session), `failedGateOutcomeNeverReachesSignedIn`,
  `failedPasscodeOutcomeNeverReachesSignedIn`, `canceledGateLeavesAppGated`
  (none of these ever reach `.signedIn`).
- **No `Task.sleep` in tests:** confirmed, zero occurrences.
- **No test deleted or weakened to pass:** confirmed — the pre-existing 33
  tests are untouched and still pass alongside the 49 new ones.

## SecOps report history for this sprint

| Report | Branch | Result |
|---|---|---|
| `security/reports/feature-sprint-1-auth-bankauth-secops.md` | `feature/sprint-1-auth-bankauth` | WARN — S10 empty catch block (`LiveReentryGateRepository.swift`); NOTE — S1 UserDefaults use ruled not a violation (no token/credential material) |
| `security/reports/feature-sprint-1-auth-bankauth-secops-warn-fix-secops.md` | `feature/sprint-1-auth-bankauth-secops-warn-fix` | S10 RESOLVED; new WARN — S9, a `privacy: .public` log line interpolating an error whose description could carry gateway-supplied text |
| `security/reports/feature-sprint-1-auth-bankauth-secops-public-log-fix-secops.md` | `feature/sprint-1-auth-bankauth-secops-public-log-fix` | S9 RESOLVED — log line now switches over a closed, client-defined set of category strings; **no findings**. One PROPOSED RULE (extend S9 to require a bounded content space for any `privacy: .public` error/string interpolation) remains open for a human decision, not a blocker |

Compiler reports on file: `reports/compiler-BankAuth-6f57c23.md` and
`reports/compiler-BankAuth-07997ce.md`, both PASS, 33/33. This Agent
independently re-ran `swift build && swift test` against current `main`
(`e410d51`, one commit past the last SecOps report) and confirms it is
still green — see Test Results above.

## UNCOVERED — what this suite does NOT verify

1. **AC-1.4, AC-1.6, AC-6.3, AC-7.2 — Keychain storage details**
   (`kSecAttrAccessibleAfterFirstUnlock`, atomic replace on refresh, no
   UserDefaults/plist leakage). This is `AuthGatewayClient`'s contractual
   responsibility (BankNetworking), not `AuthSessionRepository`'s
   (BankAuth) — confirmed independently by SecOps's own grep in the first
   report above: "BankAuth never touches Keychain-owned material
   directly." Out of this assignment's built-artifact scope, which is
   pinned to the BankAuth package. Needs its own QA pass scoped to
   BankNetworking.
2. **AC-2.2 — Secure Enclave key generation, non-exportability.**
   Hardware-level; the requirements file's own evidence column for this
   criterion names "Seam 2 sign-off plus Sprint 1 device verification,"
   not a package unit test.
3. **AC-3.1 — the OS's own 3-failed-attempt → passcode-fallback-sheet
   behavior.** Lives inside the internal, deliberately non-public
   `BiometricGating` protocol (see its own doc comment: "Deliberately
   internal, not public... enforced by the compiler, not just this
   comment") and ultimately inside `LAContext`/the OS. `LiveReentryGateRepository.live(...)`'s
   public factory takes no parameter to substitute a fake here, by design.
   Reaching around that boundary would require `@testable import`, which
   this suite deliberately avoids to keep to the genuinely public
   interface. Stories 2/3's *outcome-handling* logic (what the app does
   once given a success/failed/canceled result) is fully covered instead,
   black-box, via `LiveBiometricGateViewModel` — see AC-2.1/2.3/2.4 and
   AC-3.2/3.3 above.
4. **`LiveBiometricCapabilityChecking`'s two branches.** Only smoke-tested
   (the real `LAContext` query is allowed to return whichever case this
   machine's actual state produces). Exercising both `.available` and
   `.unavailable` deterministically needs simulator-level control over
   enrolled biometrics.
5. **The literal wire-level guarantee in AC-6.2** ("never the user's
   password" reaches the gateway) and **AC-6.4 vs AC-6.5's distinct 401
   bodies.** `AuthError.swift`'s own contract deliberately collapses both
   refresh-401 variants into one `.refreshFailed` case ("this contract
   does not distinguish them"), so BankAuth's behavior is identical either
   way and is tested as such. Whether the mock Gateway itself returns the
   correct body/status for each real scenario is a BankNetworking ↔
   Gateway integration concern, run against `Gateway/README.md`'s actual
   process — no test in this suite makes an HTTP call.
6. **End-to-end navigation after `SignInOutcome.offerBiometricEnrollment`.**
   Each involved view model's own transition is tested in isolation
   (`SignInViewModeling` produces the outcome; `BiometricEnrollmentPromptViewModeling`
   independently wires `accept()`/`decline()` through to `ReentryGateRepository`),
   but "and then the app presents that screen" is a composition-root/navigation
   concern with no protocol in this contract set to test it against.

No acceptance criterion above was escalated as untestable-as-specified per
the role prompt's ESCALATION rule — every UNCOVERED item is already scoped
out of package-level unit testing by the requirements file itself (AC-2.2's
evidence column), by the contract's own documented design (`BiometricGating`'s
internal visibility), or by ownership living in a different package/report
already verified through its own SecOps/Compiler pass. No unresolved
requirement gap was found.

This Agent reports readiness **evidence** only. Whether Sprint 1 is
*ready* is a Seam 4 human decision.
