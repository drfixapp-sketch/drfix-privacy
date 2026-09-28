import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dr_fix/main.dart';
import 'package:dr_fix/presentation/widgets/custom_drawer.dart';
import '../../data/repositories/diagnostic_prompts.dart';

class PreventativeMaintenanceScreen extends ConsumerWidget {
  final String faultName;
  const PreventativeMaintenanceScreen({Key? key, required this.faultName}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isRtl = ref.watch(localeProvider).languageCode == 'ar';
    String _localeText(String ar, String en) => isRtl ? ar : en;

    final raw = DiagnosticPromptsRepository.lastRawResponse;

    // Helper functions to parse values from raw response safely
    List<String> getList(String key) {
      if (raw == null) return [];
      final val = raw[key];
      if (val is List) {
        return val.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
      }
      return [];
    }

    List<String> getNestedList(String parentKey, String childKey) {
      if (raw == null) return [];
      final parent = raw[parentKey];
      if (parent is Map) {
        final val = parent[childKey];
        if (val is List) {
          return val.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
        }
      }
      return [];
    }

    // Section 1: Operation Guide
    final startSteps = getNestedList('operation_guide', 'start_steps');
    final stopSteps = getNestedList('operation_guide', 'stop_steps');
    final normalConditions = getNestedList('operation_guide', 'normal_conditions');
    final shutdownSigns = getNestedList('operation_guide', 'shutdown_signs');
    final bool hasOperationGuide = startSteps.isNotEmpty || stopSteps.isNotEmpty || normalConditions.isNotEmpty || shutdownSigns.isNotEmpty;

    // Section 2: Maintenance Program
    final daily = getNestedList('maintenance_program', 'daily');
    final weekly = getNestedList('maintenance_program', 'weekly');
    final monthly = getNestedList('maintenance_program', 'monthly');
    final semiAnnual = getNestedList('maintenance_program', 'semi_annual');
    final annual = getNestedList('maintenance_program', 'annual');
    final bool hasMaintenance = daily.isNotEmpty || weekly.isNotEmpty || monthly.isNotEmpty || semiAnnual.isNotEmpty || annual.isNotEmpty;

    // Section 3: Operating Errors
    final operatingErrors = getList('operating_errors');
    final bool hasErrors = operatingErrors.isNotEmpty;

    // Section 4: Longevity Recommendations
    final longevity = getList('longevity_recommendations');
    final bool hasLongevity = longevity.isNotEmpty;

    final String placeholderText = _localeText(
      'لم تتوفر معلومات كافية لإنشاء هذا القسم لهذه الحالة.',
      'Not enough information available to generate this section for this case.',
    );

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.white,
        drawer: const CustomAppDrawer(),
        appBar: AppBar(
          title: Text(_localeText('إرشادات الصيانة الوقائية', 'Preventative Maintenance Guidance'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.black87),
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
                    // Section 1: Brief Operation Guide
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.book, color: Colors.blue, size: 20),
                              const SizedBox(width: 8),
                              Text(_localeText('📘 دليل التشغيل المختصر', '📘 Brief Operation Guide'), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.blue)),
                            ],
                          ),
                          const Divider(),
                          const SizedBox(height: 8),
                          if (!hasOperationGuide)
                            Text(placeholderText, style: const TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic))
                          else ...[
                            if (startSteps.isNotEmpty) ...[
                              Text(_localeText('• خطوات التشغيل:', '• Operation steps:'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              ...startSteps.map((s) => Text('  - $s', style: const TextStyle(fontSize: 12))),
                              const SizedBox(height: 8),
                            ],
                            if (stopSteps.isNotEmpty) ...[
                              Text(_localeText('• خطوات الإيقاف:', '• Shutdown steps:'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              ...stopSteps.map((s) => Text('  - $s', style: const TextStyle(fontSize: 12))),
                              const SizedBox(height: 8),
                            ],
                            if (normalConditions.isNotEmpty) ...[
                              Text(_localeText('• ظروف التشغيل الطبيعية:', '• Normal operating conditions:'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              ...normalConditions.map((s) => Text('  - $s', style: const TextStyle(fontSize: 12))),
                              const SizedBox(height: 8),
                            ],
                            if (shutdownSigns.isNotEmpty) ...[
                              Text(_localeText('• علامات تستوجب إيقاف التشغيل:', '• Signs requiring immediate shutdown:'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.red)),
                              ...shutdownSigns.map((s) => Text('  - $s', style: const TextStyle(fontSize: 12, color: Colors.red))),
                            ],
                          ]
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Section 2: Preventative Maintenance Program
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.teal.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.teal.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.build_circle, color: Colors.teal, size: 20),
                              const SizedBox(width: 8),
                              Text(_localeText('🛠️ برنامج الصيانة الوقائية', '🛠️ Preventative Maintenance Program'), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.teal)),
                            ],
                          ),
                          const Divider(),
                          const SizedBox(height: 8),
                          if (!hasMaintenance)
                            Text(placeholderText, style: const TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic))
                          else ...[
                            if (daily.isNotEmpty) ...[
                              Text(_localeText('• يومياً:', '• Daily:'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              ...daily.map((s) => Text('  - $s', style: const TextStyle(fontSize: 12))),
                              const SizedBox(height: 6),
                            ],
                            if (weekly.isNotEmpty) ...[
                              Text(_localeText('• أسبوعياً:', '• Weekly:'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              ...weekly.map((s) => Text('  - $s', style: const TextStyle(fontSize: 12))),
                              const SizedBox(height: 6),
                            ],
                            if (monthly.isNotEmpty) ...[
                              Text(_localeText('• شهرياً:', '• Monthly:'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              ...monthly.map((s) => Text('  - $s', style: const TextStyle(fontSize: 12))),
                              const SizedBox(height: 6),
                            ],
                            if (semiAnnual.isNotEmpty) ...[
                              Text(_localeText('• نصف سنوي:', '• Semi-annual:'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              ...semiAnnual.map((s) => Text('  - $s', style: const TextStyle(fontSize: 12))),
                              const SizedBox(height: 6),
                            ],
                            if (annual.isNotEmpty) ...[
                              Text(_localeText('• سنوي:', '• Annual:'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              ...annual.map((s) => Text('  - $s', style: const TextStyle(fontSize: 12))),
                            ],
                          ]
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Section 3: Operating errors that may lead to this fault
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.warning, color: Colors.orange.shade800, size: 20),
                              const SizedBox(width: 8),
                              Expanded(child: Text(_localeText('⚠️ أخطاء التشغيل التي قد تؤدي إلى هذا العطل', '⚠️ Operating errors that may lead to this fault'), style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.orange.shade900))),
                            ],
                          ),
                          const Divider(),
                          const SizedBox(height: 8),
                          if (!hasErrors)
                            Text(placeholderText, style: const TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic))
                          else
                            ...operatingErrors.map((s) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2.0),
                              child: Text('• $s', style: const TextStyle(fontSize: 12, height: 1.4)),
                            )),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Section 4: Recommendations to extend equipment life
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.purple.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.lightbulb, color: Colors.purple, size: 20),
                              const SizedBox(width: 8),
                              Text(_localeText('💡 توصيات لإطالة عمر المعدة', '💡 Recommendations to extend equipment life'), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.purple)),
                            ],
                          ),
                          const Divider(),
                          const SizedBox(height: 8),
                          if (!hasLongevity)
                            Text(placeholderText, style: const TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic))
                          else
                            ...longevity.map((s) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2.0),
                              child: Text('• $s', style: const TextStyle(fontSize: 12, height: 1.4)),
                            )),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black87,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: Text(_localeText('عودة للتقرير', 'Back to Report'), style: const TextStyle(fontWeight: FontWeight.bold)),
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
