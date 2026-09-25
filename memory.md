# Spendly — Project Memory

> Last updated: 2026-09-05

## Project Overview
Spendly is a personal finance tracker app built with **Flutter** targeting Android. It tracks income/expense transactions, provides analytics, budget management, and category organization.

## Tech Stack
- **Framework**: Flutter (Dart)
- **State Management**: Riverpod (`AsyncNotifier`)
- **Routing**: `go_router` with `StatefulShellRoute` (bottom nav persistence)
- **Database**: Local SQLite (via `sqflite`)
- **Charts**: `fl_chart`
- **Architecture**: Clean Architecture (domain → data → presentation)

## Architecture
```
lib/
├── app/          # Router, theme, colors
├── core/         # DB helper, database migrations
├── data/         # Repository implementations (SQLite)
├── domain/       # Entities (Transaction, Category, Budget, RecurringTransaction)
├── features/     # Feature screens
│   ├── auth/          # Firebase Auth (Login, Signup, Password Reset)
│   ├── dashboard/     # Home screen
│   ├── transactions/  # Records list, add/edit, details
│   ├── analytics/     # Overview + Budgets tabs
│   ├── settings/      # Profile, Manage Categories, Subscriptions, Policies
│   ├── sync/          # Cloud syncing logic and provider
│   ├── splash/        # Splash screen with auth routing & pending transaction generator
│   └── export/        # (unused, export handled via settings)
└── shared/
    ├── providers/     # Riverpod providers (AsyncNotifier)
    ├── utils/         # Formatters, category_icon_helper (Material + Assets)
    └── widgets/       # GlassCard, GlassDatePicker, BiometricLockWrapper
```

## Navigation Structure
- **Bottom Navbar**: Home | Records | + (FAB) | Analytics | Profile
- Navbar is a custom floating pill with the FAB centered
- All primary screens use `bottomPadding: 130` for navbar clearance

## Screens & Status

### ✅ Authentication
- Login & Signup screens with glassmorphism design
- Google Sign-In and Password Reset flows
- Profile photo caching via `ProfilePhotoCache`

### ✅ Dashboard (Home)
- Greeting + month selector
- Total Balance (with smart decimal formatting)
- Income / Expense summary cards (FittedBox for overflow)
- Spending This Month (donut chart + category breakdown)
- Recent Transactions (top 3, tappable → details)
- Top spending category notification bar

### ✅ Records (Transactions)
- Grouped by date (TODAY, YESTERDAY, etc.)
- Search bar (hidden by default, revealed on pull-down)
- Filter indicator (visual badge dot on filter icon)
- Each tile shows icon, title, category, time, amount
- Tappable → Transaction Details screen
- Bottom padding for navbar clearance

### ✅ Add / Edit Transaction
- Toggle: Expense / Income (pill-shaped)
- Amount input: centered, ৳ prefix, max 2 decimal digits
- Title input (text field in GlassCard)
- Category selector → **bottom sheet grid picker** (3 per row, supports custom PNG assets)
- Custom Date & Time picker → `GlassDatePicker` and `GlassTimePicker`
- **Repeat Transaction** toggle → exposes frequency options (Daily/Weekly/Monthly/Yearly)
- Payment method → **bottom sheet list picker**
- Note field (optional)
- Edit mode: pre-fills all fields from existing transaction

### ✅ Subscriptions Hub
- Monthly Cost overview card with background blurred orbs and yearly estimate
- List of active subscriptions (category icon, frequency, next charge date, amount)
- Detailed dialog with breakdown and "Cancel Subscription" flow

### ✅ Analytics
- **Overview tab**: Total Income/Expense cards, Income vs Spending Trend (line chart, last 7 days), Month comparison card
- **Budgets tab**: Per-category budget cards with progress bars, Set Budget bottom sheet

### ✅ Settings / Profile
- Biometric App Lock toggle (requires `local_auth` and `FlutterFragmentActivity`)
- Manage Categories → navigates to dedicated screen
- Subscriptions → navigates to subscriptions hub
- Currency selector
- Theme picker (Light/Dark/System)
- Cloud Data Sync (Pull/Push)
- Export Data (CSV)
- Clear All Data & Delete Account (with loading states & confirmation dialogs)
- Help & Support and Terms & Policies (using `CustomHeader`)

### ✅ Manage Categories
- Pill toggle: Expense / Income Categories
- Section header in small caps
- Category tiles: icon, name, transaction count, total amount
- Swipe to delete (Dismissible with confirmation)
- "+ Add Category" inline button
- Add Category bottom sheet: type toggle, name input, expanded icon grid picker supporting 30+ custom PNG icons (`getAllAssets()`)

## Implemented Features
- [x] Firebase Authentication
- [x] Biometric App Lock (Fingerprint/FaceID via `local_auth`)
- [x] Cloud Data Sync (API integration)
- [x] Recurring Transactions engine (auto-generates pending records on app startup)
- [x] Subscriptions hub and management
- [x] Custom PNG asset icons for categories (30+ icons spanning utilities, transport, subscriptions)
- [x] CRUD transactions (add, edit, delete, list)
- [x] Category management (add, list, expanded icon picker)
- [x] Smart currency formatting (no .00 for whole numbers, smaller decimal font)
- [x] Amount input restricted to 2 decimal places
- [x] Dark/Light/System theme support
- [x] Budget setting per expense category
- [x] Budget progress bars
- [x] Spending breakdown donut chart
- [x] Income vs Spending trend line chart (7 days)
- [x] CSV export
- [x] Custom Glassmorphism Date and Time pickers
- [x] Clear all data & Delete Account
- [x] Month-based filtering on dashboard
- [x] Floating custom bottom navbar

## Known Bugs & Issues
- None currently active. The hot-restart caching issue with new static methods (e.g. `getAllAssets`) was resolved by fully restarting the app.

## Upcoming / Potential Features
- Push Notifications/Reminders for upcoming subscriptions or budget limits.
- Multi-currency support (auto-conversion based on exchange rates).
- Export to PDF (currently only CSV is supported).
- Advanced analytics (Yearly views, tag-based grouping).

## User Preferences & Directives
- Navigation bar selection should highlight only the icon in a pill shape
- "Transactions" renamed to "Records" in navbar
- Reuse existing theme/card designs, don't rewrite from scratch
- Category picker should be grid-based (icon + name), matching Figma
- Dropdowns replaced with bottom sheet popup pickers
- Only show decimals when they actually exist in the number
- Decimal portion should render in a smaller font size on big displays
- Destructive actions (like Delete Account or Clear Data) must use red backgrounds and have loading states.

## Key Constants
- Bottom navbar clearance padding: `130`
- Currency: BDT (৳)
- Amount max decimals: 2
