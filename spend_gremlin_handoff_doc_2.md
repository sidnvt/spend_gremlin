# Spend Gremlin — Handoff Doc 2 (Current State)

## Snapshot
- Project path: `~/spend_gremlin`
- Platform target: Android (Flutter)
- Build status: `flutter build apk --debug` succeeds
- Exported APK: `~/spend_gremlin/spend_gremlin_v1.apk`

---

## What was completed in this phase

### 1) Core data + DB
- Drift schema includes:
  - `Categories`
  - `Expenses`
  - `AppSettings`
- Added **per-category warning limits** (`Categories.limitCents`).
- DB migration to schema version `2` adds `limitCents` for existing installs.
- Seed defaults:
  - Food: `₹800`
  - Travel: `₹500`
  - Misc: `₹100`
  - New custom category default: `₹250`

### 2) Dashboard behavior
- Ring supports `daily / weekly / monthly` view and now uses correct aggregation window.
- Ring overflow behavior changed per request:
  - **No red overflow arc** anymore
  - Ring is capped visually at 100% in green
- Daily-limit exceeded banner remains as warning text block.
- Category cards now show red warning state for **any category** that exceeds its own `limitCents`.

### 3) Add expense flow
- Center `+` opens bottom sheet.
- Category picker now shows:
  - Core categories
  - **All custom categories** (not just one)
  - Misc row + New category
- Expense form:
  - Amount required
  - Optional name
  - Include toggle

### 4) Day detail/history
- Date tabs + Food/Travel sections.
- Per-expense include/exclude micro-toggle.
- Inline add expense for core categories.
- Long-press expense item deletes it.

### 5) Settings
- Global limits: daily/weekly/monthly.
- New section: **category warning limits** for each category (editable).
- Include/exclude master toggles per category type.
- Custom categories list with remove action.
- Misc category limit update also syncs legacy `AppSettings.miscLimitCents`.

### 6) Insights
- Streak, trend bars, category split, forecast, heatmap, misc creep are populated from DB.

---

## Key files for next agent

### App shell and routing
- `lib/main.dart`
- `lib/src/app.dart`
- `lib/src/router/app_router.dart`
- `lib/src/features/shell/nav_shell_screen.dart`

### Theme and shared utils
- `lib/src/core/app_theme.dart`
- `lib/src/core/app_colors.dart`
- `lib/src/core/app_typography.dart`
- `lib/src/core/money.dart`

### Database and providers
- `lib/src/data/db/tables.dart`
- `lib/src/data/db/app_db.dart`
- `lib/src/data/db/daos.dart`
- `lib/src/data/providers.dart`
- `lib/src/features/common/app_providers.dart`

### Feature screens
- `lib/src/features/splash/splash_screen.dart`
- `lib/src/features/dashboard/dashboard_screen.dart`
- `lib/src/features/dashboard/widgets/spend_ring.dart`
- `lib/src/features/expenses/add_expense_sheet.dart`
- `lib/src/features/history/day_detail_screen.dart`
- `lib/src/features/settings/settings_screen.dart`
- `lib/src/features/insights/insights_screen.dart`

---

## Build and run commands

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter build apk --debug
```

APK outputs:
- Standard: `build/app/outputs/flutter-apk/app-debug.apk`
- Export copy: `spend_gremlin_v1.apk`

---

## Product rules currently implemented
- Food and Travel are core categories.
- Misc is separate category with warning based on its own limit.
- Custom categories are unlimited and user-creatable.
- Ring total uses include flags:
  - category include toggle
  - per-item include toggle
- Category warnings are per-category and independent from ring overflow.

---

## Notes for future extension
- If required later, `AppSettings.miscLimitCents` can be fully deprecated in favor of category-level limits only.
- If stricter delete rules are wanted, block deleting categories with existing expenses or auto-migrate those expenses to Misc.

