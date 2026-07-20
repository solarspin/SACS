# SELF-REPORT — sprint-1-front-door-composition-root

## What I implemented

I replaced the Xcode-template `ContentView` with a real composition root wiring
the Sprint 1 front door end to end, using only BankAuth's public view models
and repository protocols — no new business logic, no new view models, no
changes inside BankAuth/BankNetworking/BankCore/BankDesign. `BankSmartAIApp`
now constructs the shared `LiveAuthGatewayClient` and `LiveLockoutPolicy`
once and passes both into `LiveAuthSessionRepository` and
`LiveReentryGateRepository.live(...)` (their doc comments require sharing
one `LockoutPolicy` instance so Story 4's 6-failure window is a single
combined count, not one per repository). `ContentView` is now a root
coordinator: it owns a `LiveBiometricGateViewModel` (drives Stories 2/3/4 via
`.phase`, evaluated in `.task` on cold launch and in `.onChange(of:
scenePhase)` on every return to `.active`, matching
`presentGateIfNeeded()`'s own doc comment that cold launch and
return-from-background are handled identically) and a `LiveSignInViewModel`
(Story 1). Five new view files render each state: `SignInView`,
`LockedOutView` (embeds `SignInView` under a visible, never-silent lockout
message — AC-4.2/4.3, the only way out of lockout), `BiometricGateProgressView`
(spinner while `presentGateIfNeeded()` is running the OS prompt, retry
button when it settles back into `.awaitingBiometricGate` after a failed/
canceled outcome), `BiometricEnrollmentPromptView` (Story 8), and
`LandingView` (Story 5, renders only `role` and `signedInEmail` — the
contract has no other property to accidentally show). After an interactive
sign-in, routing follows `LiveSignInViewModel.outcome`
(`.offerBiometricEnrollment` / `.signedIn(Role)`/`.none`) directly to the
enrollment offer or straight to landing, per `SignInViewModeling`'s own doc
comment — deliberately *not* by re-running `presentGateIfNeeded()` (see
FLAGGED below for why). Verified: `xcodebuild -scheme BankSmartAI build`
succeeds, and I installed and launched the build on an iOS 17 Pro simulator
— it reached the sign-in screen, and (with the human's help wiring
`GATEWAY_BASE_URL`, see FLAGGED) a real sign-in against the local mock
gateway succeeded, and a subsequent cold relaunch correctly re-presented the
OS biometric/passcode gate per AC-2.4/AC-3.1.

## UNCONFIRMED / FLAGGED

- **Idle-clock gap after an interactive sign-in.** `IdleTimeoutPolicy.recordActive()`
  is only ever called by `LiveReentryGateRepository.presentBiometricGate()`
  on a successful gate — nothing in the public contracts lets the app mark
  "just authenticated" after `AuthSessionRepository.signIn()`. That's why I
  route straight to landing from `LiveSignInViewModel.outcome` instead of
  re-running `presentGateIfNeeded()` (calling it right after an interactive
  sign-in would force an immediate biometric prompt, since
  `idleTimeoutElapsed` defaults `true` until a gate has succeeded at least
  once — contradicting `SignInViewModeling`'s own doc comment that a
  successful sign-in "goes straight to the Story 5 landing state"). The
  consequence: the *first* time the app backgrounds and returns after any
  interactive sign-in, `presentGateIfNeeded()` will force a biometric gate
  even if only a few seconds of idle time passed, because the clock was
  never started. Verify by: backgrounding immediately after a sign-in and
  confirming whether product intends that as correct Story 2 behavior, or
  whether `ReentryGateRepository`/`IdleTimeoutPolicy` needs a contract
  addition to let the app mark activity after interactive sign-in.
- **`GATEWAY_BASE_URL` / `Secrets.xcconfig` wiring is outside my assigned
  files** (`project.pbxproj`, `BankSmartAI/Info.plist` — not
  `BankSmartAIApp.swift`/`ContentView.swift`/new SwiftUI files). The human
  did this work directly in Xcode during this session (linking
  `Secrets.xcconfig` as a base configuration and/or setting
  `GATEWAY_BASE_URL`/`INFOPLIST_KEY_GATEWAY_BASE_URL` as build settings) in
  response to my STOP report. I'm including the resulting `project.pbxproj`
  and `BankSmartAI/Info.plist` diffs in this PR because the branch won't
  build without them, but I did not author them and they weren't reviewed
  by me for correctness beyond confirming the app now boots and signs in.
  Worth noting: the committed `project.pbxproj` currently has
  `GATEWAY_BASE_URL = "http://localhost:4000"` as a literal build-setting
  value (visible in the tracked project file) in addition to
  `Secrets.xcconfig` (gitignored) holding the same value — this duplicates
  the source of truth PLAN.md's SECRETS section describes; worth
  reconciling so only the gitignored xcconfig carries it, verify with the
  human.
- **Two other package products got linked to the app target as a side
  effect of the same fix** (`BankNetworking`, `BankDesign`, `BankCore` — I
  only need `BankNetworking` for `LiveAuthGatewayClient` and `BankCore` for
  `Role`; I never import `BankDesign`, since it's still an empty placeholder
  package with no `Live` conformance for `RoleBadgeStyling`). Not a problem
  I introduced or need to undo — flagging only so a human knows
  `BankDesign` linking was preparatory, not because this assignment uses it.
- **`signedInEmail` on `LandingView` is empty on every path except a
  same-session interactive sign-in.** `AuthSessionRepository` has no way to
  recover an email for a session restored via the biometric gate (cold
  launch, no interactive sign-in this launch) — `LiveLandingViewModel`'s own
  doc comment already flags this as a pre-existing contract gap from the
  prior assignment, not something I introduced or worked around. Verify by:
  cold-launching with a valid session and confirming Product is fine with
  `signedInEmail == nil` on that path, or decide `AuthSessionRepository`
  needs an accessor for it.
- **No `#Preview` on any new view.** `SignInView`/`LockedOutView`/
  `BiometricEnrollmentPromptView`/`ContentView` all need a working
  `AuthSessionRepository`/`ReentryGateRepository`, which means constructing
  a `LiveAuthGatewayClient()` — and its `init` evaluates
  `GatewayConfiguration.baseURL` eagerly, `preconditionFailure`-ing if
  `GATEWAY_BASE_URL` isn't reachable from within an Xcode Previews process
  (a separate question from whether the main app target has it). I didn't
  build preview-only fake dependencies since that would be new,
  assignment-scoped business logic beyond "wire the existing view models."
  Verify by: trying `#Preview` in Xcode once `GATEWAY_BASE_URL` is
  confirmed reachable in the Previews execution context; if it still
  crashes there, previews for these screens may need explicit fakes as a
  separate, human-approved task.
- **Manual verification only covered Stories 1, 2, 3 partially (OS passcode
  fallback observed, not a biometric match — this Mac has no Face ID
  simulator support enabled), 4's locked-out screen was not exercised
  end-to-end (would require 6 real failed attempts against the mock
  gateway), and 8 was not manually exercised** (the account used already
  had an enrollment choice recorded from state left over on the simulator).
  This is app-target wiring verification, not QA — full acceptance-level
  verification against every AC remains QA's and Seam 4's job, not mine.
