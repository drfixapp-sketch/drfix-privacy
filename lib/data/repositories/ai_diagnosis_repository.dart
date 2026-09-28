import 'package:dr_fix/data/network/ai_api_service.dart';
import 'package:dr_fix/data/network/exceptions.dart';

class AiDiagnosisRepository {
  final AiApiService _aiApiService;

  AiDiagnosisRepository(this._aiApiService);

  Future<List<Map<String, dynamic>>> getDynamicQuestionsForFault(
      String faultType) async {
    try {
      final response = await _aiApiService.getDynamicQuestionsForFault(faultType);
      return response.map((question) {
        if (question is Map) {
          return Map<String, dynamic>.from(question);
        }
        return <String, dynamic>{};
      }).toList();
    } catch (e) {
      print('Error fetching dynamic questions for fault in repository: $e');
      if (e is AppException) {
        rethrow;
      }
      throw UnknownException(technicalMessage: e.toString());
    }
  }

  Future<Map<String, dynamic>> getUnifiedMultiAiDiagnosisReport(
      List<String> faults) async {
    try {
      final response = await _aiApiService.getUnifiedMultiAiDiagnosisReport(faults);
      return response;
    } catch (e) {
      print('Error fetching unified multi-ai diagnosis report in repository: $e');
      if (e is AppException) {
        rethrow;
      }
      throw UnknownException(technicalMessage: e.toString());
    }
  }

  Future<Map<String, dynamic>> fetchDiagnosis({
    required String prompt,
    List<String>? imagesB64,
    String? apiKey,
  }) async {
    try {
      return await _aiApiService.fetchDiagnosis(
        prompt: prompt,
        imagesB64: imagesB64,
        apiKey: apiKey,
      );
    } catch (e) {
      print('Error in fetchDiagnosis in repository: $e');
      if (e is AppException) {
        rethrow;
      }
      throw UnknownException(technicalMessage: e.toString());
    }
  }
}