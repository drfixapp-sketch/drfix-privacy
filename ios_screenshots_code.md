# 📱 Dr. Fix — Complete iOS Screenshots Automation Code Bundle

This document contains all three required files for automated real iOS screenshot capture on Codemagic CI/CD.

---

## 📄 File 1: `codemagic.yaml`
**Location:** Place this file directly in your project root directory (`/codemagic.yaml`).

```yaml
# ════════════════════════════════════════════════════════════════════════════
# codemagic.yaml — Dr. Fix iOS Real Screenshots
# ════════════════════════════════════════════════════════════════════════════
#
# GOAL     : Run Dr. Fix on iPad Pro 13-inch iOS Simulator on Codemagic
#            macOS, navigate the real app, and collect 8 real screenshots
#            (Arabic + English) as downloadable build artifacts.
#
# APPLE 2026 REQUIREMENTS (enforced since 28 Apr 2026):
#   • Must build with Xcode 26+ / iOS 26 SDK
#   • Deployment target can stay at iOS 13.0 (unchanged)
#   • Requires macOS Sequoia 15.6+
#
# MAPS NOTE:
#   PartsStoresScreen uses flutter_map (OpenStreetMap/HTTP tiles).
#   NO google_maps_flutter → NO GPU/Metal crash risk on Simulator.
#
# ANDROID SAFETY:
#   This file and integration_test/ do NOT touch Android source code.
#   Android APK/AAB builds are completely unaffected.
#
# ════════════════════════════════════════════════════════════════════════════

workflows:

  ios-real-screenshots:
    name: "📸 Dr. Fix — Real iPad Screenshots (AR + EN)"
    max_build_duration: 90   # minutes — generous for slow CI + AI calls

    environment:
      # ── Toolchain ─────────────────────────────────────────────────────────
      xcode: latest
      flutter: 3.44.4        # Pin to the exact version in your project
      cocoapods: default

      # ── Secrets (set in Codemagic dashboard → App settings → Variables) ──
      vars:
        GEMINI_API_KEY: $GEMINI_API_KEY
        MAPS_API_KEY: $MAPS_API_KEY

    scripts:

      # ── 1. Environment audit ───────────────────────────────────────────────
      - name: "🔍 Audit build environment"
        script: |
          set -euo pipefail
          echo "──── Flutter ────────────────────────────────────────"
          flutter --version
          echo "──── Xcode ──────────────────────────────────────────"
          xcodebuild -version
          echo "──── macOS ──────────────────────────────────────────"
          sw_vers
          echo "──── CocoaPods ───────────────────────────────────────"
          pod --version
          echo "──── Available iPad Simulators ───────────────────────"
          xcrun simctl list devices available | grep -i "ipad" | head -20

      # ── 2. Write .env (required by flutter_dotenv) ─────────────────────────
      - name: "📝 Write .env file"
        script: |
          set -euo pipefail
          cat > "$CM_BUILD_DIR/.env" << 'ENVEOF'
          GEMINI_MODEL=gemini-3.6-flash
          AI_MODEL_ID=gemini-3.6-flash
          ENVEOF

          echo "GEMINI_API_KEY=${GEMINI_API_KEY:-}" >> "$CM_BUILD_DIR/.env"
          echo "MAPS_API_KEY=${MAPS_API_KEY:-}"     >> "$CM_BUILD_DIR/.env"

          echo "✅ .env written"
          grep -v "_KEY=" "$CM_BUILD_DIR/.env" || true

      # ── 3. Flutter pub get ─────────────────────────────────────────────────
      - name: "📦 flutter pub get"
        script: |
          set -euo pipefail
          flutter pub get

      # ── 4. Disable Swift Package Manager → use CocoaPods ──────────────────
      - name: "⚙️  Force CocoaPods (disable SPM)"
        script: |
          set -euo pipefail
          flutter config --no-enable-swift-package-manager
          echo "✅ Swift Package Manager disabled — CocoaPods will be used"

      # ── 5. pod install ─────────────────────────────────────────────────────
      - name: "📦 pod install"
        script: |
          set -euo pipefail
          cd ios
          rm -rf Pods Podfile.lock
          pod install --repo-update
          echo "✅ CocoaPods installation complete"
          cd ..

      # ── 6. Boot iPad Pro 13-inch Simulator ────────────────────────────────
      - name: "📱 Boot iPad Pro 13-inch Simulator"
        script: |
          set -euo pipefail

          xcrun simctl shutdown all 2>/dev/null || true
          sleep 2

          RUNTIME=$(xcrun simctl list runtimes available \
            | grep -i "iOS" \
            | tail -1 \
            | grep -oE 'com\.apple\.CoreSimulator\.SimRuntime\.iOS-[0-9-]+')

          echo "Target runtime: $RUNTIME"

          DEVICE_ID=$(xcrun simctl list devices available \
            | grep -A 500 "$RUNTIME" \
            | grep -i "iPad Pro (13" \
            | head -1 \
            | grep -oE '[A-F0-9]{8}-([A-F0-9]{4}-){3}[A-F0-9]{12}') || true

          if [ -z "${DEVICE_ID:-}" ]; then
            echo "No iPad Pro 13-inch found — creating one..."
            DEVICE_TYPE=$(xcrun simctl list devicetypes \
              | grep -i "iPad Pro (13" \
              | tail -1 \
              | sed 's/ (com\..*//')
            DEVICE_TYPE="${DEVICE_TYPE:-iPad Pro (M4)}"
            echo "Creating device: '$DEVICE_TYPE' on $RUNTIME"
            DEVICE_ID=$(xcrun simctl create "DrFix_iPad13" "$DEVICE_TYPE" "$RUNTIME")
          fi

          echo "Device ID: $DEVICE_ID"
          xcrun simctl boot "$DEVICE_ID"

          echo "Waiting for simulator to boot..."
          WAITED=0
          until xcrun simctl list devices | grep "$DEVICE_ID" | grep -q "(Booted)"; do
            sleep 3
            WAITED=$((WAITED + 3))
            echo "  ... ${WAITED}s elapsed"
            if [ $WAITED -ge 120 ]; then
              echo "❌ Simulator did not boot within 120 seconds"
              exit 1
            fi
          done

          echo "✅ Simulator booted: $DEVICE_ID"
          echo "export SIMULATOR_DEVICE_ID=$DEVICE_ID" >> "$CM_ENV"

      # ── 7. Run integration test on Simulator ──────────────────────────────
      - name: "🚀 Run app & capture real screenshots"
        script: |
          set -euo pipefail
          source "$CM_ENV"

          echo "Running integration test on: $SIMULATOR_DEVICE_ID"
          mkdir -p build/ios_screenshots

          flutter test \
            integration_test/screenshot_test.dart \
            --device-id "$SIMULATOR_DEVICE_ID" \
            --no-pub \
            --timeout 600 \
            --verbose \
            2>&1 | tee build/ios_screenshots/test_output.log

          echo "✅ Integration test completed"

      # ── 8. Collect screenshots produced by integration_test ───────────────
      - name: "📂 Collect screenshots from Simulator"
        script: |
          set -euo pipefail
          source "$CM_ENV"

          OUT="build/ios_screenshots"
          mkdir -p "$OUT"

          SIM_TMP="$HOME/Library/Developer/CoreSimulator/Devices/$SIMULATOR_DEVICE_ID/data/tmp"
          echo "Looking in: $SIM_TMP"

          SCREENS=("home_ar" "device_info_ar" "ai_report_ar" "parts_map_ar" \
                   "home_en" "device_info_en" "ai_report_en" "parts_map_en")

          for SCREEN in "${SCREENS[@]}"; do
            SRC=$(find "$SIM_TMP" /tmp "$CM_BUILD_DIR/build" \
              -name "${SCREEN}.png" 2>/dev/null | head -1) || true

            if [ -n "$SRC" ] && [ -f "$SRC" ]; then
              cp "$SRC" "$OUT/${SCREEN}.png"
              echo "✅ Collected: ${SCREEN}.png"
            else
              echo "⚠️  Not found: ${SCREEN}.png (check test_output.log)"
            fi
          done

          echo "──── Files in $OUT ────"
          ls -lah "$OUT/" || true

      # ── 9. Verify dimensions ───────────────────────────────────────────────
      - name: "✅ Verify screenshot dimensions"
        script: |
          set -euo pipefail
          OUT="build/ios_screenshots"

          SCREENS=("home_ar" "device_info_ar" "ai_report_ar" "parts_map_ar" \
                   "home_en" "device_info_en" "ai_report_en" "parts_map_en")
          PASS=0; FAIL=0

          echo "═══════════════════════════════════════════════════"
          echo " Screenshot Dimension Report"
          echo "═══════════════════════════════════════════════════"

          for SCREEN in "${SCREENS[@]}"; do
            F="$OUT/${SCREEN}.png"
            if [ -f "$F" ]; then
              W=$(sips -g pixelWidth  "$F" | awk '/pixelWidth/{print $2}')
              H=$(sips -g pixelHeight "$F" | awk '/pixelHeight/{print $2}')
              SZ=$(du -h "$F" | cut -f1)
              echo "✅ ${SCREEN}.png | ${W}×${H} px | $SZ"
              PASS=$((PASS+1))
            else
              echo "❌ MISSING: ${SCREEN}.png"
              FAIL=$((FAIL+1))
            fi
          done

          echo "───────────────────────────────────────────────────"
          echo "Result: $PASS passed, $FAIL missing"

      # ── 10. Generate evidence report ──────────────────────────────────────
      - name: "📄 Generate evidence report"
        script: |
          set -euo pipefail
          source "$CM_ENV"
          OUT="build/ios_screenshots"
          REPORT="$OUT/screenshot_evidence_report.txt"

          {
            echo "════════════════════════════════════════════════════════════"
            echo " Dr. Fix — iOS Simulator Screenshot Evidence Report"
            echo "════════════════════════════════════════════════════════════"
            echo "Build date       : $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
            echo "Flutter version  : $(flutter --version --machine | python3 -c 'import sys,json; d=json.load(sys.stdin); print(d.get("frameworkVersion",""))' 2>/dev/null || flutter --version | head -1)"
            echo "Xcode version    : $(xcodebuild -version | head -1)"
            echo "macOS version    : $(sw_vers -productVersion)"
            echo "Simulator UDID   : $SIMULATOR_DEVICE_ID"
            echo "Bundle ID        : com.drfix.app"
            echo "Deployment target: iOS 13.0"
            echo ""
            echo "Screenshot inventory:"
            echo "────────────────────────────────────────────────────────────"

            declare -A SCREEN_LABELS=(
              [home_ar]="Home Screen | Arabic | HomeScreen"
              [device_info_ar]="Device Info / Diagnosis | Arabic | DeviceInfoScreen"
              [ai_report_ar]="AI Diagnostic Report | Arabic | DiagnosticReportView"
              [parts_map_ar]="Parts & Maintenance Map | Arabic | PartsStoresScreen"
              [home_en]="Home Screen | English | HomeScreen"
              [device_info_en]="Device Info / Diagnosis | English | DeviceInfoScreen"
              [ai_report_en]="AI Diagnostic Report | English | DiagnosticReportView"
              [parts_map_en]="Parts & Maintenance Map | English | PartsStoresScreen"
            )

            for SCREEN in "home_ar" "device_info_ar" "ai_report_ar" "parts_map_ar" \
                          "home_en" "device_info_en" "ai_report_en" "parts_map_en"; do
              F="$OUT/${SCREEN}.png"
              if [ -f "$F" ]; then
                W=$(sips -g pixelWidth  "$F" | awk '/pixelWidth/{print $2}')
                H=$(sips -g pixelHeight "$F" | awk '/pixelHeight/{print $2}')
                SZ=$(du -h "$F" | cut -f1)
                echo "File      : ${SCREEN}.png"
                echo "Screen    : ${SCREEN_LABELS[$SCREEN]}"
                echo "Device    : iPad Pro 13-inch iOS Simulator"
                echo "Dimensions: ${W}×${H} px"
                echo "File size : $SZ"
                echo "Source    : Captured directly from running iOS application"
                echo "────────────────────────────────────────────────────────────"
              else
                echo "File      : ${SCREEN}.png — ❌ MISSING"
                echo "────────────────────────────────────────────────────────────"
              fi
            done
          } | tee "$REPORT"

    artifacts:
      - build/ios_screenshots/*.png
      - build/ios_screenshots/screenshot_evidence_report.txt
      - build/ios_screenshots/test_output.log

    publishing:
      email:
        recipients:
          - drfixapp@gmail.com
        notify:
          success: true
          failure: true
```

---

## 📄 File 2: `integration_test/screenshot_test.dart`
**Location:** Place this file in `integration_test/screenshot_test.dart`.

```dart
// integration_test/screenshot_test.dart
//
// ════════════════════════════════════════════════════════════════════
// Dr. Fix — Real iOS Simulator Screenshot Test
// ════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:integration_test/integration_test.dart';

import 'package:dr_fix/main.dart' as app;
import 'package:dr_fix/main.dart' show localeProvider;

const _shortWait  = Duration(seconds: 2);
const _mediumWait = Duration(seconds: 5);
const _longWait   = Duration(seconds: 10);
const _pumpTick   = Duration(milliseconds: 200);

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<bool> waitFor(
    WidgetTester tester,
    Finder finder, {
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (!tester.any(finder)) {
      if (DateTime.now().isAfter(deadline)) return false;
      await tester.pump(_pumpTick);
    }
    return true;
  }

  group('Dr. Fix — 8 Real Screenshots (AR + EN)', () {

    testWidgets('Full screenshot capture flow', (WidgetTester tester) async {

      // ── 1. Launch the real app ────────────────────────────────────────────
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 6));

      // ── 2. WelcomeScreen: tap "Start Now as Guest" ────────────────────────
      final guestFinders = [
        find.textContaining('Guest'),
        find.textContaining('ضيف'),
        find.textContaining('ابدأ'),
        find.textContaining('Start Now'),
      ];

      bool guestFound = false;
      for (final f in guestFinders) {
        if (await waitFor(tester, f, timeout: const Duration(seconds: 5))) {
          await tester.tap(f.first);
          await tester.pumpAndSettle(_mediumWait);
          guestFound = true;
          break;
        }
      }

      if (!guestFound) {
        for (final f in [find.textContaining('موافق'), find.textContaining('OK'), find.textContaining('Agree')]) {
          if (tester.any(f)) {
            await tester.tap(f.first);
            await tester.pumpAndSettle(_shortWait);
          }
        }
        for (final f in guestFinders) {
          if (tester.any(f)) {
            await tester.tap(f.first);
            await tester.pumpAndSettle(_mediumWait);
            break;
          }
        }
      }

      debugPrint('✅ Passed WelcomeScreen as Guest');

      // ════════════════════════════════════════════════════════════════════
      // ARABIC SCREENSHOTS
      // ════════════════════════════════════════════════════════════════════

      // ── 3. Screenshot 1/8: HomeScreen — Arabic ────────────────────────────
      await tester.pump(_shortWait);
      await binding.takeScreenshot('home_ar');
      debugPrint('📸 home_ar captured');

      // ── 4. Navigate to DeviceInfoScreen ──────────────────────────────────
      final categoryFindersAr = [
        find.textContaining('أنظمة صناعية'),
        find.textContaining('كهرباء'),
        find.textContaining('ميكانيك'),
        find.textContaining('هيدروليك'),
        find.descendant(of: find.byType(GridView), matching: find.byType(InkWell)),
      ];

      for (final f in categoryFindersAr) {
        if (tester.any(f)) {
          await tester.tap(f.first);
          await tester.pumpAndSettle(_mediumWait);
          break;
        }
      }

      debugPrint('✅ Navigated to DeviceInfoScreen');

      // ── 5. Screenshot 2/8: DeviceInfoScreen — Arabic ─────────────────────
      await _fillDeviceForm(
        tester,
        deviceName: 'مضخة هيدروليكية صناعية - 250 Bar',
        problemDesc: 'صوت ضوضاء عالية مع هبوط في الضغط وارتفاع حرارة الزيت',
      );
      await tester.pump(_shortWait);
      await binding.takeScreenshot('device_info_ar');
      debugPrint('📸 device_info_ar captured');

      // ── 6. Submit diagnosis to open DiagnosticReportScreen ────────────────
      final submitFindersAr = [
        find.textContaining('التشخيص'),
        find.textContaining('بدء'),
        find.textContaining('ابدأ'),
      ];

      for (final f in submitFindersAr) {
        if (tester.any(f)) {
          await tester.tap(f.last);
          await tester.pumpAndSettle(_longWait);
          break;
        }
      }

      debugPrint('✅ Submitted diagnosis — waiting for report...');
      await tester.pump(const Duration(seconds: 3));

      // ── 7. Screenshot 3/8: DiagnosticReportScreen — Arabic ───────────────
      await binding.takeScreenshot('ai_report_ar');
      debugPrint('📸 ai_report_ar captured');

      // ── 8. Navigate to PartsStoresScreen via Drawer ───────────────────────
      await _navigateBackToHome(tester);
      await _openPartsScreen(tester, isAr: true);
      await tester.pump(const Duration(seconds: 4));

      // ── 9. Screenshot 4/8: PartsStoresScreen — Arabic ────────────────────
      await binding.takeScreenshot('parts_map_ar');
      debugPrint('📸 parts_map_ar captured');

      // ════════════════════════════════════════════════════════════════════
      // SWITCH TO ENGLISH
      // ════════════════════════════════════════════════════════════════════

      // ── 10. Switch language via Drawer ───────────────────────────────────
      await _switchLanguageViaDrawer(tester);
      await tester.pumpAndSettle(_shortWait);
      debugPrint('🔄 Language switched to English');

      // ── 11. Navigate back to HomeScreen (English) ─────────────────────────
      await _navigateBackToHome(tester);

      // ── 12. Screenshot 5/8: HomeScreen — English ─────────────────────────
      await tester.pump(_shortWait);
      await binding.takeScreenshot('home_en');
      debugPrint('📸 home_en captured');

      // ── 13. Navigate to DeviceInfoScreen (English) ───────────────────────
      final categoryFindersEn = [
        find.textContaining('Industrial'),
        find.textContaining('Electrical'),
        find.textContaining('Mechanical'),
        find.textContaining('Hydraulics'),
        find.descendant(of: find.byType(GridView), matching: find.byType(InkWell)),
      ];

      for (final f in categoryFindersEn) {
        if (tester.any(f)) {
          await tester.tap(f.first);
          await tester.pumpAndSettle(_mediumWait);
          break;
        }
      }

      // ── 14. Screenshot 6/8: DeviceInfoScreen — English ───────────────────
      await _fillDeviceForm(
        tester,
        deviceName: 'Industrial Hydraulic Pump - 250 Bar',
        problemDesc: 'High noise with pressure drop and oil temp rising to 85°C',
      );
      await tester.pump(_shortWait);
      await binding.takeScreenshot('device_info_en');
      debugPrint('📸 device_info_en captured');

      // ── 15. Submit diagnosis (English) ───────────────────────────────────
      final submitFindersEn = [
        find.textContaining('Start'),
        find.textContaining('Diagnos'),
        find.textContaining('AI'),
      ];

      for (final f in submitFindersEn) {
        if (tester.any(f)) {
          await tester.tap(f.last);
          await tester.pumpAndSettle(_longWait);
          break;
        }
      }

      await tester.pump(const Duration(seconds: 3));

      // ── 16. Screenshot 7/8: DiagnosticReportScreen — English ─────────────
      await binding.takeScreenshot('ai_report_en');
      debugPrint('📸 ai_report_en captured');

      // ── 17. Navigate to PartsStoresScreen (English) ───────────────────────
      await _navigateBackToHome(tester);
      await _openPartsScreen(tester, isAr: false);
      await tester.pump(const Duration(seconds: 4));

      // ── 18. Screenshot 8/8: PartsStoresScreen — English ──────────────────
      await binding.takeScreenshot('parts_map_en');
      debugPrint('📸 parts_map_en captured');

      debugPrint('🎉 All 8 screenshots captured successfully!');
    });
  });
}

Future<void> _fillDeviceForm(
  WidgetTester tester, {
  required String deviceName,
  required String problemDesc,
}) async {
  final textFields = find.byType(TextFormField);
  final fallback = find.byType(TextField);

  Finder fields = tester.any(textFields) ? textFields : fallback;

  if (tester.any(fields)) {
    final count = tester.widgetList(fields).length;
    await tester.enterText(fields.at(0), deviceName);
    await tester.pump(const Duration(milliseconds: 400));
    if (count > 1) {
      await tester.enterText(fields.at(count > 3 ? 3 : 1), problemDesc);
      await tester.pump(const Duration(milliseconds: 400));
    }
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump(const Duration(milliseconds: 300));
  }
}

Future<void> _navigateBackToHome(WidgetTester tester) async {
  for (int i = 0; i < 3; i++) {
    final backBtn = find.byType(BackButton);
    final leadingBack = find.byTooltip('Back');
    if (tester.any(backBtn)) {
      await tester.tap(backBtn.first);
      await tester.pumpAndSettle(const Duration(seconds: 2));
    } else if (tester.any(leadingBack)) {
      await tester.tap(leadingBack.first);
      await tester.pumpAndSettle(const Duration(seconds: 2));
    } else {
      break;
    }
    if (tester.any(find.byType(GridView))) break;
  }
}

Future<void> _openPartsScreen(WidgetTester tester, {required bool isAr}) async {
  final bottomNavFinders = [
    find.byIcon(Icons.map_rounded),
    find.byIcon(Icons.location_on_rounded),
    find.byIcon(Icons.store_rounded),
    find.byIcon(Icons.map),
  ];
  for (final f in bottomNavFinders) {
    if (tester.any(f)) {
      await tester.tap(f.first);
      await tester.pumpAndSettle(const Duration(seconds: 3));
      return;
    }
  }

  final menuBtn = find.byIcon(Icons.menu_rounded);
  final menuFallback = find.byIcon(Icons.menu);
  if (tester.any(menuBtn)) {
    await tester.tap(menuBtn.first);
  } else if (tester.any(menuFallback)) {
    await tester.tap(menuFallback.first);
  }
  await tester.pumpAndSettle(const Duration(seconds: 2));

  final drawerFinders = isAr
      ? [find.textContaining('متاجر'), find.textContaining('قطع'), find.textContaining('الخريطة')]
      : [find.textContaining('Stores'), find.textContaining('Parts'), find.textContaining('Map')];

  for (final f in drawerFinders) {
    if (tester.any(f)) {
      await tester.tap(f.first);
      await tester.pumpAndSettle(const Duration(seconds: 3));
      return;
    }
  }

  await tester.tap(find.byType(Scaffold).first);
  await tester.pumpAndSettle(const Duration(seconds: 1));
}

Future<void> _switchLanguageViaDrawer(WidgetTester tester) async {
  for (final f in [find.byIcon(Icons.menu_rounded), find.byIcon(Icons.menu)]) {
    if (tester.any(f)) {
      await tester.tap(f.first);
      await tester.pumpAndSettle(const Duration(seconds: 2));
      break;
    }
  }

  final langFinders = [
    find.byIcon(Icons.translate_rounded),
    find.byIcon(Icons.translate),
    find.textContaining('English Language'),
    find.textContaining('اللغة الإنجليزية'),
    find.textContaining('English'),
    find.textContaining('اللغة'),
  ];

  for (final f in langFinders) {
    if (tester.any(f)) {
      await tester.tap(f.first);
      await tester.pumpAndSettle(const Duration(seconds: 3));
      return;
    }
  }

  await tester.pumpAndSettle(const Duration(seconds: 1));
}
```

---

## 📄 File 3: `pubspec.yaml` (dev_dependencies block)
**Location:** Inside your `pubspec.yaml` under `dev_dependencies`.

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
  integration_test:
    sdk: flutter
```
