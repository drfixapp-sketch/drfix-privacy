class DiagnosisContractModel {
  final String diagnosisStatus;
  final int confidence;
  final String nextQuestion;
  final List<DiagnosisCauseModel> possibleCauses;
  final List<DiagnosisPartCheckModel> partsToCheck;
  final List<DiagnosisStepModel> inspectionSteps;
  final List<DiagnosisWarningModel> oshaWarnings;
  final String knowledgeSummary;
  final List<String> followUpQuestions;

  DiagnosisContractModel({
    required this.diagnosisStatus,
    required this.confidence,
    required this.nextQuestion,
    required this.possibleCauses,
    required this.partsToCheck,
    required this.inspectionSteps,
    required this.oshaWarnings,
    required this.knowledgeSummary,
    required this.followUpQuestions,
  });

  factory DiagnosisContractModel.fromJson(Map<String, dynamic> json) {
    return DiagnosisContractModel(
      diagnosisStatus: (json['diagnosis_status'] as String?) ?? 'need_more_information',
      confidence: (json['confidence'] as num?)?.toInt() ?? 35,
      nextQuestion: (json['next_question'] as String?) ?? '',
      possibleCauses: (json['possible_causes'] as List<dynamic>?)
              ?.map((e) => DiagnosisCauseModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <DiagnosisCauseModel>[],
      partsToCheck: (json['parts_to_check'] as List<dynamic>?)
              ?.map((e) => DiagnosisPartCheckModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <DiagnosisPartCheckModel>[],
      inspectionSteps: (json['inspection_steps'] as List<dynamic>?)
              ?.map((e) => DiagnosisStepModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <DiagnosisStepModel>[],
      oshaWarnings: (json['osha_warnings'] as List<dynamic>?)
              ?.map((e) => DiagnosisWarningModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <DiagnosisWarningModel>[],
      knowledgeSummary: (json['knowledge_summary'] as String?) ?? '',
      followUpQuestions: (json['follow_up_questions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const <String>[],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'diagnosis_status': diagnosisStatus,
      'confidence': confidence,
      'next_question': nextQuestion,
      'possible_causes': possibleCauses.map((e) => e.toJson()).toList(),
      'parts_to_check': partsToCheck.map((e) => e.toJson()).toList(),
      'inspection_steps': inspectionSteps.map((e) => e.toJson()).toList(),
      'osha_warnings': oshaWarnings.map((e) => e.toJson()).toList(),
      'knowledge_summary': knowledgeSummary,
      'follow_up_questions': followUpQuestions,
    };
  }
}

class DiagnosisCauseModel {
  final String title;
  final int probability;
  final String description;

  DiagnosisCauseModel({
    required this.title,
    required this.probability,
    required this.description,
  });

  factory DiagnosisCauseModel.fromJson(Map<String, dynamic> json) {
    return DiagnosisCauseModel(
      title: (json['title'] as String?) ?? '',
      probability: (json['probability'] as num?)?.toInt() ?? 0,
      description: (json['description'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'probability': probability,
      'description': description,
    };
  }
}

class DiagnosisPartCheckModel {
  final String part;
  final String action;
  final String reason;

  DiagnosisPartCheckModel({
    required this.part,
    required this.action,
    required this.reason,
  });

  factory DiagnosisPartCheckModel.fromJson(Map<String, dynamic> json) {
    return DiagnosisPartCheckModel(
      part: (json['part'] as String?) ?? '',
      action: (json['action'] as String?) ?? '',
      reason: (json['reason'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'part': part,
      'action': action,
      'reason': reason,
    };
  }
}

class DiagnosisStepModel {
  final int step;
  final String description;
  final bool mandatory;

  DiagnosisStepModel({
    required this.step,
    required this.description,
    required this.mandatory,
  });

  factory DiagnosisStepModel.fromJson(Map<String, dynamic> json) {
    return DiagnosisStepModel(
      step: (json['step'] as num?)?.toInt() ?? 0,
      description: (json['description'] as String?) ?? '',
      mandatory: json['mandatory'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'step': step,
      'description': description,
      'mandatory': mandatory,
    };
  }
}

class DiagnosisWarningModel {
  final String risk;
  final String severity;
  final String recommendation;

  DiagnosisWarningModel({
    required this.risk,
    required this.severity,
    required this.recommendation,
  });

  factory DiagnosisWarningModel.fromJson(Map<String, dynamic> json) {
    return DiagnosisWarningModel(
      risk: (json['risk'] as String?) ?? '',
      severity: (json['severity'] as String?) ?? '',
      recommendation: (json['recommendation'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'risk': risk,
      'severity': severity,
      'recommendation': recommendation,
    };
  }
}
