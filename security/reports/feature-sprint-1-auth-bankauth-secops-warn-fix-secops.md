# SECOPS REPORT

- **Branch scanned:** feature/sprint-1-auth-bankauth-secops-warn-fix
- **Diff reviewed:** commit c6392ed (Feature Engineer), `Packages/BankAuth/Sources/BankAuth/LiveReentryGateRepository.swift` — the assigned scope (one file, one location per the assignment)
- **Rulebook:** security/masvs-checklist.md
- **Context:** this branch is a targeted fix for the sole WARN in the prior scan
  (`security/reports/feature-sprint-1-auth-bankauth-secops.md`, S10 — empty catch block around a
  failed `refreshSession()` call).

## PRIOR WARN — STATUS

### S10 (try? never discards an error; no empty catch blocks) — RESOLVED
- **File/line:** `LiveReentryGateRepository.swift:75-88`
- **Evidence:** the `catch` block is no longer empty. It now contains one executable statement,
  `Self.logger.debug(...)`, logging that a refresh failed after a successful biometric gate.
  Control flow is unchanged — the block still does nothing but observe — but the swallow is no
  longer silent, which is exactly what the prior WARN asked for. Closing this finding.

## FINDINGS

### WARN — S9 (no sensitive values in logs)
- **File/line:** `LiveReentryGateRepository.swift:87`
- **Evidence:**
  ```swift
  Self.logger.debug("presentBiometricGate: refreshSession failed after a successful gate — \(String(describing: error), privacy: .public)")
  ```
  `privacy: .public` is an explicit override of `os.Logger`'s default behavior, which otherwise
  redacts non-literal string interpolations (`<private>`) in the unified logging system. I traced
  what `error` can actually be here: `refreshSession()` throws only `AuthError`
  (`Packages/BankNetworking/Sources/BankNetworking/AuthError.swift:9-26`) — `.refreshFailed`, or
  `.transport(AppError)`. I confirmed no code path puts a raw token, refresh token, or session
  identifier into either type's string description — the Feature Engineer's self-report is
  correct on that specific claim.

  However, `AppError.serverError` and `.unknown` are reachable from this path carrying a message
  that is **not app-controlled**. In `LiveAuthGatewayClient.swift:174-178`:
  ```swift
  private func mapFailureStatus(_ status: Int, _ data: Data) -> AppError {
      let message = (try? JSONDecoder().decode(AuthErrorResponse.self, from: data))?.error
          ?? "unexpected gateway response (status \(status))"
      return status >= 500 ? .serverError(message) : .unknown(message)
  }
  ```
  `message` is decoded verbatim from the auth gateway's own response body (`{"error": "..."}`).
  That string is server-supplied, unsanitized, and unvalidated by the client before it flows into
  `String(describing: error)` and out through a `.public` log line — which, unlike `.debug`'s
  default redaction, is not protected by the OS from appearing in Console.app, `sysdiagnose`, or
  MDM-collected device logs.

  I am not asserting a token or account value is being logged today — I found no evidence of
  that, and under a well-behaved gateway this field is short, static, human-readable text (e.g.
  "refresh token expired"). I'm flagging this as WARN rather than BLOCKER for the same reason the
  prior report used WARN for the empty catch: the pattern is exactly what S9 exists to catch on
  sight, current behavior is compensated by the gateway's own response contract, and that contract
  is outside this diff's (and this package's) control. A future gateway change — an error
  response that echoes a submitted value, a request ID, or partial account context for
  debugging — would silently start flowing into a `.public` system log with no local signal that
  anything changed, because nothing in `LiveReentryGateRepository.swift` bounds what `message` can
  contain.

  Note for context, not part of this finding: `LiveAuthGatewayClient.swift:92`
  (`discardRefreshToken`'s Keychain-write-failure log, cited as this fix's precedent) also uses
  `privacy: .public`, but on an `OSStatus`-derived Keychain error, not server-supplied text — a
  narrower content space. That file is unchanged in this diff and out of scope for this scan.

## CLEAN (always-scan items with no finding)
- UserDefaults near tokens/credentials/account data: not touched in this diff.
- Credential shapes ("sk-", "Bearer ", long hex/base64 runs): none present.
- `Double` in any financial path: none present.
- `print()` anywhere: none; uses `os.Logger`.
- `[weak self]` missing in stored closures: no closures added or modified.
- `kSecAttrAccessibleAlways`: not present; BankAuth still never touches Keychain directly.

## PROPOSED RULES
- Consider extending S9: a log statement using `privacy: .public` on an interpolated `Error` or
  `String` must be traceable to a bounded, app-defined content space (an enum case, a fixed
  literal, a client-generated message) — never a value whose content originates from a server
  response body, even indirectly through a wrapped error type. Where the content space can't be
  bounded that way, the log line should stay at the default (redacted) privacy or explicitly
  sanitize/truncate before logging. Would have caught this WARN and the existing
  `discardRefreshToken` precedent's assumption from the code alone, rather than requiring a call
  trace into another package.
