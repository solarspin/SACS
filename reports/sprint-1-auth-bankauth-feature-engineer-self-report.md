# SELF-REPORT — Feature Engineer Agent, sprint-1-auth-bankauth

## What I implemented

Inside `Packages/BankAuth/` only, I implemented every contract in scope: `LiveLockoutPolicy`
(UserDefaults-backed rolling 15-minute/6-failure window, Story 4), `LiveIdleTimeoutPolicy`
(in-memory 300s idle timer, Story 2), `LiveBiometricCapabilityChecking` and `LiveBiometricGating`
(LocalAuthentication-backed, using `.deviceOwnerAuthentication` so the OS itself presents the
passcode fallback per Story 3's requirement that this never be a custom PIN UI),
`LiveBiometricEnrollmentPreferenceStoring` (Story 8), `LiveAuthSessionRepository` and
`LiveReentryGateRepository` (composing all of the above plus `AuthGatewayClient` from
`BankNetworking`, never duplicating its network/Keychain/JWT logic), and all four view models
(`LiveSignInViewModel`, `LiveLandingViewModel`, `LiveBiometricGateViewModel`,
`LiveBiometricEnrollmentPromptViewModel`). Replaced the broken placeholder test (same failure
pattern as the last assignment — a symbol deleted in the contracts PR) with 33 tests across 6
suites, using fakes/test doubles for every injected protocol so nothing requires real biometric
hardware, a real Keychain-authoritative gateway, or a running server process. All 33 pass.

## UNCONFIRMED / FLAGGED

- **A real bug, found and fixed while writing tests, not left in:** my first draft of
  `LiveBiometricGateViewModel.presentGateIfNeeded()` re-checked only `currentRole` after a gate
  attempt, so a *failed* biometric match could still fall through to `.signedIn` if the underlying
  session token happened to still be unexpired — a wrong Face ID match must never show signed-in
  content (AC-2.1). Fixed to switch on the gate's own outcome first; regression test
  `failedGateNeverFallsThroughToSignedInEvenWithAnUnexpiredToken` guards it. Flagging this
  explicitly rather than quietly folding it in, since it's exactly the kind of thing a second pair
  of eyes should specifically re-check.
- **`AuthFailureKind.biometricMismatch` vs `.passcodeMismatch` cannot be reliably distinguished**
  from a single LocalAuthentication `.deviceOwnerAuthentication` evaluation — the OS bundles both
  mechanisms into one call and returns one final result, with no signal for which sub-mechanism
  actually failed. I default every non-cancellation failure to `.biometricMismatch`. This has no
  behavioral effect on Story 4 (AC-3.3 combines both kinds identically), but if a future story ever
  needs to show different UI per failure kind, this mapping cannot supply it. Verify by: confirming
  with Architect/QA that no Sprint 1 acceptance criterion actually depends on telling the two
  apart (I don't believe any does).
- **`LandingViewModeling.signedInEmail` has no reliable source in the signed contracts.**
  `AuthSession` (BankNetworking) carries only `role`, `expiresAt`, `refreshExpiresAt` — no email or
  `sub` claim. I implemented `LiveLandingViewModel` as a simple, caller-supplied data holder (its
  protocol has no methods, only properties, so this is the only shape available); `signedInEmail`
  defaults to `nil` since nothing in scope can populate it reliably (a value survives only within
  the process that typed it at sign-in; it cannot survive a cold-launch-then-biometric-restore).
  Story 5's own ACs (5.1–5.4) never test email display, only role, so this may be intentional — but
  I didn't invent a contract to fix it, and I'm flagging it rather than silently treating it as
  done. Verify by: Architect/Seam 3 deciding whether `signedInEmail` should be removed from the
  contract, or whether `AuthSession` should gain an email/identity field in a future sprint.
- **`SignInViewModeling` has no signal for "what happens after `signIn()` completes."** No
  navigation/outcome contract exists for this in Sprint 1's signed protocols. I added a
  `SignInOutcome` enum and an `outcome` property to the concrete `LiveSignInViewModel` — additive,
  not a substitute for the protocol's own minimal requirements — so a caller (composition root) has
  something concrete to switch on (offer enrollment vs. go to landing). Verify by: deciding whether
  this belongs as a future formal contract instead of an implementation-specific addition.
- **`LockoutPolicy` and `BiometricEnrollmentPreferenceStoring` persist via `UserDefaults`, not the
  Keychain.** My reading of S1 ("no sensitive data in UserDefaults") is that a failure-attempt
  counter and a UI preference enum aren't sensitive data the way a token or credential is — neither
  reveals a secret or PII. Verify by: SecOps/Seam 4 confirming this reading; if wrong, both are a
  small, contained change (swap `UserDefaults` for a `KeychainSessionStore`-style wrapper).
- **`IdleTimeoutPolicy` is in-memory only, not persisted across app relaunch — deliberately.**
  AC-2.4 requires cold launch to gate exactly as return-from-background; persisting "last active
  moment" across launches would let a very-recently-killed-and-relaunched app skip the gate, which
  is the opposite of what AC-2.4 wants. Verify by: confirming this reading against AC-2.4 if it's
  ever in question.
- **`presentBiometricGate()`'s success-but-refresh-fails path records no lockout failure and
  returns `.success`** (the biometric prompt itself did succeed) — the caller
  (`LiveBiometricGateViewModel`) separately re-checks `AuthSessionRepository.currentRole`
  afterward and correctly falls back to `.signedOut` when it's `nil`. This two-step handoff isn't
  spelled out explicitly anywhere in the signed contracts; it's my construction of how the pieces
  fit together. Verify by: a QA integration test exercising an already-dead refresh token behind a
  successful biometric prompt.
- **No test exercises real biometric hardware or a real device passcode prompt** —
  `LiveBiometricCapabilityChecking` and `LiveBiometricGating` wrap `LocalAuthentication` directly
  and cannot be unit-tested against real Face ID/Touch ID/Secure Enclave behavior. This is exactly
  what the security checklist's S2 row already names as "Sprint 1 device verification" — I'd
  suggest that evidence comes from QA on a real device/simulator with biometrics configured, not
  from this package's test suite.

REVIEWED (Seam 3, Adam Fisher, 2026-07-16): All 6 FLAGGED items
reviewed. No fixes required — items 1, 3, 5 are sound defaults;
items 4 and 6 correctly deferred to SecOps and QA per role
boundaries; item 2 (signedInEmail) has no AuthSession field to
source it from regardless, so nil is correct as written. Closed.
