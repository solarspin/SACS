# SEAM 3 — Engineering Overwatch — Tripwires & Intervention Protocol — v1.0

*This seam is not a gate. The Feature Engineer / SecOps / Compiler loop is automated on
purpose; a human queued into it is its slowest component. A converging loop is the machine's;
a circling loop is yours. Watch with tripwires, not vigilance — vigilance decays by Thursday.*

## Step in when any of these fires — and not before

- **THREE CYCLES, SAME ERROR.** The Compiler Agent counts its iterations aloud; its prompt
  orders it to stop and summon you after three cycles on the same error. The tripwire lives
  where the loop can read it.
- **ANY STOP REPORT.** A missing contract, an ambiguous requirement, work that would cross a
  package fence — the role prompts end the session and hand you a paragraph. A STOP is the
  system working; answer it like a page, not like spam.
- **THE DIFF IS WANDERING.** Cycle five's diff touches files cycle one's never did, drifting
  outward from the assignment. Local fixes don't spread; confusion does.
- **THE FIX LOOP REACHES FOR A TEST.** Any change that would weaken, skip, or delete a test to
  get to green. The prompts forbid it; the tripwire assumes prompts fail.

## When one fires — the intervention protocol

1. **Don't type into the loop.** Another prompt into a circling session is another shovel into
   the hole.
2. **Diagnose the mechanism yourself:** reproduce it, read the error's history across cycles,
   find what the machine is missing. The description is the work.
3. **Boot a FRESH session** — role prompt, plan, assignment, plus your diagnosis stated as a
   constraint.
4. **If the lesson generalizes, it goes into the role prompt,** in its own commit, before the
   fresh boot. The prompt is the persistent artifact.

## Then log it — the signature act

One run-ledger entry per intervention. Once a sprint, review the ledger whole: three
interventions for the same class of confusion is not three fixes — it is one missing rule. The
run ledger is where prompt versions come from.

```
RUN-LEDGER ENTRY
What looped:   ________________________________________
Diagnosis:     ________________________________________
What changed:  context / constraint / prompt version (circle)
Prompt after:  ____________ v____
Logged:        ____________________, Seam 3 (tech lead hat) — ________
```
