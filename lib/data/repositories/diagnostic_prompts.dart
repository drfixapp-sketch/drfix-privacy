import 'dart:convert';
import 'dart:typed_data';
import '../network/ai_api_service.dart';

class DiagnosticPromptsRepository {
  static Map<String, dynamic>? lastRawResponse;
  final AiApiService _aiApiService;

  DiagnosticPromptsRepository({AiApiService? aiApiService})
      : _aiApiService = aiApiService ?? AiApiService();

  Future<Map<String, dynamic>> generateDiagnosticReport({
    String? apiKey,
    required String equipmentName,
    required String equipmentType,
    required String equipmentModel,
    required String additionalText,
    Uint8List? photoBytes,
    String locale = 'en',
  }) async {
    final String lang = locale == 'ar'
        ? 'Arabic (Modern Standard Arabic). ALL JSON values MUST be in Arabic.'
        : 'English. ALL JSON values MUST be in English.';

    final String normalizedEquipmentName = equipmentName.trim().isNotEmpty ? equipmentName.trim() : 'غير محدد';
    final String normalizedEquipmentType = equipmentType.trim().isNotEmpty ? equipmentType.trim() : 'غير محدد';
    final String normalizedEquipmentModel = equipmentModel.trim().isNotEmpty ? equipmentModel.trim() : 'غير محدد';
    final String normalizedAdditionalText = additionalText.trim().isNotEmpty ? additionalText.trim() : 'لا توجد ملاحظات إضافية.';

    final String prompt =
        'You are Dr.Fix Expert AI Diagnostic Engine. '
        'Return ONE minified JSON object only—no markdown, no code blocks, no extra text.\n\n'
        'INPUT:\n'
        '- Name: $normalizedEquipmentName | Type: $normalizedEquipmentType | Model: $normalizedEquipmentModel\n'
        '- Observations: $normalizedAdditionalText\n'
        '- Language: $lang\n\n'
        'OUTPUT SCHEMA (keys always in English, values in target language):\n'
        '{\n'
        '  "diagnosis_status": "complete",\n'
        '  "confidence": 85,\n'
        '  "knowledge_summary": "ملخص فني تحليلي للأعطال والأسباب",\n'
        '  "possible_causes": [\n'
        '    {"title": "اسم السبب المحتمل", "probability": 85, "description": "شرح السبب الفني بالتفصيل"}\n'
        '  ],\n'
        '  "inspection_steps": [\n'
        '    {"step": 1, "instruction": "خطوة الفحص العملي الدقيق"}\n'
        '  ],\n'
        '  "osha_warnings": [\n'
        '    "⚠️ Safety Assessment Before Starting",\n'
        '    "تحذير السلامة المهنية ومخاطر الفحص"\n'
        '  ],\n'
        '  "parts_to_check": [\n'
        '    "اسم القطعة\\nReason: سبب الاشتباه الفني الدقيق"\n'
        '  ],\n'
        '  "operation_guide": {\n'
        '    "start_steps": ["خطوة التشغيل الآمن"],\n'
        '    "stop_steps": ["خطوة الإيقاف الآمن"],\n'
        '    "normal_conditions": ["المؤشرات الطبيعية للعمل"],\n'
        '    "shutdown_signs": ["علامات التوقف الفوري"]\n'
        '  },\n'
        '  "maintenance_program": {\n'
        '    "daily": ["فحص يومي"],\n'
        '    "weekly": ["فحص أسبوعي"],\n'
        '    "monthly": ["فحص شهري"],\n'
        '    "semi_annual": ["فحص نصف سنوي"],\n'
        '    "annual": ["فحص سنوي"]\n'
        '  },\n'
        '  "operating_errors": ["خطأ تشغيلي يجب تفاديه"],\n'
        '  "longevity_recommendations": ["توصية لإطالة العمر التشغيلي"]\n'
        '}\n\n'
        'CRITICAL AND MANDATORY RULES (STRICT JSON ONLY):\n'
        '1. Output MUST be 100% valid, syntactically correct, pure JSON starting with { and ending with }.\n'
        '2. Absolutely ZERO conversational text, explanations, or commentary outside the JSON curly braces { }.\n'
        '3. Do NOT wrap the JSON in markdown code blocks (do NOT use ```json or ```). Return the raw JSON directly.\n'
        '4. All JSON keys MUST match the exact English spelling and casing specified in the OUTPUT SCHEMA above.\n'
        '5. "possible_causes" must contain at least 2 distinct causes with "title", "probability", and "description".\n'
        '6. "inspection_steps" must contain at least 3 actionable steps with "step" and "instruction".\n'
        '7. "osha_warnings"[0] MUST be the exact literal header: "⚠️ Safety Assessment Before Starting". All items in "osha_warnings" must be simple strings (never key-value pairs).\n'
        '8. "parts_to_check" is REQUIRED — each item must be a string in the format: "PartName\\nReason: why_suspected".\n'
        '9. Ensure all strings are properly escaped and there are no trailing commas.\n'
        '10. Return ONLY the single JSON object.';

    final String imagePayload =
        (photoBytes != null && photoBytes.isNotEmpty) ? base64Encode(photoBytes) : '';

    try {
      final result = await _aiApiService.executeStructuredRequest(
        apiKey: apiKey,
        prompt: prompt,
        imagesB64: imagePayload.isEmpty ? null : [imagePayload],
      );
      lastRawResponse = result;
      return result;
    } catch (e) {
      rethrow;
    }
  }
}
