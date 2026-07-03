# Data Guardian

A two-screen Android Flutter app that asks for Usage Access and then displays installed apps with their actual mobile network consumption for the current calendar month.

The Flutter UI talks to native Kotlin through a method channel. Android's `AppOpsManager` checks Usage Access, `PackageManager` lists installed apps, and `NetworkStatsManager` returns received + transmitted mobile bytes grouped by UID.

## Run

Install Flutter and an Android SDK, then run:

```sh
flutter pub get
flutter run
```

On the first screen, open Usage Access settings and enable **Data Guardian**. Returning to the app automatically opens the usage list.

## Android notes

- Requires Android 6.0 (API 23) or newer.
- Android reports network traffic by Linux UID. Apps that share a UID will show the same UID total because the platform cannot split it further.
- `QUERY_ALL_PACKAGES` is required to show the complete installed-app list. Google Play restricts this permission, so a store release needs to satisfy its policy or use a narrower app-discovery scope.
- Some manufacturers delay network-stat updates, so the latest traffic may not appear immediately.
