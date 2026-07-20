# Sprint 1 — Front Door: Completeness Check (v2)

*Produced by the Product Agent per `prompts/roles/product.md`'s COMPLETENESS CHECK rule,
run against the already-signed, already-shipped
`requirements/sprint-1-front-door-stories.md` (Stories 1–8, OPEN QUESTIONS Q1–Q12, all
resolved). This file does not modify that document and does not fill any gap it names —
per the rule, the Product Agent names gaps, the human disposes of them. Context read, in
the role's specified order: `architecture/MISSION.md`, `Gateway/README.md`,
`security/masvs-checklist.md`, then the stories file itself. Every line below states its
own evidence basis, per the rule: "(confirmed — ...)" means the actual code under
`Packages/` (and, where noted, the app target and Xcode project) was read and the claim
is checked against it; "(general expectation — not checked against this code)" means the
line is asserted from domain/platform knowledge without code-level verification.*

## COMPLETENESS CHECK

1. **Voluntary sign-out has zero acceptance criteria despite being fully built and
   shipped.** `LandingView.swift` renders a live "Sign Out" button wired through
   `ContentView.handleSignOut()` to `AuthSessionRepository.signOut()` →
   `LiveAuthGatewayClient.clearSession()` (Keychain wipe), but no story or AC in the
   signed document describes it: nothing says whether it should confirm before acting,
   what screen follows it, or whether it is expected to reset the Story 4 lockout window
   or the idle-timeout clock — it currently resets neither, since
   `LiveAuthSessionRepository.signOut()` calls only `gatewayClient.clearSession()`. This
   is the role prompt's own example — "a session that starts needs a way to end" — and
   the capability already exists in code with no requirement governing it: a real
   omission, not a stated scope-out. (confirmed — read `LandingView.swift`,
   `ContentView.swift`, `AuthSessionRepository.swift`, `LiveAuthSessionRepository.swift`,
   `LiveAuthGatewayClient.swift`)

2. **Face ID cannot function on-device as the stories assume.** Neither
   `BankSmartAI/Info.plist` nor any build setting in `BankSmartAI.xcodeproj/project.pbxproj`
   defines `NSFaceIDUsageDescription` (or `INFOPLIST_KEY_NSFaceIDUsageDescription`). iOS
   refuses to present a Face ID prompt via `LAContext.evaluatePolicy(.deviceOwnerAuthentication,...)`
   without this string present, which is exactly the call `LiveBiometricGating.evaluate()`
   makes. Stories 2, 3, 7, and 8 all depend on that prompt actually appearing. This blocks
   the sprint's core capability on a real device — a real omission, not a scope-out.
   (confirmed — read `BankSmartAI/Info.plist` in full and grepped
   `BankSmartAI.xcodeproj/project.pbxproj` for `FaceID`/`INFOPLIST_KEY`; no match either
   place)

3. **Biometric enrollment choice is stored per-device, not per-account, and survives
   sign-out.** `LiveBiometricEnrollmentPreferenceStoring` persists one fixed
   `UserDefaults` key (`com.banksmartai.auth.biometricEnrollmentChoice`) with no
   account/email scoping, and `LiveAuthSessionRepository.signOut()` does not clear it. On
   a device an owner hands to a staff member after signing out (finding 1's Sign Out
   button), the staff member's session inherits whatever biometric choice the owner made
   — and if enrolled, is gated by whichever biometric identities the OS itself has
   enrolled on that device, not anything scoped to the BankSmartAI account now signed in.
   No story names this multi-role/shared-device handoff at all. Real omission for a
   business app whose whole premise (Mission Brief) is owner + staff sharing a
   capability boundary. (confirmed — read `LiveBiometricEnrollmentPreferenceStoring.swift`
   and `LiveAuthSessionRepository.swift`)

4. **The lockout counter does not survive the one reset an attacker with physical access
   actually controls.** AC-4.5 requires the rolling failure count to persist across "the
   app is killed and relaunched or the device is restarted," and `LiveLockoutPolicy` does
   persist across those — but via `UserDefaults`, which app deletion+reinstall wipes.
   `AuthSessionRepository.swift`'s own doc comment notes the Keychain-held session
   "survives app deletion/reinstall by OS design" — meaning the token store and the
   lockout-counter store diverge at exactly the boundary an attacker who has burned 5 of
   6 attempts would try next: delete and reinstall the app to reset the counter to zero.
   AC-4.5 names two persistence boundaries and misses the one where the two storage
   layers actually behave differently. Real omission. (confirmed — read
   `LiveLockoutPolicy.swift` (`UserDefaults`-backed) against `AuthSessionRepository.swift`'s
   doc comment on Keychain surviving reinstall)

5. **No detection of a change to the device's enrolled biometrics.**
   `LocalAuthentication` exposes `LAContext.evaluatedPolicyDomainState` and
   `LAError.biometryChanged` precisely so an app can notice that a new face/fingerprint
   was added at the OS level after the app's own gate was set up, and force
   re-authentication. Nothing in `LiveBiometricGating.swift`,
   `LiveBiometricCapabilityChecking.swift`, or the Keychain layer captures or compares
   this state. Anyone who can enroll a new biometric at the OS level (i.e., anyone who
   knows the device passcode) can then pass the app's biometric gate as the enrolled
   user. Real omission for a banking app's front door. (confirmed — grepped all of
   `Packages/*/Sources` for `evaluatedPolicyDomainState`/`biometryChanged`, no matches;
   read `LiveBiometricGating.swift` and `LiveBiometricCapabilityChecking.swift` in full)

6. **DECISION Q12's "re-offerable anytime from Settings" has no story, view model, or
   screen behind it.** `BiometricEnrollmentPromptView.swift` tells the user "You can
   change this later in Settings," and Q12 formally decided enrollment is "offered once
   at first login; re-offerable anytime from Settings afterward" — but no Settings
   screen exists anywhere in the app target or in BankAuth's view-model surface, and
   Story 5's own AC-5.4 scopes the landing state to identity and role "and nothing
   else." A decided requirement with a shipped UI promise pointing at a screen that does
   not exist and that the sprint's own scope-out language may currently preclude. Real
   omission. (confirmed — grepped the app target and all of `Packages/*/Sources` for
   "settings"; only the enrollment-preference type name and `GatewayConfiguration`
   matched, no Settings view or view model anywhere)

7. **No app-switcher/screenshot privacy handling.** Nothing in the app target or BankAuth
   hooks backgrounding (`scenePhase`, `willResignActive`, or equivalent) to blur or hide
   the sign-in screen's live password field or the landing screen's identity/role content
   before the OS captures an app-switcher snapshot; `ContentView.swift`'s only
   `scenePhase` handling re-runs the biometric gate, it does not obscure content first.
   A domain professional would expect a banking app's password entry screen not to be
   preserved verbatim in the OS app switcher. Real omission, not addressed by any stated
   scope-out. (confirmed — read `ContentView.swift` in full; grepped the app target and
   `Packages/*/Sources` for screenshot/snapshot/privacy-screen hooks, no matches)

8. **No jailbreak, root, or debugger-attach detection anywhere in the app.** Not present
   in any `Packages/*/Sources` file, and not a row in `security/masvs-checklist.md`
   (S1–S10 cover storage, transport, and code hygiene, not device-integrity attestation).
   A professional auditing a banking app's front door would expect some anti-tampering
   posture, since the Secure Enclave/Keychain guarantees Stories 2 and 4 lean on are
   materially weaker on a compromised device. Since the project's own checklist —
   binding per that file's own header ("a rule not in this file is not a finding") — is
   silent on this, it is either an intentional decision nobody wrote down or a genuine
   gap; either way, unnamed anywhere in the signed stories. (confirmed — grepped all of
   `Packages/*/Sources` for jailbreak/jailbroken/root, no matches; re-read
   `security/masvs-checklist.md` in full, no such row exists)

9. **No accessibility (VoiceOver, Dynamic Type, contrast) consideration anywhere in the
   auth UI.** `SignInView.swift`, `LandingView.swift`, and
   `BiometricEnrollmentPromptView.swift` use plain SwiftUI `Text`/`Button`/`SecureField`
   with no `.accessibilityLabel`, `.accessibilityHint`, or any Dynamic Type
   accommodation beyond SwiftUI's untouched defaults, and no story mentions
   accessibility at all. A regulated banking app's sign-in and role-identity screen is
   exactly the surface accessibility law (and baseline product decency) holds to a
   higher bar. Real omission, not scoped out anywhere in the document. (confirmed —
   read `SignInView.swift`, `LandingView.swift`, and `BiometricEnrollmentPromptView.swift`
   in full; grepped `Packages/*/Sources` for accessib/voiceover, no true hits — the only
   substring matches were unrelated Keychain "Accessible" attribute names)

10. **Session and idle-timeout expiry are judged entirely against the device's own
    clock, with no server-time or monotonic-clock safeguard.**
    `LiveAuthSessionRepository.currentRole` compares `session.expiresAt > Date()` and
    `LiveIdleTimeoutPolicy.idleTimeoutElapsed` compares elapsed time using the device's
    local `Date()` only. Winding the device clock backward could keep a
    not-yet-expired-looking session gate open past the gateway's actual 3600-second
    expiry (the gateway itself would still reject a truly stale JWT on any protected
    endpoint call, but Sprint 1 makes none besides refresh). Worth naming because this
    sprint's own session rule is "never a cached token used past its stated expiry," and
    the enforcement of "stated expiry" is entirely client-clock-trusting today. (confirmed
    — read `LiveAuthSessionRepository.swift` and `LiveIdleTimeoutPolicy.swift` in full;
    both gate purely on device `Date()`)

11. **A reused/already-used refresh token (DECISION Q10's "security-relevant" event) is
    indistinguishable on-screen from a routine expired session.** Q10 requires the
    gateway to log a reused refresh token server-side as security-relevant, but
    client-side, `LiveAuthGatewayClient.refreshSession()` and
    `LiveReentryGateRepository.presentBiometricGate()` route both 401 variants
    (`unknown or already-used` and `refresh token expired`) through the identical
    silent fallback-to-login path (AC-6.4/AC-6.5 are written to be identical on
    purpose). A domain professional would expect a possible-token-theft signal to look
    different to the user than an everyday expiry, even though Q10 explicitly deferred
    building the full server-side alert response. (confirmed — read
    `LiveAuthGatewayClient.swift`, `LiveReentryGateRepository.swift`, and `AuthError.swift`
    in full; both 401 variants collapse to the same `AuthError.refreshFailed` case and
    the same app-side handling)

12. **No consent or disclosure record for biometric enrollment.** Story 8 covers the
    app's own opt-in prompt (Face ID yes/no) but nothing in the codebase records a
    legal consent/disclosure event distinct from the UI preference — relevant because
    several US states (e.g., Illinois' BIPA) impose written-consent and retention-
    disclosure duties specifically for biometric data collection, a topic the Mission
    Brief and security checklist are both silent on. Whether that duty even attaches
    here (Face ID/Touch ID matching happens entirely inside Apple's Secure Enclave, and
    BankSmartAI never receives or stores biometric data itself) is a legal question this
    check does not resolve — only that no story names it either way. (general
    expectation — not checked against this code beyond confirming no
    consent/terms/BIPA-related string or type exists anywhere in `Packages/*/Sources` or
    the app target)

13. **No handling named for a role claim changing between token issuances within an
    active app session** (e.g., an owner demoted to staff server-side while their
    current JWT is still within its 3600-second window). `DefaultJWTRoleClaimDecoder`
    and `LiveLandingViewModel` both read the role once, at token-decode time; nothing
    re-checks it mid-session, and Sprint 1 makes no protected calls that would surface a
    fresher claim anyway, so this is plausibly fine as an implicit consequence of the
    sprint's own scope. But no story or scope-out line says so explicitly. (general
    expectation — not checked beyond confirming the role is decoded once per token in
    `DefaultJWTRoleClaimDecoder.swift`/`LiveLandingViewModel.swift`; the gateway's own
    role-change behavior lives in `Gateway/server.js`, which is outside `Packages/` and
    was not read for this check)
