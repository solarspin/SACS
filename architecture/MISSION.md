# MISSION BRIEF — BankSmartAI
*Seam 1 artifact. Signed by the human at Seam 1 before any AI agent boots.*

Build and ship BankSmartAI, an iOS business banking app: biometric
sign-in with role-based access, a treasury view whose balances, runway,
and money flows are derived exactly from the ledger in decimal-precise
types, and money movement with limits, MFA, and dual-authorization
approvals — no single role moves large money — written by a fleet of AI
agents operating under named human control at every seam, to production
discipline from the first commit. Done means every capability clears
the bar in its row of the capability map, and every line the AI agents
wrote passed a human gate that produced evidence a reviewer could
check. If it is built wrong, the cost is not a bug ticket: a wrong
balance, a double-executed transfer, or a payment that moved without
its approval spends the one asset banking software runs on — the user's
belief that the number on the screen is true and the controls are real.
If it cannot be built to that bar, it does not ship.

THRESHOLDS: any transfer over $10,000.00 parks in PENDING_APPROVAL
until an owner-role human approves it — dual control is a state, not a
screen. The staff role can initiate but never approve; an approval
attempt by staff is refused (403), and that refusal is a feature with
an acceptance criterion, not an error.

SCOPE-OUT (v1): BankSmartAI v1 does not include card issuing or goal
tracking beyond runway; nothing an AI agent generates may reference
them.

COMPLIANCE: the attached security standard is
security/masvs-checklist.md — every row names its enforcer and its
evidence location, and the SecOps Agent's rules derive from that file
and only that file.

SIGNED (Seam 1): Adam Fisher          DATE: 07-15-2026
