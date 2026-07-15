# SEAM 4 SIGN-OFF CHECKLIST — Final Sign-off — v1.0

*Run when the QA Agent delivers the evidence package. The fleet has proven the code works; this
seam is where a human verifies it should be trusted. Works is a fact about the software, and
facts can be automated. Trusted is a decision about it, and the decision is why there's a chair
at this seam.*

## Evidence review — the package must prove itself

- [ ] Every capability bar in the Mission Brief traces to at least one passing test derived
      from its criteria. Bars without tests are promises without guarantees.
- [ ] Every SecOps BLOCKER in the sprint history was closed by a fix that was re-scanned — not
      by an argument.
- [ ] Every MASVS row's evidence exists at the location the row names. The checklist says
      where; you go look.
- [ ] Every UNCONFIRMED/FLAGGED line from every SELF-REPORT this sprint has a human
      disposition: verified, accepted with reason, or fixed. Flags nobody read are flags the
      system raised for no one.

## The device session — on physical hardware, not a simulator

- [ ] Sign in as both roles. Feel the biometric fallback — does it degrade the way the lockout
      policy says, or merely somehow work?
- [ ] Try to do the wrong thing on purpose: approve as staff, exceed the limit, replay a stale
      session. Read every refusal the way an attacker would.
- [ ] Kill the network mid-operation. Kill the app mid-operation. What does the ledger believe
      afterward — and what does the user see that tells them?
- [ ] The unwritable item: would you move your own money through this build, today? If the
      answer has a "but," the "but" is a finding.

**Findings** → dispositions → then, and only then, the act.

**The signature act** → the deploy itself, executed by the human, with credentials that exist
only in human hands. The fleet's inability to ship is not a policy sentence; it is a missing
key.

```
SIGN-OFF RECORD
Build:     ________  Evidence package: v____
Procedure: seams/seam-4.md v1.0 — all items run
Found:     ________________________________________
Signed:    ____________________, Seam 4 (QA + security + release hats) — ________
```
