# SEAM 2 SIGN-OFF CHECKLIST — The Architecture & Security Gate — v1.0

*Run on every contracts-only pull request from the Architect Agent, all items, in order. The
code-writing AI agents cannot boot until this seam is signed: they implement only against
protocols present on main, and until the human merges, main is silence.*

- [ ] 1. CONTRACTS ONLY. The diff contains protocols, type definitions, module manifests,
      schemas — and zero function bodies. An implementation in a contracts PR is a finding,
      however good it looks. (Example code has a way of getting committed.)
- [ ] 2. THE MAP MATCHES THE FENCES. The dependency map in the PR matches the package manifests
      on disk. What the diagram promises, the compiler must enforce.
- [ ] 3. WALK THE SENSITIVE VALUES. For each of: auth token, balance, credential, account
      identifier — trace where the structure lets it travel. Can it reach a log? A cache? A
      package that shouldn't know it exists? The time to find a leak is when it's a line in a
      protocol.
- [ ] 4. EVERY CRITERION HAS A HOME. Each acceptance criterion from the approved stories points
      at some contract whose implementation would satisfy it. An orphan criterion means a
      missing contract — found now for pennies.
- [ ] 5. NO OPEN QUESTIONS CROSS. Every NOT FOUND the Product Agent flagged has a human answer
      recorded. A question that crosses this gate becomes an AI agent's guess.
- [ ] 6. MONEY IS MONEY. Every financial value in every signature is Money (Decimal). One
      Double here becomes ten thousand generated lines of drift by Thursday.
- [ ] 7. STATES AND TRANSITIONS. For any state machine: every state reachable, every transition
      authorized, and the failure states present — a machine with no failure states is a
      machine that hasn't been imagined failing.
- [ ] 8. THE EXPLAINING TEST. Pick any contract at random and explain aloud what it's for and
      why it's shaped this way. If you can't, you are not done reviewing — you are done
      skimming. Don't merge.

**Calibration:** time-box it — contracts are short; this is an hour of real attention, not a
week of scheduling. If it's taking a week, the contracts are too big, and that is the finding.
"Not how I'd do it" is a conversation; "the token can reach a log" is a finding. The gate guards
the second kind.

**Findings** → back to the Architect Agent; re-review the fix.

**The signature act** → the merge itself (branch protection makes the review part of the
record), plus the dated line in `PLAN.md`.

```
SIGN-OFF RECORD
Reviewed:  Initial skeleton (no PR at this stage): PLAN.md +
           package manifests as of commit 85f5d8e
Procedure: seams/seam-2.md v1.0 — items 1,2,3,6,8 run;
           items 4/5/7 N/A at skeleton stage (no user stories
           yet) — re-run at the Sprint 1 contracts PR
Found:     None at plan level. During review: fence proven by
           forced build failure (import BankAuth in
           BankTransfers); BankCore tests 4/4; process finding —
           .build/ artifacts briefly committed, caught in diff,
           amended out, .build/ and .swiftpm/ now gitignored
Signed:    Adam Fisher, Seam 2 (tech lead hat) — 07/15/2026
```
