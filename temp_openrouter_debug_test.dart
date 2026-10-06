import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dr_fix/data/network/ai_api_service.dart';

Future<void> main() async {
  await dotenv.load(fileName: "assets/app_config.env");
  final aiService = AiApiService();
  
  print('🚀 [DIAGNOSIS TEST STARTING...]');
  print('====================================');
  print('Device: تكييف شارب 2.25 حصان');
  print('Fault: الكمبروسر لا يعمل ويصدر صوت طنين عالي مع توقف التبريد تماماً');
  print('====================================');

  final String rawDiagnosisText = await aiService.getUnifiedMultiAiDiagnosis(
    category: 'تكييف وتبريد',
    deviceName: 'تكييف شارب 2.25 حصان',
    brand: 'Sharp',
    model: 'AH-A18USE',
    description: 'الكمبروسر لا يعمل ويصدر صوت طنين عالي مع توقف التبريد تماماً',
    observations: 'صوت زن قوي من الوحدة الخارجية عند التشغيل',
    errorCode: 'N/A',
    voltage: '220V',
    pressure: '120 PSI',
  );

  print('================ RAW DIAGNOSIS RESULT ================');
  print(rawDiagnosisText);
  print('======================================================');

  final normalizedContract = aiService.normalizeDiagnosisContractModel(
    rawDiagnosisText,
    category: 'تكييف وتبريد',
    deviceName: 'تكييف شارب 2.25 حصان',
    brand: 'Sharp',
    model: 'AH-A18USE',
    description: 'الكمبروسر لا يعمل ويصدر صوت طنين عالي مع توقف التبريد تماماً',
    observations: 'صوت زن قوي من الوحدة الخارجية عند التشغيل',
    errorCode: 'N/A',
  );

  print('================ NORMALIZED REPORT CONTRACT ================');
  print('Status: ${normalizedContract.diagnosisStatus}');
  print('Confidence: ${normalizedContract.confidence}%');
  print('Possible Causes Count: ${normalizedContract.possibleCauses.length}');
  for (var c in normalizedContract.possibleCauses) {
    print(' - Cause: ${c.title} (${c.probability}%) -> ${c.description}');
  }
  print('Inspection Steps Count: ${normalizedContract.inspectionSteps.length}');
  for (var s in normalizedContract.inspectionSteps) {
    print(' - Step ${s.step}: ${s.description}');
  }
  print('OSHA Warnings Count: ${normalizedContract.oshaWarnings.length}');
  for (var w in normalizedContract.oshaWarnings) {
    print(' - Warning: ${w.risk} (${w.severity}) -> ${w.recommendation}');
  }
  print('============================================================');
  print('✅ [DIAGNOSIS TEST COMPLETED SUCCESSFULLY!]');
}
