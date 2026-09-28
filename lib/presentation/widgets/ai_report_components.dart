import 'package:flutter/material.dart';

// 1. شريط البحث الذكي وفلاتر الـ Chips التفاعلية المترجمة
class ReportHeaderSearch extends StatelessWidget {
  final bool isRtl;
  final String activeFilter;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onFilterSelected;

  const ReportHeaderSearch({
    Key? key,
    required this.isRtl,
    required this.activeFilter,
    required this.onSearchChanged,
    required this.onFilterSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String searchPlaceholder = isRtl ? '🔍 ابحث داخل الخطوات أو قطع الغيار...' : '🔍 Search steps or spare parts...';
    
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        children: [
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: TextField(
              onChanged: onSearchChanged,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: searchPlaceholder,
                hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                isRtl ? 'الكل' : 'All',
                isRtl ? 'أدوات الصيانة' : 'Tools',
                isRtl ? 'خطوات العمل' : 'Fix Steps',
                isRtl ? 'قطع الغيار' : 'Spare Parts',
              ].map((filter) {
                final bool isSelected = activeFilter == filter;
                return Padding(
                  padding: const EdgeInsetsDirectional.only(end: 8.0),
                  child: ChoiceChip(
                    label: Text(filter, style: const TextStyle(fontSize: 11)),
                    selected: isSelected,
                    selectedColor: const Color(0xFFE2EEFF),
                    backgroundColor: const Color(0xFFF1F5F9),
                    labelStyle: TextStyle(color: isSelected ? const Color(0xFF0F75BC) : const Color(0xFF475569)),
                    onSelected: (_) => onFilterSelected(filter),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// 2. كرت مخصص ومرن لبناء كروت التقرير بمسافات مضغوطة وحواف ملونة ذكية لمنع التشابه
class ReportSectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color themeColor;
  final bool isRtl;
  final Widget child;
  final double titleFontSize;

  const ReportSectionCard({
    Key? key,
    required this.title,
    required this.icon,
    required this.themeColor,
    required this.isRtl,
    required this.child,
    this.titleFontSize = 13,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border(
          right: isRtl ? BorderSide(color: themeColor, width: 5) : BorderSide.none,
          left: !isRtl ? BorderSide(color: themeColor, width: 5) : BorderSide.none,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: themeColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(fontSize: titleFontSize, fontWeight: FontWeight.bold, color: themeColor),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

// 3. كرت عرض مستوى الثقة بالذكاء الاصطناعي شريطي احترافي (العداد التناظري التفاعلي)
class ConfidenceMetricWidget extends StatelessWidget {
  final int percentage;
  final bool isRtl;
  final List<String> reasons;

  const ConfidenceMetricWidget({
    Key? key,
    required this.percentage,
    required this.isRtl,
    required this.reasons,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(isRtl ? 'درجة الثقة: عالية' : 'Confidence Level: High', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
            Text('$percentage%', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.green)),
          ],
        ),
        const SizedBox(height: 6),
        // شريط بياني متقدم يحاكي تفكير المهندسين الفنيين
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: const Color(0xFFF1F5F9),
            color: Colors.green,
            minHeight: 8,
          ),
        ),
        const SizedBox(height: 12),
        Text(isRtl ? 'لماذا وصلنا إلى نسبة $percentage%؟' : 'Why $percentage%?', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 4),
        Column(
          children: reasons.map((reason) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.0),
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline_rounded, size: 12, color: Colors.green),
                const SizedBox(width: 6),
                Text(reason, style: const TextStyle(fontSize: 11, color: Color(0xFF475569))),
              ],
            ),
          )).toList(),
        )
      ],
    );
  }
}

// 4. كرت العداد ومقارنة الأسعار وعناصر التكلفة التقريبية
class CostRangeWidget extends StatelessWidget {
  final bool isRtl;
  final String partCost;
  final String fixCost;

  const CostRangeWidget({
    Key? key,
    required this.isRtl,
    required this.partCost,
    required this.fixCost,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE2E8F0))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isRtl ? 'تكلفة القطعة التقديرية' : 'Estimated Part Cost', style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(partCost, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F75BC))),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE2E8F0))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isRtl ? 'تكلفة الإصلاح والمصنعية' : 'Estimated Repair Cost', style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(fixCost, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.orange)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
