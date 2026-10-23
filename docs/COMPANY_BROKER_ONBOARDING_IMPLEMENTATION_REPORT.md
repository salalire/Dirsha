# Company and Broker Onboarding Implementation & Verification Report

**Branch:** `phase1-integration`  
**Date:** 23 October 2026  
**Status:** COMPLETE & VERIFIED  

---

## 1. Executive Summary

This report documents the completion of the company and broker registration, onboarding, and administrative review workflows for the Dirsha primary market platform on the integrated `phase1-integration` branch.

All work conforms strictly to the agreed **Option C** architecture:
- **Investors** use the existing Flutter mobile application for authentication, wallet funding, IPO exploration, and primary market subscriptions.
- **Company representatives** access a dedicated Company Web Portal (`/portal/company`) to register their legal entity profile, upload required regulatory evidence, submit applications, track review states, and respond to requests for additional information.
- **Brokers** (firms and individual brokers) access a dedicated Broker Web Portal (`/portal/broker`) to submit ECMA licensing details, upload proof of licensing, and manage their onboarding lifecycle.
- **Administrators** review, approve, reject, or request additional information for both company and broker applications through the existing Flutter Admin Dashboard (`admin/`).
- **Backend & Database** manage persistent state across PostgreSQL using migration `0005_company_broker_onboarding.sql`, enforcing role-based access control, document storage with SHA-256 integrity checks, and immutable status audit trails.

All 286 automated tests (116 backend vitest tests, 15 admin flutter tests, 155 mobile flutter tests) pass with 100% success rate. Zero Phase 3 work was started.

---

## 2. Company Registration Workflow

### 2.1 Representative Registration & Access
- Company representatives register through `/auth/register` with role `company_rep`.
- Public registration creates a user record with `account_status: active` and `verification_status: unverified`.
- The user is authenticated via standard JWT (`/auth/login`) with role validation.

### 2.2 Profile & Field Capture
Through `/onboarding/company` and the Company Web Portal (`portals/company/`), the applicant provides:
- **Company Identity:** Registered company name, trading name, registration number, legal entity type, country of incorporation, incorporation date, registered address, operating address, business email, business telephone, website, sector/industry, business description.
- **Tax & Regulatory Details:** Tax Identification Number (TIN), regulatory registration details, business license number.
- **Authorized Representative:** Full legal name, business email, telephone, job title/position, relationship to the company, and mandatory declaration confirming authority to submit the application (`authority_declaration_confirmed`).

### 2.3 Application Lifecycle & State Transitions
Supported lifecycle states:
```mermaid
stateDiagram-v2
    [*] --> draft
    draft --> submitted: Complete profile & mandatory documents
    submitted --> under_review: Admin starts review
    under_review --> approved: Admin approval
    under_review --> rejected: Admin rejection (with reason)
    under_review --> additional_info_required: Admin requests info
    additional_info_required --> resubmitted: Applicant updates & resubmits
    resubmitted --> under_review: Admin reviews update
    approved --> [*]
    rejected --> [*]
```
- The backend blocks submission if mandatory documents (`commercial_registration`, `tin_certificate`) are missing or if the authority declaration is false.
- When an application is approved, the company representative's user `verification_status` transitions from `pending` to `verified`.

---

## 3. Broker Registration Workflow

### 3.1 Broker Account Types
The onboarding workflow supports two distinct broker applicant types:
1. **Brokerage Firm (`firm`):** Collects firm name, commercial registration number, authorized representative details, business address, and corporate contact details.
2. **Individual Broker (`individual`):** Collects individual professional details, professional address, and individual contact information.

### 3.2 Licensing & Regulatory Information
- **License Number:** Registered license identifier (e.g., `ECMA-BRK-2026-0042`).
- **Licensing Authority:** Regulatory body issuing the license (default: Ethiopian Capital Market Authority - ECMA).
- **Jurisdiction:** Country or territory of legal jurisdiction (`ET`).
- **Expiry Date & Verification:** Required license expiry date. The backend validates that the expiry date is in the future at submission time and flags expired licenses (`is_license_expired: true`).
- **Mandatory Document:** Proof of licensing (`broker_license`) is strictly enforced before submission.

### 3.3 Authorization Enforcement
- Registering as a broker does NOT grant approved broker privileges.
- Backend authorization guards reject unverified brokers attempting restricted operations.
- Admin review is mandatory before privileges are granted.

---

## 4. Admin Review & Decision Workflow

The existing Flutter Admin Dashboard (`admin/`) has been extended to provide review for both company and broker applications.

### 4.1 Company Reviews (`/company-reviews`, `/company-reviews/:id`)
- **List View:** Search by company name, representative, or ID. Filter by status (`All`, `Pending`, `Under Review`, `Info Required`, `Approved`, `Rejected`).
- **Detail View:**
  - Company identity, tax details (TIN), legal entity type, and registered address.
  - Authorized representative contact information and authority confirmation.
  - Submitted documents with document type, review status, and reviewer notes.
  - Review actions:
    - **Approve Company:** Persists approval decision, marks user verified, logs audit trail.
    - **Request Info:** Opens modal requiring detailed message to applicant, sets status to `additional_info_required`.
    - **Reject Application:** Opens destructive modal requiring official reason, sets status to `rejected`.

### 4.2 Broker Reviews (`/broker-reviews`, `/broker-reviews/:id`)
- **List View:** Search by broker name, firm name, license number, or ID. Shows applicant type (`FIRM` / `INDIVIDUAL`), license number, expiration warnings, and status badge.
- **Detail View:**
  - Broker identity, firm name, representative, and contact info.
  - Licensing authority, license number, and expiry date.
  - **License Expiration Warning:** Prominently highlights expired licenses and disables the Approve button until a valid license is submitted.
  - Submitted supporting documents with review status.
  - Review actions:
    - **Approve Broker:** Persists approval decision, marks user verified.
    - **Request Info:** Requests updated documents or clarifications.
    - **Reject Broker:** Records rejection reason and audit event.

### 4.3 Document Review Endpoint
- Administrators can review individual supporting documents via `POST /admin/documents/:id/review` with `{ "status": "approved" | "rejected", "notes": "..." }`.

---

## 5. Mobile Integration

### 5.1 Option C Entry Points
The mobile application retains its architecture in:
- `CompanyPortalScreen` (`mobile/lib/features/auth/screens/company_portal_screen.dart`)
- `BrokerPortalScreen` (`mobile/lib/features/auth/screens/broker_portal_screen.dart`)

### 5.2 Build-Time Configuration
URLs are injected at build time using `--dart-define`:
```bash
flutter run --dart-define=DIRSHA_COMPANY_PORTAL_URL=http://localhost:3000/portal/company \
            --dart-define=DIRSHA_BROKER_PORTAL_URL=http://localhost:3000/portal/broker
```
- When configured: Screens provide an "Open company portal" / "Open broker portal" action.
- When unconfigured / empty: Screens display a helpful "portal not yet available" notice with return navigation to sign-in.
- Investor registration and authentication flows remain untouched.

---

## 6. Backend Implementation & APIs

All onboarding and review operations are exposed through Express endpoints following the project's established conventions (`snake_case` JSON, JWT bearer authentication, structured error codes, audit logging).

### 6.1 Onboarding Endpoints
| Endpoint | Method | Role | Description |
|---|---|---|---|
| `/onboarding/company` | `GET` | `company_rep` | Retrieve company profile, documents, and history |
| `/onboarding/company/draft` | `POST` | `company_rep` | Upsert company draft information |
| `/onboarding/company/submit` | `POST` | `company_rep` | Validate and submit application |
| `/onboarding/company/documents` | `POST` | `company_rep` | Upload supporting document (base64, 10MB limit) |
| `/onboarding/company/documents/:docId/download` | `GET` | `company_rep` / `admin` | Download protected document binary |
| `/onboarding/company/documents/:docId` | `DELETE` | `company_rep` | Delete document in draft or correction state |
| `/onboarding/broker` | `GET` | `broker` | Retrieve broker profile, documents, and history |
| `/onboarding/broker/draft` | `POST` | `broker` | Upsert broker draft information |
| `/onboarding/broker/submit` | `POST` | `broker` | Validate license & submit broker application |
| `/onboarding/broker/documents` | `POST` | `broker` | Upload broker document (base64, 10MB limit) |
| `/onboarding/broker/documents/:docId/download` | `GET` | `broker` / `admin` | Download broker document binary |
| `/onboarding/broker/documents/:docId` | `DELETE` | `broker` | Delete broker document |

### 6.2 Admin Review Endpoints
| Endpoint | Method | Role | Description |
|---|---|---|---|
| `/admin/companies` | `GET` | `admin` | List company applications with pagination & filters |
| `/admin/companies/:id` | `GET` | `admin` | Get company application detail |
| `/admin/companies/:id/approve` | `POST` | `admin` | Approve company application |
| `/admin/companies/:id/reject` | `POST` | `admin` | Reject company application with reason |
| `/admin/companies/:id/request-info` | `POST` | `admin` | Request corrections/documents with message |
| `/admin/brokers` | `GET` | `admin` | List broker applications with pagination & filters |
| `/admin/brokers/:id` | `GET` | `admin` | Get broker application detail |
| `/admin/brokers/:id/approve` | `POST` | `admin` | Approve broker application |
| `/admin/brokers/:id/reject` | `POST` | `admin` | Reject broker application with reason |
| `/admin/brokers/:id/request-info` | `POST` | `admin` | Request broker corrections/documents |
| `/admin/documents/:id/review` | `POST` | `admin` | Record review status for supporting document |

---

## 7. Database Migrations

Migration file: [`backend/migrations/0005_company_broker_onboarding.sql`](file:///home/salah/Dirsha/backend/migrations/0005_company_broker_onboarding.sql)
Applied to both `dirsha_dev` and `dirsha_test`.

### Schema Additions:
1. **Extended `companies` table:**
   - 20+ columns for business identity, registered address, tax identifier (`tin`), sector, authorized representative credentials, and authority confirmation.
   - Status constraint: `draft`, `submitted`, `under_review`, `additional_info_required`, `resubmitted`, `approved`, `rejected`.
2. **`brokers` table:**
   - Identity, firm vs individual type, licensing authority, license number, license expiry date, jurisdiction, contact details, status, review notes, timestamps.
3. **`supporting_documents` table:**
   - Tracks document uploads linked polymorphically to `company` or `broker`.
   - Stores `storage_key`, `original_filename`, `mime_type`, `file_size`, `sha256_hash`, `review_status` (`pending`, `approved`, `rejected`), `review_notes`.
4. **`application_status_history` table:**
   - Immutable audit trail recording each state transition: `from_status`, `to_status`, `changed_by_user_id`, `actor_role`, `notes`, `created_at`.

---

## 8. Document Storage Implementation

Implemented in [`backend/src/modules/onboarding/document-storage.ts`](file:///home/salah/Dirsha/backend/src/modules/onboarding/document-storage.ts):
- **Storage Location:** Private disk storage configured via `DOCUMENT_STORAGE_DIR` (default: `<project_root>/storage/documents`), completely outside web server root.
- **Allowed MIME Types:** `application/pdf`, `image/png`, `image/jpeg`.
- **Size Limitation:** Maximum 10MB per file; verified on server before persistence.
- **Integrity:** SHA-256 hash computed on binary buffer and stored in database.
- **Path Traversal Guards:** File paths strictly sanitized using random UUID storage keys.
- **Access Control:** No public URLs. Document streaming requires valid authenticated session where user is either the application owner or an authorized administrator.

---

## 9. Security & Authorization

- **Ownership Checks:** Company reps cannot access or modify other companies' applications. Brokers cannot access other brokers' applications.
- **Role Escalation Prevention:** Users cannot self-assign `admin` roles or approve their own applications.
- **License Validation:** Expired licenses cannot be submitted or approved.
- **Zero Secrets in Code or Logs:** Storage paths, tokens, and document content are never leaked in error responses or logs.
- **Transactional State Updates:** Application approval and user status verification execute inside PostgreSQL transactions (`db.tx()`).

---

## 10. UI Consistency

- **Web Portals (`/portal/company`, `/portal/broker`):**
  - Built with modern HTML5, CSS3, and ES6 JavaScript.
  - Matches Dirsha brand emerald green (`#00A86B`), dark slate (`#0B0F17`), and gold accents.
  - Fully responsive for mobile and desktop screens.
  - Clean multi-section forms, real-time client-side validation, drag-and-drop document upload, and status timeline display.
- **Admin Dashboard (`admin/`):**
  - Adheres to established typography, dark/light theme switching, AppShell sidebar navigation, info cards, status badges, and confirmation dialogs.

---

## 11. Automated Test Results

### 11.1 Backend Test Results
Command executed:
```bash
TEST_DATABASE_URL="postgres://dirsha:dirsha_local_test@localhost:5432/dirsha_test" npx vitest run
```
Output:
```
Test Files  13 passed (13)
     Tests  116 passed (116)
  Start at  09:57:31
  Duration  25.87s
```
Test files verified:
- `tests/onboarding.test.ts` (6 comprehensive test suites: company lifecycle, broker lifecycle, unauthorized access, license validation, admin review, and document security)
- `tests/auth.test.ts` (20 tests)
- `tests/admin.test.ts` (7 tests)
- `tests/e2e-phase2-checkpoint.test.ts` (1 test)
- `tests/subscriptions.test.ts` (17 tests)
- `tests/ipos.test.ts` (11 tests)
- `tests/users.test.ts` (4 tests)
- `tests/admin-provision.test.ts` (2 tests)
- `tests/health-and-http.test.ts` (7 tests)
- `tests/migrations.test.ts` (4 tests)
- `tests/env-and-money.test.ts` (9 tests)
- `tests/ledger.test.ts` (10 tests)
- `tests/wallet-reconciliation.test.ts` (3 tests)

### 11.2 Admin Dashboard Flutter Test Results
Command executed:
```bash
/home/salah/programfiles/flutter/bin/flutter test
```
Output:
```
00:04 +15: All tests passed!
```
Test files verified:
- `test/widget_test.dart` (App builds and renders)
- `test/api_repositories_test.dart` (15 tests including `ApiAuthService`, `ApiIpoRepository`, `ApiUserRepository`, `ApiAuditRepository`, `ApiCompanyRepository`, and `ApiBrokerRepository`)

### 11.3 Mobile App Flutter Test Results
Command executed:
```bash
/home/salah/programfiles/flutter/bin/flutter test
```
Output:
```
00:17 +155: All tests passed!
```
Test suites verified:
- Role selection tests (`test/features/auth/role_selection_test.dart`)
- Company & broker portal unavailable state tests
- Auth & registration tests
- Wallet balance & transaction tests
- Subscription & IPO exploration tests

---

## 12. End-to-End Verification Evidence

### 12.1 Company Onboarding Workflow (End to End)
1. Registered new company representative (`company_rep`).
2. Created draft application with full company identity, registration number, TIN (`0011223344`), and sector (`Manufacturing`).
3. Uploaded commercial registration and TIN certificate documents via base64 upload to private storage.
4. Submitted application with representative authority declaration confirmation. Status transitioned to `submitted`.
5. Listed application in admin dashboard via `/admin/companies`.
6. Admin reviewed application and requested additional information ("Please provide clearer copy of TIN certificate"). Status transitioned to `additional_info_required`.
7. Company representative retrieved status, uploaded corrected document, and resubmitted application. Status transitioned to `resubmitted`.
8. Admin reviewed updated document and approved application via `/admin/companies/:id/approve`.
9. Verified company status transitioned to `approved` and user `verification_status` transitioned to `verified`.
10. Application status history verified in database table `application_status_history`.

### 12.2 Broker Onboarding Workflow (End to End)
1. Registered broker user (`broker`).
2. Created draft broker profile with broker type `firm`, firm name `Abyssinia Capital`, ECMA license `ECMA-BRK-2026-0042`, and future expiry date (`2027-12-31`).
3. Uploaded mandatory `broker_license` document.
4. Submitted application. Verified status transitioned to `submitted`.
5. Admin listed broker application in `/admin/brokers`.
6. Verified license was valid and unexpired.
7. Admin approved broker application. Verified status transitioned to `approved` and user `verification_status` transitioned to `verified`.
8. Tested expired license scenario: application with expired license date was blocked at submission and flagged as expired in admin reviews.

---

## 13. Regression Testing

All prior Phase 1 and Phase 2 features were verified against the live PostgreSQL database:
- **Ledger Invariance:** Zero wallet reconciliation errors (`wallet_reconciliation.ok = true` for all wallets).
- **Simulated Test Funds:** `POST /dev/test-funds` continues to enforce idempotency and max limits.
- **Primary Market Subscriptions:** Pro-rata allocation and settlement engine pass all checkpoint tests.
- **IPO Discovery & Filtering:** Open, upcoming, and listed IPOs render with correct pricing and share units.
- **Investor Auth & Profile:** Investor registration and login workflows function without regression.

---

## 14. Environment Configuration

### Backend (`backend/.env`)
```bash
PORT=3000
DATABASE_URL=postgres://dirsha:dirsha_local_test@localhost:5432/dirsha_dev
TEST_DATABASE_URL=postgres://dirsha:dirsha_local_test@localhost:5432/dirsha_test
DOCUMENT_STORAGE_DIR=/home/salah/Dirsha/storage/documents
JWT_SECRET=local-development-secret-change-in-production
ENABLE_TEST_FUNDS=true
```

### Mobile App Build Flags (`mobile/`)
```bash
flutter run --dart-define=DIRSHA_API_BASE_URL=http://localhost:3000 \
            --dart-define=DIRSHA_COMPANY_PORTAL_URL=http://localhost:3000/portal/company \
            --dart-define=DIRSHA_BROKER_PORTAL_URL=http://localhost:3000/portal/broker
```

### Admin Dashboard (`admin/`)
```bash
flutter run -d chrome --dart-define=DIRSHA_API_BASE_URL=http://localhost:3000 \
                      --dart-define=DIRSHA_USE_MOCKS=false
```

---

## 15. Outstanding Blockers & Non-Blocking Notes

- **Zero Functional Blockers:** Both workflows are fully implemented, tested, and operational.
- **Storage Driver Note:** Document storage currently uses local private disk storage with SHA-256 verification and path traversal protections. For production cloud deployments, an S3/GCS bucket driver can be plugged into `DocumentStorageManager` without changing API contracts or database models.

---

## 16. Confirmation of Scope Boundaries

- **Phase 3:** Has **NOT** been started. No secondary market, trading books, order matching, or broker-investor trading relationships were implemented.
- **Git State:** No commits were pushed; no branches were merged; `main` was not modified.
- **Existing Work:** All existing Phase 1 and Phase 2 investor functionality, wallets, and IPO primary market capabilities were preserved intact.
