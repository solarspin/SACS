#!/usr/bin/env node
/**
 * BankSmartAI mock banking gateway.
 *
 * Local. Deterministic. Zero dependencies. No real money, ever.
 * Behaves like a banking core from the app's point of view:
 *   - JWT-style auth with a ROLE claim (owner | staff)
 *   - accounts / transactions with exact decimal-string amounts
 *   - transfers with an approval threshold: over-threshold parks in
 *     PENDING_APPROVAL until an owner approves (dual control as a state)
 *   - asynchronous settlement (INITIATED -> PENDING -> COMPLETED)
 *   - failure injection: latency, forced errors, and the Sprint-3
 *     nightmare switch: drop-after-accept.
 *
 * All internal math is integer cents. There is no floating point
 * anywhere near money in this file either.
 *
 * Run:  node server.js          (port 4000, override with PORT)
 * Docs: README.md in this directory. Part of the Control Point book.
 */

const http = require("http");
const crypto = require("crypto");

const PORT = process.env.PORT || 4000;
const SECRET = "local-demo-secret-not-a-real-key";
const APPROVAL_THRESHOLD_CENTS = 10_000_00; // $10,000.00
const SETTLE_MS = { toPending: 1500, toCompleted: 4000 };

// ---------------------------------------------------------------------------
// Seed data — identical on every boot and every POST /reset.
// ---------------------------------------------------------------------------

const USERS = {
  "owner@banksmart.test": { password: "owner-demo-1", role: "owner", name: "Demo Owner" },
  "staff@banksmart.test": { password: "staff-demo-1", role: "staff", name: "Demo Staff" },
};

function seed() {
  return {
    accounts: [
      { id: "acct-operating", name: "Operating", type: "operating", balanceCents: 8_600_000_00, rateBps: 0 },
      { id: "acct-reserve",   name: "Reserve",   type: "reserve",   balanceCents: 2_300_000_00, rateBps: 380 },
      { id: "acct-savings",   name: "Savings",   type: "savings",   balanceCents: 1_500_000_00, rateBps: 415 },
    ],
    transactions: {
      "acct-operating": [
        tx("txn-1001", "2026-07-01", "Client A — invoice 2214", 1_200_000_00),
        tx("txn-1002", "2026-07-02", "Payroll",                -1_100_000_00),
        tx("txn-1003", "2026-07-05", "Vendors — LED panels",     -732_000_00),
        tx("txn-1004", "2026-07-08", "Cloud infrastructure",     -120_000_00),
        tx("txn-1005", "2026-07-10", "Contractors",              -350_000_00),
        tx("txn-1006", "2026-07-12", "Client B — retainer",       400_000_00),
      ],
      "acct-reserve": [tx("txn-2001", "2026-07-01", "Dividend accrual", 7_283_33)],
      "acct-savings": [tx("txn-3001", "2026-07-01", "Dividend accrual", 5_187_50)],
    },
    transfers: {},   // id -> transfer
    nextTransfer: 1,
  };
}
function tx(id, date, description, amountCents) {
  return { id, date, description, amountCents };
}

let db = seed();

// ---------------------------------------------------------------------------
// Money formatting — cents in, exact decimal string out.
// ---------------------------------------------------------------------------

function centsToString(cents) {
  const sign = cents < 0 ? "-" : "";
  const abs = Math.abs(cents);
  return `${sign}${Math.floor(abs / 100)}.${String(abs % 100).padStart(2, "0")}`;
}
function parseAmountToCents(s) {
  // Accepts "1234.56" or "1234". Rejects floats-in-disguise and negatives.
  if (typeof s !== "string" || !/^\d+(\.\d{1,2})?$/.test(s)) return null;
  const [whole, frac = "0"] = s.split(".");
  return parseInt(whole, 10) * 100 + parseInt(frac.padEnd(2, "0"), 10);
}

// ---------------------------------------------------------------------------
// Tiny HMAC token (JWT-shaped, HS256) — good enough for a local demo core.
// ---------------------------------------------------------------------------

function b64url(buf) {
  return Buffer.from(buf).toString("base64").replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}
function sign(payload) {
  const header = b64url(JSON.stringify({ alg: "HS256", typ: "JWT" }));
  const body = b64url(JSON.stringify(payload));
  const mac = b64url(crypto.createHmac("sha256", SECRET).update(`${header}.${body}`).digest());
  return `${header}.${body}.${mac}`;
}
function verify(token) {
  const parts = (token || "").split(".");
  if (parts.length !== 3) return null;
  const mac = b64url(crypto.createHmac("sha256", SECRET).update(`${parts[0]}.${parts[1]}`).digest());
  if (mac !== parts[2]) return null;
  try {
    const payload = JSON.parse(Buffer.from(parts[1].replace(/-/g, "+").replace(/_/g, "/"), "base64"));
    if (payload.exp && payload.exp < Date.now() / 1000) return null;
    return payload;
  } catch {
    return null;
  }
}

// ---------------------------------------------------------------------------
// Server
// ---------------------------------------------------------------------------

const server = http.createServer(async (req, res) => {
  const url = new URL(req.url, `http://localhost:${PORT}`);
  const path = url.pathname;
  const send = (status, obj) => {
    res.writeHead(status, { "content-type": "application/json" });
    res.end(JSON.stringify(obj, null, 2));
  };

  // ---- failure injection ----------------------------------------------
  const latency = parseInt(req.headers["x-latency"] || process.env.LATENCY_MS || "0", 10);
  if (latency > 0) await new Promise((r) => setTimeout(r, latency));
  const forceFail = parseInt(req.headers["x-fail"] || "0", 10);
  if (forceFail >= 400) return send(forceFail, { error: "injected failure (x-fail header)" });
  const dropAfterAccept =
    (req.headers["x-drop-after-accept"] || "").toLowerCase() === "true" ||
    (process.env.DROP_AFTER_ACCEPT || "").toLowerCase() === "true";

  // ---- body ------------------------------------------------------------
  let body = {};
  if (req.method === "POST") {
    const raw = await new Promise((r) => {
      let d = "";
      req.on("data", (c) => (d += c));
      req.on("end", () => r(d));
    });
    try { body = raw ? JSON.parse(raw) : {}; } catch { return send(400, { error: "invalid JSON" }); }
  }

  // ---- public routes -----------------------------------------------------
  if (path === "/health") return send(200, { ok: true, service: "banksmart-gateway" });

  if (path === "/reset" && req.method === "POST") {
    db = seed();
    return send(200, { ok: true, reset: true });
  }

  if (path === "/auth/login" && req.method === "POST") {
    const user = USERS[body.email];
    if (!user || user.password !== body.password) return send(401, { error: "invalid credentials" });
    const token = sign({ sub: body.email, role: user.role, name: user.name, exp: Math.floor(Date.now() / 1000) + 3600 });
    return send(200, { token, role: user.role, expiresInSeconds: 3600 });
  }

  // ---- everything below requires auth ------------------------------------
  const auth = verify((req.headers.authorization || "").replace(/^Bearer /, ""));
  if (!auth) return send(401, { error: "missing or invalid token" });

  if (path === "/accounts" && req.method === "GET") {
    return send(200, {
      accounts: db.accounts.map((a) => ({
        id: a.id, name: a.name, type: a.type,
        balance: centsToString(a.balanceCents), currency: "USD",
        dividendRatePercent: (a.rateBps / 100).toFixed(2),
      })),
    });
  }

  const acctMatch = path.match(/^\/accounts\/([\w-]+)(\/transactions)?$/);
  if (acctMatch && req.method === "GET") {
    const acct = db.accounts.find((a) => a.id === acctMatch[1]);
    if (!acct) return send(404, { error: "no such account" });
    if (acctMatch[2]) {
      return send(200, {
        accountId: acct.id,
        transactions: (db.transactions[acct.id] || []).map((t) => ({
          id: t.id, date: t.date, description: t.description,
          amount: centsToString(t.amountCents), currency: "USD",
        })),
      });
    }
    return send(200, {
      id: acct.id, name: acct.name, type: acct.type,
      balance: centsToString(acct.balanceCents), currency: "USD",
      dividendRatePercent: (acct.rateBps / 100).toFixed(2),
    });
  }

  if (path === "/transfers" && req.method === "POST") {
    const from = db.accounts.find((a) => a.id === body.from);
    const to = db.accounts.find((a) => a.id === body.to);
    const cents = parseAmountToCents(body.amount);
    if (!from || !to || from.id === to.id) return send(400, { error: "invalid from/to account" });
    if (cents === null || cents === 0) return send(400, { error: "amount must be a positive decimal string, e.g. \"250.00\"" });
    if (cents > from.balanceCents) return send(422, { error: "insufficient funds" });

    const id = `tr-${String(db.nextTransfer++).padStart(4, "0")}`;
    const needsApproval = cents > APPROVAL_THRESHOLD_CENTS;
    const transfer = {
      id, from: from.id, to: to.id,
      amount: centsToString(cents), amountCents: cents, currency: "USD",
      state: needsApproval ? "PENDING_APPROVAL" : "INITIATED",
      initiatedBy: auth.sub, createdAt: new Date().toISOString(),
      approval: needsApproval ? { requiredRole: "owner", decidedBy: null, decidedAt: null } : null,
    };
    db.transfers[id] = transfer;
    if (!needsApproval) scheduleSettlement(transfer);

    // The Sprint-3 nightmare switch: the transfer HAS been accepted and
    // stored — and the connection dies before the app hears about it.
    if (dropAfterAccept) { res.socket.destroy(); return; }

    return send(201, publicTransfer(transfer));
  }

  const trMatch = path.match(/^\/transfers\/([\w-]+)$/);
  if (trMatch && req.method === "GET") {
    const t = db.transfers[trMatch[1]];
    if (!t) return send(404, { error: "no such transfer" });
    return send(200, publicTransfer(t));
  }

  if (path === "/approvals" && req.method === "GET") {
    const pending = Object.values(db.transfers).filter((t) => t.state === "PENDING_APPROVAL");
    return send(200, { approvals: pending.map(publicTransfer) });
  }

  const apMatch = path.match(/^\/approvals\/([\w-]+)\/(approve|reject)$/);
  if (apMatch && req.method === "POST") {
    if (auth.role !== "owner") {
      return send(403, {
        error: "forbidden: approvals require the owner role",
        yourRole: auth.role,
        hint: "authentication says who you are; authorization says what you may do",
      });
    }
    const t = db.transfers[apMatch[1]];
    if (!t) return send(404, { error: "no such transfer" });
    if (t.state !== "PENDING_APPROVAL") return send(409, { error: `transfer is ${t.state}, not PENDING_APPROVAL` });
    t.approval.decidedBy = auth.sub;
    t.approval.decidedAt = new Date().toISOString();
    if (apMatch[2] === "approve") {
      t.state = "APPROVED";
      scheduleSettlement(t);
    } else {
      t.state = "REJECTED";
    }
    return send(200, publicTransfer(t));
  }

  return send(404, { error: `no route: ${req.method} ${path}` });
});

function scheduleSettlement(t) {
  setTimeout(() => {
    if (t.state === "INITIATED" || t.state === "APPROVED") t.state = "PENDING";
  }, SETTLE_MS.toPending);
  setTimeout(() => {
    if (t.state === "PENDING") {
      t.state = "COMPLETED";
      const from = db.accounts.find((a) => a.id === t.from);
      const to = db.accounts.find((a) => a.id === t.to);
      from.balanceCents -= t.amountCents;
      to.balanceCents += t.amountCents;
      const stamp = new Date().toISOString().slice(0, 10);
      (db.transactions[t.from] ||= []).push(tx(`${t.id}-out`, stamp, `Transfer to ${to.name}`, -t.amountCents));
      (db.transactions[t.to] ||= []).push(tx(`${t.id}-in`, stamp, `Transfer from ${from.name}`, t.amountCents));
    }
  }, SETTLE_MS.toCompleted);
}

function publicTransfer(t) {
  const { amountCents, ...pub } = t;
  return pub;
}

server.listen(PORT, () => {
  console.log(`BankSmartAI mock gateway listening on http://localhost:${PORT}`);
  console.log(`Demo logins: owner@banksmart.test / owner-demo-1   ·   staff@banksmart.test / staff-demo-1`);
  console.log(`Approval threshold: $${centsToString(APPROVAL_THRESHOLD_CENTS)}`);
});
