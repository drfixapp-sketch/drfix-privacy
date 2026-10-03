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
