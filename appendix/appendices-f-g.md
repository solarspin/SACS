# Appendices — Supplementary Reference

*Version 2026-08-03 · pre-press. Tracks the manuscript of "Agentic AI Control Point." Where this file and a printed page disagree, this file is the corrected one.*

*Appendices A through E are the kit: everything needed to run the Control Point system on a new
project, in the order you need it. These last two are not part of that kit. You do not need either
one to start. You reach for them once the system is already running — the first when something has
gone wrong and you need to name what kind of wrong it is, the second when you are ready to build
the deterministic checker your own project has earned.*

---

# Appendix F — Failure-Mode Diagnostic Guide

*The four Chapter 11 failure modes. Each entry: what it looks like from the outside, the question
that finds it, and the first move once found.*

## 1. The boundary that's only claimed

**Looks like**
A rule sitting in a plan, a diagram, or a role prompt — and nowhere in the running system.
Indistinguishable from an enforced boundary until something actually tests it.

**The question**
For every boundary you're responsible for — not "has this ever been crossed" but *"what,
specifically, in the running system, would stop it if it were about to be — and have I watched it
stop one?"*

**If the answer is "it's in the plan" or "the prompt says not to"**
That's the finding. Prove it with a forced failure — add the forbidden import, make the disallowed
call — before you trust it again.

## 2. The competent answer to the wrong question

**Looks like**
A fluent, standard, textbook-correct solution to a problem that should have been deleted instead
of solved. Nothing about the answer looks wrong, because it isn't wrong — it's aimed at the wrong
target.

**The question**
Before judging how *well* a proposed solution works, ask what risk it exists to handle, and whether
that risk could be made *impossible* instead of *survivable* — by not doing the underlying action,
rather than doing it more carefully.

**If the answer is "yes, and we'd lose almost nothing"**
You just found a problem to subtract, not solve. The machine will rarely offer you that path
itself — deleting a problem and solving one are different skills.

## 3. The green that never met reality

**Looks like**
Every automated check passing — tests, scans, structural review — describing a system that has
never actually been made to fail on purpose, on the real thing, by a real person.

**The question**
For the failure that would actually hurt, has it been *reproduced* — deliberately triggered and
watched, on the real, assembled system — or only *asserted* by a passing test?

**If the answer is "the tests are green, so"**
That's not evidence, it's the absence of evidence. Go trigger the failure yourself and watch the
real screen.

## 4. The honest limit of your gates

**Looks like**
A clean review, a clean scan, a clean checklist — describing a system that still does the wrong
thing the one time the real world misbehaves in a way none of those checks was built to see.

**The question**
Name, out loud, the last thing each gate you rely on can actually see, and the first thing it
can't.

**Remember**
A clean automated pass is a floor, never a certificate. It verifies the thinking was complete
enough to be judged — the judgment, and the proof against reality, stay human work, on real
hardware, past the edge of every check you can name.

In every case, once a control failure is confirmed, the question is never just "what broke?" It's
*"what else got through?"* — the same gap, on other accounts, during the same window. Scope first,
patch second.

---

# Appendix G — The Always-Scan List

*What actually stands in for a deterministic checker in this book: not a separate tool, but the
SecOps Agent's own fixed, published rulebook — the same list Prompt 3 excerpts (labeled "core"
there, since it's shown alongside the full role prompt), reproduced here in its entirety so you can
copy it into a workflow of your own.*

## What it is

A short list of patterns, checked on sight, no judgment call required, against every diff any role
prompt's authority produced:

```
UserDefaults near a token, a credential, or account data
Credential shapes: sk-, "Bearer ", a hex or base64 run over 32 chars
Double in any financial path
try? discarding an error; an empty catch block
print() anywhere; a sensitive value in any log call
[weak self] missing in a stored closure
An always-available accessibility flag on stored secrets
```

That last one is platform-specific: this book's app flags `kSecAttrAccessibleAlways` on the iOS
Keychain, and you swap in your own platform's equivalent.

It is not an AI, and that's the design, not a limitation. The same input produces the same output,
forever, and every rule on the list is short enough to read in one sitting — your most skeptical
reviewer can audit the whole thing before lunch.

## Extending it

A rule earns a place on this list only after a real failure your organization actually saw, added
one at a time, with a note on what it would have caught. If a proposed rule needs judgment — "does
this *seem* risky" — it doesn't belong here; that's a human's call at a seam, not a pattern a
machine can flag on sight. The thing that checks the boundary must stay simpler than the thing it
bounds.

## Its honest limits

This list catches patterns, not intent. It cannot tell you whether an approved architecture is the
*right* one, and it cannot see whether a boundary that passed every scan actually holds under a
real failure on real hardware — that gap is Chapter 11's third and fourth failure modes, named in
the book on purpose. Pattern-matching is the part software can do cheaply and reliably. Everything
past that is yours to check.

## Where the live version lives

The list above is a snapshot. The actual, currently-maintained file — `prompts/roles/secops.md` —
lives in the companion repository at `github.com/solarspin/SACS`, the same repo Chapter 5's
Follow Along box has you clone. Add rules there as your own build earns them; don't let this
printed page fall out of sync with the one your SecOps Agent actually runs against.
