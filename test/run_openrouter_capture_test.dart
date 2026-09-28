import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dr_fix/data/repositories/diagnostic_prompts.dart';
import 'package:dio/dio.dart';
import 'dart:typed_data';

void main() {
  test('Run Gemini capture for two cases', () async {
    await dotenv.load();
    final repo = DiagnosticPromptsRepository();
    dotenv.env['OPENAI_API_KEY'] = '';
    dotenv.env['CLAUDE_API_KEY'] = '';
    dotenv.env['DEEPSEEK_API_KEY'] = '';

    // Case 1: Washer - no water drainage
    try {
      await repo.generateDiagnosticReport(
        apiKey: dotenv.env['GEMINI_API_KEY'],
        equipmentName: 'غسالة',
        equipmentType: 'غسالة',
        equipmentModel: '',
        additionalText: 'لا تصرف الماء',
      );
    } catch (_) {}

    // Case 2: Refrigerator - not cooling
    try {
      await repo.generateDiagnosticReport(
        apiKey: dotenv.env['GEMINI_API_KEY'],
        equipmentName: 'ثلاجة',
        equipmentType: 'ثلاجة',
        equipmentModel: '',
        additionalText: 'لا تبرد',
      );
    } catch (_) {}
  }, timeout: Timeout(Duration(minutes: 3)));
}
