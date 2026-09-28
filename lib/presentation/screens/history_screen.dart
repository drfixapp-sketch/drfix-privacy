import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dr_fix/main.dart';
import 'package:dr_fix/presentation/providers/auth_provider.dart';
import 'package:dr_fix/presentation/widgets/custom_drawer.dart';
import 'package:dr_fix/data/services/history_service.dart';
import '../widgets/ai_report_state_notifier.dart';
import 'diagnostic_report_screen.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  List<AIReportState> _historyList = [];
  List<AIReportState> _filteredList = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    
    final authState = ref.read(authProvider);
    List<AIReportState> history;
    
    if (authState.status == AuthStatus.authenticated && authState.user != null) {
      final user = authState.user!;
      if (!user.isGuest) {
        history = await HistorySyncService.syncCloudAndLocal(user.uid);
      } else {
        history = await DiagnosisHistoryManager.getHistory();
      }
    } else {
      history = await DiagnosisHistoryManager.getHistory();
    }

    setState(() {
      _historyList = history;
      _filteredList = history;
      _isLoading = false;
    });
  }

  void _filterHistory(String query, bool isRtl) {
    if (query.isEmpty) {
      setState(() => _filteredList = _historyList);
      return;
    }

    final lowerQuery = query.toLowerCase();
    setState(() {
      _filteredList = _historyList.where((report) {
        final deviceName = report.deviceName?.toLowerCase() ?? '';
        final category = report.categoryName?.toLowerCase() ?? '';
        final statusAr = report.currentStatusAr.toLowerCase();
        final statusEn = report.currentStatusEn.toLowerCase();
        final partAr = report.partNameAr.toLowerCase();
        final partEn = report.partNameEn.toLowerCase();

        return deviceName.contains(lowerQuery) ||
            category.contains(lowerQuery) ||
            statusAr.contains(lowerQuery) ||
            statusEn.contains(lowerQuery) ||
            partAr.contains(lowerQuery) ||
            partEn.contains(lowerQuery);
      }).toList();
    });
  }

  Future<void> _deleteReport(AIReportState report, bool isRtl) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          isRtl ? 'حذف التشخيص' : 'Delete Diagnosis',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          textAlign: isRtl ? TextAlign.right : TextAlign.left,
        ),
        content: Text(
          isRtl
              ? 'هل أنت متأكد من رغبتك في حذف هذا التشخيص من السجل؟'
              : 'Are you sure you want to delete this diagnosis from history?',
          style: const TextStyle(fontSize: 12),
          textAlign: isRtl ? TextAlign.right : TextAlign.left,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(isRtl ? 'إلغاء' : 'Cancel', style: const TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(isRtl ? 'حذف' : 'Delete', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final authState = ref.read(authProvider);
      final String? uid = (authState.status == AuthStatus.authenticated) ? authState.user?.uid : null;
      
      await HistorySyncService.deleteReport(report, uid: uid);
      await _loadHistory();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isRtl ? '🗑️ تم الحذف بنجاح' : '🗑️ Deleted successfully'),
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
    }
  }

  Future<void> _clearAllHistory(bool isRtl) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          isRtl ? 'مسح السجل بالكامل' : 'Clear All History',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          textAlign: isRtl ? TextAlign.right : TextAlign.left,
        ),
        content: Text(
          isRtl
              ? 'هل أنت متأكد من حذف كافة التشخيصات السابقة نهائياً؟ لا يمكن التراجع عن هذا الإجراء.'
              : 'Are you sure you want to permanently clear all past diagnostics? This cannot be undone.',
          style: const TextStyle(fontSize: 12),
          textAlign: isRtl ? TextAlign.right : TextAlign.left,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(isRtl ? 'إلغاء' : 'Cancel', style: const TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(isRtl ? 'مسح الكل' : 'Clear All', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final authState = ref.read(authProvider);
      final String? uid = (authState.status == AuthStatus.authenticated) ? authState.user?.uid : null;
      
      await HistorySyncService.clearAllHistory(uid: uid);
      await _loadHistory();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isRtl ? '🧹 تم تفريغ السجل بالكامل' : '🧹 History cleared completely'),
            backgroundColor: Colors.black87,
          ),
        );
      }
    }
  }

  Color _getCategoryColor(String? category) {
    final cat = category?.trim().toLowerCase() ?? '';
    if (cat.contains('تكييف') || cat.contains('hvac')) return Colors.cyan.shade700;
    if (cat.contains('سيارات') || cat.contains('auto')) return Colors.red.shade700;
    if (cat.contains('صناعي') || cat.contains('industrial')) return Colors.blue.shade700;
    if (cat.contains('كهرباء') || cat.contains('electrical')) return Colors.amber.shade800;
    if (cat.contains('هيدروليك') || cat.contains('hydraulics')) return Colors.indigo.shade700;
    if (cat.contains('منزلية') || cat.contains('appliance')) return Colors.deepOrange.shade700;
    if (cat.contains('سباكة') || cat.contains('plumbing')) return Colors.teal.shade700;
    if (cat.contains('ميكانيك') || cat.contains('mechanical')) return Colors.blueGrey.shade700;
    return Colors.purple.shade700;
  }

  IconData _getCategoryIcon(String? category) {
    final cat = category?.trim().toLowerCase() ?? '';
    if (cat.contains('تكييف') || cat.contains('hvac')) return Icons.ac_unit_rounded;
    if (cat.contains('سيارات') || cat.contains('auto')) return Icons.time_to_leave_rounded;
    if (cat.contains('صناعي') || cat.contains('industrial')) return Icons.precision_manufacturing_rounded;
    if (cat.contains('كهرباء') || cat.contains('electrical')) return Icons.electric_bolt_rounded;
    if (cat.contains('هيدروليك') || cat.contains('hydraulics')) return Icons.water_drop_rounded;
    if (cat.contains('منزلية') || cat.contains('appliance')) return Icons.kitchen_rounded;
    if (cat.contains('سباكة') || cat.contains('plumbing')) return Icons.plumbing_rounded;
    if (cat.contains('ميكانيك') || cat.contains('mechanical')) return Icons.settings_applications_rounded;
    return Icons.settings_suggest_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final isRtl = ref.watch(localeProvider).languageCode == 'ar';

    final String title = isRtl ? 'سجل الفحوصات والتشخيصات' : 'Diagnosis History';
    final String searchHint = isRtl ? 'بحث في الفحوصات السابقة...' : 'Search past diagnoses...';
    final String emptyStateText = isRtl ? 'لا يوجد فحوصات مسجلة بعد' : 'No past diagnoses yet';
    final String emptyStateSub = isRtl
        ? 'كل فحص ناجح تقوم به عبر الذكاء الاصطناعي سيتم حفظه هنا للرجوع إليه بدون إنترنت.'
        : 'Every successful AI diagnosis report will be saved here for offline access.';
    final String clearAllText = isRtl ? 'مسح السجل' : 'Clear History';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: CustomAppDrawer(),
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0.5,
        automaticallyImplyLeading: true,
        actions: [
          if (_historyList.isNotEmpty)
            TextButton.icon(
              onPressed: () => _clearAllHistory(isRtl),
              icon: const Icon(Icons.delete_sweep_rounded, size: 18, color: Colors.red),
              label: Text(
                clearAllText,
                style: const TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 🔎 حقل البحث المتقدم في السجل المكتوب
            if (_historyList.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => _filterHistory(val, isRtl),
                    style: const TextStyle(fontSize: 13),
                    textAlign: isRtl ? TextAlign.right : TextAlign.left,
                    decoration: InputDecoration(
                      hintText: searchHint,
                      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                      border: InputBorder.none,
                      prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF94A3B8), size: 16),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 16, color: Color(0xFF94A3B8)),
                              onPressed: () {
                                _searchController.clear();
                                _filterHistory('', isRtl);
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                ),
              ),

            // القائمة أو واجهة التحميل/الفراغ
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF0F75BC)))
                  : _filteredList.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircleAvatar(
                                  radius: 36,
                                  backgroundColor: const Color(0xFFE2E8F0),
                                  child: Icon(Icons.history_toggle_off_rounded, size: 36, color: Colors.blueGrey.shade400),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  emptyStateText,
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  emptyStateSub,
                                  style: const TextStyle(fontSize: 11, color: Colors.grey, height: 1.5),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _filteredList.length,
                          padding: const EdgeInsets.all(16.0),
                          itemBuilder: (context, index) {
                            final report = _filteredList[index];
                            final catColor = _getCategoryColor(report.categoryName);
                            final catIcon = _getCategoryIcon(report.categoryName);

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12.0),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.01),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () {
                                  // تحميل التقرير المحدد في المزود النشط
                                  ref.read(aiReportProvider.notifier).setReport(report);

                                  // الانتقال الآمن لعرض التقرير أوفلاين بالكامل
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const DiagnosticReportView()),
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(14.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // الصف العلوي: البراند والتاريخ وأيقونة النظام
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: catColor.withOpacity(0.08),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(catIcon, size: 12, color: catColor),
                                                const SizedBox(width: 4),
                                                Text(
                                                  report.categoryName ?? (isRtl ? 'أخرى' : 'Other'),
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: catColor,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Row(
                                            children: [
                                              Text(
                                                report.dateStr ?? '',
                                                style: const TextStyle(fontSize: 10, color: Colors.grey),
                                              ),
                                              const SizedBox(width: 4),
                                              IconButton(
                                                padding: EdgeInsets.zero,
                                                constraints: const BoxConstraints(),
                                                icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.red),
                                                onPressed: () => _deleteReport(report, isRtl),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),

                                      // اسم الجهاز الفني
                                      Text(
                                        report.deviceName ?? (isRtl ? 'جهاز غير معروف' : 'Unknown Device'),
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1E293B),
                                        ),
                                      ),
                                      const SizedBox(height: 6),

                                      // قطعة الغيار المقترحة والحل
                                      Text(
                                        isRtl
                                            ? '🔧 الحل المقترح: ${report.partNameAr}'
                                            : '🔧 Suggestion: ${report.partNameEn}',
                                        style: const TextStyle(fontSize: 11, color: Color(0xFF475569)),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 10),

                                      const Divider(color: Color(0xFFF1F5F9), height: 1),
                                      const SizedBox(height: 8),

                                      // الصف السفلي: مستوى الصعوبة ونسبة المطابقة
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                isRtl ? 'مستوى الصعوبة: ' : 'Difficulty: ',
                                                style: const TextStyle(fontSize: 10, color: Colors.grey),
                                              ),
                                              Text(
                                                isRtl ? report.difficultyAr : report.difficultyEn,
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: report.difficultyColor,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.green.withOpacity(0.08),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              isRtl
                                                  ? 'نسبة المطابقة: ${report.confidenceRate}%'
                                                  : 'Confidence: ${report.confidenceRate}%',
                                              style: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.green,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
