import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/ai_report_state_notifier.dart';
import '../widgets/ai_report_components.dart';
import 'package:dr_fix/main.dart'; 
import 'package:dr_fix/presentation/widgets/forum_models_and_providers.dart';
// استيراد دالة الفحص الجغرافي الذكية للعملات
import 'package:dr_fix/presentation/widgets/currency_geo_service.dart'; 
import 'package:dr_fix/presentation/screens/parts_stores_screen.dart';
import 'package:dr_fix/presentation/widgets/custom_drawer.dart';

class ProcurementAndCompaniesScreen extends ConsumerStatefulWidget {
  const ProcurementAndCompaniesScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ProcurementAndCompaniesScreen> createState() => _ProcurementAndCompaniesScreenState();
}

class _ProcurementAndCompaniesScreenState extends ConsumerState<ProcurementAndCompaniesScreen> {
  // متغير العملة الديناميكي الذي يتغير تلقائياً حسب إحداثيات موقع الفني
  String _currentCurrency = '...';

  @override
  void initState() {
    super.initState();
    _initializeCurrency(); // تشغيل فحص الموقع الجغرافي الفوري عند إقلاع الشاشة حياً
  }

  Future<void> _initializeCurrency() async {
    final isRtl = ref.read(localeProvider).languageCode == 'ar';
    // استدعاء المعالج الجغرافي الذكي لمعرفة الدولة وتحديد رمز العملة المقابل لها
    String currency = await CurrencyGeoService.getCurrencyBasedOnLocation(isRtl);
    if (mounted) {
      setState(() {
        _currentCurrency = currency;
      });
    }
  }

  bool _isLocationDenied = false; // Enabled interactive map by default

  @override
  Widget build(BuildContext context) {
    final isRtl = ref.watch(localeProvider).languageCode == 'ar';
    final reportState = ref.watch(aiReportProvider);

    final String pageTitle = isRtl ? 'البحث عن قطع الغيار وشركات الصيانة' : 'Search Parts & Service Companies';
    final String mapSectionTitle = isRtl ? '🗺️ شركات ومزودي خدمات الصيانة القريبة منك' : '🗺️ Nearby Service Centers & Vendors';
    final String discountSectionTitle = isRtl ? '🎟️ أكواد خصم حصرية ومعتمدة للشركاء' : '🎟️ Verified Partner Discount Codes';
    final String disclaimerTitle = isRtl ? '⚖️ إخلاء المسؤولية القانونية وتوضيح الخدمة' : '⚖️ Legal Disclaimer & Service Clarification';
    
    final String disclaimerText = isRtl
      ? 'تنويه قانوني: إن كافة المعلومات والتشخيصات الواردة في هذه الشاشة تم توليدها آلياً لأغراض استرشادية فقط. الخدمة مقدمة بشكل مجاني كمحاولة مساعدة، ويرجى التواصل المباشر مع الشركات والتحقق من التراخيص قبل إبرام التعاقد.'
      : 'Legal Disclaimer: All information and diagnostics on this screen are auto-generated for guidance purposes only. This service is provided for free as a helper feature; please verify directly with companies and check licenses before contracting.';

    final promoCodes = ref.watch(promoCodeProvider);

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        drawer: const CustomAppDrawer(),
        appBar: AppBar(
          title: Text(pageTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B))),
          backgroundColor: Colors.white,
          elevation: 0.5,
          centerTitle: true,
          automaticallyImplyLeading: true,
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(bottom: 16.0),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.blueGrey.shade100, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.blueGrey.shade200, width: 1)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.gavel_rounded, size: 16, color: Colors.blueGrey.shade800),
                              const SizedBox(width: 8),
                              Text(disclaimerTitle, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueGrey.shade800)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(disclaimerText, style: TextStyle(fontSize: 11, color: Colors.blueGrey.shade900, height: 1.5, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),

                    // بطاقة الخارطة الجغرافية للبحث التفاعلي
                    ReportSectionCard(
                      title: mapSectionTitle,
                      icon: Icons.map_rounded,
                      themeColor: const Color(0xFF0F75BC),
                      isRtl: isRtl,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isRtl ? reportState.partNameAr : reportState.partNameEn,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                          ),
                          const SizedBox(height: 12),
                          if (_isLocationDenied)
                            TextField(
                              style: const TextStyle(fontSize: 13),
                              decoration: InputDecoration(
                                hintText: isRtl ? 'ابحث باسم المدينة أو الحي يدويًا...' : 'Search by city or district manually...',
                                prefixIcon: const Icon(Icons.search, size: 20, color: Colors.grey),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                              ),
                            )
                          else
                            InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: () {
                                Navigator.push(context, MaterialPageRoute(builder: (context) => PartsStoresScreen(initialCategory: reportState.categoryName)));
                              },
                              child: Container(
                                height: 140,
                                width: double.infinity,
                                decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFCBD5E1))),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.share_location_rounded, size: 32, color: Color(0xFF0F75BC)),
                                      const SizedBox(height: 6),
                                      Text(isRtl ? '📍 جاري تحديد أقرب مزودي قطع الغيار والصيانة...' : '📍 Tracking nearby vendors...', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                                      const SizedBox(height: 4),
                                      Text(isRtl ? '(اضغط لفتح الخريطة التفاعلية 🗺️)' : '(Tap to open interactive map 🗺️)', style: const TextStyle(fontSize: 9, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: 44,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0F75BC),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                elevation: 0,
                              ),
                              onPressed: () {
                                Navigator.push(context, MaterialPageRoute(builder: (context) => PartsStoresScreen(initialCategory: reportState.categoryName)));
                              },
                              icon: const Icon(Icons.map_rounded, size: 18),
                              label: Text(isRtl ? 'فحص الخريطة التفاعلية وأسواق البدائل 🛒' : 'Check Interactive Map & Markets 🛒', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // بطاقة أكواد الخصم الترويجية (شرطية ومخفية تماماً إذا لم تكن هناك عروض)
                    if (promoCodes.isNotEmpty)
                      ReportSectionCard(
                        title: discountSectionTitle,
                        icon: Icons.local_offer_rounded,
                        themeColor: Colors.orange.shade800,
                        isRtl: isRtl,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.orange.shade100),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(isRtl ? "خصم معتمد وحصري للشركاء" : "Verified & Exclusive Partner Discount", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.orange.shade900)),
                                  const SizedBox(height: 2),
                                  Text(isRtl ? 'صالح للاستخدام عند كافة الشركاء' : 'Valid across all certified partners', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.orange.shade300)),
                                child: Text(
                                  promoCodes.first.code,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B), letterSpacing: 1.2),
                                ),
                              ),
                            ],
                          ),
                        ),
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
}
