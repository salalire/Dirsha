# Dirsha --- End-to-End Functional Gap Assessment

**Document type:** Project issue and scope-planning document\
**Status:** Draft for repository/SRS verification before implementation\
**Purpose:** Record functional gaps observed during hands-on testing and
define what must be audited before the next implementation prompt.

------------------------------------------------------------------------

## 1. Background

Dirsha is intended to be an Ethiopian digital investment platform
connecting investors, companies/issuers, brokers, and administrators. It
already has a Flutter mobile application, Flutter Web admin application,
and backend.

The latest Phase 3 report stated that mobile and admin features were
implemented, backend integrations added, and automated tests/static
analysis passed. Subsequent hands-on testing, however, revealed business
workflows that appear incomplete or inconsistent.

**Important:** The items below are observations and investigation
targets, not all confirmed root causes. Inspect the actual source code,
APIs, database behavior, SRS, business rules, and implementation report
before changing anything. This document does not authorize scope
expansion without checking the approved requirements.

## 2. Main Issues Observed

### 2.1 Company functionality appears limited to registration and verification

**Observed:** Company users can register and be reviewed/verified by an
administrator, but meaningful company-side workflows appear missing or
incomplete.

**Capabilities to verify against the SRS:** - Dedicated company
dashboard and profile. - Viewing/updating permitted company
information. - Creating, saving, and submitting an IPO application. -
Entering offering details, share quantity, price, and opening/closing
dates. - Submitting required offering information and supporting
documents. - Tracking application status and administrator feedback. -
Responding to requests for additional information and resubmitting when
permitted. - Monitoring approved offerings and lifecycle outcomes. -
Viewing demand/allocation information where authorized.

**Expected:** An approved company has a meaningful issuer workflow
beyond registration. Material offering changes follow defined approval
and audit rules.

### 2.2 Broker functionality appears limited to registration and verification

**Observed:** Broker users can register and be approved, but core
brokerage workflows appear absent or incomplete.

**Capabilities to verify:** - Dedicated broker dashboard and profile. -
Investor--broker relationship requests, acceptance/rejection, status,
and revocation. - Explicit investor authorization and permission
controls. - List of clients with active, authorized relationships. -
Access to permitted client portfolios, holdings, balances, orders, and
transaction information. - Broker-assisted order placement and order
management, if required by the SRS. - Distinction between actions
initiated by the investor and actions performed by a broker on the
investor's behalf. - Audit records for relationship changes and
broker-initiated actions.

**Expected:** Registration and admin approval establish identity/status;
they do not provide brokerage functionality. A broker must not gain
account access merely because they are registered or approved.

### 2.3 Approved IPOs do not appear consistently for investors and brokers

**Observed:** An IPO approved by an administrator does not appear in
investor and broker applications as expected. An administrator closing
an IPO does appear to update the investor side immediately; preserve
this working behavior.

**Expected behavior to verify:** - Approved offerings become
discoverable according to publication rules. - Approved offerings with
future opening times can appear as **Upcoming**, if allowed by the
SRS. - Offerings within the subscription window appear as **Open**. -
Closed, allocated, and listed offerings remain available in appropriate
active or historical views. - Investor and broker views use consistent
backend lifecycle data and authorization rules. - Client screens refresh
or invalidate stale data after approval, closure, allocation, or
listing.

**Possible causes to investigate (not confirmed):** API filters exclude
approved IPOs; clients use different endpoints/filters; approval updates
a different status field; cached data is stale; or approval,
publication, and subscription status are incorrectly treated as one
state.

**Expected:** The backend is authoritative for IPO state, and each
client displays offerings according to the same lifecycle rules and the
user's permissions.

### 2.4 IPO displayed status conflicts with subscription eligibility

**Observed:** Some IPOs appear **Open**, but subscription attempts are
rejected with a "not open" message. The user suspects date handling, but
the root cause is unconfirmed.

**Rules to verify:** - Backend subscription eligibility is
authoritative. - Approval/publication requirements are satisfied. -
Opening time has been reached and closing deadline has not passed. -
Administrator closure or suspension is respected. - Investor eligibility
rules are enforced. - IPO list, detail view, and subscription endpoint
agree on lifecycle state. - Time zones are handled consistently,
including Ethiopia local time and UTC conversions. - Boundary cases are
tested before, at, and after opening/closing times.

**Expected closing behavior:** - After the closing deadline, the backend
rejects new subscriptions even if a scheduled status update has not
run. - A background process may synchronize stored status to **Closed**,
but it must not be the only protection against late subscriptions. -
Administrative closure remains effective immediately. - Existing
subscription/allocation concurrency safeguards remain intact. - Error
responses accurately explain the reason for rejection.

### 2.5 Investor profile/account experience is incomplete

**Observed:** The investor home screen mainly shows a greeting such as
"Hello, \[first name\]" rather than a professional profile/account
experience.

**Capabilities to verify and implement if required:** - Dedicated
investor profile screen. - Authenticated account information: name,
email, phone (if collected), role, and verification status. - Editing
permitted fields with validation and authorization. - Re-verification
rules for sensitive or verified identity fields. - Account settings and
working sign-out. - Password/security controls only when actually
supported by the backend. - Coherent access to portfolio, wallet,
subscriptions, allocation results, transaction history, and broker
relationships. - Loading, empty, validation, and error states.

**Expected:** The profile uses real authenticated-user data and working
actions. Decorative controls or unsupported security features must not
be presented as functional.

### 2.6 Secondary-market share trading is unavailable

**Observed:** The platform supports parts of the primary-market IPO
subscription/allocation flow, but users cannot perform meaningful
secondary-market trading. Investor and broker trading are desired,
subject to SRS/scope confirmation.

**Scope distinction:** The first version can be a simulated market using
simulated ETB balances and holdings. This does not require real-money
payments, real stock-exchange connectivity, or claims of live market
prices.

**Investor-side capabilities to assess:** - Browse securities eligible
for trading. - View clearly sourced or labeled indicative/last-traded
information. - Submit buy and sell orders. - Review and confirm
orders. - View open, partially filled, completed, cancelled, and
rejected orders as supported. - Cancel eligible open orders. - Review
trade history. - See holdings and simulated balances update after
settlement.

**Broker-side capabilities to assess:** - Select only investors with
active, authorized brokerage relationships. - View client
holdings/balances within granted permissions. - Submit/manage orders for
authorized clients if permitted by the SRS. - Track order status and
trade history. - Identify whether an investor or broker initiated each
action. - Enforce authorization on every backend operation, not just by
hiding UI controls.

**Backend trading capabilities to assess:** - Security/listing
eligibility. - Order creation, validation, retrieval, and
cancellation. - Buy-side funds reservation and sell-side share
reservation. - Order book and documented matching rules. - Matching and
partial fills if supported by the chosen design. - Transactional
execution and settlement. - Portfolio/wallet integration. - Ledger and
audit records. - Idempotency and concurrency protection. - Prevention of
overspending, overselling, duplicate execution, and negative balances. -
Explicit rules for pricing, order types, trading status, and any
included fees or market hours.

**Expected:** Buy/sell operations cause real, consistent backend state
changes in the simulation. UI-only balance changes or hardcoded
successful responses are not acceptable.

**Scope boundary:** Do not add real-money rails, bank
deposits/withdrawals, real-exchange integration, or an invented
live-price feed unless separately approved and supported by project
requirements.

## 3. Cross-Platform Integration

Dirsha must behave as one connected platform rather than a collection of
screens.

A typical lifecycle to validate against the SRS:

1.  A company submits an IPO application.
2.  The administrator reviews and approves/rejects it, recording
    relevant feedback.
3.  An approved offering becomes visible according to publication rules.
4.  It is shown as **Upcoming** or **Open** according to the approved
    schedule.
5.  Eligible investors subscribe while it is open.
6.  The backend reserves simulated funds and records subscription/ledger
    activity.
7.  After closure, an authorized administrator runs allocation according
    to business rules.
8.  Allocated amounts settle and unallocated reservations are released
    correctly.
9.  Investor holdings and subscription/allocation history reflect the
    outcome.
10. Once eligible and listed under project rules, shares become
    available in the simulated secondary market.
11. Completed trades update holdings, simulated balances, transaction
    history, and audit records.
12. Authorized brokers can assist clients only within explicit
    permissions.

This is intended behavior to validate, not a claim that every step
currently exists.

## 4. Shared Backend, Security, and Integrity Requirements

-   Backend authority for roles, permissions, lifecycle transitions,
    balances, reservations, allocations, holdings, and trades.
-   Preserve existing subscription concurrency fixes, idempotency,
    wallet/ledger rules, and audit mechanisms.
-   Follow existing API conventions and document response/error formats.
-   Use the established migration system for necessary database changes.
-   Protect company documents and investor data with role- and
    relationship-based authorization.
-   Limit brokers to explicit client permissions.
-   Limit company representatives to their own company's permitted
    records.
-   Make financial changes transactional and auditable.
-   Do not treat mock data as completion of required real API
    integration.
-   Update API documentation, automated tests, and implementation
    reports.
-   Do not introduce real-money functionality by implication.

## 5. Audit and Verification Plan

### Sources to inspect

-   Current SRS and team/phase plan.
-   API specification and business rules.
-   Latest Phase 3 mobile/admin implementation report.
-   Actual backend routes, services, models, migrations, and tests.
-   Actual mobile/admin screens, state management, repositories, and API
    clients.
-   Current Git branch, working tree, branch ancestry, and relevant
    commits.

Use the current repository state; do not assume earlier branch
descriptions or reports remain accurate.

### Requirement status categories

-   **COMPLETE:** Implemented, integrated, and verified with evidence.
-   **PARTIAL:** Some of the workflow exists, but part is missing or
    disconnected.
-   **MISSING:** Required functionality does not exist.
-   **BROKEN:** Functionality exists but behaves incorrectly.
-   **BLOCKED:** Requires an unavailable dependency or decision.
-   **FUTURE PHASE / OUT OF SCOPE:** Not approved for the current scope.

For every requirement, record its source, relevant code/API, gap,
proposed action, and verification evidence.

### End-to-end workflows to verify

-   Company application → admin review → approved IPO visibility.
-   IPO schedule → accurate Upcoming/Open/Closed state → consistent
    subscription eligibility.
-   Investor profile → authenticated data and supported account actions.
-   Investor subscription → reservation → admin allocation →
    settlement/refund → portfolio update.
-   Broker relationship request → explicit authorization → permitted
    client access.
-   Eligible listed holding → buy/sell order → matching/execution →
    settlement → updated holdings/balances.
-   Audit records for consequential admin, brokerage, and financial
    actions.

Run these where in scope and supported by the environment. Record actual
commands/results and limitations. Static analysis or isolated unit tests
alone do not prove end-to-end completion.

## 6. Proposed Workstream Priorities

This is a proposed sequence, not a replacement for the SRS. Reorder it
after dependency inspection.

  --------------------------------------------------------------------------
  Priority                Workstream                 Goal
  ----------------------- -------------------------- -----------------------
  P0                      Audit and existing defects Diagnose IPO
                                                     visibility, date/status
                                                     conflicts, API gaps,
                                                     and broken workflows.

  P1                      Company functionality      Complete required
                                                     issuer profile, IPO
                                                     application, document,
                                                     and lifecycle
                                                     workflows.

  P2                      IPO lifecycle and          Align approval,
                          visibility                 publication, opening,
                                                     closing, allocation,
                                                     and listing across
                                                     roles.

  P3                      Investor profile/account   Complete profile
                                                     experience and verify
                                                     portfolio, wallet, and
                                                     subscription
                                                     integration.

  P4                      Broker functionality       Implement required
                                                     relationships,
                                                     permissions, client
                                                     management, and
                                                     brokerage workflows.

  P5                      Secondary-market backend   Implement approved
                                                     simulated order,
                                                     reservation, matching,
                                                     execution, settlement,
                                                     and audit capabilities.

  P6                      Trading interfaces         Integrate investor and
                                                     broker trading
                                                     workflows with the real
                                                     backend.

  P7                      Full                       Test approved workflows
                          integration/verification   and update
                                                     documentation.
  --------------------------------------------------------------------------

Trading UI should not be marked complete before the required backend
behavior and business rules are defined.

## 7. Definition of Done

A feature is complete only when: 1. Its scope is supported by the SRS or
explicitly approved plan. 2. Required backend logic and APIs exist. 3.
Authorized roles can use it and unauthorized roles are rejected. 4.
Database transitions and financial invariants remain correct. 5.
Mobile/admin interfaces use the real API. 6. Loading, empty, validation,
and error states are handled. 7. Relevant automated tests pass. 8.
End-to-end behavior is verified where feasible, with limitations stated.
9. Documentation and the requirements matrix are updated. 10. Remaining
limitations and deferred requirements are recorded.

## 8. Git and Implementation Safety

-   Inspect the current branch and working tree before edits.
-   Preserve existing and uncommitted work.
-   Do not use destructive Git operations.
-   Do not overwrite another member's changes or blindly merge branches.
-   Work on an appropriate feature branch.
-   Do not push, merge into `main`, or deploy without explicit
    authorization.
-   Reuse existing functionality; avoid duplicate endpoints and
    competing implementations.
-   Implement missing in-scope capabilities. If a change requires a new
    business decision or expands scope, document it and request approval
    instead of inventing rules.

## 9. Expected Deliverables

**Before implementation:** - Requirements-completeness matrix. -
Existing defect/root-cause findings. - API gap matrix. - Company,
broker, investor, admin, and trading workflow maps. - Dependency/risk
list. - Proposed implementation sequence. - Questions requiring a
business decision.

**After implementation:** - Working, integrated functionality within
approved scope. - Necessary backend endpoints, services, and
migrations. - Updated API and business-rule documentation. - Automated
test results and actual end-to-end evidence. - Updated report showing
complete, partial, broken, blocked, and deferred requirements. - List of
changed files and remaining limitations.

## 10. Final Objective

Move Dirsha beyond partially connected registration, IPO, wallet, and
admin features toward a coherent investment-platform workflow for
investors, companies, brokers, and administrators.

The next step is **not to code from assumptions**. Audit the current
repository and approved SRS, distinguish existing defects from genuinely
missing functionality, confirm business rules, and identify scope
decisions. Then implement and verify approved work end to end while
preserving financial integrity, security, and Git safety.
