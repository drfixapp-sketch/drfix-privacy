import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dr_fix/main.dart'; 
import 'package:dr_fix/presentation/screens/device_info_screen.dart'; 
import 'package:dr_fix/presentation/screens/history_screen.dart';
import 'package:dr_fix/presentation/widgets/custom_drawer.dart';

class EngineeringCategory {
  final String id;
  final String titleAr, titleEn;
  final IconData icon;
  final Color themeColor;

  const EngineeringCategory({
    required this.id,
    required this.titleAr,
    required this.titleEn,
    required this.icon,
    required this.themeColor,
  });
}

final List<EngineeringCategory> engineeringCategories = [
  const EngineeringCategory(id: '1', titleAr: 'أنظمة صناعية', titleEn: 'Industrial Systems', icon: Icons.precision_manufacturing_rounded, themeColor: Colors.blue),
  const EngineeringCategory(id: '2', titleAr: 'كهرباء', titleEn: 'Electrical', icon: Icons.electric_bolt_rounded, themeColor: Colors.amber),
  const EngineeringCategory(id: '3', titleAr: 'ميكانيك', titleEn: 'Mechanical', icon: Icons.settings_applications_rounded, themeColor: Colors.blueGrey),
  const EngineeringCategory(id: '4', titleAr: 'أنظمة هيدروليك', titleEn: 'Hydraulics', icon: Icons.water_drop_rounded, themeColor: Colors.indigo),
  const EngineeringCategory(id: '5', titleAr: 'أجهزة منزلية', titleEn: 'Home Appliances', icon: Icons.kitchen_rounded, themeColor: Colors.deepOrange),
  const EngineeringCategory(id: '6', titleAr: 'تكييف وتبريد', titleEn: 'HVAC', icon: Icons.ac_unit_rounded, themeColor: Colors.cyan),
  const EngineeringCategory(id: '7', titleAr: 'سيارات ومركبات', titleEn: 'Automotive', icon: Icons.time_to_leave_rounded, themeColor: Colors.red),
  const EngineeringCategory(id: '8', titleAr: 'سباكة', titleEn: 'Plumbing', icon: Icons.plumbing_rounded, themeColor: Colors.teal),
  const EngineeringCategory(id: '9', titleAr: 'أخرى', titleEn: 'Other', icon: Icons.more_horiz_rounded, themeColor: Colors.purple),
];

final homeSearchQueryProvider = StateProvider<String>((ref) => '');
class HomeScreen extends ConsumerWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localeState = ref.watch(localeProvider);
    final bool isRtl = localeState.languageCode == 'ar';
    final searchQuery = ref.watch(homeSearchQueryProvider);

    final String pageTitle = isRtl ? 'ماذا تواجه اليوم؟' : 'What are you facing today?';
    final String searchHint = isRtl ? 'ابحث عن المشكلة أو العطل مباشرة...' : 'Search for the fault directly...';
    final String noResults = isRtl ? 'لا توجد أقسام تطابق بحثك' : 'No categories match your search';

    final filteredCategories = engineeringCategories.where((category) {
      final title = isRtl ? category.titleAr : category.titleEn;
      return searchQuery.isEmpty || title.toLowerCase().contains(searchQuery.toLowerCase());
    }).toList();

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          pageTitle, 
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B))
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded, color: Color(0xFF1E293B)),
            tooltip: isRtl ? 'القائمة الجانبية' : 'Menu',
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded, color: Color(0xFF1E293B)),
            tooltip: isRtl ? 'سجل الفحوصات' : 'History',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HistoryScreen()),
              );
            },
          ),
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu_open_rounded, color: Color(0xFF1E293B)),
              tooltip: isRtl ? 'القائمة العلوية' : 'Open menu',
              onPressed: () => Scaffold.of(context).openEndDrawer(),
            ),
          ),
        ],
      ),
      drawer: const CustomAppDrawer(),
      endDrawer: const CustomAppDrawer(),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: TextField(
                      onChanged: (val) => ref.read(homeSearchQueryProvider.notifier).state = val,
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: searchHint,
                        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                        border: InputBorder.none,
                        prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF94A3B8), size: 18),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (filteredCategories.isEmpty)
                    Center(child: Text(noResults, style: const TextStyle(color: Colors.grey, fontSize: 13)))
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredCategories.length,
                      itemBuilder: (context, index) {
                        final category = filteredCategories[index];
                        final String categoryTitle = isRtl ? category.titleAr : category.titleEn;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10.0),
                          child: Material(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            elevation: 0.5,
                            shadowColor: Colors.black.withValues(alpha: 0.04),
                            child: ListTile(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                              leading: CircleAvatar(
                                radius: 16,
                                backgroundColor: category.themeColor.withValues(alpha: 0.08),
                                child: Icon(category.icon, size: 16, color: category.themeColor),
                              ),
                              title: Text(
                                categoryTitle,
                                style: const TextStyle(
                                  fontSize: 13, 
                                  fontWeight: FontWeight.w600, 
                                  color: Color(0xFF1E293B)
                                ),
                              ),
                              trailing: Icon(
                                isRtl ? Icons.arrow_back_ios_new_rounded : Icons.arrow_forward_ios_rounded,
                                size: 14,
                                color: const Color(0xFF94A3B8),
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => DeviceInfoScreen(categoryName: categoryTitle),
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
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
