# Dirsha Backend

Node.js + TypeScript + PostgreSQL API. **Prototype: simulated funds and test securities only.**
Contract for the apps: [`../docs/API_SPECIFICATION.md`](../docs/API_SPECIFICATION.md) ·
rules: [`../docs/BUSINESS_RULES.md`](../docs/BUSINESS_RULES.md).

## Stack (proposed for team agreement, SRS §15)

| Concern | Choice |test
|---|---|
| HTTP | Express 5 |
| Validation | Zod (strict objects: unknown fields are rejected) |
| Database | PostgreSQL 14+ via `pg`, plain SQL migrations |
| Auth | bcrypt (`bcryptjs`) password hashes + short-lived HS256 JWT access tokens |
| Logging | pino (secrets redacted) with a request id on every request |
| Tests | Vitest + Supertest against a **real** PostgreSQL database |

## Quick start (local)

Prerequisites: Node.js ≥ 20, PostgreSQL ≥ 14.

```bash
cd backend
npm install

# 1. Create a role and two databases (dev + test). Pick your own local password.
createuser --pwprompt dirsha
createdb -O dirsha dirsha_dev
createdb -O dirsha dirsha_test

# 2. Configure (the real .env is git-ignored; .env.example has placeholders only)
cp .env.example .env
#    edit .env: DATABASE_URL, and generate JWT_ACCESS_SECRET with:
#    node -e "console.log(require('crypto').randomBytes(48).toString('hex'))"
#    For local development you may also set ENABLE_TEST_FUNDS=true

# 3. Create tables, add fake data, run
npm run migrate
SEED_PASSWORD='choose-a-local-password' npm run seed     # optional fake accounts, see API spec §6
npm run dev                                              # http://localhost:3000/health
```

## Commands

| Command | What it does |
|---|---|
| `npm run dev` | Start with auto-reload |
| `npm run build` / `npm start` | Compile to `dist/` / run the compiled server |
| `npm run typecheck` · `npm run lint` | Static checks |
| `npm test` | Full test suite (needs `TEST_DATABASE_URL`, see below) |
| `npm run migrate` · `migrate:status` | Apply pending migrations / show status |
| `npm run db:reset` | **Dev only:** drop everything and re-migrate (refuses `NODE_ENV=production`) |
| `npm run seed` | **Dev only:** fake accounts, one company, 5 test IPOs, 10,000 ETB simulated funds |
| `npm run create-admin` | Create an admin (`ADMIN_EMAIL`, `ADMIN_PASSWORD` env vars; password ≥ 12 chars) |
| `npm run migrate:prod` · `create-admin:prod` | Same, run from the compiled `dist/` (no dev dependencies needed) |

## Running the tests

```bash
export TEST_DATABASE_URL='postgres://dirsha:<your-password>@localhost:5432/dirsha_test'
npm test
```

> ⚠️ The test run **drops and recreates the schema** of `TEST_DATABASE_URL` every time (that also proves migrations work
> from a clean database). It refuses any database whose name does not end in `_test`. Never point it at `dirsha_dev`.

Coverage: environment guards, auth, role/ownership checks, validation, IPO visibility, wallet reads, test-fund guards,
ledger concurrency / idempotency / rollback, database-level immutability, migrations, admin provisioning.

## Configuration (environment variables: names only, never commit values)

| Variable | Required | Default | Notes |
|---|---|---|---|
| `NODE_ENV` | no | `development` | `development` \| `test` \| `production` |
| `PORT` | no | `3000` | |
| `DATABASE_URL` | **yes** | – | `postgres://…` connection string |
| `JWT_ACCESS_SECRET` | **yes** | – | ≥ 32 chars; the placeholder value is refused in production |
| `JWT_ACCESS_TTL_SECONDS` | no | `900` | Access-token lifetime |
| `BCRYPT_COST` | no | `12` | |
| `CORS_ORIGINS` | no | empty | Comma-separated browser origins (admin web). Empty = none allowed |
| `ENABLE_TEST_FUNDS` | no | `false` | Dev/test only. **Startup fails if `true` with `NODE_ENV=production`** |
| `AUTH_RATE_LIMIT_MAX` | no | `20` | Sign-in/registration attempts per IP per 15 min |
| `LOG_LEVEL` | no | `info` | |
| `TEST_DATABASE_URL` | tests only | – | Must end in `_test` |
| `SEED_PASSWORD` · `ADMIN_EMAIL` · `ADMIN_PASSWORD` · `ADMIN_NAME` | CLI only | – | Read by the seed / create-admin commands only |

The server refuses to start with missing or unsafe configuration and prints variable **names**, never values.

## Deployment hand-off notes (for the project owner)

- Runtime: Node.js ≥ 20. Build: `npm ci && npm run build`. Start: `npm start` (`node dist/server.js`). Listens on `PORT`.
- Health check: `GET /health` → `200` when the process and database are up, `503` if the database is unreachable. It exposes no configuration.
- Migrations: `npm run migrate:prod` (idempotent; safe to run on every deploy; takes a database advisory lock). Edited, already-applied
  migrations are refused: add a new file instead.
- First admin: `ADMIN_EMAIL=… ADMIN_PASSWORD=… npm run create-admin:prod`.
- Logs: JSON to stdout (one line per request: method, path without query string, status, request id). Authorization headers, passwords
  and tokens are redacted.
- Behind a load balancer: the rate limiter keys on client IP, so the proxy must be trusted (`trust proxy`). **Not configured yet**; tell Member 2
  the topology (ALB/CloudFront) and it will be set. The limiter is in-memory, i.e. per process (fine for a single instance).
- Database: must not be publicly reachable (NFR-SEC-03). The app needs only `SELECT/INSERT/UPDATE` on its tables plus the ability to run migrations.
- No S3 / external service is used yet (document upload is not implemented).

## Layout

```
backend/
├── migrations/            plain SQL, applied in filename order, checksummed
├── src/
│   ├── config/env.ts      validated configuration
│   ├── db/                pool, migration runner, seed + create-admin CLIs
│   ├── http/              auth middleware, error envelope, validation helpers
│   ├── lib/               errors (stable codes), money, logger
│   ├── modules/           auth · users · ipos · wallet (ledger.ts) · audit · health
│   ├── app.ts             builds the Express app from explicit dependencies
│   └── server.ts          process entry point
└── tests/                 Vitest + Supertest, real PostgreSQL
```
Business rules live in `*.service.ts` / `ledger.ts`; route files only parse input and shape output (NFR-MNT-02).

## Known limitations (Phase 1 baseline)

- **No refresh tokens**; sessions last 15 minutes (FR-AUTH-07, P1).
- **Not implemented yet:** subscriptions, allocation, admin review actions, company onboarding, IPO creation, document upload / S3, WebSocket, orders, broker relationships.
  See API spec §7 for the schedule.
- No identity verification, e-mail confirmation or password reset; `verification_status` is only a column.
- Rate limiter is in-memory (single instance only). `trust proxy` is not configured.
- Real-money operation is blocked by design and needs separate legal, security and operational review (SRS §3.2).
