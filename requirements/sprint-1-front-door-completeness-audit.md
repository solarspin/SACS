# Sprint 1 — Front Door: Completeness Check (Audit Pass)

*Produced by the Product Agent per the role prompt's COMPLETENESS CHECK rule
(prompts/roles/product.md), run against the already-signed, already-shipped
`requirements/sprint-1-front-door-stories.md`. This file does not modify that
document. It names gaps only — it does not fill them. The human disposes of
each line.*

## COMPLETENESS CHECK

- **No user-initiated sign-out.** A session that starts (Story 1) needs a
  named way to end deliberately, not just by 3600s expiry (Story 6) or
  lockout (Story 4). No story defines a "log out" action that clears the
  Keychain-held token and refresh token and returns the app to the sign-in
  screen. REAL OMISSION.

- **No way to turn biometric re-entry back off once enrolled.** Story 8
  covers opting in and Q12 covers re-*offering* enrollment from Settings, but
  no story covers a user who enrolled (Story 8) later disabling app-level
  biometric re-entry — a state that's entered needs every exit named. REAL
  OMISSION.

- ~~**iOS invalidates Secure-Enclave-bound keys when the device's biometric
  enrollment changes**~~ — **CORRECTED, 2026-07-20, human-verified: FALSE for
  this codebase.** That invalidation is real on iOS, but only for Keychain
  items explicitly protected with `kSecAccessControlBiometryCurrentSet`.
  Grepped `Packages/BankAuth` and `Packages/BankNetworking`: zero occurrences
  of `SecAccessControl`/`kSecAccessControl`/`biometryCurrentSet` anywhere.
  This app's session token uses `kSecAttrAccessibleAfterFirstUnlock`
  (device-unlock-state, not biometry-linked), and the gate itself
  (`.deviceOwnerAuthentication`) simply re-evaluates fresh against whatever
  is currently enrolled — no stored key to invalidate. Confirmed against
  Apple's own LocalAuthentication/Keychain documentation, not just this
  code. Left in place, struck through, rather than deleted: this file exists
  to be checked, not trusted, and that includes checking itself.

- **Concurrent sessions on a second device are not addressed.** Signing in on
  a second device while a session is already active on the first — does the
  first session keep working, get revoked, or get flagged? The gateway spec
  exposes no session-listing or revocation endpoint, so this may be a genuine
  platform limit rather than a story gap — but no story or scope-out line
  says so. Looks like an OMISSION the gateway itself would need to resolve
  before it could be scoped in or out.

- **Keychain persistence across app delete/reinstall is unaddressed.** iOS
  Keychain items default to surviving app deletion. Whether a reinstalled app
  should silently recover a live refresh token from a previous install, or
  whether that should be treated as a fresh device requiring login, is not
  stated anywhere, despite S3/S1 governing exactly where these tokens live.
  REAL OMISSION.

- **No story covers gateway/network failure during login or refresh** —
  timeout, 5xx, or no connectivity — as distinct from the 401 "wrong
  credentials" path Story 1/6 already cover. A user with no network hits a
  spinner or silence rather than a defined failure state. REAL OMISSION.

- **Security events are logged but never surfaced to the user.** Q10
  resolves that a reused/stolen refresh token is logged server-side, but no
  story puts that event (or a fresh lockout, Story 4) in front of the actual
  customer — e.g., "your session was signed out for your protection." For a
  banking app this is a normal expectation, not an edge case. Likely a REAL
  OMISSION, though it may be an intentional defer to a later sprint given
  Q10's "full alert response is out of scope for Sprint 1" language.

- **Stale role claim after a server-side role change.** The role is read
  from the JWT (AC-1.5, AC-5.3) and trusted for the life of the token/refresh
  chain. If a business's owner were to change a staff member's role, nothing
  in this sprint's design forces re-issuance or invalidates the old claim
  before its natural expiry. Given the gateway exposes no role-change
  endpoint yet, this is likely out of scope for Sprint 1 by gateway
  limitation, but no scope-out line says so explicitly.

- **No screen-privacy handling for the app switcher / background snapshot.**
  Banking apps commonly blank or obscure the screen when backgrounded so the
  OS's app-switcher thumbnail doesn't leak signed-in state. Sprint 1's
  landing state is minimal (identity + role only, per AC-5.4), which lowers
  the stakes, but no story or security row addresses it either way. Likely
  an intentional scope-out given the minimal landing content, but it isn't
  stated as one.

- **No accessibility acceptance criteria** (VoiceOver, Dynamic Type, reduced
  motion) for the sign-in form, biometric-failure messaging, or the
  locked-out state (Story 4's "visible on screen" requirement doesn't specify
  what "visible" means for a screen-reader user). REAL OMISSION.

- **No jailbroken/compromised-device posture check.** Nothing in the cited
  security rows (S1–S10) or these stories addresses detecting a compromised
  OS before trusting biometric/Secure Enclave guarantees. May be intentionally
  deferred to a SecOps-owned sprint rather than a Product-owned story, but no
  line states that.

- **No consent/disclosure capture at first sign-in** (terms of service,
  e-signature consent, privacy notice) — a regulated banking onboarding
  norm. Likely out of this sprint's scope given Story 1's explicit "no
  account creation" boundary, but not named as a scope-out.
