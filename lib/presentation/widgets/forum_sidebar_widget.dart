import 'package:flutter/material.dart';

class ForumSidebarWidget extends StatelessWidget {
  final Map<String, String> txt;

  const ForumSidebarWidget({
    Key? key,
    required this.txt,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // التحقق الآمن: إذا لم يتم العثور على المفاتيح، نضع نصوصاً افتراضية فوراً لمنع الـ null value
    final String title1 = txt['side_t1'] ?? '🔥 الأكثر مشاهدة اليوم';
    final String title2 = txt['side_active_techs'] ?? 'أكثر الفنيين نشاطاً';
    final String title3 = txt['side_tags'] ?? 'وسوم شائعة';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Colors.grey.shade200, width: 1)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // القسم الأول: الأكثر مشاهدة اليوم
            Text(title1, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
            const SizedBox(height: 8),
            _buildSidebarItem("عطل ضاغط روتاري LG - تكييف"),
            _buildSidebarItem("مشكلة في صمام الهيدروليك الاتجاهي"),
            const Divider(height: 24),

            // القسم الثاني: أكثر الفنيين نشاطاً بنظام النجوم المضيئة برمجياً
            Text(title2, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
            const SizedBox(height: 8),
            _buildTechItem("م. يوسف محمد", 5),
            _buildTechItem("فني ميكانيك عام", 4),
            const Divider(height: 24),

            // القسم الثالث: الوسوم الشائعة المقلمة هندسياً دون فراغ أبيض
            Text(title3, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _buildTag("#Chiller"),
                _buildTag("#Inverter_E11"),
                _buildTag("#Hydraulics"),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarItem(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text("• $title", maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: Color(0xFF475569))),
    );
  }

  Widget _buildTechItem(String name, int stars) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF334155)))),
          Row(children: List.generate(stars, (index) => const Icon(Icons.star, color: Colors.amber, size: 12))),
        ],
      ),
    );
  }

  Widget _buildTag(String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(4)),
      child: Text(tag, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0F75BC))),
    );
  }
}
