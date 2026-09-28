import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/diagnostic_prompts.dart';
import '../models/diagnostic_report_model.dart';

final diagnosticRepositoryProvider = Provider<DiagnosticPromptsRepository>((ref) {
  return DiagnosticPromptsRepository();
});

class DiagnosticEngineNotifier extends StateNotifier<AsyncValue<DiagnosticReportModel?>> {
  final DiagnosticPromptsRepository _repository;

  /// Signature of the last successful call — used to skip duplicate API hits.
  String? _lastSignature;

  DiagnosticEngineNotifier(this._repository) : super(const AsyncValue.data(null));

  Future<void> runLiveDiagnostic({
    String? apiKey,
    required String name,
    required String type,
    required String model,
    required String notes,
    Uint8List? imageBytes,
    String locale = 'en',
  }) async {
    // ── Cache guard: skip the API call if inputs haven't changed ──────────
    final signature = '$name|$type|$model|$notes|$locale';
    if (state.hasValue && state.value != null && _lastSignature == signature) {
      debugPrint('DiagnosticEngine: cache hit — skipping duplicate API call.');
      return;
    }
    _lastSignature = signature;

    state = const AsyncValue.loading();
    final stopwatch = Stopwatch()..start();
    try {
      final rawJsonResponse = await _repository.generateDiagnosticReport(
        apiKey: apiKey,
        equipmentName: name,
        equipmentType: type,
        equipmentModel: model,
        additionalText: notes,
        photoBytes: imageBytes,
        locale: locale,
      );

      final String encoded = jsonEncode(rawJsonResponse);
      debugPrint('RAW_DIAGNOSTIC_RESPONSE (first 300): ${encoded.substring(0, encoded.length > 300 ? 300 : encoded.length)}');

      final parsedReport = DiagnosticReportModel.fromJson(encoded);

      // 🛡️ قفل الحد الأدنى للعرض (Minimum Display Duration Lock = 4 ثوانٍ) لمنع وميض الواجهة الخاطف
      final elapsed = stopwatch.elapsedMilliseconds;
      const minDurationMs = 4000;
      if (elapsed < minDurationMs) {
        await Future.delayed(Duration(milliseconds: minDurationMs - elapsed));
      }

      state = AsyncValue.data(parsedReport);
    } catch (error, stackTrace) {
      debugPrint('DiagnosticEngineNotifier error: $error');
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Clears cached result so the next call always hits the API.
  void reset() {
    _lastSignature = null;
    state = const AsyncValue.data(null);
  }
}

final diagnosticEngineStateProvider =
    StateNotifierProvider<DiagnosticEngineNotifier, AsyncValue<DiagnosticReportModel?>>((ref) {
  final repo = ref.watch(diagnosticRepositoryProvider);
  return DiagnosticEngineNotifier(repo);
});
