# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Run the full app (proxy + Flutter) — double-click run.bat or:
.\run.bat

# Run Flutter app only (if proxy already running):
cd app && flutter run -d chrome --web-port 5000

# Start proxy only (for testing):
cd server && python proxy.py

# Analyze Dart code:
cd app && flutter analyze

# Run tests:
cd app && flutter test

# Quick proxy test:
curl http://localhost:3002/

# Kill stale proxy processes:
taskkill /F /IM python*.exe
```

## Architecture (Three-Tier)

### 1. Python Proxy (`server/proxy.py`)
- Standalone HTTP server on `localhost:3002`
- Primary source: `https://yyswz.uhfasuf.com:14949/kj/caiji/amkj.js` (Macau lottery JSON API)
- Fallback: scrapes `0542.com` entry links for `#tmpinfo` div
- 30s in-memory cache, 5s retry delay
- Returns `{"period": "第XX期", "numbers": ["38","14","...","44"], "special": "07"}`
- `GET /` or `/lottery` → draw data; `GET /debug` → raw API dump

### 2. Flutter App (`app/`)
- **Entry**: `lib/main.dart` — `ChangeNotifierProvider<AppState>`
- **State**: `lib/providers/app_state.dart` — single `ChangeNotifier` holds all state
- **Services**: `LotteryFetcher` (HTTP to proxy), `BetParser` (parse user text input), `DrawParser` (parse drawInfo string)
- **Models**: `DateConfig`, `UserBet`, `DailySummary`, `DrawBall`/`DrawResult`
- **Widgets**: `HomeScreen` scaffolds layout → `TopNavBar` + `ConfigPanel` + `UserListView` + `ActionButtons` + `BottomSummaryBar`

### 3. Data Flow
```
yyswz API / 0542.com  →  Python Proxy (:3002)  →  LotteryFetcher  →  AppState
                                                                        ↕
                                                              _recalcUser() + _recalcSummary()
                                                                        ↓
                                                              UI rebuilds via Provider
```

## Key Business Rules

### Zodiac Map (`lib/constants/zodiac_map.dart`)
```
马=[1,13,25,37,49],  蛇=[2,14,26,38],  龙=[3,15,27,39],
兔=[4,16,28,40],     虎=[5,17,29,41],  牛=[6,18,30,42],
鼠=[7,19,31,43],     猪=[8,20,32,44],  狗=[9,21,33,45],
鸡=[10,22,34,46],    猴=[11,23,35,47], 羊=[12,24,36,48]
```

### Wave Colors (in `lottery_fetcher.dart`)
- **红波**: 1,2,7,8,12,13,18,19,23,24,29,30,34,35,40,45,46
- **蓝波**: 3,4,9,10,14,15,20,25,26,31,36,37,41,42,47,48
- **绿波**: 5,6,11,16,17,21,22,27,28,32,33,38,39,43,44,49

### 21:35 Cutoff Rule
- After 21:35 local time, `addUser()` / `addUserWithParsing()` auto-saves current day and advances to next day
- Day snapshots stored in memory (`_savedDays` Map) — lost on page refresh
- History navigation via `switchDate()` saves/loads snapshots

### Bet Parsing (`lib/services/bet_parser.dart`)
- **Number format**: space/comma/slash/hyphen/dot delimited numbers (1-49), e.g. `01 05 12` or `01/05/12`
- **Zodiac format**: "鼠肖各100", "虎兔两肖各50", "包马肖50", "平肖买牛/羊各30"
- **Each syntax**: "各X" sets per-item bet amount, e.g. "01 05 12 各10" = bet 10 on each of 3 numbers

## Win Calculation (`app_state.dart:_recalcUser`)
```
winMoney = (codeHits × rateCode × base) + (zodiacHits × rateZodiac × base)
```
- Code hit: user's bet number matches `drawNo` exactly (zero-padded to 2 digits)
- Zodiac hit: user's bet zodiac matches the zodiac of `drawNo`
- Commission: `totalWin × (commissionPct / 100)`
- Payout: `totalWin - commission`

## Config Defaults
- base=1, rateCode=48, rateZodiac=12, commissionPct=10.0

## Layout Constants (`lib/constants/theme.dart`)
- navBarHeight=50, bottomBarHeight=60, inputHeight=44, buttonHeight=44
- primary=#1677FF, background=#F3F4F6, radius=6, padding=10

## Important Notes
- **No persistence** — all data is in-memory, lost on page refresh
- **Port 5000** for Flutter dev server; **port 3002** for proxy
- Proxy must be running before Flutter app fetches data (app waits 800ms on startup)
- Stale Python processes on port 3002 cause "wrong data" issues — kill them with taskkill
- `run.bat` handles proxy lifecycle automatically
- Only tested on Chrome web — other platforms may have issues
- Test file (`test/widget_test.dart`) is default scaffold code, not adapted to this project
