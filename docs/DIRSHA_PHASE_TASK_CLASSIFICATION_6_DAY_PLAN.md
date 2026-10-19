# Dirsha — Phase-by-Phase Team Task Classification and 6-Day Delivery Plan

**Document status:** Team execution plan  
**Plan starts:** Tuesday, 20 October 2026  
**Development phases:** 3 phases × 2 calendar days each  
**Planned development finish:** Sunday, 25 October 2026  
**Deployment phase starts:** Monday, 26 October 2026  
**Team:** 3 developers + project owner (AWS deployment lead)

> **Scheduling assumption:** The plan uses calendar days, not working days. Each phase has two consecutive days. If the team cannot work weekends, shift the dates while keeping each phase to two working days. A six-day schedule is an aggressive MVP sprint: scope must stay focused, tasks must be integrated daily, and unfinished features must be recorded rather than hidden.

---

## 1. Purpose and execution rules

This document tells each member exactly what to build, when to build it, what to deliver, and how the team decides whether a phase is complete.

### Team roles

| Role | Main responsibility | Must not become a bottleneck for |
|---|---|---|
| **Member 1 — Mobile** | Flutter mobile app for investor, company representative, and broker-facing workflows | Backend API decisions; use agreed API contracts and mock responses until endpoints are ready |
| **Member 2 — Backend** | Node.js + TypeScript API, PostgreSQL schema, authentication/authorization, wallet/ledger, IPO and transaction business logic | UI implementation; publish API contracts and example payloads early |
| **Member 3 — Admin Web** | Flutter Web admin dashboard, review workflows, administrative views, integration support and QA coordination | Backend implementation; use mock data while API endpoints are in progress |
| **Project owner — AWS/deployment** | Own AWS account/infrastructure, deployment plan, environment configuration, secrets, networking, database/storage setup, deployment and release checks | Day-to-day feature development; developers must deliver deployment-ready configuration and documentation |

**Important:** Member 3 remains the owner of the admin web interface. The project owner leads AWS deployment; this does not mean developers can leave deployment requirements undocumented.

### Non-negotiable working rules

1. **One repository and one agreed branch strategy.** Use feature branches and pull requests; do not commit directly to the main branch without team agreement.
2. **Commit working increments every day.** Do not wait until the end of a phase to push.
3. **Agree on contracts before parallel implementation.** Member 2 publishes endpoint names, request/response JSON, error formats, and role permissions. Members 1 and 3 can use mock data until the API is ready.
4. **Never commit secrets.** No passwords, JWT secrets, database URLs, AWS access keys, private keys, or real customer documents in Git.
5. **Use test data and simulated money only during this sprint.** Do not enable real-money deposits, withdrawals, bank/mobile-money gateways, or real securities settlement without separate legal, regulatory, security, and operational approval.
6. **Wallet balances must be ledger-backed.** Do not let clients directly edit balances. Every balance-changing operation must be validated by the backend and recorded as a transaction.
7. **Every member tests their work before requesting integration.** Report blockers early and ask for help before the end-of-day checkpoint.
8. **Keep the scope small.** A feature that cannot be completed safely in this sprint must be documented as deferred rather than implemented incompletely.

---

## 2. Delivery timeline at a glance

| Dates | Phase | Main outcome | Exit checkpoint |
|---|---|---|---|
| **Tue, 20 Oct – Wed, 21 Oct** | **Phase 1: Foundation, Identity, Wallet and Primary-Market MVP** | A runnable app set, initial API/database, user roles, wallet ledger foundation, IPO list/details and admin review skeleton | All components run locally; agreed API contract and schema are committed; core screens use real API or clearly marked mocks |
| **Thu, 22 Oct – Fri, 23 Oct** | **Phase 2: Wallet Transactions, IPO Subscription and Allocation** | Users can see test wallet activity and submit an IPO subscription; backend reserves funds safely; admin can review/manage IPO and subscription states | End-to-end test passes for subscription, reservation, insufficient balance, duplicate retry, and release/refund paths |
| **Sat, 24 Oct – Sun, 25 Oct** | **Phase 3: Integration, Quality, Security and Release Readiness** | Integrated MVP, documented limitations, automated/manual tests, deployment configuration and release checklist | Critical tests pass, no known exposed secrets, setup documentation is complete, and project owner accepts the deployment handoff |
| **Mon, 26 Oct onward** | **Deployment phase** | Deploy approved MVP to AWS test/staging environment, validate service, logs, database and storage, then decide production readiness separately | Health checks and smoke tests pass; rollback/recovery steps are documented; production approval is not assumed |

**Calendar note:** Dates are based on the project starting tomorrow, 20 October 2026, and a two-calendar-day duration for each phase.

---

# 3. Phase 1 — Foundation, Identity, Wallet and Primary-Market MVP

**Dates:** Tuesday, 20 October – Wednesday, 21 October 2026  
**Goal:** Establish the shared foundation so the three parts of Dirsha can be developed in parallel. Deliver the minimum vertical slice: user can sign in, view an IPO listing, see a test wallet balance/transaction history, and an administrator can access the basic IPO-review interface. Where a backend path is not yet complete, use explicitly labeled mock data—not fake production behavior.

## 3.1 Member 1 — Flutter Mobile

### Day 1 — Tuesday, 20 October

- [ ] Inspect the existing `mobile/` project and report its current status; do not overwrite working code without agreement.
- [ ] Confirm Flutter version, application entry point, state-management approach, routing, folder conventions and environment configuration with the team.
- [ ] Create or clean the initial app structure, for example:
  - `core/` for shared configuration, network client, errors and theme.
  - `features/auth/` for sign-in and registration/onboarding screens.
  - `features/home/` for home/dashboard.
  - `features/ipos/` for IPO list and detail screens.
  - `features/wallet/` for wallet summary and transaction history.
  - `shared/` for reusable widgets.
- [ ] Build the base navigation and responsive layouts for the target mobile sizes.
- [ ] Implement sign-in and registration UI with validation and loading/error states. Do not store plaintext passwords.
- [ ] Create typed models for the agreed API contract: user, IPO summary, wallet summary and wallet transaction.
- [ ] Connect the network client to the agreed local API base URL, using environment configuration rather than hardcoding a production URL.
- [ ] If the backend is not ready, add a mock repository behind the same interface and label mock/test data clearly.

**Day 1 deliverables**
- App launches without errors.
- Base navigation and auth screens exist.
- Models and API/mock repository structure are committed.
- A short note identifies what is connected to the API versus mocked.

### Day 2 — Wednesday, 21 October

- [ ] Implement the investor home screen with wallet summary and IPO-list entry point.
- [ ] Implement IPO list and IPO details screens, including status, dates, price/terms fields as supplied by the backend contract.
- [ ] Implement wallet summary and transaction history screens, including empty, loading, success and failure states.
- [ ] Connect screens to the available API endpoints; use mocks only for endpoints not yet available.
- [ ] Add client-side validation for form inputs, while treating backend validation as authoritative.
- [ ] Ensure unauthorized/expired-session responses lead to a safe sign-out or re-authentication path.
- [ ] Test navigation and screen layouts on at least one emulator or physical device.
- [ ] Commit code and update `docs/TEAM_TASK_CLASSIFICATION.md` or the sprint status file with blockers and endpoint dependencies.

**Phase 1 acceptance criteria — Member 1**
- [ ] The app launches and navigates without a crash.
- [ ] Auth, IPO list/detail, wallet summary and transaction history screens are present.
- [ ] The UI distinguishes unavailable, empty, loading and error states.
- [ ] No secret or real personal/financial data is embedded in the app.
- [ ] The team can identify exactly which screens use real API data and which still use mocks.

## 3.2 Member 2 — Node.js + TypeScript Backend

### Day 1 — Tuesday, 20 October

- [ ] Inspect `backend/` and document the existing framework and current run status.
- [ ] Set up or standardize Node.js + TypeScript project scripts for development, build, lint/type-check and tests.
- [ ] Establish environment-variable validation and a safe `.env.example` containing placeholders only.
- [ ] Create a health endpoint such as `GET /health` that reports service status without leaking secrets.
- [ ] Set up PostgreSQL connection and migration workflow; avoid relying only on manual database edits.
- [ ] Define initial entities/tables or migration drafts for:
  - users and role assignments;
  - company profiles / onboarding status;
  - IPOs and IPO status history;
  - wallet accounts;
  - wallet transactions / ledger entries;
  - IPO subscriptions.
- [ ] Agree and commit the first API contract with Members 1 and 3. Include success and error response shapes.
- [ ] Define authentication and authorization boundaries for investor, company representative, broker and admin roles.
- [ ] Implement the initial auth/user endpoints only to the extent safely achievable; do not claim full identity verification if it is not implemented.
- [ ] Add input validation and consistent error handling.

**Day 1 deliverables**
- Backend starts locally using documented commands.
- `GET /health` works.
- Database connection/migration approach is established.
- API contract and initial schema/migrations are committed.
- `.env.example` exists; secrets remain outside Git.

### Day 2 — Wednesday, 21 October

- [ ] Implement or complete registration/sign-in/session or token handling appropriate to the chosen auth design.
- [ ] Enforce authorization on server-side routes; hiding a button in the UI is not access control.
- [ ] Implement read endpoints for IPO list and IPO details.
- [ ] Implement wallet summary and wallet transaction-history read endpoints backed by the database.
- [ ] Create a safe test-fund provisioning mechanism restricted to development/test environments and authorized test users. Never expose an unrestricted “add balance” endpoint.
- [ ] Implement ledger-oriented data structures and transaction boundaries for balance-changing operations, even if subscription execution is completed in Phase 2.
- [ ] Ensure money values use a precise representation (e.g. integer minor units or a suitable fixed-precision numeric type), not floating-point arithmetic.
- [ ] Add basic tests for authorization, validation, IPO reads and wallet reads.
- [ ] Publish example requests/responses and note any endpoint not ready for integration.

**Phase 1 acceptance criteria — Member 2**
- [ ] Backend builds and starts using the documented commands.
- [ ] Health, IPO read, wallet summary and transaction-history endpoints work.
- [ ] PostgreSQL migrations are repeatable in a clean development database.
- [ ] Server-side role checks exist for protected endpoints.
- [ ] Test-fund functionality is disabled outside explicitly configured test environments.
- [ ] No balance can be changed by sending a client-supplied balance value.
- [ ] Basic tests pass and API contracts are committed.

## 3.3 Member 3 — Flutter Web Admin Dashboard

### Day 1 — Tuesday, 20 October

- [ ] Inspect `admin/` and confirm the Flutter Web project can run in a browser.
- [ ] Set up routing, shared layout, theme, navigation/sidebar and reusable page structure.
- [ ] Build the admin sign-in screen and protected-route structure; backend authorization remains the real security boundary.
- [ ] Build a dashboard shell with summary cards and clearly labeled placeholder metrics if live endpoints do not exist yet.
- [ ] Build initial user/company review list and IPO management list pages using typed models and a mock-data repository where needed.
- [ ] Agree with Member 2 on role names, status enums, field names and error response conventions.
- [ ] Add loading, empty, error and permission-denied states.
- [ ] Record the exact command to run the web app locally.

**Day 1 deliverables**
- Admin web app launches in a browser.
- Shared layout and navigation are present.
- Basic sign-in, user/company review list and IPO list screens exist.
- Mock data is clearly identified.

### Day 2 — Wednesday, 21 October

- [ ] Implement IPO details/review page with status, company, submitted documents metadata and review actions in the UI.
- [ ] Implement user/company detail view and a placeholder audit/activity view.
- [ ] Connect available endpoints or keep mock repositories behind interfaces.
- [ ] Ensure review actions require confirmation and show success/failure feedback.
- [ ] Ensure admin-only screens are not presented as secure solely because of client-side routing; backend must authorize every admin action.
- [ ] Test the dashboard in a browser at desktop and narrower widths.
- [ ] Prepare a short manual QA checklist for the Phase 2 end-to-end flow.
- [ ] Commit code and list missing backend endpoints/blockers.

**Phase 1 acceptance criteria — Member 3**
- [ ] Admin app launches in a browser without critical console/runtime errors.
- [ ] Navigation, review lists and IPO management screens exist.
- [ ] Review action states and failure feedback are represented.
- [ ] Mock/live data boundaries are documented.
- [ ] A Phase 2 manual QA checklist is ready.

## 3.4 Phase 1 team integration checkpoint — Wednesday evening

All members join a short review and demonstrate their component. The phase is complete only when:

- [ ] All three projects have clear local run instructions.
- [ ] The initial API contract and schema are committed.
- [ ] The mobile app, backend and admin app each start locally.
- [ ] At least one IPO-list flow and wallet-read flow can be demonstrated end-to-end, or the remaining mock dependency is explicitly listed.
- [ ] No secrets are committed.
- [ ] Phase 2 blockers and owners are recorded.

---

# 4. Phase 2 — Wallet Transactions, IPO Subscription and Allocation

**Dates:** Thursday, 22 October – Friday, 23 October 2026  
**Goal:** Complete one coherent and testable transaction flow. Prioritize safe ledger operations and IPO subscription over building many disconnected features. The sprint uses simulated test funds and test securities only.

## 4.1 Member 1 — Flutter Mobile

### Day 3 — Thursday, 22 October

- [ ] Add IPO subscription flow: quantity/amount input, terms summary, validation, review/confirmation screen and result screen.
- [ ] Show available balance and estimated subscription amount before confirmation.
- [ ] Show a clear insufficient-funds error returned by the backend.
- [ ] Prevent accidental repeated taps while a request is in progress, without treating client-side button disabling as the duplicate-transaction safeguard.
- [ ] Display subscription status/history from the backend.
- [ ] Add wallet activity detail with transaction type, status, timestamp and reference ID where available.
- [ ] Use API response fields and status enums defined by Member 2; do not invent client-side transaction success.

**Day 3 deliverables**
- User can review and submit a subscription request.
- Wallet and subscription history screens show backend status.
- Errors and pending states are clear.

### Day 4 — Friday, 23 October

- [ ] Integrate the full subscription flow with the backend.
- [ ] Test success, insufficient funds, invalid quantity, closed IPO, network failure and repeated submission.
- [ ] Ensure the app refreshes wallet and subscription data after a confirmed result.
- [ ] Add clear messaging when funds are reserved, released or refunded.
- [ ] Verify the user cannot access another user's wallet or subscriptions by changing an ID in a request; the backend must enforce ownership.
- [ ] Fix high-priority integration issues and provide evidence/screenshots or a short demo.
- [ ] Update known limitations in the docs.

**Phase 2 acceptance criteria — Member 1**
- [ ] A test user can submit a valid subscription.
- [ ] The UI reflects backend-confirmed status, not assumed success.
- [ ] Insufficient balance and invalid/closed IPO errors are handled.
- [ ] Repeated taps/retries do not mislead the user into thinking multiple subscriptions were created.
- [ ] User-specific wallet/subscription data is displayed only for the authenticated user.

## 4.2 Member 2 — Node.js + TypeScript Backend

### Day 3 — Thursday, 22 October

- [ ] Implement the IPO subscription creation endpoint and request validation.
- [ ] Add server-side checks for IPO status/window, minimum/maximum allowed subscription and other agreed business rules.
- [ ] Implement atomic reservation of funds and subscription creation in a database transaction.
- [ ] Ensure concurrent requests cannot spend the same available balance twice; use appropriate locking/transaction isolation or another justified concurrency-control strategy.
- [ ] Add idempotency protection for transaction-creating requests so a retry with the same idempotency key does not create duplicate financial effects.
- [ ] Record ledger entries for reservation and any balance-state changes.
- [ ] Add an insufficient-funds response with a stable error code.
- [ ] Add tests for valid subscription, insufficient balance, invalid IPO state and duplicate request.

**Day 3 deliverables**
- Subscription endpoint works against the development database.
- Reservation is atomic and ledger-backed.
- Core transaction tests pass.

### Day 4 — Friday, 23 October

- [ ] Implement subscription status/history reads for the authenticated owner and authorized admins.
- [ ] Implement allocation/settlement logic for the agreed MVP test rules, including the correct treatment of allocated versus unallocated funds.
- [ ] Implement release/refund of unused reserved funds as a single auditable operation.
- [ ] Ensure retries cannot create duplicate releases, refunds or settlements.
- [ ] Add admin review/status-change endpoints with explicit role checks and audit records.
- [ ] Add tests for allocation, partial allocation, release of unused reservation, failure/rollback and concurrent requests.
- [ ] Ensure wallet balance is derived from or reconciled against ledger entries; document the chosen model and reconciliation checks.
- [ ] Publish updated API documentation and a short database/migration note.

**Phase 2 acceptance criteria — Member 2**
- [ ] Subscription and reservation occur atomically.
- [ ] Insufficient balance is rejected by the server.
- [ ] Idempotent retries do not duplicate transactions.
- [ ] Unused reserved funds can be released exactly once.
- [ ] Allocation and settlement follow documented test rules.
- [ ] All wallet mutations are auditable and covered by tests.
- [ ] Ownership and role checks are tested.

## 4.3 Member 3 — Flutter Web Admin Dashboard

### Day 3 — Thursday, 22 October

- [ ] Connect the admin IPO list/details screens to the backend.
- [ ] Implement IPO review actions for the statuses supported by the MVP, with confirmation dialogs and reason/notes where required.
- [ ] Implement subscription list/detail views for authorized admins.
- [ ] Display subscription status and non-sensitive transaction references; do not expose secrets or unnecessary personal data.
- [ ] Add filtering/search by IPO, status or reference where supported.
- [ ] Ensure action buttons are disabled while requests are pending and errors are visible.

**Day 3 deliverables**
- Admin can view IPOs and subscriptions using backend data.
- Review/status actions use actual API responses or are explicitly marked as blocked.

### Day 4 — Friday, 23 October

- [ ] Complete the admin workflow needed to support the test IPO subscription lifecycle.
- [ ] Display wallet/ledger transaction references and status for support/audit purposes, without allowing arbitrary balance edits.
- [ ] Add or complete a basic audit/activity page for administrative actions.
- [ ] Test forbidden actions with non-admin roles and confirm the backend denies them.
- [ ] Run the manual QA checklist with Member 1 and Member 2.
- [ ] Log bugs with reproduction steps, expected result, actual result, severity and owner.
- [ ] Verify responsive layout and fix high-priority usability issues.

**Phase 2 acceptance criteria — Member 3**
- [ ] Authorized admin can review supported IPO/subscription states.
- [ ] Admin actions show success/failure and produce auditable backend events.
- [ ] The dashboard does not provide a manual “edit balance” shortcut.
- [ ] Basic search/filter works for supported fields.
- [ ] The end-to-end test findings are recorded with assigned owners.

## 4.4 Phase 2 team integration checkpoint — Friday evening

Run this exact happy path and its failure variants together:

1. Create/use a designated test investor with **10,000 ETB of simulated test funds**.
2. Open an IPO in a valid test state.
3. Submit a subscription that reserves **3,000 ETB**.
4. Verify available balance becomes **7,000 ETB** and the reservation is visible in the ledger/history.
5. Retry the same request with the same idempotency key; verify no duplicate subscription or reservation is created.
6. Attempt a subscription larger than the available balance; verify it is rejected without changing the ledger.
7. Simulate partial allocation or cancellation according to the agreed MVP rules.
8. Verify unused reserved funds are released exactly once and all balances/history reconcile.
9. Confirm the mobile app and admin dashboard show consistent backend statuses.

**Do not treat the example amounts as product rules.** They are test values only. The team must document whether the MVP uses ETB integer minor units or another precise representation and must agree on allocation/cancellation rules.

---

# 5. Phase 3 — Integration, Quality, Security and Release Readiness

**Dates:** Saturday, 24 October – Sunday, 25 October 2026  
**Goal:** Stabilize the MVP and hand over a deployable, documented build to the project owner. This is not a promise that a regulated real-money investment service is production-ready.

## 5.1 Member 1 — Flutter Mobile

### Day 5 — Saturday, 24 October

- [ ] Run the complete mobile smoke test: launch, authentication, IPO list/details, wallet, subscription and history.
- [ ] Fix critical crashes and high-severity API integration issues.
- [ ] Test loading, empty, timeout, server-error and expired-session states.
- [ ] Verify sensitive values are not written to logs and tokens are not stored insecurely.
- [ ] Review form validation and ensure the backend remains authoritative.
- [ ] Test on at least one target device/emulator and record platform/version.
- [ ] Prepare a mobile build/run note and list required environment values (names only, never secret values).

### Day 6 — Sunday, 25 October

- [ ] Fix final high-priority bugs and retest the affected flows.
- [ ] Remove debug-only shortcuts and unintended mock/test controls from the normal app path.
- [ ] Ensure any remaining mock/test features are visibly labeled and disabled or isolated from release configuration.
- [ ] Confirm API base URL is environment-configurable.
- [ ] Add screenshots or a short demo checklist to the release evidence.
- [ ] Submit final commit/PR and a concise handoff: completed, deferred, known issues, how to run.

**Phase 3 acceptance criteria — Member 1**
- [ ] Critical mobile flows pass the agreed smoke test.
- [ ] No known critical crash blocks the MVP.
- [ ] Test/mock mode is clearly separated from normal configuration.
- [ ] Run/build instructions and known issues are documented.

## 5.2 Member 2 — Node.js + TypeScript Backend

### Day 5 — Saturday, 24 October

- [ ] Run all unit/integration tests and fix transaction, authorization and migration failures.
- [ ] Review every balance-changing endpoint for atomicity, idempotency, ownership and audit logging.
- [ ] Verify no API accepts arbitrary client-supplied balances or trusts role values supplied by the client.
- [ ] Verify request validation, safe error responses, rate-limiting approach for auth-sensitive endpoints and no secrets in logs.
- [ ] Confirm database migrations work from a clean database and document backup/recovery assumptions.
- [ ] Provide deployment configuration requirements: runtime version, build/start commands, port, health endpoint, environment variable names, database migration command and logging behavior.
- [ ] Create/verify a safe `.env.example`; confirm `.env` and credentials are ignored by Git.
- [ ] Document any external services or storage permissions needed.

### Day 6 — Sunday, 25 October

- [ ] Run the complete backend test suite and publish results.
- [ ] Perform a final role/ownership review for investor, company representative, broker and admin routes.
- [ ] Verify health endpoint behavior and ensure it does not expose internal configuration.
- [ ] Add API documentation for all endpoints used by the mobile and admin apps.
- [ ] Provide seed-data instructions for non-sensitive development/test data only.
- [ ] Prepare a short database schema/migration and rollback note.
- [ ] Hand over a deployment checklist to the project owner; do not place credentials in documentation or Git.

**Phase 3 acceptance criteria — Member 2**
- [ ] Build and test commands work from a clean checkout.
- [ ] Critical wallet/subscription tests pass.
- [ ] Secrets are not tracked by Git.
- [ ] API, environment, migration and health-check instructions are documented.
- [ ] Known limitations are explicitly listed; no unimplemented feature is claimed as complete.

## 5.3 Member 3 — Flutter Web Admin Dashboard

### Day 5 — Saturday, 24 October

- [ ] Run admin workflows end-to-end against the development API.
- [ ] Fix high-severity runtime, routing, permission-state and API integration issues.
- [ ] Verify loading, empty, error, success and permission-denied states for important pages.
- [ ] Check that administrative actions ask for confirmation where appropriate and display the backend result.
- [ ] Review displayed user and financial information for data minimization.
- [ ] Test desktop and narrow-browser layouts.
- [ ] Finish the manual QA checklist and record defects with severity/owner.

### Day 6 — Sunday, 25 October

- [ ] Retest all fixed defects and mark each pass/fail with evidence or notes.
- [ ] Ensure mock data is disabled or clearly separated from API-backed release configuration.
- [ ] Verify the admin frontend uses the configured API base URL, not a hardcoded developer machine address.
- [ ] Document build/run commands and required non-secret configuration values.
- [ ] Prepare admin demo steps and a concise known-issues list.
- [ ] Coordinate final acceptance review with the project owner and both developers.

**Phase 3 acceptance criteria — Member 3**
- [ ] Core admin review/subscription views work against the API.
- [ ] Admin actions show real backend outcomes.
- [ ] No critical UI or routing defect blocks the MVP.
- [ ] QA checklist, defects and handoff notes are complete.

## 5.4 Project owner — Daily oversight and deployment preparation

The project owner is not a fourth feature developer in this schedule. During the three development phases:

### Day 1–2 (20–21 October)
- [ ] Confirm scope, role definitions, business rules and the test-only money model.
- [ ] Confirm repository permissions, branch/PR rules and issue board.
- [ ] Review the API contract and approve key architecture decisions.
- [ ] Prepare an AWS deployment checklist and identify the intended test/staging environment.
- [ ] Do not create or share long-lived credentials in source code or chat.

### Day 3–4 (22–23 October)
- [ ] Review wallet/ledger integrity tests and the subscription happy-path demonstration.
- [ ] Confirm the MVP does not connect to real-money payment rails.
- [ ] Identify required AWS services and estimate operational costs before provisioning.
- [ ] Prepare secure environment/secrets handling and least-privilege IAM plan.

### Day 5–6 (24–25 October)
- [ ] Review test results, known limitations and open high-severity defects.
- [ ] Confirm backend health check, startup/build instructions, migration process and log expectations are ready.
- [ ] Confirm storage access will be private by default for sensitive documents, with authorized access and time-limited access mechanisms as appropriate.
- [ ] Accept or reject the deployment handoff based on the exit checklist; do not deploy an unstable build just to meet the date.

---

# 6. Deployment phase — begins Monday, 26 October 2026

**The deployment phase starts after the six-day development sprint.** It is separate from the three development phases and should not be squeezed into Phase 3.

## Deployment workstreams

### Project owner — AWS deployment lead

- [ ] Confirm the target environment is a test/staging environment and define who can access it.
- [ ] Select/confirm AWS resources and network design based on actual requirements and cost limits.
- [ ] Configure IAM with least privilege and use a managed secrets mechanism or an approved secure alternative.
- [ ] Provision/configure PostgreSQL (for example, RDS if selected), networking, security groups and backup settings.
- [ ] Configure private S3 storage for private documents and define access policies; do not make identity/financial documents public.
- [ ] Deploy the backend to the selected compute target (EC2 is the current intended approach unless the owner approves a change).
- [ ] Configure TLS/HTTPS, domain/DNS if available, health checks, logs, alerts and basic monitoring.
- [ ] Apply database migrations using the documented process.
- [ ] Configure environment variables/secrets outside Git.
- [ ] Deploy the admin web build and mobile test build/configuration as appropriate for the agreed test strategy.
- [ ] Run smoke tests, verify logs and permissions, and document rollback/recovery steps.
- [ ] Record resource costs and teardown steps for unused test resources.

### Member 1 — Mobile deployment support

- [ ] Provide a release/test build and confirm the configured API endpoint.
- [ ] Test the mobile client against the deployed staging API.
- [ ] Report connectivity, TLS, authentication/session and API errors.
- [ ] Confirm no development-only mock data is accidentally presented as real data.

### Member 2 — Backend deployment support

- [ ] Assist with backend deployment, environment configuration, migrations and health checks.
- [ ] Verify database connectivity from the intended compute environment only.
- [ ] Check logs and diagnose deployment failures without printing secrets.
- [ ] Verify CORS/origin policy if applicable, request limits, authentication and role enforcement.
- [ ] Run deployed API tests and wallet/subscription integrity checks.
- [ ] Provide a rollback plan for application releases and a recovery plan for database changes.

### Member 3 — Admin web deployment and acceptance support

- [ ] Provide the production-build command and environment configuration instructions.
- [ ] Verify the deployed dashboard points to the staging API and has no hardcoded localhost URL.
- [ ] Test admin login, review workflow, subscription view and forbidden-access behavior.
- [ ] Check browser console/network errors and report defects.
- [ ] Complete the deployment smoke-test checklist with the project owner.

## Deployment exit criteria

- [ ] Backend health endpoint passes.
- [ ] Mobile and admin web clients reach the intended API over HTTPS where publicly accessed.
- [ ] Database is not publicly exposed unless there is a separately reviewed, justified exception.
- [ ] S3 documents are private by default.
- [ ] Secrets are not present in Git, frontend bundles, logs or screenshots.
- [ ] Database migrations complete and backup/recovery assumptions are documented.
- [ ] Auth, ownership and role-based access checks pass in staging.
- [ ] Wallet subscription/reservation/release smoke tests pass against staging test data.
- [ ] Monitoring/logging and rollback/recovery instructions exist.
- [ ] Project owner signs off on the staging release.

**Important:** Passing staging checks does not authorize real-money operation. Before real funds, real securities or public investment offers are enabled, obtain the appropriate Ethiopian legal/regulatory review, security assessment, operational controls, reconciliation procedures and explicit business approval.

---

# 7. Daily communication and reporting

## Daily rhythm

- **Start of day (10–15 minutes):** Each member says what they will finish today, what they need from others, and any blocker.
- **During the day:** Push small commits and open draft PRs early. Communicate API changes before changing shared contracts.
- **End of day (15–30 minutes):** Demonstrate working progress, run the relevant tests, update the task board and list blockers with an owner.
- **Phase boundary:** No phase is accepted solely because the date has arrived. Use the phase acceptance checklist.

## Daily status template

Copy this into the team issue board or daily chat:

```text
Date:
Member:
Completed today:
Evidence (PR/commit/demo/test):
In progress:
Blocked by:
Help needed from:
Plan for tomorrow:
Known risks:
```

## Task status definitions

- **Not started:** No implementation has begun.
- **In progress:** Work has begun, but acceptance criteria are not met.
- **In review:** Code is pushed and ready for another member to review.
- **Blocked:** Work cannot continue due to a named dependency; the blocker and owner are recorded.
- **Done:** Acceptance criteria are met, code is committed, tests are run, and documentation is updated where necessary.

---

# 8. Shared definition of done

A task is not complete merely because its screen or endpoint exists. Mark it done only when:

- [ ] It matches the agreed requirement/API contract.
- [ ] It handles expected success and failure cases.
- [ ] It has appropriate validation and authorization.
- [ ] It has tests or a recorded manual verification appropriate to its risk.
- [ ] It does not introduce secrets, unsafe defaults or misleading mock behavior.
- [ ] It is committed and reviewed through the agreed workflow.
- [ ] Relevant setup/API/known-limitations documentation is updated.

# 9. Scope guardrails and deferred work

The sprint is an MVP integration sprint, not the complete implementation of every long-term Dirsha idea. Unless the team explicitly trades off other scope, defer the following:

- Real deposits and withdrawals, mobile-money/bank/payment-gateway integrations and real-money settlement.
- Real securities trading or a production-grade exchange/matching engine.
- Production identity verification, regulatory onboarding and real document-verification services.
- A production-grade broker commission/payout engine.
- AI investment advice, recommendations or any AI feature that could be interpreted as financial advice.
- High-availability architecture, advanced analytics and nonessential visual polish.

Keep the wallet as a **core feature**, but implement it first as an auditable internal ledger with simulated test funds. Do not let any client set a balance directly. Define and document the rules for available, reserved and settled funds before adding more wallet operations.

# 10. Final handoff package — due Sunday, 25 October

By the end of Phase 3, the team should have:

- [ ] Mobile app source and local run/build instructions.
- [ ] Backend source, API documentation, migrations, test results and `.env.example`.
- [ ] Admin web source and local run/build instructions.
- [ ] Committed SRS and this task plan.
- [ ] Database design and agreed wallet/IPO business rules.
- [ ] Test checklist and test results for the subscription lifecycle.
- [ ] Known issues, deferred features and risks.
- [ ] AWS deployment notes, health-check instructions and required configuration names.
- [ ] A list of items needing legal/security/business review before real-money operation.

**Final rule:** If a critical wallet-integrity, authorization, secret-management or data-exposure issue remains open on 25 October, record it and fix it before staging release. The schedule is a target, not a reason to bypass security.
