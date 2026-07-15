# BankSmartAI

An iOS business banking app demo, built by a governed fleet of six AI
agents with a human at every seam — the working companion project of
the book *Control Point*.

- `architecture/MISSION.md` — the Mission Brief (Seam 1 signs)
- `architecture/PLAN.md` — the Architecture Plan (Seam 2 signs)
- `prompts/roles/` — the six AI agent role prompts (the fleet)
- `prompts/statements/` — Control Point Statements, one per agent,
  verified by ControlCheck before any agent boots
- `security/masvs-checklist.md` — the security spine
- `Gateway/` — the local mock banking core (`npm start`)
- `Packages/` — feature-per-package; the manifests are the fences

Demo only: mock gateway, fake credentials, no real money, ever.
