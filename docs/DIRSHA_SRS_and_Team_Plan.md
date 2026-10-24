# DIRSHA --- Software Requirements Specification and Team Development Plan

**Document version:** 1.1\
**Status:** Phase 2 Complete Baseline — Transitioning to Phase 3 (Quality, Security & Release Readiness)\
**Project:** Dirsha (ድርሻ) --- Proposed Ethiopian digital investment
platform\
**Date:** 24 October 2026

> **Important scope note:** This document specifies a development
> prototype and its intended workflows. It does not establish that
> Dirsha is authorized to operate as a securities exchange, broker,
> investment adviser, custodian, payment service, or other regulated
> financial service. Before handling real investments or real customer
> funds, the team must obtain qualified legal/regulatory advice, confirm
> applicable Ethiopian requirements, and complete independent security,
> financial-control, and operational reviews.

------------------------------------------------------------------------

## 1. Purpose and Document Conventions

This Software Requirements Specification (SRS) defines the proposed
product scope, user roles, functional requirements, quality
requirements, high-level architecture, acceptance criteria, and task
ownership for a three-developer team.

Requirements use these labels:

-   **P0 --- Essential:** required for the controlled prototype and core
    workflows.
-   **P1 --- Important:** required for a complete demonstration or
    planned feature set.
-   **P2 --- Later:** enhancement that may be deferred.
-   **TBD --- To be decided:** requires a team decision before
    implementation.

The SRS is a living document. Update it when the team agrees on scope,
workflow rules, or technical decisions. Record significant changes in
Git history.

## 2. Project Overview

### 2.1 Product vision

Dirsha aims to provide a digital platform through which companies can
submit proposed public share offerings, administrators can review and
manage those offerings, and investors can learn about offerings, submit
subscriptions, view allocations, and---within the prototype's defined
scope---trade eligible listed shares. The platform also plans to support
broker-investor relationships and an educational AI assistant in Amharic
and English.

### 2.2 Objectives

1.  Provide role-appropriate experiences for investors, companies,
    brokers, and administrators.
2.  Support a traceable IPO submission, review, subscription, closure,
    and allocation workflow.
3.  Maintain consistent records for subscriptions, funds represented in
    the prototype, orders, trades, and holdings.
4.  Enforce authorization on the backend for every protected operation.
5.  Provide a maintainable architecture that can be deployed to AWS by
    the project owner.
6.  Establish documentation, testing, auditability, and security
    practices from the beginning.

### 2.3 Success measures

-   Users can complete approved workflows for their assigned roles.
-   Unauthorized requests are rejected by the backend, even if manually
    constructed outside the UI.
-   IPO and subscription state transitions are validated and traceable.
-   Duplicate/retried requests do not create duplicate financial
    operations.
-   Orders, trades, ledger entries, and holdings remain consistent under
    tested concurrent operations.
-   Critical workflows have automated tests and documented acceptance
    results.
-   Setup, configuration, API, and deployment notes are documented for
    another developer to follow.

## 3. Scope

### 3.1 Included in the project plan

-   Mobile app built with Flutter for investors, companies, and brokers.
-   Separate Flutter Web admin dashboard.
-   Node.js + TypeScript backend exposing a documented REST API.
-   PostgreSQL relational database.
-   Role- and resource-based authorization.
-   Account/profile and company onboarding workflows.
-   IPO submission, review, publication, subscription, closure, and
    allocation.
-   Internal wallet/ledger for balance control, transaction history, fund reservation/release, and test-fund workflows.
-   Investor holdings and portfolio views.
-   Secondary-market order book and matching engine for test securities.
-   Broker relationships and permission modes.
-   Notifications and WebSocket market/order updates where needed.
-   S3 document storage design, secure access controls, and AWS-ready
    configuration.
-   Audit logs, automated tests, error handling, and documentation.
-   Optional AI educational assistant after core workflows are stable.

### 3.2 Explicitly out of scope unless separately approved

-   Handling real customer money or deposits.
-   Real payment settlement, banking integrations, or withdrawals.
-   Launching a real securities exchange or public trading venue.
-   Claiming regulatory approval or authorization.
-   Personalized investment advice or AI-generated buy/sell
    recommendations.
-   Autonomous AI trading.
-   Production identity verification through a third-party provider
    before that provider and legal basis are selected.
-   High-frequency trading, complex derivatives, margin lending, short
    selling, or market manipulation detection beyond prototype-level
    flags.
-   Microservices, Kubernetes, and multi-region deployment at the
    initial stage.

**Prototype rule:** Use clearly labelled simulated funds and test
securities until legal, compliance, payment, operational, and security
requirements for any real-money use are confirmed.

## 4. Stakeholders and User Roles

### 4.1 Investor

Can register, manage their profile, browse available IPOs, review
offering information, submit and track subscriptions, view allocations
and holdings, and place permitted orders for eligible listed test
securities.

### 4.2 Company representative

Can manage an organization profile, submit supporting documents, create
and submit IPO applications, review application status, and view
permitted subscription/allocation summaries for its own offerings.

### 4.3 Broker

Can manage an approved broker profile and, where an investor has
established an active relationship, perform only the actions permitted
by the selected mode and recorded authorization. Broker actions must be
attributable to the broker and auditable.

### 4.4 Administrator

Can review user/company/broker applications, review IPO submissions,
approve/reject or suspend within granted permissions, monitor system
activity, and inspect audit records. Privileged actions must be logged.

### 4.5 Project owner / deployment lead

The project owner coordinates AWS deployment and infrastructure
decisions. Developers must provide deployable application configuration,
documented environment variables, health checks, logs, and integration
support. Deployment ownership does not remove developers' responsibility
for secure coding and deployment-readiness documentation.

## 5. Three-Phase Delivery Plan

### Phase 1 --- Foundation and Primary Market [COMPLETED & VERIFIED]

**Goal:** Establish the application foundation and deliver the
company/IPO/subscription workflow.

**Status:** Completed and verified locally and against PostgreSQL backend on 21 October 2026.

Deliverables: - Repository conventions, local setup instructions, and
API contract. - Authentication, profiles, roles, account status, and
authorization middleware. - Company onboarding and document
metadata/storage integration. - Admin review workflows. - IPO
application lifecycle and offering details. - Investor IPO discovery and
subscription submission. - Prototype test-fund/ledger model sufficient
for safe simulation. - Audit events, input validation, initial automated
tests, and API documentation.

**Exit criteria:** A company can submit a profile and IPO; an
administrator can review it; an approved offering can open; an eligible
investor can submit a subscription; status and history are persisted and
visible to authorized users. *(Passed)*

### Phase 2 --- Allocation, Secondary Market, and Brokerage [COMPLETED & VERIFIED]

**Goal:** Complete the main investment lifecycle using test funds and
test securities.

**Status:** Completed and verified end-to-end on 24 October 2026 across physical Android device (Samsung `R7AX60V79ZB` via ADB reverse proxy), PostgreSQL backend on port 3000, and Flutter Web Admin dashboard on port 8080.

Deliverables: - IPO closure and deterministic allocation rules (`POST /admin/ipos/:id/close` and `POST /admin/ipos/:id/allocate`). -
Allocation records and holdings. - Portfolio views. - Wallet
reservations, ledger operations, and development test-fund provisioning (`POST /dev/test-funds` with in-app UI). - Order lifecycle
and cancellation. - Order book and price-time matching engine. - Trade
records and consistent balance/holding updates. - Broker-investor
relationship and self-directed/advisory/managed permission
enforcement. - WebSocket updates for order/trade/market state. -
Concurrency, idempotency, and failure-path tests.

**Exit criteria:** The system can close an IPO, allocate shares, list
eligible test securities, accept and match orders according to
documented rules, and maintain consistent ledger and holding records
under automated tests. *(Passed — live end-to-end verified with test funds, atomic fund reservations, admin IPO closure and allocation with unallocated refund).*

### Phase 3 --- Intelligence, Hardening, and Readiness Review [ACTIVE / IN PROGRESS]

**Goal:** Add agreed advanced features and validate operational
readiness.

**Status:** Officially kicked off (24 October – 25 October 2026).

Deliverables: - Optional educational AI assistant in Amharic and
English, with clear limitations and source-grounded explanations. -
Administrative monitoring and human-review flags. - Expanded security,
privacy, accessibility, and performance testing. - Backup/restore and
incident-response exercises. - Logging, metrics, alerting, and
dependency review. - AWS deployment documentation and environment
configuration support. - End-to-end test report, known-issues list, and
regulatory/operational readiness checklist.

**Exit criteria:** Critical workflows pass agreed tests; high-risk
findings are resolved or documented; restore and operational procedures
are demonstrated; real-money operation remains blocked until appropriate
external legal, regulatory, security, and operational reviews are
complete.

**Cross-phase rule:** Security, testing, code review, and documentation
happen in every phase---not only Phase 3.

## 6. Functional Requirements

Each requirement has an identifier and priority. The team should convert
these into GitHub issues with acceptance criteria.

### 6.1 Authentication and account management

-   **FR-AUTH-01 (P0):** The system shall allow users to register and
    sign in using the agreed authentication method.
-   **FR-AUTH-02 (P0):** Passwords shall be stored using a suitable
    password-hashing algorithm; plaintext passwords shall never be
    stored or logged.
-   **FR-AUTH-03 (P0):** The backend shall authenticate protected API
    requests and validate token expiry and relevant claims.
-   **FR-AUTH-04 (P0):** The backend shall enforce role and resource
    authorization for each protected operation; UI hiding alone is not
    authorization.
-   **FR-AUTH-05 (P0):** Users shall be able to view and update
    permitted profile fields.
-   **FR-AUTH-06 (P0):** The system shall represent account and
    verification status separately from role.
-   **FR-AUTH-07 (P1):** The system shall support secure logout and
    refresh-token revocation/rotation as selected in the authentication
    design.
-   **FR-AUTH-08 (P1):** The system shall record security-relevant
    events such as repeated failed sign-ins and privileged account
    status changes without logging secrets.

### 6.2 Company and broker onboarding

-   **FR-ONB-01 (P0):** A company representative shall be able to submit
    organization information and required supporting documents.
-   **FR-ONB-02 (P0):** The system shall track onboarding status,
    reviewer, decision, timestamps, and permitted rejection reasons.
-   **FR-ONB-03 (P0):** An administrator with appropriate permission
    shall be able to approve or reject an application.
-   **FR-ONB-04 (P1):** A broker shall be able to submit a broker
    profile for review.
-   **FR-ONB-05 (P1):** Only an approved broker may establish
    broker-investor relationships or perform broker-only actions.
-   **FR-ONB-06 (P0):** A user shall not be able to read or alter
    another organization's private information without explicit
    authorization.

### 6.3 Document management

-   **FR-DOC-01 (P0):** Authorized users shall be able to upload
    permitted documents through a controlled backend-mediated or
    short-lived presigned-URL workflow.
-   **FR-DOC-02 (P0):** The database shall store document metadata,
    owner/resource relationship, storage key, review status, and
    timestamps; the file object shall be stored in private object
    storage.
-   **FR-DOC-03 (P0):** Public access to private documents shall be
    blocked by default.
-   **FR-DOC-04 (P1):** The system shall validate file type and size and
    apply malware scanning or a documented compensating control before
    sensitive documents are made available.
-   **FR-DOC-05 (P0):** Every document download request shall be
    authorized against the requesting user's role and resource
    relationship.

### 6.4 IPO lifecycle

-   **FR-IPO-01 (P0):** An authorized company representative shall be
    able to create and save an IPO draft.
-   **FR-IPO-02 (P0):** The system shall validate required offering
    fields and supporting documents before submission.
-   **FR-IPO-03 (P0):** An IPO shall follow a defined state machine,
    such as Draft, Submitted, Under Review, Approved, Open, Closed,
    Allocated, and Listed, with Rejected/Withdrawn paths where
    applicable.
-   **FR-IPO-04 (P0):** Only an authorized administrator shall approve
    or reject an IPO submission.
-   **FR-IPO-05 (P0):** Only an approved offering that satisfies
    publication rules may open for subscription.
-   **FR-IPO-06 (P0):** The system shall enforce subscription opening
    and closing times on the backend.
-   **FR-IPO-07 (P0):** The company shall only view private application
    and offering information it is authorized to access.
-   **FR-IPO-08 (P1):** The system shall retain decision history and
    audit events for material IPO state changes.

### 6.5 Subscriptions and allocation

-   **FR-SUB-01 (P0):** An eligible investor shall be able to submit a
    subscription for an open IPO.
-   **FR-SUB-02 (P0):** The backend shall validate the IPO state,
    subscription limits, user eligibility, requested quantity, and
    available test funds.
-   **FR-SUB-03 (P0):** Subscription requests shall support idempotency
    or an equivalent duplicate-request protection mechanism.
-   **FR-SUB-04 (P0):** The system shall record subscription
    quantity/amount, status, timestamps, and relevant financial ledger
    references.
-   **FR-SUB-05 (P0):** At closure, the system shall apply a documented
    allocation algorithm and persist the results.
-   **FR-SUB-06 (P0):** The allocation design shall define
    oversubscription handling, rounding, residual shares,
    minimum/maximum allocation, and unused-fund release/refund behavior.
-   **FR-SUB-07 (P0):** Investors shall be able to view their own
    subscription and allocation results.
-   **FR-SUB-08 (P1):** Authorized company users shall be able to view
    aggregate offering/subscription results without exposing unnecessary
    investor personal data.

### 6.6 Internal wallet, balance control, and ledger

The wallet is a core Dirsha feature. It provides an internal account balance and a trustworthy record of how funds are credited, reserved, committed, released, or refunded within the platform. In the initial prototype, balances use simulated funds; this does not mean the wallet feature itself is out of scope. Real-world funding rails and withdrawals are separate integrations.

-   **FR-LED-01 (P0):** The prototype shall clearly label simulated
    funds and shall not imply that they are real money.
-   **FR-LED-02 (P0):** Financial movements shall be represented by
    immutable or correction-linked ledger entries rather than silent
    balance overwrites.
-   **FR-LED-03 (P0):** The system shall distinguish available funds
    from reserved funds.
-   **FR-LED-04 (P0):** A single logical operation shall not be applied
    more than once when the same idempotency key/request is retried.
-   **FR-LED-05 (P0):** Related ledger, order, trade, and holding
    updates shall use appropriate database transactions and consistency
    controls.
-   **FR-LED-06 (P0):** The system shall record who/what initiated a
    financial operation, its reason/type, amount, status, and related
    business reference.
-   **FR-LED-07 (P1):** Authorized administrators shall be able to
    review ledger events without having unrestricted ability to rewrite
    financial history.

### 6.7 Portfolio and holdings

-   **FR-PORT-01 (P0):** Investors shall be able to view their own
    holdings and allocation history.
-   **FR-PORT-02 (P0):** The system shall distinguish total shares from
    shares available to sell and shares reserved by open sell orders.
-   **FR-PORT-03 (P1):** Portfolio valuation shall identify the price
    source and timestamp and shall be labelled as an estimate.
-   **FR-PORT-04 (P0):** Investors shall not be able to view or modify
    another investor's private portfolio data.

### 6.8 Orders, order book, and matching

-   **FR-ORD-01 (P1):** Eligible investors shall be able to submit valid
    buy and sell orders for listed test securities.
-   **FR-ORD-02 (P1):** The backend shall validate order type, quantity,
    price where applicable, security status, account status, available
    funds/shares, and permissions.
-   **FR-ORD-03 (P1):** The system shall define order states, including
    Open, Partially Filled, Filled, Cancelled, Rejected, and Expired
    where applicable.
-   **FR-ORD-04 (P1):** The matching engine shall apply documented
    price-time priority and deterministic tie-breaking rules.
-   **FR-ORD-05 (P1):** The engine shall support partial fills and
    create durable trade records for executed quantities.
-   **FR-ORD-06 (P1):** Order cancellation shall race safely with
    matching; already executed quantities shall not be undone by
    cancellation.
-   **FR-ORD-07 (P1):** The system shall prevent selling more shares
    than are available and prevent reserving/spending the same funds
    more than once.
-   **FR-ORD-08 (P1):** The system shall update orders, trades, ledger
    entries, and holdings consistently or fail the related transaction
    safely.
-   **FR-ORD-09 (P1):** The system shall define market-order behavior,
    price protection, and insufficient-liquidity behavior before
    implementation.
-   **FR-ORD-10 (P1):** The system shall record order and trade history
    for authorized users and audit purposes.

### 6.9 Broker relationships and permissions

-   **FR-BRK-01 (P1):** An investor shall be able to establish a broker
    relationship only with an approved broker.
-   **FR-BRK-02 (P1):** The system shall support self-directed,
    advisory, and managed modes with explicit permission definitions.
-   **FR-BRK-03 (P1):** In advisory mode, a broker shall not submit
    orders on behalf of the investor.
-   **FR-BRK-04 (P1):** In managed mode, broker actions shall be
    constrained by the investor's recorded authorization and limits.
-   **FR-BRK-05 (P1):** Investors shall be able to revoke or change a
    relationship according to defined rules.
-   **FR-BRK-06 (P1):** Broker-initiated actions shall record the broker
    identity, investor identity, authorization basis, action, timestamp,
    and result.

### 6.10 Notifications and real-time updates

-   **FR-RT-01 (P1):** The system shall notify authorized clients about
    relevant order, trade, IPO, and allocation state changes.
-   **FR-RT-02 (P1):** WebSocket connections shall be authenticated and
    access to private events shall be authorized.
-   **FR-RT-03 (P1):** Notifications shall not be treated as the
    authoritative record of a financial operation; clients shall be able
    to retrieve the persisted status through the API.
-   **FR-RT-04 (P2):** The system may support user notification
    preferences and additional delivery channels.

### 6.11 Administration and audit

-   **FR-ADM-01 (P0):** Administrative operations shall require
    authenticated, explicitly authorized accounts.
-   **FR-ADM-02 (P0):** Approval, rejection, suspension, and other
    privileged actions shall be audited.
-   **FR-ADM-03 (P0):** Audit records shall include actor, action,
    target resource, timestamp, outcome, and relevant
    correlation/reference identifier.
-   **FR-ADM-04 (P1):** Administrators shall be able to review flagged
    events and record investigation outcomes.
-   **FR-ADM-05 (P0):** The system shall avoid recording passwords,
    access tokens, secret keys, or unnecessary sensitive personal data
    in logs.

### 6.12 Educational AI assistant

-   **FR-AI-01 (P2):** The assistant may explain general investing and
    IPO terminology in Amharic and English.
-   **FR-AI-02 (P2):** When summarizing company/IPO information, the
    assistant shall use authorized source material and distinguish
    source facts from general explanation.
-   **FR-AI-03 (P2):** The assistant shall not execute trades or
    independently alter balances, holdings, orders, or approvals.
-   **FR-AI-04 (P2):** The interface shall disclose that AI output may
    be incomplete and is not a substitute for professional advice.
-   **FR-AI-05 (P2):** Access to private documents and account
    information shall follow existing authorization rules; the AI layer
    shall not bypass them.

## 7. Non-Functional Requirements

### 7.1 Security

-   **NFR-SEC-01:** All external API traffic shall use HTTPS in deployed
    environments.
-   **NFR-SEC-02:** Secrets and database credentials shall not be
    committed to Git or embedded in Flutter binaries.
-   **NFR-SEC-03:** RDS shall not be publicly accessible in the intended
    AWS deployment; access shall be restricted to authorized backend
    resources.
-   **NFR-SEC-04:** Private S3 buckets shall block public access by
    default.
-   **NFR-SEC-05:** Sensitive data shall be protected in transit and at
    rest using appropriate encryption.
-   **NFR-SEC-06:** Authorization shall be enforced server-side and
    tested for object-level access violations.
-   **NFR-SEC-07:** Dependencies shall be reviewed and updated;
    high-risk vulnerabilities shall be triaged before release.
-   **NFR-SEC-08:** Administrative access shall use least privilege and
    strong authentication appropriate to risk.
-   **NFR-SEC-09:** Logs shall exclude secrets and minimize sensitive
    personal information.

### 7.2 Financial integrity and consistency

-   **NFR-FIN-01:** The system shall preserve consistency among orders,
    executions, ledger entries, and holdings.
-   **NFR-FIN-02:** Concurrent operations shall not overspend funds or
    oversell holdings.
-   **NFR-FIN-03:** Retried requests shall not duplicate subscriptions,
    reservations, or trades.
-   **NFR-FIN-04:** Financial history shall be traceable and corrections
    shall be represented transparently.
-   **NFR-FIN-05:** The team shall test transaction rollback and
    recovery behavior for failures at critical points.

### 7.3 Reliability and recovery

-   **NFR-REL-01:** Errors shall return clear, non-sensitive responses
    and shall be logged with correlation identifiers.
-   **NFR-REL-02:** Database backup and restore procedures shall be
    documented and tested before a production-readiness claim.
-   **NFR-REL-03:** The system shall expose a health endpoint for
    deployment monitoring.
-   **NFR-REL-04:** Background tasks and event delivery shall handle
    retries without duplicating business operations.
-   **NFR-REL-05:** The project shall document known limitations and
    recovery steps.

### 7.4 Performance and scalability

-   **NFR-PERF-01:** The team shall establish measurable response-time
    and concurrency targets before performance testing. Initial
    numerical targets are TBD.
-   **NFR-PERF-02:** Database queries and endpoints shall be measured
    and indexed based on actual query patterns.
-   **NFR-PERF-03:** The matching engine shall be tested with concurrent
    orders and repeatable datasets.
-   **NFR-PERF-04:** Real-time updates shall not be required for
    correctness; persisted API/database state remains authoritative.
-   **NFR-PERF-05:** The architecture shall avoid premature
    microservices and permit later scaling when measured needs justify
    it.

### 7.5 Usability and accessibility

-   **NFR-UX-01:** The mobile application shall support common phone
    screen sizes and clear loading, empty, success, and error states.
-   **NFR-UX-02:** Financial amounts, share quantities, dates, and
    statuses shall be labelled unambiguously.
-   **NFR-UX-03:** The product should support English and plan for
    Amharic localization; exact localization scope is TBD.
-   **NFR-UX-04:** Critical actions such as submitting a subscription or
    order shall show a review/confirmation step where appropriate.
-   **NFR-UX-05:** UI permissions are for usability only and shall not
    replace backend authorization.

### 7.6 Maintainability and testability

-   **NFR-MNT-01:** Backend code shall use TypeScript and consistent
    formatting/linting conventions.
-   **NFR-MNT-02:** Business rules shall be separated from HTTP
    route/controller code.
-   **NFR-MNT-03:** API schemas and error formats shall be documented
    and versioned as needed.
-   **NFR-MNT-04:** Critical business rules shall have unit and
    integration tests.
-   **NFR-MNT-05:** Pull requests shall be reviewed by at least one
    other team member before merging to the main branch.
-   **NFR-MNT-06:** Local setup and environment-variable requirements
    shall be documented without exposing real secrets.

### 7.7 Privacy and compliance

-   **NFR-PRV-01:** The team shall collect only personal data needed for
    the approved prototype scope.
-   **NFR-PRV-02:** Access, retention, deletion, and sharing rules for
    identity and financial information shall be documented.
-   **NFR-PRV-03:** Before real-world use, the team shall obtain
    qualified review of applicable Ethiopian legal and regulatory
    requirements.
-   **NFR-PRV-04:** Marketing and UI language shall not imply that test
    funds, test securities, or prototype functionality represent
    regulated real-money services.

## 8. High-Level System Architecture

### 8.1 Applications and services

-   **Mobile:** Flutter application for investor, company, and broker
    workflows.
-   **Admin:** Separate Flutter Web dashboard for privileged
    administrative workflows.
-   **Backend:** Node.js + TypeScript application exposing REST
    endpoints and authenticated WebSocket events.
-   **Database:** PostgreSQL as the authoritative relational store for
    users, offerings, subscriptions, ledger entries, orders, trades, and
    holdings.
-   **File storage:** Private Amazon S3 bucket for uploaded documents;
    PostgreSQL stores metadata and object keys.
-   **Deployment:** Project owner manages AWS deployment. Initial
    proposal is EC2 for the backend, RDS for PostgreSQL, and S3 for
    files/static web assets; CloudFront, load balancing, monitoring, and
    secrets management are selected as needed and budget permits.

### 8.2 Trust boundaries

The Flutter clients are untrusted. They must not contain database
credentials or decide authoritative balances, permissions, allocations,
or trade outcomes.

All sensitive operations pass through the backend. The backend validates
authentication, authorization, business rules, and data constraints
before persisting changes.

RDS should be private and accept connections only from authorized
backend resources. S3 objects should remain private unless a specific
object is deliberately published. Short-lived presigned URLs may be used
only after server-side authorization.

### 8.3 Suggested API domains

-   `/auth`
-   `/users` and `/profiles`
-   `/companies`
-   `/brokers` and `/broker-relationships`
-   `/documents`
-   `/ipos`
-   `/subscriptions`
-   `/allocations`
-   `/wallets` and `/ledger`
-   `/portfolios` and `/holdings`
-   `/orders`
-   `/order-book`
-   `/trades`
-   `/admin`
-   `/notifications`
-   `/health`

These are conceptual API domains, not a final endpoint contract. Exact
paths, methods, schemas, pagination, and error codes should be defined
in an API specification.

## 9. High-Level Data Model

The final schema is a separate design deliverable. Expected entities
include:

-   User
-   Role/Permission
-   InvestorProfile
-   Company
-   CompanyMembership or Representative
-   BrokerProfile
-   BrokerInvestorRelationship
-   Verification/Application
-   DocumentMetadata
-   IPO
-   IPOReview/Decision
-   Subscription
-   Allocation
-   Security/ShareClass
-   Wallet/Account
-   LedgerEntry
-   Order
-   Trade/Execution
-   Holding/Position
-   Notification
-   AuditEvent
-   IdempotencyRecord

Important design principles: 1. Use stable identifiers and explicit
foreign-key relationships. 2. Store monetary values using exact
decimal/numeric types or integer minor units---not binary
floating-point. 3. Define currency and precision rules explicitly. 4.
Treat financial ledger entries as auditable history; do not silently
overwrite past movements. 5. Define unique constraints and idempotency
behavior for retryable operations. 6. Use database transactions and
appropriate locking/concurrency control for financial operations. 7.
Decide whether holdings are derived from ledger/trade records, stored as
transactionally maintained positions, or reconciled using both. Document
the source of truth. 8. Do not store uploaded file contents directly in
relational tables unless a specific requirement justifies it.

## 10. Key Business Rules Requiring Team Decisions

These decisions must be resolved and recorded before the related feature
is implemented:

1.  **IPO eligibility:** What makes an investor eligible to subscribe?
2.  **Subscription limits:** Are minimum/maximum quantities or amounts
    required?
3.  **Allocation:** Exact pro-rata calculation, rounding, and
    residual-share handling.
4.  **Funds:** How are test funds credited, reserved, released, and
    reconciled?
5.  **Order matching:** Price-time priority details, price protection,
    and tie-breaking.
6.  **Market orders:** Execution limits and behavior when liquidity is
    insufficient.
7.  **Cancellation:** Cutoff and race behavior when matching is in
    progress.
8.  **Trading sessions:** Whether trading is continuous or
    session-based, and how halts work.
9.  **Share precision:** Whether only whole shares are allowed.
10. **Broker authority:** Exact permitted actions and limits for each
    mode.
11. **Notifications:** Which events are delivered in-app and/or by other
    channels.
12. **Localization:** Which screens and messages must be available in
    Amharic at the prototype milestone.
13. **Verification:** Whether verification is manual for the prototype
    or uses a selected provider.
14. **Retention:** Document and audit-record retention periods.
15. **Performance targets:** Expected concurrent users, order volume,
    and response-time goals.
16. **Real-money boundary:** The project remains test-only until all
    applicable reviews and authorizations are complete.

## 11. Testing and Acceptance Strategy

### 11.1 Test layers

-   **Unit tests:** business rules, validators, allocation arithmetic,
    permission checks, matching priority.
-   **Integration tests:** API + database transactions, document
    authorization, subscription workflows, ledger operations.
-   **End-to-end tests:** role-based workflows through the mobile/admin
    clients and API.
-   **Security tests:** unauthorized object access, privilege
    escalation, input validation, token handling, upload controls, rate
    limiting.
-   **Concurrency tests:** simultaneous subscriptions, order placement,
    cancellation/matching races, and duplicate retries.
-   **Recovery tests:** rollback after injected failures, backup
    restoration, and reconciliation checks.
-   **Usability tests:** clear status, confirmations, errors, and mobile
    layouts.

### 11.2 Minimum acceptance scenarios

The wallet must be treated as a core workflow and tested alongside subscriptions and trades:

1.  An unauthenticated user cannot call a protected endpoint.
2.  An investor cannot approve an IPO or access another investor's
    private records.
3.  A company cannot modify another company's IPO.
4.  An unapproved company cannot open an offering.
5.  A subscription cannot be submitted after the subscription window
    closes.
6.  Retrying the same subscription request does not create a duplicate.
7.  An oversubscribed IPO follows the agreed allocation and rounding
    rules.
8.  Available funds cannot be reserved twice by concurrent requests.
9.  An investor cannot sell more shares than are available.
10. Matching compatible orders creates correct executions and consistent
    ledger/holding records.
11. Cancelling a partially filled order preserves executed trades and
    releases only remaining reservations.
12. A broker cannot place an order in advisory mode or exceed
    managed-mode permissions.
13. A private document cannot be downloaded by an unauthorized user.
14. A failed transaction does not leave partial financial state.
15. Administrative decisions and material financial events are
    auditable.
16. A database restore procedure is demonstrated before any
    production-readiness declaration.

## 12. Three-Member Developer Task Classification

AWS deployment ownership belongs to the project owner. The three members
are classified as developers; all three still provide integration and
deployment-readiness support.

### Member 1 --- Mobile Application Lead (`mobile/`)

**Primary ownership** - Flutter app structure, navigation, reusable
widgets, state management, and UI conventions. - Investor workflows:
registration/login UI, profile, IPO discovery/details, subscription
screens, allocation, portfolio, order entry/history. - Company
workflows: profile, document submission UI, IPO
draft/submission/status. - Broker workflows: profile, investor
relationship screens, mode display, permitted actions. - API integration
using the agreed contract; loading/error/empty states. - Client-side
form validation and accessible, responsive layouts. - Mobile unit/widget
tests and end-to-end support.

**Deliverables by phase** - **Phase 1 (Completed & Verified):**
Authentication/profile screens, company onboarding, IPO browsing,
subscription flow, integration with backend APIs. - **Phase 2 (Completed & Verified):**
Wallet activity, simulated test-fund provisioning (`POST /dev/test-funds`),
allocation/portfolio screens, order entry and history, real-world Android
device connectivity over ADB reverse proxy. - **Phase 3 (Active / In Progress):**
UI hardening, localization agreed for release, usability/accessibility
fixes, end-to-end regression testing and release build preparation.

**Boundaries** - Must not implement authoritative financial calculations
or permissions only in the client. - Must not store database credentials
or long-lived secrets in the app. - Must coordinate API models and error
handling with Member 2.

### Member 2 --- Backend and Database Lead (`backend/`)

**Primary ownership** - Node.js + TypeScript application structure and
REST API. - PostgreSQL schema/migrations, constraints, indexes, and
data-access layer. - Authentication, authorization middleware,
role/resource permissions. - Company/broker onboarding, IPO workflow,
subscription and allocation logic. - Prototype ledger and wallet
reservation logic. - Order lifecycle, matching engine, trade execution,
and portfolio consistency. - Document authorization and S3 integration
interface. - WebSocket authorization/events and optional AI service
integration when scheduled. - Backend unit/integration/concurrency
tests, API documentation, and structured logs.

**Deliverables by phase** - **Phase 1 (Completed & Verified):**
API foundation, authentication/authorization, migrations, onboarding,
IPO state machine, subscription workflow, audit events. - **Phase 2 (Completed & Verified):**
Ledger-backed wallet, atomic subscription fund reservation, IPO closure
(`/admin/ipos/:id/close`), atomic share allocation and unallocated fund
refund (`/admin/ipos/:id/allocate`), dev test fund endpoint, and concurrency
protections. - **Phase 3 (Active / In Progress):**
Security hardening, rate limiting, performance/reliability optimization,
AI integration if approved, observability, structured logs, and Docker/AWS
deployment handoff.

**Boundaries** - Owns backend enforcement of all business and security
rules. - Must document transactions, idempotency, and failure
behavior. - Must provide stable API contracts early so Members 1 and 3
can work in parallel.

### Member 3 --- Admin Dashboard and Quality/Integration Lead (`admin/`)

**Primary ownership** - Flutter Web admin dashboard, navigation, forms,
tables, status views, and role-appropriate access states. -
Company/broker application review and IPO approval/rejection
workflows. - Administrative monitoring, user/account status actions, and
audit-event views. - Integration against the shared backend API
contract. - Cross-application test planning, end-to-end scenarios,
integration issue tracking, and release checklists. - Developer-facing
documentation for setup, test execution, API usage, and known
limitations. - Coordinate with the project owner by providing health
checks, environment-variable documentation, logs, and deployable build
instructions.

**Deliverables by phase** - **Phase 1 (Completed & Verified):**
Admin dashboard foundation, company/IPO review screens, approval
decisions, basic audit views, workflow test cases. - **Phase 2 (Completed & Verified):**
IPO subscription and allocation oversight, one-click IPO close and allocation
execution with transaction feedback, safe payload envelope unwrap for
applications, integration with live PostgreSQL backend. - **Phase 3 (Active / In Progress):**
Complete administrative monitoring, end-to-end regression suite,
accessibility and usability polish, release-readiness checklist and
operational handoff.

**Boundaries** - Does not independently invent or bypass backend
permissions. - Does not own AWS infrastructure deployment; the project
owner does. - Coordinates with Member 2 on audit data and API contracts,
and with Member 1 on shared UI conventions where useful.

### 12.1 Shared responsibilities

All three members must: - Review pull requests and follow the agreed Git
workflow. - Write tests for their own code. - Review security
implications of their changes. - Update documentation when behavior or
APIs change. - Participate in integration testing and bug triage. -
Avoid committing secrets, real identity documents, or real financial
data. - Raise unclear business rules before implementing assumptions.

### 12.2 Workload balance and dependency management

Member 2 has the highest technical risk due to the backend, financial
ledger, and matching engine. Reduce overload by: - Agreeing API
contracts and data models before UI implementation. - Letting Member 1
and Member 3 build against mocked API responses while backend endpoints
are in progress. - Having Member 3 lead test planning and integration
coordination without being the sole tester. - Deferring the AI assistant
until core workflows and tests are stable. - Splitting backend work into
small, reviewable modules/issues rather than assigning the entire
backend as one task.

### 12.3 Definition of Done for a task

A task is complete only when: 1. Acceptance criteria are met. 2.
Relevant tests pass. 3. Authorization and validation are enforced where
required. 4. Errors and edge cases are handled. 5.
API/schema/documentation changes are recorded. 6. A pull request has
been reviewed and merged according to team rules. 7. No secrets or
sensitive test data are committed.

## 13. Repository and Documentation Plan

Keep the current top-level repository structure:

``` text
Dirsha/
├── README.md
├── docs/
├── backend/
├── mobile/
└── admin/
```

Recommended documentation files under `docs/`:

``` text
docs/
├── SRS.md
├── TEAM_TASK_CLASSIFICATION.md
├── SYSTEM_ARCHITECTURE.md
├── DATABASE_DESIGN.md
├── API_SPECIFICATION.md
├── BUSINESS_RULES.md
├── TEST_PLAN.md
├── SECURITY_AND_PRIVACY.md
├── AWS_DEPLOYMENT_NOTES.md
└── decisions/
    └── ADR-0001-initial-architecture.md
```

This is a proposed documentation layout, not a demand to create every
file immediately. Start with `SRS.md`, `TEAM_TASK_CLASSIFICATION.md`,
and `BUSINESS_RULES.md`; add the others as the relevant decisions are
made.

### Documentation format recommendation

-   **Keep Markdown (`.md`) as the canonical source in GitHub.** It is
    easy to review, diff, search, and update alongside code.
-   **Optionally publish a PDF snapshot** for meetings, submission, or
    offline reading.
-   Avoid manually maintaining separate Markdown and PDF copies.
    Generate the PDF from the reviewed Markdown when a stable version is
    needed.
-   Keep secrets, real customer information, and private verification
    documents out of the repository.

## 14. Risks and Mitigations

  -----------------------------------------------------------------------
  Risk                                Mitigation
  ----------------------------------- -----------------------------------
  Financial rules are unclear         Agree and document business rules
                                      before implementation.

  Frontend and backend drift apart    Publish API contracts and shared
                                      examples early.

  Backend workload overload           Use milestones, small issues,
                                      mocked APIs, and peer review.

  Concurrent operations corrupt state Use database transactions,
                                      constraints, locking/concurrency
                                      controls, idempotency, and tests.

  Unauthorized access to private      Enforce resource-level
  records                             authorization and test negative
                                      cases.

  Sensitive documents become public   Private S3 buckets, least
                                      privilege, short-lived links, and
                                      access auditing.

  AWS costs grow unexpectedly         Start small, estimate costs, set
                                      budgets/alerts, and remove unused
                                      resources.

  AI produces inaccurate or unsafe    Defer until core workflows are
  output                              stable; ground responses in
                                      authorized sources and disclose
                                      limitations.

  Prototype mistaken for a live       Label test funds/securities clearly
  financial service                   and block real-money use pending
                                      external reviews.

  Requirements change without         Update this SRS, link changes to
  traceability                        issues, and record architectural
                                      decisions.
  -----------------------------------------------------------------------

## 15. Open Decisions and Sign-Off

Before implementation of the relevant features, the team should agree
on:

-   Authentication library and refresh-token strategy.
-   Flutter state-management approach.
-   Backend framework and validation/schema library.
-   Exact IPO state transitions.
-   Allocation and rounding algorithm.
-   Ledger and balance representation.
-   Order matching, cancellation, and market-order rules.
-   Document upload and malware-check workflow.
-   Initial performance/concurrency targets.
-   Localization scope.
-   Test-fund initialization for the prototype.
-   Acceptance criteria for each GitHub issue.

### Review checklist (Phases 1 & 2 Signed Off — Phase 3 Kicked Off)

-   [x] All three developers agree on the phase boundaries.
-   [x] Each task has one accountable owner and clear acceptance
    criteria.
-   [x] API contract and database ownership are clear.
-   [x] Allocation, ledger, and matching rules are documented and implemented.
-   [x] Security and testing work begins in Phase 1 and continues in Phase 2 & 3.
-   [x] The project owner owns AWS deployment; developers provide
    integration support.
-   [x] Test funds and test securities are clearly separated from any
    real-money service.
-   [x] The SRS is reviewed and versioned in the GitHub repository (v1.1 baseline).

------------------------------------------------------------------------

**End of document --- Dirsha SRS and Team Development Plan, version
1.1.**
