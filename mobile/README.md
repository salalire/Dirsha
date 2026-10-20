# Dirsha Mobile — Phase 1

Flutter investor-facing application for the Dirsha Ethiopian digital investment platform.

**Phase:** 1  
**Flutter:** 3.44.7 · **Dart:** 3.12.2  
**Status:** Foundation complete, mock repositories active, backend integration pending Member 2 API confirmation.

---

## Contents

1. [Quick start](#quick-start)
2. [Environment configuration](#environment-configuration)
3. [Project structure](#project-structure)
4. [Design system](#design-system)
5. [Architecture](#architecture)
6. [Mock vs live data](#mock-vs-live-data)
7. [Authentication status](#authentication-status)
8. [API endpoints used](#api-endpoints-used)
9. [Quality checks](#quality-checks)
10. [Known limitations and blockers](#known-limitations-and-blockers)
11. [Phase 2 readiness](#phase-2-readiness)

---

## Quick start

```bash
# 1. Install dependencies
cd mobile
flutter pub get

# 2. Run with mock repositories (default — no backend required)
flutter run

# 3. Run against a local backend (replace URL with Member 2's address)
flutter run \
  --dart-define=DIRSHA_API_BASE_URL=http://10.0.2.2:3000/api \
  --dart-define=DIRSHA_ENV=development \
  --dart-define=DIRSHA_USE_MOCKS=false
```

> **Android emulator note:** `10.0.2.2` is the Android emulator's alias for `localhost` on the host machine. Use the actual IP address for a physical device.

### Mock login credentials

When running with mock repositories (default), use:

| Field    | Value                  |
|----------|------------------------|
| Email    | `investor@dirsha.dev`  |
| Password | `Demo1234!`            |

These credentials only work against the mock repository. They are not real account credentials.

---

## Environment configuration

Configuration is injected at compile time via `--dart-define`. No secrets are stored in source code.

| Variable               | Default                        | Description                                      |
|------------------------|--------------------------------|--------------------------------------------------|
| `DIRSHA_API_BASE_URL`  | `http://localhost:3000/api`    | Backend API base URL. Must be set for live mode. |
| `DIRSHA_ENV`           | `development`                  | `development`, `staging`, or `production`.       |
| `DIRSHA_USE_MOCKS`     | `true`                         | `true` = mock repos; `false` = live API.         |

**Production build example:**

```bash
flutter build apk \
  --dart-define=DIRSHA_API_BASE_URL=https://api.dirsha.com/api \
  --dart-define=DIRSHA_ENV=production \
  --dart-define=DIRSHA_USE_MOCKS=false
```

The mock data banner (`MOCK DATA — Not connected to live API`) is displayed on every screen while `DIRSHA_USE_MOCKS=true`. It is never shown in production builds.

---

## Project structure

```
mobile/
├── lib/
│   ├── main.dart                        # App entry point and composition root
│   ├── core/
│   │   ├── config/app_config.dart       # Compile-time env configuration
│   │   ├── errors/app_exception.dart    # Sealed exception hierarchy
│   │   ├── network/
│   │   │   ├── api_client.dart          # Dio wrapper — central HTTP client
│   │   │   └── auth_interceptor.dart    # Bearer token injection + refresh
│   │   ├── theme/
│   │   │   ├── app_colors.dart          # Official Dirsha color palette
│   │   │   ├── app_text_styles.dart     # Typography hierarchy (Inter)
│   │   │   └── app_theme.dart           # Full dark emerald ThemeData
│   │   └── utils/formatters.dart        # Currency, date, compact formatters
│   ├── features/
│   │   ├── auth/
│   │   │   ├── models/auth_models.dart
│   │   │   ├── providers/auth_provider.dart
│   │   │   ├── repositories/
│   │   │   │   ├── auth_repository.dart       # Interface
│   │   │   │   ├── mock_auth_repository.dart  # Development mock
│   │   │   │   └── live_auth_repository.dart  # Live (inactive)
│   │   │   └── screens/
│   │   │       ├── login_screen.dart
│   │   │       └── register_screen.dart
│   │   ├── home/
│   │   │   └── screens/home_screen.dart  # Dashboard + bottom nav (3 tabs)
│   │   ├── ipos/
│   │   │   ├── models/ipo_models.dart
│   │   │   ├── providers/ipo_provider.dart
│   │   │   ├── repositories/
│   │   │   │   ├── ipo_repository.dart
│   │   │   │   ├── mock_ipo_repository.dart
│   │   │   │   └── live_ipo_repository.dart
│   │   │   └── screens/
│   │   │       ├── ipo_list_screen.dart
│   │   │       └── ipo_detail_screen.dart
│   │   └── wallet/
│   │       ├── models/wallet_models.dart
│   │       ├── providers/wallet_provider.dart
│   │       ├── repositories/
│   │       │   ├── wallet_repository.dart
│   │       │   ├── mock_wallet_repository.dart
│   │       │   └── live_wallet_repository.dart
│   │       └── screens/wallet_screen.dart
│   ├── router/app_router.dart           # GoRouter with auth guard
│   └── shared/widgets/                  # Reusable components
│       ├── widgets.dart                 # Barrel export
│       ├── dirsha_button.dart
│       ├── dirsha_text_field.dart
│       ├── status_badge.dart
│       ├── loading_indicator.dart
│       ├── empty_state.dart
│       ├── error_state.dart
│       ├── section_header.dart
│       ├── confirmation_dialog.dart
│       └── mock_data_banner.dart
└── test/
    ├── widget_test.dart
    ├── features/auth/
    │   ├── auth_models_test.dart
    │   └── mock_auth_repository_test.dart
    ├── features/ipos/
    │   ├── ipo_models_test.dart
    │   └── mock_ipo_repository_test.dart
    ├── features/wallet/
    │   ├── wallet_models_test.dart
    │   └── mock_wallet_repository_test.dart
    └── shared/
        └── status_badge_test.dart
```

---

## Design system

The default theme is **Dark Emerald Fintech**. All values are defined in `lib/core/theme/`.

### Color palette

| Token                  | Hex       | Usage                                      |
|------------------------|-----------|--------------------------------------------|
| `brandEmerald`         | `#064E3B` | Primary brand — gradients, avatars         |
| `secondaryEmerald`     | `#047857` | Primary actions, focused borders           |
| `deepForest`           | `#022C22` | Deep background gradients                  |
| `backgroundPrimary`    | `#080B09` | Screen background                          |
| `backgroundSecondary`  | `#101612` | Navigation bar, sections                   |
| `cardSurface`          | `#141A16` | Default card background                    |
| `cardElevated`         | `#1B241D` | Elevated card, dialog background           |
| `gold`                 | `#D4A72C` | Ethiopian gold accent — use sparingly      |
| `textPrimary`          | `#F5F7F5` | Main readable text                         |
| `textSecondary`        | `#A7B3AA` | Supporting text, labels                    |
| `border`               | `#2A352D` | Card borders, input borders                |
| `success`              | `#22C55E` | Open IPOs, completed transactions          |
| `error`                | `#F87171` | Failures, closed offerings                 |
| `warning`              | `#FBBF24` | Pending, reserved funds                    |
| `info`                 | `#60A5FA` | Draft, informational badges                |

### Typography

Inter (Google Fonts) is used throughout. Financial figures use tabular figures for column alignment. Style definitions are in `AppTextStyles`.

### Shared components

`DirshaButton`, `DirshaTextField`, `StatusBadge`, `LoadingIndicator`, `SkeletonCard`, `EmptyState`, `ErrorState`, `SectionHeader`, `ConfirmationDialog`, `MockDataBanner`.

Import all at once:
```dart
import 'package:dirsha_mobile/shared/widgets/widgets.dart';
```

---

## Architecture

**State management:** Provider (`ChangeNotifier`).  
**Navigation:** GoRouter with auth-guard redirect.  
**HTTP:** Dio via `ApiClient` — never used directly in screens.  
**Token storage:** `FlutterSecureStorage` (Keychain / EncryptedSharedPreferences).  
**Pattern:** Feature-sliced — each feature owns models, repository interface, mock + live implementations, provider, and screens.

### Navigation routes

| Path          | Screen           | Guard        |
|---------------|------------------|--------------|
| `/`           | Splash           | Redirect only|
| `/login`      | Login            | Unauthenticated only |
| `/register`   | Register         | Unauthenticated only |
| `/home`       | Dashboard shell  | Authenticated only |
| `/ipos/:id`   | IPO detail       | Authenticated only |

### Auth flow

1. App starts → `checkAuthStatus()` attempts `GET /users/me`.
2. If the stored token is valid → `AuthStatus.authenticated` → router navigates to `/home`.
3. If no token or 401 → `AuthStatus.unauthenticated` → router navigates to `/login`.
4. If the access token expires mid-session → `AuthInterceptor` attempts refresh automatically. If refresh also fails → `forceSignOut()` → router redirects to `/login`.

---

## Mock vs live data

| Repository         | Current mode | Switch condition                                     |
|--------------------|--------------|------------------------------------------------------|
| Auth               | **MOCK**     | `DIRSHA_USE_MOCKS=false` + Member 2 API confirmed    |
| IPO listing        | **MOCK**     | `DIRSHA_USE_MOCKS=false` + `GET /ipos` available     |
| IPO detail         | **MOCK**     | `DIRSHA_USE_MOCKS=false` + `GET /ipos/:id` available |
| Wallet summary     | **MOCK**     | `DIRSHA_USE_MOCKS=false` + `GET /wallets/me` available |
| Wallet transactions| **MOCK**     | `DIRSHA_USE_MOCKS=false` + `GET /wallets/me/transactions` available |

**Rule:** A network failure is never silently replaced by mock data. The `ErrorState` widget is shown with a retry action. Mock data is only active when explicitly configured.

Mock IPO companies are labeled `[MOCK]` in their names. Mock wallet balances are labeled "Simulated test funds" in the UI. Neither can be mistaken for real data.

---

## Authentication status

| Aspect                          | Status in Phase 1               |
|---------------------------------|---------------------------------|
| Login UI + client validation    | ✅ Implemented                  |
| Registration UI + validation    | ✅ Implemented                  |
| Token storage (secure)          | ✅ FlutterSecureStorage          |
| Token refresh on 401            | ✅ AuthInterceptor               |
| Connected to real backend       | ❌ Pending Member 2 API         |
| Forgot password flow            | ❌ Out of scope for Phase 1     |
| KYC / identity verification     | ❌ Out of scope for Phase 1     |

---

## API endpoints used

All paths below are relative to `DIRSHA_API_BASE_URL`.

| Method | Path                        | Feature         | Status in Phase 1    |
|--------|-----------------------------|-----------------|----------------------|
| POST   | `/auth/register`            | Auth            | ❌ Mock only         |
| POST   | `/auth/login`               | Auth            | ❌ Mock only         |
| POST   | `/auth/logout`              | Auth            | ❌ Mock only         |
| POST   | `/auth/refresh`             | Auth interceptor| ❌ Mock only         |
| GET    | `/users/me`                 | Auth startup    | ❌ Mock only         |
| GET    | `/ipos`                     | IPO listing     | ❌ Mock only         |
| GET    | `/ipos/:id`                 | IPO detail      | ❌ Mock only         |
| GET    | `/wallets/me`               | Wallet balance  | ❌ Mock only         |
| GET    | `/wallets/me/transactions`  | Wallet history  | ❌ Mock only         |

**Awaiting confirmation from Member 2:**
- Exact JSON field names for all responses.
- Error response envelope shape: `{ message, error, statusCode }`.
- Monetary field representation: string vs integer minor units.
- IPO status enum values (all states in the state machine).
- Transaction type and status enum values.
- Pagination envelope shape (`items` or `data`, `total`, `page`, `pageSize`).
- Refresh token rotation strategy.

---

## Quality checks

All checks run from the `mobile/` directory.

| Command           | Result  | Notes                              |
|-------------------|---------|------------------------------------|
| `flutter pub get` | ✅ PASS | All dependencies resolved          |
| `dart format .`   | ✅ PASS | 49 files formatted                 |
| `flutter analyze` | ✅ PASS | 0 issues                           |
| `flutter test`    | ✅ PASS | 75 tests passed, 0 failed          |

**Runtime test:** Cannot be confirmed in this environment (no connected device or emulator). The app must be verified on an Android emulator or physical device before any integration checkpoint.

---

## Known limitations and blockers

### Blockers requiring Member 2

- All live API endpoints — none are connected yet.
- Final JSON field names, status enums, and error response format.
- Refresh token behavior and rotation strategy.
- Monetary value representation (strings vs integer minor units).

### Deferred to Phase 2

- IPO subscription execution — the subscribe button is present but disabled with a clear "Coming in Phase 2" label.
- Portfolio and holdings views.
- Order entry and trading screens.
- Broker-investor relationship screens.
- Wallet reservation confirmation flow.
- WebSocket real-time price/order updates.

### Deferred to Phase 3 or later

- Real-money deposits and withdrawals — out of scope until legal/regulatory review.
- KYC and identity verification.
- Forgot password and email verification.
- Amharic localization (planned, scope TBD with project owner).
- Light theme.
- Full company and broker-facing workflows (investor-only in Phase 1).
- AI educational assistant.

---

## Phase 2 readiness

The following foundations are in place and ready for Phase 2 work:

- **Repository interfaces** (`IpoRepository`, `WalletRepository`, `AuthRepository`) are fully defined. Connecting the live backend requires setting `DIRSHA_USE_MOCKS=false` and confirming field names with Member 2 — no screen rewrites needed.
- **`AuthInterceptor`** handles token refresh automatically. The subscription flow can attach to authenticated requests immediately.
- **`ApiException`** includes an `errorCode` field. The subscription endpoint's `INSUFFICIENT_FUNDS` and `IPO_CLOSED` error codes can be mapped to user-friendly messages without changing the error handling architecture.
- **`WalletProvider`** already distinguishes `availableBalance` from `reservedBalance`. Displaying reserved amounts after subscription is a data-only change.
- **`IpoDetailScreen`** has a disabled subscribe button scaffolded. Enabling it for Phase 2 requires adding a subscription repository and provider — the screen structure does not need to change.
- **Navigation** is route-based (GoRouter). New Phase 2 screens (subscription confirmation, allocation result, order entry) can be added as new routes without modifying existing ones.
- **`StatusBadge.fromString`** maps all agreed IPO and transaction status values. Additional enum values can be added in one place.
