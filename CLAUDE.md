# Data Guardian — MVP (Claude Code Session Memory)

## Package & App Identity
- App name: **Data Guardian**
- Package ID: `com.dataguardian.app`
- Flutter SDK: 3.22.x | Dart: ^3.4.0
- Android minSdk: 23 | targetSdk: 34 | compileSdk: 35 (current project uses 35)

## Architecture
Clean Architecture — 4 layers:
1. **Presentation**: Flutter widgets + Riverpod providers + GoRouter
2. **Domain**: Use cases + entities (Freezed) + repository interfaces + service interfaces
3. **Data**: Repository impls + Hive adapters + MethodChannel bridges
4. **Platform (Android)**: Kotlin — `NetworkStatsChannel.kt`, `UsageStatsChannel.kt`

## Platform Channels
- `com.dataguardian/network_stats` → `NetworkStatsChannel.kt`
- `com.dataguardian/usage_stats` → `UsageStatsChannel.kt`

## Key Locked Decisions (do not change without explicit instruction)
- State management: **flutter_riverpod ^2.5.1**
- DI: **get_it ^7.7.0 + injectable ^2.4.2**
- Storage structured: **hive_flutter ^1.1.0** (Hive boxes: app_usage_records, daily_usage_summaries, alert_records)
- Storage key-value: **shared_preferences ^2.2.3** (UserPreferences stored as JSON under key 'user_preferences')
- Navigation: **go_router ^14.2.7**
- Charts: **fl_chart ^0.68.0**
- Background service: **flutter_background_service ^5.0.5** (foregroundServiceType=dataSync, 15-min polling)
- Code gen: freezed ^2.5.2 + hive_generator ^2.0.1 + injectable_generator ^2.4.1 + riverpod_generator ^2.4.0
- Theme: Material 3, seed color `Color(0xFF1A56DB)`, dark mode supported

## Hive Type IDs
- AppUsageRecord: 0 | DailyUsageSummary: 1 | AlertRecord: 2 | AlertType enum: 3 | DateTime adapter: 200

## Feature Requirements (beyond original brief)
1. **Wi-Fi data**: Track alongside mobile. `AppUsageRecord` has `mobileForegroundBytes`, `mobileBackgroundBytes`, `wifiForegroundBytes`, `wifiBackgroundBytes`. UI: stacked progress bar (blue=mobile, green=Wi-Fi). User can toggle view between mobile/Wi-Fi sort.
2. **No package names shown** in any UI list.
3. **Custom date range** on App Usage screen: date picker capped at 4 months back (`AppConstants.maxDateRangeMonths = 4`).
4. **Zero-usage apps hidden**: `GetAppUsageUseCase` filters out apps where selected metric bytes == 0.
5. **Grouped list**: personal apps first, then system apps. `AppUsageRecord.isSystemApp` flag set by Kotlin.

## Colors
- Mobile data: `Color(0xFF1A56DB)` (blue)
- Wi-Fi data: `Color(0xFF10B981)` (green)
- Background data: `Color(0xFFF59E0B)` (amber)

## Onboarding Flow (7 steps)
1. Welcome → 2. Usage Access Explain → 3. Verification (auto-poll) → 4. Notification Permission → 5. Billing Cycle → 6. Complete

## Phase Status
- [x] Phase 0 — Pre-implementation planning
- [x] Phase 1 — Foundation scaffold (this session)
- [ ] Phase 2 — Platform channels (full Kotlin implementations)
- [ ] Phase 3 — Data & domain layer (full repo impls, use cases, tests)
- [ ] Phase 4 — Onboarding (screens already stubbed; full polish + widget tests)
- [ ] Phase 5 — Core screens (Dashboard, App Usage, Background Usage, Alerts)
- [ ] Phase 6 — Background service & notifications
- [ ] Phase 7 — Polish, error states, analytics, tests

## Running build_runner
```
dart run build_runner build --delete-conflicting-outputs
```

## Current State
- `flutter analyze lib/` → 0 issues
- All Freezed models generated (`.freezed.dart` + `.g.dart`)
- Hive adapters registered in `HiveService`
- GoRouter wired with all routes (screens are stubs until Phase 5)
- Onboarding screens: WelcomeScreen, UsageAccessScreen, AccessVerificationScreen, NotificationPermissionScreen, BillingCycleScreen, OnboardingCompleteScreen — all implemented
- Android: new package `com.dataguardian.app`, `NetworkStatsChannel.kt` + `UsageStatsChannel.kt` stub in place
- PoC code archived to `_poc/`
