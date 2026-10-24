# Dirsha Backend — Phase 3 Handover (Member 2)

Simulated funds only. No real-money payment rails exist or are connected. No credentials appear in this file or in Git.

## 1. Deployment configuration

| Item | Value |
|---|---|
| Runtime | Node.js >= 20, PostgreSQL 14+ |
| Install | `npm ci` (run in `backend/`) |
| Build | `npm run build` (outputs `dist/`) |
| Start | `npm start` (`node dist/server.js`) |
| Port | `PORT` (default 3000) |
| Health check | `GET /health` → `200 {status:"ok"}` or `503 {status:"degraded"}`; exposes no version, host or config |
| Migrations | `npm run migrate:prod` (compiled) — run before each deploy; `npm run migrate:status` to inspect |
| First admin | `npm run create-admin:prod` (admin accounts cannot self-register) |
| Logging | JSON (pino) to stdout; secrets/tokens/passwords redacted; every response carries `request_id` |

### Environment variables (names only; values come from the secret store)
`NODE_ENV`, `PORT`, `LOG_LEVEL`, `DATABASE_URL`, `JWT_ACCESS_SECRET` (>=32 chars, random), `JWT_ACCESS_TTL_SECONDS`, `BCRYPT_COST`, `CORS_ORIGINS` (explicit origins, no wildcard in production), `ENABLE_TEST_FUNDS` (must be `false`/unset in production — the server refuses to start otherwise), `AUTH_RATE_LIMIT_MAX`.

Generate a secret with `openssl rand -hex 48`. Never reuse a development value.

### External services / storage
None required by the backend today (PostgreSQL only). No file/document storage is implemented, so no storage permissions are needed yet. When document upload is added it must be private by default with time-limited access.

## 2. Deployment checklist (project owner)
- [ ] `JWT_ACCESS_SECRET` and DB password are new, random, and stored in a secret manager (not Git, not chat).
- [ ] `NODE_ENV=production`, `ENABLE_TEST_FUNDS` not true, `CORS_ORIGINS` lists only the real admin/web origins.
- [ ] Database is private (not publicly reachable); backups enabled (see section 4).
- [ ] `npm run migrate:prod` succeeds on the target DB; `migrate:status` shows all applied.
- [ ] First admin created with `create-admin:prod`; seed data NOT loaded in production.
- [ ] `/health` returns 200 behind the load balancer; logs reach the log service; no secret appears in logs.
- [ ] TLS terminates in front of the API.
- [ ] Owner has read the known limitations below and accepts them.

## 3. Roles and routes

| Route | Roles | Notes |
|---|---|---|
| `POST /auth/register` | public | roles `investor`, `company_rep`, `broker` only; rate limited; returns user (login afterwards) |
| `POST /auth/login` | public | rate limited |
| `GET/PATCH /users/me` | any authenticated | PATCH is strict: `role`, `balance`, status fields are rejected |
| `GET /ipos`, `GET /ipos/:id` | authenticated | |
| `GET /wallets/me`, `GET /wallets/me/transactions` | investor | own wallet only |
| `POST /wallets/test-funds` | investor | only when `ENABLE_TEST_FUNDS=true`; disabled in production |
| `POST /subscriptions` | investor | requires `Idempotency-Key`; reserves funds |
| `GET /subscriptions`, `GET /subscriptions/:id` | authenticated | investors see only their own; admin sees all |
| `GET /admin/users`, `GET /admin/audit` | admin | |
| `POST /admin/ipos/:id/approve\|reject\|close\|allocate` | admin | audited |
| `GET /health` | public | |

Role and account status are re-read from the database on every request; the JWT carries only the user id, so a client cannot supply or forge a role.

## 4. Schema, migrations and rollback
- Migrations `0001`–`0005` in `migrations/` are plain SQL, applied in order and checksummed. **Never edit an applied migration**; add a new file.
- Clean-database check: tests drop and recreate the schema and run all migrations on every run.
- `0005` (added in Phase 3) adds: one active subscription per investor per IPO (partial unique index), an IPO/status index, and a trigger making a subscription's final status immutable.
- Money is stored as integer santim (BIGINT). `ledger_entries` is append-only (UPDATE/DELETE/TRUNCATE are blocked by triggers); `wallets` balances are maintained in the same transaction as each ledger entry.
- **Rollback:** there are no automatic down-migrations. Roll back by restoring the pre-deploy database backup/snapshot, then redeploying the previous build. Take a snapshot before every `migrate:prod`. Because the ledger is append-only, corrections are made with new compensating entries, never by editing rows.
- Backup assumption: the hosting provider's managed PostgreSQL automated backups + a manual snapshot before each migration. Restore has not been rehearsed — rehearse it once in staging.

## 5. Seed data (development/test only)
`SEED_PASSWORD='<local password>' ENABLE_TEST_FUNDS=true npm run seed` creates five `*@dirsha.test` accounts, one fictional company, five test IPOs and 10,000.00 ETB of simulated funds for `investor@dirsha.test`. Do not run it in production.

## 6. Phase 3 review results
- Balance-changing endpoints (`POST /subscriptions`, `POST /admin/ipos/:id/allocate`, `POST /wallets/test-funds`): all run in one DB transaction, lock the wallet row, write a ledger entry, write an audit event, and are idempotent (per-key). Ownership enforced by role and `investor_id` checks.
- No endpoint accepts a client-supplied balance or role (strict Zod schemas).
- **Defect found and fixed:** concurrent subscribe requests with different idempotency keys could create several active subscriptions for the same investor and IPO (4 of 4 succeeded in a test). Also the IPO status was read outside the transaction, so a subscription could be created during allocation. Fixed by locking the IPO row inside the transaction and adding the unique index in `0005`; regression tests in `tests/phase3-concurrency.test.ts`.
- `.env` and `.env.*` are git-ignored; `.env.example` must contain placeholders only.

## 7. Known limitations (not implemented — do not present as complete)
- No real money: deposits, withdrawals, KYC and payment rails do not exist; wallets hold simulated funds.
- No refresh tokens or server-side logout (`POST /auth/logout` does not exist; clients just discard the token). Access tokens last 15 minutes by default.
- No email/phone verification, password reset, or MFA.
- No subscription cancellation endpoint in the current API.
- No document upload/storage; company/IPO creation by company reps is not exposed in the API (IPOs are created via seed/DB).
- No secondary market/trading, no payout of allocated shares to a registry.
- Rate limiting covers register/login only and is in-memory (per instance).
- Backup restore not yet rehearsed.
