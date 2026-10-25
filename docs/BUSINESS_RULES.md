# Dirsha Business Rules (wallet, money, access)

**Owner:** Member 2 (backend) · **Status:** Phase 1 baseline, **PROPOSED, needs team sign-off** · **Date:** 20 October 2026

SRS §10 requires business rules to be agreed and recorded before the related feature is built.
Part A is **already implemented and tested** in the backend. Part B lists decisions the
**team must make** before Phase 2 code relies on them; nothing in Part B is implemented.

> **Test-only.** All funds are simulated and all securities are test securities. Nothing here
> authorises real-money operation (SRS §3.2, NFR-PRV-03/04).

---

## Part A: Implemented rules

### A1. Money representation
- Amounts are **integer minor units of ETB (santim)**; 1 ETB = 100 santim. Stored as PostgreSQL `BIGINT`; no
  floating-point type is used for money anywhere (a test scans the migrations for it).
- JSON fields are named `*_minor` and carry `currency: "ETB"`. Only ETB exists; the database enforces it.
- Values must be safe integers (≤ 2^53 − 1). Larger values are rejected rather than rounded.
- *Resolves open decision "ledger and balance representation" (SRS §15) as proposed.*

### A2. Wallet model: ledger is the source of truth
- One wallet per investor, created at registration with a zero balance. Company representatives, brokers and
  admins have no wallet in this phase.
- Each wallet has `available_minor` (spendable) and `reserved_minor` (held for a pending subscription).
  Total = available + reserved. Both are always ≥ 0 (database `CHECK`).
- **Every balance change is an append-only row in `ledger_entries`**, written in the *same database transaction* as the
  wallet update. Ledger rows can never be updated, deleted or truncated (database triggers), so corrections are
  new, linked entries (FR-LED-02, NFR-FIN-04).
- The stored wallet balance is a transactionally-maintained running total. The view `wallet_reconciliation`
  recomputes it from the ledger; **any row with `ok = false` is a defect**. Tests assert zero such rows.
- *Resolves the "source of truth" design principle (SRS §9.7) as: ledger authoritative, wallet row reconciled to it.*

| Entry type | Available Δ | Reserved Δ | Meaning |
|---|---|---|---|
| `test_fund_credit` | + | 0 | Simulated funds credited (dev/test only) |
| `subscription_reserve` | − x | + x | Hold funds for a subscription |
| `subscription_release` | + x | − x | Return unused/cancelled reservation |
| `subscription_settle` | 0 | − x | Reserved funds paid to the offering (leave the wallet) |
| `adjustment` | any | any | Admin correction; must be linked and audited (not exposed yet) |

The shape of each type is enforced by database `CHECK` constraints, not just by code.

### A3. Concurrency and idempotency
- The only code path that changes a balance is `applyLedgerEntry` (`backend/src/modules/wallet/ledger.ts`). It locks the wallet row
  (`SELECT … FOR UPDATE`), so concurrent operations on one wallet are serialised and **funds cannot be spent twice**.
  Tested: 10 concurrent reservations of 300 against 1,000 → exactly 3 succeed, 7 get `INSUFFICIENT_FUNDS`, no extra ledger rows.
  (The test fails if the row lock is removed.)
- An operation that would make `available` negative is rejected (`422 INSUFFICIENT_FUNDS`) and changes nothing.
- Releasing or settling more than is reserved is a programming error and fails the transaction.
- **Idempotency:** a ledger entry is unique per `(wallet, entry type, idempotency key)`. Retrying with the same key returns the
  original entry and changes nothing; the same key with a *different* amount is `409 IDEMPOTENCY_KEY_REUSED`.
  Concurrent retries apply exactly once. (FR-LED-04, NFR-FIN-03)
- If anything later in the same transaction fails, the whole transaction rolls back (tested, NFR-FIN-05).

### A4. Test funds (simulated money)
- The ONLY way to put simulated money in a wallet over HTTP is `POST /dev/test-funds`, and it is guarded in layers:
  1. The route exists only if `ENABLE_TEST_FUNDS=true`; startup **fails** if that is set with `NODE_ENV=production`.
  2. Investors only, and only for their **own** wallet (no wallet/user id is accepted).
  3. `Idempotency-Key` required; max 10,000,000 santim (100,000 ETB) per call; goes through the ledger; audited.
- There is **no** endpoint that accepts a balance, and any request carrying `balance`/`available_minor`/`wallet_id` fields is rejected.
- Seed data credits 10,000.00 ETB to `investor@dirsha.test` through the ledger (once; re-running is a no-op).

### A5. Accounts, roles and sessions
- Roles: `investor`, `company_rep`, `broker`, `admin`. Account status (`active`/`suspended`) and verification status
  (`unverified`/`pending`/`verified`/`rejected`) are separate columns. **Verification is only a status field today; no identity verification
  exists** and the apps must not imply otherwise.
- Public registration can create `investor`, `company_rep`, `broker`. **Admins cannot self-register**; they are created out-of-band with
  `npm run create-admin` (min. 12-char password, audited).
- Passwords: bcrypt hash (cost 12 by default), 8–72 bytes. Never stored or logged in plaintext; never returned.
- The access token carries only the user id. **Role and account status are re-read from the database on every request**, so tokens cannot
  assert privileges and a suspension applies immediately.
- Sign-in/registration are rate-limited (default 20 / 15 min / IP). Failed and denied sign-ins are written to the audit log
  (without the password or submitted email).

### A6. IPO visibility (reads)
- Public statuses: `open`, `closed`, `allocated`, `listed`: visible to any signed-in user.
- Every other status (`draft`, `submitted`, `under_review`, `approved`, `rejected`, `withdrawn`) is visible only to **admins** and to the
  **owning company's representative**. Enforced in the SQL query; a hidden IPO returns the same `404` as a missing one.

### A7. Audit
- `audit_events` is append-only and records actor, role, action, target, outcome and the request id. It never contains passwords,
  tokens or secrets. Currently written for: registration, sign-in (success / failure / suspended), test-fund credits, admin provisioning.

### A8. Company and Broker Onboarding & Document Verification
- **Application Lifecycles:** 7-state onboarding lifecycle: `draft` -> `submitted` -> `under_review` -> `additional_info_required` -> `resubmitted` -> `approved` / `rejected`.
- **Company Requirements:** Company Name, Registration Number, TIN, Legal Entity Type, Country of Incorporation, Registered Address, Business Email, Sector, Authorized Representative details with explicit authority declaration (`authority_declaration_confirmed: true`). Mandatory documents: `commercial_registration`, `tin_certificate`.
- **Broker Requirements:** Broker Type (`firm` or `individual`), Firm Name (for firms), License Number, Licensing Authority (ECMA), Jurisdiction (`ET`), License Expiry Date (must be future). Mandatory document: `broker_license`. Expired licenses are blocked at submission and cannot be approved by administrators.
- **Document Storage & Privacy:** Documents are stored in secure private storage outside web root with SHA-256 verification, MIME validation (PDF, PNG, JPEG), and 10MB file size limit. Access requires backend authorization (own application or admin).
- **Administrative Decision Enforceability:** Admins review applications and supporting documents (`approved`/`rejected`). Approvals require complete mandatory documents and non-expired licenses. Rejections require an explicit recorded reason. Additional-info requests transition application to `additional_info_required` to allow applicant correction and resubmission.
- **Role Isolation:** Only approved companies can create IPOs; only approved brokers can engage in broker activities.

### A9. Company IPO Creation and Management Lifecycle
- **Eligibility:** Only authenticated company representatives with an `approved` company onboarding status (or platform administrators) may create, edit, or submit IPO offerings.
- **Offering Draft States:** IPO offerings follow a strict state flow: `draft` -> `submitted` -> `under_review` -> `approved` / `rejected` -> `open` (during active window) -> `closed` -> `allocated`.
- **Document Requirements:** Company representatives must upload required offering documents (prospectus, valuation report, ECMA approval) linked directly to the IPO entity before submitting for admin review.
- **Tenant Isolation:** Companies may only view, edit, attach documents to, or submit their own offerings. Cross-company access is rejected with `403 Forbidden` / `404 Not Found`.

### A10. Broker Client Relationships & Authorized Portfolio Operations
- **Eligibility:** Only approved brokers with active licenses can request client relationships.
- **Consent Lifecycle:** Relationships progress from `pending` -> `active` (accepted by investor) -> `revoked` / `rejected`.
- **Authorization Enforcement:** Brokers cannot inspect private client balances, share holdings, or place orders on behalf of clients while a relationship is in `pending`, `rejected`, or `revoked` status. Explicit client acceptance is required.
- **Assisted Operations:** When authorized, brokers may place orders on behalf of clients, explicitly recording `assisted_by_broker_id` and creating immutable audit entries.

### A11. Simulated Secondary-Market Trading Engine & Ledger Settlement
- **Reconciliation of Requirements:** While live stock exchange integration and real monetary rails remain deferred, Dirsha provides a fully operational **simulated secondary-market trading and deterministic matching engine** denominated strictly in ETB minor units (santim) for test securities.
- **Pre-Trade Asset Reservation:**
  - Buy orders reserve cash (`price × quantity`) via the immutable ledger (`trade_reserve`), preventing overspending.
  - Sell orders reserve shares in `share_holdings` (`reserved_quantity`), preventing overselling.
- **Deterministic Price-Time Priority Matching:**
  - Buy orders match against active sell orders sorted by `price_per_share_minor ASC, created_at ASC`.
  - Sell orders match against active buy orders sorted by `price_per_share_minor DESC, created_at ASC`.
  - Self-trading is strictly prohibited (`user_id != counterparty.user_id`).
- **Instant Dual-Settlement & Price Improvement:**
  - Execution occurs at the resting passive order (maker) price.
  - Buyer's reserved cash is settled (`trade_settle`), and any price improvement difference is refunded to available cash (`trade_release`).
  - Seller's wallet is credited with trade proceeds (`trade_credit`).
  - Shares are atomically decremented from the seller and credited to the buyer in PostgreSQL.
  - Full double-entry reconciliation (`wallet_reconciliation.ok = true`) is strictly preserved on every transaction.
- **Order Cancellation:**
  - Cancelling an open buy order atomically releases remaining reserved funds back to available cash (`trade_release`).
  - Cancelling an open sell order releases reserved shares back to available inventory.
  - Already filled or cancelled orders cannot be cancelled (`409 Conflict`).

---

## Part B: Decisions the team must make (before Phase 2 relies on them)

These come from SRS §10 / §15. **Proposed defaults** are what Member 2 will implement on Day 3 unless the team says otherwise.
Please confirm or change each one (a reply in the team chat is enough; then update this file).

| # | Decision | Proposed default | Affects |
|---|---|---|---|
| B1 | **Subscription amount** | `quantity × price_per_share_minor`, reserved in full at subscription time | M1 screens, M2 |
| B2 | **Min/max per subscription** | Use the IPO's `min_shares_per_subscription` / `max_shares_per_subscription`; `null` max = no maximum | M1 validation, M2 |
| B3 | **Eligibility to subscribe** | Role `investor`, account `active`. **`verification_status` is NOT required in the MVP** (no verification flow exists). Confirm. | M1, M2 |
| B4 | **One or many subscriptions per investor per IPO** | One *active* subscription per investor per IPO (simplest to explain and reconcile) | M1, M2 |
| B5 | **Subscription window** | `status = 'open'` **and** `opens_at ≤ now < closes_at`, checked by the server clock | M1, M3 |
| B6 | **Allocation when undersubscribed** | Everyone gets what they asked for; unused reserved funds are released | M2 |
| B7 | **Allocation when oversubscribed** | Pro-rata: `floor(requested × total_shares ÷ total_requested)`; leftover whole shares go one at a time to the largest remainders, ties broken by earliest subscription time then id, so the result is deterministic | M2, M3 |
| B8 | **Settlement** | Allocated amount (`allocated_quantity × price`) is settled (leaves the wallet); the rest is released, as one auditable operation, exactly once | M2 |
| B9 | **Cancellation by the investor** | Allowed only while the IPO is `open` (before `closes_at`); releases the whole reservation | M1, M2 |
| B10 | **Share precision** | Whole shares only | all |
| B11 | **Where the capital goes** | MVP: settled funds are recorded as a ledger `subscription_settle` entry; no company wallet yet | M2, M3 |
| B12 | **Session length** | Keep 15-minute access tokens for now; add refresh tokens only if the team wants it (FR-AUTH-07 is P1) | M1 |
| B13 | **Company onboarding / IPO creation / documents** | Implemented in Phase 3. Approved companies create offerings and manage document reviews. | all |
| B14 | **Secondary-Market Trading Engine** | Implemented in Phase 3 as an internal simulated deterministic matching engine in ETB; live exchange matching deferred. | all |

External banking rails, physical payment gateways, and external exchange matching remain deferred.
