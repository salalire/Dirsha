# Dirsha API Specification (Phase 1 contract)

**Owner:** Member 2 (backend) · **Status:** Phase 1 baseline, v0.1 · **Date:** 20 October 2026

This is the contract Members 1 (mobile) and 3 (admin) build against. It describes what the
backend **actually implements today**, plus a clearly separated list of what is **not ready
yet** (use mocks for those). Change it only by pull request and tell the other members
first (task plan, rule 3).

> **Prototype notice.** All money in Dirsha is **simulated test funds** and all securities
> are **test securities**. Nothing here handles real money. Every wallet response carries
> `"simulated": true`; the UI must label balances accordingly (FR-LED-01, NFR-PRV-04).

---

## 1. Conventions

| Topic | Rule |
|---|---|
| Base URL | Configurable per environment. Local default: `http://localhost:3000`. **Never hard-code it** in the apps. No `/v1` prefix yet. |
| Format | JSON in, JSON out. `Content-Type: application/json`. Max body 100 KB. |
| Field names | `snake_case` everywhere (requests and responses). |
| IDs | UUID strings. |
| Timestamps | ISO-8601 UTC strings, e.g. `2026-10-20T18:36:40.489Z`. |
| **Money** | **Integer minor units of ETB ("santim"): 1 ETB = 100 santim.** Fields end in `_minor`, e.g. `price_per_share_minor: 10000` = 100.00 ETB. Never floats, never decimal strings. Every money-bearing object also carries `currency: "ETB"`. To display: `amount_minor / 100` with 2 decimals. |
| Quantities | Whole shares as integers (`total_shares`, `quantity`). |
| Auth | `Authorization: Bearer <access_token>` on everything except `/health`, `/auth/register`, `/auth/login`. |
| Success envelope | Single object: `{ "data": { ... } }`. List: `{ "data": [ ... ], "pagination": { "page", "page_size", "total" } }`. |
| Error envelope | See §2. |
| Pagination | Query `page` (default 1, min 1) and `page_size` (default 20, max 100). Out-of-range page returns an empty `data` array, not an error. |
| Request id | Every response has `X-Request-Id`. Send your own (`[A-Za-z0-9._-]`, 8–64 chars) to correlate logs, or one is generated. Quote it when reporting a bug. |
| Idempotency | Operations that create financial effects require an `Idempotency-Key` header (8–128 chars, `[A-Za-z0-9._:-]`). **Generate one UUID per user action and reuse it on retry.** |
| CORS | Browser origins must be listed in the backend `CORS_ORIGINS` setting (admin web). Mobile apps are not affected. |

## 2. Errors

Every failure has this shape:

```json
{
  "error": {
    "code": "INSUFFICIENT_FUNDS",
    "message": "Available balance is not enough for this operation",
    "details": [ { "field": "password", "message": "Password must be at least 8 characters" } ],
    "request_id": "bff091ad-be1d-426a-b229-d82fb67595fc"
  }
}
```

**Switch on `code`, never on `message`** (messages may be reworded). `details` appears only for
`VALIDATION_ERROR` and never contains submitted values.

| HTTP | `code` | When |
|---|---|---|
| 400 | `VALIDATION_ERROR` | Bad/missing field, unknown field, malformed JSON, bad query param, bad id format |
| 401 | `UNAUTHENTICATED` | No/invalid/expired token. **Client action: go to sign-in.** |
| 401 | `INVALID_CREDENTIALS` | Wrong email or password (same response for unknown email) |
| 403 | `FORBIDDEN` | Signed in, but your role may not do this |
| 403 | `ACCOUNT_SUSPENDED` | Account suspended (takes effect immediately, also for live tokens) |
| 404 | `NOT_FOUND` | Unknown route, or a resource that doesn't exist **or you aren't allowed to see** |
| 409 | `EMAIL_ALREADY_REGISTERED` | Registration with an email already in use (case-insensitive) |
| 409 | `IDEMPOTENCY_KEY_REUSED` | Same `Idempotency-Key` sent with a *different* request |
| 422 | `INSUFFICIENT_FUNDS` | Available balance too low (used from Phase 2 subscriptions) |
| 429 | `RATE_LIMITED` | Too many sign-in/registration attempts (20 per 15 min per IP by default) |
| 500 | `INTERNAL_ERROR` | Unexpected server error; nothing sensitive is returned |

Reserved for Phase 2: `IPO_NOT_OPEN`, `CONFLICT`.

## 3. Enumerations (use these exact strings)

| Enum | Values |
|---|---|
| `role` | `investor`, `company_rep`, `broker`, `admin` |
| `account_status` | `active`, `suspended` |
| `verification_status` | `unverified`, `pending`, `verified`, `rejected` |
| IPO `status` | `draft`, `submitted`, `under_review`, `approved`, `open`, `closed`, `allocated`, `listed`, `rejected`, `withdrawn` |
| Ledger `type` | `test_fund_credit`, `subscription_reserve`, `subscription_release`, `subscription_settle`, `adjustment` |
| Ledger `status` | `posted` |

Role, account status and verification status are **separate** fields (FR-AUTH-06).

## 4. Who can call what

| Endpoint | investor | company_rep | broker | admin |
|---|:-:|:-:|:-:|:-:|
| `GET /health` | public | public | public | public |
| `POST /auth/register`, `POST /auth/login` | public | public | public | public |
| `GET/PATCH /users/me` | ✅ | ✅ | ✅ | ✅ |
| `GET /ipos`, `GET /ipos/:id` | public IPOs | public + own company's | public IPOs | all |
| `GET /wallets/me`, `GET /wallets/me/transactions` | ✅ (own) | ❌ 403 | ❌ 403 | ❌ 403 |
| `POST /dev/test-funds` | ✅ dev/test only | ❌ | ❌ | ❌ |

"Public IPOs" = status `open`, `closed`, `allocated` or `listed`. The role always comes from
the database, never from the token. **Hiding a button is not security; the server enforces
all of the above.**

---

## 5. Endpoints

### `GET /health`
Public. `200 {"status":"ok","checks":{"database":"up"},"timestamp":"..."}`.
`503` with `"status":"degraded"` and `"database":"down"` if the database is unreachable.
Exposes no version or configuration.

### `POST /auth/register`
Public, rate-limited. Creates an account. Investors automatically get an empty simulated wallet.

```json
{ "email": "abebe@example.com", "password": "at-least-8-chars", "full_name": "Abebe Kebede",
  "phone": "+251 911 000 000", "role": "investor" }
```
- `role`: `investor` | `company_rep` | `broker` only. **`admin` is rejected** (admins are provisioned out-of-band).
- `password`: 8+ characters, max 72 bytes. `phone` optional (`+`, digits, spaces, `()-`, 7–20 chars).
- Unknown fields (e.g. `balance`, `account_status`) → `400 VALIDATION_ERROR`.
- Does **not** sign the user in. Call `/auth/login` next.

`201`:
```json
{ "data": { "id": "…", "email": "abebe@example.com", "full_name": "Abebe Kebede", "phone": "+251 911 000 000",
            "role": "investor", "account_status": "active", "verification_status": "unverified",
            "created_at": "2026-10-20T18:36:40.489Z" } }
```
Errors: `400 VALIDATION_ERROR`, `409 EMAIL_ALREADY_REGISTERED`, `429 RATE_LIMITED`.

### `POST /auth/login`
Public, rate-limited. Body: `{ "email": "…", "password": "…" }` (email is case-insensitive).

`200`:
```json
{ "data": { "access_token": "<jwt>", "token_type": "Bearer", "expires_in": 900,
            "user": { "id": "…", "email": "…", "full_name": "…", "phone": null, "role": "investor",
                      "account_status": "active", "verification_status": "unverified", "created_at": "…" } } }
```
- `expires_in` is seconds (default **900 = 15 min**). **There is no refresh token yet** (see §7): when
  you get `401 UNAUTHENTICATED`, send the user to sign-in.
- Store the token in secure storage (`flutter_secure_storage`), never in plain preferences, and never log it.

Errors: `401 INVALID_CREDENTIALS`, `403 ACCOUNT_SUSPENDED`, `400`, `429`.

### `GET /users/me`
`200 { "data": <user> }`: the caller's own profile (same shape as above). Use it to read the current
`role` after login and to rebuild state on app start.

### `PATCH /users/me`
Body: any of `{ "full_name": "…", "phone": "…" | null }` (at least one). `null` clears the phone.
Only these two fields are editable; `role`, `email`, `account_status`, `verification_status` → `400`.
`200 { "data": <user> }`.

### `GET /ipos`
Auth required. Query: `status` (enum), `page`, `page_size`. Newest `opens_at` first.
Visibility depends on role (§4). Filtering by a status you can't see returns an empty list.

`200`:
```json
{ "data": [ { "id": "…", "company_id": "…", "company_name": "Demo Holdings PLC (TEST DATA)",
              "title": "TEST IPO A (open)", "symbol": "TESTA", "description": "…", "currency": "ETB",
              "price_per_share_minor": 10000, "total_shares": 100000,
              "min_shares_per_subscription": 10, "max_shares_per_subscription": 5000,
              "opens_at": "2026-10-19T18:36:40.000Z", "closes_at": "2026-10-26T18:36:40.000Z",
              "status": "open", "created_at": "…" } ],
  "pagination": { "page": 1, "page_size": 20, "total": 3 } }
```
`max_shares_per_subscription` may be `null` (no maximum).

### `GET /ipos/:id`
Auth required. `200 { "data": <ipo> }` (same shape as a list item).
`404 NOT_FOUND` if it doesn't exist **or** you may not see it (indistinguishable on purpose).
`400 VALIDATION_ERROR` if `:id` is not a UUID.

> `status: "open"` does **not** by itself mean you can subscribe right now. Subscription timing and
> limits are enforced by the server in Phase 2; the app should treat the server's answer as final.

### `GET /wallets/me`
Investors only. Your simulated wallet.
`200`:
```json
{ "data": { "id": "…", "currency": "ETB", "simulated": true,
            "available_minor": 1000000, "reserved_minor": 0, "total_minor": 1000000,
            "updated_at": "…" } }
```
- `available_minor`: can be spent/reserved now. `reserved_minor`: held for pending subscriptions.
  `total_minor = available + reserved`. Example above = **10,000.00 ETB**.

### `GET /wallets/me/transactions`
Investors only. Query: `page`, `page_size`. Newest first. Every balance change appears here.

`200`:
```json
{ "data": [ { "id": "…", "wallet_id": "…", "type": "test_fund_credit", "status": "posted",
              "available_delta_minor": 1000000, "reserved_delta_minor": 0,
              "available_after_minor": 1000000, "reserved_after_minor": 0,
              "reference_type": null, "reference_id": null,
              "description": "Seed: simulated test funds (not real money)",
              "created_at": "…" } ],
  "pagination": { "page": 1, "page_size": 20, "total": 1 } }
```
`*_delta_minor` are signed (a reservation is a negative available delta and an equal positive reserved delta).
`reference_type`/`reference_id` point at the business object (e.g. a subscription) from Phase 2.

### `POST /dev/test-funds`  ⚠️ development/test only
Only exists when the backend runs with `ENABLE_TEST_FUNDS=true`, which the server **refuses** in
production (otherwise this path returns `404`). Credits **simulated** funds to the **caller's own** wallet.

Headers: `Idempotency-Key` (required). Body: `{ "amount_minor": 1000000 }` (integer, 1 … 10,000,000 per call = max 100,000 ETB).
- Unknown fields (`wallet_id`, `balance`, `available_minor`…) → `400`.
- First call `201`; a retry with the same key and amount `200` with header `Idempotent-Replay: true` and the **same** transaction (balance unchanged).
- Same key, different amount → `409 IDEMPOTENCY_KEY_REUSED`.

`201`/`200`: `{ "data": { "transaction": <ledger entry>, "wallet": <wallet> } }`.

The mobile app should expose this only behind a clearly labelled **test mode** that is off in release builds.

---

## 6. Test accounts for local development

After the backend owner runs `npm run seed` (see `backend/README.md`) the API has these fake accounts
(`*@dirsha.test`; the password is whatever was set in `SEED_PASSWORD`; ask Member 2, it is **not** in Git):

| Email | Role | Notes |
|---|---|---|
| `investor@dirsha.test` | investor | Wallet with 10,000.00 ETB simulated funds |
| `investor2@dirsha.test` | investor | Empty wallet |
| `company@dirsha.test` | company_rep | Owns the demo company and its IPOs |
| `broker@dirsha.test` | broker | |
| `admin@dirsha.test` | admin | Sees all IPOs, including `draft` / `under_review` |

Seeded IPOs: `TESTA`, `TESTB` (open), `TESTC` (listed), `TESTD` (under review), `TESTE` (draft).

## 7. Not ready yet: build against mocks

These are in the SRS/plan but **not implemented in this baseline**. Keep them behind your mock
repository interface and label them as mock. Planned timing is from the 6-day plan.

| Needed by | Endpoint / feature | Planned |
|---|---|---|
| Mobile + Admin | `POST /subscriptions`, `GET /subscriptions` (reserve funds, idempotent, `INSUFFICIENT_FUNDS`, `IPO_NOT_OPEN`) | Phase 2, Day 3 (22 Oct) |
| Mobile | Subscription status/history, allocation and release/refund results | Phase 2, Day 4 (23 Oct) |
| Admin | IPO review actions (approve/reject/open…), subscription list/detail, audit-event list | Phase 2, Day 3–4 |
| Admin | User/company review lists and decisions | Phase 2 (needs a team decision on scope: not in the Phase 1 backend list) |
| Mobile | Company onboarding, IPO draft/submit, document upload (S3) | Not scheduled in the 6-day plan; needs a team decision |
| Both | **Refresh tokens** / silent re-login (FR-AUTH-07, P1) | Not in Phase 1; sessions last 15 min |
| Both | WebSocket live updates, orders/order book, broker relationships | Out of the 6-day MVP scope (§9 of the plan) |

When a real endpoint lands it will follow the conventions above; only the "not ready" row changes.
