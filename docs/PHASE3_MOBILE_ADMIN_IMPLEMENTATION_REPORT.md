# Phase 3 Implementation Report: Mobile (Member 1) & Admin (Member 3)

**Branch:** `feature/phase3-mobile-admin` (based on Member 2 backend commit `318c851`)  
**Date:** October 2026  
**Status:** Complete & Fully Verified  

---

## 1. Executive Summary

This deliverable concludes the implementation and end-to-end integration of Phase 3 responsibilities for:
- **Member 1 (Investor Mobile Application — Flutter):** Portfolio & Holdings views (`FR-PORT-01..04`), Allocation Results detail views (`FR-ALC-01..02`, `FR-SUB-04`), subscription order-entry hardening (idempotency key generation, double-tap prevention, reservation explanation), and full dashboard navigation.
- **Member 3 (Admin Web Dashboard — Flutter Web):** Subscription Management & Audit (`FR-SUB-05`), Allocation Oversight & Subscriber Breakdown on IPO details (`FR-ALC-01..03`), Audit Log integration (`FR-ADM-02..03`), and preservation of Phase 2 review workflows.
- **Backend Enablers (Express + TypeScript + PostgreSQL):** Implementation of missing `GET /portfolio` endpoint and enrichment of `GET /subscriptions` with joined company names, ticker symbols, offering titles, unit share prices, and investor profile details.

All implementations strictly adhere to:
- SRS v1.1 requirements
- `BUSINESS_RULES.md` (e.g., Integer santim minor currency units, ETB invariant, append-only financial ledger, `FOR UPDATE` concurrency locks)
- `API_SPECIFICATION.md`

---

## 2. Requirements Traceability Matrix

| Requirement Code | Description | Implementation Component | Verification / Test |
| :--- | :--- | :--- | :--- |
| **FR-PORT-01** | Portfolio holdings list showing allocated shares per IPO | `mobile/lib/features/portfolio/screens/portfolio_screen.dart`<br>`mobile/lib/features/portfolio/widgets/holding_card.dart` | `mobile/test/features/portfolio/portfolio_test.dart` |
| **FR-PORT-02** | Unallocated pending subscriptions excluded from shareholdings | `backend/src/modules/portfolio/portfolio.service.ts`<br>`mobile/lib/features/portfolio/providers/portfolio_provider.dart` | `backend/tests/portfolio.test.ts` (test: *does not include pending reservations*) |
| **FR-PORT-03** | Portfolio valuation calculation based on offering price | `backend/src/modules/portfolio/portfolio.service.ts`<br>`mobile/lib/features/portfolio/widgets/portfolio_summary_card.dart` | `backend/tests/portfolio.test.ts`<br>`mobile/test/features/portfolio/portfolio_test.dart` |
| **FR-PORT-04** | Portfolio empty state & refresh | `mobile/lib/shared/widgets/empty_state.dart`<br>`mobile/lib/features/portfolio/screens/portfolio_screen.dart` | `backend/tests/portfolio.test.ts` (empty portfolio)<br>`mobile/test/features/portfolio/portfolio_test.dart` |
| **FR-SUB-01** | Subscription order entry with idempotency key | `mobile/lib/features/subscriptions/widgets/subscription_bottom_sheet.dart` | `mobile/test/features/subscriptions/subscription_provider_test.dart` |
| **FR-SUB-02** | Escrow balance deduction & reservation lock | `backend/src/modules/subscriptions/subscriptions.service.ts` | `backend/tests/phase3-concurrency.test.ts`<br>`backend/tests/subscriptions.test.ts` |
| **FR-SUB-04** | Allocation results view & refund transparency | `mobile/lib/features/subscriptions/screens/subscription_detail_screen.dart`<br>`mobile/lib/features/subscriptions/screens/my_subscriptions_screen.dart` | `mobile/test/features/subscriptions/subscription_provider_test.dart` |
| **FR-SUB-05** | Admin subscription oversight list & filter | `admin/lib/features/subscriptions/screens/subscriptions_list_screen.dart`<br>`admin/lib/features/subscriptions/providers/subscriptions_provider.dart` | `admin/test/subscriptions_test.dart` |
| **FR-ALC-01** | Admin close IPO subscription window | `admin/lib/features/ipos/screens/ipo_detail_screen.dart` (`POST /admin/ipos/:id/close`) | `backend/tests/ipos.test.ts`<br>`backend/tests/e2e-phase2-checkpoint.test.ts` |
| **FR-ALC-02** | Share allocation execution & ledger settlement | `backend/src/modules/ipos/ipos.service.ts`<br>`admin/lib/features/ipos/screens/ipo_detail_screen.dart` | `backend/tests/phase3-concurrency.test.ts`<br>`backend/tests/admin.test.ts` |
| **FR-ALC-03** | Allocation breakdown & oversubscription metrics | `admin/lib/features/ipos/screens/ipo_detail_screen.dart` (`_IpoSubscriptionsBreakdown`) | `admin/test/subscriptions_test.dart` |
| **FR-ADM-02..03**| Immutable Audit Log viewer | `admin/lib/features/audit/screens/audit_screen.dart` | `admin/test/widget_test.dart` |

---

## 3. API Gap & Resolution Matrix

| Endpoint | Prior Status | Resolution / Implementation | Documented Spec |
| :--- | :--- | :--- | :--- |
| `GET /portfolio` | Missing (404) | Implemented in `backend/src/modules/portfolio/`. Computes allocated positions grouped by `ipo_id`, calculates valuation via integer santim arithmetic, and enforces investor role authorization. | `docs/API_SPECIFICATION.md` §3.5 |
| `GET /subscriptions` | Basic fields only | Enriched query in `backend/src/modules/subscriptions/subscriptions.service.ts` with joins to `ipos` and `companies` (`ipo_title`, `ipo_symbol`, `company_name`, `price_per_share_minor`) and `users` (`investor_name`, `investor_email` for admin). | `docs/API_SPECIFICATION.md` §3.3 |
| `GET /subscriptions/:id` | Basic fields only | Returns enriched DTO with offering and allocation breakdown data. | `docs/API_SPECIFICATION.md` §3.4 |

---

## 4. Key Implementation Details

### 4.1 Mobile Application (`mobile/`)
1. **Portfolio Feature:**
   - Model: [HoldingModel](file:///home/salah/Dirsha/mobile/lib/features/portfolio/models/portfolio_models.dart), [PortfolioSummaryModel](file:///home/salah/Dirsha/mobile/lib/features/portfolio/models/portfolio_models.dart).
   - Repositories: [PortfolioRepository](file:///home/salah/Dirsha/mobile/lib/features/portfolio/repositories/portfolio_repository.dart), [LivePortfolioRepository](file:///home/salah/Dirsha/mobile/lib/features/portfolio/repositories/live_portfolio_repository.dart), and [MockPortfolioRepository](file:///home/salah/Dirsha/mobile/lib/features/portfolio/repositories/mock_portfolio_repository.dart).
   - Screen: [PortfolioScreen](file:///home/salah/Dirsha/mobile/lib/features/portfolio/screens/portfolio_screen.dart) displaying summary card, valuation source transparency (*Offering Price* per FR-PORT-03), simulated funds banner, holdings list with share counts, and empty state linking to subscriptions.
   - Provider: [PortfolioProvider](file:///home/salah/Dirsha/mobile/lib/features/portfolio/providers/portfolio_provider.dart) with `load()` and `refresh()`.
2. **Subscriptions & Allocation Results:**
   - Screen: [MySubscriptionsScreen](file:///home/salah/Dirsha/mobile/lib/features/subscriptions/screens/my_subscriptions_screen.dart) with filter chips (*All, Reserved, Settled, Refunded*) and pull-to-refresh.
   - Screen: [SubscriptionDetailScreen](file:///home/salah/Dirsha/mobile/lib/features/subscriptions/screens/subscription_detail_screen.dart) showing allocation outcome banners (*Fully Allocated, Partially Allocated, Zero Allocation*), share breakdown cards (requested vs. allocated), refund amounts, and reservation ledger details.
   - Order-entry hardening: [SubscriptionBottomSheet](file:///home/salah/Dirsha/mobile/lib/features/subscriptions/widgets/subscription_bottom_sheet.dart) generates unique idempotency keys per submission attempt and disables submit button during in-flight requests.
3. **App Navigation:**
   - [HomeScreen](file:///home/salah/Dirsha/mobile/lib/features/home/screens/home_screen.dart) updated to 4 tabs: *Explore IPOs*, *My Portfolio*, *Wallet*, *Subscriptions*.
   - Added dashboard quick-action navigation cards.
   - [AppRouter](file:///home/salah/Dirsha/mobile/lib/router/app_router.dart) updated with `/subscriptions` and `/subscriptions/:id`.

### 4.2 Admin Web Dashboard (`admin/`)
1. **Subscription Management:**
   - Model: [AdminSubscription](file:///home/salah/Dirsha/admin/lib/features/subscriptions/models/subscription_model.dart).
   - Repositories: [SubscriptionsRepository](file:///home/salah/Dirsha/admin/lib/features/subscriptions/repositories/subscription_repository.dart), [ApiSubscriptionsRepository](file:///home/salah/Dirsha/admin/lib/features/subscriptions/repositories/api_subscription_repository.dart), and [MockSubscriptionsRepository](file:///home/salah/Dirsha/admin/lib/features/subscriptions/repositories/mock_subscription_repository.dart).
   - Screen: [SubscriptionsListScreen](file:///home/salah/Dirsha/admin/lib/features/subscriptions/screens/subscriptions_list_screen.dart) featuring:
     - Top KPI cards: Total Subscriptions, Requested Shares, Allocated Shares, Committed Volume in ETB.
     - Live search filter (by offering, symbol, investor name, email, or ID) and status dropdown.
     - Data table with responsive horizontal scrolling and proper row heights.
     - Detailed inspection dialog displaying full audit metadata, idempotency key, timestamps, and escrow settlement status.
   - Provider: [SubscriptionsProvider](file:///home/salah/Dirsha/admin/lib/features/subscriptions/providers/subscriptions_provider.dart).
2. **Allocation & Subscription Oversight on IPO Details:**
   - [IpoDetailScreen](file:///home/salah/Dirsha/admin/lib/features/ipos/screens/ipo_detail_screen.dart) enhanced with `_IpoSubscriptionsBreakdown`:
     - Displays subscriber count, total requested shares, oversubscription ratio (%), and allocated shares.
     - Table of all subscribers with requested vs. allocated shares, status badges, and refund amounts.
     - Integrates with existing "Close IPO" and "Allocate Shares" lifecycle action buttons.
3. **Routing & Shell:**
   - Added `/subscriptions` route to [AppRoutes](file:///home/salah/Dirsha/admin/lib/core/routing/app_routes.dart) and [createRouter](file:///home/salah/Dirsha/admin/lib/core/routing/app_router.dart).
   - Added Subscriptions item to [AppShell](file:///home/salah/Dirsha/admin/lib/core/widgets/app_shell.dart) sidebar navigation.

### 4.3 Backend Enablers (`backend/`)
1. **Portfolio Service & Routes:**
   - Created [portfolio.service.ts](file:///home/salah/Dirsha/backend/src/modules/portfolio/portfolio.service.ts) and [portfolio.routes.ts](file:///home/salah/Dirsha/backend/src/modules/portfolio/portfolio.routes.ts).
   - Mounted in [app.ts](file:///home/salah/Dirsha/backend/src/app.ts) at `GET /portfolio`.
   - Groups settled allocations by IPO, joins `ipos` and `companies` (`legal_name`, `trade_name`), and calculates total portfolio valuation in minor units (santim).
2. **Subscription Enrichment:**
   - Updated [subscriptions.service.ts](file:///home/salah/Dirsha/backend/src/modules/subscriptions/subscriptions.service.ts) queries to return `ipo_title`, `ipo_symbol`, `company_name`, `price_per_share_minor`, and investor contact info.

---

## 5. Verification & Test Evidence

### 5.1 Backend Test Suite (Vitest + PostgreSQL)
Command: `TEST_DATABASE_URL=postgres://dirsha:dirsha_local_test@localhost:5432/dirsha_test npm test`
- **Result:** **15 test files passed (15/15), 124 tests passed (124/124)**
- **Key Test Highlights:**
  - `tests/portfolio.test.ts` (6 tests): Passed (unauthenticated 401, non-investor 403, empty portfolio, exclusion of pending reservations, allocated shares reflection after admin allocation, investor isolation).
  - `tests/phase3-concurrency.test.ts` (2 tests): Passed (parallel subscription race condition safety, subscription racing with allocation).
  - `tests/e2e-phase2-checkpoint.test.ts` (1 test): Passed (full lifecycle funding -> reserve -> idempotent retry -> 422 check -> admin close & allocate).
  - `tests/subscriptions.test.ts` (17 tests): Passed.
  - `tests/ipos.test.ts` (11 tests): Passed.
  - `tests/auth.test.ts` (12 tests): Passed.
  - `tests/admin.test.ts` (7 tests): Passed.

### 5.2 Mobile Flutter Test Suite
Command: `/home/salah/programfiles/flutter/bin/flutter test`
- **Result:** **162 tests passed (162/162)**
- **Static Analysis:** `/home/salah/programfiles/flutter/bin/flutter analyze` -> **0 issues found**
- **Test Highlights:**
  - `test/features/portfolio/portfolio_test.dart` (5 tests): Passed (holding valuations, summary calculations, provider loading and refreshing).
  - `test/features/subscriptions/subscription_provider_test.dart` (6 tests): Passed (idempotency, conflict detection, reservation creation, loading and details retrieval).
  - All existing Phase 1 & 2 tests (auth, wallet, IPOs, money, formatters): Passed.

### 5.3 Admin Flutter Web Test Suite
Command: `/home/salah/programfiles/flutter/bin/flutter test`
- **Result:** **22 tests passed (22/22)**
- **Static Analysis:** `/home/salah/programfiles/flutter/bin/flutter analyze` -> **0 issues found**
- **Test Highlights:**
  - `test/subscriptions_test.dart` (7 tests): Passed (model parsing, partial/zero/full allocation helpers, provider KPI metrics & oversubscription ratios, live API repository mocking, and widget test rendering KPI cards and subscription table).
  - `test/widget_test.dart` and `test/api_repositories_test.dart`: Passed (15 tests).

---

## 6. Git Branch Status

- **Working Branch:** `feature/phase3-mobile-admin`
- **Base Commit:** `318c851` (`feature/Singa10-Backend`)
- **Preservation:** All Member 2 backend enhancements, ledger integrity, database migrations, and concurrency controls preserved intact. No merge or push to `main` without authorization.
