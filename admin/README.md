# Dirsha Admin Dashboard

**Flutter Web admin dashboard for the Dirsha Ethiopian digital investment platform.**  
Phase 1 — Foundation and Primary Market MVP.

> ⚠️ This is a Phase 1 prototype. All data is mock/demo data. No real backend
> connection is active. See [Mock / API Boundary](#mock--api-boundary) below.

---

## Quick Start

```bash
# 1. Make sure Flutter is installed
flutter --version   # requires 3.x or later

# 2. Install dependencies
cd admin/
flutter pub get

# 3. Run in Chrome (demo mode — no backend needed)
flutter run -d chrome

# 4. Sign in with demo credentials:
#    Email:    admin@dirsha.dev
#    Password: demo1234
```

---

## Running with a Backend

```bash
# Point to your local backend (Member 2's Node.js API):
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:3000

# Build for web deployment:
flutter build web --dart-define=API_BASE_URL=https://your-backend-url
```

The API base URL defaults to `http://localhost:3000` if not set.  
**Never hardcode a production URL in source code.**

---

## Pages Implemented (Phase 1)

| Page | Route | Status | Data Source |
|------|-------|--------|-------------|
| Sign In | `/sign-in` | ✅ Done | Mock auth |
| Dashboard | `/dashboard` | ✅ Done | Mock data |
| User Reviews | `/user-reviews` | ✅ Done | Mock data |
| User Detail | `/user-reviews/:id` | ✅ Done | Mock data |
| Company Reviews | `/company-reviews` | ✅ Done | Mock data |
| Company Detail | `/company-reviews/:id` | ✅ Done | Mock data |
| IPO Management | `/ipo-management` | ✅ Done | Mock data |
| IPO Detail & Review | `/ipo-management/:id` | ✅ Done | Mock data |
| Audit / Activity | `/audit` | ✅ Placeholder | Endpoint not yet available |

---

## Mock / API Boundary

All pages currently use **mock repositories**. Every page with mock data
shows a clearly visible yellow **"DEVELOPMENT MODE"** banner.

To connect a page to a real backend endpoint:

1. Create `ApiXxxRepository` implementing the existing `XxxRepository` interface
2. Swap the injection in `lib/main.dart`
3. Remove the mock banner from that page

See `PHASE_1_QA.md` for the full list of missing endpoints and their owners.

---

## Project Structure

```
lib/
├── core/
│   ├── theme/          # AppColors + AppTheme (Ethiopian Emerald palette)
│   ├── config/         # AppConfig (API URL, mock flag)
│   ├── routing/        # GoRouter setup + AppRoutes constants
│   ├── network/        # ApiClient + ApiException
│   └── widgets/        # AppShell (sidebar + top bar)
├── features/
│   ├── auth/           # Sign-in, AdminAuthProvider, AuthService interface
│   ├── dashboard/      # Dashboard overview screen
│   ├── users/          # User review list + detail
│   ├── companies/      # Company review list + detail
│   ├── ipos/           # IPO list + detail + approve/reject
│   └── audit/          # Audit placeholder
└── shared/
    └── widgets/        # StatusBadge, LoadingIndicator, EmptyState,
                        # ErrorState, ConfirmationDialog, MockBanner, InfoCard
```

---

## Design System

**Ethiopian Emerald palette** — all colors centralized in `lib/core/theme/app_colors.dart`.

| Token | Hex | Usage |
|-------|-----|-------|
| Primary (Deep Emerald) | `#064E3B` | Buttons, active nav |
| Primary Light (Emerald Green) | `#047857` | Secondary actions |
| Accent (Ethiopian Gold) | `#D4A72C` | Logo, decorative accents |
| Background (Warm Ivory) | `#F8FAF5` | Page backgrounds |
| Surface (White) | `#FFFFFF` | Cards, dialogs, tables |
| Text Primary (Deep Charcoal) | `#17231F` | Body text |
| Text Secondary (Muted Green-Gray) | `#64756C` | Labels, secondary text |
| Border (Soft Sage) | `#DCE5DD` | Dividers, input borders |
| Success (Forest Green) | `#15803D` | Approved, success states |
| Error (Deep Red) | `#B91C1C` | Rejected, error states |

---

## Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| `go_router` | ^14.6.2 | Navigation + route guards |
| `provider` | ^6.1.2 | State management |
| `http` | ^1.2.2 | API HTTP client |
| `shared_preferences` | ^2.3.3 | Local session persistence |

---

## Analysis

```bash
flutter analyze   # Should report: No issues found
```

---

## Phase 2 Next Steps

1. Member 2 confirms and publishes API endpoint contracts
2. Replace `MockAuthService` with `ApiAuthService`
3. Replace each `Mock*Repository` with `Api*Repository`
4. Remove mock banners from API-backed pages
5. Run Phase 2 end-to-end QA checklist (see `PHASE_1_QA.md`)
