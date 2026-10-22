# Dirsha — Mobile and Admin to Backend API Contract Gap Analysis

**Document Status:** Technical Architecture Analysis & Contract Audit  
**Target Baseline:** `phase1-integration` (`8b5dd49`)  
**Specification Reference:** `docs/API_SPECIFICATION.md` (v0.1, 2026-10-20)  
**Date:** 2026-10-22  

---

## 1. Overview and Problem Statement

During Phase 1, the three subsystems were developed in parallel using agreed interface specifications:
- **Member 2 (Backend):** Built Express + PostgreSQL endpoints adhering to `docs/API_SPECIFICATION.md`.
- **Member 1 (Mobile):** Built Flutter client models and screens based on the conceptual SRS draft and isolated mock repositories.
- **Member 3 (Admin Web):** Built Flutter Web administrative screens based on mock repositories.

While the components merge cleanly and static analysis passes, connecting the mobile and admin frontends to the live backend currently fails due to contract mismatches in URLs, JSON naming, enum formatting, envelope structures, and request payloads.

This document systematically audits every mismatch between the current backend implementation and frontend expectations, provides code evidence, evaluates severity, and outlines safe, non-destructive resolution paths.

---

## 2. Forensic Gap Analysis by Contract Area

### A. API Base URL
- **Backend Implementation:**
  In `backend/src/app.ts:L64-71`, routes are mounted directly at root prefixes:
  ```ts
  app.use('/health', healthRouter(deps.db));
  app.use('/auth', authRouter(deps));
  app.use('/users', usersRouter(deps));
  app.use('/ipos', iposRouter(deps));
  app.use('/wallets', walletsRouter(deps));
  app.use('/dev', devRouter(deps));
  ```
  `docs/API_SPECIFICATION.md` §1 confirms: *"Local default: `http://localhost:3000`. Never hard-code it in the apps. No `/v1` prefix yet."*
- **Client Implementation:**
  - **Mobile:** In `mobile/lib/core/config/app_config.dart:L36`, the default base URL is:
    ```dart
    static const String apiBaseUrl = String.fromEnvironment(
      'DIRSHA_API_BASE_URL',
      defaultValue: 'http://localhost:3000/api', // Note trailing /api
    );
    ```
    Requests made with this default target `http://localhost:3000/api/auth/login`, returning HTTP `404 NOT_FOUND`.
  - **Admin Web:** In `admin/lib/core/config/app_config.dart:L13`, default is `http://localhost:3000` (correct).
- **Severity:** **HIGH** (Completely blocks all mobile live HTTP communication out-of-the-box).
- **Recommended Resolution:**
  Update `mobile/lib/core/config/app_config.dart` default to `http://localhost:3000` (or `http://10.0.2.2:3000` for Android emulator testing via `--dart-define`). Keep backend routes at root as specified.

---

### B. JSON Field Casing and Key Naming
- **Backend Implementation:**
  Adheres strictly to `snake_case` per `docs/API_SPECIFICATION.md` §1:
  - User: `full_name`, `account_status`, `verification_status`, `created_at`
  - IPO: `company_id`, `company_name`, `price_per_share_minor`, `total_shares`, `min_shares_per_subscription`, `max_shares_per_subscription`, `opens_at`, `closes_at`, `created_at`
  - Wallet: `available_minor`, `reserved_minor`, `total_minor`, `updated_at`
  - Ledger / Transactions: `wallet_id`, `available_delta_minor`, `reserved_delta_minor`, `available_after_minor`, `reserved_after_minor`, `reference_type`, `reference_id`, `created_at`
- **Client Implementation:**
  - `mobile/lib/features/auth/models/auth_models.dart:L105-116` (`UserProfile.fromJson`):
    Expects `firstName`, `lastName`, `accountStatus`, `avatarUrl`. Because `firstName` is declared `String` without nullability and backend returns `full_name`, parsing throws a runtime `TypeError` (`null is not a subtype of type 'String'`).
  - `mobile/lib/features/ipos/models/ipo_models.dart:L38-70` (`IpoSummary.fromJson`):
    Expects `companyName` (non-nullable `String`), `subscriptionStartDate`, `subscriptionEndDate`, `totalShares`. Parsing throws `TypeError` on missing `companyName`. Dates and total shares silently evaluate to `null`.
  - `mobile/lib/features/wallet/models/wallet_models.dart:L87-100` (`WalletTransaction.fromJson`):
    Expects `createdAt` (`DateTime.parse(json['createdAt'] as String)`), `referenceId`, `referenceType`, and `amount_minor` (backend sends deltas `available_delta_minor`). Parsing throws runtime `TypeError` on `json['createdAt']`.
- **Severity:** **HIGH** (Causes immediate client-side JSON deserialization exceptions and application crashes on valid backend responses).
- **Recommended Resolution:**
  Adapt the mobile model serialization layer (`fromJson` / `toJson`). Update mobile models to support both snake_case (authoritative backend) and legacy camelCase fallback.

---

### C. Status Enumerations (Casing and Values)
- **Backend Implementation:**
  All enums use lowercase `snake_case` strings (`API_SPECIFICATION.md` §3):
  - `role`: `investor`, `company_rep`, `broker`, `admin`
  - `account_status`: `active`, `suspended`
  - `verification_status`: `unverified`, `pending`, `verified`, `rejected`
  - `ipo_status`: `draft`, `submitted`, `under_review`, `approved`, `open`, `closed`, `allocated`, `listed`, `rejected`, `withdrawn`
  - `ledger_type`: `test_fund_credit`, `subscription_reserve`, `subscription_release`, `subscription_settle`, `adjustment`
  - `ledger_status`: `posted`
- **Client Implementation:**
  - **Mobile:**
    - `IpoSummary.isOpen` (`ipo_models.dart:L99`): Checks `status == 'OPEN'`. Backend sends `"open"`, so `isOpen` evaluates to `false`.
    - `UserProfile.isActive` (`auth_models.dart:L134`): Checks `accountStatus == 'ACTIVE'`. Backend sends `"active"`, evaluating to `false`.
    - `WalletTransaction`: Expects types `CREDIT`, `DEBIT`, `RESERVATION`, `RELEASE`, `REFUND`, `SETTLEMENT`. Backend sends `test_fund_credit`, `subscription_reserve`, etc. Consequently, `isCredit` and `isDebit` both evaluate to `false`.
    - `WalletTransaction.status`: Expects `PENDING`, `COMPLETED`, `FAILED`, `REVERSED`. Backend sends `posted`.
  - **Admin Web:**
    - `admin/lib/features/ipos/models/ipo_application.dart:L141-166`: Correctly parses lowercase backend strings via `_parseStatus()` (`case 'open': return IpoStatus.open;`).
- **Severity:** **MEDIUM-HIGH** (Does not immediately crash if handled as string, but breaks all conditional UI logic, action button visibility, and transaction type displays).
- **Recommended Resolution:**
  Add a robust enum parser/normalizer in mobile models that maps backend lowercase snake_case values to internal Dart enums, with case-insensitive fallback.

---

### D. Response Envelopes, Pagination, and Query Parameters
- **Backend Implementation:**
  - Single entity: `{ "data": { ... } }`
  - List / paginated: `{ "data": [ ... ], "pagination": { "page": 1, "page_size": 20, "total": 3 } }`
  - Query parameters: `page` (default 1), `page_size` (default 20, max 100)
- **Client Implementation:**
  - `mobile/lib/features/wallet/repositories/live_wallet_repository.dart:L26-31`:
    Calls `_client.get('/wallets/me')` and passes the response directly to `WalletSummary.fromJson(data)`. Because `data` contains `{ "data": { "id": ... } }`, `data['id']` is `null`, throwing `TypeError`.
  - `mobile/lib/features/ipos/repositories/live_ipo_repository.dart:L41-46`:
    Calls `_client.get('/ipos/$id')` and directly invokes `IpoDetail.fromJson(data)` without unwrapping `{ "data": ... }`.
  - `PaginatedIpos.fromJson` (`ipo_models.dart:L236-247`) & `PaginatedTransactions.fromJson` (`wallet_models.dart:L157-168`):
    Looks for `json['total']`, `json['page']`, `json['pageSize']` at root. In the backend response, these reside in the nested `pagination` object (`json['pagination']['total']`, etc.).
  - Query parameter naming:
    Mobile repositories send `queryParameters: {'page': page, 'pageSize': pageSize}`. Backend expects `page_size`.
- **Severity:** **HIGH** (Prevents reading single-object details and causes pagination metadata to default to 0/empty).
- **Recommended Resolution:**
  1. In `mobile/lib/core/network/api_client.dart` or repository methods, consistently unwrap `{ "data": ... }`.
  2. In paginated wrappers, read metadata from `json['pagination'] ?? json`.
  3. Send `page_size` in query parameters.

---

### E. User Registration Payload and Role Selection
- **Backend Implementation:**
  `backend/src/modules/auth/auth.schema.ts` enforces:
  ```ts
  export const registerBodySchema = z.strictObject({
    email: emailSchema,
    password: passwordSchema,
    full_name: z.string().trim().min(1).max(120),
    phone: phoneSchema.optional(),
    role: z.enum(['investor', 'company_rep', 'broker']),
  });
  ```
  Unknown fields result in `400 VALIDATION_ERROR`.
  Does not authenticate the user; returns `201` with created user record.
- **Client Implementation:**
  - `mobile/lib/features/auth/models/auth_models.dart:L35-42` (`RegisterRequest.toJson`):
    ```dart
    Map<String, dynamic> toJson() => {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'password': password,
    };
    ```
    Sends `firstName` and `lastName` (both rejected as unknown fields by `strictObject`).
    Omits `full_name` (required).
    Omits `role` (required).
  - `LiveAuthRepository.register` (`live_auth_repository.dart:L63-68`):
    Expects registration to return tokens immediately (`AuthResult.fromJson(data)`). Backend returns only the user profile and requires calling `POST /auth/login` to obtain a session token.
- **Severity:** **HIGH** (All registration attempts fail with 400 Validation Error).
- **Recommended Resolution:**
  1. Update `RegisterRequest.toJson()` to send:
     `'full_name': '$firstName $lastName'.trim()`
     `'role': role.toLowerCase()` (from the selected user role screen)
  2. Update registration flow in `LiveAuthRepository`: after a successful 201 response, automatically execute login or route user to login screen.

---

### F. Authentication Response and Session Management
- **Backend Implementation:**
  `POST /auth/login` response envelope (`API_SPECIFICATION.md` §5):
  ```json
  {
    "data": {
      "access_token": "<jwt>",
      "token_type": "Bearer",
      "expires_in": 900,
      "user": {
        "id": "...",
        "email": "...",
        "full_name": "...",
        "phone": null,
        "role": "investor",
        "account_status": "active",
        "verification_status": "unverified",
        "created_at": "..."
      }
    }
  }
  ```
  Access tokens expire in 15 minutes (`900` seconds). **No refresh token is issued in Phase 1.**
- **Client Implementation:**
  - `AuthTokens.fromJson` (`auth_models.dart:L69-80`):
    Expects `json['accessToken']`. Throws `FormatException` when missing.
  - `AuthResult.fromJson` (`auth_models.dart:L145-150`):
    Expects tokens at root and user at `json['user']`.
  - `LiveAuthRepository.logout` (`live_auth_repository.dart:L79-84`):
    Calls `POST /auth/logout`. Backend does not implement `/auth/logout` (JWT is stateless; sign-out is handled client-side by clearing secure storage).
- **Severity:** **HIGH** (Blocks login parsing and throws `FormatException`).
- **Recommended Resolution:**
  1. Update `AuthResult.fromJson` to parse from `json['data'] ?? json`.
  2. Map `json['access_token'] ?? json['accessToken']`.
  3. Treat `refreshToken` as optional `null`.
  4. Make `logout()` clear local tokens without expecting a backend `/auth/logout` endpoint.

---

### G. Error Response Structure
- **Backend Implementation:**
  `backend/src/http/error-handler.ts:L31-48`:
  ```json
  {
    "error": {
      "code": "VALIDATION_ERROR",
      "message": "Human readable message",
      "details": [
        { "field": "password", "message": "Password must be at least 8 characters" }
      ],
      "request_id": "bff091ad-be1d-426a-b229-d82fb67595fc"
    }
  }
  ```
- **Client Implementation:**
  `mobile/lib/core/network/api_client.dart:L217-236`:
  ```dart
  String? _extractMessage(dynamic body) => body['message'] as String?;
  String? _extractErrorCode(dynamic body) => body['error'] as String?;
  Map<String, String> _extractFieldErrors(dynamic body) { ... body['errors'] ... }
  ```
  Because `body['error']` is a Map in backend responses, `body['error'] as String?` returns `null` or throws. `body['message']` returns `null`. Field errors in `body['error']['details']` are ignored.
- **Severity:** **MEDIUM** (Error codes and user-friendly messages from the backend are dropped, displaying generic error fallbacks).
- **Recommended Resolution:**
  Update `_mapHttpError()` in `ApiClient` to read `body['error']['message']`, `body['error']['code']`, and transform `body['error']['details']` into field error mappings.

---

### H. Admin Review Endpoints
- **Current State:**
  The Admin Web dashboard (`admin/`) currently implements all operations using `MockIpoRepository`, `MockUserRepository`, `MockCompanyRepository`, and `MockAuditRepository`.
- **Phase 2 Backend Dependencies:**
  As documented in `docs/API_SPECIFICATION.md` §7 and `admin/PHASE_1_QA.md` §12, the following endpoints are Phase 2 deliverables:
  - `POST /auth/login` (with role `admin`)
  - `GET /admin/users`, `GET /admin/users/:id`, `POST /admin/users/:id/approve`, `POST /admin/users/:id/reject`
  - `GET /admin/companies`, `GET /admin/companies/:id`, `POST /admin/companies/:id/approve`, `POST /admin/companies/:id/reject`
  - `GET /admin/ipos`, `GET /admin/ipos/:id`, `POST /admin/ipos/:id/approve`, `POST /admin/ipos/:id/reject`
  - `GET /admin/audit`
- **Severity:** **INFORMATIONAL / PHASE 2 DEPENDENCY** (Expected by design for Phase 1; admin dashboard correctly indicates mock status).

---

## 3. Comprehensive Contract Mismatch Matrix

| # | Contract Area | Actual Backend Behavior | Actual Client Expectation | Evidence / File Path | Severity | Recommended Resolution | Owner |
|---|---|---|---|---|---|---|---|
| **1** | **Base URL** | Routes mounted at `/` (`/auth`, `/ipos`, `/wallets`) | Defaults to `http://localhost:3000/api` | `mobile/lib/core/config/app_config.dart:L36`<br>`backend/src/app.ts:L64-71` | **HIGH** | Change mobile default `apiBaseUrl` to `http://localhost:3000` | Member 1 |
| **2** | **Envelope Unwrapping** | Single object: `{ data: { ... } }`<br>List: `{ data: [ ... ], pagination: { ... } }` | Expects model fields at root of response JSON | `mobile/lib/features/wallet/repositories/live_wallet_repository.dart:L26-31`<br>`mobile/lib/features/ipos/repositories/live_ipo_repository.dart:L41-46` | **HIGH** | Unwrap `data['data']` in repositories or `ApiClient` before passing to model `fromJson` | Member 1 |
| **3** | **Auth Response** | Returns `{ data: { access_token, token_type, expires_in, user } }`. No refresh token. | Expects `{ accessToken, refreshToken, user }` at top level | `mobile/lib/features/auth/models/auth_models.dart:L69-80`<br>`backend/src/modules/auth/auth.routes.ts:L37` | **HIGH** | Update `AuthTokens.fromJson` and `AuthResult.fromJson` to unwrap `data` and read `access_token` | Member 1 |
| **4** | **Registration Schema** | Strict object: `{ full_name, email, password, phone, role }` | Sends `{ firstName, lastName, email, phone, password }` | `mobile/lib/features/auth/models/auth_models.dart:L35-42`<br>`backend/src/modules/auth/auth.schema.ts:L22` | **HIGH** | Update `RegisterRequest.toJson` to produce `full_name` and include selected `role` | Member 1 |
| **5** | **User Profile Deserialization** | Returns `{ id, email, full_name, phone, role, account_status, verification_status }` | Expects `{ id, firstName, lastName, email, phone, role, accountStatus }` | `mobile/lib/features/auth/models/auth_models.dart:L105-116`<br>`backend/src/http/auth.ts:L63-85` | **HIGH** | Update `UserProfile.fromJson` to parse `full_name` (split or map) and `account_status` | Member 1 |
| **6** | **IPO Summary Deserialization** | Returns `company_name`, `price_per_share_minor`, `opens_at`, `closes_at`, `total_shares` | Expects `companyName`, `subscriptionStartDate`, `subscriptionEndDate`, `totalShares` | `mobile/lib/features/ipos/models/ipo_models.dart:L38-70`<br>`backend/src/modules/ipos/ipos.service.ts:L41-57` | **HIGH** | Update `IpoSummary.fromJson` to accept `company_name`, `opens_at`, `closes_at`, `total_shares` | Member 1 |
| **7** | **Wallet Transaction Model** | Returns `available_delta_minor`, `reserved_delta_minor`, `created_at`, `reference_id`, `reference_type` | Expects `amount_minor`, `createdAt`, `referenceId`, `referenceType` | `mobile/lib/features/wallet/models/wallet_models.dart:L87-100`<br>`backend/src/modules/wallet/ledger.ts:L44-57` | **HIGH** | Update `WalletTransaction.fromJson` to read `created_at`, `reference_id`, and derive amount from deltas | Member 1 |
| **8** | **Status Enum Casing** | Returns lowercase snake_case: `open`, `active`, `posted`, `test_fund_credit` | Evaluates uppercase: `OPEN`, `ACTIVE`, `RESERVATION`, `POSTED` | `mobile/lib/features/ipos/models/ipo_models.dart:L99`<br>`mobile/lib/features/wallet/models/wallet_models.dart:L128-134` | **MEDIUM** | Standardize enum parsing to case-insensitive comparison or lowercase mapping in client models | Member 1 |
| **9** | **Pagination Envelope & Query Params** | Enveloped in `pagination: { page, page_size, total }`. Query accepts `page`, `page_size` | Expects `total`, `pageSize` at root. Sends query param `pageSize` | `mobile/lib/features/ipos/models/ipo_models.dart:L236-247`<br>`backend/src/http/validate.ts:L11-15` | **MEDIUM** | Read metadata from `json['pagination']`; send `page_size` in query params | Member 1 |
| **10** | **Error Format Handling** | Returns `{ error: { code, message, details, request_id } }` | Expects `{ message, error: "STRING_CODE", errors: { ... } }` | `mobile/lib/core/network/api_client.dart:L217-236`<br>`backend/src/http/error-handler.ts:L31-48` | **MEDIUM** | Update `ApiClient._mapHttpError` to parse nested `body['error']` object | Member 1 |
| **11** | **Server Logout Endpoint** | Stateless JWT. No `/auth/logout` endpoint in backend | Mobile attempts `POST /auth/logout` | `mobile/lib/features/auth/repositories/live_auth_repository.dart:L79`<br>`backend/src/modules/auth/auth.routes.ts` | **LOW** | Handle logout client-side by clearing tokens; omit server request or make it non-failing | Member 1 |
| **12** | **Admin Review Endpoints** | Review endpoints not implemented in Phase 1 baseline | Admin web expects `/admin/users`, `/admin/ipos/:id/approve`, etc. | `admin/lib/features/ipos/repositories/mock_ipo_repository.dart`<br>`docs/API_SPECIFICATION.md:§7` | **PHASE 2** | Implement admin review routes in Phase 2 Day 3–4 | Member 2 |

---

## 4. Recommended Alignment Strategy

### Core Principles
1. **Preserve the Backend Specification:**
   The backend API specification (`docs/API_SPECIFICATION.md`) is aligned with PostgreSQL column names, standard REST envelopes, and security constraints. Changing backend database columns or endpoint structures would risk breaking existing migrations and ledger triggers.
2. **Client-Side Model Adaptation:**
   The mobile application's serialization layer (`fromJson` / `toJson`) should be adapted to seamlessly parse backend snake_case schemas while retaining internal Dart naming conventions and backward compatibility with mock tests.
3. **Execution Order:**
   - Step 1: Adapt mobile `ApiClient` error handling and envelope unwrapping.
   - Step 2: Adapt mobile model `fromJson` and `toJson` methods.
   - Step 3: Run mobile test suite (`flutter test`) to verify mock tests continue to pass.
   - Step 4: Validate against live backend during Phase 2 Day 3 integration.
