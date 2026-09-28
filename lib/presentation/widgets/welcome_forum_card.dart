import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dr_fix/main.dart';

class WelcomeForumCard extends ConsumerWidget {
  const WelcomeForumCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isRtl = ref.watch(localeProvider).languageCode == 'ar';

    return Container(
      constraints: const BoxConstraints(maxWidth: 550),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F75BC).withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: const Color(0xFFE2EEFF), width: 1.5),
      ),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.forum_rounded, color: Colors.orange, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isRtl ? 'مجتمع تبادل الخبرات' : 'Community Forum',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                    ),
                    Text(
                      isRtl
                          ? 'تابع نقاشات وأعطال الورش الآن'
                          : 'Follow workshop discussions & faults live',
                      style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Divider(color: Color(0xFFEDF2F7)),
          ),

          // 👨‍🔧 إحصائية الفنيين المتواجدين
          _buildIndicatorRow(
            icon: Icons.engineering_rounded,
            iconColor: const Color(0xFF0F75BC),
            title: isRtl
                ? '👨‍🔧 عدد الفنيين المتواجدين حالياً:'
                : '👨‍🔧 Active Technicians Live:',
            value: isRtl ? '+1,497 فني خبير' : '+1,497 Expert Technicians',
            isBoldValue: true,
          ),
          const SizedBox(height: 16),

          // 🔥 آخر سؤال تفاعلي نشط في المنتدى
          _buildIndicatorRow(
            icon: Icons.local_fire_department_rounded,
            iconColor: Colors.red,
            title: isRtl ? '🔥 آخر سؤال نشط:' : '🔥 Latest Active Question:',
            value: isRtl
                ? 'كود خطأ E11 في غسالة ديجيتال انفرتر المصلحة حديثاً وعلاجه؟'
                : 'Error code E11 in a recently repaired digital inverter washing machine?',
            isBoldValue: false,
          ),
          const SizedBox(height: 16),

          // 🛠️ الأجهزة والأعطال الأكثر تشخيصاً اليوم
          _buildIndicatorRow(
            icon: Icons.analytics_rounded,
            iconColor: Colors.purple,
            title: isRtl ? '🛠️ الأكثر تشخيصاً اليوم:' : '🛠️ Most Diagnosed Today:',
            value: isRtl
                ? 'أعطال دوائر الهيدروليك وأنظمة التكييف VRF'
                : 'Hydraulic circuit faults & VRF cooling systems',
            isBoldValue: false,
          ),
          const SizedBox(height: 28),

          // زر تفاعلي عريض للانتقال المباشر لصفحة المنتدى
          ElevatedButton(
            onPressed: () {
              // التوجيه التلقائي إلى forum_screen.dart
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFF3E0),
              foregroundColor: Colors.orange.shade800,
              elevation: 0,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  isRtl
                      ? 'تصفح نقاشات الحلول الهندسية'
                      : 'Browse Engineering Solutions',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_rounded, size: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ودجت فرعي مخصص لبناء سطور البيانات بشكل منسق وجذاب
  Widget _buildIndicatorRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required bool isBoldValue,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: iconColor),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isBoldValue ? FontWeight.bold : FontWeight.normal,
                  color: isBoldValue ? const Color(0xFF0F75BC) : const Color(0xFF334155),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
