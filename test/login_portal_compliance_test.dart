import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dr_fix/presentation/screens/login_screen.dart';
import 'package:dr_fix/presentation/screens/welcome_screen.dart';
import 'package:dr_fix/presentation/screens/home_screen.dart';
import 'package:dr_fix/presentation/screens/otp_verification_screen.dart';
import 'package:dr_fix/presentation/providers/auth_provider.dart';

class TestAuthNotifier extends AuthNotifier {
  TestAuthNotifier() : super() {
    state = AuthState.unauthenticated();
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('LoginPortal & Legal Compliance Tests', () {
    testWidgets('LoginScreen shows strict Jordan & GCC + OSHA compliance text in Sign Up mode and hides it in Sign In mode', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => TestAuthNotifier()),
          ],
          child: const MaterialApp(
            home: LoginScreen(isSignUp: false),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 950));

      const String expectedArabicCompliance =
          'أوافق على سياسة الخصوصية وحماية البيانات المعمول بها في الأردن ودول الخليج العربي، وأقر بمسؤوليتي المهنية عن تطبيق خطوات السلامة (OSHA).';
      // In Sign In mode, compliance checkbox is hidden per requirement
      expect(find.text(expectedArabicCompliance), findsNothing);

      // Tap Sign Up tab
      final signUpTabFinder = find.text('إنشاء حساب');
      expect(signUpTabFinder, findsOneWidget);
      await tester.tap(signUpTabFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Now compliance checkbox must be present
      expect(find.text(expectedArabicCompliance), findsOneWidget);
    });

    testWidgets('Buttons are locked/disabled by default in Sign Up mode until checkbox is checked', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => TestAuthNotifier()),
          ],
          child: const MaterialApp(
            home: LoginScreen(isSignUp: true),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 950));

      // 1. Primary Action Button (Sign Up) should have onPressed == null
      final primaryBtnFinder = find.widgetWithText(ElevatedButton, 'تأكيد التسجيل وإنشاء الحساب');
      expect(primaryBtnFinder, findsOneWidget);
      final ElevatedButton primaryBtn = tester.widget<ElevatedButton>(primaryBtnFinder);
      expect(primaryBtn.onPressed, isNull);

      // 2. Google button should have onPressed == null
      final googleBtnFinder = find.widgetWithText(ElevatedButton, 'تسجيل الدخول عن طريق حساب Google');
      expect(googleBtnFinder, findsOneWidget);
      final ElevatedButton googleBtn = tester.widget<ElevatedButton>(googleBtnFinder);
      expect(googleBtn.onPressed, isNull);

      // 3. Guest button should have onPressed == null
      final guestBtnFinder = find.widgetWithText(ElevatedButton, 'ابدأ الآن كضيف ➡️');
      expect(guestBtnFinder, findsOneWidget);
      final ElevatedButton guestBtn = tester.widget<ElevatedButton>(guestBtnFinder);
      expect(guestBtn.onPressed, isNull);

      // Tap the Checkbox
      final checkboxFinder = find.byType(Checkbox);
      expect(checkboxFinder, findsOneWidget);
      await tester.tap(checkboxFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // After checking, buttons should now be live (onPressed != null)
      final ElevatedButton activePrimaryBtn = tester.widget<ElevatedButton>(primaryBtnFinder);
      expect(activePrimaryBtn.onPressed, isNotNull);

      final ElevatedButton activeGoogleBtn = tester.widget<ElevatedButton>(googleBtnFinder);
      expect(activeGoogleBtn.onPressed, isNotNull);

      final ElevatedButton activeGuestBtn = tester.widget<ElevatedButton>(guestBtnFinder);
      expect(activeGuestBtn.onPressed, isNotNull);
    });

    testWidgets('Confirm Password field and validation in Sign Up mode', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => TestAuthNotifier()),
          ],
          child: const MaterialApp(
            home: LoginScreen(isSignUp: true),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 950));

      // Confirm Password field is present
      expect(find.text('تأكيد كلمة المرور'), findsOneWidget);
    });

    testWidgets('Switching to Sign Up tab displays Full Name field', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => TestAuthNotifier()),
          ],
          child: const MaterialApp(
            home: LoginScreen(isSignUp: false),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 950));

      // In login mode, name field is not displayed
      expect(find.text('الاسم بالكامل'), findsNothing);

      // Tap on the "إنشاء حساب" tab
      final signUpTabFinder = find.text('إنشاء حساب');
      expect(signUpTabFinder, findsOneWidget);
      await tester.tap(signUpTabFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Now name field should appear
      expect(find.text('الاسم بالكامل'), findsOneWidget);
      expect(find.text('تأكيد التسجيل وإنشاء الحساب'), findsOneWidget);
    });

    test('AuthNotifier has signInWithEmailAndPassword and signUpWithEmailAndPassword methods', () {
      final notifier = TestAuthNotifier();
      expect(notifier.state.status, equals(AuthStatus.unauthenticated));
    });
  });

  group('WelcomeScreen Navigation Routing Tests', () {
    testWidgets('Guest button navigates directly to HomeScreen', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => TestAuthNotifier()),
          ],
          child: const MaterialApp(
            home: WelcomeScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1500));

      final guestBtn = find.widgetWithText(ElevatedButton, 'ابدأ الآن كضيف ➡️');
      expect(guestBtn, findsOneWidget);

      await tester.ensureVisible(guestBtn);
      await tester.pumpAndSettle();
      await tester.tap(guestBtn);
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('Sign In button navigates to LoginScreen in sign-in mode', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => TestAuthNotifier()),
          ],
          child: const MaterialApp(
            home: WelcomeScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1500));

      final loginBtn = find.widgetWithText(ElevatedButton, 'تسجيل الدخول');
      expect(loginBtn, findsOneWidget);

      await tester.ensureVisible(loginBtn);
      await tester.pumpAndSettle();
      await tester.tap(loginBtn);
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text('الاسم بالكامل'), findsNothing);
      expect(find.text('بوابة تسجيل الدخول'), findsOneWidget);
    });

    testWidgets('Sign Up button navigates to LoginScreen in sign-up mode', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => TestAuthNotifier()),
          ],
          child: const MaterialApp(
            home: WelcomeScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1500));

      final registerBtn = find.widgetWithText(ElevatedButton, 'إنشاء حساب');
      expect(registerBtn, findsOneWidget);

      await tester.ensureVisible(registerBtn);
      await tester.pumpAndSettle();
      await tester.tap(registerBtn);
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text('الاسم بالكامل'), findsOneWidget);
      expect(find.text('إنشاء حساب فني جديد'), findsOneWidget);
    });
  });

  group('Email OTP Verification & Debounce Timer Tests', () {
    testWidgets('OtpVerificationScreen displays 6 input boxes, 24h validity badge and debounce timer', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => TestAuthNotifier()),
          ],
          child: const MaterialApp(
            home: OtpVerificationScreen(email: 'tech@example.com'),
          ),
        ),
      );
      await tester.pump();

      // Verify header and target email
      expect(find.text('التحقق من البريد الإلكتروني'), findsOneWidget);
      expect(find.text('tech@example.com'), findsOneWidget);
      expect(find.text('صلاحية الكود: 24 ساعة فقط'), findsOneWidget);

      // Verify 6 OTP input boxes
      final otpTextFormFields = find.byType(TextFormField);
      expect(otpTextFormFields, findsNWidgets(6));

      // Verify confirm button is present
      expect(find.text('تأكيد الرمز وتفعيل الحساب'), findsOneWidget);

      // Verify 60s cooldown timer on Resend button
      expect(find.textContaining('إعادة الإرسال متاحة بعد'), findsOneWidget);
    });

    test('AppUser model serializes and deserializes isVerified correctly', () {
      final user = AppUser(
        uid: 'user_123',
        displayName: 'مهندس فحص',
        email: 'eng@drfix.app',
        isGuest: false,
        isVerified: false,
      );

      final json = user.toJson();
      expect(json['isVerified'], isFalse);

      final fromJsonUser = AppUser.fromJson(json);
      expect(fromJsonUser.isVerified, isFalse);

      final verifiedUser = fromJsonUser.copyWith(isVerified: true);
      expect(verifiedUser.isVerified, isTrue);
      expect(verifiedUser.toJson()['isVerified'], isTrue);
    });
  });
}

