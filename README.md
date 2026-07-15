# BankSmartAI

An iOS business banking app demo, built by a governed fleet of six AI
agents with a human at every seam — the working companion project of
the book *Control Point*.

## What this repo is, and why it exists

This is the book's proof, not its illustration. *Control Point* argues that a fleet of AI
agents can build production-grade software while humans hold real authority at real
checkpoints. This repo is that argument, actually run. The book cannot claim a real bank
deployed this method and measured the ROI — so it earns its credibility the only honest way
left: by building a real (if demo) app with the method, in the open, artifact by artifact, and
letting the reader watch. That's also why this repo stays messy and mid-history instead of
being cleaned up into a tidy appendix afterward — the book's Sprint chapters are written FROM
these commits, these SELF-REPORTs, these SecOps findings, these seam sign-offs. A polished
version built after the fact would just be inventing scenes with code instead of characters.

What running it actually teaches, concretely: that a signature is a specific, checkable act —
and startlingly easy to *feel* done without being done (ask the author about Seam 1's blank
signature line, or the underscore that wasn't a name); that governance artifacts here are
load-bearing, not decorative — the fleet structurally cannot boot past an unsigned
`MISSION.md` or `PLAN.md`; and that "software parts are the business parts" is not a slogan —
the compliance, risk, and sign-off content of this project live entirely inside engineering
artifacts (a checklist, a manifest, a commit), never inside an invented boardroom. One rule
holds at every scale in this repo, from the `.claude/commands/` boot rituals to the
Control Gates Panel to the seams themselves: **automate the ceremony, never the signature.**

## What's in it

- `architecture/MISSION.md` — the Mission Brief (Seam 1 signs)
- `architecture/PLAN.md` — the Architecture Plan (Seam 2 signs)
- `prompts/roles/` — the six AI agent role prompts (the fleet)
- `prompts/statements/` — Control Point Statements, one per agent,
  verified by ControlCheck before any agent boots
- `security/masvs-checklist.md` — the security spine
- `Gateway/` — the local mock banking core (`npm start`)
- `Packages/` — feature-per-package; the manifests are the fences

Demo only: mock gateway, fake credentials, no real money, ever.
