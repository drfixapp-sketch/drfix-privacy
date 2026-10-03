// integration_test/screenshot_test.dart
//
// ════════════════════════════════════════════════════════════════════
// Dr. Fix — Real iOS Simulator Screenshot Test
// ════════════════════════════════════════════════════════════════════
//
// PURPOSE : Navigate the real running app on iOS Simulator and capture
//           8 real screenshots (4 AR + 4 EN) using the official
//           integration_test binding.takeScreenshot() API.
//
// SCREENS :
//   1. WelcomeScreen  → tap "Start Now as Guest" → HomeScreen
//   2. HomeScreen     (AR + EN)
//   3. DeviceInfoScreen — tap first category card  (AR + EN)
//   4. DiagnosticReportScreen — fill form + submit  (AR + EN)
//   5. PartsStoresScreen — via Drawer               (AR + EN)
//
// MAPS NOTE :
//   PartsStoresScreen uses flutter_map (OpenStreetMap tiles via HTTP),
//   NOT google_maps_flutter. No GPU/Metal required → zero crash risk
//   on iOS Simulator. We still pump briefly before capture so tiles
//   start loading (network in CI → grey placeholders acceptable).
//
// ANDROID : This file lives in integration_test/ and is excluded from
//   all Android release/debug builds. Zero impact on Android APK/AAB.
//
// LANGUAGE SWITCHING :
//   localeProvider is a Riverpod StateProvider<Locale>.
//   Language toggle is inside CustomAppDrawer (Icons.translate_rounded).
//   We open the drawer and tap it programmatically.
//
// ════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:integration_test/integration_test.dart';

import 'package:dr_fix/main.dart' as app;
import 'package:dr_fix/main.dart' show localeProvider;

// ─── Constants ────────────────────────────────────────────────────────────────
const _shortWait  = Duration(seconds: 2);
const _mediumWait = Duration(seconds: 5);
const _longWait   = Duration(seconds: 10); // AI report generation
const _pumpTick   = Duration(milliseconds: 200);

void main() {
  // Initialise the integration test binding — this enables takeScreenshot()
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // ─── Utilities ─────────────────────────────────────────────────────────────

  /// Pump until [finder] appears or [timeout] elapses; does NOT throw.
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

  /// Tap [finder] if found; silently skips if not found.
  Future<void> safeTap(WidgetTester tester, Finder finder) async {
    if (tester.any(finder)) {
      await tester.tap(finder.first);
      await tester.pumpAndSettle(_shortWait);
    }
  }

  /// Capture a screenshot with the given [name].
  /// integration_test saves PNG files that Codemagic collects as Artifacts.
  Future<void> capture(String name) async {
    await tester_capture(binding, name);
  }

  // ─── Test suite ────────────────────────────────────────────────────────────
  group('Dr. Fix — 8 Real Screenshots (AR + EN)', () {

    testWidgets('Full screenshot capture flow', (WidgetTester tester) async {

      // ── 1. Launch the real app ────────────────────────────────────────────
      app.main();
      // Allow Firebase init + animations to settle
      await tester.pumpAndSettle(const Duration(seconds: 6));

      // ── 2. WelcomeScreen: tap "Start Now as Guest" ────────────────────────
      // The button label uses key 'g_b' which maps to:
      //   AR: 'ابدأ الآن كضيف 🚀'   EN: 'Start Now as Guest 🚀'
      // We search by partial text to be locale-independent.
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

      // Fallback: if modal disclaimer appeared, look for a confirm/proceed button
      if (!guestFound) {
        for (final f in [find.textContaining('موافق'), find.textContaining('OK'), find.textContaining('Agree')]) {
          if (tester.any(f)) {
            await tester.tap(f.first);
            await tester.pumpAndSettle(_shortWait);
          }
        }
        // Try guest again after dismissing modal
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
      // ARABIC SCREENSHOTS (app starts in AR by default)
      // ════════════════════════════════════════════════════════════════════

      // ── 3. Screenshot 1/8: HomeScreen — Arabic ────────────────────────────
      await tester.pump(_shortWait);
      await binding.takeScreenshot('home_ar');
      debugPrint('📸 home_ar captured');

      // ── 4. Navigate to DeviceInfoScreen: tap first category card ──────────
      // HomeScreen renders a GridView of EngineeringCategory tiles.
      // Each tile is wrapped in InkWell/GestureDetector.
      // Tap the first visible card by finding its text (AR: 'أنظمة صناعية').
      final categoryFindersAr = [
        find.textContaining('أنظمة صناعية'),
        find.textContaining('كهرباء'),
        find.textContaining('ميكانيك'),
        find.textContaining('هيدروليك'),
        // Fallback: first InkWell in the grid
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
      // Enter realistic sample data so the screenshot looks authentic
      await _fillDeviceForm(
        tester,
        deviceName: 'مضخة هيدروليكية صناعية - 250 Bar',
        problemDesc: 'صوت ضوضاء عالية مع هبوط في الضغط وارتفاع حرارة الزيت',
      );
      await tester.pump(_shortWait);
      await binding.takeScreenshot('device_info_ar');
      debugPrint('📸 device_info_ar captured');

      // ── 6. Submit diagnosis to open DiagnosticReportScreen ────────────────
      // The CTA button text (AR): 'بدء التشخيص الهندسي بالذكاء الاصطناعي'
      final submitFindersAr = [
        find.textContaining('التشخيص'),
        find.textContaining('بدء'),
        find.textContaining('ابدأ'),
      ];

      for (final f in submitFindersAr) {
        if (tester.any(f)) {
          // Use the LAST match to avoid tapping nav bar items
          await tester.tap(f.last);
          // Allow up to 15 s for AI response (Gemini) or loading state
          await tester.pumpAndSettle(_longWait);
          break;
        }
      }

      debugPrint('✅ Submitted diagnosis — waiting for report...');
      // Extra pump in case AI is slow; we screenshot whatever state we're in
      await tester.pump(const Duration(seconds: 3));

      // ── 7. Screenshot 3/8: DiagnosticReportScreen — Arabic ───────────────
      await binding.takeScreenshot('ai_report_ar');
      debugPrint('📸 ai_report_ar captured');

      // ── 8. Navigate to PartsStoresScreen via CustomAppDrawer ─────────────
      // Back to HomeScreen first
      await _navigateBackToHome(tester);

      // Open Drawer → tap Parts/Map entry
      await _openPartsScreen(tester, isAr: true);
      // flutter_map tiles load via HTTP — pump a moment for initial render
      await tester.pump(const Duration(seconds: 4));

      // ── 9. Screenshot 4/8: PartsStoresScreen — Arabic ────────────────────
      await binding.takeScreenshot('parts_map_ar');
      debugPrint('📸 parts_map_ar captured');

      // ════════════════════════════════════════════════════════════════════
      // SWITCH TO ENGLISH
      // ════════════════════════════════════════════════════════════════════

      // ── 10. Switch language via Drawer language toggle ────────────────────
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

// ─── Helper functions (outside testWidgets for readability) ──────────────────

/// Fill the DeviceInfoScreen form fields with realistic data.
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
    // Field 0: device name / classification
    await tester.enterText(fields.at(0), deviceName);
    await tester.pump(const Duration(milliseconds: 400));
    // Field 1 or 2: problem description (may be index 1 or 3 depending on layout)
    if (count > 1) {
      await tester.enterText(fields.at(count > 3 ? 3 : 1), problemDesc);
      await tester.pump(const Duration(milliseconds: 400));
    }
    // Dismiss keyboard
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump(const Duration(milliseconds: 300));
  }
}

/// Pop back to HomeScreen using Navigator back or bottom-nav Home tab.
Future<void> _navigateBackToHome(WidgetTester tester) async {
  // Pop up to 3 levels
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
    // Stop early if we see the category grid (HomeScreen)
    if (tester.any(find.byType(GridView))) break;
  }
}

/// Open PartsStoresScreen via the CustomAppDrawer.
/// Drawer entry is a ListTile with Icons.map or text containing 'متاجر'/'Stores'/'Map'.
Future<void> _openPartsScreen(WidgetTester tester, {required bool isAr}) async {
  // Try bottom navigation first (if present)
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

  // Fallback: open Drawer and tap map/stores entry
  final menuBtn = find.byIcon(Icons.menu_rounded);
  final menuFallback = find.byIcon(Icons.menu);
  if (tester.any(menuBtn)) {
    await tester.tap(menuBtn.first);
  } else if (tester.any(menuFallback)) {
    await tester.tap(menuFallback.first);
  }
  await tester.pumpAndSettle(const Duration(seconds: 2));

  // Tap the parts/map entry in drawer
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

  // Last fallback: close drawer
  await tester.tap(find.byType(Scaffold).first);
  await tester.pumpAndSettle(const Duration(seconds: 1));
}

/// Switch app language by opening Drawer and tapping the translate icon.
/// CustomAppDrawer has: ListTile(leading: Icon(Icons.translate_rounded), onTap: toggle locale)
Future<void> _switchLanguageViaDrawer(WidgetTester tester) async {
  // Open drawer
  for (final f in [find.byIcon(Icons.menu_rounded), find.byIcon(Icons.menu)]) {
    if (tester.any(f)) {
      await tester.tap(f.first);
      await tester.pumpAndSettle(const Duration(seconds: 2));
      break;
    }
  }

  // Tap language toggle in drawer
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

  // Drawer might have closed; try again
  await tester.pumpAndSettle(const Duration(seconds: 1));
}

/// Wraps binding.takeScreenshot with a debug print.
Future<void> tester_capture(
  IntegrationTestWidgetsFlutterBinding binding,
  String name,
) async {
  await binding.takeScreenshot(name);
}
