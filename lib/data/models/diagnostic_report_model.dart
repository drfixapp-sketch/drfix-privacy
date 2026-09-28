import 'dart:convert';

class DiagnosticReportModel {
  final PrimaryDiagnosis primaryDiagnosis;
  final List<DifferentialDiagnosis> differentialDiagnoses;
  final List<String> oshaSafetyAlerts;
  final List<String> dynamicRiskQuestions;
  final List<String> actionableSteps;
  final List<String> potentialPartsToInspect;

  DiagnosticReportModel({
    required this.primaryDiagnosis,
    required this.differentialDiagnoses,
    required this.oshaSafetyAlerts,
    required this.dynamicRiskQuestions,
    required this.actionableSteps,
    required this.potentialPartsToInspect,
  });

  factory DiagnosticReportModel.fromJson(String rawJsonString) {
    String cleanJson = rawJsonString.trim();
    if (cleanJson.startsWith('```json')) cleanJson = cleanJson.substring(7);
    if (cleanJson.endsWith('```')) cleanJson = cleanJson.substring(0, cleanJson.length - 3);
    cleanJson = cleanJson.trim();

    Map<String, dynamic> jsonMap;
    print("JSON PARSER INPUT:");
    print(cleanJson);
    print("jsonDecode called from: DiagnosticReportModel.fromJson");
    try {
      jsonMap = jsonDecode(cleanJson) as Map<String, dynamic>;
    } catch (e) {
      jsonMap = {};
    }

    // ── الحقول الجديدة (ما يُرجعه AI حالياً) ──────────────────────────
    final newPossibleCauses = jsonMap['possible_causes'];
    final newInspectionSteps = jsonMap['inspection_steps'];
    final newOshaWarnings    = jsonMap['osha_warnings'];
    final newKnowledgeSummary = jsonMap['knowledge_summary'] as String?;
    final newConfidence = jsonMap['confidence'];

    // ── الحقول القديمة (backward compatibility) ───────────────────────
    final primaryData = jsonMap['PrimaryDiagnosis'] as Map<String, dynamic>? ?? {};

    // ── PrimaryDiagnosis ──────────────────────────────────────────────
    // faultName: قديم → PrimaryDiagnosis.faultName | جديد → possible_causes[0].title
    String faultName = primaryData['faultNameShort'] as String?
        ?? primaryData['faultName'] as String?
        ?? '';
    if (faultName.isEmpty && newPossibleCauses is List && newPossibleCauses.isNotEmpty) {
      faultName = (newPossibleCauses[0] as Map<String, dynamic>?)?['title'] as String? ?? '';
    }
    if (faultName.isEmpty) faultName = 'عطل الآلة المكتشف';

    // confidenceScore: قديم → PrimaryDiagnosis.confidenceScore | جديد → confidence
    int confidenceScore = 75;
    if (primaryData['confidenceScore'] != null) {
      confidenceScore = primaryData['confidenceScore'] is int
          ? primaryData['confidenceScore'] as int
          : int.tryParse(primaryData['confidenceScore'].toString()) ?? 75;
    } else if (newConfidence != null) {
      confidenceScore = newConfidence is int
          ? newConfidence
          : int.tryParse(newConfidence.toString()) ?? 75;
    }

    // mechanicalExplanation: قديم → PrimaryDiagnosis.mechanicalExplanation | جديد → knowledge_summary
    final mechanicalExplanation = primaryData['mechanicalExplanation'] as String?
        ?? newKnowledgeSummary
        ?? 'جاري تحليل الأنماط الميدانية الحية والمشاهدات الحسية من السيرفر...';

    final primary = PrimaryDiagnosis(
      faultName: faultName,
      confidenceScore: confidenceScore,
      mechanicalExplanation: mechanicalExplanation,
    );

    // ── DifferentialDiagnoses ─────────────────────────────────────────
    // قديم → DifferentialCauses / DifferentialDiagnosis
    // جديد → possible_causes (title + probability)
    final List<DifferentialDiagnosis> differentials = [];
    if (jsonMap['DifferentialCauses'] is List) {
      for (var item in (jsonMap['DifferentialCauses'] as List)) {
        if (item is Map<String, dynamic>) differentials.add(DifferentialDiagnosis.fromMap(item));
      }
    } else if (jsonMap['DifferentialDiagnosis'] is List) {
      for (var item in (jsonMap['DifferentialDiagnosis'] as List)) {
        if (item is Map<String, dynamic>) differentials.add(DifferentialDiagnosis.fromMap(item));
      }
    } else if (newPossibleCauses is List) {
      for (var item in newPossibleCauses) {
        if (item is Map<String, dynamic>) {
          differentials.add(DifferentialDiagnosis(
            faultName: item['title'] as String? ?? 'سبب محتمل',
            probability: item['probability'] is int
                ? item['probability'] as int
                : int.tryParse(item['probability'].toString()) ?? 35,
          ));
        }
      }
    }
    differentials.sort((a, b) => b.probability.compareTo(a.probability));

    // ── OSHA Safety Alerts ────────────────────────────────────────────
    // قديم → OSHAProtocols.oshaAlerts | جديد → osha_warnings
    final safetyData = jsonMap['OSHAProtocols'] as Map<String, dynamic>?
        ?? jsonMap['SafetyProtocols'] as Map<String, dynamic>?;
    final List<String> oshaAlerts;
    if (safetyData != null) {
      oshaAlerts = _safeParseStringList(safetyData['oshaAlerts'] ?? safetyData['lotoSteps'], 'OSHA');
    } else {
      oshaAlerts = _safeParseStringList(newOshaWarnings, 'OSHA');
    }

    // ── Risk Questions ────────────────────────────────────────────────
    // لا يوجد مقابل في الحقول الجديدة → fallback فقط عند الغياب الفعلي
    final riskQuestions = _safeParseStringList(
      safetyData?['riskAssessmentQuestions'] ?? safetyData?['requiredPPE'],
      'QUESTIONS',
    );

    // ── Actionable Steps ──────────────────────────────────────────────
    // قديم → ActionableSteps | جديد → inspection_steps[].instruction
    final List<String> actionable;
    if (jsonMap['ActionableSteps'] != null) {
      actionable = _safeParseStringList(jsonMap['ActionableSteps'], 'ACTIONABLE');
    } else if (newInspectionSteps is List) {
      actionable = newInspectionSteps
          .map((e) => (e is Map<String, dynamic>) ? (e['instruction'] as String? ?? '') : '')
          .where((s) => s.isNotEmpty)
          .toList();
      if (actionable.isEmpty) {
        actionable.addAll(_safeParseStringList(null, 'ACTIONABLE'));
      }
    } else {
      actionable = _safeParseStringList(null, 'ACTIONABLE');
    }

    // ── Potential Parts ───────────────────────────────────────────────
    // Primary key: parts_to_check (current AI output)
    // Fallbacks: legacy field names for backward compatibility
    final parts = _safeParseStringList(
      jsonMap['parts_to_check'] ??
          jsonMap['PotentialPartsToReplace'] ??
          jsonMap['PotentialPartsToInspect'],
      'PARTS',
    );

    return DiagnosticReportModel(
      primaryDiagnosis: primary,
      differentialDiagnoses: differentials,
      oshaSafetyAlerts: oshaAlerts,
      dynamicRiskQuestions: riskQuestions,
      actionableSteps: actionable,
      potentialPartsToInspect: parts,
    );
  }

  static List<String> _safeParseStringList(dynamic rawInput, String contextKey) {
    List<String> result = [];
    if (rawInput is List) {
      result = rawInput.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
      if (result.isNotEmpty) return result;
    }

    final String textToParse = rawInput?.toString() ?? '';
    if (textToParse.isNotEmpty && textToParse != 'null') {
      final regex = RegExp(r'(?:[•\-\*\d+\.]\s*)([^\n•\-\*]+)');
      final matches = regex.allMatches(textToParse);
      for (final match in matches) {
        final cleanLine = match.group(1)?.trim() ?? '';
        if (cleanLine.isNotEmpty && cleanLine.length > 2) result.add(cleanLine);
      }
      if (result.isEmpty) {
        result = textToParse.split('\n').map((e) => e.trim()).where((e) => e.length > 3).toList();
      }
    }

    if (result.isEmpty) {
      if (contextKey == 'OSHA') {
        result = ['⚠️ معايير أوشا حتمية: اعزل واقفل مصادر التغذية الأساسية بقفل وحامل بطاقات معتمد', 'تأكد من تصفير الضغوط الداخلية المخزنة بالدوائر قبل مباشرة التتبع الميداني'];
      } else if (contextKey == 'QUESTIONS') {
        result = ['هل قمت بالتحقق من خلو بيئة العمل المحيطة من أي سوائل أو غازات قابلة للاشتعال؟', 'هل ترتدي حالياً قفازات العزل الحراري المعتمدة ونظارات الحماية الشخصية لحمايتك؟'];
      } else if (contextKey == 'PARTS') {
        result = ['صمامات التحكم بالتوجيه والمحابس الرئيسية للنظام', 'الحشوات الميكانيكية ومانعات التسريب المطاطية المجاورة للوحدة'];
      } else {
        result = ['تفقد استقرار قراءات الجهد الكهربائي ومؤشرات لوحة التحكم', 'راجع الدليل الهندسي التشغيلي لمطابقة الكود القياسي للعطل المكتشف'];
      }
    }
    return result;
  }
}

class PrimaryDiagnosis {
  final String faultName;
  final int confidenceScore;
  final String mechanicalExplanation;
  PrimaryDiagnosis({required this.faultName, required this.confidenceScore, required this.mechanicalExplanation});
}

class DifferentialDiagnosis {
  final String faultName;
  final int probability;
  DifferentialDiagnosis({required this.faultName, required this.probability});
  factory DifferentialDiagnosis.fromMap(Map<String, dynamic> map) {
    return DifferentialDiagnosis(
      faultName: map['faultName'] as String? ?? 'سبب تشخيصي محتمل',
      probability: map['probability'] is int ? map['probability'] as int : int.tryParse(map['probability'].toString()) ?? 35,
    );
  }
}
