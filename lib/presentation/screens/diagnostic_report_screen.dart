import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dr_fix/main.dart';
import 'package:dr_fix/presentation/widgets/custom_drawer.dart';
import '../../data/models/diagnostic_report_model.dart';
import '../../data/providers/diagnostic_engine_provider.dart';
import '../widgets/ai_report_state_notifier.dart';
import 'procurement_and_companies_screen.dart';
import 'preventative_maintenance_screen.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../widgets/forum_models_and_providers.dart';
import '../widgets/engineering_diagnosis_loading_view.dart';
import '../widgets/contextual_diagnostic_chat_sheet.dart';
import '../widgets/stt_helper.dart';

class DiagnosticReportView extends ConsumerStatefulWidget {
  final DiagnosticReportModel? initialReport;
  const DiagnosticReportView({Key? key, this.initialReport}) : super(key: key);

  @override
  ConsumerState<DiagnosticReportView> createState() => _DiagnosticReportViewState();
}

class _DiagnosticReportViewState extends ConsumerState<DiagnosticReportView> {
  DiagnosticReportModel? _localReport;
  DiagnosticReportModel? activeReport;
  bool _isSent = false; // حماية الإرسال المتكرر — يُعطَّل الزران بعد أول submitForReview
  int currentStepIndex = 0; 
  int selectedCauseIndex = 0;
  
  List<bool> oshaCheckedStates = [];

  final TextEditingController _feedbackController = TextEditingController();

  // محرك STT متوافق مع Android moderno لحقل المساعد الذكي
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechAvailable = false;
  bool _isListening = false;

  final List<String> _attachedImages = [];

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final List<XFile>? images = await picker.pickMultiImage(imageQuality: 70);
      if (images != null) {
        setState(() {
          _attachedImages.addAll(images.map((img) => img.path));
        });
      }
    } catch (e) {
      debugPrint("Error picking images: $e");
    }
  }

  // سجل المحادثة السياقية الجانبية المرتبطة بهذا التقرير
  final List<DiagnosticChatMessage> _chatHistory = [];

  void _openContextualChat({
    String? initialQuestion,
    required DiagnosticReportModel report,
    required bool isRtl,
  }) async {
    final result = await showModalBottomSheet<List<DiagnosticChatMessage>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ContextualDiagnosticChatSheet(
        report: report,
        initialQuestion: initialQuestion,
        initialImages: List<String>.from(_attachedImages),
        chatHistory: _chatHistory,
        isRtl: isRtl,
      ),
    );
    if (result != null && mounted) {
      setState(() {
        _chatHistory.clear();
        _chatHistory.addAll(result);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialReport != null) {
      _localReport = widget.initialReport;
      _syncVerificationNodes(_localReport!);
    }
    // تهيئة STT لحقل إرسال الملاحظات للمساعد الذكي
    _speech.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          if (mounted) setState(() => _isListening = false);
        }
      },
      onError: (error) {
        debugPrint('STT Error: ${error.errorMsg}');
        if (mounted) setState(() => _isListening = false);
      },
      options: [stt.SpeechToText.webDoNotAggregate],
    ).then((available) {
      if (mounted) setState(() => _speechAvailable = available);
    }).catchError((Object error) {
      debugPrint('STT initialize failed: $error');
      if (mounted) setState(() => _speechAvailable = false);
    });
  }

  void _syncVerificationNodes(DiagnosticReportModel rep) {
    currentStepIndex = 0;
    initializeOshaChecklist(rep.dynamicRiskQuestions);
  }

  bool get _isRtl => ref.watch(localeProvider).languageCode == 'ar';
  String _localeText(String ar, String en) => _isRtl ? ar : en;

  String _buildDiagnosticReportText(DiagnosticReportModel report, AIReportState journeyState) {
    final localeState = ref.watch(localeProvider);
    final isArabic = localeState.languageCode == 'ar';

    final labelDevice = isArabic ? 'اسم الجهاز' : 'Device';
    final labelProblem = isArabic ? 'وصف العطل' : 'Problem';
    final labelSolution = isArabic ? 'خطوات الحل' : 'Solution';

    final lines = <String>[
      '$labelDevice: ${report.primaryDiagnosis.faultName}',
      '$labelProblem: ${report.primaryDiagnosis.mechanicalExplanation}',
    ];

    if (journeyState.diagnosisSolved && report.actionableSteps.isNotEmpty) {
      lines.add('$labelSolution:');
      lines.addAll(report.actionableSteps);
    }

    return lines.join('\n');
  }

  void initializeOshaChecklist(List<String> questions) {
    if (oshaCheckedStates.length != questions.length) {
      oshaCheckedStates = List<bool>.filled(questions.length, false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final engineState = ref.watch(diagnosticEngineStateProvider);
    final journeyState = ref.watch(aiReportProvider);
    final localeState = ref.watch(localeProvider);
    final bool isRtl = localeState.languageCode == 'ar';
    final String appBarTitle = isRtl ? 'نتيجة التشخيص الذكي' : 'Smart Diagnosis Result';
        final String emptyWarningText = isRtl ? '⚠️ تنبيه فني: لم يتم تسجيل مدخلات التشخيص أو تفاصيل العطل في الصفحة السابقة. يرجى إدخال تفاصيل المشكلة أدناه لبدء التشخيص.' : '⚠️ Technical alert: diagnostics input or fault details were not recorded on the previous page. Please enter your problem details in the inquiry field below to start.';
    final String partsTitle = isRtl ? 'المكونات المشتبه بها:' : 'Suspected components:';
    final String noPartsText = isRtl ? 'لا توجد قطع غيار محددة.' : 'No parts specified.';
    final String causesTitle = isRtl ? 'الأسباب المحتملة:' : 'Potential causes:';
    final String noCausesText = isRtl ? 'لا توجد أسباب محددة.' : 'No specific causes specified.';
    final String stepsTitle = isRtl ? 'خطوات الفحص:' : 'Inspection steps:';
    final String viewAllStepsLabel = isRtl ? 'تصفح جميع خطوات الفحص' : 'Browse all inspection steps';
    final String noStepsText = isRtl ? 'لا توجد خطوات متاحة.' : 'No steps available.';
    final String previousButtonLabel = isRtl ? 'السابق' : 'Previous';
    final String nextButtonLabel = isRtl ? 'التالي' : 'Next';
 
    final String listeningHint = isRtl ? 'جاري الاستماع...' : 'Listening...';
    final String feedbackHint = isRtl ? 'اكتب ملاحظاتك هنا...' : 'Type your feedback here...';
    final String sendFeedbackLabel = isRtl ? '💬 اسأل المساعد الذكي' : '💬 Ask Smart Assistant';
    final String maintainButtonLabel = isRtl ? 'كيف تحافظ على المعدة؟ 💡' : 'How to maintain the machine? 💡';
    final String newJourneyButtonLabel = isRtl ? 'ابدأ رحلة جديدة 🔄' : 'Start a new journey 🔄';
    final String oshaTitle = isRtl ? '⚠️ تقييم السلامة قبل البدء' : '⚠️ Safety Assessment Before Starting';
    final String oshaNoRisksText = isRtl ? 'لا توجد مخاطر محددة حالياً.' : 'No specific risks at this time.';
    final String footerButtonLabel = isRtl ? 'المساعدة بالبحث عن قطع الغيار وشركات الصيانة 🛒' : 'Help find parts and service companies 🛒';

    final String dialogAllStepsTitle = isRtl ? 'جميع خطوات الفحص' : 'All inspection steps';
    final String dialogCloseLabel = isRtl ? 'إغلاق' : 'Close';
    // debug prints حُذفت في Phase 6

    if (engineState is AsyncData && engineState.value != null) {
      if (activeReport == null || activeReport != engineState.value) {
        activeReport = engineState.value;
        // activeReport set
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _localReport = activeReport;
              _syncVerificationNodes(activeReport!);
            });
          }
        });
      }
    }

    bool showEmptyWarning = activeReport == null && !engineState.isLoading;

    // To prevent null crashes and maintain layout structure, we provide a safe fallback empty chassis
    final safeReport = activeReport ?? DiagnosticReportModel(
      primaryDiagnosis: PrimaryDiagnosis(
        faultName: _localeText('بانتظار المدخلات', 'Waiting for input'),
        confidenceScore: 0,
        mechanicalExplanation: _localeText('يرجى إدخال تفاصيل العطل لبدء التشخيص وتحديد الأسباب المحتملة.', 'Please enter fault details to start diagnosis and identify possible causes.'),
      ),
      differentialDiagnoses: [],
      oshaSafetyAlerts: [],
      dynamicRiskQuestions: [],
      actionableSteps: [],
      potentialPartsToInspect: [],
    );

    final primary = safeReport.primaryDiagnosis;
    final journeyCauseLabel = journeyState.currentCauseIndex >= 0
        ? _localeText('السبب الحالي: ${journeyState.currentCauseIndex + 1}', 'Current cause: ${journeyState.currentCauseIndex + 1}')
        : null;
    final journeyStepLabel = journeyState.currentInspectionStep >= 0
        ? _localeText('الخطوة الحالية: ${journeyState.currentInspectionStep + 1}', 'Current step: ${journeyState.currentInspectionStep + 1}')
        : null;
    final journeyStatusLabel = journeyState.diagnosisSolved
        ? _localeText('الحالة: تم حل التشخيص', 'Status: Diagnosis solved')
        : journeyState.diagnosisCompleted
            ? _localeText('الحالة: انتهت الرحلة', 'Status: Journey completed')
            : null;
    final displayExplanation = _buildDiagnosticReportText(safeReport, journeyState);
    final displayedInspectionStepIndex = safeReport.actionableSteps.isNotEmpty && journeyState.currentInspectionStep >= 0 && journeyState.currentInspectionStep < safeReport.actionableSteps.length
        ? journeyState.currentInspectionStep
        : currentStepIndex;
    final bool isLastInspectionStep = safeReport.actionableSteps.isNotEmpty && displayedInspectionStepIndex == safeReport.actionableSteps.length - 1;
    final Widget safetyAssessmentWidget = (() {
      final fallbackAlerts = [
        'معايير أوشا حتمية: اعزل واقفل مصادر التغذية الأساسية بقفل وحامل بطاقات معتمد',
        'تأكد من تصفير الضغوط الداخلية المخزنة بالدوائر قبل مباشرة التتبع الميداني',
        'هل قمت بالتحقق من خلو بيئة العمل المحيطة من أي سوائل أو غازات قابلة للاشتعال؟',
        'هل ترتدي حالياً قفازات العزل الحراري المعتمدة ونظارات الحماية الشخصية لحمايتك؟'
      ];

      final List<String> allItems = [];
      for (var item in [...safeReport.oshaSafetyAlerts, ...safeReport.dynamicRiskQuestions]) {
        final trimmed = item.trim();
        if (trimmed.isEmpty) continue;
        bool isFallback = false;
        for (var fb in fallbackAlerts) {
          if (trimmed.contains(fb) || fb.contains(trimmed)) {
            isFallback = true;
            break;
          }
        }
        if (!isFallback) {
          allItems.add(trimmed);
        }
      }

      if (allItems.isEmpty) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            isRtl
                ? 'لم يحدد الذكاء الاصطناعي مخاطر خاصة لهذه الحالة.'
                : 'AI did not identify specific safety risks for this case.',
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 12,
              fontStyle: FontStyle.italic,
              fontFamily: 'Tajawal',
            ),
          ),
        );
      }

      String? riskLevelStr;
      String? reasonStr;
      final List<String> precautions = [];

      for (var item in allItems) {
        if (item.contains('مستوى الخطورة') || 
            item.toLowerCase().contains('risk level') || 
            item.toLowerCase().contains('severity') || 
            item.toLowerCase().contains('danger level')) {
          riskLevelStr = item;
        } else if (item.contains('السبب') || 
                   item.toLowerCase().contains('reason') || 
                   item.toLowerCase().contains('cause') || 
                   item.toLowerCase().contains('why')) {
          reasonStr = item;
        } else {
          precautions.add(item);
        }
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (riskLevelStr != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6.0),
              child: Row(
                children: [
                  const Icon(Icons.shield_outlined, size: 16, color: Colors.blueGrey),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: (() {
                        final lower = riskLevelStr!.toLowerCase();
                        if (lower.contains('منخفض') || lower.contains('low')) {
                          return const Color(0xFF16A34A);
                        } else if (lower.contains('متوسط') || lower.contains('medium') || lower.contains('moderate')) {
                          return const Color(0xFFEAB308);
                        } else if (lower.contains('مرتفع') || lower.contains('high') || lower.contains('critical')) {
                          return const Color(0xFFDC2626);
                        }
                        return Colors.grey;
                      })(),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      riskLevelStr!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Tajawal',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
          if (reasonStr != null) ...[
            Text(
              reasonStr!,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                fontFamily: 'Tajawal',
              ),
            ),
            const SizedBox(height: 8),
          ],
          if (precautions.isNotEmpty) ...[
            ...precautions.map((p) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle_outline, size: 14, color: Colors.red.shade600),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      p,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black87,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ],
      );
    })();
    final bool isInsufficientData = !engineState.isLoading && (
        safeReport.differentialDiagnoses.isEmpty || 
        safeReport.actionableSteps.isEmpty || 
        safeReport.primaryDiagnosis.faultName.isEmpty ||
        safeReport.primaryDiagnosis.faultName == 'بانتظار المدخلات' || 
        safeReport.primaryDiagnosis.faultName == 'Waiting for input'
    );

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.white,
        drawer: const CustomAppDrawer(),
        appBar: AppBar(
          title: Text(appBarTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
          backgroundColor: Colors.transparent, // APPBAR FIX
          centerTitle: true,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black87),
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // INJECT ADVISORY NOTIFICATION OR LOADING
                    if (engineState.isLoading)
                      EngineeringDiagnosisLoadingView(isRtl: isRtl),

                     if (isInsufficientData) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFCA5A5), width: 1.5),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 24),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    isRtl 
                                        ? 'المعلومات الحالية غير كافية لإنتاج تشخيص موثوق.' 
                                        : 'Current information is insufficient for a reliable diagnosis.',
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF991B1B), fontFamily: 'Tajawal'),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(color: Color(0xFFFEE2E2), height: 24),
                            Text(
                              '${isRtl ? "اسم الجهاز:" : "Device:"} ${safeReport.primaryDiagnosis.faultName}',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B), fontFamily: 'Tajawal'),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${isRtl ? "وصف المشكلة:" : "Fault Description:"} ${safeReport.primaryDiagnosis.mechanicalExplanation}',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF475569), fontFamily: 'Tajawal', height: 1.4),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFDC2626),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                icon: const Icon(Icons.arrow_back, size: 16),
                                 label: Text(
                           isRtl ? 'العودة لتعايل البيانات' : 'Back to Edit Info',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'Tajawal'),
                                ),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                    // ADVISOR GAUGE
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 80,
                          height: 80,
                          child: CircularProgressIndicator(
                            value: primary.confidenceScore == 0 ? 1.0 : primary.confidenceScore / 100,
                            backgroundColor: Colors.grey.shade200,
                            color: primary.confidenceScore == 0 ? Colors.grey.shade300 : Colors.green,
                            strokeWidth: 8,
                          ),
                        ),
                        Text(
                          '${primary.confidenceScore}%',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primary.confidenceScore == 0 ? Colors.grey : Colors.green),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // PURGE SECTION: Direct diagnosis name
                    Text(
                      primary.faultName, 
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A237E)),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      displayExplanation,
                      style: const TextStyle(fontSize: 13, color: Colors.black54),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 12),

                    // CAUSES GRID
                    Text(causesTitle, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    if (safeReport.differentialDiagnoses.isEmpty)
                      Text(noCausesText, style: const TextStyle(color: Colors.grey)),
                    ...List.generate(safeReport.differentialDiagnoses.length, (index) {
                      final cause = safeReport.differentialDiagnoses[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          '${index + 1}. ${cause.faultName} - ${cause.probability}%',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black87),
                        ),
                      );
                    }),
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 12),

                    // PARTS SECTION
                    Text(partsTitle, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    if (safeReport.potentialPartsToInspect.isEmpty)
                      Text(noPartsText, style: const TextStyle(color: Colors.grey)),
                    ...List.generate(safeReport.potentialPartsToInspect.length, (index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.build, size: 14, color: Colors.blueGrey),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                safeReport.potentialPartsToInspect[index],
                                style: const TextStyle(fontSize: 13, color: Colors.black87),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 12),

                    // STEPPER SECTOR
                    Text(stepsTitle, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    if (safeReport.actionableSteps.isNotEmpty) ...[
                      Text(
                        _localeText('الخطوة ${displayedInspectionStepIndex + 1} من ${safeReport.actionableSteps.length}', 'Step ${displayedInspectionStepIndex + 1} of ${safeReport.actionableSteps.length}'),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, height: 1.4),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                                        child: Text(
                          _localeText('الخطوة ${displayedInspectionStepIndex + 1}: ${safeReport.actionableSteps[displayedInspectionStepIndex]}', 'Step ${displayedInspectionStepIndex + 1}: ${safeReport.actionableSteps[displayedInspectionStepIndex]}'),
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, height: 1.5),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text(dialogAllStepsTitle),
                              content: SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: safeReport.actionableSteps.asMap().entries.map((e) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8.0),
                                    child: Text('${e.key + 1}. ${e.value}', style: const TextStyle(fontSize: 13)),
                                  )).toList(),
                                ),
                              ),
                              actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(dialogCloseLabel))],
                            )
                          );
                        },
                        icon: const Icon(Icons.list_alt, size: 16),
                        label: Text(viewAllStepsLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ] else ...[
                      Text(noStepsText, style: const TextStyle(color: Colors.grey)),
                    ],
                    const SizedBox(height: 12),

                    // زر "السابق" — يعمل طالما لم نكن في الخطوة الأولى
                    if (safeReport.actionableSteps.isNotEmpty && displayedInspectionStepIndex > 0)
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), padding: const EdgeInsets.symmetric(horizontal: 12)),
                        icon: const Icon(Icons.arrow_forward_ios, size: 12),
                        label: Text(previousButtonLabel, style: const TextStyle(fontSize: 12)),
                        onPressed: displayedInspectionStepIndex <= 0
                            ? null
                            : () => ref.read(aiReportProvider.notifier).goToPreviousInspectionStep(
                                totalSteps: safeReport.actionableSteps.length,
                              ),
                      ),
                    // زر "التالي" — يعمل طالما لم نصل للخطوة الأخيرة
                    if (safeReport.actionableSteps.isNotEmpty && !isLastInspectionStep)
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), padding: const EdgeInsets.symmetric(horizontal: 12)),
                        icon: const Icon(Icons.arrow_back_ios, size: 12),
                        label: Text(nextButtonLabel, style: const TextStyle(fontSize: 12)),
                        onPressed: displayedInspectionStepIndex >= safeReport.actionableSteps.length - 1
                            ? null
                            : () => ref.read(aiReportProvider.notifier).goToNextInspectionStep(
                                totalSteps: safeReport.actionableSteps.length,
                              ),
                      ),
                    if (safeReport.actionableSteps.isNotEmpty && isLastInspectionStep)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF16A34A),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.verified_rounded, size: 18),
                            label: Text(
                              isRtl ? 'اعتماد التشخيص ومشاركة المعرفة في الموسوعة الموثقة' : 'Approve & Share Knowledge in Verified Encyclopedia',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                            onPressed: _isSent || journeyState.diagnosisCompleted || journeyState.diagnosisSolved ? null : () {
                              final deviceName = safeReport.primaryDiagnosis.faultName.isNotEmpty
                                  ? safeReport.primaryDiagnosis.faultName
                                  : (isRtl ? 'جهاز غير محدد' : 'Unspecified device');
                              final systemType = safeReport.potentialPartsToInspect.isNotEmpty
                                  ? safeReport.potentialPartsToInspect.first
                                  : (isRtl ? 'عام وصناعي' : 'General industrial');

                              _showPublisherDialog(
                                context: context,
                                isRtl: isRtl,
                                deviceName: deviceName,
                                systemType: systemType,
                                safeReport: safeReport,
                              );

                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                backgroundColor: const Color(0xFF16A34A),
                                content: Text(
                                  isRtl
                                      ? '✅ تم إرسال التشخيص لمراجعة الإدارة قبل النشر في الموسوعة.'
                                      : '✅ Diagnosis sent for admin review before publishing.',
                                ),
                              ));
                            },
                          ),
                          const SizedBox(height: 10),
                          // ❌ تصعيد إلى الخبراء → Expert Community Queue
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFB91C1C),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.escalator_warning_rounded, size: 18),
                            label: Text(
                              isRtl ? 'نشر العطل في مجتمع الخبراء للمساعدة في الحل' : 'Post Fault to Experts Community for Help',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                            onPressed: _isSent || journeyState.diagnosisCompleted || journeyState.diagnosisSolved ? null : () {
                              final deviceName = safeReport.primaryDiagnosis.faultName.isNotEmpty
                                  ? safeReport.primaryDiagnosis.faultName
                                  : (isRtl ? 'جهاز غير محدد' : 'Unspecified device');
                              final systemType = safeReport.potentialPartsToInspect.isNotEmpty
                                  ? safeReport.potentialPartsToInspect.first
                                  : (isRtl ? 'عام وصناعي' : 'General industrial');
                              final excludedCauses = safeReport.differentialDiagnoses
                                  .map((d) => '• ${d.faultName}')
                                  .join('\n');
                              final steps = safeReport.actionableSteps.asMap().entries
                                  .map((e) => '${e.key + 1}. ${e.value}')
                                  .join('\n');
                              final chatLogMarkdown = _chatHistory.isNotEmpty
                                  ? '\n\n💬 ' + (isRtl ? 'استفسارات ومداولات الفحص مع المساعد الذكي:' : 'Diagnostic consultation logs with AI Assistant:') + '\n' +
                                      _chatHistory.map((m) => '• ${m.isUser ? (isRtl ? "الفني" : "Technician") : (isRtl ? "المساعد" : "AI")}: ${m.text}').join('\n')
                                  : '';
                              final summary =
                                  '${isRtl ? 'الجهاز' : 'Device'}: $deviceName\n'
                                  '${isRtl ? 'وصف العطل' : 'Fault'}: ${safeReport.primaryDiagnosis.mechanicalExplanation}\n'
                                  '${excludedCauses.isNotEmpty ? "\n${isRtl ? 'أسباب مستبعدة' : 'Reviewed causes'}:\n$excludedCauses" : ""}\n'
                                  '${steps.isNotEmpty ? "\n${isRtl ? 'فحوصات تمت' : 'Inspections done'}:\n$steps" : ""}'
                                  '$chatLogMarkdown';

                              ref.read(forumProvider.notifier).submitForReview(
                                author: isRtl ? 'محرك التشخيص الذكي' : 'AI Diagnostic Engine',
                                specialty: '[Expert] $systemType',
                                title: isRtl
                                    ? '🆘 [خبراء] $deviceName — يحتاج مراجعة'
                                    : '🆘 [Expert] $deviceName — needs review',
                                description: summary,
                                category: '[Expert] $systemType',
                                chatLogs: _chatHistory.isNotEmpty ? _chatHistory.map((m) => m.toJson()).toList() : null,
                              );

                              setState(() => _isSent = true);

                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                backgroundColor: const Color(0xFFB91C1C),
                                content: Text(
                                  isRtl
                                      ? '❌ تم تصعيد الحالة لمجتمع الخبراء بعد مراجعة الإدارة.'
                                      : '❌ Case escalated to expert community after admin review.',
                                ),
                              ));
                            },
                          ),
                        ],
                      ),
                    // بطاقة المشاركة (_showShareCard) — حُذفت في Phase 6 (كانت ميتة: لا شيء يضع _showShareCard = true)
                    if (!safeReport.actionableSteps.isNotEmpty || !isLastInspectionStep)
                      const SizedBox(height: 12),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 12),

                    // LIVE FEED INPUT
                    TextField(
                      controller: _feedbackController,
                      maxLines: 2,
                      minLines: 1,
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: _isListening ? listeningHint : feedbackHint,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        suffixIcon: IconButton(
                          tooltip: isRtl ? 'اضغط وتحدث الآن...' : 'Tap and speak now...',
                          icon: Icon(
                            _isListening ? Icons.mic : Icons.mic_none,
                            color: _isListening ? Colors.red : Colors.blue,
                          ),
                          onPressed: () async {
                            if (_isListening) {
                              // إيقاف الاستماع
                              await _speech.stop();
                              if (mounted) setState(() => _isListening = false);
                            } else {
                              if (!_speechAvailable) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                  content: Text(isRtl
                                      ? '⚠️ التعرف على الكلام غير مدعوم على هذا الجهاز.'
                                      : '⚠️ Speech recognition is not supported on this device.'),
                                  backgroundColor: Colors.orange,
                                ));
                                return;
                              }
                              setState(() => _isListening = true);
                              final localeId = await resolveBestSttLocale(_speech, isRtl);
                              await _speech.listen(
                                onResult: (result) {
                                  if (mounted) {
                                    setState(() {
                                      _feedbackController.text = result.recognizedWords;
                                    });
                                  }
                                },
                                localeId: localeId,
                                listenMode: stt.ListenMode.dictation,
                                listenFor: const Duration(seconds: 30),
                                pauseFor: const Duration(seconds: 4),
                                listenOptions: stt.SpeechListenOptions(
                                  localeId: localeId,
                                  listenMode: stt.ListenMode.dictation,
                                  partialResults: true,
                                  cancelOnError: false,
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isRtl 
                          ? "يمكنك إرفاق صورة أو أكثر للعطل (اختياري)، مثل شاشة الخطأ أو الجزء المتضرر، لتحسين دقة التشخيص."
                          : "You can attach one or more photos of the fault (optional), such as error screens or damaged parts, to improve diagnostic accuracy.",
                      style: const TextStyle(fontSize: 10, color: Colors.grey, fontFamily: 'Tajawal'),
                    ),
                    const SizedBox(height: 6),
                    if (_attachedImages.isNotEmpty)
                      SizedBox(
                        height: 60,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _attachedImages.length,
                          itemBuilder: (context, index) {
                            return Stack(
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    image: DecorationImage(
                                      image: FileImage(File(_attachedImages[index])),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: -2,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _attachedImages.removeAt(index);
                                      });
                                    },
                                    child: Container(
                                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                      padding: const EdgeInsets.all(2),
                                      child: const Icon(Icons.close, size: 10, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    Align(
                      alignment: isRtl ? Alignment.centerRight : Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.add_photo_alternate_rounded, size: 16),
                        label: Text(
                           isRtl ? 'إرفاق صورة' : 'Attach photo',
                          style: const TextStyle(fontSize: 11, fontFamily: 'Tajawal'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.send, size: 16),
                        label: Text(sendFeedbackLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        onPressed: () {
                          final String feedbackText = _feedbackController.text.trim();
                          _openContextualChat(
                            initialQuestion: feedbackText.isNotEmpty ? feedbackText : null,
                            report: safeReport,
                            isRtl: isRtl,
                          );
                          _feedbackController.clear();
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ACTIONS
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal.shade600,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            icon: const Icon(Icons.lightbulb_outline, size: 16),
                            label: Text(maintainButtonLabel, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => PreventativeMaintenanceScreen(faultName: primary.faultName)),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueGrey.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            icon: const Icon(Icons.refresh, size: 16),
                            label: Text(newJourneyButtonLabel, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            onPressed: () {
                              Navigator.popUntil(context, (route) => route.isFirst);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // OSHA INTERLOCK
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.shade200, width: 1.5),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 20),
                              const SizedBox(width: 8),
                              Text(oshaTitle, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.red.shade800)),
                            ],
                          ),
                          const Divider(color: Color(0xFFFFCC80)),
                          const SizedBox(height: 4),
                          safetyAssessmentWidget,
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // FOOTER
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.shopping_cart, size: 18),
                        label: Text(footerButtonLabel, style: const TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade800,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ProcurementAndCompaniesScreen()),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    ]
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }


  void _showPublisherDialog({
    required BuildContext context,
    required bool isRtl,
    required String deviceName,
    required String systemType,
    required dynamic safeReport,
  }) {
    final commentController = TextEditingController();
    final nameController = TextEditingController();
    final experienceController = TextEditingController();
    bool showName = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Directionality(
              textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
              child: AlertDialog(
                title: Text(
                   isRtl ? 'بيانات ناشر التقرير' : 'Enter Publisher Information',
                  style: const TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold, fontSize: 16),
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isRtl
                            ? 'يمكنك إدخال بياناتك اختيارياً لتظهر كمساهم في حل هذا العطل عند اعتماده ونشره بالموسوعة.'
                            : 'You can optionally enter your information to appear as a contributor to this solution when published.',
                        style: const TextStyle(fontFamily: 'Tajawal', fontSize: 13, color: Color(0xFF475569)),
                      ),
                      const SizedBox(height: 16),
                      // حقل اسم الناشر
                      TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                           labelText: isRtl ? 'الاسم (اختياري)' : 'Publisher Name (Optional)',
                          labelStyle: const TextStyle(fontFamily: 'Tajawal', fontSize: 12),
                          border: const OutlineInputBorder(),
                        ),
                        style: const TextStyle(fontFamily: 'Tajawal', fontSize: 13),
                      ),
                      const SizedBox(height: 12),
                      // حقل الخبرة
                      TextField(
                        controller: experienceController,
                        decoration: InputDecoration(
                           labelText: isRtl ? 'الخبرة / المسمى الوظيفي (اختياري)' : 'Experience / Title (Optional)',
                          labelStyle: const TextStyle(fontFamily: 'Tajawal', fontSize: 12),
                          border: const OutlineInputBorder(),
                        ),
                        style: const TextStyle(fontFamily: 'Tajawal', fontSize: 13),
                      ),
                      const SizedBox(height: 12),
                      // حقل تعليق اختياري
                      TextField(
                        controller: commentController,
                        maxLines: 2,
                        decoration: InputDecoration(
                           labelText: isRtl ? 'أضف تعليقاً أو ملاحظة (اختياري)' : 'Add Comment or Note (Optional)',
                          labelStyle: const TextStyle(fontFamily: 'Tajawal', fontSize: 12),
                          border: const OutlineInputBorder(),
                        ),
                        style: const TextStyle(fontFamily: 'Tajawal', fontSize: 13),
                      ),
                      const SizedBox(height: 12),
                      // خيار إظهار الاسم
                      CheckboxListTile(
                        title: Text(
                               isRtl ? 'إظهار اسمي وخبرتي مع الحل' : 'Show my name and experience with the solution',
                          style: const TextStyle(fontFamily: 'Tajawal', fontSize: 12),
                        ),
                        value: showName,
                        onChanged: (val) {
                          setState(() {
                            showName = val ?? true;
                          });
                        },
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                       isRtl ? 'إلغاء' : 'Cancel',
                      style: const TextStyle(fontFamily: 'Tajawal', color: Colors.grey),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      Navigator.pop(context);

                      final causesList = safeReport.differentialDiagnoses
                          .map((d) => '• ${d.faultName} (${d.probability}%)')
                          .join('\n');
                      final steps = safeReport.actionableSteps.asMap().entries
                          .map((e) => '${e.key + 1}. ${e.value}')
                          .join('\n');

                      final chatLogMarkdown = _chatHistory.isNotEmpty
                          ? '\n\n### [TECHNICAL_CHAT_LOGS]\n' +
                              _chatHistory.map((m) => '• [${m.isUser ? (isRtl ? "الفني" : "Technician") : (isRtl ? "المساعد الذكي" : "AI Assistant")}]: ${m.text}').join('\n')
                          : '';

                      final summary = 
                        '### [DEVICE_NAME]\n$deviceName\n\n'
                        '### [FAULT_DESCRIPTION]\n${safeReport.primaryDiagnosis.mechanicalExplanation}\n\n'
                        '### [FAULT_CAUSE]\n$causesList\n\n'
                        '### [RESOLUTION_STEPS]\n$steps\n\n'
                        '### [ATTACHED_IMAGES]\n${_attachedImages.join('\n')}\n\n'
                        '### [PUBLISHER_NAME]\n${nameController.text.trim()}\n\n'
                        '### [PUBLISHER_EXP]\n${experienceController.text.trim()}\n\n'
                        '### [PUBLISHER_COMMENT]\n${commentController.text.trim()}\n\n'
                        '### [SHOW_NAME]\n$showName'
                        '$chatLogMarkdown';

                      ref.read(forumProvider.notifier).submitForReview(
                        author: isRtl ? 'محرك التشخيص الذكي' : 'AI Diagnostic Engine',
                        specialty: '[KB] $systemType',
                        title: isRtl
                            ? '📘 [موسوعة] $deviceName'
                            : '📘 [KB] $deviceName',
                        description: summary,
                        category: '[KB] $systemType',
                        imagePath: _attachedImages.isNotEmpty ? _attachedImages.first : null,
                        chatLogs: _chatHistory.isNotEmpty ? _chatHistory.map((m) => m.toJson()).toList() : null,
                      );

                      _attachedImages.clear();

                      ref.read(aiReportProvider.notifier).recordCurrentCauseResult('succeeded');
                      setState(() => _isSent = true);

                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        backgroundColor: const Color(0xFF16A34A),
                        content: Text(
                          isRtl
                              ? '✅ تم إرسال التشخيص لمراجعة الإدارة قبل النشر في الموسوعة.'
                              : '✅ Diagnosis sent for admin review before publishing.',
                        ),
                      ));
                    },
                    child: Text(
                       isRtl ? 'إرسال للمراجعة' : 'Submit for Review',
                      style: const TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
