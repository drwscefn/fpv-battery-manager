# LIPO MGR

A focused Android app for FPV pilots who want to track the health of their LiPo battery packs over time — without cloud accounts, subscriptions, or unnecessary complexity.

---

## Features

| Feature | Detail |
|---|---|
| **Battery registry** | Add packs with label, cell count, capacity, and optional notes |
| **QR identity stickers** | Each battery gets a UUID-based QR code. Print it, stick it on the pack, scan it to instantly identify the battery and jump to the log screen |
| **Charger OCR** | Point the camera at your charger's balance screen after a session. ML Kit reads the individual cell voltages and IR values automatically |
| **Charge log history** | Every session is stored with voltages, IR, log type (POST-CHARGE / POST-FLIGHT / STORAGE), and optional notes |
| **Health flags** | Automatic warnings for high IR, rising IR trend, cell imbalance, and low resting voltage |
| **Charts** | Line charts per battery: IR trend per cell, pack voltage over time, cell balance (max − min) |
| **Duplicate battery** | Long-press any battery on the home screen → Duplicate to copy specs to a new entry. Saves time when setting up multiple identical packs |
| **Long-press actions** | Long-press on home screen opens a quick action sheet: Open, Charts, Rename, Duplicate, Delete |
| **QR print helper** | Choose a print size (25 mm / 50 mm / 75 mm), save to gallery, then print from any printer app |
| **All data local** | SQLite database on-device. No account, no cloud, no tracking |

---

## Supported Chargers

OCR uses three strategies in priority order. Most displays are covered without any configuration.

| Charger | Voltages | IR | Format example |
|---|---|---|---|
| **ToolkitRC M6D** (dual channel) | ✅ | ✅ | `14.192V` = C1 @ 4.192 V |
| **ToolkitRC M8 / M6** (single channel) | ✅ | ✅ | Same cell-prefix format |
| **ISDT Q6 Plus / Q8** | ✅ | ✅ | `S1 4.190V` / `S1: 4.190V` |
| **HOTA D6 Pro** | ✅ | ✅ | `1: 4.190V  14mΩ` |
| **SkyRC S65 / S100 / S150** | ✅ | ✅ | `C1 4.190V` |
| **Junsi iCharger 308 / 4010** | ✅ | ✅ | `01 4.192V  12mΩ` |
| **Any other charger** | ✅ | ⚠️ | Sequential bare voltages (fallback) — IR only if units are visible |

> **OCR tips**
> - Shoot in good lighting with the phone parallel to the screen
> - Fill the framing box with just the balance/cell section of the display
> - Tap the shutter button; a confirmation screen lets you correct any OCR errors before saving
> - If your charger isn't in the table above, the bare-voltage fallback usually picks up cell values fine — just verify the count on the confirm screen

---

## Installation

Download the latest APK from [Releases](https://github.com/drwscefn/fpv-battery-manager/releases) and install it. You will need to allow installation from unknown sources on Android.

Minimum Android version: **5.0 (API 21)**

Required permissions:
- **Camera** — charger OCR and QR scanning

---

## Typical Workflow

```
1. Add battery
   Home screen → [+] → fill in label (e.g. "RACE 1"), cells, capacity

2. Print identity sticker
   Battery detail → QR icon → choose size → Save to Gallery → print

3. Log a session
   Home screen → [scan] → point at QR sticker on the pack → camera opens
   — OR —
   Home screen → tap battery → LOG CHARGE
   
   Point camera at charger balance screen → tap shutter → confirm values → 
   choose POST-CHARGE / POST-FLIGHT / STORAGE → Save

4. Review health
   Battery detail shows health flags and full log history
   Tap the chart icon (📊) for trend graphs

5. Identify a pack quickly
   Home screen → [scan] → point at QR sticker → jumps straight to log capture
```

---

## Building from Source

**Prerequisites**
- Flutter SDK ≥ 3.24 (on `X:\flutter` in this repo's `local.properties`)
- Android SDK with build-tools for API 35
- JDK 21
- Gradle 8.9 (downloaded automatically via wrapper)

```bash
git clone https://github.com/drwscefn/fpv-battery-manager.git
cd fpv-battery-manager

# Update android/local.properties with your SDK and Flutter paths
flutter pub get
flutter build apk --release
```

The APK lands at `build/app/outputs/flutter-apk/app-release.apk`.

**Database migrations** — the schema version is in `lib/core/database/database.dart`. When adding columns, bump `schemaVersion` and add an `onUpgrade` branch.

**Code generation** — Drift and Riverpod use build_runner:
```bash
dart run build_runner build --delete-conflicting-outputs
```

---

## Architecture

```
lib/
  app.dart                    GoRouter config (nested routes for correct back-stack)
  main.dart
  core/
    database/                 Drift SQLite — Batteries + ChargeLogs tables
    health/                   Health flag computation (IR, imbalance, voltage)
    models/                   LogType enum, HealthFlag
    ocr/                      ML Kit text recognition + multi-charger parser
    theme/                    AppColors, AppTheme (dark, Share Tech Mono)
  features/
    battery_list/             Home screen + long-press action sheet
    add_battery/              New battery form
    battery_detail/           History list, health card, AppBar actions
    charts/                   fl_chart graphs (IR, voltage, balance)
    log_charge/               Capture → Confirm → Save flow
    print_label/              QR display with size picker, save/share
    settings/                 Thresholds (editable IR and voltage limits)
    battery_list/qr_scan/     Camera QR scanner
```

**Key dependencies**

| Package | Purpose |
|---|---|
| `drift` | Type-safe SQLite ORM |
| `flutter_riverpod` | State management |
| `go_router` | Declarative navigation (nested for proper back-stack) |
| `google_mlkit_text_recognition` | On-device OCR |
| `google_mlkit_barcode_scanning` | QR code scanning |
| `camera` | Camera preview and capture |
| `qr_flutter` | QR code rendering |
| `fl_chart` | Line charts |
| `gal` | Save images to Android gallery |
| `share_plus` | Share sheet for QR images |

---

## Health Thresholds

Defaults (editable in Settings):

| Flag | Default trigger |
|---|---|
| High IR | Any cell > 30 mΩ |
| Rising IR trend | Mean IR increased > 5 mΩ over last 5 logs |
| Cell imbalance | Max − min cell voltage > 0.05 V |
| Low resting voltage | Any cell < 3.75 V on a POST-FLIGHT log |

---

## Contributing

Issues and pull requests are welcome. For OCR improvements, include a photo of the charger display (with battery model in the issue title) — it makes pattern testing much easier.

---

## License

MIT
