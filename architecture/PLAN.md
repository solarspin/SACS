# ARCHITECTURE PLAN — BankSmartAI
*Seam 2 signs this document before any code-writing AI agent boots.
Every role prompt quotes this plan; it is context at every fleet boot.*

## MODULES & ALLOWED DEPENDENCIES
    App            -> all packages (composition root only)
    BankAuth       -> BankCore, BankNetworking, BankDesign
    BankTreasury   -> BankCore, BankNetworking, BankDesign
    BankTransfers  -> BankCore, BankNetworking, BankDesign
    BankNetworking -> BankCore
    BankDesign     -> BankCore
    BankCore       -> (nothing)
Feature packages may NEVER import each other. The manifests enforce
this; a violating import is a build failure, not a review comment.

## LAYER RULES (non-negotiable)
- Views observe view models — never call services.
- View models call repositories — never construct URLs, never touch
  tokens.
- Only BankNetworking speaks HTTP; it owns the auth token.
- All money is Money (Decimal) — no Double in any financial path.
- All view models are @MainActor; async/await only; no completion
  handlers; no force unwrapping; no try? that discards an error.

## DATA RULE
Cache nothing by default. Anything cached: SQLCipher or Keychain-backed
AES-256, decided at Seam 1, in writing, per item.

## SECURITY SPINE
security/masvs-checklist.md — every row names an enforcer and an
evidence location. SecOps Agent rules derive from that file and only
that file.

## SECRETS
Secrets.xcconfig (gitignored) + fail-fast config. No credential ever
appears in a prompt, a source file, a test, or a log. The gateway's
demo credentials are fake by design.

## GATEWAY
Gateway/server.js — local mock banking core. Approval threshold
$10,000.00. Demo roles: owner@banksmart.test / staff@banksmart.test.
Failure injection: x-latency, x-fail, x-drop-after-accept headers.

SIGNED (Seam 2): Adam Fisher______________________  DATE: 07/15/2026__________
