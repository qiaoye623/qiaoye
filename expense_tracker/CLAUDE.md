# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Test Commands

```bash
# Install dependencies
flutter pub get

# Analyze all Dart code for errors/warnings
flutter analyze

# Run all tests
flutter test

# Run a single test file
flutter test test/widget_test.dart

# Run on web (headless server mode)
flutter run -d web-server --web-hostname 127.0.0.1 --web-port 8080

# Run on Chrome
flutter run -d chrome

# Build Windows release exe
flutter build windows --release

# Build Android APK
flutter build apk --release

# Add a new package dependency
flutter pub add <package_name>
```

## Architecture Overview

### State Management
Provider (`ChangeNotifier`) pattern. Four providers via `MultiProvider` in `lib/main.dart`:

- **LedgerProvider** — ledger list CRUD, current ledger selection, enforces min 1 / max 20
- **TransactionProvider** — transactions filtered by current ledger, monthly navigation, category/daily summaries
- **AssetAccountProvider** — asset accounts CRUD, balance updates on transaction
- **SaveProvider** — save plans CRUD, save records with done/cancel, plan type calculations (365/52week/12deposit/elastic/flexible)

All providers call `DatabaseHelper()` singleton for data access.

### Database Layer (Dual Platform)

`lib/database/database_helper.dart` re-exports:
- Native (mobile/desktop): `database_helper_sqlite.dart` — sqflite + sqflite_common_ffi (SQLite v8 schema)
- Web: `database_helper_web.dart` — sembast

6 tables:
- `categories` — name, icon, type (seeded with 10 expense + 5 income defaults)
- `transactions` — amount, type, categoryId, categoryName, categoryIcon, note, date, ledgerId, accountId, createdAt
- `ledgers` — name, icon, isDefault, sortOrder, createdAt
- `asset_accounts` — name, icon, type (wallet/cash), balance, isDefault
- `save_plans` — name, type, start_amount, duration_days, increment_coeff, month_amount, total_target, current_amount, icon_code, start_date, status
- `save_records` — plan_id, sequence_index, target_amount, saved_amount, status (pending/done), saved_date, created_at

DB singleton uses `_initFuture` lock pattern to prevent concurrent initialization races.

Models (`lib/models/`): `Transaction`, `Category`, `Ledger`, `AssetAccount`, `SavePlan`, `SaveRecord` — all with `toMap()`, `fromMap()`, `copyWith()`.

### Screen Structure (`lib/screens/`)

Bottom nav via `MainShell` (IndexedStack + custom BottomAppBar, default tab=1):
1. **LedgerTab** — grid of ledger cards with Slidable (edit/delete), add dialog
2. **DetailsTab** — month navigation, summary bar, 4-grid menu (statistics/calendar/assets/search), recent list, FAB
3. **ProfileTab** — user card, grouped menu (功能/设置/数据/其他)

Sub-screens:
- `AddTransactionScreen` / `EditTransactionScreen` — type toggle (expense/income), amount, category grid, date picker, note, account selector
- `LedgerDetailScreen` — single ledger with filtered transactions
- `AssetAccountScreen` — full asset account management with total net assets card
- `CategoryManageScreen` — add/edit/delete expense & income categories
- `AnnualBillScreen` — yearly summary with income/expense charts
- `QrCodeScreen` — QR code display (contact info)
- `SaveHomeScreen` — save plan list with progress
- `SaveDetailScreen` — plan detail with date grid
- `SaveCreatePopup` / `SaveTypePopup` / `SaveTypeDetailScreen` — plan creation flow

### Windows Desktop Build

- Window default size set in `windows/runner/main.cpp` — currently 400×780 for phone-aspect display
- `sqlite3.dll` is bundled from `sqflite_common_ffi` package to `windows/runner/`
- CMake install rule in `windows/CMakeLists.txt` copies it to the release build output
- Requires Visual Studio Build Tools 2022

### Theme (`lib/utils/constants.dart`)
- Primary #1677FF, income #52C41A, expense #F5222D, text #333/#666/#999, bg #F5F7FA
- `formatAmount()` → "¥xx.xx"
- DefaultCategories: 10 expense + 5 income with emoji icons

### Key Widgets (`lib/widgets/`)
- `TransactionListItem` — reusable transaction row with onTap/onDelete
- `CalendarView` — month grid with daily dots, today highlight
- `StatisticsChart` — pie chart with legend

### CI (codemagic.yaml)
- Two workflows: android-release (APK + AAB) and ios-release (IPA via --no-codesign)
- Trigger: push to master or release/* branches

## Key Conventions

- Provider: `context.watch<T>()` for rebuilds, `context.read<T>()` for actions
- Always pass `ledgerId` in transaction DB queries for multi-ledger isolation
- Material 3 enabled, Chinese (zh_CN) default locale
- Use `const` constructors where possible
- DB singleton — call `DatabaseHelper()` anywhere (handles platform selection automatically)
- Windows release builds require `sqlite3.dll` next to the executable (bundled via CMake install)
