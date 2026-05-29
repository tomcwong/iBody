# iBody — Professional Body Health Monitor

A professional cross-platform health monitoring app built with Flutter.

## Project Structure

```
iBody/
├── iphone/ibody_ios/   ← iPhone app (Flutter, iOS 14+)
└── android/            ← Android app (coming soon)
```

## Features (iPhone)

| Feature | Method | Sensor |
|---|---|---|
| Heart Rate | PPG | Rear camera + flashlight |
| Blood Oxygen (SpO2) | PPG | Rear camera + flashlight |
| Body Temperature | Manual / Bluetooth | Bluetooth BLE thermometer |
| Respiratory Rate | Breathing animation guide | Timer-based |
| Steps & Activity | HealthKit | Accelerometer |
| Sleep Tracking | Manual log | Self-report |
| Stress / HRV | PPG-derived | Rear camera |
| Skin Check | AI photo analysis | Front/rear camera |
| Symptom Diary | Self-report | — |

## Tech Stack

- **Framework:** Flutter 3.22 + Dart 3.3
- **State:** flutter_riverpod
- **Charts:** fl_chart
- **Health:** Apple HealthKit (`health` package)
- **Bluetooth:** flutter_blue_plus
- **Storage:** SQLite (sqflite) + SharedPreferences
- **CI/CD:** GitHub Actions with macOS runner

## Compatibility

- **iOS:** 14.0+ (iPhone 6s and later, released 2015)
- **iPadOS:** 14.0+

## Setup (Mac with Xcode required for iOS builds)

```bash
cd iphone/ibody_ios
flutter pub get
flutter run
```

## Build via GitHub Actions (from Windows)

Push to `main` or `develop` branch and GitHub Actions will:
1. Run on a macOS runner
2. Build the iOS release
3. Create an unsigned IPA artifact (downloadable from Actions tab)

For App Store distribution, add your Apple signing certificates as GitHub Secrets (see `.github/workflows/ios_build.yml` for instructions).

## Design

- **Colors:** Deep navy (#0A1628) + health teal (#00D4AA)
- **Typography:** System SF Pro (native iOS)
- **Design language:** Inspired by iOS 26 Liquid Glass — frosted cards, depth, smooth animations
- **Modes:** Full light and dark mode support

## Disclaimer

iBody is a wellness monitoring tool. Readings are for informational purposes only and are not a substitute for professional medical advice, diagnosis, or treatment. Always consult a qualified healthcare provider for medical concerns.
