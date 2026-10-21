# Dirsha Admin — Phase 1 Manual QA Checklist

**Phase:** 1 — Foundation and Primary Market  
**App:** Flutter Web Admin Dashboard  
**Member:** Member 3  
**Date prepared:** 2026-10-21  
**Status:** Ready for Phase 2 integration testing

> Each item should be tested manually and marked Pass / Fail.
> Add evidence (screenshot, URL, console log) and a defect owner where applicable.

---

## 1. Application Start

| # | Check | Pass/Fail | Notes / Evidence | Defect Owner |
|---|-------|-----------|-----------------|--------------|
| 1.1 | Admin app starts with `flutter run -d chrome` without crash | | | |
| 1.2 | No critical red errors in browser console on startup | | | |
| 1.3 | Page title shows "Dirsha Admin" in browser tab | | | |
| 1.4 | DEVELOPMENT MODE / DEMO DATA banners are visible | | | |

---

## 2. Sign-In Page

| # | Check | Pass/Fail | Notes / Evidence | Defect Owner |
|---|-------|-----------|-----------------|--------------|
| 2.1 | Sign-in page renders with email and password fields | | | |
| 2.2 | Submitting empty email shows "Email is required" | | | |
| 2.3 | Submitting empty password shows "Password is required" | | | |
| 2.4 | Invalid email format shows "Enter a valid email address" | | | |
| 2.5 | Password show/hide toggle works | | | |
| 2.6 | Wrong credentials shows error message (not a crash) | | | |
| 2.7 | Sign-in button shows loading spinner while in flight | | | |
| 2.8 | Demo mode note is visible with demo credentials | | | |
| 2.9 | Correct credentials (admin@dirsha.dev / demo1234) navigate to Dashboard | | | |
| 2.10 | No real password or credential is hardcoded as a production credential | | | |

---

## 3. Navigation

| # | Check | Pass/Fail | Notes / Evidence | Defect Owner |
|---|-------|-----------|-----------------|--------------|
| 3.1 | Sidebar is visible on desktop width (>900px) | | | |
| 3.2 | Sidebar collapses to icons on narrow width | | | |
| 3.3 | Drawer opens on narrow width | | | |
| 3.4 | Active page is highlighted in sidebar | | | |
| 3.5 | All 5 nav items navigate without error: Dashboard, User Reviews, Company Reviews, IPO Management, Audit | | | |
| 3.6 | Browser back/forward navigation works | | | |
| 3.7 | Visiting a protected route while unauthenticated redirects to sign-in | | | |
| 3.8 | Sign-out from account menu returns to sign-in page | | | |

---

## 4. Dashboard Overview

| # | Check | Pass/Fail | Notes / Evidence | Defect Owner |
|---|-------|-----------|-----------------|--------------|
| 4.1 | Dashboard renders metric cards | | | |
| 4.2 | Metric cards show counts from mock data | | | |
| 4.3 | Mock data banner is visible | | | |
| 4.4 | Quick action buttons navigate to correct pages | | | |
| 4.5 | Recent IPO list renders and is clickable | | | |
| 4.6 | No real financial figures or live data is implied | | | |

---

## 5. User Reviews

| # | Check | Pass/Fail | Notes / Evidence | Defect Owner |
|---|-------|-----------|-----------------|--------------|
| 5.1 | User list loads and shows mock records | | | |
| 5.2 | Loading state shows spinner | | | |
| 5.3 | Search filters the list by name / email | | | |
| 5.4 | Status filter works | | | |
| 5.5 | Status badges render with correct colors | | | |
| 5.6 | "Review" button navigates to user detail | | | |
| 5.7 | User detail shows applicant information | | | |
| 5.8 | Approve/Reject buttons only show for Pending / Under Review records | | | |
| 5.9 | Approve opens confirmation dialog | | | |
| 5.10 | Reject opens confirmation dialog with required reason field | | | |
| 5.11 | Reject without reason shows validation error, does not submit | | | |
| 5.12 | Approve/Reject shows loading state while in flight | | | |
| 5.13 | Success message appears after approve/reject | | | |
| 5.14 | Approved/Rejected record updates status correctly | | | |
| 5.15 | Already-approved record has no approve/reject buttons | | | |
| 5.16 | Mock data banner is visible | | | |

---

## 6. Company Reviews

| # | Check | Pass/Fail | Notes / Evidence | Defect Owner |
|---|-------|-----------|-----------------|--------------|
| 6.1 | Company list loads and shows mock records | | | |
| 6.2 | Search and filter work | | | |
| 6.3 | Company detail shows company and representative info | | | |
| 6.4 | Document list shows metadata (name, type, status) | | | |
| 6.5 | Document lock icon is visible (no actual download available in Phase 1) | | | |
| 6.6 | Approve/Reject actions work with confirmation (same as users) | | | |
| 6.7 | Mock data banner is visible | | | |

---

## 7. IPO Management

| # | Check | Pass/Fail | Notes / Evidence | Defect Owner |
|---|-------|-----------|-----------------|--------------|
| 7.1 | IPO list loads and shows mock records | | | |
| 7.2 | Search by title / company works | | | |
| 7.3 | Status filter works | | | |
| 7.4 | Refresh button reloads the list | | | |
| 7.5 | IPO detail page shows offering info and terms | | | |
| 7.6 | Document metadata is listed (no download in Phase 1) | | | |
| 7.7 | Approve IPO opens confirmation dialog | | | |
| 7.8 | Reject IPO opens confirmation dialog with required reason | | | |
| 7.9 | Reject without reason is blocked by validation | | | |
| 7.10 | Loading state shown while review action is in flight | | | |
| 7.11 | Cannot submit twice (button disabled while pending) | | | |
| 7.12 | Success feedback shown after approve/reject | | | |
| 7.13 | Status updates after successful action | | | |
| 7.14 | Already-approved/rejected IPO shows no review buttons | | | |
| 7.15 | Mock data banner is visible | | | |
| 7.16 | No real financial figures (prices, share counts) displayed | | | |

---

## 8. Audit / Activity Page

| # | Check | Pass/Fail | Notes / Evidence | Defect Owner |
|---|-------|-----------|-----------------|--------------|
| 8.1 | Audit page renders without crash | | | |
| 8.2 | Page clearly shows "PHASE 1 PLACEHOLDER" notice | | | |
| 8.3 | Dependency note lists Member 2 as blocker for /admin/audit | | | |
| 8.4 | No invented real audit events are displayed | | | |
| 8.5 | Planned columns list is visible | | | |

---

## 9. Security and Data Safety

| # | Check | Pass/Fail | Notes / Evidence | Defect Owner |
|---|-------|-----------|-----------------|--------------|
| 9.1 | No real passwords or tokens in source code or Git | | | |
| 9.2 | No real customer data committed | | | |
| 9.3 | Unauthenticated navigation is blocked by route guard | | | |
| 9.4 | Backend authorization is documented as the real security boundary | | | |
| 9.5 | No manual "edit balance" feature exists | | | |
| 9.6 | No real financial transaction is implied as completed | | | |
| 9.7 | Mock approval does not claim to be a real backend operation | | | |

---

## 10. Responsive Layout

| # | Check | Pass/Fail | Notes / Evidence | Defect Owner |
|---|-------|-----------|-----------------|--------------|
| 10.1 | Dashboard usable at 1440px width | | | |
| 10.2 | Dashboard usable at 768px width | | | |
| 10.3 | Dashboard usable at 400px width (sidebar collapses) | | | |
| 10.4 | Tables scroll horizontally on narrow screens | | | |
| 10.5 | Dialogs fit viewport on narrow screens | | | |
| 10.6 | Text does not overflow or truncate unreadably | | | |

---

## 11. Mock / API Boundary Documentation

| # | Check | Pass/Fail | Notes / Evidence | Defect Owner |
|---|-------|-----------|-----------------|--------------|
| 11.1 | All mock pages have a visible mock banner | | | |
| 11.2 | All repository interfaces are documented for API swap | | | |
| 11.3 | Missing endpoints are listed with owner in this document | | | |

---

## 12. Known Missing Endpoints (Phase 2 Blockers)

| Endpoint | Feature | Owner | Priority |
|----------|---------|-------|----------|
| `POST /auth/login` | Real admin authentication | Member 2 — Backend | P0 |
| `GET /admin/users` | User review list | Member 2 — Backend | P0 |
| `GET /admin/users/:id` | User detail | Member 2 — Backend | P0 |
| `POST /admin/users/:id/approve` | Approve user | Member 2 — Backend | P0 |
| `POST /admin/users/:id/reject` | Reject user | Member 2 — Backend | P0 |
| `GET /admin/companies` | Company review list | Member 2 — Backend | P0 |
| `GET /admin/companies/:id` | Company detail | Member 2 — Backend | P0 |
| `POST /admin/companies/:id/approve` | Approve company | Member 2 — Backend | P0 |
| `POST /admin/companies/:id/reject` | Reject company | Member 2 — Backend | P0 |
| `GET /admin/ipos` | IPO list | Member 2 — Backend | P0 |
| `GET /admin/ipos/:id` | IPO detail | Member 2 — Backend | P0 |
| `POST /admin/ipos/:id/approve` | Approve IPO | Member 2 — Backend | P0 |
| `POST /admin/ipos/:id/reject` | Reject IPO | Member 2 — Backend | P0 |
| `GET /admin/audit` | Audit log | Member 2 — Backend | P1 |

---

## 13. Run Instructions

```bash
# From the admin/ directory:

# Install dependencies (first time only):
flutter pub get

# Run in Chrome (demo mode, no backend needed):
flutter run -d chrome

# Run with real backend:
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:3000

# Run static analysis:
flutter analyze

# Build for web:
flutter build web --dart-define=API_BASE_URL=https://your-backend-url
```

**Demo credentials (mock mode only):**
- Email: `admin@dirsha.dev`
- Password: `demo1234`

---

*This checklist should be completed before the Phase 2 integration checkpoint.*

---

## 14. Business-Rule Alignment (added 2026-10-21)

This section documents how the admin dashboard aligns with the business rules
supplied by Member 2 (Dirsha Business Rules — wallet, money, access, Oct 20 2026).

### A. Money and financial precision

| Rule | Implementation | Status |
|---|---|---|
| ETB amounts are integer minor units (santim), 100 santim = 1 ETB | `pricePerShareSantim: int?` in `IpoApplication`. Field renamed from `pricePerShareEtb` to make units unambiguous. | ✅ Aligned |
| Display using integer arithmetic, no floats | `EtbFormatter` in `lib/core/utils/etb_formatter.dart` — uses `~/` and `%`, no floating-point | ✅ Aligned |
| `fromJson` accepts both `pricePerShareSantim` and legacy `pricePerShareEtb` | Fallback in `IpoApplication.fromJson` | ✅ Aligned |
| `totalSharesOffered` is a share count, not ETB | Documented in model and displayed as "X shares", not formatted as currency | ✅ Aligned |
| No wallet-edit UI | No such feature exists | ✅ Aligned |
| No direct balance mutation | Not implemented | ✅ Aligned |
| Mock IPO-003 has a demo price in santim | `pricePerShareSantim: 50000` = ETB 500.00. Labeled DEMO VALUE in comment. | ✅ Aligned |

**Outstanding question for Member 2:** Confirm the backend field name for share price — is it `pricePerShareSantim` or something else? The `fromJson` currently accepts both `pricePerShareSantim` and `pricePerShareEtb` as a fallback.

### B. Roles, account status, and verification status

| Rule | Implementation | Status |
|---|---|---|
| Role, accountStatus, verificationStatus are separate fields | `UserApplication` now has three distinct fields with separate enums | ✅ Aligned |
| Backend role values: `investor`, `company_rep`, `broker`, `admin` | `UserRole` enum maps all four plus `unknown` fallback | ✅ Aligned |
| Backend accountStatus values: `active`, `suspended` | `UserAccountStatus` enum maps both plus `unknown` | ✅ Aligned |
| Backend verificationStatus values: `unverified`, `pending`, `verified`, `rejected` | `UserVerificationStatus` enum maps all four plus `unknown` | ✅ Aligned |
| Do not infer verified from active | Separate badges shown; explicit note in UI: "No regulated identity-verification process exists yet" | ✅ Aligned |
| B3 PENDING — do not imply verification is required | Note in model and in user detail screen: "B3 pending team sign-off" | ✅ Pending preserved |
| User list shows role column | `RoleBadge` shown in table and card | ✅ Aligned |
| User detail shows all three fields with separate badges | `RoleBadge`, `AccountStatusBadge`, `VerificationStatusBadge` | ✅ Aligned |

**Outstanding question for Member 2:** Confirm `accountStatus` field name in `/admin/users` response — is it `accountStatus` or `account_status`?

### C. Authentication and administrative access

| Rule | Implementation | Status |
|---|---|---|
| Admin accounts cannot self-register | No registration route exists | ✅ Aligned |
| Mock auth clearly labeled as dev-only | Three warning comments in `mock_auth_service.dart`; demo note on sign-in screen | ✅ Aligned |
| No real credentials hardcoded | Demo credentials shown in UI, never in production config | ✅ Aligned |
| `AdminUser` has `accountStatus` field | Added — display only, not used as a security gate | ✅ Aligned |
| `ApiException` typed for 401/403/404/network | All four exist in `api_exception.dart` | ✅ Aligned |
| B12 PENDING — session/refresh token policy | Documented in `AdminUser` model comment; no token lifetime assumed | ✅ Pending preserved |

**Note:** When `ApiAuthService` is implemented, a 401 response from any API call should call `authProvider.signOut()` and redirect to sign-in. The infrastructure exists in `AdminAuthProvider` but is not triggered automatically yet — dependency on Member 2's auth endpoint contract.

### D. IPO visibility and status

| Rule | Implementation | Status |
|---|---|---|
| Two-tier visibility (public: open/closed/allocated/listed; restricted: draft/submitted/under_review/approved/rejected/withdrawn) | Documented in `ipo_application.dart` header comment | ✅ Documented |
| Backend returns same 404 for non-existent and restricted IPOs | Error message in `ipo_detail_screen.dart` explains this behavior | ✅ Aligned |
| Status snake_case mapping | All 10 statuses map correctly in `_parseStatus` | ✅ Aligned |
| `isReviewable` limited to `submitted` and `underReview` | Unchanged — correct | ✅ Aligned |

### E. Audit and activity

| Rule | Implementation | Status |
|---|---|---|
| No fabricated audit events | `MockAuditRepository` returns empty list | ✅ Aligned |
| No audit record editing | Not implemented | ✅ Aligned |
| Placeholder clearly labeled | "PHASE 1 PLACEHOLDER" banner with dependency note | ✅ Aligned |
| Dependency documented | `/admin/audit` — owner: Member 2 | ✅ Documented |

### Part B decisions — all correctly pending

| Decision | Status |
|---|---|
| B1 Subscription amount/reservation | Not implemented |
| B2 Min/max subscription quantities | Not implemented |
| B3 Investor eligibility / verification required | Not implemented; explicit note in user model and detail screen |
| B4 One active subscription per investor per IPO | Not implemented |
| B5 IPO subscription window / server-clock validation | Not implemented |
| B6 Allocation when undersubscribed | Not implemented |
| B7 Pro-rata allocation | Not implemented |
| B8 Settlement and release | Not implemented |
| B9 Investor cancellation | Not implemented |
| B10 Whole-share precision | Not implemented |
| B11 Settled funds without company wallet | Not implemented |
| B12 Session/token policy | Not implemented; noted in AdminUser model |
| B13 Company onboarding / IPO creation timing | Deferred; noted in PHASE_1_QA.md |

### Out-of-scope features confirmed not implemented

- Investor wallet management or test-fund crediting
- Subscription creation or cancellation
- Share allocation or settlement
- Trading, order matching, broker authority
- Company wallet or money-transfer
- Any Part B proposal as finalized behavior

### Outstanding questions for Member 2

1. What is the exact field name for share price in the IPO API response — `pricePerShareSantim` or different?
2. What is the exact field name for account status in the user API response — `accountStatus` or `account_status`?
3. What are the exact endpoint paths for admin review actions — `/admin/ipos/:id/approve` or different?
4. What HTTP status code does the backend return for a suspended admin attempting to sign in — 401 or 403?
5. When is the `/admin/audit` endpoint available and what fields does it return?
