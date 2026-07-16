# SECOPS REPORT

- **Branch scanned:** feature/sprint-1-auth-bankauth
- **Diff reviewed:** commit fd6cc3d (Feature Engineer), Packages/BankAuth only — the assigned scope
- **Rulebook:** security/masvs-checklist.md
- **Note:** this branch was already fast-forward-merged into `main` before this scan ran; findings
  below apply to the merged code as it stands on `main` today.

## FINDINGS

### WARN — S10 (try? never discards an error; no empty catch blocks)
- **File/line:** `Packages/BankAuth/Sources/BankAuth/LiveReentryGateRepository.swift:72-80`
- **Evidence:** inside `presentBiometricGate()`, the `catch` block around the
  `gatewayClient.refreshSession()` call is syntactically empty — its body is seven lines of
  comment, zero executable statements:
  ```swift
  } catch {
      // AC-6.4/6.5, DECISION Q9: a failed refresh here is
      // not a biometric or passcode failure and must not
      // be recorded via LockoutPolicy. ...
  }
  ```
  This matches the always-scan item literally. I read the reasoning documented in the comment and
  in the Feature Engineer's self-report (the outcome is separately observable via
  `AuthSessionRepository.currentRole` returning `nil` afterward, which
  `LiveBiometricGateViewModel` does check) — I am not asserting this currently loses a signal
  the app needs. I'm flagging it as WARN rather than BLOCKER because the mitigation is real and
  covered by a regression test, but the pattern itself — an empty catch body — is exactly what S10
  exists to catch on sight regardless of whether today's surrounding code happens to compensate for
  it elsewhere. A future edit to either this method or `LiveBiometricGateViewModel` could silently
  reintroduce a lost error with no local signal that anything changed.

### NOTE — S1 (no sensitive data in UserDefaults, plists, or unencrypted files)
- **Files/lines:** `Packages/BankAuth/Sources/BankAuth/LiveLockoutPolicy.swift:8,14` and
  `LiveBiometricEnrollmentPreferenceStoring.swift:7,11`
- **Evidence:** both use `UserDefaults` for persistence, which the always-scan list requires
  flagging on sight. On inspection of what is actually written:
  - `LiveLockoutPolicy` stores an array of failure timestamps (`[TimeInterval]`) under
    `com.banksmartai.auth.lockoutFailureTimestamps`.
  - `LiveBiometricEnrollmentPreferenceStoring` stores one of three literal strings
    (`"enrolled"` / `"declined"` / absent) under `com.banksmartai.auth.biometricEnrollmentChoice`.
  Neither value is a token, a credential, or account data — S1's actual targets, per the other
  rows in this rulebook (S3, S4), are auth tokens and credentials specifically. A failure-attempt
  counter and a UI preference enum reveal nothing about identity, money, or auth material. I did
  not find a token, refreshToken, password, or JWT anywhere near either `UserDefaults` call site —
  confirmed by also grepping for Keychain APIs and BankNetworking's internal storage types
  (`KeychainSessionStore`, `StoredSession`) inside `Packages/BankAuth/`: zero hits, confirming
  BankAuth never touches Keychain-owned material directly, only role/session results already
  decoded by BankNetworking. On the merits, this is NOT an S1 violation. Recording it as a NOTE,
  not a WARN, because the Feature Engineer's own self-report already surfaced this exact question
  and asked for confirmation — this is that confirmation, not a new concern.

## CLEAN (always-scan items with no finding)
- Credential shapes ("sk-", "Bearer ", long hex/base64 runs): no genuine hits. A naive grep for
  32+-char alphanumeric runs matched only long CamelCase type names (e.g.
  `BiometricEnrollmentPreferenceStoring`) — false positives, not embedded secrets.
- `Double` in any financial path: zero occurrences in this diff (no money in Sprint 1's scope).
- `kSecAttrAccessibleAlways`: zero occurrences; BankAuth never touches the Keychain at all — that
  remains BankNetworking's sole responsibility, confirmed by this scan.
- `print()` / sensitive values in log calls: zero occurrences.
- `[weak self]` missing in stored closures: no closures store `self` in this diff. The one closure
  present (`FakeReentryGateRepository.onPresent` in `TestDoubles.swift`) is test-only, captures a
  local test variable, not `self`, and isn't a retained/long-lived reference cycle risk.

## PROPOSED RULES
None.
