# BankSmartAI Mock Banking Gateway

Local, deterministic, zero dependencies, no real money ever.
Run: `npm start` (port 4000). Reset to seed data: `POST /reset`.

Demo logins (fake by design — printable in a book):
- owner@banksmart.test / owner-demo-1  (role: owner — may approve)
- staff@banksmart.test / staff-demo-1  (role: staff — 403 on approvals)

Endpoints: POST /auth/login · GET /accounts · GET /accounts/:id ·
GET /accounts/:id/transactions · POST /transfers · GET /transfers/:id ·
GET /approvals · POST /approvals/:id/approve|reject · GET /health ·
POST /reset

Transfers over $10,000.00 park in PENDING_APPROVAL until an owner
decides. Settlement is asynchronous: INITIATED/APPROVED → PENDING →
COMPLETED (~4s). Failure injection headers: `x-latency: <ms>`,
`x-fail: <status>`, `x-drop-after-accept: true` (accepts the transfer,
stores it, then kills the connection before responding — the gap
between reported and true).

## Request/response examples

All authenticated requests: `Authorization: Bearer <token>`.
All amounts everywhere are positive decimal strings (`"250.00"`) —
never numbers, never floats. Account ids: `acct-operating`,
`acct-reserve`, `acct-savings`.

**POST /auth/login**
```
{ "email": "owner@banksmart.test", "password": "owner-demo-1" }
→ 200 { "token": "<jwt>", "role": "owner", "expiresInSeconds": 3600 }
→ 401 { "error": "invalid credentials" }
```

**GET /accounts**
```
→ 200 { "accounts": [ { "id": "acct-operating", "name": "Operating",
        "type": "operating", "balance": "8600000.00",
        "currency": "USD", "dividendRatePercent": "0.00" }, … ] }
```

**POST /transfers** — field names are `from` and `to` (account ids):
```
{ "from": "acct-operating", "to": "acct-reserve",
  "amount": "12500.00", "memo": "optional" }
→ 200 { "id": "tr-0001", "from": "acct-operating",
        "to": "acct-reserve", "amount": "12500.00",
        "currency": "USD",
        "state": "PENDING_APPROVAL",     ← or "INITIATED" at/under
        "initiatedBy": "<email>",           the $10,000.00 threshold
        "createdAt": "<iso-8601>",
        "approval": { "requiredRole": "owner", "decidedBy": null,
                      "decidedAt": null } }   ← null when no approval
→ 400 { "error": "invalid from/to account" }     (unknown id, from == to)
→ 400 { "error": "amount must be a positive decimal string,
        e.g. \"250.00\"" }
→ 422 { "error": "insufficient funds" }
```

**GET /transfers/:id** — the same transfer object; `state` advances
asynchronously: INITIATED/APPROVED → PENDING → COMPLETED.

**GET /approvals** — transfers waiting in PENDING_APPROVAL. Either
role may look; only the owner may act.

**POST /approvals/:id/approve** (or `…/reject`) — owner role only:
```
→ 200 the transfer object, state APPROVED (or REJECTED), with
      approval.decidedBy and approval.decidedAt stamped
→ 403 { "error": "forbidden: approvals require the owner role",
        "yourRole": "staff",
        "hint": "authentication says who you are; authorization
                 says what you may do" }
```

**GET /health** → `{ "ok": true, "service": "banksmart-gateway" }`
**POST /reset** → `{ "ok": true, "reset": true }` — returns the
gateway to seed data.
