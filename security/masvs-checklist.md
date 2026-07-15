# BankSmartAI Security Checklist (MASVS-aligned)
*The security spine. SecOps Agent rules derive from this file. A rule
not in this file is not a finding — it is a proposal, decided by the
Seam 2 security lead. Every row: requirement, enforcer, evidence.*

| # | Requirement | Enforced by | Evidence |
|---|-------------|-------------|----------|
| S1 | No sensitive data in UserDefaults, plists, or unencrypted files | SecOps always-scan + Seam 4 review | SecOps report per PR |
| S2 | Cryptographic keys generated in the Secure Enclave, non-exportable | Sprint 1 contracts + Seam 2 human check | Seam 2 sign-off; Sprint 1 device verification |
| S3 | Auth tokens in Keychain, kSecAttrAccessibleAfterFirstUnlock (never ...Always) | Role-prompt rule + SecOps always-scan | SecOps report; Seam 4 checklist |
| S4 | No secrets in source, tests, or config in git | .gitignore + SecOps credential-shape scan | pre-merge scan output |
| S5 | TLS for all connections in release builds | Build configuration guard | Seam 4 checklist |
| S6 | No Double in any financial path — Money (Decimal) only | BankCore type design + SecOps always-scan | compile evidence; SecOps report |
| S7 | 401 handled as control signal (reauth), 403 surfaced truthfully | Architecture contracts + QA role-boundary tests | QA evidence package |
| S8 | Approval threshold enforced server-side; client never bypasses PENDING_APPROVAL | Gateway behavior + QA state-machine tests | QA evidence package |
| S9 | No sensitive values in logs; no print() | SecOps always-scan | SecOps report |
| S10 | try? never discards an error; no empty catch blocks | SecOps always-scan | SecOps report |
