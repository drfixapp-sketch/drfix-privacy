class PublicationDraft {
  final String deviceName;
  final String faultDescription;
  final String? successfulCause;
  final List<String> solutionSteps;
  final List<String> inspectedOrReplacedParts;
  final List<String> safetyWarnings;
  final List<String> attemptedCauses;
  final String notes;
  final bool solved;
  final String status;
  final String consentText;
  final String publicationType;
  final String sector;

  const PublicationDraft({
    required this.deviceName,
    required this.faultDescription,
    this.successfulCause,
    this.solutionSteps = const [],
    this.inspectedOrReplacedParts = const [],
    this.safetyWarnings = const [],
    this.attemptedCauses = const [],
    this.notes = '',
    required this.solved,
    this.status = 'pending_admin_review',
    this.consentText = 'أوافق على مشاركة هذا الملخص بعد إزالة أي بيانات شخصية، ليتم مراجعته من قبل الإدارة قبل النشر.',
    this.publicationType = 'community_help',
    this.sector = 'أخرى',
  });

  Map<String, dynamic> toJson() {
    return {
      'deviceName': deviceName,
      'faultDescription': faultDescription,
      'successfulCause': successfulCause,
      'solutionSteps': solutionSteps,
      'inspectedOrReplacedParts': inspectedOrReplacedParts,
      'safetyWarnings': safetyWarnings,
      'attemptedCauses': attemptedCauses,
      'notes': notes,
      'solved': solved,
      'status': status,
      'consentText': consentText,
      'publicationType': publicationType,
      'sector': sector,
    };
  }

  factory PublicationDraft.fromJson(Map<String, dynamic> json) {
    return PublicationDraft(
      deviceName: json['deviceName'] as String? ?? '',
      faultDescription: json['faultDescription'] as String? ?? '',
      successfulCause: json['successfulCause'] as String?,
      solutionSteps: List<String>.from(json['solutionSteps'] as List? ?? const []),
      inspectedOrReplacedParts: List<String>.from(json['inspectedOrReplacedParts'] as List? ?? const []),
      safetyWarnings: List<String>.from(json['safetyWarnings'] as List? ?? const []),
      attemptedCauses: List<String>.from(json['attemptedCauses'] as List? ?? const []),
      notes: json['notes'] as String? ?? '',
      solved: json['solved'] as bool? ?? false,
      status: json['status'] as String? ?? 'pending_admin_review',
      consentText: json['consentText'] as String? ?? 'أوافق على مشاركة هذا الملخص بعد إزالة أي بيانات شخصية، ليتم مراجعته من قبل الإدارة قبل النشر.',
      publicationType: json['publicationType'] as String? ?? 'community_help',
      sector: json['sector'] as String? ?? 'أخرى',
    );
  }
}

class PublicationDraftHelper {
  static PublicationDraft buildDraft({
    required String faultDescription,
    String? successfulCause,
    List<String> solutionSteps = const [],
    List<String> inspectedOrReplacedParts = const [],
    List<String> safetyWarnings = const [],
    List<String> attemptedCauses = const [],
    String notes = '',
    required bool solved,
    required bool userConsentToShare,
    String consentText = 'أوافق على مشاركة هذا الملخص بعد إزالة أي بيانات شخصية، ليتم مراجعته من قبل الإدارة قبل النشر.',
    String publicationType = 'community_help',
    String sector = 'أخرى',
  }) {
    final redactedFaultDescription = _redactPii(faultDescription);
    final redactedNotes = _redactPii(notes);

    return PublicationDraft(
      deviceName: '',
      faultDescription: redactedFaultDescription,
      successfulCause: successfulCause != null ? _redactPii(successfulCause) : null,
      solutionSteps: solutionSteps.map(_redactPii).toList(),
      inspectedOrReplacedParts: inspectedOrReplacedParts.map(_redactPii).toList(),
      safetyWarnings: safetyWarnings.map(_redactPii).toList(),
      attemptedCauses: attemptedCauses.map(_redactPii).toList(),
      notes: redactedNotes,
      solved: solved,
      status: userConsentToShare ? 'pending_admin_review' : 'pending_admin_review',
      consentText: consentText,
      publicationType: publicationType,
      sector: sector,
    );
  }

  static String _redactPii(String input) {
    final value = input.trim();
    if (value.isEmpty) return '[REDACTED]';

    final emailPattern = RegExp(r'[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}');
    final phonePattern = RegExp(r'\b(?:\+?966|0)?[0-9]{9,10}\b');
    final namePattern = RegExp(r'\b(?:Mr|Mrs|Ms|Dr|Prof)\.\s+[A-Z][a-z]+\b');

    var redacted = value.replaceAll(emailPattern, '[REDACTED]');
    redacted = redacted.replaceAll(phonePattern, '[REDACTED]');
    redacted = redacted.replaceAll(namePattern, '[REDACTED]');
    return redacted.isEmpty ? '[REDACTED]' : redacted;
  }
}
