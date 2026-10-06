import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dr_fix/presentation/screens/admin_review_screen.dart';
import 'package:dr_fix/presentation/screens/welcome_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dr_fix/presentation/widgets/notification_helper.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// المزود المشترك الرسمي المسؤول عن حالة وحفظ لغة التطبيق الفورية بدون أي بادئات وهمية
final localeProvider = StateProvider<Locale>((ref) => const Locale('ar'));

// دالة التشغيل الأساسية
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // تحميل ملف البيئة (اختياري — لا يوقف التطبيق عند غيابه)
  try {
    await dotenv.load(fileName: "assets/app_config.env");
  } catch (e) {
    debugPrint("Failed to load .env file: $e");
  }

  // تهيئة Firebase — يقرأ الإعدادات المعتمدة لكافة المنصات
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e) {
    debugPrint("Firebase initialization failed: $e");
  }

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider);
    return MaterialApp(
      title: 'Dr Fix',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0F75BC)),
        useMaterial3: true,
        fontFamily: currentLocale.languageCode == 'ar' ? 'Tajawal' : 'Roboto',
      ),
      locale: currentLocale,
      supportedLocales: const [
        Locale('ar'),
        Locale('en'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalCustromLocalizationsDelegate(),
        AppLocalizationsDelegate(),
      ],
      builder: (context, child) => HeadsUpNotificationOverlay(child: child!),
      routes: {
        '/admin-review': (context) => const AdminReviewScreen(),
      },
      home: const WelcomeScreen(),
    );
  }
}

// دليلة كوبرتينو احتياطية لتجنب أخطاء حزم اللغات الشائعة للويب
class GlobalCustromLocalizationsDelegate extends LocalizationsDelegate<MaterialLocalizations> {
  const GlobalCustromLocalizationsDelegate();
  @override
  bool isSupported(Locale locale) => true;
  @override
  Future<MaterialLocalizations> load(Locale locale) => GlobalMaterialLocalizations.delegate.load(locale);
  @override
  bool shouldReload(GlobalCustromLocalizationsDelegate old) => false;
}
// نظام إدارة وتوزيع التراجم والنصوص داخل التطبيق
class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  static const LocalizationsDelegate<AppLocalizations> delegate = AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  String translate(String key) {
    return _localizedStrings[locale.languageCode]?[key] ?? key;
  }
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['ar', 'en'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(AppLocalizations(locale));
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}

// قاموس الترجمة الشامل المعتمد للمشروع (تم تأمين وإخفاء الرقم السري بنجاح)
final Map<String, Map<String, String>> _localizedStrings = {
  'ar': {
    'welcome_title': 'مرحباً بك في Dr Fix',
    'welcome_subtitle': 'مساعدك الذكي للصيانة الشاملة والعمل الميداني',
    'disclaimer_title': '⚖️ إخلاء المسؤولية القانونية والسياسة',
    'disclaimer_body': 'تطبيق Dr Fix يقدم تشخيصات هندسية وإرشادات ميكانيكية مدعومة بالـ AI لأغراض مساعدة الفنيين وتسهيل الصيانة فقط. هذا التطبيق ليس بديلاً عن الفحص الفني المعتمد والمطابق لمعايير السلامة الصناعية والمصنعية، ويتحمل الفني/المستخدم المسؤولية الكاملة والمنفردة عن أي عمليات فحص، صيانة، أو تركيب ميداني يتم تنفيذها.',
    'privacy_hint': '🔒 معالجة محلية 100%: نحن لا نجمع أو نحفظ صورك أو بصمتك الصوتية في أي خادم.',
    'accept_btn': 'موافق والدخول كزائر آمن ➡️',
    'lang_btn': 'English',
    'home_title': 'ماذا تواجه اليوم؟',
    'search_hint': 'ابحث عن المشكلة أو العطل مباشرة...',
    'cat_industrial': 'أنظمة صناعية',
    'cat_electrical': 'كهرباء',
    'cat_mechanical': 'ميكانيك',
    'cat_hydraulic': 'أنظمة هيدروليك',
    'cat_appliances': 'أجهزة منزلية',
    'cat_hvac': 'تكييف وتبريد',
    'cat_automotive': 'سيارات ومركبات',
    'cat_plumbing': 'سباكة',
    'cat_other': 'أخرى',
    'starting_diagnosis': 'جاري بدء التشخيص...',
    'loading_images': 'جاري تحليل الصور بالذكاء الاصطناعي...',
    'loading_report': 'جاري إعداد التقرير التفاعلي...',
    'thinking': 'جاري التفكير...',
    'listening': 'جاري الاستماع...',
    // 🌟 المفاتيح السرية للوحة التحكم (تم حجب الباسورد هنا)
    'admin_title': 'صلاحيات مدير النظام (Admin)',
    'admin_pass_hint': 'أدخل رمز المرور السري للمشرفين...',
  },
  'en': {
    'welcome_title': 'Welcome to Dr Fix',
    'welcome_subtitle': 'Your Smart Maintenance & Field Operation Assistant',
    'disclaimer_title': '⚖️ Legal Disclaimer & Policy',
    'disclaimer_body': 'Dr Fix provides engineering diagnostics and mechanical guides powered by AI for assistance and troubleshooting purposes only. This app is not a substitute for certified technical inspection matching official factory safety standards. The technician/user bears the full and sole responsibility for any inspection, maintenance, or field operations performed.',
    'privacy_hint': '🔒 100% On-Device Processing: We do not collect or save your photos or voice tokens on any server.',
    'accept_btn': 'Accept & Enter as Guest ➡️',
    'lang_btn': 'العربية',
    'home_title': 'What are you facing today?',
    'search_hint': 'Search for your issue...',
    'cat_industrial': 'Industrial Systems',
    'cat_electrical': 'Electrical',
    'cat_mechanical': 'Mechanics',
    'cat_hydraulic': 'Hydraulics',
    'cat_appliances': 'Home Appliances',
    'cat_hvac': 'HVAC & Cooling',
    'cat_automotive': 'Automotive / Cars',
    'cat_plumbing': 'Plumbing',
    'cat_other': 'Other',
    'starting_diagnosis': 'Starting Diagnosis...',
    'loading_images': 'Analyzing images with AI...',
    'loading_report': 'Preparing interactive report...',
    'thinking': 'Thinking...',
    'listening': 'Listening...',
    // 🌟 مفاتيح لوحة التحكم بالإنجليزية
    'admin_title': 'Admin Privileges',
    'admin_pass_hint': 'Enter admin security key to verify...',
  }
};
