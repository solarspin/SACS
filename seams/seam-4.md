# SEAM 4 SIGN-OFF CHECKLIST — Final Sign-off — v1.0

*Run when the QA Agent delivers the evidence package. The fleet has proven the code works; this
seam is where a human verifies it should be trusted. Works is a fact about the software, and
facts can be automated. Trusted is a decision about it, and the decision is why there's a chair
at this seam.*

## Evidence review — the package must prove itself

- [x] Every capability bar in the Mission Brief traces to at least one passing test derived
      from its criteria. Sign-in, biometric re-entry, lockout, role-aware landing — all in
      `qa/evidence/sprint-1-front-door.md`'s AC-to-test table, 82/82 passing, independently
      re-run at `e943625` (confirmed above, same result). One bar was NOT written down until
      the device session found it missing: voluntary sign-out. Added this session (protocol +
      impl + UI, commit `9db634d` in the pre-merge history), now covered.
- [x] Every SecOps BLOCKER in the sprint history was closed by a fix that was re-scanned — not
      by an argument. Zero BLOCKERs this sprint across all three SecOps reports; the sole WARN
      (S9, `.public` log content) was fixed and re-scanned clean at
      `security/reports/feature-sprint-1-auth-bankauth-secops-public-log-fix-secops.md`.
- [x] Every MASVS row's evidence exists at the location the row names. S1/S4/S9/S10 — SecOps
      reports, present. S2/S3 — Seam 2 sign-off plus this device session (Face ID + Keychain
      confirmed live, see below).
- [x] Every UNCONFIRMED/FLAGGED line from every SELF-REPORT this sprint has a human
      disposition. Including two found only tonight: the composition-root
      self-report's `preconditionFailure` flag (accepted with reason — unreachable this
      sprint, logged forward) and the completeness-check audit's own false claim about
      Face ID/Secure Enclave invalidation (checked against real code and real Apple docs,
      found FALSE, corrected in the audit file itself rather than deleted).

## The device session — on physical hardware, not a simulator

- [x] Sign in as both roles. Feel the biometric fallback — does it degrade the way the lockout
      policy says, or merely somehow work? Both roles signed in live, this session, on a
      physical iPhone (not simulator). Biometric fallback degrades exactly as documented:
      confirmed via real Apple documentation that Face ID allows 2 failed attempts before
      falling back to the OS passcode sheet, matching what was felt live. Two real device-only
      bugs found and fixed in the process: missing `NSFaceIDUsageDescription` (Face ID could
      not invoke at all until fixed — likely explains earlier passcode-only behavior) and
      `localhost` resolving to the phone itself rather than the Mac running the gateway.
- [~] Try to do the wrong thing on purpose: approve as staff, exceed the limit, replay a stale
      session. Approve-as-staff/exceed-the-limit is N/A this sprint — no money movement is
      reachable yet (Sprint 3's scope, not this one). Lockout WAS tried for real: 5 failed
      passcode attempts triggered the phone's own OS-level 1-minute lockout, a real,
      physically-felt consequence, independent of and faster-triggering than the app's own
      6-failure combined-count policy. Confirmed via real Apple documentation: passcode
      lockout escalation begins at the 6th failed attempt, growing toward 60 minutes by the
      9th, full device erase on the 10th only if Erase Data is enabled — NOT tested further on
      purpose, correctly, given that exact real consequence.
- [ ] Kill the network mid-operation. Kill the app mid-operation. NOT done this session — a
      deliberate, triaged call, not an oversight: Sprint 1 moves no money and has no
      unrecoverable state yet, so the cost of skipping this tonight is low. Explicitly
      deferred to Sprint 3/4, when a real ledger and real irreversible operations exist to
      protect. Flagged here rather than silently skipped.
- [x] The unwritable item: would you move your own money through this build, today? Sprint 1
      moves no money, so the literal question doesn't yet apply — the honest Sprint-1-scoped
      version is answered: yes, this build's front door (who's signed in, which role, can they
      get back in, can they get out) is real and can be trusted, on the evidence above. The
      literal money question is Sprint 3's to answer, not this seam's, this sprint.

**Findings** → dispositions → then, and only then, the act.

**The signature act** → the deploy itself, executed by the human, with credentials that exist
only in human hands. The fleet's inability to ship is not a policy sentence; it is a missing
key.

```
SIGN-OFF RECORD
Build:     e943625 (main, clean, 82/82 tests re-verified at sign-off time)
Evidence package: qa/evidence/sprint-1-front-door.md (no version number was ever
           assigned to it — first and only version)
Procedure: seams/seam-4.md v1.0 — all items run; one item (kill network/app
           mid-operation) explicitly deferred to Sprint 3/4, not silently skipped
           — see its checklist line above for the stated reason
Found:     6 real bugs this session, none caught by 82 tests/3 SecOps scans/4 seam
           checklists up through evidence review — all found only by running the
           actual app: (1) composition root never wired (Hello World despite
           passing tests), (2) packages never linked to the Xcode app target,
           (3) a circular target dependency from linking them, (4) Secrets.xcconfig
           never created, (5) no sign-out anywhere in the app despite the
           capability existing unused in BankNetworking, (6) NSFaceIDUsageDescription
           missing, silently blocking Face ID entirely. All 6 fixed and verified
           live on physical hardware this session. Also found and corrected: a
           false technical claim in the new completeness-check tooling (Secure
           Enclave/Face ID re-enrollment — real iOS behavior, doesn't apply to
           this codebase) and a wrong number in the human/AI conversation about
           it (Face ID attempt limit — corrected to 2, sourced against real Apple
           documentation, not assumed). One item deferred on purpose (network/app
           kill mid-operation) — see above. No unresolved findings; two open
           product decisions logged forward for a human, not blocking (idle-clock
           reset after interactive sign-in; GATEWAY_BASE_URL's dual-location
           duplication).
Signed:    _____Adam Fisher_______________, Seam 4 (QA + security + release hats) — ____07/20/2026____
```
