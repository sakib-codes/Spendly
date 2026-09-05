# Spendly — Agent Context

> Instructions and context for AI agents working on this project.

## Quick Start
```bash
cd /home/sakib360/sakib-codes/Spendly
flutter run  # or hot reload with 'r' in the running terminal
```

## Critical Rules
1. **Never rewrite themes/cards from scratch** — use the existing `AppColors`, `GlassCard`, `PrimaryButton` widgets
2. **Bottom padding = 130** on all primary screen ListViews/ScrollViews (floating navbar)
3. **Currency = BDT (৳)** — use `formatBDT()` from `shared/utils/currency_formatter.dart` for plain text, `formatBDTRich()` for RichText with smaller decimals
4. **Riverpod version note**: This version does NOT have `valueOrNull` — use `.value` or `.whenOrNull(data: (v) => v)` instead
5. **Dropdowns → Bottom sheets**: User prefers popup bottom sheet pickers over native `DropdownButton`
6. **Category picker**: Grid layout (4 per row), icon + label below — NOT a list
7. **No `.00` decimals**: Only show decimal part when the amount actually has fractional value

## Key File Locations

### Screens
| Screen | File |
|--------|------|
| Dashboard | `lib/features/dashboard/presentation/screens/dashboard_screen.dart` |
| Records | `lib/features/transactions/presentation/screens/transactions_screen.dart` |
| Add/Edit | `lib/features/transactions/presentation/screens/add_transaction_screen.dart` |
| Details | `lib/features/transactions/presentation/screens/transaction_details_screen.dart` |
| Analytics | `lib/features/analytics/presentation/screens/analytics_screen.dart` |
| Settings | `lib/features/settings/presentation/screens/settings_screen.dart` |
| Categories | `lib/features/settings/presentation/screens/manage_categories_screen.dart` |

### Providers
| Provider | File |
|----------|------|
| Transactions | `lib/shared/providers/transaction_provider.dart` |
| Categories | `lib/shared/providers/category_provider.dart` |
| Budgets | `lib/shared/providers/budget_provider.dart` |
| Dashboard stats | `lib/shared/providers/dashboard_provider.dart` |
| Theme | `lib/shared/providers/theme_provider.dart` |
| Preferences | `lib/shared/providers/preferences_provider.dart` |

### Core
| File | Purpose |
|------|---------|
| `lib/app/router/app_router.dart` | GoRouter with all routes |
| `lib/app/router/route_names.dart` | Route name constants |
| `lib/app/theme/app_colors.dart` | Color constants |
| `lib/app/theme/app_theme.dart` | ThemeData (light/dark) |
| `lib/shared/widgets/app_scaffold.dart` | Floating navbar scaffold |
| `lib/shared/widgets/glass_card.dart` | Reusable glass card widget |
| `lib/shared/utils/currency_formatter.dart` | `formatBDT()` and `formatBDTRich()` |
| `lib/shared/utils/category_icon_helper.dart` | Icon mapping for categories |

## Entities
- **Transaction**: id, title, amount, type (income/expense), categoryId, date, paymentMethod, note
- **Category**: id, name, icon, type (income/expense/both), createdAt
- **Budget**: id, categoryId, amount, month, year

## TODO — Next Work Items
1. **Wire up category deletion** — add `deleteCategory()` to `CategoryNotifier` and `CategoryRepository`
2. **Fix month filtering on dashboard** — stats should only include transactions from the selected month
3. **Make comparison card dynamic** — calculate real last-month vs current-month spending
4. **Remove debug prints** — clean up `print()` in `budget_provider.dart`
5. **Remove dead code** — unused `formatCurrency`/`formatCurrencyChart` variables in analytics
6. **SnackBar dark mode fix** — ensure SnackBar text color matches dark theme
7. **Amount field text input restriction** — verify `FilteringTextInputFormatter` actually blocks non-numeric characters on all keyboards
