# Sprint 1 — Front Door: User Stories
*Produced by the Product Agent from: architecture/MISSION.md, Gateway/README.md,
security/masvs-checklist.md, and the sprint-1-front-door ASSIGNMENT block in
prompts/roles/product.md. Anything not established by those sources is marked
NOT FOUND and listed under OPEN QUESTIONS. Sprint 1 proves WHO is signed in and
WHICH role — no money movement is reachable, so the $10,000.00 approval
threshold applies to nothing in this sprint.*

Gateway surface in scope: **POST /auth/login only.**

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
  `401 { "error": "invalid credentials" }` and the app surfaces a visible
  sign-in failure — the 401 is handled as a control signal, never swallowed
  (S7). The user remains on the sign-in screen with no session established.
- AC-1.4 — Given a successful login, When the session token is persisted,
  Then it is stored in the Keychain with
  `kSecAttrAccessibleAfterFirstUnlock`, and it appears in no UserDefaults
  domain, plist, or unencrypted file (S3, S1). Evidence: SecOps always-scan
  plus a test that inspects UserDefaults after login and finds no token.
- AC-1.5 — Given a successful login, When the JWT is received, Then the app
  reads the role claim from it and that claim is the single source of the
  user's role everywhere in the app — the role is never stored separately in
  UserDefaults or hardcoded (S1).

**Scope-outs**

- No "remember me" / stay-logged-in that bypasses biometric on relaunch.
- No password reset, account creation, or credential change — the gateway
  exposes none of these.
- No MFA beyond biometric — that is Sprint 3's money-movement story.

---

## Story 2 — Biometric re-entry gates the app while a session is valid

As a signed-in user returning to the app, I re-enter with Face ID / Touch ID
so my still-valid session is never reachable without fresh biometric proof.

**Acceptance criteria**

- AC-2.1 — Given a signed-in user with an unexpired token whose idle timeout
  has elapsed (value: NOT FOUND — see OPEN QUESTIONS, Q1), When the app
  returns from background, Then the app requires a successful Face ID /
  Touch ID prompt before any signed-in content is shown, and never
  re-authenticates silently in the background.
- AC-2.2 — Given the biometric gate, When cryptographic keys backing it are
  generated, Then they are generated inside the Secure Enclave and are
  non-exportable (S2). Evidence: Seam 2 sign-off plus Sprint 1 device
  verification, per the checklist's evidence column.
- AC-2.3 — Given a successful biometric prompt within the token's 3600-second
  validity, When the user re-enters, Then the existing Keychain token is
  reused (it is still within its stated expiry) and no new
  `POST /auth/login` call is made.
- AC-2.4 — Given an unexpired session, When the app is cold-launched, Then the
  biometric gate applies exactly as on return-from-background — relaunch never
  bypasses it.

**Scope-outs**

- No custom in-app PIN entry UI — fallback is the OS's own biometric fallback.
- No silent background token refresh of any kind.
- No biometric gating of individual actions (e.g., per-transfer MFA) — Sprint 3.

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
  (biometric + passcode combined) accumulate within it, Then the app disables
  biometric re-entry entirely.
- AC-4.2 — Given the locked-out state, When the user opens the app, Then a
  visible on-screen locked-out state explains that biometric entry is
  disabled and that signing in with email + password is required — the state
  is never silent.
- AC-4.3 — Given the locked-out state, When the user completes a fresh
  `POST /auth/login` with valid email + password (gateway returns 200 with a
  new token), Then a new session is established per Story 1's criteria
  (AC-1.4, AC-1.5 apply to the new token).
- AC-4.4 — Given the locked-out state, When the user attempts to reach any
  signed-in content without the fresh login, Then no cached token grants
  entry.

**Scope-outs**

- No CAPTCHA, back-off timer, or server-side lockout — the gateway spec
  defines none; the lockout is app-side per the Seam 1 policy.
- Whether lockout survives app relaunch/device restart, whether gateway 401s
  count toward the window, and whether fresh login clears the window are NOT
  FOUND — see OPEN QUESTIONS Q4–Q6; no criterion here assumes an answer.

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

**Role-failure note (binding rule check):** the role prompt requires every
role story to state the failure the staff role must see. In Sprint 1 the
assignment places every staff-forbidden action (approvals, transfers) out of
scope and unreachable, so there is no reachable action for staff to be
refused; the 403-as-a-feature criterion (Mission Brief; checklist S7/S8)
attaches to the sprint that first makes an approval action reachable. What
the landing state shows *beyond* the role indicator is NOT FOUND — see OPEN
QUESTIONS Q3.

**Scope-outs**

- No account data, balances, transfers, or approvals reachable — no criterion
  above assumes any screen beyond sign-in and the landing state exists.
- No owner-only UI elements beyond the role indicator — nothing owner-gated
  exists yet to show or hide.

---

## Story 6 — Sessions expire honestly; no token outlives its expiry

As the bank's honesty guarantee, the app treats the gateway's 3600-second
expiry as final, so the screen never claims a session the gateway would
refuse.

**Acceptance criteria**

- AC-6.1 — Given a session token with `expiresInSeconds: 3600`, When 3600
  seconds elapse from issuance, Then the app never presents that token to the
  gateway again and never shows signed-in content on its basis.
- AC-6.2 — Given an expired session, When the user next opens or foregrounds
  the app, Then re-entry is required per the assignment's session rule —
  biometric, or the lockout path of Story 4 — and never a silent background
  re-authentication. (How the fresh gateway token is then obtained is NOT
  FOUND — see OPEN QUESTIONS Q2; no criterion here assumes credentials are
  cached.)
- AC-6.3 — Given any gateway response of 401 after sign-in, When it is
  received, Then the app treats it as a control signal requiring
  re-authentication and surfaces the state change to the user (S7) — it is
  never retried silently with the same token.

**Scope-outs**

- No token refresh endpoint exists in the gateway and none is invented here.
- No idle-timeout value is chosen here — it is a Seam 1 decision still open
  (Q1).

---

## OPEN QUESTIONS (for the Seam 1 human)

- **Q1 — Idle timeout value.** The assignment says "a to-be-set idle
  timeout." NOT FOUND. AC-2.1 and Story 6 are parameterized on it; QA cannot
  write the boundary test until a number (in seconds) is set.
      **DECISION (Adam Fisher, 2026-07-15):** 300 seconds (5 minutes).

- **Q2 — Re-entry after token expiry.** The gateway has no refresh endpoint;
  the only token mint is `POST /auth/login` with email + password. The
  session rule says post-expiry re-entry "requires biometric (or the lockout
  path)." What does biometric unlock in the expiry case — must the user
  re-enter email + password (biometric merely gating the screen), or are
  credentials stored in the Keychain behind biometric to replay the login?
  The second option is a significant security-design decision (S1/S3
  territory) the sources do not make. NOT FOUND.
    **DECISION (Adam Fisher, 2026-07-15):** Option C — amend the gateway with a refresh-token endpoint. At login, the gateway issues a session token and a longer-lived refresh token; the refresh token — not the password — lives in the Keychain behind biometric; after expiry, Face ID unlocks it and POST /auth/refresh mints a fresh session. Same UX as B, same Keychain-behind-biometric teaching content, but the stored secret is scoped and revocable. This is how real banking apps actually work, and it teaches the principle the whole question turns on: store the least-powerful secret that does the job. 

- **Q3 — Landing-state content.** Beyond truthfully displaying the role
  claim, what does the role-aware landing state contain for owner vs staff?
  No source defines it. NOT FOUND.
**DECISION (Adam Fisher, 2026-07-15):** Show who they are, the role the token says they hold, and nothing else.

- **Q4 — Lockout persistence.** Does the 6-failure lockout state survive app
  kill/relaunch and device restart? The policy says the state must be
  visible, but not where it is persisted or for how long. NOT FOUND.
**DECISION (Adam Fisher, 2026-07-15):** Yes. On device, in the app.

- **Q5 — Do gateway 401s count toward lockout?** The lockout policy counts
  "biometric + passcode" failures. Do failed `POST /auth/login` attempts
  (gateway 401) also count toward the 6-in-15-minutes window? NOT FOUND.
**DECISION (Adam Fisher, 2026-07-15):** Yes.

- **Q6 — Lockout reset.** After a successful fresh login from the locked-out
  state, is biometric re-entry immediately re-enabled and the rolling window
  cleared? "Re-establish a session" implies yes but does not state it. NOT
  FOUND.
**DECISION (Adam Fisher, 2026-07-15):** Yes.

- **Q7 — No biometrics available.** Behavior on a device with no biometric
  hardware, biometrics not enrolled, or no device passcode set: NOT FOUND in
  any source.
**DECISION (Adam Fisher, 2026-07-15):** Like a laptop? Require password login

- **Q8 — Biometric enrollment consent.** After the first email + password
  login, is the user prompted to opt in to biometric re-entry, or is it
  assumed? NOT FOUND.
  **DECISION (Adam Fisher, 2026-07-15):** Not assumed. Opt-in
