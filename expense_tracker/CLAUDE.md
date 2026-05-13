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

# Add a new package dependency
flutter pub add <package_name>
```

## Architecture Overview

### State Management
Provider (`ChangeNotifier`) pattern. Three providers via `MultiProvider` in `lib/main.dart`:

- **LedgerProvider** — ledger list CRUD, current ledger selection, enforces min 1 / max 20
- **TransactionProvider** — transactions filtered by current ledger, monthly navigation, category/daily summaries
- **AssetAccountProvider** — asset accounts CRUD, balance updates

### Database Layer (Dual Platform)

`lib/database/database_helper.dart` uses conditional exports:
- Native: `database_helper_sqlite.dart` — sqflite + sqflite_common_ffi
- Web: `database_helper_web.dart` — sembast

`DatabaseHelper` is a singleton. Version 2 schema with 4 tables:
- `transactions` — amount, type, categoryId, categoryName, categoryIcon, note, date, ledgerId, createdAt
- `categories` — name, icon, type (seeded with defaults)
- `ledgers` — name, icon, isDefault, sortOrder, createdAt
- `asset_accounts` — name, icon, type, balance, isDefault

Entry point is `lib/database/database_helper.dart` which re-exports the platform-specific implementation. All DB queries should pass `ledgerId` for multi-ledger filtering.

### Models (`lib/models/`)
- `Transaction` — `{id, amount, type, categoryId, categoryName, categoryIcon, note, date, ledgerId, createdAt}` with toMap/fromMap/copyWith
- `Category` — `{id, name, icon, type}`
- `Ledger` — `{id, name, icon, isDefault, sortOrder, createdAt}`
- `AssetAccount` — `{id, name, icon, type, balance, isDefault}`

### Screen Structure (`lib/screens/`)

Bottom navigation via `MainShell` (IndexedStack + BottomAppBar):
1. **LedgerTab** — grid of ledger cards with Slidable (edit/delete), add dialog
2. **DetailsTab** — month navigation, summary bar, 4-grid menu (statistics/calendar/assets/search), recent list, FAB
3. **ProfileTab** — user card, grouped menu (功能/设置/数据/其他)

Sub-screens:
- `AddTransactionScreen` / `EditTransactionScreen` — type toggle, amount, category grid, date picker, note
- `LedgerDetailScreen` — single ledger view with filtered transactions + delete
- `AssetAccountScreen` — full asset account management

### Theme (`lib/utils/constants.dart`)
- `AppColors` — primary #1677FF, income #52C41A, expense #F5222D, text #333/#666/#999, bg #F5F7FA
- `DefaultCategories` — 10 expense + 5 income seed categories
- `formatAmount()` — formats double to "¥xx.xx"

### Key Widgets (`lib/widgets/`)
- `TransactionListItem` — reusable transaction row with onTap/onDelete
- `CalendarView` — month grid with daily dots, today highlight
- `StatisticsChart` — pie chart with legend

## Key Conventions

- Provider: `context.watch<T>()` for rebuilds, `context.read<T>()` for actions
- Always pass `ledgerId` in transaction DB queries for multi-ledger isolation
- Material 3 enabled, Chinese (zh_CN) localization
- Use `const` constructors where possible
- DB singleton — call `DatabaseHelper()` anywhere
