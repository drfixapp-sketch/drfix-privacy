import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dr_fix/main.dart'; 
import 'package:dr_fix/presentation/screens/login_screen.dart';
import 'home_screen.dart';
import 'forum_screen.dart'; 
import 'device_info_screen.dart';
import 'technician_break_screen.dart';

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _scaleAnimation = Tween<double>(begin: 0.80, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.bounceOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _showLegalDisclaimer(BuildContext context, Map<String, String> txt) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  txt['m_title']!,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F75BC)),
                ),
                const SizedBox(height: 12),
                Text(
                  txt['m_body']!,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF334155), height: 1.6),
                  textAlign: TextAlign.justify,
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }
  @override
  Widget build(BuildContext context) {
    final localeState = ref.watch(localeProvider);
    final bool isRtl = localeState.languageCode == 'ar';

    final Map<String, String> txt = isRtl ? {
      't': 'Dr Fix',
      's': 'مساعدك الذكي لتشخيص الأعطال وإصلاحها باحترافية وبدقائق',
      'c1': '⚙️ أنظمة صناعية',
      'c2': '🚗 سيارات ومركبات',
      'c3': '❄️ تكييف وتبريد',
      'c4': '🏠 أجهزة منزلية',
      'f_t': 'مجتمع تبادل الخبرات',
      'f_d': 'تابع نقاشات وأعطال الورش الآن ومشاركة الفنيين',
      'f_l': '👨‍🔧 الفنيين المتواجدين حالياً: ',
      'f_v': '+1,497 خبير متاح',
      'q_l': '🔥 الأكثر تداولاً ومستجدات الورش: ',
      'q_v': 'أعطال دوائر الهيدروليك وأنظمة التكييف VRF المتطورة',
      'f_st': '⚡ تم تسجيل 88 مشاركة وإجابة فنية جديدة اليوم',
      'f_vw': '👁️ 3,591 عطل تم استعراضه ومناقشته اليوم',
      'f_b': '🔥 اسأل المجتمع الآن واستكشف الأعطال',
      's_d_l': 'عمليات تشخيص ناجحة',
      's_d_v': '50,727',
      's_t_l': 'متوسط وقت الحل والوصول للتشخيص',
      's_t_v': '2.4 دقيقة',
      's_a_l': 'دقة التوصيات الهندسية',
      's_a_v': '94%',
      'g_b': 'ابدأ الآن كضيف ➡️',
      'd_l': '⚖️ شروط الاستخدام وإخلاء المسؤولية القانونية',
      'm_title': '⚖️ إخلاء المسؤولية القانونية والسياسة',
      'm_body': 'تطبيق Dr Fix يقدم تشخيصات هندسية وإرشادات ميكانيكية مدعومة بالـ AI لأغراض مساعدة الفنيين وتسهيل الصيانة فقط. هذا التطبيق ليس بديلاً عن الفحص الفني المعتمد والمطابق لمعايير السلامة الصناعية والمصنعية، ويتحمل الفني/المستخدم المسؤولية الكاملة والمنفردة عن أي عمليات فحص، صيانة، أو تركيب ميداني يتم تنفيذها.',
      'p_h': '🔒 معالجة محلية 100%: لا نجمع صورك أو بصمتك الصوتية.',
      'tr1': '✓ يعمل بالذكاء الاصطناعي',
      'tr2': '✓ مجتمع خبراء',
      'tr3': '✓ خصوصية كاملة',
      'tr4': '✓ يدعم العربية والإنجليزية',
      'login': 'تسجيل الدخول',
      'register': 'إنشاء حساب',
      'break_title': '☕ استراحة Dr. Fix',
      'break_sub': 'نكت وألغاز وتحديات هندسية خفيفة',
    } : {
      't': 'Dr Fix',
      's': 'Your intelligent assistant to diagnose and repair faults professionally in minutes',
      'c1': '⚙️ Industrial Systems',
      'c2': '🚗 Automotive',
      'c3': '❄️ HVAC & Cooling',
      'c4': '🏠 Home Appliances',
      'f_t': 'Community Forum',
      'f_d': 'Follow workshop discussions & troubleshoot with experts',
      'f_l': '👨‍🔧 Active Technicians Live: ',
      'f_v': '+1,497 Experts Online',
      'q_l': 'Trending Workshop Topics: ',
      'q_v': 'Hydraulic circuit faults & VRF advanced cooling systems',
      'f_st': '⚡ 88 new technical posts and answers added today',
      'f_vw': '👁️ 3,591 breakdowns reviewed and discussed today',
      'f_b': '🔥 Ask the Community Now & Explore Faults',
      's_d_l': 'Successful AI Diagnostics',
      's_d_v': '50,727',
      's_t_l': 'Average Diagnostic & Fix Time',
      's_t_v': '2.4 min',
      's_a_l': 'Recommendation Accuracy',
      's_a_v': '94%',
      'g_b': 'Start Now as Guest ➡️',
      'd_l': '⚖️ Terms of Use & Legal Disclaimer',
      'm_title': '⚖️ Legal Disclaimer & Policy',
      'm_body': 'Dr Fix provides engineering diagnostics and mechanical guides powered by AI for assistance and troubleshooting purposes only. This app is not a substitute for certified technical inspection matching official factory safety standards. The technician/user bears the full and sole responsibility for any inspection, maintenance, or field operations performed.',
      'p_h': '🔒 100% Local Processing: No server tracking.',
      'tr1': '✓ Powered by AI',
      'tr2': '✓ Experts Community',
      'tr3': '✓ Full Privacy',
      'tr4': '✓ Supports AR / EN',
      'login': 'Log In',
      'register': 'Create Account',
      'break_title': '☕ Dr. Fix Lounge',
      'break_sub': 'Jokes, riddles & technical challenges',
    };

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 450),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: ScaleTransition(
                        scale: _scaleAnimation,
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F75BC).withOpacity(0.08),
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFF0F75BC).withOpacity(0.2), width: 2),
                              ),
                              child: const Icon(
                                Icons.engineering_rounded,
                                size: 56,
                                color: Color(0xFF0F75BC),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              txt['t']!,
                              style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w900, color: Color(0xFF0F75BC), letterSpacing: 1.2),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      txt['s']!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13, color: Color(0xFF475569), fontWeight: FontWeight.w600, height: 1.4),
                    ),
                    const SizedBox(height: 24),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        _buildInteractiveCategoryChip(context, txt['c1']!),
                        _buildInteractiveCategoryChip(context, txt['c2']!),
                        _buildInteractiveCategoryChip(context, txt['c3']!),
                        _buildInteractiveCategoryChip(context, txt['c4']!),
                      ],
                    ),
                    const SizedBox(height: 28),
                    _buildHoverCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(txt['f_t']!, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                                    Text(txt['f_d']!, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                                  ],
                                ),
                              ),
                              const Icon(Icons.forum_rounded, color: Colors.orange, size: 22),
                            ],
                          ),
                          const Divider(height: 20, color: Color(0xFFF1F5F9)),
                          RichText(
                            text: TextSpan(
                              style: const TextStyle(fontSize: 11, color: Color(0xFF475569)),
                              children: [
                                TextSpan(text: txt['f_l']!),
                                TextSpan(text: txt['f_v']!, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F75BC))),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(txt['f_st']!, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green)),
                          const SizedBox(height: 6),
                          Text(txt['f_vw']!, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF64748B))),
                          const SizedBox(height: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(txt['q_l']!, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569)),),
                              const SizedBox(height: 2),
                              Text(txt['q_v']!, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.orange.shade800)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          InkWell(
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => const ForumScreen()));
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              width: double.infinity,
                              height: 42,
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.orange.withOpacity(0.3), width: 1),
                              ),
                              alignment: Alignment.center,
                              child: Text(txt['f_b']!, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.orange)),
                            ),
                          ),
                        ],
                      ),
                    ),
                                        const SizedBox(height: 24),
                    
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F75BC),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const HomeScreen(),
                            ),
                          );
                        },
                        child: Text(txt['g_b']!, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    
                    const SizedBox(height: 14),

                    // 2️⃣ صف زري "تسجيل الدخول" و "إنشاء حساب" (مطابقة تماماً لزر الضيف وبلون احترافي آخر)
                    SizedBox(
                      width: double.infinity,
                      child: Row(
                        children: [
                          
                          // أ. زر تسجيل الدخول (بلون أزرق داكن فخم ومتناسق)
                          Expanded(
                            child: SizedBox(
                              height: 44,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1E293B), // رمادي داكن فخم (Slate-800) متناسق للويب
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  elevation: 0,
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const LoginScreen(isSignUp: false),
                                    ),
                                  );
                                },
                                child: Text(
                                  txt['login']!,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'Tajawal'),
                                ),
                              ),
                            ),
                          ),
                          
                          const SizedBox(width: 12), // مسافة تفصل أفقياً بين الزرين لمنع التداخل البصري
                          
                          // ب. زر إنشاء حساب جديد (بلون مائل للرمادي الفني والأنيق)
                          Expanded(
                            child: SizedBox(
                              height: 44,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF475569), // تدرج مئوي احترافي معتمد (Slate-600)
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  elevation: 0,
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const LoginScreen(isSignUp: true),
                                    ),
                                  );
                                },
                                child: Text(
                                  txt['register']!,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'Tajawal'),
                                ),
                              ),
                            ),
                          ),
                          
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 14),

                    // ☕ بطاقة زر "استراحة الفني" الدافئة الخفيفة
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const TechnicianBreakScreen(),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF7ED),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3), width: 1),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF59E0B).withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.local_cafe_rounded, color: Color(0xFFD97706), size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    txt['break_title']!,
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFB45309)),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    txt['break_sub']!,
                                    style: const TextStyle(fontSize: 10, color: Color(0xFF78350F)),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Color(0xFFD97706)),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // 3️⃣ بطاقة الإحصائيات الفنية المستقرة والمعتمدة
                    _buildHoverCard(
                      child: Column(
                        children: [
                          _buildPremiumStatRow(txt['s_d_v']!, txt['s_d_l']!, Colors.green),
                          const Divider(height: 16, color: Color(0xFFF1F5F9)),
                          _buildPremiumStatRow(txt['s_t_v']!, txt['s_t_l']!, Colors.blue),
                          const Divider(height: 16, color: Color(0xFFF1F5F9)),
                          _buildPremiumStatRow(txt['s_a_v']!, txt['s_a_l']!, Colors.indigo),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // 4️⃣ عبارات وبطاقات الموثوقية والأمان
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        _buildTrustBullet(txt['tr1']!),
                        _buildTrustBullet(txt['tr2']!),
                        _buildTrustBullet(txt['tr3']!),
                        _buildTrustBullet(txt['tr4']!),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // 5️⃣ زر إخلاء المسؤولية القانونية
                    TextButton(
                      onPressed: () => _showLegalDisclaimer(context, txt),
                      child: Text(
                        txt['d_l']!,
                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), decoration: TextDecoration.underline),
                      ),
                    ),
                    
                    // 6️⃣ زر تبديل لغة التطبيق المعتمد على الـ localeProvider المشترك
                    TextButton.icon(
                      onPressed: () {
                        ref.read(localeProvider.notifier).state = localeState.languageCode == 'ar' ? const Locale('en') : const Locale('ar');
                      },
                      icon: const Icon(Icons.translate_rounded, size: 16, color: Color(0xFF94A3B8)),
                      label: Text(isRtl ? 'English' : 'العربية', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInteractiveCategoryChip(BuildContext context, String label) {
    return InkWell(
      onTap: () {
        final String cleanName = label.replaceAll(RegExp(r'[^\w\s\u0600-\u06FF]'), '').trim();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DeviceInfoScreen(categoryName: cleanName),
          ),
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
        ),
      ),
    );
  }

  Widget _buildHoverCard({required Widget child}) {
    return ValueNotifier<bool>(false).build((context, isHovered) {
      return MouseRegion(
        onEnter: (_) => isHovered.value = true,
        onExit: (_) => isHovered.value = false,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isHovered.value ? const Color(0xFF0F75BC).withOpacity(0.5) : const Color(0xFFE2E8F0),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isHovered.value ? Colors.black.withOpacity(0.04) : Colors.black.withOpacity(0.01),
                blurRadius: isHovered.value ? 12 : 6,
                offset: isHovered.value ? const Offset(0, 4) : const Offset(0, 2),
              )
            ],
          ),
          child: child,
        ),
      );
    });
  }

  Widget _buildPremiumStatRow(String value, String label, Color accentColor) {
    return Row(
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: accentColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
          ),
        ),
      ],
    );
  }

  Widget _buildTrustBullet(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0F75BC)),
    );
  }
}

extension _ValueNotifierExtension on ValueNotifier<bool> {
  Widget build(Widget Function(BuildContext context, ValueNotifier<bool> value) builder) {
    return ValueListenableBuilder<bool>(
      valueListenable: this,
      builder: (context, value, _) => builder(context, this),
    );
  }
}
