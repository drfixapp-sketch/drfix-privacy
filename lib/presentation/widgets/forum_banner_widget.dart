import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dr_fix/main.dart'; // استيراد الـ localeProvider المركزي
import 'package:dr_fix/presentation/screens/forum_screen.dart'; // استدعاء شاشة المنتدى الكاملة

class ForumBannerWidget extends ConsumerWidget {
  const ForumBannerWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localeState = ref.watch(localeProvider);
    final bool isRtl = localeState.languageCode == 'ar';

    // معجم النصوص والترجمات الفورية للبطاقة كما تظهر في الصورة تماماً
    final String forumTitle = isRtl ? 'مجتمع تبادل الخبرات' : 'Community Forum';
    final String forumSubtitle = isRtl ? 'تابع نقاشات وأعطال الورش الآن' : 'Follow workshop discussions & faults now';
    
    final String activeTechsLabel = isRtl ? '👨‍🔧 عدد الفنيين المتواجدين حالياً:' : '👨‍🔧 Active Technicians Online:';
    final String activeTechsValue = isRtl ? '+1497 فني خبير' : '+1497 Expert Techs';
    
    final String lastQuestionLabel = isRtl ? '🔥 آخر سؤال نشط:' : '🔥 Latest Active Question:';
    final String lastQuestionValue = isRtl 
        ? 'كود خطأ E11 في غسالة ديجيتال انفرتر المصلحة حديثاً وعلاجه؟' 
        : 'Error code E11 in digital inverter washing machine remedy?';
    
    final String topDiagnosisLabel = isRtl ? '📊 الأكثر تشخيصاً اليوم:' : '📊 Top Diagnosed Today:';
    final String topDiagnosisValue = isRtl 
        ? 'أعطال دوائر الهيدروليك وأنظمة التكييف VRF' 
        : 'Hydraulic circuit faults & VRF AC systems';
    
    final String buttonText = isRtl ? 'زاوية مجتمع تبادل الخبرات ←' : 'Community Forum Section →';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: isRtl ? CrossAxisAlignment.start : CrossAxisAlignment.end,
          children: [
            // رأس الكرت (العنوان والأيقونة الملونة) مع إصلاح المحاذاة البرمجية والـ spaceBetween الصارمة
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (!isRtl)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.forum_rounded, color: Colors.orange, size: 24),
                  ),
                Column(
                  crossAxisAlignment: isRtl ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    Text(
                      forumTitle,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      forumSubtitle,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                    ),
                  ],
                ),
                if (isRtl)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.forum_rounded, color: Colors.orange, size: 24),
                  ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12.0),
              child: Divider(color: Color(0xFFF1F5F9), thickness: 1.5),
            ),

            // البيانات الإحصائية التفصيلية المتوافقة مع واجهة الصورة
            _buildForumInfoRow(activeTechsLabel, activeTechsValue, isRtl, const Color(0xFF0F75BC)),
            const SizedBox(height: 10),
            _buildForumInfoRow(lastQuestionLabel, lastQuestionValue, isRtl, const Color(0xFF334155)),
            const SizedBox(height: 10),
            _buildForumInfoRow(topDiagnosisLabel, topDiagnosisValue, isRtl, const Color(0xFF64748B)),
            const SizedBox(height: 20),

            // الزر العريض السفلي التفاعلي الموجه لشاشة المنتدى
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ForumScreen()),
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.orange.shade100.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  buttonText,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // دالة مساعدة لبناء صفوف البيانات الإحصائية حركياً
  Widget _buildForumInfoRow(String label, String value, bool isRtl, Color valueColor) {
    return Align(
      alignment: isRtl ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isRtl ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: valueColor),
            textAlign: isRtl ? TextAlign.right : TextAlign.left,
          ),
        ],
      ),
    );
  }
}
