# Appendices

*Version 2026-08-03 · pre-press. Tracks the manuscript of "Agentic AI Control Point." Where this file and a printed page disagree, this file is the corrected one.*

# How to Use These Appendices

The chapters explain why the method works. These five appendices are the method itself, in the
form you need to run it — everything required to stand up the Control Point system on a project of
your own, without going back through the book to reassemble it.

**Appendix A — The Four Questions**
What every role prompt has to answer before an agent is allowed to run. Use it when you write your
roster.

**Appendix B — Architecture and Audit-Trail Checklist**
The enforcement ladder and the five properties of a trail worth keeping. Use it at Seam 2, and
again periodically after production.

**Appendix C — Mission Brief Template**
The blank first artifact. Use it before anything else exists.

**Appendix D — The Seam Sign-off Procedure**
The signature standard and all four seam checklists. Use it every time you sign anything.

**Appendix E — Running the Four Seams on a New Project**
The order of operations, phase by phase, naming which of the above you need at each step. Start
here.

Two more — Appendix F (Failure-Mode Diagnostic Guide) and Appendix G (The Always-Scan List) — are
in the supplementary reference section. Neither is needed to start.

## What this covers

The Control Point system governs **both** — a fleet of agents building something, and a system of
agents running in production once it's built. The same four seams, the same four questions, the
same signature standard.

That works because the seams are not stages of a build. They are the four points where authority
changes hands, and those points exist in a running system exactly as they do in a build:

**Seam 1 — Strategy & Requirements.**
Building: what are we making, and what must it never do. Running: what may the live system decide
on its own, and what must it never do. The same question, asked of a different subject.

**Seam 2 — Architecture & Security.**
Building: the contracts, and the fences between components. Running: the fences between agents —
which one owns which action, who can override whom, and what no amount of agreement between them
can authorize.

**Seam 3 — Engineering Overwatch.**
Building: watch the build loop, step in when it circles. Running: watch the live system, step in
when it does. This seam was always about a loop that is supposed to run without you; a production
system is that loop with the stakes turned up. The run ledger becomes the intervention log.

**Seam 4 — Final Sign-off.**
Building: cleared to ship. Running: cleared to operate — this configuration, this environment,
today — and signed again when any of that changes.

Appendix A's four questions apply on both sides too, and get written twice: once for each member of
a build fleet, in its role prompt, and again for every agent that will still be running after you
ship. That second set is a description of your product's behavior, and writing it is Seam 1 and
Seam 2 work, not a separate discipline.

## When the decision is faster than a human

Some running systems act on a clock no human can be inside. A vehicle that loses the track boundary
has a few hundred milliseconds; nobody is going to be paged and answer in time. It is tempting to
read that as a hole in the method — a gate nobody can stand at.

It isn't, because a control point never meant a human present at the moment of action. It meant a
human having decided, in writing, before that action was possible. When there is time to ask, the
decision takes the shape of an escalation: a trigger, a named recipient, and a clock. When there
isn't, the decision takes the shape of a **default action, chosen and signed in advance** — stop
the car, refuse the trade, hold the position, fail closed. Both are human decisions. What changes
is *when you are asked*, never *whether*.

So the fast path is governed like any other: name the condition, name the action it triggers, and
sign it at Seam 1. Then Seam 2 checks that the action can actually fire — that the component
holding it needs nothing from the components that may have just failed. Then Seam 4 makes it
happen on the real system and watches it, because a default nobody has ever triggered on purpose is
a claim, not a control.

A signed default is a control point. An unsigned one is a developer's guess wearing a control's
clothes — and the difference between them is not in the code, which looks identical either way. It
is in whether a human decided it, wrote it down, and put their name on it.

## Two ways to start

**By hand**
Read Appendix E, then work its six phases in order. It tells you what to produce at each step and
which appendix to produce it with. This is the slower path and the one that teaches you the most,
because every artifact passes through your own judgment on the way in.

**By handing the setup to an AI agent**
The scaffolding — directories, file skeletons, first-draft role prompts, the four seam procedures
copied in with their checklists — is ceremony, not signature. It is exactly the kind of work the
machines should carry. Give an agent the text of Appendices A through E along with the facts about
your project, and it can have a governed repository standing in front of you in minutes.

That is the faster path, and it is legitimate — but only if you draw the boundary first, in
writing, before the agent runs. The prompt below draws it.

## The setup prompt

**Don't retype this.** All of it — this prompt, every checklist, and the templates — lives in the
companion repository at `github.com/solarspin/SACS`, in the `appendix/` folder. The prompt on its
own is `appendix/setup-prompt.txt`, and Appendices A through E, in full, are
`appendix/appendices-a-e.md` — the file to hand your agent. Type one path instead of forty lines;
selecting text out of a book is a fight on a tablet, worse on an e-reader, and impossible on paper.
The copy in the repository is also the one that gets corrected when something in it turns out to be
wrong. A printed page can't be.

What follows is the same prompt, printed so you can read what you're about to hand an agent before
you hand it over. Fill in the bracketed lines with your own project's facts; leave the rest exactly
as written.

```
Read the appendix material I am giving you — Appendices A
through E of "Agentic AI Control Point." Then set up a new project.

MY PROJECT
  What it is:              [one clause]
  Capabilities:            [name them; nouns, not adjectives]
  It must never:           [the absolutes]
  A failure would cost:    [the real asset at stake]
  Agents I plan to run:    [how many, and doing what]
  Who owns what:           [what each agent may do that no other
                           may; who can override whom, and who
                           cannot; anything only one of them holds]
  Language / platform:     [yours]

WHAT TO PRODUCE
 1. The repository layout from Appendix E, created for real.
 2. architecture/MISSION.md — a DRAFT mission brief in Appendix
    C's template, filled from MY PROJECT above. Leave the
    wrong-cost sentence and the walk-away line marked [DECIDE].
    Also create architecture/PLAN.md as an EMPTY stub carrying
    only its unsigned Seam 2 record — it is a Phase 3 artifact
    and you are not the one who writes it.
 3. prompts/roles/<role>.md — one draft role prompt per agent,
    each answering Appendix A's six questions, with a ceiling on
    every authority and a trigger, a named recipient, and a clock
    on every escalation. Mark [DECIDE] wherever a ceiling needs a
    number I have not given you.
 4. seams/seam-1.md through seam-4.md — the four procedures from
    Appendix D, each carrying its full checklist, marked v1.0.
    Seams 1, 2, and 4 each get an EMPTY sign-off record. Seam 3
    gets an EMPTY run ledger instead — it is not a gate, and
    Appendix D says so.
 5. DECIDE.md at the repository root — every [DECIDE] you left,
    in one file, so I can work through them in one pass. Group
    them by whether getting one wrong would cost more than
    changing it later.

WHAT YOU MAY NEVER DO
  - Never fill in a signature, a name, or a date. Every sign-off
    record ships empty.
  - Never invent a number I did not give you. A missing threshold
    is a [DECIDE], not a sensible default.
  - Never mark a checklist item as done, checked, or passed.
  - Never drop or soften an item from the appendix checklists to
    fit my project. If one does not apply, leave it in and flag it.
  - Never write implementation code. This assignment produces
    governance artifacts and directory structure only.
```

## Read the boundary you just wrote

That last block is not boilerplate. It is the first control point in your project, and it is worth
seeing for what it is: you just answered the four questions of Appendix A about an agent, before
letting it run. What it may decide — file layout, draft wording, structure. What it must escalate —
every `[DECIDE]`. What it may never do — sign, invent a threshold, mark anything passed, weaken a
checklist. How you would find out — the `[DECIDE]` list it hands back, and four sign-off records
that are visibly, checkably empty.

An agent that returns a repository with a signature already in it did not save you the setup work.
It removed a decision, and the whole method is the distinction between those two things.

What comes back is a draft. It is not signed, and nothing in it has passed a gate. Open Appendix E
at Phase 1 and start where you would have started anyway: the mission brief is yours to finish, the
Seam 1 checklist is yours to run, and the signature at the bottom is yours to write. The machine
built the room. You still have to be the one standing in it.

*A worked example of every artifact named here — real mission brief, real role prompts, real signed
seam records — lives in the companion repository at `github.com/solarspin/SACS`. Point your agent at
it if you would rather it copy a working shape than infer one.*

---

# Appendix A — The Four Questions, Quick Reference

## The four questions

**1. What may the AI agent decide entirely on its own?**

**2. What must it escalate to a human — and to whom, by name or role?**

**3. What may it never do, under any circumstances?**

**4. How would anyone find out?**

They are questions about authority, not technology. If you can answer all four, in writing, in a
form a stranger could check — you have a control point. That phrase sits in this book's title, not
by coincidence: this is the actual point where control either exists or doesn't. If you can't
answer all four, you have a hope.

## The six questions every role prompt has to answer

A role prompt is where these four questions get written down for real, and it earns its
authority by answering two more alongside them — six in fixed order, and every one has to be
checkable by someone who has never met you:

```
THE AI AGENT'S JOB
One or two sentences: what it does, on what schedule, feeding what.

MAY DECIDE
The authority, with its ceilings — amount, count, category, time.

MUST ESCALATE
Triggers, a named recipient (role + roster is fine), and a clock.

MAY NEVER TOUCH
Absolutes only. No hedge words survive here.

AUDIT TRAIL
What's recorded, where it lives, who reads it, on what schedule.

FAILURE LOOKS LIKE
The observable events that mean a control has failed — each one
traceable to a line above it.
```

There is no second document that restates these in a different format. The role prompt that
boots the AI agent is the same file a human reads to know what it may do — see Chapter 6. The six
names above are the abstract test; the real prompts in the repository answer the same six under
their own concrete headers — IDENTITY, CONTEXT YOU RECEIVE, NON-NEGOTIABLE RULES, OUTPUT FORMAT,
ESCALATION, ASSIGNMENT. Different labels, same six questions — check a real prompt against this
list by content, not by matching header text.

## The rules, one line each

**Every grant of authority needs a ceiling.**
The four flavors, whatever the domain: amount (under $2,500; never above 90 km/h), count (one per
7 days; three retries), category (approved templates only; these three endpoints), time (15–45
days past due; business hours only).

**Every escalation needs three parts.**
A trigger, a named recipient an actual person occupies today, and a clock. No clock means a
suggestion. No recipient means a status field.

**Hedge words are structural failures in MAY NEVER TOUCH.**
*Generally, typically, usually, where possible, should avoid, in most cases.* A boundary with an
exception clause is an invitation with extra steps.

**A "never" with legitimate exceptions isn't a never.**
It's an escalation — move it up a section and give it a trigger, recipient, and clock.

**An audit trail exists for a reader.**
Name the reader, and the day of the week their eyes land on it.

**FAILURE LOOKS LIKE turns boundaries into tripwires.**
Without it, a crossed line gets treated as a bug. With it, the right question gets asked: not
"what broke?" but "what else got through?"

---

# Appendix B — Architecture and Audit-Trail Checklist

*The Chapter 5 material in checkable form. Run it against any AI agent workflow before — and
periodically after — production.*

## The enforcement ladder

For every MAY NEVER TOUCH line in a role prompt, name the rung it actually sits on today:

**Rung 1 — the prompt asks nicely.**
The instruction exists in the role prompt and nowhere else. Acceptable for style preferences.
Never acceptable for MAY NEVER TOUCH.

**Rung 2 — instructions plus after-the-fact monitoring.**
Someone would notice a violation once it already happened. A smoke alarm: valuable, and it has
never prevented a fire.

**Rung 3 — a hard pre-action check.**
Ordinary deterministic code, outside the model, unpersuadable by phrasing, blocks the action
before it fires. The minimum rung for every MAY NEVER TOUCH line.

**Rung 4 — structural impossibility.**
The AI agent lacks the permission, credential, or access to attempt the action at all. Not
available for every boundary; worth taking everywhere it is.

☐ Every MAY NEVER TOUCH line sits on rung 3 or 4

☐ Every rung-3 check runs at action time, not queue time — the gap between the two is where
near-misses live

☐ Any line still on rung 1 or 2 is documented as such, with a reason, in writing

## The audit trail — five properties

☐ **Timestamped** — to the action, not the day

☐ **Tied to a specific case** — filterable down to one account, one event, one date

☐ **Carries the rationale** — "sent reminder" is an event; "sent reminder — 45 days, $1,840, under
both ceilings, no hardship flag" is evidence

☐ **Records blocked attempts, not just completed actions** — the single most valuable line in any
trail is the one proving a boundary was tested and held

☐ **Queryable by someone who isn't its builder** — otherwise it's a diary, whatever it contains

## Escalations that interrupt

☐ Fires a notification to the named recipient specifically — not a shared inbox

☐ Starts a clock that something else is tracking

☐ A missed clock escalates again, upward — an escalation without a second escalation behind it is
a single point of failure wearing a process's clothing

## Access

☐ The AI agent sees only the data its stated job requires — mapped, granted exactly, nothing
adjacent ("it has access to the data warehouse" is a finding, not a feature)

☐ The decision logic runs as its own bounded service with its own ledger — its blast radius
visible in the architecture diagram as a box with edges

☐ No vendor claim stands in for evidence anywhere on this list — your architecture is the evidence

---

# Appendix C — Mission Brief Template

*The Chapter 3 artifact, blank. One paragraph, four required elements — the highest-leverage
prompt in the project, because it's the first thing the Product Agent reads and everything it
writes traces back to it.*

```
MISSION BRIEF — [project name]

Build and ship [project name], [what it is, one clause]:
[list every capability, however many there are, separated by
commas with "and" before the last] — written by a fleet of AI
agents operating under named human control at every seam, to
production discipline from the first commit. Done means
every capability clears the bar in its row of the capability map,
and every line the AI agents wrote passed a human gate that
produced evidence a reviewer could check. If it is built wrong,
the cost is not a bug ticket: [the specific, named consequence]
spends [the actual asset at stake — not "reputation" in the
abstract]. If it cannot be built to that bar, it does not ship.
```

The four elements, checked separately:

**What, specifically**
The capabilities, named, not adjectives. "Biometric sign-in with role-based access," not "secure
login."

**The bar**
Production discipline and human gates as a *condition* of the build, not an aspiration bolted on
after.

**The wrong-cost sentence**
What a failure actually costs, priced before anyone prices the build. Name the real asset at
stake. This is the sentence that separates a governed build from a fast one.

**The walk-away line**
What happens if the bar can't be met, decided now, so "ship it anyway" never becomes the default
under deadline pressure.

Two rules of use. First: no element without a number or a name attached — "secure" and "as
quickly as possible" are the tells of the brief fear writes, not this one. Second: hand the
finished paragraph to one colleague and ask *"From this alone, what happens if we build it
wrong?"* If they can't answer in one sentence, the wrong-cost sentence isn't done.

---

# Appendix D — The Seam Sign-off Procedure

*The Chapter 7 material in checkable form: one signature standard and four procedures. For each
seam — what arrives, what you check, what act constitutes your signature, and what evidence that
act leaves behind.*

## What a signature has to have

Four properties. A sign-off missing any one of them is a thumbs-up wearing a procedure's clothes:

☐ **It names the exact object** — a commit hash, a file version, a build number. What was signed
cannot silently change after the signing.

☐ **It names the procedure** — the checklist and its version, so anyone can reconstruct what
"looked it over" actually covered.

☐ **It records findings** — what was caught, what was returned, what was accepted with
reservations. A seam that never records a finding is either guarding perfect machines or has
stopped looking.

☐ **It names a person and a date** — not "the team," not "reviewed by engineering."

Every seam's record takes the same shape:

```
SEAM <N> SIGN-OFF — <what was reviewed>

Reviewed:  <exact object — commit hash, file version, build number>
Procedure: <checklist file> v<version> — all items run
Found:     <findings and their dispositions; "none" only when true>
Signed:    <name>, Seam <N> (<which hat>) — <date>
```

A procedure file starts at **v1.0** the day you write it, and its version goes up when the
checklist changes — never when you sign. That version number is the one figure you may set without
deciding anything, because it labels a document rather than governing behavior: "never invent a
number" is about thresholds an agent would then act on, not about naming the edition of a checklist.

## The four seams at a glance

**Seam 1 — Strategy & Requirements**
Arrives: nothing — you initiate, with the mission brief and compliance checklist in hand.
Check: the Seam 1 list.
Signature: a dated line in the mission file, committed by you.

**Seam 2 — Architecture & Security**
Arrives: a contracts-only pull request.
Check: the Seam 2 reading protocol.
Signature: the merge itself, plus a dated line in the architecture plan.

**Seam 3 — Engineering Overwatch**
Arrives: a running loop — cycle counts, STOP reports, diffs in flight.
Check: tripwires, not a queue.
Signature: a run-ledger entry per intervention, the ledger reviewed every sprint. This one is not
a gate, and the discipline is refusing to make it one.

**Seam 4 — Final Sign-off**
Arrives: the evidence package.
Check: the evidence review, then the live session on the real system.
Signature: the deploy, executed by you, with credentials only you hold.

## Seam 1 checklist

☐ Every capability has a bar a test could check — no "works well," no "feels fast."

☐ The wrong-cost sentence is priced. If it still says "would be bad," it isn't done.

☐ The scope-outs are explicit, written, and phrased so an AI agent can be held to them.

☐ Every threshold is an actual number. An agent can escalate a number; it cannot escalate
"reasonable."

☐ The compliance checklist is attached, and every row names its enforcer and where the evidence
lives. If no external regime governs this project, that is a finding to record, not a row to skip:
write down which standard you are holding yourself to instead and attach *that* — a checklist you
chose is still a checklist, and "nothing applies to us" is a claim that should appear in writing,
signed, rather than as an empty folder.

Cheapest seam in the pipeline, and the only one that can doom the project by itself: everything
downstream verifies the product against this brief, including a wrong one.

## Seam 2 reading protocol — run all items, in order

☐ **1. Just definitions?** Only names, shapes, and what talks to what — with no working code snuck
in. Real logic in a contracts PR is a finding, however good it looks.

☐ **2. Does the map match reality?** The PR says which packages each one may use. Do the actual
manifests on disk say the same? The compiler has to enforce what the diagram promises.

☐ **3. Follow the sensitive values.** Take a token, a balance, a password, an account number. For
each, follow where this structure lets it travel — could it reach a log, a cache, or a component
with no business seeing it? Catch the leak while it's still a line in a protocol.

☐ **4. Does every requirement have a home?** For each thing the approved stories say the feature
must do, is there a piece here responsible for doing it? A requirement with no home is a missing
contract.

☐ **5. Are all the open questions answered?** Every question flagged as unanswered has a written
human answer. A question that crosses this gate becomes an agent's guess.

☐ **6. Are the exact values exact types?** Any value that must never drift — money, a count, a
threshold something gets compared against — carries a type that guarantees exactness, never a
floating-point number that can round. In a financial system that means money is a decimal type and
never a plain number; in a physical one it means a measured limit isn't quietly re-rounded on every
pass. One wrong one becomes thousands of generated lines of drift.

☐ **7. What happens when it fails?** For any sequence of states: is every state reachable, every
step allowed, and are the failure states there? A design with no failure states is one nobody
imagined failing.

☐ **8. Pick one and explain it.** Choose any contract at random and say out loud what it's for and
why it's shaped that way. If you can't, you're skimming — don't merge.

Findings go back to the agent that produced them; re-review the fix. Time-box this to an hour of
real attention. If it's taking a week, the contracts are too big, and that is the finding. The
protocol never asks whether the design is the one you'd have drawn: "not how I'd do it" is a
conversation, "the token can reach a log" is a finding.

## Seam 3 tripwires — step in when one fires, and not before

☐ **Three cycles, same error.** The loop counts its iterations and is ordered to stop and summon
you after three on the same error. The tripwire lives where the loop can read it.

☐ **Any STOP report.** A missing contract, an ambiguous requirement, work that would cross a
fence. A STOP is the system working — answer it like a page, not like spam.

☐ **The diff is wandering.** Cycle five touches files cycle one never did. Local fixes don't
spread; confusion does.

☐ **The fix loop reaches for a test.** Any change that would weaken, skip, or delete a test to get
to green. The prompts forbid it; the tripwire assumes prompts fail.

The intervention protocol, when one fires:

**1. Don't type into the loop.**
Another prompt into a circling session is another shovel into the hole.

**2. Diagnose the mechanism yourself.**
Reproduce it, read the error's history across cycles, find what the machine is missing. The
description is the work.

**3. Boot a fresh session.**
Role prompt, plan, assignment, plus your diagnosis stated as a constraint.

**4. Put the lesson where it persists.**
If it generalizes, it goes into the role prompt, in its own commit, before the fresh boot. The
prompt is the persistent artifact.

Then log it — one run-ledger entry per intervention: what looped, the diagnosis, what changed
(context, constraint, or prompt version), and the prompt version after. Review the ledger once a
sprint, whole: three interventions for the same class of confusion is not three fixes, it's one
missing rule.

This seam has **no sign-off record**, and that is deliberate — the ledger is its artifact. Every
other seam gates a thing before it moves; this one watches a loop that is supposed to run without
you. Give it a signature block and you have quietly converted the one seam that isn't a gate into
a fourth gate you now have to staff.

## Seam 4 — evidence review, then the real thing

The evidence package must prove itself:

☐ Every capability bar in the mission brief traces to at least one passing test derived from its
criteria. Bars without tests are promises without guarantees.

☐ Every security BLOCKER in the sprint history was closed by a fix that was re-scanned — not by an
argument.

☐ Every compliance row's evidence exists at the location the row names. The checklist says where;
you go look.

☐ Every UNCONFIRMED/FLAGGED line from every self-report this sprint has a human disposition:
verified, accepted with reason, or fixed. Flags nobody read are flags the system raised for no one.

The live session — on the real system, not a simulator:

☐ Exercise every role. Feel the failure paths — do they degrade the way the policy says, or merely
somehow work?

☐ Try to do the wrong thing on purpose: exceed a limit, act above your role, replay a stale
session. Read every refusal the way an attacker would.

☐ Interrupt it mid-operation — cut the network, kill the process, pull the power. What does the
system believe afterward, and what does whoever depends on it see that tells them?

☐ The unwritable item: would you put your own money, or your own name, through this build today?
If the answer has a "but," the "but" is a finding.

Findings, then dispositions, then the act: the release, executed by you, with credentials that exist
only in your hands. The live session is not repeating the tests by hand — the suites already proved
the criteria. You are hunting what automation structurally cannot judge: whether refusals read
clearly, whether a fallback feels trustworthy or merely functions.

## Budgeting the attention

Seams don't die from being skipped. They die from being run out of budget: week one you trace
every path, week four you're skimming, and the review that mattered gets the attention the
previous thirty-nine trained you to give it. Two questions set the depth of any review — is the
machine reliable at this kind of work, and would a mistake be cheap and visible, or expensive and
invisible?

**Reliable work, cheap and visible mistake**
Skim. The structure already guards it.

**Reliable work, expensive or invisible mistake**
Verify the guardrail exists, then sample.

**Unreliable work, cheap and visible mistake**
Let the loop and the tests catch it.

**Unreliable work, expensive or invisible mistake**
Deep read, every time: crypto, key storage, auth flows, money math, state machines, anything
concurrent.

Every checklist above is weighted toward that last cell. The checklists tell you *what* to check;
these two questions tell you *how hard to look* — and give you permission to skim the first case
with a clear conscience, which is what makes the last case sustainable for years instead of weeks.

## Signing alone — the four rules

When the signer and the signed-off are the same person, the signature survives on four rules:

☐ **Never sign in the session that produced the work.** The hat that builds and the hat that signs
must not share a context window. Sign Seam 2 after lunch; sign Seam 4 tomorrow. Time is how one
person buys the distance a second person would have provided.

☐ **The checklist is the colleague.** Run it aloud, item by item. Skimming silently feels like
reviewing; explaining to an empty room does not survive not-knowing.

☐ **Record findings even when no one will read them.** The moment sign-offs stop containing
findings is the moment the seam became a ritual. You in six months is the auditor.

☐ **Let deterministic tools be the second person.** A compiler refuses a forbidden import no matter
how tired you were when you wrote it. A pattern scanner flags a credential-shaped string with no
opinion about who wrote it. Neither is impressed by fluency — and the person most fluent in the
rules is the person most able to skim past their own violation of one.

One rule governs every shortcut you will be offered: **automate the ceremony, never the
signature.** If it removes keystrokes, take it. If it removes a decision, it isn't a shortcut.

---

# Appendix E — Running the Four Seams on a New Project

*The order of operations, start to finish. Everything below is the book's method stripped to a
sequence: what you produce, which appendix you use, and what you cannot start until you've signed.
Chapters 3 through 8 are where the reasoning lives; this is the running order.*

*The phases below are written for a fleet building something, because that is the longer path and
the one with more moving parts. If your system will itself run agents in production, the same four
seams govern it — read "what the fleet produces" as "what will be running," and see "What this
covers" and "When the decision is faster than a human" at the front of these appendices.*

## Before anything — the decisions that aren't in a file yet

**Name the seams.**
Write the four seams down a page and put a real, specific name on each. A role is not a name;
"someone senior" is nobody. The same name at more than two seams is a finding, not a convenience —
and if you are solo, that finding is the reason Appendix D's four solo rules exist.

**If a seam crosses an organizational boundary, settle it before the fleet runs.**
A pipeline that spans departments, contracts, or two vendors' toolchains has the same four seams,
but the name on each becomes a negotiation rather than a decision you make alone. Three questions
settle it, and all three are far cheaper to answer now than mid-sprint. Whose name goes on a seam
the work passes through but no single team owns? Whose signature counts when two toolchains meet in
the middle and each produces its own records? And who is authorized to refuse on a Friday when the
release has already been announced? None of these is a technical problem, and no framework answers
them for you. They are the same negotiation your organization already had about who may approve a
purchase order, arriving again about something that moves considerably faster.

**Fix the count.**
Four seams, whatever the size of your fleet. Gates are not keyed to how many agents you run — they
sit at the four points where the cost of a mistake inflects, and a fleet of three agents and a
fleet of twelve cross the same four lines. The test for any fifth seam you're tempted to add: *can
the human at this line afford to run its full procedure, every time, indefinitely?* If no, it's a
future rubber stamp, and the kindest thing is to not install it.

## The repository layout

Every artifact below is a file in the project repository, versioned with the code it governs.
Nothing lives in a wiki, a ticket, or a chat log — a governance artifact that isn't in the repo
isn't in the build:

```
architecture/
  MISSION.md          the signed mission brief (Seam 1)
  PLAN.md             the signed architecture plan (Seam 2)
seams/
  seam-1.md           the procedure, and its sign-off record
  seam-2.md           …one file per seam, each carrying its own
  seam-3.md              checklist version and its signed records
  seam-4.md
prompts/roles/
  <role>.md           one role prompt per agent, each ending in an
                      ASSIGNMENT block that gets replaced per sprint
requirements/
  <sprint>-stories.md approved stories, with escalations and decisions
reports/
  <sprint>-<role>-self-report.md    what each agent did, its
                      assumptions, its defaults, and its flagged items
security/
  <compliance>-checklist.md         each row: requirement, enforcer,
                      where the evidence lives — an external regime's
                      if one governs you, your own chosen bar if not
```

## Phase 1 — Write the brief, sign Seam 1

Produce `architecture/MISSION.md` using Appendix C. Attach the compliance checklist — the external
regime's if one governs you, and the standard you have chosen to hold yourself to if none does.
Then run the Seam 1 checklist in Appendix D, record what you found, and sign the dated line at the
bottom of the file. Commit it.

Nothing else starts until this is signed. Everything downstream verifies the product against this
brief — a fleet working from an unsigned or vague mission builds the wrong thing with perfect
discipline, and every later seam will correctly certify that the wrong thing was built well.

## Phase 2 — Write the roster

Produce one role prompt per agent under `prompts/roles/`. Each answers the six questions in
Appendix A: the job, may decide, must escalate, may never touch, audit trail, failure looks like.
Ceilings on every authority. A trigger, a named recipient, and a clock on every escalation. No
hedge words anywhere in may-never-touch.

Three rules make the roster hold. First, no agent vouches for its own work — the agent that writes
and the agent that checks are different agents with different prompts. Second, every rule in a
prompt has to be checkable by a stranger; if you can't say how anyone would find out it was broken,
it isn't a rule yet.

Third, write down what each agent *exclusively* owns, and put it in the prompts on both sides of
the line. Most real boundaries come from ownership rather than from a list of forbidden verbs: if
one agent alone may perform some action, then its prompt says it owns that action and every other
prompt says it may only request one. Ownership also decides what happens when two agents disagree,
which is the case a roster written as six independent job descriptions will not cover. Name the
overrides too — who can countermand whom, and who can countermand no one.

Give every prompt an escalation triage it can run without you: *would getting this wrong cost more
than changing it later?* No — resolve it and record it as a `DEFAULT:` line in the self-report.
Yes — stop, and write the decision up for the seam. This is what keeps your attention for the
decisions that stop the line instead of the ones that don't.

## Phase 3 — Design the contracts, sign Seam 2

The architecture agent produces a contracts-only branch: interfaces, module boundaries, schemas,
dependency graph, no implementation. Alongside it, `architecture/PLAN.md` — the layer rules, the
fences, the types that guard the values that matter.

Run Appendix D's eight-item reading protocol and Appendix B's enforcement-ladder and audit-trail
checklists against it. Every may-never-touch line has to sit on rung 3 or 4 — a hard pre-action
check or structural impossibility — not on "the prompt asks nicely."

Sign by merging, and by dating the line in `PLAN.md`. Until you merge, the implementing agents have
nothing to build against: the wrong sequence isn't discouraged, it's structurally unavailable.

## Phase 4 — Run the build loop, watch Seam 3

The implementing, scanning, and compiling agents run their loop without you. You are not in it —
compile errors are the one failure class the machine diagnoses faster than you do, and a human
queued into that loop is its slowest component.

Watch for the four tripwires in Appendix D. When one fires, run the intervention protocol: diagnose
the mechanism yourself, boot a fresh session with your diagnosis as a constraint, and put any
generalizable lesson into the role prompt before the reboot. Log every intervention in the run
ledger. Review the ledger once a sprint.

## Phase 5 — Verify and ship, sign Seam 4

The testing agent — which derives its tests from the contract and has never seen the implementation
— assembles the evidence package. Run Appendix D's evidence review, then the live session on the
real system.

The fleet proves the code works. That is a fact, and facts can be automated. Whether it should be
trusted is a decision, and the decision is why there's a chair at this seam. Sign by deploying, with
credentials that exist only in your hands, and record the build number, the evidence package
version, the findings, their dispositions, your name, and the date.

## Phase 6 — The next sprint

Replace the ASSIGNMENT block in each role prompt. Everything else — the mission, the plan, the
prompts, the seams — persists and compounds. This is the whole economic argument: you paid for the
apparatus once, and the second feature costs a fraction of the first.

Two artifacts to keep current as you go. The role prompts, which absorb every lesson the run ledger
surfaces — the prompt is the persistent artifact, not the session. And the seam procedures
themselves, versioned, so a sign-off that names `seam-2.md v1.1` means something specific and
checkable years later.

When something goes wrong, and it will: Appendix F names the four failure modes and the question
that finds each one. Appendix G is the pattern list your scanner runs, and the rule for extending
it — one rule at a time, each earned by a real failure you actually saw.
