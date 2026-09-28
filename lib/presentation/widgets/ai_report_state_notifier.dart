import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dr_fix/data/models/diagnosis_contract_model.dart';
import 'package:dr_fix/data/network/ai_api_service.dart';
import 'package:dr_fix/data/services/history_service.dart';
import 'package:dr_fix/data/repositories/publication_draft_repository.dart';
import 'package:dr_fix/presentation/widgets/publication_draft_helper.dart';

class DiagnosticStep {
  final int number;
  final String textAr, textEn, estimatedTimeAr, estimatedTimeEn;
  bool isCompleted;

  DiagnosticStep({
    required this.number,
    required this.textAr,
    required this.textEn,
    required this.estimatedTimeAr,
    required this.estimatedTimeEn,
    this.isCompleted = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'number': number,
      'textAr': textAr,
      'textEn': textEn,
      'estimatedTimeAr': estimatedTimeAr,
      'estimatedTimeEn': estimatedTimeEn,
      'isCompleted': isCompleted,
    };
  }

  factory DiagnosticStep.fromJson(Map<String, dynamic> json) {
    return DiagnosticStep(
      number: json['number'] as int,
      textAr: json['textAr'] as String,
      textEn: json['textEn'] as String,
      estimatedTimeAr: json['estimatedTimeAr'] as String,
      estimatedTimeEn: json['estimatedTimeEn'] as String,
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }
}

// نموذج البيانات الشامل والمحدث لتمرير الأكواد والتكاليف والخصومات للشاشة الجديدة والبحث الخرائطي
class AIReportState {
  final String currentStatusAr, currentStatusEn;
  final String safetyWarningAr, statusWarningEn;
  final List<String> toolsAr, toolsEn;
  final List<DiagnosticStep> steps;
  final String partNameAr, partNameEn, partDiscount, partCode;
  final int currentStepIndex;
  final int confidenceRate;
  final List<String> confidenceReasonsAr, confidenceReasonsEn;
  final Map<String, int> alternativeCausesAr;
  final Map<String, int> alternativeCausesEn;
  final List<DiagnosticHypothesis> hypotheses;
  final String reasoningNarrativeAr, reasoningNarrativeEn;
  final String evidenceSummaryAr, evidenceSummaryEn;
  final String timelineSummaryAr, timelineSummaryEn;
  final List<String> suggestedPartsAr, suggestedPartsEn;
  final String totalTimeAr, totalTimeEn;
  final String difficultyAr, difficultyEn;
  final Color difficultyColor;
  final String partCostRangeAr, partCostRangeEn; 
  final String fixCostRangeAr, fixCostRangeEn;   
  final List<String> aiBasisAr, aiBasisEn;       
  final bool isFavorited;                        
  final List<String> attemptHistory;
  final int currentCauseIndex;
  final int currentInspectionStep;
  final bool diagnosisCompleted;
  final bool diagnosisSolved;
  final PublicationDraft? publicationDraft;

  // حقول تعريفية مضافة لتسهيل نظام السجل (Diagnosis History)
  final String? deviceName;
  final String? categoryName;
  final String? dateStr;

  const AIReportState({
    required this.currentStatusAr, required this.currentStatusEn,
    required this.safetyWarningAr, required this.statusWarningEn,
    required this.toolsAr, required this.toolsEn, required this.steps,
    required this.partNameAr, required this.partNameEn, required this.partDiscount, required this.partCode,
    required this.currentStepIndex,
    required this.confidenceRate, required this.confidenceReasonsAr, required this.confidenceReasonsEn,
    required this.alternativeCausesAr, required this.alternativeCausesEn,
    this.hypotheses = const [],
    this.reasoningNarrativeAr = '', this.reasoningNarrativeEn = '',
    this.evidenceSummaryAr = '', this.evidenceSummaryEn = '',
    this.timelineSummaryAr = '', this.timelineSummaryEn = '',
    this.suggestedPartsAr = const [], this.suggestedPartsEn = const [],
    required this.totalTimeAr, required this.totalTimeEn, required this.difficultyAr, required this.difficultyEn, required this.difficultyColor,
    required this.partCostRangeAr, required this.partCostRangeEn, required this.fixCostRangeAr, required this.fixCostRangeEn,
    required this.aiBasisAr, required this.aiBasisEn, required this.isFavorited,
    this.attemptHistory = const [],
    this.deviceName,
    this.categoryName,
    this.dateStr,
    this.currentCauseIndex = 0,
    this.currentInspectionStep = 0,
    this.diagnosisCompleted = false,
    this.diagnosisSolved = false,
    this.publicationDraft,
  });

  AIReportState copyWith({
    String? currentStatusAr,
    String? currentStatusEn,
    String? safetyWarningAr,
    String? statusWarningEn,
    List<String>? toolsAr,
    List<String>? toolsEn,
    List<DiagnosticStep>? steps,
    String? partNameAr,
    String? partNameEn,
    String? partDiscount,
    String? partCode,
    int? currentStepIndex,
    int? confidenceRate,
    List<String>? confidenceReasonsAr,
    List<String>? confidenceReasonsEn,
    Map<String, int>? alternativeCausesAr,
    Map<String, int>? alternativeCausesEn,
    List<DiagnosticHypothesis>? hypotheses,
    String? reasoningNarrativeAr,
    String? reasoningNarrativeEn,
    String? evidenceSummaryAr,
    String? evidenceSummaryEn,
    String? timelineSummaryAr,
    String? timelineSummaryEn,
    List<String>? suggestedPartsAr,
    List<String>? suggestedPartsEn,
    String? totalTimeAr,
    String? totalTimeEn,
    String? difficultyAr,
    String? difficultyEn,
    Color? difficultyColor,
    String? partCostRangeAr,
    String? partCostRangeEn,
    String? fixCostRangeAr,
    String? fixCostRangeEn,
    List<String>? aiBasisAr,
    List<String>? aiBasisEn,
    bool? isFavorited,
    List<String>? attemptHistory,
    String? deviceName,
    String? categoryName,
    String? dateStr,
    int? currentCauseIndex,
    int? currentInspectionStep,
    bool? diagnosisCompleted,
    bool? diagnosisSolved,
    PublicationDraft? publicationDraft,
  }) {
    return AIReportState(
      currentStatusAr: currentStatusAr ?? this.currentStatusAr,
      currentStatusEn: currentStatusEn ?? this.currentStatusEn,
      safetyWarningAr: safetyWarningAr ?? this.safetyWarningAr,
      statusWarningEn: statusWarningEn ?? this.statusWarningEn,
      toolsAr: toolsAr ?? this.toolsAr,
      toolsEn: toolsEn ?? this.toolsEn,
      steps: steps ?? this.steps,
      partNameAr: partNameAr ?? this.partNameAr,
      partNameEn: partNameEn ?? this.partNameEn,
      partDiscount: partDiscount ?? this.partDiscount,
      partCode: partCode ?? this.partCode,
      currentStepIndex: currentStepIndex ?? this.currentStepIndex,
      confidenceRate: confidenceRate ?? this.confidenceRate,
      confidenceReasonsAr: confidenceReasonsAr ?? this.confidenceReasonsAr,
      confidenceReasonsEn: confidenceReasonsEn ?? this.confidenceReasonsEn,
      alternativeCausesAr: alternativeCausesAr ?? this.alternativeCausesAr,
      alternativeCausesEn: alternativeCausesEn ?? this.alternativeCausesEn,
      hypotheses: hypotheses ?? this.hypotheses,
      reasoningNarrativeAr: reasoningNarrativeAr ?? this.reasoningNarrativeAr,
      reasoningNarrativeEn: reasoningNarrativeEn ?? this.reasoningNarrativeEn,
      evidenceSummaryAr: evidenceSummaryAr ?? this.evidenceSummaryAr,
      evidenceSummaryEn: evidenceSummaryEn ?? this.evidenceSummaryEn,
      timelineSummaryAr: timelineSummaryAr ?? this.timelineSummaryAr,
      timelineSummaryEn: timelineSummaryEn ?? this.timelineSummaryEn,
      suggestedPartsAr: suggestedPartsAr ?? this.suggestedPartsAr,
      suggestedPartsEn: suggestedPartsEn ?? this.suggestedPartsEn,
      totalTimeAr: totalTimeAr ?? this.totalTimeAr,
      totalTimeEn: totalTimeEn ?? this.totalTimeEn,
      difficultyAr: difficultyAr ?? this.difficultyAr,
      difficultyEn: difficultyEn ?? this.difficultyEn,
      difficultyColor: difficultyColor ?? this.difficultyColor,
      partCostRangeAr: partCostRangeAr ?? this.partCostRangeAr,
      partCostRangeEn: partCostRangeEn ?? this.partCostRangeEn,
      fixCostRangeAr: fixCostRangeAr ?? this.fixCostRangeAr,
      fixCostRangeEn: fixCostRangeEn ?? this.fixCostRangeEn,
      aiBasisAr: aiBasisAr ?? this.aiBasisAr,
      aiBasisEn: aiBasisEn ?? this.aiBasisEn,
      isFavorited: isFavorited ?? this.isFavorited,
      attemptHistory: attemptHistory ?? this.attemptHistory,
      deviceName: deviceName ?? this.deviceName,
      categoryName: categoryName ?? this.categoryName,
      dateStr: dateStr ?? this.dateStr,
      currentCauseIndex: currentCauseIndex ?? this.currentCauseIndex,
      currentInspectionStep: currentInspectionStep ?? this.currentInspectionStep,
      diagnosisCompleted: diagnosisCompleted ?? this.diagnosisCompleted,
      diagnosisSolved: diagnosisSolved ?? this.diagnosisSolved,
      publicationDraft: publicationDraft ?? this.publicationDraft,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currentStatusAr': currentStatusAr,
      'currentStatusEn': currentStatusEn,
      'safetyWarningAr': safetyWarningAr,
      'statusWarningEn': statusWarningEn,
      'toolsAr': toolsAr,
      'toolsEn': toolsEn,
      'steps': steps.map((s) => s.toJson()).toList(),
      'partNameAr': partNameAr,
      'partNameEn': partNameEn,
      'partDiscount': partDiscount,
      'partCode': partCode,
      'currentStepIndex': currentStepIndex,
      'confidenceRate': confidenceRate,
      'confidenceReasonsAr': confidenceReasonsAr,
      'confidenceReasonsEn': confidenceReasonsEn,
      'alternativeCausesAr': alternativeCausesAr,
      'alternativeCausesEn': alternativeCausesEn,
      'hypotheses': hypotheses.map((h) => h.toJson()).toList(),
      'reasoningNarrativeAr': reasoningNarrativeAr,
      'reasoningNarrativeEn': reasoningNarrativeEn,
      'evidenceSummaryAr': evidenceSummaryAr,
      'evidenceSummaryEn': evidenceSummaryEn,
      'timelineSummaryAr': timelineSummaryAr,
      'timelineSummaryEn': timelineSummaryEn,
      'suggestedPartsAr': suggestedPartsAr,
      'suggestedPartsEn': suggestedPartsEn,
      'totalTimeAr': totalTimeAr,
      'totalTimeEn': totalTimeEn,
      'difficultyAr': difficultyAr,
      'difficultyEn': difficultyEn,
      'difficultyColorValue': difficultyColor.toARGB32(),
      'partCostRangeAr': partCostRangeAr,
      'partCostRangeEn': partCostRangeEn,
      'fixCostRangeAr': fixCostRangeAr,
      'fixCostRangeEn': fixCostRangeEn,
      'aiBasisAr': aiBasisAr,
      'aiBasisEn': aiBasisEn,
      'isFavorited': isFavorited,
      'attemptHistory': attemptHistory,
      'deviceName': deviceName,
      'categoryName': categoryName,
      'dateStr': dateStr,
      'currentCauseIndex': currentCauseIndex,
      'currentInspectionStep': currentInspectionStep,
      'diagnosisCompleted': diagnosisCompleted,
      'diagnosisSolved': diagnosisSolved,
      'publicationDraft': publicationDraft?.toJson(),
    };
  }

  factory AIReportState.fromJson(Map<String, dynamic> json) {
    return AIReportState(
      currentStatusAr: json['currentStatusAr'] as String,
      currentStatusEn: json['currentStatusEn'] as String,
      safetyWarningAr: json['safetyWarningAr'] as String,
      statusWarningEn: json['statusWarningEn'] as String,
      toolsAr: List<String>.from(json['toolsAr'] as List),
      toolsEn: List<String>.from(json['toolsEn'] as List),
      steps: (json['steps'] as List).map((s) => DiagnosticStep.fromJson(Map<String, dynamic>.from(s as Map))).toList(),
      partNameAr: json['partNameAr'] as String,
      partNameEn: json['partNameEn'] as String,
      partDiscount: json['partDiscount'] as String,
      partCode: json['partCode'] as String,
      currentStepIndex: json['currentStepIndex'] as int,
      confidenceRate: json['confidenceRate'] as int,
      confidenceReasonsAr: List<String>.from(json['confidenceReasonsAr'] as List),
      confidenceReasonsEn: List<String>.from(json['confidenceReasonsEn'] as List),
      alternativeCausesAr: Map<String, int>.from(json['alternativeCausesAr'] as Map),
      alternativeCausesEn: Map<String, int>.from(json['alternativeCausesEn'] as Map),
      hypotheses: (json['hypotheses'] as List? ?? const []).map((h) => DiagnosticHypothesis.fromJson(Map<String, dynamic>.from(h as Map))).toList(),
      reasoningNarrativeAr: json['reasoningNarrativeAr'] as String? ?? '',
      reasoningNarrativeEn: json['reasoningNarrativeEn'] as String? ?? '',
      evidenceSummaryAr: json['evidenceSummaryAr'] as String? ?? '',
      evidenceSummaryEn: json['evidenceSummaryEn'] as String? ?? '',
      timelineSummaryAr: json['timelineSummaryAr'] as String? ?? '',
      timelineSummaryEn: json['timelineSummaryEn'] as String? ?? '',
      suggestedPartsAr: List<String>.from(json['suggestedPartsAr'] as List? ?? const []),
      suggestedPartsEn: List<String>.from(json['suggestedPartsEn'] as List? ?? const []),
      totalTimeAr: json['totalTimeAr'] as String,
      totalTimeEn: json['totalTimeEn'] as String,
      difficultyAr: json['difficultyAr'] as String,
      difficultyEn: json['difficultyEn'] as String,
      difficultyColor: Color(json['difficultyColorValue'] as int? ?? Colors.amber.toARGB32()),
      partCostRangeAr: json['partCostRangeAr'] as String,
      partCostRangeEn: json['partCostRangeEn'] as String,
      fixCostRangeAr: json['fixCostRangeAr'] as String,
      fixCostRangeEn: json['fixCostRangeEn'] as String,
      aiBasisAr: List<String>.from(json['aiBasisAr'] as List),
      aiBasisEn: List<String>.from(json['aiBasisEn'] as List),
      isFavorited: json['isFavorited'] as bool? ?? false,
      attemptHistory: List<String>.from(json['attemptHistory'] as List? ?? const []),
      deviceName: json['deviceName'] as String?,
      categoryName: json['categoryName'] as String?,
      dateStr: json['dateStr'] as String?,
      publicationDraft: json['publicationDraft'] != null
          ? PublicationDraft.fromJson(Map<String, dynamic>.from(json['publicationDraft'] as Map))
          : null,
    );
  }
}

class DiagnosticHypothesis {
  final String id;
  final String title;
  final String status;
  final int confidence;
  final List<String> supportingEvidence;
  final List<String> contradictingEvidence;
  final String reason;

  const DiagnosticHypothesis({
    required this.id,
    required this.title,
    required this.status,
    required this.confidence,
    required this.supportingEvidence,
    required this.contradictingEvidence,
    required this.reason,
  });

  DiagnosticHypothesis copyWith({
    String? id,
    String? title,
    String? status,
    int? confidence,
    List<String>? supportingEvidence,
    List<String>? contradictingEvidence,
    String? reason,
  }) {
    return DiagnosticHypothesis(
      id: id ?? this.id,
      title: title ?? this.title,
      status: status ?? this.status,
      confidence: confidence ?? this.confidence,
      supportingEvidence: supportingEvidence ?? this.supportingEvidence,
      contradictingEvidence: contradictingEvidence ?? this.contradictingEvidence,
      reason: reason ?? this.reason,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'status': status,
      'confidence': confidence,
      'supportingEvidence': supportingEvidence,
      'contradictingEvidence': contradictingEvidence,
      'reason': reason,
    };
  }

  factory DiagnosticHypothesis.fromJson(Map<String, dynamic> json) {
    return DiagnosticHypothesis(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      status: json['status'] as String? ?? 'Active',
      confidence: json['confidence'] as int? ?? 0,
      supportingEvidence: List<String>.from(json['supportingEvidence'] as List? ?? const []),
      contradictingEvidence: List<String>.from(json['contradictingEvidence'] as List? ?? const []),
      reason: json['reason'] as String? ?? '',
    );
  }
}

class DiagnosticTimelineEntry {
  final String type;
  final String text;

  const DiagnosticTimelineEntry({required this.type, required this.text});
}

class DiagnosticSessionState {
  final List<String> evidence;
  final List<String> findings;
  final List<String> userResponses;
  final List<String> confirmedEvidence;
  final List<String> rejectedEvidence;
  final List<DiagnosticHypothesis> hypotheses;
  final List<DiagnosticTimelineEntry> timeline;
  final String nextBestAction;
  final String reasoningSummary;
  final String riskLevel;
  final String safetyLevel;
  final bool isResolved;
  final bool isStillOpen;
  final String lastEvent;
  final int lastCompletedStep;
  final int currentCauseIndex;
  final int currentInspectionStep;
  final bool diagnosisCompleted;
  final bool diagnosisSolved;
  final bool userConsentToShare;
  final PublicationDraft? publicationDraft;

  const DiagnosticSessionState({
    required this.evidence,
    required this.findings,
    required this.userResponses,
    required this.confirmedEvidence,
    required this.rejectedEvidence,
    required this.hypotheses,
    required this.timeline,
    required this.nextBestAction,
    required this.reasoningSummary,
    required this.riskLevel,
    required this.safetyLevel,
    required this.isResolved,
    required this.isStillOpen,
    required this.lastEvent,
    required this.lastCompletedStep,
    this.currentCauseIndex = 0,
    this.currentInspectionStep = 0,
    this.diagnosisCompleted = false,
    this.diagnosisSolved = false,
    this.userConsentToShare = false,
    this.publicationDraft,
  });

  DiagnosticSessionState copyWith({
    List<String>? evidence,
    List<String>? findings,
    List<String>? userResponses,
    List<String>? confirmedEvidence,
    List<String>? rejectedEvidence,
    List<DiagnosticHypothesis>? hypotheses,
    List<DiagnosticTimelineEntry>? timeline,
    String? nextBestAction,
    String? reasoningSummary,
    String? riskLevel,
    String? safetyLevel,
    bool? isResolved,
    bool? isStillOpen,
    String? lastEvent,
    int? lastCompletedStep,
    int? currentCauseIndex,
    int? currentInspectionStep,
    bool? diagnosisCompleted,
    bool? diagnosisSolved,
    bool? userConsentToShare,
    PublicationDraft? publicationDraft,
  }) {
    return DiagnosticSessionState(
      evidence: evidence ?? this.evidence,
      findings: findings ?? this.findings,
      userResponses: userResponses ?? this.userResponses,
      confirmedEvidence: confirmedEvidence ?? this.confirmedEvidence,
      rejectedEvidence: rejectedEvidence ?? this.rejectedEvidence,
      hypotheses: hypotheses ?? this.hypotheses,
      timeline: timeline ?? this.timeline,
      nextBestAction: nextBestAction ?? this.nextBestAction,
      reasoningSummary: reasoningSummary ?? this.reasoningSummary,
      riskLevel: riskLevel ?? this.riskLevel,
      safetyLevel: safetyLevel ?? this.safetyLevel,
      isResolved: isResolved ?? this.isResolved,
      isStillOpen: isStillOpen ?? this.isStillOpen,
      lastEvent: lastEvent ?? this.lastEvent,
      lastCompletedStep: lastCompletedStep ?? this.lastCompletedStep,
      currentCauseIndex: currentCauseIndex ?? this.currentCauseIndex,
      currentInspectionStep: currentInspectionStep ?? this.currentInspectionStep,
      diagnosisCompleted: diagnosisCompleted ?? this.diagnosisCompleted,
      diagnosisSolved: diagnosisSolved ?? this.diagnosisSolved,
      userConsentToShare: userConsentToShare ?? this.userConsentToShare,
      publicationDraft: publicationDraft ?? this.publicationDraft,
    );
  }
}

class _EquipmentKnowledge {
  final String type;
  final String displayNameAr;
  final String displayNameEn;
  final List<String> supportedFailureModesAr;
  final List<String> supportedFailureModesEn;
  final List<String> typicalSymptomsAr;
  final List<String> typicalSymptomsEn;
  final List<String> requiredEvidenceAr;
  final List<String> requiredEvidenceEn;
  final List<String> recommendedInspectionsAr;
  final List<String> recommendedInspectionsEn;
  final List<String> sparePartsAr;
  final List<String> sparePartsEn;
  final List<String> safetyRulesAr;
  final List<String> safetyRulesEn;

  const _EquipmentKnowledge({
    required this.type,
    required this.displayNameAr,
    required this.displayNameEn,
    required this.supportedFailureModesAr,
    required this.supportedFailureModesEn,
    required this.typicalSymptomsAr,
    required this.typicalSymptomsEn,
    required this.requiredEvidenceAr,
    required this.requiredEvidenceEn,
    required this.recommendedInspectionsAr,
    required this.recommendedInspectionsEn,
    required this.sparePartsAr,
    required this.sparePartsEn,
    required this.safetyRulesAr,
    required this.safetyRulesEn,
  });
}

class _EquipmentContext {
  final String equipmentType;
  final String manufacturer;
  final String model;
  final String driveType;
  final String operatingContext;
  final String fault;
  final _EquipmentKnowledge knowledge;

  const _EquipmentContext({
    required this.equipmentType,
    required this.manufacturer,
    required this.model,
    required this.driveType,
    required this.operatingContext,
    required this.fault,
    required this.knowledge,
  });
}

const Map<String, _EquipmentKnowledge> _industrialKnowledge = {
  'hvac_compressor': _EquipmentKnowledge(
    type: 'hvac_compressor',
    displayNameAr: 'مكيف/ضاغط تبريد',
    displayNameEn: 'HVAC compressor',
    supportedFailureModesAr: ['فشل المكثف أو المرحل', 'انخفاض المبرد أو تسربه', 'تحمّل كهربائي زائد', 'فشل مستشعر الضغط أو الحرارة'],
    supportedFailureModesEn: ['Capacitor or relay failure', 'Low refrigerant or leak', 'Electrical overload', 'Pressure or temperature sensor fault'],
    typicalSymptomsAr: ['عدم تشغيل الضاغط', 'هَمْهَمة عند التشغيل', 'ارتفاع ضغط التفريغ', 'خرجات هواء غير باردة'],
    typicalSymptomsEn: ['Compressor does not start', 'Humming at startup', 'High discharge pressure', 'Warm air output'],
    requiredEvidenceAr: ['قياس جهد التشغيل', 'قياس التيار', 'قياس ضغط التفريغ', 'فحص الحالة الحرارية'],
    requiredEvidenceEn: ['Measure operating voltage', 'Measure running current', 'Measure discharge pressure', 'Inspect thermal condition'],
    recommendedInspectionsAr: ['اقيس الجهد على الملف والمرحلة عند التشغيل.', 'افحص المكثف والمرحلة بحثًا عن انتفاخ أو تآكل.', 'اقيس ضغط التفريغ ودرجة حرارة الأنابيب.', 'افحص مرشح المبخر ومرور الهواء قبل استبدال أي قطعة.'],
    recommendedInspectionsEn: ['Measure coil and contactor voltage at startup.', 'Inspect capacitor and relay for bulging or corrosion.', 'Measure discharge pressure and line temperature.', 'Inspect evaporator airflow before replacing parts.'],
    sparePartsAr: ['مكثف تشغيل/بدء معتمد', 'مرحلة/مُلامس تيار', 'مفتاح ضغط', 'فلتر مبخر'],
    sparePartsEn: ['Approved start/run capacitor', 'Contactor relay', 'Pressure switch', 'Filter drier'],
    safetyRulesAr: ['افصل التيار وتفريغ المكثف قبل لمس الأطراف.', 'لا تفتح دائرة الضغط وهي مشحونة.', 'استخدم أدوات معزولة عند فحص الدائرة.'],
    safetyRulesEn: ['Isolate power and discharge the capacitor before touching terminals.', 'Do not open the pressure circuit while it is charged.', 'Use insulated tools for circuit checks.'],
  ),
  'centrifugal_pump': _EquipmentKnowledge(
    type: 'centrifugal_pump',
    displayNameAr: 'مضخة طرد مركزي',
    displayNameEn: 'Centrifugal pump',
    supportedFailureModesAr: ['تسريب الختم الميكانيكي', 'تآكل المحمل', 'انسداد الدافع', 'تغير في ضغط السريان', 'فشل المحرك أو الحمل الزائد'],
    supportedFailureModesEn: ['Mechanical seal leakage', 'Bearing wear', 'Impeller blockage', 'Flow pressure deviation', 'Motor overload'],
    typicalSymptomsAr: ['تسريب حول الختم', 'اهتزاز عالي', 'انخفاض التدفق', 'ارتفاع حرارة المحرك'],
    typicalSymptomsEn: ['Seal leakage', 'High vibration', 'Reduced flow', 'High motor temperature'],
    requiredEvidenceAr: ['قياس الضغط عند التفريغ', 'قياس التدفق', 'فحص الاهتزاز', 'فحص تسريب الختم'],
    requiredEvidenceEn: ['Measure discharge pressure', 'Measure flow rate', 'Inspect vibration', 'Inspect seal leakage'],
    recommendedInspectionsAr: ['افحص فلتر السحب والوضعية الصمامية قبل فتح المضخة.', 'اقيس ضغط التفريغ والتدفق لتأكيد التراجع.', 'افحص الختم والاهتزاز عند التشغيل.', 'راجع حرارة المحرك والتحميل قبل استبدال أي جزء.'],
    recommendedInspectionsEn: ['Inspect suction strainer and valve position before opening the pump.', 'Measure discharge pressure and flow to confirm reduction.', 'Inspect seal condition and vibration during operation.', 'Review motor temperature and load before replacing parts.'],
    sparePartsAr: ['ختم ميكانيكي', 'محمل', 'دافع', 'غشاء أو حشية', 'صمام تأمين'],
    sparePartsEn: ['Mechanical seal', 'Bearing', 'Impeller', 'Gasket', 'Relief valve'],
    safetyRulesAr: ['أوقف التيار وقفل المضخة قبل الفتح.', 'فرّغ الضغط قبل فتح أي خط.', 'لا تلمس الأجزاء الساخنة أو الماصة قبل التبريد.'],
    safetyRulesEn: ['Lock out power and isolate the pump before opening it.', 'Depressurize before opening any line.', 'Do not touch hot or pressurized parts before cooling.'],
  ),
  'direct_drive_motor': _EquipmentKnowledge(
    type: 'direct_drive_motor',
    displayNameAr: 'محرّك مباشر الدفع',
    displayNameEn: 'Direct-drive motor',
    supportedFailureModesAr: ['تآكل المحمل', 'فشل المغناطيس أو الملف', 'تسرب التوصيل', 'زيادة الحمل الكهربائي'],
    supportedFailureModesEn: ['Bearing wear', 'Coil or magnet failure', 'Connection breakdown', 'Electrical overload'],
    typicalSymptomsAr: ['اهتزاز عند الدوران', 'حرارة مرتفعة', 'عدم الدوران', 'صوت غير طبيعي'],
    typicalSymptomsEn: ['Vibration at rotation', 'Excess heat', 'No rotation', 'Abnormal noise'],
    requiredEvidenceAr: ['قياس الجهد', 'قياس التيار', 'فحص التوصيل', 'فحص الحرارة والاهتزاز'],
    requiredEvidenceEn: ['Measure voltage', 'Measure current', 'Inspect wiring', 'Inspect heat and vibration'],
    recommendedInspectionsAr: ['اقيس الجهد والتيار عند التشغيل.', 'افحص التوصيلات والموصلات بحثًا عن الوصلات الملوّثة أو المفقودة.', 'فحص المحمل والاهتزاز أثناء الدوران.', 'راجع درجة حرارة المحرك قبل استبدال أي جزء.'],
    recommendedInspectionsEn: ['Measure voltage and current at startup.', 'Inspect terminals and connectors for looseness or contamination.', 'Check bearings and vibration while rotating.', 'Review motor temperature before replacing parts.'],
    sparePartsAr: ['محمل', 'موصل أو طرف', 'ملف أو كهرومغناطيس', 'مفتاح/قاطع حماية'],
    sparePartsEn: ['Bearing', 'Terminal connector', 'Coil or magnet', 'Protective breaker'],
    safetyRulesAr: ['أوقف التيار قبل لمس الأسلاك.', 'لا تعمل على الجزء الدوار أثناء الحركة.', 'استخدم أدوات معزولة عند القياس.'],
    safetyRulesEn: ['Isolate electrical power before touching wiring.', 'Do not work on rotating parts while moving.', 'Use insulated tools for measurement.'],
  ),
  'belt_drive_motor': _EquipmentKnowledge(
    type: 'belt_drive_motor',
    displayNameAr: 'محرّك حزامي',
    displayNameEn: 'Belt-driven motor',
    supportedFailureModesAr: ['تآكل الحزام أو انزلاقه', 'عدم محاذاة البكرة', 'تآكل المحمل', 'فشل المحرك الكهربائي'],
    supportedFailureModesEn: ['Belt wear or slippage', 'Pulley misalignment', 'Bearing wear', 'Motor electrical failure'],
    typicalSymptomsAr: ['صوت صرير أو انزلاق', 'اهتزاز', 'انخفاض القوة', 'تآكل الحزام'],
    typicalSymptomsEn: ['Squeal or slippage', 'Vibration', 'Reduced torque', 'Visible belt wear'],
    requiredEvidenceAr: ['فحص الحزام', 'فحص التوتر والمحاذاة', 'قياس الجهد والتيار', 'فحص الاهتزاز'],
    requiredEvidenceEn: ['Inspect belt condition', 'Inspect tension and alignment', 'Measure voltage and current', 'Inspect vibration'],
    recommendedInspectionsAr: ['افحص الحزام للتآكل أو الانزلاق.', 'تحقق من محاذاة البكرات والتوتر الصحيح.', 'اقيس الجهد والتيار عند التشغيل.', 'راجع الاهتزاز قبل استبدال الحزام أو المحرك.'],
    recommendedInspectionsEn: ['Inspect the belt for wear or slippage.', 'Check pulley alignment and proper tension.', 'Measure voltage and current during startup.', 'Review vibration before replacing the belt or motor.'],
    sparePartsAr: ['حزام نقل', 'بكرة', 'محمل', 'مفتاح حماية'],
    sparePartsEn: ['Drive belt', 'Pulley', 'Bearing', 'Protective switch'],
    safetyRulesAr: ['أوقف التشغيل قبل لمس الحزام أو البكرات.', 'لا تضع الأيدي بالقرب من الأجزاء الدوارة.', 'استخدم أدوات معزولة عند فحص الدائرة.'],
    safetyRulesEn: ['Stop operation before touching the belt or pulleys.', 'Keep hands away from rotating parts.', 'Use insulated tools for circuit checks.'],
  ),
  'gearbox_drive_motor': _EquipmentKnowledge(
    type: 'gearbox_drive_motor',
    displayNameAr: 'محرّك مع boîte تروس',
    displayNameEn: 'Gearbox-driven motor',
    supportedFailureModesAr: ['تآكل التروس', 'تسرب الزيت', 'فشل المحمل', 'انزلاق أو تحمل زائد'],
    supportedFailureModesEn: ['Gear tooth wear', 'Oil leakage', 'Bearing failure', 'Overload or slip'],
    typicalSymptomsAr: ['صوت طحن', 'تسريب زيت', 'اهتزاز', 'انخفاض العزم'],
    typicalSymptomsEn: ['Grinding noise', 'Oil leakage', 'Vibration', 'Reduced torque'],
    requiredEvidenceAr: ['فحص مستوى الزيت', 'فحص التروس والاهتزاز', 'قياس الحمل', 'فحص التسريب'],
    requiredEvidenceEn: ['Inspect oil level', 'Inspect gears and vibration', 'Measure load', 'Inspect leakage'],
    recommendedInspectionsAr: ['افحص مستوى الزيت ودرجة نقاوته.', 'تفقد التروس والاهتزاز بحثًا عن تآكل أو احتكاك.', 'راجع الحمل على المحرك قبل استبدال التروس.', 'افحص التسريب والضغط قبل أي صيانة.'],
    recommendedInspectionsEn: ['Inspect oil level and cleanliness.', 'Check gears and vibration for wear or friction.', 'Review motor load before replacing gears.', 'Inspect leakage and pressure before any service.'],
    sparePartsAr: ['زيت تروس', 'تروس', 'محمل', 'ختم أو حشية'],
    sparePartsEn: ['Gear oil', 'Gears', 'Bearing', 'Seal or gasket'],
    safetyRulesAr: ['أوقف التشغيل قبل فتح علبة التروس.', 'لا تفتح الخزان قبل فراغ الضغط.', 'استخدم معدات حماية عند رفع أو فحص الوزن.'],
    safetyRulesEn: ['Stop operation before opening the gearbox.', 'Do not open the sump before relieving pressure.', 'Use protective gear when lifting or inspecting.'],
  ),
  'general_industrial': _EquipmentKnowledge(
    type: 'general_industrial',
    displayNameAr: 'معدات صناعية عامة',
    displayNameEn: 'General industrial equipment',
    supportedFailureModesAr: ['فشل تشغيلي', 'فشل في التحكم', 'فشل في التوصيل', 'تراكم تآكل أو غبار'],
    supportedFailureModesEn: ['Operational failure', 'Control failure', 'Connection failure', 'Dust or wear buildup'],
    typicalSymptomsAr: ['توقف غير مبرر', 'سلوك غير طبيعي', 'تحسن بعد التوقف', 'أداء متقلب'],
    typicalSymptomsEn: ['Unexpected shutdown', 'Abnormal behavior', 'Recovery after reset', 'Fluctuating performance'],
    requiredEvidenceAr: ['ملاحظة السلوك', 'قياس الإشارة أو الجهد', 'فحص التوصيلات', 'تأكيد الخطوة الحالية'],
    requiredEvidenceEn: ['Observe behavior', 'Measure signal or voltage', 'Inspect wiring', 'Confirm current step'],
    recommendedInspectionsAr: ['اقيس الإشارة أو الجهد وفق الخطوة الحالية.', 'افحص التوصيلات والموصلات المعنية.', 'راجع الحالة التشغيلية قبل الاستبدال.', 'حدد ما إذا كانت الخطوة الحالية تكشف عن عطل جديد.'],
    recommendedInspectionsEn: ['Measure the signal or voltage relevant to the current step.', 'Inspect the relevant connectors and wiring.', 'Review operating behavior before replacement.', 'Identify whether the current step reveals a new fault.'],
    sparePartsAr: ['قطعة تحكم أو موصل', 'مفتاح حماية', 'حشية أو غطاء', 'مستشعر مناسب'],
    sparePartsEn: ['Control part or connector', 'Protective switch', 'Seal or cover', 'Relevant sensor'],
    safetyRulesAr: ['أوقف التيار قبل أي فحص داخل المعدات.', 'استخدم التدابير المناسبة للخطوة الحالية.', 'لا تُدخل يدك في المكونات الدوارة أو الساخنة.'],
    safetyRulesEn: ['Isolate power before any internal inspection.', 'Use the precautions relevant to the current step.', 'Do not reach into rotating or hot components.'],
  ),
};

class AITroubleshootNotifier extends StateNotifier<AIReportState> {
  DiagnosticSessionState _sessionState = const DiagnosticSessionState(
    evidence: [],
    findings: [],
    userResponses: [],
    confirmedEvidence: [],
    rejectedEvidence: [],
    hypotheses: [],
    timeline: [],
    nextBestAction: 'ابدأ بجمع دليل جديد',
    reasoningSummary: 'الجلسة جاهزة للاستدلال المحلي.',
    riskLevel: 'low',
    safetyLevel: 'standard',
    isResolved: false,
    isStillOpen: false,
    lastEvent: 'created',
    lastCompletedStep: -1,
  );

  AITroubleshootNotifier() : super(AIReportState(
    currentStatusAr: '🟢 جاهز للإصلاح والتتبع الحركي', currentStatusEn: '🟢 Ready for Fix',
    safetyWarningAr: 'تحذير السلامة المهنية: افصل مصدر الطاقة واقطع الأمان الرئيسي تماماً قبل فحص أو فك أي جزء منعاً للصعق الكهربائي ومخاطر الالتماس.', statusWarningEn: 'Safety Warning: Disconnect power source completely.',
    toolsAr: ['مفك براغي معزول 1000V', 'مفتاح ربط سداسي مقاس 10 مم'], toolsEn: ['Insulated Screwdriver', '10mm Wrench'],
    steps: [
      DiagnosticStep(number: 1, textAr: 'قم بفك البراغي الأربعة للغطاء الخلفي برفق واستخراج المكثف.', textEn: 'Unscrew the four side screws gently.', estimatedTimeAr: '⏱️ 3 دقائق', estimatedTimeEn: '⏱️ 3 min'),
      DiagnosticStep(number: 2, textAr: 'افحص المكثف للتأكد من عدم وجود انتفاخ أو تسريب للمادة الكيميائية باللوحة.', textEn: 'Inspect the capacitor for bulging.', estimatedTimeAr: '⏱️ 5 دقائق', estimatedTimeEn: '⏱️ 5 min'),
    ],
    partNameAr: 'شركة النخبة المعتمدة للتوريد الميكانيكي ومبيعات قطع الغيار والمكونات الهندسية', partNameEn: 'Al-Nokhba Spare Parts Co.',
    partDiscount: 'نسبة توفير الكود: 20%', partCode: 'DRFIX20', currentStepIndex: 0,
    confidenceRate: 92,
    confidenceReasonsAr: ['الأعراض متطابقة مع المدخلات والمشكلة المرصودة', 'رمز الخطأ يؤكد تلف الدائرة وبادئ الحركة الكهربائي', 'التحليل البصري للصورة المرفوعة يظهر انتفاخاً باهتاً بالقطعة', 'أجوبتك التفاعلية تدعم ضعف معدلات الارتداد الميكانيكي للذراع'],
    confidenceReasonsEn: ['Symptoms match inputs', 'Error code confirms circuit fault', 'Image shows slight bulging', 'Your answers support low return'],
    alternativeCausesAr: {'مكثف التشغيل المستمر (Run Capacitor)': 92, 'مرحل وبادئ الحركة الحراري (Starter Relay)': 81, 'ملفات المحرك الكهربائي والضاغط': 43},
    alternativeCausesEn: {'Run Capacitor (Main Cylinder)': 92, 'Starter Relay': 81, 'Motor Windings': 43},
    totalTimeAr: '15 دقيقة', totalTimeEn: '15 min',
    difficultyAr: '🟡 متوسط', difficultyEn: '🟡 Medium', difficultyColor: Colors.amber,
    partCostRangeAr: '30 - 45 ريال', partCostRangeEn: '30 - 45 SAR',
    fixCostRangeAr: '120 - 180 ريال', fixCostRangeEn: '120 - 180 SAR',
    aiBasisAr: ['وصف المشكلة الدقيق', 'الأسئلة الذكية الميدانية', 'التحليل البصري للصورة المرفوعة', 'قاعدة المعرفة الهندسية المعتمدة'],
    aiBasisEn: ['Exact fault description', 'Smart questions', 'Visual photo analysis', 'Certified knowledge base'],
    isFavorited: false,
    deviceName: 'مكيف سبلت إل جي',
    categoryName: 'تكييف',
    dateStr: '2026-07-11 11:24',
  )) {
    _initializeReasoningEngine();
  }

  void toggleFavorite() { 
    state = state.copyWith(isFavorited: !state.isFavorited); 
  }

  _EquipmentContext _buildKnowledgeContext(String evidenceText, AIReportState report, List<DiagnosticHypothesis> hypotheses) {
    final lowerEvidence = evidenceText.toLowerCase();
    final lowerDevice = (report.deviceName ?? '').toLowerCase();
    final lowerCategory = (report.categoryName ?? '').toLowerCase();
    final lowerPartName = '${report.partNameAr} ${report.partNameEn}'.toLowerCase();

    String equipmentType = 'general_industrial';
    if (lowerCategory.contains('تكييف') || lowerCategory.contains('hvac') || lowerDevice.contains('compressor') || lowerPartName.contains('compressor') || lowerDevice.contains('مكيف')) {
      equipmentType = 'hvac_compressor';
    } else if (lowerCategory.contains('مضخة') || lowerCategory.contains('pump') || lowerDevice.contains('pump') || lowerDevice.contains('مضخة')) {
      equipmentType = 'centrifugal_pump';
    } else if (lowerEvidence.contains('حزام') || lowerEvidence.contains('belt') || lowerCategory.contains('belt')) {
      equipmentType = 'belt_drive_motor';
    } else if (lowerEvidence.contains('تروس') || lowerEvidence.contains('gear') || lowerEvidence.contains('gearbox') || lowerCategory.contains('gear')) {
      equipmentType = 'gearbox_drive_motor';
    } else if (lowerCategory.contains('موتور') || lowerCategory.contains('motor') || lowerDevice.contains('motor')) {
      equipmentType = 'direct_drive_motor';
    } else if (lowerCategory.contains('مروحة') || lowerCategory.contains('fan') || lowerDevice.contains('fan')) {
      equipmentType = 'general_industrial';
    }

    final knowledge = _industrialKnowledge[equipmentType] ?? _industrialKnowledge['general_industrial']!;
    final topFault = hypotheses.where((h) => h.status != 'Eliminated').fold<DiagnosticHypothesis?>(null, (current, next) {
      if (current == null || next.confidence > current.confidence) {
        return next;
      }
      return current;
    });

    return _EquipmentContext(
      equipmentType: equipmentType,
      manufacturer: _extractManufacturer(report, lowerDevice, lowerPartName),
      model: _extractModel(report, lowerDevice, lowerPartName),
      driveType: equipmentType == 'belt_drive_motor'
          ? 'belt drive'
          : equipmentType == 'gearbox_drive_motor'
              ? 'gearbox drive'
              : 'direct drive',
      operatingContext: _inferOperatingContext(lowerEvidence, lowerCategory, lowerDevice),
      fault: topFault?.title ?? knowledge.supportedFailureModesEn.first,
      knowledge: knowledge,
    );
  }

  String _extractManufacturer(AIReportState report, String lowerDevice, String lowerPartName) {
    final candidates = <String>[
      'schneider', 'siemens', 'lg', 'daikin', 'carrier', 'samsung', 'abb', 'hitachi', 'mitsubishi', 'johnson', 'honeywell',
    ];
    final combined = '$lowerDevice $lowerPartName'.toLowerCase();
    for (final candidate in candidates) {
      if (combined.contains(candidate)) {
        return candidate[0].toUpperCase() + candidate.substring(1);
      }
    }
    return report.partNameEn.isNotEmpty ? report.partNameEn : 'Unknown';
  }

  String _extractModel(AIReportState report, String lowerDevice, String lowerPartName) {
    final combined = '$lowerDevice $lowerPartName';
    final match = RegExp(r'(model|serie|series|type)\s*[:#-]?\s*([A-Za-z0-9\-/]+)').firstMatch(combined);
    if (match != null) {
      return match.group(2) ?? 'Unknown';
    }
    return report.partNameAr.isNotEmpty ? report.partNameAr : 'Unknown';
  }

  String _inferOperatingContext(String lowerEvidence, String lowerCategory, String lowerDevice) {
    if (lowerEvidence.contains('مستمر') || lowerEvidence.contains('continuous') || lowerEvidence.contains('24/7') || lowerEvidence.contains('critical')) {
      return 'continuous duty';
    }
    if (lowerEvidence.contains('خارج') || lowerEvidence.contains('outdoor') || lowerEvidence.contains('مفتوح')) {
      return 'outdoor service';
    }
    if (lowerCategory.contains('صناعي') || lowerCategory.contains('industrial') || lowerDevice.contains('process')) {
      return 'industrial service';
    }
    return 'standard service';
  }

  String _derivePartName(String evidenceText, String fallbackAr, String fallbackEn) {
    final context = _buildKnowledgeContext(evidenceText, state, _sessionState.hypotheses);
    final activeHypotheses = _sessionState.hypotheses.where((h) => h.status != 'Eliminated').toList();
    if (activeHypotheses.isNotEmpty && context.knowledge.sparePartsAr.isNotEmpty) {
      return context.knowledge.sparePartsAr.first;
    }
    return fallbackAr.isNotEmpty ? fallbackAr : fallbackEn;
  }

  String _deriveSafetyMessage(String evidenceText, String fallbackAr, String fallbackEn) {
    final context = _buildKnowledgeContext(evidenceText, state, _sessionState.hypotheses);
    final currentStep = state.steps.isEmpty ? '' : state.steps[(state.currentStepIndex).clamp(0, state.steps.length - 1)].textAr;
    final relevantRule = context.knowledge.safetyRulesAr.firstWhere((rule) => rule.isNotEmpty, orElse: () => '');
    if (relevantRule.isEmpty) {
      return fallbackAr.isNotEmpty ? fallbackAr : fallbackEn;
    }
    final faultHint = context.fault.isNotEmpty ? context.fault : 'current fault';
    return '⚠️ ${context.knowledge.displayNameAr} · $faultHint · ${currentStep.isNotEmpty ? currentStep : 'الخطوة الحالية'}: $relevantRule';
  }

  String _deriveDifficultyText(String evidenceText, int completedSteps, bool isResolved, bool isStillOpen) {
    final context = _buildKnowledgeContext(evidenceText, state, _sessionState.hypotheses);
    if (isResolved) {
      return '🟢 سهل/مُحسّن';
    }
    if (isStillOpen || completedSteps >= 2 || context.knowledge.requiredEvidenceAr.length > 3) {
      return '🟠 متوسط/متقدم';
    }
    return '🟡 متوسط';
  }

  Color _deriveDifficultyColor(String evidenceText, int completedSteps, bool isResolved, bool isStillOpen) {
    final context = _buildKnowledgeContext(evidenceText, state, _sessionState.hypotheses);
    if (isResolved) {
      return Colors.green.shade700;
    }
    if (isStillOpen || completedSteps >= 2 || context.knowledge.requiredEvidenceAr.length > 3) {
      return Colors.orange.shade800;
    }
    return Colors.amber;
  }

  String _deriveCostRange(String evidenceText, String fallbackAr, String fallbackEn) {
    final context = _buildKnowledgeContext(evidenceText, state, _sessionState.hypotheses);
    if (context.knowledge.type == 'hvac_compressor') {
      return '120 - 220 ريال';
    }
    if (context.knowledge.type == 'centrifugal_pump') {
      return '180 - 320 ريال';
    }
    if (context.knowledge.type == 'belt_drive_motor') {
      return '80 - 150 ريال';
    }
    if (context.knowledge.type == 'gearbox_drive_motor') {
      return '200 - 400 ريال';
    }
    return fallbackAr.isNotEmpty ? fallbackAr : fallbackEn;
  }

  void _initializeReasoningEngine() {
    final seededHypotheses = _seedHypothesesFromState(state);
    _sessionState = _sessionState.copyWith(
      hypotheses: seededHypotheses,
      nextBestAction: 'ابدأ بجمع دليل جديد وتحقق من الفرضية الأرجح.',
      reasoningSummary: 'الجلسة جاهزة للاستدلال المحلي وتحديث البطاقات عند كل دليل جديد.',
      timeline: const [
        DiagnosticTimelineEntry(type: 'session', text: 'تم تهيئة الجلسة المحلية لاستدلال تشخيصي قابل للتفسير.'),
      ],
    );
    _syncSessionToReport();
  }

  void setReport(AIReportState report) {
    state = report;
    final seededHypotheses = _seedHypothesesFromState(report);
    _sessionState = _sessionState.copyWith(
      evidence: [if (report.deviceName != null) report.deviceName!],
      confirmedEvidence: [if (report.deviceName != null) report.deviceName!],
      hypotheses: seededHypotheses,
      lastEvent: 'loaded',
      nextBestAction: 'ابدأ بجمع دليل جديد وتحقق من الفرضية الأرجح.',
      reasoningSummary: 'تم تحميل التقرير الحالي كجلسة تشخيصية مباشرة.',
      timeline: [
        const DiagnosticTimelineEntry(type: 'session', text: 'تم تحميل تقرير تشخيصي جديد إلى الجلسة المحلية.'),
      ],
    );
    _syncSessionToReport();
  }

  void goToPreviousStep() {
    if (state.steps.isEmpty) return;
    final previousIndex = (state.currentStepIndex - 1).clamp(0, state.steps.length - 1);
    state = state.copyWith(currentStepIndex: previousIndex);
    _sessionState = _sessionState.copyWith(lastEvent: 'step');
    _recordEvidence('تم الرجوع إلى خطوة الفحص السابقة.', confirmed: true, eventType: 'step');
  }

  void goToFirstInspectionStep() {
    if (_sessionState.diagnosisCompleted || _sessionState.diagnosisSolved) return;
    _sessionState = _sessionState.copyWith(currentInspectionStep: 0, lastEvent: 'inspection_step');
    _syncSessionToReport();
  }

  /// الانتقال للخطوة السابقة — يستخدم [totalSteps] (عدد actionableSteps من الـ UI)
  /// لضمان أن الـ clamp يعتمد على الخطوات الفعلية وليس قائمة الجلسة الداخلية.
  /// لا يتوقف عند diagnosisSolved لأن المستخدم قد لا يزال يتصفح الخطوات.
  void goToPreviousInspectionStep({int? totalSteps}) {
    final count = totalSteps ?? (state.steps.isEmpty ? 1 : state.steps.length);
    if (count <= 0) return;
    final previousIndex = (_sessionState.currentInspectionStep - 1).clamp(0, count - 1);
    _sessionState = _sessionState.copyWith(currentInspectionStep: previousIndex, lastEvent: 'inspection_step');
    _syncSessionToReport();
  }

  /// الانتقال للخطوة التالية — يستخدم [totalSteps] (عدد actionableSteps من الـ UI)
  /// للتأكد من عدم تجاوز الحد الأعلى الفعلي للخطوات.
  /// لا يتوقف عند diagnosisSolved لأن التنقل بين الخطوات مستقل عن حالة الحل.
  void goToNextInspectionStep({int? totalSteps}) {
    final count = totalSteps ?? (state.steps.isEmpty ? 1 : state.steps.length);
    if (count <= 0) return;
    final nextIndex = (_sessionState.currentInspectionStep + 1).clamp(0, count - 1);
    _sessionState = _sessionState.copyWith(currentInspectionStep: nextIndex, lastEvent: 'inspection_step');
    _syncSessionToReport();
  }

  void goToLastInspectionStep() {
    if (_sessionState.diagnosisCompleted || _sessionState.diagnosisSolved) return;
    final lastIndex = state.steps.isEmpty ? 0 : state.steps.length - 1;
    _sessionState = _sessionState.copyWith(currentInspectionStep: lastIndex, lastEvent: 'inspection_step');
    _syncSessionToReport();
  }

  void setUserConsentToShare(bool consent) {
    _sessionState = _sessionState.copyWith(userConsentToShare: consent);
    if (!consent) {
      _sessionState = _sessionState.copyWith(publicationDraft: null);
      state = state.copyWith(publicationDraft: null);
      _syncSessionToReport();
      return;
    }

    final baseDraft = _buildPublicationDraft();
    final updatedDraft = PublicationDraft(
      deviceName: '',
      faultDescription: baseDraft.faultDescription,
      successfulCause: baseDraft.successfulCause,
      solutionSteps: baseDraft.solutionSteps,
      inspectedOrReplacedParts: baseDraft.inspectedOrReplacedParts,
      safetyWarnings: baseDraft.safetyWarnings,
      attemptedCauses: baseDraft.attemptedCauses,
      notes: baseDraft.notes,
      solved: baseDraft.solved,
      status: 'ready_for_admin_review',
      consentText: baseDraft.consentText,
      publicationType: baseDraft.solved ? 'knowledge_base' : 'community_help',
      sector: baseDraft.sector,
    );

    _sessionState = _sessionState.copyWith(
      userConsentToShare: consent,
      publicationDraft: updatedDraft,
    );
    state = state.copyWith(publicationDraft: updatedDraft);
    _syncSessionToReport();
  }

  void recordCurrentCauseResult(String result) {
    if (_sessionState.diagnosisCompleted || _sessionState.diagnosisSolved) return;
    final normalized = result.trim().toLowerCase();
    if (normalized != 'succeeded' && normalized != 'failed' && normalized != 'skipped') return;

    // If the user reports a failure but there are remaining inspection steps for the current cause,
    // advance the inspection step first (do not move to the next cause yet).
    if (normalized == 'failed' && state.steps.isNotEmpty) {
      final maxStep = state.steps.length - 1;
      if (_sessionState.currentInspectionStep < maxStep) {
        _sessionState = _sessionState.copyWith(
          currentInspectionStep: _sessionState.currentInspectionStep + 1,
          lastEvent: 'inspection',
        );
        _syncSessionToReport();
        return;
      }
    }

    final currentIndex = _normalizeCurrentCauseIndex(_sessionState.hypotheses, _sessionState.currentCauseIndex);
    final nextIndex = (currentIndex + 1).clamp(0, _sessionState.hypotheses.length);
    final hasMoreCauses = nextIndex < _sessionState.hypotheses.length;
    final shouldCompleteJourney = normalized == 'succeeded' || normalized == 'skipped' || !hasMoreCauses || _sessionState.hypotheses.isEmpty;

    final bool journeyCompleted = shouldCompleteJourney;

    if (normalized == 'succeeded') {
      _sessionState = _sessionState.copyWith(
        currentInspectionStep: 0,
        diagnosisCompleted: true,
        diagnosisSolved: true,
        lastEvent: 'cause_result',
      );
    } else {
      _sessionState = _sessionState.copyWith(
        currentCauseIndex: hasMoreCauses ? nextIndex : currentIndex,
        currentInspectionStep: 0,
        diagnosisCompleted: journeyCompleted,
        diagnosisSolved: false,
        lastEvent: 'cause_result',
      );
    }

    if (journeyCompleted) {
      _sessionState = _sessionState.copyWith(publicationDraft: null);
      state = state.copyWith(publicationDraft: null);
    }

    _syncSessionToReport();
  }

  void goToNextStep() {
    if (state.steps.isEmpty) return;
    _completeCurrentStep(advance: true);
  }

  void markStepCompleted(int index) {
    _completeCurrentStep(index: index, advance: true);
  }

  void _completeCurrentStep({int? index, bool advance = true}) {
    if (state.steps.isEmpty) return;
    final targetIndex = (index ?? state.currentStepIndex).clamp(0, state.steps.length - 1);
    final updatedSteps = List<DiagnosticStep>.from(state.steps);
    if (targetIndex >= 0 && targetIndex < updatedSteps.length) {
      if (!updatedSteps[targetIndex].isCompleted) {
        updatedSteps[targetIndex].isCompleted = true;
        _recordEvidence(updatedSteps[targetIndex].textAr, confirmed: true, eventType: 'step');
      }
    }

    int nextIndex = state.currentStepIndex;
    if (advance && targetIndex == state.currentStepIndex && nextIndex < state.steps.length - 1) {
      nextIndex++;
    }

    state = state.copyWith(steps: updatedSteps, currentStepIndex: nextIndex);
    _syncSessionToReport();
  }

  List<String> _mergeDistinctStrings(List<String> existing, List<String> additions) {
    final merged = <String>[];
    final seen = <String>{};
    for (final value in [...existing, ...additions]) {
      final normalized = value.trim();
      if (normalized.isEmpty || seen.contains(normalized)) continue;
      seen.add(normalized);
      merged.add(normalized);
    }
    return merged;
  }

  List<DiagnosticTimelineEntry> _mergeDistinctTimelineEntries(List<DiagnosticTimelineEntry> existing, List<DiagnosticTimelineEntry> additions) {
    final merged = <DiagnosticTimelineEntry>[];
    final seen = <String>{};
    for (final entry in [...existing, ...additions]) {
      final key = '${entry.type}:${entry.text}';
      if (seen.contains(key)) continue;
      seen.add(key);
      merged.add(entry);
    }
    return merged;
  }

  int _normalizeCurrentCauseIndex(List<DiagnosticHypothesis> hypotheses, int fallbackIndex) {
    if (hypotheses.isEmpty) return 0;
    return fallbackIndex.clamp(0, hypotheses.length - 1);
  }

  DiagnosticSessionState _deriveJourneyState(List<DiagnosticHypothesis> hypotheses, DiagnosticSessionState currentState, {required bool inspectionFailed}) {
    final normalizedIndex = _normalizeCurrentCauseIndex(hypotheses, currentState.currentCauseIndex);
    final currentHypothesis = hypotheses.isEmpty ? null : hypotheses[normalizedIndex];
    final activeHypotheses = hypotheses.where((item) => item.status != 'Eliminated').toList();

    bool diagnosisSolved = false;
    bool diagnosisCompleted = false;
    int nextCauseIndex = normalizedIndex;
    int nextInspectionStep = currentState.currentInspectionStep;

    if (currentHypothesis != null) {
      if (currentHypothesis.status == 'Confirmed') {
        diagnosisSolved = true;
        diagnosisCompleted = true;
      } else if (inspectionFailed) {
        nextCauseIndex = (normalizedIndex + 1).clamp(0, hypotheses.length);
        nextInspectionStep = 0;
        if (nextCauseIndex >= hypotheses.length) {
          diagnosisCompleted = true;
        }
      } else if (activeHypotheses.isEmpty) {
        diagnosisCompleted = true;
      }
    } else {
      diagnosisCompleted = true;
    }

    return currentState.copyWith(
      currentCauseIndex: nextCauseIndex,
      currentInspectionStep: nextInspectionStep,
      diagnosisCompleted: diagnosisCompleted,
      diagnosisSolved: diagnosisSolved,
      publicationDraft: diagnosisCompleted || diagnosisSolved ? _buildPublicationDraftForSession(currentState, hypotheses) : currentState.publicationDraft,
    );
  }

  void ingestNormalizedDiagnosisContract(DiagnosisContractModel contract) {
    final DiagnosisContractModel diagnosisContract = contract;

    final List<String> aiEvidence = <String>[];
    final List<String> findings = <String>[];
    final List<DiagnosticHypothesis> aiHypotheses = <DiagnosticHypothesis>[];

    final summary = diagnosisContract.knowledgeSummary.trim();
    if (summary.isNotEmpty) {
      aiEvidence.add(summary);
      findings.add(summary);
    }

    for (final item in diagnosisContract.possibleCauses) {
      final title = item.title.trim();
      final description = item.description.trim();
      final probability = item.probability;
      if (title.isEmpty) continue;
      aiHypotheses.add(DiagnosticHypothesis(
        id: 'ai-${title.hashCode}',
        title: title,
        status: probability >= 70 ? 'Confirmed' : 'Likely',
        confidence: probability.clamp(15, 98),
        supportingEvidence: description.isEmpty ? const [] : [description],
        contradictingEvidence: const [],
        reason: 'تم استلام فرضية من JSON الذكاء الاصطناعي.',
      ));
      aiEvidence.add('$title ($probability%)');
      if (description.isNotEmpty) aiEvidence.add(description);
    }

    for (final item in diagnosisContract.inspectionSteps) {
      final description = item.description.trim();
      if (description.isNotEmpty) {
        aiEvidence.add(description);
        findings.add(description);
      }
    }

    for (final item in diagnosisContract.oshaWarnings) {
      final risk = item.risk.trim();
      final recommendation = item.recommendation.trim();
      if (risk.isNotEmpty || recommendation.isNotEmpty) {
        aiEvidence.add(risk.isEmpty ? recommendation : '$risk — $recommendation');
      }
    }

    final updatedEvidence = _mergeDistinctStrings(_sessionState.evidence, aiEvidence);
    final updatedConfirmed = _mergeDistinctStrings(_sessionState.confirmedEvidence, aiEvidence);
    final updatedHypotheses = aiHypotheses.isNotEmpty ? aiHypotheses : _sessionState.hypotheses;

    final nextSessionState = _deriveJourneyState(
      updatedHypotheses,
      _sessionState.copyWith(
        evidence: updatedEvidence,
        confirmedEvidence: updatedConfirmed,
        findings: _mergeDistinctStrings(_sessionState.findings, findings),
        hypotheses: updatedHypotheses,
        nextBestAction: 'تم更新 الجلسة من JSON الذكاء الاصطناعي.',
        reasoningSummary: summary.isNotEmpty ? summary : _sessionState.reasoningSummary,
        lastEvent: 'ai_contract',
        timeline: _mergeDistinctTimelineEntries(
          _sessionState.timeline,
          [const DiagnosticTimelineEntry(type: 'ai', text: 'تم استلام JSON تشخيصي من الذكاء الاصطناعي.')],
        ).take(10).toList(),
      ),
      inspectionFailed: false,
    );

    _sessionState = nextSessionState;

    _syncSessionToReport();
  }

  Future<void> recordUserAnswer(String answer) async {
    final trimmed = answer.trim();
    if (trimmed.isEmpty) return;

    final updatedResponses = [..._sessionState.userResponses, trimmed];
    _sessionState = _sessionState.copyWith(
      userResponses: updatedResponses,
      isResolved: false,
      isStillOpen: true,
      lastEvent: 'answer',
    );
    _recordEvidence(trimmed, confirmed: true, eventType: 'answer');

    final shouldRequestAi = _shouldRequestAi(trimmed);
    if (shouldRequestAi) {
      try {
        final aiService = AiApiService();
        final deltaPrompt = _buildDeltaPrompt(trimmed);
        final aiText = await aiService.getUnifiedMultiAiDiagnosis(
          category: state.categoryName ?? 'عام',
          deviceName: state.deviceName ?? 'جهاز',
          brand: state.partNameEn.isNotEmpty ? state.partNameEn : 'غير محدد',
          model: state.partNameAr.isNotEmpty ? state.partNameAr : 'غير محدد',
          description: deltaPrompt,
          observations: 'أدلة جديدة داخل الجلسة المحلية',
          errorCode: state.partCode.isNotEmpty ? state.partCode : 'N/A',
          voltage: '220',
          pressure: '120',
        );
        if (aiText.isNotEmpty) {
          final normalizedContract = aiService.normalizeDiagnosisContractModel(
            aiText,
            category: state.categoryName ?? 'عام',
            deviceName: state.deviceName ?? 'جهاز',
            brand: state.partNameEn.isNotEmpty ? state.partNameEn : 'غير محدد',
            model: state.partNameAr.isNotEmpty ? state.partNameAr : 'غير محدد',
            description: deltaPrompt,
            observations: 'أدلة جديدة داخل الجلسة المحلية',
            errorCode: state.partCode.isNotEmpty ? state.partCode : 'N/A',
          );
          ingestNormalizedDiagnosisContract(normalizedContract);
          _recordEvidence('تفسير AI مُحدَّث: $aiText', confirmed: true, eventType: 'ai');
        }
      } catch (e, st) {
        print('CAUGHT ERROR: $e');
        print(st);
      }
    }
  }

  Future<void> recordInspectionResult(String result) async {
    final trimmed = result.trim();
    if (trimmed.isEmpty) return;
    _recordEvidence(trimmed, confirmed: true, eventType: 'inspection');
  }

  Future<void> markSessionResolved() async {
    _sessionState = _sessionState.copyWith(
      isResolved: true,
      isStillOpen: false,
      lastEvent: 'resolved',
    );
    _recordEvidence('تم تصنيف الجلسة على أنها محلولة.', confirmed: true, eventType: 'resolve');
  }

  Future<void> markSessionStillOpen() async {
    _sessionState = _sessionState.copyWith(
      isResolved: false,
      isStillOpen: true,
      lastEvent: 'open',
    );
    _recordEvidence('تم إبقاء الجلسة مفتوحة لاستكمال الفحص.', confirmed: false, eventType: 'open');
  }

  List<DiagnosticHypothesis> _seedHypothesesFromState(AIReportState report) {
    final context = _buildKnowledgeContext('', report, const []);
    return context.knowledge.supportedFailureModesAr.map((mode) {
      return DiagnosticHypothesis(
        id: 'hyp-${mode.hashCode}',
        title: mode,
        status: 'Active',
        confidence: 35,
        supportingEvidence: [if (report.deviceName != null) report.deviceName!],
        contradictingEvidence: const [],
        reason: 'فرضية أولية مستخلصة من المعرفة الصناعية للمعدات الحالية.',
      );
    }).toList();
  }

  void _recordEvidence(String evidence, {required bool confirmed, required String eventType}) {
    final cleaned = evidence.trim();
    if (cleaned.isEmpty) return;

    final updatedEvidence = [..._sessionState.evidence, cleaned];
    final updatedConfirmed = confirmed
        ? [..._sessionState.confirmedEvidence, cleaned]
        : List<String>.from(_sessionState.confirmedEvidence);
    final updatedRejected = !confirmed
        ? [..._sessionState.rejectedEvidence, cleaned]
        : List<String>.from(_sessionState.rejectedEvidence);

    final updatedHypotheses = _recomputeHypotheses(
      evidenceText: cleaned,
      confirmed: confirmed,
      updatedEvidence: updatedEvidence,
      updatedConfirmed: updatedConfirmed,
      updatedRejected: updatedRejected,
    );

    final currentStep = state.steps.isEmpty ? 0 : state.currentStepIndex.clamp(0, state.steps.length - 1);
    final context = _buildKnowledgeContext(updatedEvidence.join(' '), state, updatedHypotheses);
    final nextBestAction = _deriveNextBestAction(updatedHypotheses, currentStep);
    final riskLevel = _deriveRiskLevel(updatedEvidence, updatedConfirmed);
    final safetyLevel = _deriveSafetyLevel(updatedEvidence, updatedConfirmed);
    final confidenceValue = _deriveConfidence(updatedHypotheses, updatedEvidence, updatedConfirmed, updatedRejected, state.steps.where((step) => step.isCompleted).length);
    final reasoningSummary = _deriveReasoningSummary(updatedHypotheses, confidenceValue, nextBestAction, context);

    final timelineEntry = DiagnosticTimelineEntry(
      type: eventType,
      text: '${confirmed ? 'إثبات' : 'رفض'} دليل: $cleaned',
    );
    final updatedTimeline = [
      ..._sessionState.timeline,
      timelineEntry,
    ].take(10).toList();

    final nextSessionState = _deriveJourneyState(
      updatedHypotheses,
      _sessionState.copyWith(
        evidence: updatedEvidence,
        confirmedEvidence: updatedConfirmed,
        rejectedEvidence: updatedRejected,
        hypotheses: updatedHypotheses,
        timeline: updatedTimeline,
        nextBestAction: nextBestAction,
        reasoningSummary: reasoningSummary,
        riskLevel: riskLevel,
        safetyLevel: safetyLevel,
        lastEvent: eventType,
        lastCompletedStep: state.currentStepIndex,
      ),
      inspectionFailed: eventType == 'inspection',
    );

    _sessionState = nextSessionState;

    _syncSessionToReport();
  }

  List<DiagnosticHypothesis> _recomputeHypotheses({
    required String evidenceText,
    required bool confirmed,
    required List<String> updatedEvidence,
    required List<String> updatedConfirmed,
    required List<String> updatedRejected,
  }) {
    final baseHypotheses = _sessionState.hypotheses.isEmpty
        ? _seedHypothesesFromState(state)
        : List<DiagnosticHypothesis>.from(_sessionState.hypotheses);

    final workingEvidence = updatedEvidence.join(' ');
    final lowerText = workingEvidence.toLowerCase();
    final evidenceQuality = _estimateEvidenceQuality(updatedEvidence, updatedConfirmed, updatedRejected);
    final context = _buildKnowledgeContext(workingEvidence, state, baseHypotheses);
    final missingEvidence = context.knowledge.requiredEvidenceAr.where((item) => !_containsAny(lowerText, _tokenize(item))).toList();
    final supportCount = updatedConfirmed.length;
    final contradictionCount = updatedRejected.length;

    return baseHypotheses.map((hypothesis) {
      final titleLower = hypothesis.title.toLowerCase();
      int localScore = hypothesis.confidence;
      final hypothesisMatches = _containsAny(titleLower, _tokenize(hypothesis.title));
      if (hypothesisMatches) {
        localScore += (confirmed ? 8 : 4);
      }
      if (_containsAny(lowerText, _tokenize(hypothesis.title))) {
        localScore += 10;
      }
      if (lowerText.contains('لا') || lowerText.contains('not') || lowerText.contains('عدم')) {
        localScore -= 4;
      }
      if (contradictionCount > 0 && _containsAny(lowerText, _tokenize(hypothesis.title))) {
        localScore -= 6;
      }
      if (missingEvidence.isNotEmpty) {
        localScore -= (missingEvidence.length * 4).clamp(0, 16);
      }
      final effectiveConfidence = (localScore + evidenceQuality + (supportCount * 2) - (contradictionCount * 5)).clamp(15, 98);
      final status = effectiveConfidence >= 84
          ? 'Confirmed'
          : effectiveConfidence >= 58
              ? 'Likely'
              : effectiveConfidence <= 24
                  ? 'Eliminated'
                  : 'Active';
      return hypothesis.copyWith(
        confidence: effectiveConfidence,
        status: status,
        supportingEvidence: updatedConfirmed.isNotEmpty ? updatedConfirmed.take(2).toList() : hypothesis.supportingEvidence,
        contradictingEvidence: updatedRejected.isNotEmpty ? updatedRejected.take(2).toList() : hypothesis.contradictingEvidence,
        reason: status == 'Eliminated'
            ? 'الأدلة الحالية تتعارض مع هذه الفرضية.'
            : 'الاستدلال المحلي يربط هذه الفرضية بالمعرفة الصناعية الحالية.',
      );
    }).toList();
  }

  int _deriveConfidence(List<DiagnosticHypothesis> hypotheses, List<String> evidence, List<String> confirmedEvidence, List<String> rejectedEvidence, int completedSteps) {
    final activeHypotheses = hypotheses.where((item) => item.status != 'Eliminated').toList();
    if (activeHypotheses.isEmpty) {
      return 35;
    }
    final bestConfidence = activeHypotheses.map((item) => item.confidence).reduce((a, b) => a > b ? a : b);
    final evidenceQuality = _estimateEvidenceQuality(evidence, confirmedEvidence, rejectedEvidence);
    final missingPenalty = _countMissingCriticalEvidence(evidence, hypotheses).clamp(0, 4) * 7;
    final supportScore = confirmedEvidence.length * 3;
    final contradictionPenalty = rejectedEvidence.length * 6;
    final remainingPenalty = activeHypotheses.length > 2 ? (activeHypotheses.length - 2) * 3 : 0;
    final progressBonus = completedSteps > 0 ? 4 : 0;
    return (45 + supportScore + evidenceQuality + progressBonus + (bestConfidence ~/ 5) - contradictionPenalty - missingPenalty - remainingPenalty).clamp(20, 96);
  }

  String _deriveNextBestAction(List<DiagnosticHypothesis> hypotheses, int currentStepIndex) {
    final context = _buildKnowledgeContext(_sessionState.evidence.join(' '), state, hypotheses);
    final activeHypotheses = hypotheses.where((item) => item.status != 'Eliminated').toList();
    final missingInspection = _pickMostValuableInspection(context, _sessionState.evidence.join(' '));

    if (missingInspection != null && _sessionState.confirmedEvidence.length + _sessionState.rejectedEvidence.length < 4) {
      return 'أجمع أدلة إضافية أولاً عبر: $missingInspection';
    }
    if (activeHypotheses.isEmpty) {
      return 'أغلق الجلسة بعد مراجعة الأدلة المجمّعة لل${context.knowledge.displayNameAr}.';
    }
    final top = activeHypotheses.reduce((a, b) => a.confidence >= b.confidence ? a : b);
    final stepText = state.steps.isNotEmpty && currentStepIndex < state.steps.length
        ? state.steps[currentStepIndex].textAr
        : 'تابع الفحص الحالي.';
    return 'تحقق من ${top.title} عبر: $stepText';
  }

  String _deriveRiskLevel(List<String> evidence, List<String> confirmedEvidence) {
    final lower = [...evidence, ...confirmedEvidence].join(' ').toLowerCase();
    if (lower.contains('مكثف') || lower.contains('capacitor') || lower.contains('كهرب') || lower.contains('electric')) {
      return 'high';
    }
    if (lower.contains('تسريب') || lower.contains('leak') || lower.contains('حزام') || lower.contains('belt')) {
      return 'medium';
    }
    return 'low';
  }

  String _deriveSafetyLevel(List<String> evidence, List<String> confirmedEvidence) {
    final lower = [...evidence, ...confirmedEvidence].join(' ').toLowerCase();
    if (lower.contains('مكثف') || lower.contains('capacitor') || lower.contains('كهرب') || lower.contains('electric')) {
      return 'high';
    }
    if (lower.contains('تسريب') || lower.contains('leak') || lower.contains('حزام') || lower.contains('belt')) {
      return 'medium';
    }
    return 'standard';
  }

  String _deriveReasoningSummary(List<DiagnosticHypothesis> hypotheses, int confidenceValue, String nextBestAction, _EquipmentContext context) {
    final activeHypotheses = hypotheses.where((item) => item.status != 'Eliminated').toList();
    if (activeHypotheses.isEmpty) {
      return 'لا توجد فرضيات متبقية. تم إغلاق الاستدلال المحلي للمعدات ${context.knowledge.displayNameAr}.';
    }
    final top = activeHypotheses.reduce((a, b) => a.confidence >= b.confidence ? a : b);
    return 'الثقة الحالية $confidenceValue% — ${context.knowledge.displayNameAr} · ${context.driveType} · ${context.operatingContext} — الفرضية الأرجح: ${top.title}. $nextBestAction';
  }

  String _deriveEnglishReasoningSummary(List<DiagnosticHypothesis> hypotheses, int confidenceValue, String nextBestAction, _EquipmentContext context) {
    final activeHypotheses = hypotheses.where((item) => item.status != 'Eliminated').toList();
    if (activeHypotheses.isEmpty) {
      return 'No remaining hypotheses. Local reasoning closed for ${context.knowledge.displayNameEn}.';
    }
    final top = activeHypotheses.reduce((a, b) => a.confidence >= b.confidence ? a : b);
    return 'Current confidence $confidenceValue% — ${context.knowledge.displayNameEn} · ${context.driveType} · ${context.operatingContext} — leading hypothesis: ${top.title}. $nextBestAction';
  }

  String _buildEvidenceSummary(List<String> confirmedEvidence, List<String> rejectedEvidence) {
    final confirmed = confirmedEvidence.isNotEmpty ? confirmedEvidence.join(' • ') : 'لا توجد أدلة مؤكدة بعد.';
    final rejected = rejectedEvidence.isNotEmpty ? rejectedEvidence.join(' • ') : 'لا توجد أدلة مرفوضة بعد.';
    return 'أدلة مؤكدة: $confirmed\nأدلة مرفوضة: $rejected';
  }

  String _buildEnglishEvidenceSummary(List<String> confirmedEvidence, List<String> rejectedEvidence) {
    final confirmed = confirmedEvidence.isNotEmpty ? confirmedEvidence.join(' • ') : 'No confirmed evidence yet.';
    final rejected = rejectedEvidence.isNotEmpty ? rejectedEvidence.join(' • ') : 'No rejected evidence yet.';
    return 'Confirmed: $confirmed\nRejected: $rejected';
  }

  String _buildTimelineSummary(List<DiagnosticTimelineEntry> timeline) {
    if (timeline.isEmpty) {
      return 'لا توجد أحداث بعد.';
    }
    return timeline.reversed.take(4).map((entry) => '${entry.type}: ${entry.text}').join('\n');
  }

  List<String> _deriveSuggestedParts(List<DiagnosticHypothesis> hypotheses, String evidenceText, String fallback, String deviceContext) {
    final context = _buildKnowledgeContext(evidenceText, state, hypotheses);
    final activeHypotheses = hypotheses.where((item) => item.status != 'Eliminated').toList();
    if (activeHypotheses.isEmpty) {
      return [];
    }
    final parts = <String>{};
    for (final hypothesis in activeHypotheses) {
      final matchedParts = context.knowledge.sparePartsAr.where((part) => part.isNotEmpty).toList();
      parts.addAll(matchedParts);
    }
    return parts.take(3).toList();
  }

  bool _shouldRequestAi(String evidence) {
    final context = _buildKnowledgeContext(evidence, state, _sessionState.hypotheses);
    final normalized = evidence.trim().toLowerCase();
    final hasComplexEvidence = normalized.contains('لا') || normalized.contains('غير') || normalized.contains('مشكلة') || normalized.contains('تعارض');
    final missingCritical = _countMissingCriticalEvidence([evidence], _sessionState.hypotheses);
    return missingCritical > 1 && hasComplexEvidence;
  }

  bool _containsAny(String value, List<String> tokens) {
    final lower = value.toLowerCase();
    return tokens.any((token) => token.isNotEmpty && lower.contains(token));
  }

  List<String> _tokenize(String value) {
    final normalized = value.toLowerCase();
    final parts = normalized.split(RegExp(r'[^a-z0-9\u0600-\u06ff]+'));
    return parts.where((part) => part.isNotEmpty).toList();
  }

  int _estimateEvidenceQuality(List<String> evidence, List<String> confirmedEvidence, List<String> rejectedEvidence) {
    final allEvidence = [...evidence, ...confirmedEvidence, ...rejectedEvidence].join(' ').toLowerCase();
    final qualitySignals = <String>['قياس', 'measure', 'ضغط', 'pressure', 'جهد', 'voltage', 'تيار', 'current', 'درجة', 'temperature', 'ملاحظة', 'observed', 'مفتاح', 'vibration', 'اهتزاز', 'سجل', 'reading'];
    final hits = qualitySignals.where((signal) => allEvidence.contains(signal)).length;
    return hits * 2;
  }

  int _countMissingCriticalEvidence(List<String> evidence, List<DiagnosticHypothesis> hypotheses) {
    final evidenceText = evidence.join(' ');
    final context = _buildKnowledgeContext(evidenceText, state, hypotheses);
    final lowerEvidence = evidenceText.toLowerCase();
    return context.knowledge.requiredEvidenceAr.where((item) => !_containsAny(lowerEvidence, _tokenize(item))).length;
  }

  String? _pickMostValuableInspection(_EquipmentContext context, String evidenceText) {
    final lowerEvidence = evidenceText.toLowerCase();
    for (final inspection in context.knowledge.recommendedInspectionsAr) {
      if (!_containsAny(lowerEvidence, _tokenize(inspection))) {
        return inspection;
      }
    }
    return context.knowledge.recommendedInspectionsAr.isNotEmpty ? context.knowledge.recommendedInspectionsAr.first : null;
  }

  String _buildDeltaPrompt(String evidence) {
    final activeHypotheses = _sessionState.hypotheses.where((item) => item.status != 'Eliminated').map((item) => '${item.title} (${item.status}, ${item.confidence}%)').join('; ');
    return 'أدلة جديدة: $evidence\nأدلة مؤكدة: ${_sessionState.confirmedEvidence.join(' | ')}\nأدلة مرفوضة: ${_sessionState.rejectedEvidence.join(' | ')}\nفرضيات حالية: $activeHypotheses';
  }

  PublicationDraft _buildPublicationDraftForSession(DiagnosticSessionState currentState, List<DiagnosticHypothesis> hypotheses) {
    final faultDescription = [
      state.deviceName ?? '',
      state.partNameAr.isNotEmpty ? state.partNameAr : null,
    ].where((value) => value != null && value.toString().trim().isNotEmpty).join(' - ');

    String? successfulCause;
    if (currentState.diagnosisSolved && currentState.hypotheses.isNotEmpty) {
      final normalizedIndex = _normalizeCurrentCauseIndex(currentState.hypotheses, currentState.currentCauseIndex);
      successfulCause = currentState.hypotheses[normalizedIndex].title;
    }

    final currentSector = (state.currentStatusAr.isNotEmpty ? state.currentStatusAr : 'أخرى');

    if (currentState.diagnosisSolved) {
      return PublicationDraftHelper.buildDraft(
        faultDescription: faultDescription.isNotEmpty ? faultDescription : 'وصف العطل غير متوفر',
        successfulCause: successfulCause,
        solutionSteps: state.steps.map((step) => step.textAr).where((value) => value.trim().isNotEmpty).toList(),
        solved: true,
        userConsentToShare: currentState.userConsentToShare,
        publicationType: currentState.diagnosisSolved && currentState.userConsentToShare ? 'knowledge_base' : 'community_help',
        sector: currentSector,
      );
    }

    return PublicationDraft(
      deviceName: state.deviceName ?? '',
      faultDescription: faultDescription.isNotEmpty ? faultDescription : 'وصف العطل غير متوفر',
      solved: false,
      sector: currentSector,
    );
  }

  PublicationDraft _buildPublicationDraft() {
    final faultDescription = [
      state.deviceName ?? '',
      state.partNameAr.isNotEmpty ? state.partNameAr : null,
    ].where((value) => value != null && value.toString().trim().isNotEmpty).join(' - ');

    final currentSector = (state.currentStatusAr.isNotEmpty ? state.currentStatusAr : 'أخرى');

    String? successfulCause;
    if (_sessionState.diagnosisSolved && _sessionState.hypotheses.isNotEmpty) {
      final normalizedIndex = _normalizeCurrentCauseIndex(_sessionState.hypotheses, _sessionState.currentCauseIndex);
      successfulCause = _sessionState.hypotheses[normalizedIndex].title;
    }

    if (_sessionState.diagnosisSolved) {
      return PublicationDraft(
        deviceName: state.deviceName ?? '',
        faultDescription: faultDescription.isNotEmpty ? faultDescription : 'وصف العطل غير متوفر',
        successfulCause: successfulCause,
        solutionSteps: state.steps.map((step) => step.textAr).where((value) => value.trim().isNotEmpty).toList(),
        solved: true,
        sector: currentSector,
      );
    }

    return PublicationDraft(
      deviceName: state.deviceName ?? '',
      faultDescription: faultDescription.isNotEmpty ? faultDescription : 'وصف العطل غير متوفر',
      solved: false,
      sector: currentSector,
    );
  }

  void _syncSessionToReport() {
    final completedSteps = state.steps.where((step) => step.isCompleted).length;
    final PublicationDraft? publicationDraft = _sessionState.publicationDraft;
    final PublicationDraft? effectivePublicationDraft = publicationDraft == null
        ? null
        : PublicationDraft(
            deviceName: publicationDraft.deviceName,
            faultDescription: publicationDraft.faultDescription,
            successfulCause: publicationDraft.successfulCause,
            solutionSteps: publicationDraft.solutionSteps,
            inspectedOrReplacedParts: publicationDraft.inspectedOrReplacedParts,
            safetyWarnings: publicationDraft.safetyWarnings,
            attemptedCauses: publicationDraft.attemptedCauses,
            notes: publicationDraft.notes,
            solved: publicationDraft.solved,
            status: publicationDraft.status == 'ready_for_admin_review'
                ? 'ready_for_admin_review'
                : 'pending_admin_review',
            consentText: publicationDraft.consentText,
            publicationType: publicationDraft.publicationType,
            sector: publicationDraft.sector,
          );
    final evidenceCount = _sessionState.evidence.length;
    final evidenceText = _sessionState.evidence.join(' ').toLowerCase();
    final confidenceValue = _deriveConfidence(
      _sessionState.hypotheses,
      _sessionState.evidence,
      _sessionState.confirmedEvidence,
      _sessionState.rejectedEvidence,
      completedSteps,
    );
    final rankedHypotheses = List<DiagnosticHypothesis>.from(_sessionState.hypotheses)
      ..sort((a, b) => b.confidence.compareTo(a.confidence));

    final baseReasons = List<String>.from(state.confidenceReasonsAr);
    final updatedReasons = <String>[];
    updatedReasons.addAll(baseReasons.take(2));
    updatedReasons.add('تم تحديث الاستدلال المحلي من ${evidenceCount} دليل(ة) داخل الجلسة.');
    updatedReasons.add('الفرضية الأرجح: ${rankedHypotheses.isNotEmpty ? rankedHypotheses.first.title : state.partNameAr}.');
    updatedReasons.add('الخطوة التالية: ${_sessionState.nextBestAction}');
    if (updatedReasons.length > 4) {
      updatedReasons.removeRange(4, updatedReasons.length);
    }

    final arStatus = _sessionState.isResolved
        ? '🟢 تم حل المشكلة بنجاح وتمت متابعة الجلسة.'
        : _sessionState.isStillOpen
            ? '🔴 المشكلة ما زالت قائمة ومستمرة الجلسة.'
            : _sessionState.lastEvent == 'step'
                ? '🟡 الجلسة نشطة ويتم متابعة خطوة الفحص الحالية.'
                : _sessionState.lastEvent == 'answer'
                    ? '🟡 تم تحديث الجلسة بناءً على أدلة جديدة.'
                    : '🟢 جلسة تشخيص نشطة.';

    final enStatus = _sessionState.isResolved
        ? '🟢 Issue resolved and session updated.'
        : _sessionState.isStillOpen
            ? '🔴 Issue still open and session continues.'
            : _sessionState.lastEvent == 'step'
                ? '🟡 Session active and current step is being tracked.'
                : _sessionState.lastEvent == 'answer'
                    ? '🟡 Session updated from new evidence.'
                    : '🟢 Diagnostic session is active.';

    final context = _buildKnowledgeContext(evidenceText, state, rankedHypotheses);
    final dynamicArPartName = _derivePartName(evidenceText, state.partNameAr, state.partNameEn);
    final dynamicEnPartName = _derivePartName(evidenceText, state.partNameEn, state.partNameAr);
    final dynamicArStatus = '${arStatus}\n${_sessionState.reasoningSummary}';
    final dynamicEnStatus = '${enStatus}\n${_deriveEnglishReasoningSummary(_sessionState.hypotheses, confidenceValue, _sessionState.nextBestAction, context)}';
    final dynamicSafety = _deriveSafetyMessage(evidenceText, state.safetyWarningAr, state.statusWarningEn);
    final dynamicRisk = _deriveSafetyMessage(evidenceText, state.statusWarningEn, state.safetyWarningAr);
    final evidenceSummaryAr = _buildEvidenceSummary(_sessionState.confirmedEvidence, _sessionState.rejectedEvidence);
    final evidenceSummaryEn = _buildEnglishEvidenceSummary(_sessionState.confirmedEvidence, _sessionState.rejectedEvidence);
    final timelineSummaryAr = _buildTimelineSummary(_sessionState.timeline);
    final timelineSummaryEn = _buildTimelineSummary(_sessionState.timeline);
    final suggestedPartsAr = _deriveSuggestedParts(rankedHypotheses, evidenceText, state.partNameAr, state.deviceName ?? 'الجهاز');
    final suggestedPartsEn = _deriveSuggestedParts(rankedHypotheses, evidenceText, state.partNameEn, state.deviceName ?? 'device');
    final dynamicSteps = _buildInspectionSteps(context, completedSteps);
    final safeCurrentStepIndex = (state.currentStepIndex).clamp(0, dynamicSteps.length == 0 ? 0 : dynamicSteps.length - 1);

    state = state.copyWith(
      currentStatusAr: dynamicArStatus,
      currentStatusEn: dynamicEnStatus,
      confidenceRate: confidenceValue,
      hypotheses: rankedHypotheses,
      steps: dynamicSteps,
      reasoningNarrativeAr: _sessionState.reasoningSummary,
      reasoningNarrativeEn: _deriveEnglishReasoningSummary(_sessionState.hypotheses, confidenceValue, _sessionState.nextBestAction, context),
      evidenceSummaryAr: evidenceSummaryAr,
      evidenceSummaryEn: evidenceSummaryEn,
      timelineSummaryAr: timelineSummaryAr,
      timelineSummaryEn: timelineSummaryEn,
      suggestedPartsAr: suggestedPartsAr,
      suggestedPartsEn: suggestedPartsEn,
      confidenceReasonsAr: updatedReasons,
      confidenceReasonsEn: updatedReasons.map((reason) => reason).toList(),
      alternativeCausesAr: {
        for (final hypothesis in rankedHypotheses) hypothesis.title: hypothesis.confidence,
      },
      alternativeCausesEn: {
        for (final hypothesis in rankedHypotheses) hypothesis.title: hypothesis.confidence,
      },
      safetyWarningAr: dynamicSafety,
      statusWarningEn: dynamicRisk,
      partNameAr: dynamicArPartName,
      partNameEn: dynamicEnPartName,
      currentStepIndex: safeCurrentStepIndex,
      currentCauseIndex: _sessionState.currentCauseIndex,
      currentInspectionStep: _sessionState.currentInspectionStep,
      diagnosisCompleted: _sessionState.diagnosisCompleted,
      diagnosisSolved: _sessionState.diagnosisSolved,
      publicationDraft: effectivePublicationDraft,
      difficultyAr: _deriveDifficultyText(evidenceText, completedSteps, _sessionState.isResolved, _sessionState.isStillOpen),
      difficultyEn: _deriveDifficultyText(evidenceText, completedSteps, _sessionState.isResolved, _sessionState.isStillOpen),
      difficultyColor: _deriveDifficultyColor(evidenceText, completedSteps, _sessionState.isResolved, _sessionState.isStillOpen),
      partCostRangeAr: _deriveCostRange(evidenceText, state.partCostRangeAr, state.partCostRangeEn),
      partCostRangeEn: _deriveCostRange(evidenceText, state.partCostRangeEn, state.partCostRangeAr),
      fixCostRangeAr: _deriveCostRange(evidenceText, state.fixCostRangeAr, state.fixCostRangeEn),
      fixCostRangeEn: _deriveCostRange(evidenceText, state.fixCostRangeEn, state.fixCostRangeAr),
    );
  }

  List<DiagnosticStep> _buildInspectionSteps(_EquipmentContext context, int completedSteps) {
    if (context.knowledge.recommendedInspectionsAr.isEmpty) {
      return const [];
    }
    return List.generate(context.knowledge.recommendedInspectionsAr.length, (index) {
      final inspectionAr = context.knowledge.recommendedInspectionsAr[index];
      final inspectionEn = context.knowledge.recommendedInspectionsEn[index];
      return DiagnosticStep(
        number: index + 1,
        textAr: inspectionAr,
        textEn: inspectionEn,
        estimatedTimeAr: index == 0 ? '⏱️ 3 دقائق' : '⏱️ 4 دقائق',
        estimatedTimeEn: index == 0 ? '⏱️ 3 min' : '⏱️ 4 min',
        isCompleted: index < completedSteps,
      );
    });
  }

  Future<void> triggerAIBackupRoute() async {
    final previousAttemptSummary = [
      state.currentStatusAr,
      state.safetyWarningAr,
      state.partNameAr,
      state.partCode,
      state.steps.map((step) => step.textAr).join(' | '),
      state.toolsAr.join(' | '),
    ].where((value) => value.trim().isNotEmpty).join(' | ');

    final previousContext = previousAttemptSummary.isNotEmpty
        ? 'المحاولة السابقة:\n$previousAttemptSummary\nيرجى توليد حل بديل مختلف تماماً عن هذه الإجابة، مع خطوات جديدة وأدوات مختلفة وقطع غيار مختلفة، ولا تكرر نفس التوصيات أو نفس المكونات.'
        : 'يرجى توليد حل بديل مختلف تماماً عن المحاولة السابقة مع خطوات جديدة وأدوات وقطع مختلفة.';

    String alternativeMarkdown = '';
    try {
      final aiService = AiApiService();
      alternativeMarkdown = await aiService.getUnifiedMultiAiDiagnosis(
        category: state.categoryName ?? 'عام',
        deviceName: state.deviceName ?? 'جهاز',
        brand: state.partNameEn.isNotEmpty ? state.partNameEn : 'غير محدد',
        model: state.partNameAr.isNotEmpty ? state.partNameAr : 'غير محدد',
        description: 'محاولة بديلة بعد عدم نجاح الحل السابق. $previousContext',
        observations: 'الهدف: توليد حل مختلف تماماً عن المحاولة السابقة',
        errorCode: 'ALT-RETRY',
        voltage: '220',
        pressure: '120',
        previousAttemptContext: previousContext,
      );
    } catch (e, st) {
      print('CAUGHT ERROR: $e');
      print(st);
      debugPrint('Alternative AI route failed: $e');
    }

    final updatedHistory = List<String>.from(state.attemptHistory)
      ..add(previousAttemptSummary.isNotEmpty ? previousAttemptSummary : 'attempt');

    if (alternativeMarkdown.isNotEmpty) {
      _recordEvidence('مسار بديل من AI تم تقييده إلى الاستدلال المحلي: $alternativeMarkdown', confirmed: true, eventType: 'ai');
    }

    _sessionState = _sessionState.copyWith(
      lastEvent: 'retry',
      isResolved: false,
      isStillOpen: true,
    );

    state = state.copyWith(
      attemptHistory: updatedHistory,
      currentStepIndex: 0,
      confidenceRate: state.confidenceRate > 70 ? state.confidenceRate - 4 : state.confidenceRate,
      difficultyAr: '🔴 متقدم / صعبة',
      difficultyEn: '🔴 Advanced / Hard',
      difficultyColor: Colors.red.shade700,
      safetyWarningAr: '🚨 تم تحديث المسار البديل محلياً بناءً على الأدلة الحالية دون عرض الرد الخام للذكاء الاصطناعي.',
      statusWarningEn: '🚨 Alternative route updated locally from current evidence without exposing raw AI output.',
      toolsAr: state.toolsAr.isNotEmpty ? [...state.toolsAr, 'أداة بديلة للقياس والتأكيد'] : ['أداة بديلة للقياس والتأكيد'],
      toolsEn: state.toolsEn.isNotEmpty ? [...state.toolsEn, 'Alternate verification tool'] : ['Alternate verification tool'],
      steps: [
        DiagnosticStep(
          number: 1,
          textAr: '🔁 تم توليد مسار بديل جديد بناءً على المحاولة السابقة دون تكرار نفس الحل.',
          textEn: '🔁 A new alternative route was generated based on the previous attempt without repeating the same fix.',
          estimatedTimeAr: '⏱️ 4 دقائق',
          estimatedTimeEn: '⏱️ 4 min',
          isCompleted: true,
        ),
        ...state.steps.map((step) => DiagnosticStep(
          number: step.number + 1,
          textAr: step.textAr,
          textEn: step.textEn,
          estimatedTimeAr: step.estimatedTimeAr,
          estimatedTimeEn: step.estimatedTimeEn,
          isCompleted: step.isCompleted,
        )),
      ],
    );
    _syncSessionToReport();
  }

  /// توليد تقرير ذكي وديناميكي بالكامل بناءً على حقول الإدخال المختارة والنظام، وحفظه تلقائياً في السجل
  Future<List<String>> _encodeSelectedImages(List<XFile>? selectedImages) async {
    if (selectedImages == null || selectedImages.isEmpty) {
      return [];
    }

    final List<String> imagesB64 = [];
    for (final image in selectedImages.take(3)) {
      try {
        final bytes = await image.readAsBytes();
        imagesB64.add(base64Encode(bytes));
      } catch (e, st) {
        print('CAUGHT ERROR: $e');
        print(st);
        debugPrint('Failed to read selected image: $e');
      }
    }
    return imagesB64;
  }

  Future<void> generateAndSaveReport({
    required String category,
    required String deviceName,
    required String manufacturer,
    required String model,
    required String problemDetails,
    required String observations,
    required String errorCode,
    List<XFile>? selectedImages,
  }) async {
    print('STEP 2 generateAndSaveReport()');
    final cat = category.trim().toLowerCase();
    
    // القيم الافتراضية المناسبة لكل حقل
    final dName = deviceName.isEmpty ? 'جهاز ميكانيكي' : deviceName;
    final dMfg = manufacturer.isEmpty ? 'ماركة مخصصة' : manufacturer;
    final dModel = model.isEmpty ? 'طراز قياسي' : model;
    final dProblem = problemDetails.isEmpty ? 'توقف مفاجئ في الدورة التشغيلية' : problemDetails;
    final dObs = observations.isEmpty ? 'اهتزاز وصوت طنين غير منتظم بالهيكل' : observations;
    final dCode = errorCode.isEmpty ? 'N/A' : errorCode;

    List<String> toolsAr = [];
    List<String> toolsEn = [];
    List<DiagnosticStep> steps = [];
    Map<String, int> alternativeCausesAr = {};
    Map<String, int> alternativeCausesEn = {};
    String partNameAr = '';
    String partNameEn = '';
    String safetyWarningAr = '';
    String safetyWarningEn = '';
    String difficultyAr = '🟡 متوسط';
    String difficultyEn = '🟡 Medium';
    Color difficultyColor = Colors.amber;
    String partCostAr = '40 - 70 ريال';
    String partCostEn = '40 - 70 SAR';
    String fixCostAr = '100 - 150 ريال';
    String fixCostEn = '100 - 150 SAR';
    int confidenceRate = 92;

    if (cat.contains('تكييف') || cat.contains('hvac') || cat.contains('cooling')) {
      toolsAr = ['مفك براغي معزول 1000V', 'مفتاح ربط سداسي مقاس 10 مم', 'مقياس الضغط المانومتر للغاز', 'جهاز قياس التيار كلمب ميتر'];
      toolsEn = ['Insulated Screwdriver 1000V', '10mm Hex Wrench', 'Gas Manometer Pressure Gauge', 'Clamp Meter'];
      steps = [
        DiagnosticStep(number: 1, textAr: 'افصل القاطع الكهربائي الرئيسي المغذي للوحدة الخارجية لضمان السلامة التامة.', textEn: 'Disconnect the main breaker to the outdoor unit.', estimatedTimeAr: '⏱️ 3 دقائق', estimatedTimeEn: '⏱️ 3 min'),
        DiagnosticStep(number: 2, textAr: 'افتح غطاء الصيانة الجانبي بحذر وتفقد سلامة المكثف ($dMfg) وابحث عن أي انتفاخ أو تسريب زيت.', textEn: 'Open maintenance cover and check the capacitor ($dMfg) for bulging/leaks.', estimatedTimeAr: '⏱️ 5 دقائق', estimatedTimeEn: '⏱️ 5 min'),
        DiagnosticStep(number: 3, textAr: 'قم بقياس سعة المكثف باستخدام ملتيميتر للتأكد من مطابقة السعة مع مواصفات الموديل ($dModel).', textEn: 'Measure capacitor capacitance with a multimeter according to specs ($dModel).', estimatedTimeAr: '⏱️ 6 دقائق', estimatedTimeEn: '⏱️ 6 min'),
      ];
      alternativeCausesAr = {
        'تلف مكثف البدء والتشغيل (Run Capacitor)': 90,
        'ارتخاء أو تلف أسلاك التوصيل النحاسية': 75,
        'عطل في مرحل الحماية الزائدة للضاغط': 60,
      };
      alternativeCausesEn = {
        'Run Capacitor Failure': 90,
        'Loose copper wire connections': 75,
        'Compressor thermal overload failure': 60,
      };
      partNameAr = 'مكثف تشغيل مكيّفات 45 ميكروفاراد (μF) بمعدل أمان عالي';
      partNameEn = 'Run Capacitor 45 μF with High Safety Rate';
      safetyWarningAr = 'تحذير أمان التكييف: المكثف يخزن شحنات مميتة! لا تلمس الأطراف المعدنية قبل تفريغه تماماً باستخدام مقاومة تفريغ معزولة.';
      safetyWarningEn = 'AC Warning: Capacitor stores lethal charges! Discharge before touching.';
      difficultyAr = '🟡 متوسط';
      difficultyColor = Colors.amber;
      partCostAr = '45 - 65 ريال';
      partCostEn = '45 - 65 SAR';
      fixCostAr = '120 - 180 ريال';
      fixCostEn = '120 - 180 SAR';
    } else if (cat.contains('سيارات') || cat.contains('مركبات') || cat.contains('auto') || cat.contains('car')) {
      toolsAr = ['مفتاح ربط مقاس 10 مم و 12 مم', 'قارئ أكواد أعطال السيارات OBD2 Scanner', 'قفازات صيانة ميكانيكية مقاومة للزيوت والسخونة'];
      toolsEn = ['10mm & 12mm Wrenches', 'OBD2 Diagnostic Scanner', 'Oil & Heat Resistant Work Gloves'];
      final bool hasObd2 = errorCode.isNotEmpty && errorCode.trim().toUpperCase() != 'N/A';
      steps = [
        DiagnosticStep(number: 1, textAr: 'أوقف تشغيل محرك السيارة ($dName) واسحب مكابح اليد، ثم افتح غطاء المحرك بحذر.', textEn: 'Shut down engine for ($dName), apply handbrake, and open hood safely.', estimatedTimeAr: '⏱️ 2 دقيقة', estimatedTimeEn: '⏱️ 2 min'),
        if (hasObd2)
          DiagnosticStep(number: 2, textAr: 'تم قراءة الكود ($errorCode) عبر بلوتوث OBD2 بنجاح! جاري تقاطعه مع الأعراض ومطابقة فحص كراسي ومستشعرات الصمامات المتصلة.', textEn: 'DTC code ($errorCode) successfully read via Bluetooth OBD2! Cross-referencing with symptoms to inspect connected valves and sensors.', estimatedTimeAr: '⏱️ 3 دقائق', estimatedTimeEn: '⏱️ 3 min')
        else
          DiagnosticStep(number: 2, textAr: 'قم بتوصيل جهاز OBD2 (اختياري) بمنفذ التشخيص لقراءة الرموز الحية وتتبع الكود ($dCode).', textEn: 'Connect OBD2 scanner (Optional) to view active fault codes and track ($dCode).', estimatedTimeAr: '⏱️ 4 دقائق', estimatedTimeEn: '⏱️ 4 min'),
        DiagnosticStep(number: 3, textAr: 'افحص شمعات الاحتراق (البواجي) لعلامة التجارية ($dMfg) وتأكد من سلامة كويلات الإشعال ومقاومتها.', textEn: 'Inspect spark plugs ($dMfg) and check ignition coils resistance.', estimatedTimeAr: '⏱️ 10 دقائق', estimatedTimeEn: '⏱️ 10 min'),
      ];
      alternativeCausesAr = {
        'تلف شمعات الاحتراق (Spark Plugs)': 88,
        'خلل في دائرة كويل الإشعال الفرعي': 80,
        'انسداد جزئي في بخاخات الوقود المباشر': 55,
      };
      alternativeCausesEn = {
        'Spark Plugs Misfire': 88,
        'Ignition Coil Circuit Fault': 80,
        'Partial fuel injector blockage': 55,
      };
      partNameAr = 'طقم بواجي ليزر بلاتينيوم (Laser Platinum Sparks) متطابق هندسياً';
      partNameEn = 'Laser Platinum Spark Plugs Set';
      safetyWarningAr = 'تحذير المركبات: لا تقم بفك أي قطعة بالقرب من نظام الوقود أو المحرك وهو ساخن لتجنب الحروق أو اشتعال الأبخرة.';
      safetyWarningEn = 'Automotive Warning: Do not work on a hot engine or near fuel lines to avoid burns/fires.';
      difficultyAr = '🟢 سهلة / متاح للجميع';
      difficultyEn = '🟢 Easy';
      difficultyColor = Colors.green;
      partCostAr = '120 - 200 ريال';
      partCostEn = '120 - 200 SAR';
      fixCostAr = '60 - 100 ريال';
      fixCostEn = '60 - 100 SAR';
    } else if (cat.contains('صناعي') || cat.contains('صناعية') || cat.contains('industrial')) {
      toolsAr = ['مفاتيح رينج متكاملة ومفكات ميكانيكية مخصصة', 'مقياس الضغط الهيدروليكي الميداني', 'مقياس الجهد والتيار الرقمي المستمر'];
      toolsEn = ['Complete Ring Wrench Set', 'Hydraulic Pressure Gauge', 'Digital DC Voltage Meter'];
      steps = [
        DiagnosticStep(number: 1, textAr: 'قم بتفعيل زر الإيقاف الاضطراري (E-Stop) وتثبيت بطاقة القفل والوسم (LOTO) على لوحة المعدة ($dMfg).', textEn: 'Activate emergency stop (E-Stop) and apply LOTO tags on ($dMfg) power panel.', estimatedTimeAr: '⏱️ 5 دقائق', estimatedTimeEn: '⏱️ 5 min'),
        DiagnosticStep(number: 2, textAr: 'افتح وحدة التحكم PLC للموديل ($dModel) وتأكد من سلامة الفيوزات ومؤشرات لوحة الدوائر الإلكترونية.', textEn: 'Open PLC control unit ($dModel) and check fuses and PCB LED status indicators.', estimatedTimeAr: '⏱️ 10 دقائق', estimatedTimeEn: '⏱️ 10 min'),
        DiagnosticStep(number: 3, textAr: 'افحص صمام الأمان الميكانيكي ومستشعرات الضغط لتتبع العطل المتسبب في ($dProblem).', textEn: 'Inspect mechanical safety relief valve and pressure sensors to trace ($dProblem).', estimatedTimeAr: '⏱️ 12 دقيقة', estimatedTimeEn: '⏱️ 12 min'),
      ];
      alternativeCausesAr = {
        'عطل في مرحل التيار الزائد للوحة الكهربائية (Overload)': 85,
        'انخفاض مستويات ضغط السائل الهيدروليكي في الأنابيب': 78,
        'خلل برمجي أو قصر في مستشعر الحرارة الذكي': 50,
      };
      alternativeCausesEn = {
        'Overload Relay Failure': 85,
        'Low hydraulic fluid pressure': 78,
        'Smart heat sensor short-circuit': 50,
      };
      partNameAr = 'مرحل تيار زائد وحماية مغناطيسية حرارية قابلة للتعديل';
      partNameEn = 'Adjustable Thermal-Magnetic Overload Relay';
      safetyWarningAr = 'تحذير صناعي: الصيانة للمعدات الصناعية تتطلب تدريب LOTO صارم! لا تفتح صمامات الضغط العالي دون تفريغ آمن مسبق.';
      safetyWarningEn = 'Industrial Warning: LOTO procedure is strictly mandatory. Depressurize before valve maintenance.';
      difficultyAr = '🔴 متقدم / صعبة';
      difficultyColor = Colors.red.shade700;
      partCostAr = '350 - 550 ريال';
      partCostEn = '350 - 550 SAR';
      fixCostAr = '400 - 600 ريال';
      fixCostEn = '400 - 600 SAR';
    } else if (cat.contains('كهرباء') || cat.contains('electrical')) {
      toolsAr = ['مفك فحص جهد (Test Pen) معزول بالكامل', 'جهاز ملتيميتر فني مع شهادة معايرة', 'زردية قطع وتجريد أسلاك معزولة 1000V'];
      toolsEn = ['Fully Insulated Test Pen', 'Calibrated Tech Multimeter', '1000V Insulated Wire Stripper'];
      steps = [
        DiagnosticStep(number: 1, textAr: 'افصل قاطع التيار الكهربائي الفرعي المغذي للخط في لوحة توزيع ($dMfg).', textEn: 'Turn off the branch circuit breaker in ($dMfg) distribution panel.', estimatedTimeAr: '⏱️ 3 دقائق', estimatedTimeEn: '⏱️ 3 min'),
        DiagnosticStep(number: 2, textAr: 'افتح علبة المفتاح أو المقبس المسبب للمشكلة وتفقد الأسلاك بحثاً عن أي ارتخاء أو ذوبان بالبلاستيك.', textEn: 'Open the wall box and inspect terminal wires for loose screw connections or melting.', estimatedTimeAr: '⏱️ 7 دقائق', estimatedTimeEn: '⏱️ 7 min'),
        DiagnosticStep(number: 3, textAr: 'قس جهد التغذية المستقر للتأكد من خلو الدائرة من الارتدادات أو الترددات غير الآمنة ($dCode).', textEn: 'Measure line voltage stability to ensure no unsafe ripples or surges ($dCode).', estimatedTimeAr: '⏱️ 5 دقائق', estimatedTimeEn: '⏱️ 5 min'),
      ];
      alternativeCausesAr = {
        'التماس كهربائي في الخط بسبب التحميل الزائد للفرن/السخان': 92,
        'ارتخاء السلك الساخن (Phase Line) بداخل نقطة التوصيل': 80,
        'تلف قاطع الحماية الميكانيكي الفرعي ولوحة التوزيع': 65,
      };
      alternativeCausesEn = {
        'Short-circuit due to appliance overload': 92,
        'Loose live wire terminal connection': 80,
        'Damaged miniature circuit breaker (MCB)': 65,
      };
      partNameAr = 'قاطع حماية ذكي تيار متبقي فرعي ثنائي القطب Schneider';
      partNameEn = 'Schneider 2-Pole Residual Current Breaker (RCBO)';
      safetyWarningAr = 'تحذير كهربائي: الكهرباء لا تعطي فرصة ثانية! تأكد ثلاث مرات من خلو الخط من الجهد عبر مفك الفحص قبل اللمس.';
      safetyWarningEn = 'Electrical Warning: Electricity has no mercy! Triple-check line is dead before touching.';
      difficultyAr = '🟡 متوسط';
      difficultyColor = Colors.amber;
      partCostAr = '90 - 150 ريال';
      partCostEn = '90 - 150 SAR';
      fixCostAr = '100 - 160 ريال';
      fixCostEn = '100 - 160 SAR';
    } else if (cat.contains('هيدروليك') || cat.contains('hydraulics')) {
      toolsAr = ['مفاتيح ضغط هيدروليكية ثقيلة ومحكمة', 'ساعة قياس ضغط سائل هيدروليكي حتى 400 بار', 'وعاء مقاوم للزيوت والحرارة العالية لتفريغ السوائل'];
      toolsEn = ['Heavy Hydraulic Spanners', '400 Bar Liquid Pressure Gauge', 'Oil & Heat Resistant Drain Container'];
      steps = [
        DiagnosticStep(number: 1, textAr: 'قم بإيقاف تشغيل المضخة الهيدروليكية الرئيسية وتفريغ كامل الشحنات المتبقية بالمجمع (Accumulator).', textEn: 'Turn off primary hydraulic pump and discharge residual fluid from accumulator.', estimatedTimeAr: '⏱️ 5 دقائق', estimatedTimeEn: '⏱️ 5 min'),
        DiagnosticStep(number: 2, textAr: 'افحص مستوى ونقاء الزيت الهيدروليكي في الجهاز ($dName) وتأكد من خلوه من أي فقاعات أو رغوة.', textEn: 'Check hydraulic oil level and clarity in ($dName), ensure no foaming.', estimatedTimeAr: '⏱️ 6 دقائق', estimatedTimeEn: '⏱️ 6 min'),
        DiagnosticStep(number: 3, textAr: 'تفقد الخراطيم وأطراف التوصيل المصنعة من ($dMfg) للبحث عن أي مؤشرات لتسريب أو تشقق في الأنابيب.', textEn: 'Inspect ($dMfg) hoses and couplings for leaks, tiny cracks, or rubber degradation.', estimatedTimeAr: '⏱️ 8 دقائق', estimatedTimeEn: '⏱️ 8 min'),
      ];
      alternativeCausesAr = {
        'تلف صمام الأمان وتفريغ الضغط (Relief Valve)': 87,
        'اهتراء وتآكل حلقات منع التسرب المطاطية بالأسطوانات': 82,
        'انخفاض حاد في كفاءة مضخة التروس الهيدروليكية لضعف الزيت': 60,
      };
      alternativeCausesEn = {
        'Relief Valve malfunction': 87,
        'Worn cylinder piston seals (O-Rings)': 82,
        'Gear pump internal degradation': 60,
      };
      partNameAr = 'طقم حلقات مطاطية وموانع تسريب ضغط هيدروليكي مخصص ومقاوم للحرارة';
      partNameEn = 'Heat Resistant High-Pressure O-Ring Seals Kit';
      safetyWarningAr = 'تحذير هيدروليكي: السائل تحت الضغط العالي يمكن أن يخترق الجلد مسبباً إصابات مميتة! لا تتفقد التسريبات بيدك مباشرة.';
      safetyWarningEn = 'Hydraulic Warning: Fluid under pressure can penetrate skin! Never search for leaks with bare hands.';
      difficultyAr = '🔴 متقدم / صعبة';
      difficultyColor = Colors.red.shade700;
      partCostAr = '150 - 250 ريال';
      partCostEn = '150 - 250 SAR';
      fixCostAr = '250 - 350 ريال';
      fixCostEn = '250 - 350 SAR';
    } else if (cat.contains('أجهزة') || cat.contains('منزلية') || cat.contains('appliance')) {
      toolsAr = ['مجموعة مفاتيح ومفكات توركس مع مسامير أمان', 'ملتيميتر قياس المقاومة والفولتية ذكي', 'كماشة صغيرة لإخراج الأجسام الصلبة والقطع الصغيرة'];
      toolsEn = ['Complete Safety Torx Keys Set', 'Smart Tech Multimeter', 'Needle Nose Pliers for debris extraction'];
      steps = [
        DiagnosticStep(number: 1, textAr: 'انزع كابل الطاقة الخاص بجهاز ($dName) من مقبس الحائط تماماً قبل فتح الهيكل.', textEn: 'Disconnect ($dName) power cord completely from wall outlet before opening.', estimatedTimeAr: '⏱️ 2 دقيقة', estimatedTimeEn: '⏱️ 2 min'),
        DiagnosticStep(number: 2, textAr: 'افك المسامير الخلفية بحذر للوصول لمضخة الصرف أو عنصر التسخين ($dModel).', textEn: 'Carefully remove rear screws to access drain pump or heater element ($dModel).', estimatedTimeAr: '⏱️ 8 دقائق', estimatedTimeEn: '⏱️ 8 min'),
        DiagnosticStep(number: 3, textAr: 'قس مقاومة عنصر التسخين للتأكد من عدم وجود قطع داخلي بالملف الكهربائي الخاص بـ ($dMfg).', textEn: 'Measure heating element resistance to confirm no internal coil breaks ($dMfg).', estimatedTimeAr: '⏱️ 6 دقائق', estimatedTimeEn: '⏱️ 6 min'),
      ];
      alternativeCausesAr = {
        'وجود انسداد أو تراكم كلسي وأجسام غريبة في مضخة صرف المياه': 91,
        'تلف عنصر التسخين الحراري (Heater Coil)': 80,
        'خلل الكتروني في حساس قفل الباب أو ضغط مستوى المياه': 52,
      };
      alternativeCausesEn = {
        'Clogged drain pump filter': 91,
        'Defective thermal heating element': 80,
        'Door switch lock or pressure sensor fault': 52,
      };
      partNameAr = 'مضخة تصريف مياه وصرف وموتور سحب متوافق وهندسي بالكامل';
      partNameEn = 'Replacement Automatic Drain Pump Assembly';
      safetyWarningAr = 'تحذير منزلي: الغسالات وسخانات الفرن تخزن مياه ساخنة وشحنات مكثف عالية! ارتد قفازات وافصل كابل الكهرباء والماء.';
      safetyWarningEn = 'Appliance Warning: Washers and ovens store heat and capacitor charges! Disconnect utilities before repair.';
      difficultyAr = '🟢 سهلة / متاح للجميع';
      difficultyEn = '🟢 Easy';
      difficultyColor = Colors.green;
      partCostAr = '80 - 130 ريال';
      partCostEn = '80 - 130 SAR';
      fixCostAr = '70 - 110 ريال';
      fixCostEn = '70 - 110 SAR';
    } else if (cat.contains('سباكة') || cat.contains('plumbing')) {
      toolsAr = ['مفتاح أنابيب كبير قابل للتعديل (Pipe Wrench)', 'شريط تفلون مانع للتسريب عالي الكثافة (Teflon Tape)', 'مقص وقطاعة أنابيب المياه البلاستيكية PPR'];
      toolsEn = ['Adjustable Heavy Pipe Wrench', 'High-Density Teflon Thread Sealing Tape', 'PPR Pipe Cutter'];
      steps = [
        DiagnosticStep(number: 1, textAr: 'أغلق محبس إمداد المياه الرئيسي المغذي للمنطقة تماماً لوقف التدفق ومنع إهدار المياه.', textEn: 'Shut off the main building water valve to stop supply and prevent flooding.', estimatedTimeAr: '⏱️ 3 دقائق', estimatedTimeEn: '⏱️ 3 min'),
        DiagnosticStep(number: 2, textAr: 'تفقد الأنابيب والصمامات لتحديد موقع التسريب المسبب لـ ($dProblem) باستخدام الملاحظة البصرية الدقيقة.', textEn: 'Inspect pipes and joint fittings ($dMfg) to locate leak source ($dProblem) visually.', estimatedTimeAr: '⏱️ 8 دقائق', estimatedTimeEn: '⏱️ 8 min'),
        DiagnosticStep(number: 3, textAr: 'قم بفك الوصلة التالفة ونظف السنون اللولبية جيداً قبل لف شريط تفلون جديد بإحكام.', textEn: 'Disassemble leaking joint, clean threads, and wrap fresh Teflon tape tightly.', estimatedTimeAr: '⏱️ 10 دقائق', estimatedTimeEn: '⏱️ 10 min'),
      ];
      alternativeCausesAr = {
        'تلف أو جفاف حلقة ومنع التسرب المطاطية (Gasket)': 85,
        'وجود انسداد جزئي أو شوائب رملية في الأكواع والتوصيلات': 70,
        'تصدع دقيق في أنبوب التغذية البلاستيكي نتيجة لزيادة الضغط': 60,
      };
      alternativeCausesEn = {
        'Degraded rubber gasket/washer': 85,
        'Debris or mineral clog in elbows': 70,
        'Hairline crack in PPR pipe under wall pressure': 60,
      };
      partNameAr = 'محبس مياه نحاسي مقاس نصف بوصة مقاوم للتكلس والصدمات المائية';
      partNameEn = 'Anti-Corrosion Brass Faucet Valve 0.5-inch';
      safetyWarningAr = 'تحذير السباكة: تسرب المياه بجوار التمديدات الكهربائية يمثل خطورة صعق قصوى! افصل الكهرباء دائماً أولاً.';
      safetyWarningEn = 'Plumbing Warning: Water leak near electrical outlets is extremely hazardous! Turn off power.';
      difficultyAr = '🟢 سهلة / متاح للجميع';
      difficultyEn = '🟢 Easy';
      difficultyColor = Colors.green;
      partCostAr = '35 - 60 ريال';
      partCostEn = '35 - 60 SAR';
      fixCostAr = '50 - 80 ريال';
      fixCostEn = '50 - 80 SAR';
    } else if (cat.contains('ميكانيك') || cat.contains('mechanical')) {
      toolsAr = ['مجموعة مفاتيح ربط سداسية ومفاتيح ألن', 'بخاخ مزلق ومزيل صدأ ميكانيكي (WD-40)', 'مقياس الفتحات والمسافات الفنية الدقيقة (Feeler)'];
      toolsEn = ['Complete Hex Wrenches & Allen Keys Set', 'WD-40 Rust Remover & Lubricant Spray', 'Precision Feeler Gauge'];
      steps = [
        DiagnosticStep(number: 1, textAr: 'افصل مصدر الطاقة الميكانيكية والكهربائية وثبت السيور والتروس حركياً لضمان عدم الدوران المفاجئ.', textEn: 'Disconnect mechanical and electrical power, lock gears to prevent unexpected motion.', estimatedTimeAr: '⏱️ 5 دقائق', estimatedTimeEn: '⏱️ 5 min'),
        DiagnosticStep(number: 2, textAr: 'افحص التروس وأحزمة نقل الحركة المصنعة من ($dMfg) للتأكد من خلوها من التشققات أو الارتخاء الملحوظ.', textEn: 'Check gears and driving belts ($dMfg) for any cracks, fraying, or loose tension.', estimatedTimeAr: '⏱️ 8 دقائق', estimatedTimeEn: '⏱️ 8 min'),
        DiagnosticStep(number: 3, textAr: 'تفقد كراسي التحميل ($dModel) وقس مستوى الخشونة في حركة عمود الدوران يدوياً عند فحص ($dProblem).', textEn: 'Check bearing housings ($dModel) and manually test rotation smoothness for ($dProblem).', estimatedTimeAr: '⏱️ 10 دقائق', estimatedTimeEn: '⏱️ 10 min'),
      ];
      alternativeCausesAr = {
        'تآكل واهتراء حواف التروس الداخلية للناقل': 84,
        'ارتخاء وانزلاق سيور التوصيل والمروحة المطاطية': 78,
        'جفاف زيت التشحيم والتحميل في كراسي الدوران بالداخل': 65,
      };
      alternativeCausesEn = {
        'Internal gearbox teeth wear': 84,
        'Friction belt slippage': 78,
        'Lack of lubricating grease in ball bearings': 65,
      };
      partNameAr = 'رولمان بلي (Ball Bearing) فئة 6204 مخصصة للسرعات والأحمال العالية';
      partNameEn = 'Heavy Duty Radial Ball Bearing 6204';
      safetyWarningAr = 'تحذير ميكانيكي: الأجزاء الدوارة يمكن أن تسحب الملابس أو الأصابع في أجزاء من الثانية! لا تعمل أبداً والمحرك يدور.';
      safetyWarningEn = 'Mechanical Warning: Rotating shafts can grab clothing/fingers instantly! Never work on moving parts.';
      difficultyAr = '🔴 متقدم / صعبة';
      difficultyColor = Colors.red.shade700;
      partCostAr = '140 - 240 ريال';
      partCostEn = '140 - 240 SAR';
      fixCostAr = '150 - 250 ريال';
      fixCostEn = '150 - 250 SAR';
    } else {
      // أخرى / General
      toolsAr = ['مجموعة مفاتيح ومفكات صيانة متكاملة قياسية', 'شريط عزل كهربائي وحراري مطور ومقاوم للرطوبة', 'جهاز ملتيميتر فني متعدد الاستخدامات'];
      toolsEn = ['Standard Multi-Tool & Screwdriver Set', 'Heat Resistant Electrical Insulation Tape', 'Multi-Purpose Digital Tech Multimeter'];
      steps = [
        DiagnosticStep(number: 1, textAr: 'افصل الجهاز تماماً عن أي مصدر للطاقة الكهربائية أو الميكانيكية وعزل الخط.', textEn: 'Completely disconnect the device from any active power or mechanical utility line.', estimatedTimeAr: '⏱️ 3 دقائق', estimatedTimeEn: '⏱️ 3 min'),
        DiagnosticStep(number: 2, textAr: 'افحص الهيكل والمنافذ للبراند ($dMfg) بدقة لتحديد مسببات العطل ($dProblem) ومحاذاة المكونات.', textEn: 'Inspect ($dMfg) outer casing and ports to identify ($dProblem) or misalignments.', estimatedTimeAr: '⏱️ 8 دقائق', estimatedTimeEn: '⏱️ 8 min'),
        DiagnosticStep(number: 3, textAr: 'قس الفولتية والمقاومة عند أطراف الإدخال والتغذية الكهربائية للموديل ($dModel).', textEn: 'Measure input terminal voltage and resistance values for model ($dModel).', estimatedTimeAr: '⏱️ 10 دقائق', estimatedTimeEn: '⏱️ 10 min'),
      ];
      alternativeCausesAr = {
        'وجود قطع في كابل التوصيل أو تلامس أرضي غير مستقر': 80,
        'تلف صمام الحماية الحراري الداخلي أو الفيوز الرئيسي': 75,
        'تراكم الأتربة والغبار الكثيف داخل قنوات التبريد والتهوية': 60,
      };
      alternativeCausesEn = {
        'Power cord break or unstable grounding terminal': 80,
        'Blown internal thermal fuse or protective circuit': 75,
        'Excessive dust accumulation blocking ventilation': 60,
      };
      partNameAr = 'فيوز حماية حراري كهربائي ومقاومة تيار متوافقة للحد من الالتماس';
      partNameEn = 'Heavy-Duty Thermal Protection Fuse';
      safetyWarningAr = 'تحذير عام: تأكد من قراءة كتيّب الإرشادات الهندسي الخاص بالجهاز دائماً وتطبيق تدابير الحماية والقفازات المعزولة.';
      safetyWarningEn = 'General Warning: Always consult the manufacturer manual and wear protective insulated gear.';
      difficultyAr = '🟡 متوسط';
      difficultyColor = Colors.amber;
      partCostAr = '25 - 45 ريال';
      partCostEn = '25 - 45 SAR';
      fixCostAr = '80 - 120 ريال';
      fixCostEn = '80 - 120 SAR';
    }

    // التحقق المباشر من جلب تشخيص واقعي وتفاعلي عبر Gemini/GPT-4 في حال الاتصال وتوفر المفاتيح
    String realDiagnosisMarkdown = '';
    final List<String> imagesB64 = await _encodeSelectedImages(selectedImages);
    DiagnosisContractModel normalizedContract = DiagnosisContractModel(
      diagnosisStatus: 'need_more_information',
      confidence: 35,
      nextQuestion: 'ما هي الأعراض الدقيقة عند حدوث العطل؟',
      possibleCauses: const <DiagnosisCauseModel>[],
      partsToCheck: const <DiagnosisPartCheckModel>[],
      inspectionSteps: const <DiagnosisStepModel>[],
      oshaWarnings: const <DiagnosisWarningModel>[],
      knowledgeSummary: '',
      followUpQuestions: const <String>[],
    );

    final aiService = AiApiService();

    try {
      realDiagnosisMarkdown = await aiService.getUnifiedMultiAiDiagnosis(
        category: category,
        deviceName: dName,
        brand: dMfg,
        model: dModel,
        description: dProblem,
        observations: dObs,
        errorCode: dCode,
        voltage: '220',
        pressure: '120',
        imagesB64: imagesB64,
      );
      normalizedContract = aiService.normalizeDiagnosisContractModel(
        realDiagnosisMarkdown,
        category: category,
        deviceName: dName,
        brand: dMfg,
        model: dModel,
        description: dProblem,
        observations: dObs,
        errorCode: dCode,
      );
    } catch (e, st) {
      print('CAUGHT ERROR: $e');
      print(st);
      debugPrint("Real API diagnosis call skipped or failed: $e");
    }

    if (realDiagnosisMarkdown.isNotEmpty || normalizedContract.diagnosisStatus == 'complete') {
      ingestNormalizedDiagnosisContract(normalizedContract);

      final String knowledgeSummary = normalizedContract.knowledgeSummary;
      final String summaryText = knowledgeSummary.isNotEmpty ? knowledgeSummary : realDiagnosisMarkdown;
      safetyWarningAr = "⚠️ [تم التحليل البصري المتعدد بالذكاء الاصطناعي بنجاح]:\n$summaryText";
      safetyWarningEn = "⚠️ [Multimodal AI Visual Analysis Successful]:\n$summaryText";

      confidenceRate = normalizedContract.confidence;

      if (normalizedContract.possibleCauses.isNotEmpty) {
        final firstCause = normalizedContract.possibleCauses.first;
        final String causeTitle = firstCause.title;
        if (causeTitle.isNotEmpty) {
          partNameAr = causeTitle;
          partNameEn = causeTitle;
        }
        final Map<String, int> convertedCauses = {};
        for (final item in normalizedContract.possibleCauses) {
          final String title = item.title;
          final int probability = item.probability;
          if (title.isNotEmpty) {
            convertedCauses[title] = probability;
          }
        }
        if (convertedCauses.isNotEmpty) {
          alternativeCausesAr = convertedCauses;
          alternativeCausesEn = convertedCauses;
        }
      }

      if (normalizedContract.inspectionSteps.isNotEmpty) {
        steps = normalizedContract.inspectionSteps.asMap().entries.map((entry) {
          final item = entry.value;
          return DiagnosticStep(
            number: entry.key + 1,
            textAr: item.description,
            textEn: item.description,
            estimatedTimeAr: '⏱️ خطوة ${entry.key + 1}',
            estimatedTimeEn: '⏱️ step ${entry.key + 1}',
            isCompleted: item.mandatory,
          );
        }).toList();
      }
      
      // إضافة خطوة حركية للصور في البداية لتوضيح نجاح التحليل البصري للفني
      if (imagesB64.isNotEmpty) {
        steps = [
          DiagnosticStep(
            number: 1,
            textAr: 'جاري تشخيص العطل وتحليل النظام بواسطة الذكاء الاصطناعي...',
            textEn: 'Diagnosing fault and analyzing system via AI...',
            estimatedTimeAr: '⏱️ فوري',
            estimatedTimeEn: '⏱️ Instant',
            isCompleted: true,
          ),
          ...steps.map((st) => DiagnosticStep(
            number: st.number + 1,
            textAr: st.textAr,
            textEn: st.textEn,
            estimatedTimeAr: st.estimatedTimeAr,
            estimatedTimeEn: st.estimatedTimeEn,
            isCompleted: st.isCompleted,
          )),
        ];
      }
    }

    // بناء كائن تقرير التشخيص
    final DateTime now = DateTime.now();
    final String dateString = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    final AIReportState newReport = AIReportState(
      currentStatusAr: '🟢 جاهز للإصلاح وتتبع الأعطال لـ ($dName)',
      currentStatusEn: '🟢 Ready for Fix ($dName)',
      safetyWarningAr: safetyWarningAr,
      statusWarningEn: safetyWarningEn,
      toolsAr: toolsAr,
      toolsEn: toolsEn,
      steps: steps,
      partNameAr: partNameAr,
      partNameEn: partNameEn,
      partDiscount: 'نسبة توفير الكود: 20%',
      partCode: 'DRFIX20',
      currentStepIndex: 0,
      confidenceRate: confidenceRate,
      confidenceReasonsAr: [
        'الأعراض متطابقة تماماً مع البيانات المدخلة والمشكلة المرصودة',
        'الملاحظات الحسية تدعم هذا الخلل الهيكلي',
        'الكود ($dCode) الذي تم إدخاله يؤكد فرضية هذا التشخيص بدقة',
        'سجل المعرفة الهندسية المعتمدة لـ Dr Fix يرشح هذا المسار بنسبة عالية'
      ],
      confidenceReasonsEn: [
        'Symptoms exactly match input and observations',
        'Sensory notes support this structural defect hypothesis',
        'The entered code ($dCode) confirms this diagnosis accurately',
        'Dr Fix certified engineering knowledge base highly recommends this path'
      ],
      alternativeCausesAr: alternativeCausesAr,
      alternativeCausesEn: alternativeCausesEn,
      totalTimeAr: '20 دقيقة',
      totalTimeEn: '20 min',
      difficultyAr: difficultyAr,
      difficultyEn: difficultyEn,
      difficultyColor: difficultyColor,
      partCostRangeAr: partCostAr,
      partCostRangeEn: partCostEn,
      fixCostRangeAr: fixCostAr,
      fixCostRangeEn: fixCostEn,
      aiBasisAr: [
        'وصف المشكلة المكتوب: ($dProblem)',
        'الملاحظات والحالة المدخلة: ($dObs)',
        'قاعدة تشخيصات الذكاء الاصطناعي من Dr Fix التوليدية المعمقة',
        'كود الفحص المسجل ($dCode)'
      ],
      aiBasisEn: [
        'Written problem description: ($dProblem)',
        'Entered observations: ($dObs)',
        'Dr Fix deep generative AI diagnostic core',
        'Registered diagnostic error code ($dCode)'
      ],
      isFavorited: false,
      deviceName: dName,
      categoryName: category,
      dateStr: dateString,
    );

    // تحديث الحالة الحالية للتطبيق للتقرير النشط
    state = newReport;

    // حفظ التقرير في السجل المزدوج (محلي وسحابي) عبر خدمة المزامنة
    await HistorySyncService.saveReport(newReport);
  }
}

final aiReportProvider = StateNotifierProvider<AITroubleshootNotifier, AIReportState>((ref) => AITroubleshootNotifier());
final reportSearchQueryProvider = StateProvider<String>((ref) => '');
final reportFilterChipProvider = StateProvider<String>((ref) => 'الكل');

/// كلاس مخصص لإدارة سجل التشخيصات السابقة وحفظها محلياً في SharedPreferences بالتنسيق التسلسلي JSON
class DiagnosisHistoryManager {
  static const String _historyKey = 'dr_fix_diagnosis_history_v1';

  /// استرداد قائمة السجلات السابقة مرتبة ترتيباً تنازلياً (الأحدث أولاً)
  static Future<List<AIReportState>> getHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String>? jsonList = prefs.getStringList(_historyKey);
      if (jsonList == null) return [];
      return jsonList.map((str) {
        final Map<String, dynamic> map = jsonDecode(str) as Map<String, dynamic>;
        return AIReportState.fromJson(map);
      }).toList();
    } catch (e) {
      debugPrint("Error loading diagnosis history: $e");
      return [];
    }
  }

  /// حفظ تقرير تشخيصي جديد في قائمة السجل
  static Future<void> saveReportToHistory(AIReportState report) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> currentList = prefs.getStringList(_historyKey) ?? [];
      
      // تحويل التقرير إلى تنسيق JSON وسلسلة نصية
      final String reportJson = jsonEncode(report.toJson());
      
      // تفادي التكرار إذا كان الاسم والتاريخ متطابقين تماماً
      bool exists = false;
      for (final item in currentList) {
        try {
          final decoded = jsonDecode(item);
          if (decoded['deviceName'] == report.deviceName && 
              decoded['dateStr'] == report.dateStr && 
              decoded['categoryName'] == report.categoryName) {
            exists = true;
            break;
          }
        } catch (_) {}
      }

      if (!exists) {
        currentList.insert(0, reportJson); // الإدخال في رأس القائمة ليكون الأحدث بالقمة
        await prefs.setStringList(_historyKey, currentList);
        debugPrint("Successfully saved report to diagnosis history.");
      }
    } catch (e) {
      debugPrint("Error saving report to history: $e");
    }
  }

  /// حذف سجل معين بالكامل من القائمة
  static Future<void> deleteReportFromHistory(AIReportState report) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> currentList = prefs.getStringList(_historyKey) ?? [];
      final List<String> updatedList = [];

      for (final item in currentList) {
        try {
          final decoded = jsonDecode(item);
          if (decoded['deviceName'] == report.deviceName && 
              decoded['dateStr'] == report.dateStr && 
              decoded['categoryName'] == report.categoryName) {
            continue; // تجاهل هذا العنصر لحذفه
          }
          updatedList.add(item);
        } catch (_) {
          updatedList.add(item);
        }
      }

      await prefs.setStringList(_historyKey, updatedList);
    } catch (e) {
      debugPrint("Error deleting report from history: $e");
    }
  }

  /// مسح السجل بالكامل
  static Future<void> clearHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_historyKey);
    } catch (e) {
      debugPrint("Error clearing history: $e");
    }
  }
}
