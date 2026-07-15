# Sprint 1 — Front Door: User Stories
*Produced by the Product Agent from: architecture/MISSION.md, Gateway/README.md,
security/masvs-checklist.md, and the sprint-1-front-door ASSIGNMENT block in
prompts/roles/product.md. Anything not established by those sources is marked
NOT FOUND and listed under OPEN QUESTIONS. Sprint 1 proves WHO is signed in and
WHICH role — no money movement is reachable, so the $10,000.00 approval
threshold applies to nothing in this sprint.*

*Revision note: this is the second pass. The Seam 1 human (Adam Fisher,
2026-07-15) answered all eight questions from the first pass and, per the Q2
decision, amended the gateway with `POST /auth/refresh`. This pass folds those
decisions into acceptance criteria, updates the gateway surface line, and adds
Stories 7–8 for capabilities the refresh decision and Q7/Q8 introduced. The
original resolved questions are kept below as an audit trail, each pointing to
the story that now encodes it. New questions the refresh endpoint raises are
listed as Q9–Q12.*

Gateway surface in scope: **POST /auth/login and POST /auth/refresh.**

---

## Story 1 — Email + password sign-in establishes a session

As a business user (owner or staff), I sign in with email and password so the
app can establish an authenticated session with a role claim.

**Acceptance criteria**

- AC-1.1 — Given the app has no active session, When the user submits
  `owner@banksmart.test` / `owner-demo-1` to `POST /auth/login`, Then the
  gateway returns 200 with `token`, `role: "owner"`, and
  `expiresInSeconds: 3600`, and the app enters the signed-in state as owner.
- AC-1.2 — Given the app has no active session, When the user submits
  `staff@banksmart.test` / `staff-demo-1`, Then the gateway returns 200 with
  `role: "staff"` and the app enters the signed-in state as staff.
- AC-1.3 — Given the app has no active session, When the user submits any
  wrong email/password pair, Then the gateway returns
  `401 { "error": "invalid credentials" }`, the app surfaces a visible
  sign-in failure — the 401 is handled as a control signal, never swallowed
  (S7) — and the attempt counts toward the Story 4 rolling 15-minute lockout
  window (DECISION Q5, Adam Fisher, 2026-07-15). The user remains on the
  sign-in screen with no session established.
- AC-1.4 — Given a successful login, When the session token is persisted,
  Then it is stored in the Keychain with
  `kSecAttrAccessibleAfterFirstUnlock`, and it appears in no UserDefaults
  domain, plist, or unencrypted file (S3, S1). Evidence: SecOps always-scan
  plus a test that inspects UserDefaults after login and finds no token.
- AC-1.5 — Given a successful login, When the JWT is received, Then the app
  reads the role claim from it and that claim is the single source of the
  user's role everywhere in the app — the role is never stored separately in
  UserDefaults or hardcoded (S1).
- AC-1.6 — Given a successful login, When the response also contains
  `refreshToken` and `refreshExpiresInSeconds` (added per the Q2 decision),
  Then both are stored in the Keychain with the same protection as the
  session token (S3) — never in UserDefaults, a plist, or any unencrypted
  file (S1) — immediately, before any biometric-enrollment choice (Story 8)
  is made.

**Scope-outs**

- No "remember me" / stay-logged-in that bypasses biometric on relaunch.
- No password reset, account creation, or credential change — the gateway
  exposes none of these.
- No MFA beyond biometric — that is Sprint 3's money-movement story.

---

## Story 2 — Biometric re-entry gates the app while a session is valid

As a signed-in, biometric-enrolled user (Story 8) returning to the app, I
re-enter with Face ID / Touch ID so my still-valid session is never reachable
without fresh biometric proof.

**Acceptance criteria**

- AC-2.1 — Given a signed-in user with an unexpired token whose idle timeout
  has elapsed (300 seconds — DECISION Q1, Adam Fisher, 2026-07-15), When the
  app returns from background, Then the app requires a successful Face ID /
  Touch ID prompt before any signed-in content is shown, and never
  re-authenticates silently in the background.
- AC-2.2 — Given the biometric gate, When cryptographic keys backing it are
  generated, Then they are generated inside the Secure Enclave and are
  non-exportable (S2). Evidence: Seam 2 sign-off plus Sprint 1 device
  verification, per the checklist's evidence column.
- AC-2.3 — Given a successful biometric prompt within the token's 3600-second
  validity, When the user re-enters, Then the existing Keychain token is
  reused (it is still within its stated expiry) and no new
  `POST /auth/login` or `POST /auth/refresh` call is made.
- AC-2.4 — Given an unexpired session, When the app is cold-launched, Then the
  biometric gate applies exactly as on return-from-background — relaunch never
  bypasses it.

**Scope-outs**

- No custom in-app PIN entry UI — fallback is the OS's own biometric fallback.
- No silent background token refresh of any kind.
- No biometric gating of individual actions (e.g., per-transfer MFA) — Sprint 3.
- Applies only once biometric is enrolled (Story 8) on a capable device
  (Story 7) — this story does not cover either the opt-in prompt or the
  no-biometric-capability path.

---

## Story 3 — Biometric failure falls back to the OS passcode

As a user whose face/finger isn't matching, I fall back to the device
passcode so a bad camera angle doesn't lock me out of my bank.

**Acceptance criteria**

- AC-3.1 — Given the biometric prompt, When biometric matching fails 3 times
  in a row, Then the OS's own device passcode/PIN fallback is offered — this
  is the operating system's fallback sheet, not a screen BankSmartAI built.
- AC-3.2 — Given the passcode fallback, When the user enters the correct
  device passcode, Then re-entry succeeds exactly as a biometric success
  would (AC-2.3 applies).
- AC-3.3 — Given failed attempts of either kind, When each failure occurs,
  Then it is counted toward the rolling 15-minute lockout window defined in
  Story 4 (biometric and passcode failures combined).

**Scope-outs**

- No custom PIN creation, storage, or entry UI anywhere in the app.
- No app-side alteration of the OS's 3-attempt biometric behavior beyond
  observing its outcome.

---

## Story 4 — Lockout after 6 failures is visible and requires fresh login

As the account's line of defense, the app locks out biometric entry after
repeated failures and says so on screen, so a locked-out user never wonders
why Face ID stopped being offered.

**Acceptance criteria**

- AC-4.1 — Given a rolling 15-minute window, When 6 total failed attempts
  accumulate within it — biometric, passcode, and failed `POST /auth/login`
  401s combined (DECISION Q5, Adam Fisher, 2026-07-15) — Then the app
  disables biometric re-entry entirely.
- AC-4.2 — Given the locked-out state, When the user opens the app, Then a
  visible on-screen locked-out state explains that biometric entry is
  disabled and that signing in with email + password is required — the state
  is never silent.
- AC-4.3 — Given the locked-out state, When the user completes a fresh
  `POST /auth/login` with valid email + password (gateway returns 200 with a
  new token and a new refreshToken), Then a new session is established per
  Story 1's criteria (AC-1.4–AC-1.6 apply to the new tokens) and the rolling
  failure window resets to zero, immediately re-enabling biometric (DECISION
  Q6, Adam Fisher, 2026-07-15).
- AC-4.4 — Given the locked-out state, When the user attempts to reach any
  signed-in content without the fresh login, Then no cached token grants
  entry.
- AC-4.5 — Given the locked-out state, When the app is killed and relaunched
  or the device is restarted, Then the locked-out state and its rolling
  failure count persist on-device (DECISION Q4, Adam Fisher, 2026-07-15) —
  the user is not silently returned to an unlocked state by restarting.

**Scope-outs**

- No CAPTCHA, back-off timer, or server-side lockout — the gateway spec
  defines none; the lockout is app-side per the Seam 1 policy.
- Whether failed `POST /auth/refresh` attempts also count toward this window
  is NOT FOUND — see OPEN QUESTIONS Q9; no criterion here assumes an answer.

---

## Story 5 — The landing state is role-aware for both roles

As an owner or a staff member, I land on a screen that truthfully reflects my
role claim, so authorization is visible from the first screen.

**Acceptance criteria**

- AC-5.1 — Given a login as `owner@banksmart.test`, When the landing state
  renders, Then it reflects the `owner` role claim taken from the JWT
  (AC-1.5), and displays that the signed-in role is owner.
- AC-5.2 — Given a login as `staff@banksmart.test`, When the landing state
  renders, Then it reflects the `staff` role claim, and displays that the
  signed-in role is staff.
- AC-5.3 — Given either role, When any screen that needs the role claim
  renders (in Sprint 1: the landing state only), Then the role is read from
  the JWT claim and never from a second, separately stored copy.
- AC-5.4 — Given either role, When the landing state renders, Then it shows
  only who the user is and the role their token holds, and nothing else
  (DECISION Q3, Adam Fisher, 2026-07-15) — no account data, balance, or
  navigation affordance toward money-movement screens.

**Role-failure note (binding rule check):** the role prompt requires every
role story to state the failure the staff role must see. In Sprint 1 the
assignment places every staff-forbidden action (approvals, transfers) out of
scope and unreachable, so there is no reachable action for staff to be
refused; the 403-as-a-feature criterion (Mission Brief; checklist S7/S8)
attaches to the sprint that first makes an approval action reachable.

**Scope-outs**

- No account data, balances, transfers, or approvals reachable — no criterion
  above assumes any screen beyond sign-in and the landing state exists.
- No owner-only UI elements beyond the role indicator — nothing owner-gated
  exists yet to show or hide.

---

## Story 6 — Sessions expire honestly; refresh never replays a password

As the bank's honesty guarantee, the app treats the gateway's 3600-second
session expiry as final and re-establishes trust only through the one-time-use
refresh token the Q2 decision put behind biometric — never a cached session
token past its expiry, and never a stored password.

**Acceptance criteria**

- AC-6.1 — Given a session token with `expiresInSeconds: 3600`, When 3600
  seconds elapse from issuance, Then the app never presents that token to the
  gateway again and never shows signed-in content on its basis.
- AC-6.2 — Given an expired session (3600s) or an elapsed idle timeout (300s,
  Story 2) on a biometric-enrolled device (Story 8), When the user returns to
  the app and a Face ID / Touch ID (or passcode-fallback, Story 3) prompt
  succeeds, Then the app calls `POST /auth/refresh` with the Keychain-stored
  `refreshToken` — never the user's password — to mint a fresh session
  (DECISION Q2, Adam Fisher, 2026-07-15).
- AC-6.3 — Given `POST /auth/refresh` returns 200, When the response is
  received, Then the app atomically replaces the stored `token`,
  `refreshToken`, `expiresInSeconds`, and `refreshExpiresInSeconds` in the
  Keychain with the new values — the old refreshToken is one-time-use and is
  never presented to the gateway again.
- AC-6.4 — Given `POST /auth/refresh` returns
  `401 { "error": "unknown or already-used refresh token" }`, When received,
  Then the app discards the stored refreshToken, never retries it, and
  requires a fresh `POST /auth/login` with email + password (S7 — the 401 is
  a control signal, not swallowed).
- AC-6.5 — Given `POST /auth/refresh` returns
  `401 { "error": "refresh token expired" }` (the 45-day refresh lifetime has
  elapsed), When received, Then the app requires a fresh `POST /auth/login`
  with email + password, identical to AC-6.4's path.
- AC-6.6 — Given any gateway response of 401 after sign-in on any
  authenticated endpoint, When it is received, Then the app treats it as a
  control signal requiring re-authentication and surfaces the state change to
  the user (S7) — it is never retried silently with the same token.

**Scope-outs**

- No indefinite trust chain: after the refresh token's 45-day lifetime (or the
  gateway's `REFRESH_TTL_SECONDS` test override) elapses, a fresh email +
  password login is required — the app never works around a gateway-enforced
  expiry.
- Whether a failed refresh counts toward the Story 4 lockout, and whether an
  "already-used" refresh response should trigger anything beyond falling back
  to login, are NOT FOUND — see OPEN QUESTIONS Q9–Q10.

---

## Story 7 — Devices without usable biometrics fall back to password login

As a user on a device with no biometric hardware, no biometrics enrolled, or
no device passcode set, I sign in and re-enter with email + password, the same
way I would on a laptop, so the app never dead-ends waiting on a prompt the
device cannot show.

**Acceptance criteria**

- AC-7.1 — Given a device with no biometric hardware, no biometrics enrolled
  at the OS level, or no device passcode set, When the app needs to gate
  initial sign-in or re-entry, Then it never presents a Face ID / Touch ID
  prompt and instead requires email + password via `POST /auth/login`
  (DECISION Q7, Adam Fisher, 2026-07-15 — "like a laptop, require password
  login").
- AC-7.2 — Given this password-login path, When the user authenticates, Then
  the resulting session token and refreshToken are still stored in the
  Keychain per S3, S1 (AC-1.4, AC-1.6) — the absence of biometric capability
  changes only the re-entry gate, never the token-storage requirement.

**Scope-outs**

- No degraded in-app PIN screen as a substitute for OS biometric on these
  devices — the Story 3 prohibition on custom PIN UI applies here too.
- No detection or messaging beyond falling back to password login — e.g., no
  in-app nudge to enroll device biometrics is specified here.

---

## Story 8 — Biometric enrollment is opt-in, never assumed

As a user who just signed in for the first time on a device, I am asked
whether I want Face ID / Touch ID re-entry — it is never turned on for me
silently.

**Acceptance criteria**

- AC-8.1 — Given a user's first successful `POST /auth/login` on a device,
  When the login succeeds, Then the app prompts the user to opt in to
  biometric re-entry — enrollment is never assumed or silently enabled
  (DECISION Q8, Adam Fisher, 2026-07-15).
- AC-8.2 — Given the user declines the opt-in prompt (or has not yet
  responded), When the app next requires re-entry, Then it follows Story 7's
  password-login path, never presenting a biometric prompt.
- AC-8.3 — Given the user accepts the opt-in prompt on a capable device
  (Story 7's conditions not met), When enrollment completes, Then Story 2's
  biometric re-entry gate applies on subsequent re-entries.

**Scope-outs**

- Whether a declined prompt is ever re-offered later, and on what cadence, is
  NOT FOUND — see OPEN QUESTIONS Q12.

---

## OPEN QUESTIONS (for the Seam 1 human)

**Resolved in this pass — kept for the audit trail:**

- **Q1 — Idle timeout value.** RESOLVED: 300 seconds (5 minutes). DECISION
  (Adam Fisher, 2026-07-15). Encoded in Story 2, AC-2.1.
- **Q2 — Re-entry after token expiry.** RESOLVED: Option C — the gateway now
  exposes `POST /auth/refresh`; the refresh token, never the password, lives
  in the Keychain behind biometric. DECISION (Adam Fisher, 2026-07-15).
  Encoded in Story 6 and Gateway/README.md.
- **Q3 — Landing-state content.** RESOLVED: identity and role only, nothing
  else. DECISION (Adam Fisher, 2026-07-15). Encoded in Story 5, AC-5.4.
- **Q4 — Lockout persistence.** RESOLVED: yes, persists on-device. DECISION
  (Adam Fisher, 2026-07-15). Encoded in Story 4, AC-4.5.
- **Q5 — Do gateway 401s count toward lockout?** RESOLVED: yes. DECISION
  (Adam Fisher, 2026-07-15). Encoded in Story 1 AC-1.3 and Story 4 AC-4.1.
- **Q6 — Lockout reset.** RESOLVED: yes, a fresh login clears the window and
  re-enables biometric. DECISION (Adam Fisher, 2026-07-15). Encoded in
  Story 4, AC-4.3.
- **Q7 — No biometrics available.** RESOLVED: require password login, like a
  laptop. DECISION (Adam Fisher, 2026-07-15). Encoded in Story 7.
- **Q8 — Biometric enrollment consent.** RESOLVED: not assumed, opt-in.
  DECISION (Adam Fisher, 2026-07-15). Encoded in Story 8.

**New, raised by the Q2 refresh-token decision and Gateway/README.md's
`POST /auth/refresh` addition — not established by any source:**

- **Q9 — Do failed refresh attempts count toward lockout?** Q5's decision
  covered failed `POST /auth/login` 401s specifically. `POST /auth/refresh`
  can also return 401 (unknown/already-used or expired token) — a different
  failure class, a stale-or-stolen-token signal rather than a wrong-password
  guess. Should these count toward the Story 4 six-failure window? NOT FOUND.
  Q9: DECIDED (Adam Fisher, 2026-07-15): No. Refresh 401s do not count
toward the Story 4 lockout window.

- **Q10 — Does an "already-used" refresh token deserve a stronger response
  than falling back to login?** `401 { "error": "unknown or already-used
  refresh token" }` can indicate a stolen, replayed token — a more serious
  signal than a mistyped password. Beyond AC-6.4's fallback to login, should
  the app show a distinct warning, force a full lockout, or flag the event
  for later SecOps review? Mission Brief and checklist are silent. NOT FOUND.
  Q10: DECIDED (Adam Fisher, 2026-07-15): A reused/already-used refresh
token forces a fresh login and is logged server-side as security-relevant.
Full revoke/alert response is out of scope for Sprint 1.

- **Q11 — Refresh-token storage when biometric enrollment is declined.**
  AC-1.6 stores the gateway-issued refreshToken in the Keychain at login,
  unconditionally, per S3's "auth tokens go in Keychain" rule. But if the user
  then declines biometric opt-in (Story 8), that refresh token sits in the
  Keychain unused and never gated by biometric proof, since Story 7's
  password-only path doesn't call `POST /auth/refresh` at all in this design.
  Should a declined-biometric device even receive/retain a refreshToken, or
  should the app discard it immediately in that case? NOT FOUND.
  Q11: DECIDED (Adam Fisher, 2026-07-15): No. If biometric enrollment is
declined, the refresh token is discarded client-side, not persisted.

- **Q12 — Re-offering biometric enrollment.** If a user declines Story 8's
  opt-in prompt once, is the app allowed to ask again on a later login, and on
  what cadence — or is the decision permanent until an app reinstall? NOT
  FOUND.
  Q12: DECIDED (Adam Fisher, 2026-07-15): Yes, offered once at first
login; re-offerable anytime from Settings afterward, no re-prompting.
