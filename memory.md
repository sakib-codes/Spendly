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
├── core/         # DB helper
├── data/         # Repository implementations
├── domain/       # Entities (Transaction, Category, Budget)
├── features/     # Feature screens
│   ├── dashboard/     # Home screen
│   ├── transactions/  # Records list, add/edit, details
│   ├── analytics/     # Overview + Budgets tabs
│   ├── settings/      # Settings + Manage Categories
│   ├── categories/    # (unused, categories managed via settings)
│   └── export/        # (unused, export handled via settings)
└── shared/
    ├── providers/     # Riverpod providers
    ├── utils/         # Formatters, icon helpers, export service
    └── widgets/       # GlassCard, PrimaryButton, AppScaffold
```

## Navigation Structure
- **Bottom Navbar**: Home | Records | + (FAB) | Analytics | Settings
- Navbar is a custom floating pill with the FAB centered
- All primary screens use `bottomPadding: 130` for navbar clearance

## Screens & Status

### ✅ Dashboard (Home)
- Greeting + month selector
- Total Balance (with smart decimal formatting)
- Income / Expense summary cards (FittedBox for overflow)
- Spending This Month (donut chart + category breakdown)
- Recent Transactions (top 3, tappable → details)
- Top spending category notification bar

### ✅ Records (Transactions)
- Grouped by date (TODAY, YESTERDAY, etc.)
- Each tile shows icon, title, category, time, amount
- Tappable → Transaction Details screen
- Bottom padding for navbar clearance

### ✅ Add / Edit Transaction
- Toggle: Expense / Income (pill-shaped)
- Amount input: centered, ৳ prefix, max 2 decimal digits
- Title input (text field in GlassCard)
- Category selector → **bottom sheet grid picker** (4 per row, icon + name)
- Date picker → native date picker
- Payment method → **bottom sheet list picker**
- Note field (optional)
- Edit mode: pre-fills all fields from existing transaction

### ✅ Transaction Details
- Back button + "Details" title
- Category icon, title, amount (smart decimals, smaller decimal font)
- GlassCard with: Type, Category, Date, Payment Method, Note
- Edit + Delete action buttons
- Hides duplicate subtitle when title matches category name

### ✅ Analytics
- **Overview tab**: Total Income/Expense cards, Income vs Spending Trend (line chart, last 7 days), Month comparison card
- **Budgets tab**: Per-category budget cards with progress bars, Set Budget bottom sheet

### ✅ Settings
- Manage Categories → navigates to dedicated screen
- Currency selector
- Theme picker (Light/Dark/System)
- First day of month
- Export Data (CSV)
- Clear All Data (with confirmation dialog)
- About section (version, privacy, terms)

### ✅ Manage Categories
- Pill toggle: Expense / Income Categories
- Section header in small caps
- Category tiles: icon, name, transaction count, total amount
- Swipe to delete (Dismissible with confirmation)
- "+ Add Category" inline button
- Add Category bottom sheet: type toggle, name input, icon grid picker

## Implemented Features
- [x] CRUD transactions (add, edit, delete, list)
- [x] Category management (add, list, icon picker)
- [x] Smart currency formatting (no .00 for whole numbers, smaller decimal font)
- [x] Amount input restricted to 2 decimal places
- [x] Dark/Light/System theme support
- [x] Budget setting per expense category
- [x] Budget progress bars
- [x] Spending breakdown donut chart
- [x] Income vs Spending trend line chart (7 days)
- [x] CSV export
- [x] Clear all data
- [x] Month-based filtering on dashboard
- [x] Floating custom bottom navbar

## Known Bugs & Issues

- All previously known bugs and UI/UX issues have been resolved.

## User Preferences & Directives
- Navigation bar selection should highlight only the icon in a pill shape
- "Transactions" renamed to "Records" in navbar
- Reuse existing theme/card designs, don't rewrite from scratch
- Category picker should be grid-based (icon + name), matching Figma
- Dropdowns replaced with bottom sheet popup pickers
- Only show decimals when they actually exist in the number
- Decimal portion should render in a smaller font size on big displays

## Key Constants
- Bottom navbar clearance padding: `130`
- Currency: BDT (৳)
- Amount max decimals: 2
