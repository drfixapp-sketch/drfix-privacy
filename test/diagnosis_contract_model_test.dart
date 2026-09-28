import 'package:dr_fix/data/models/diagnosis_contract_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DiagnosisContractModel', () {
    test('parses and serializes the diagnosis contract JSON', () {
      final json = {
        'diagnosis_status': 'complete',
        'confidence': 84,
        'next_question': '',
        'possible_causes': [
          {
            'title': 'مكثف معطل',
            'probability': 84,
            'description': 'الأعراض تشير إلى عطل المكثف.'
          }
        ],
        'parts_to_check': [
          {
            'part': 'المكثف',
            'action': 'Inspect',
            'reason': 'تحقق من التشغيل.'
          }
        ],
        'inspection_steps': [
          {
            'step': 1,
            'description': 'افحص المكثف',
            'mandatory': true
          }
        ],
        'osha_warnings': [
          {
            'risk': 'خطر صدمة كهربائية',
            'severity': 'High',
            'recommendation': 'افصل التيار قبل الفحص.'
          }
        ],
        'knowledge_summary': 'سبب واضح: المكثف معطل.',
        'follow_up_questions': ['ما هي القراءة الحالية؟']
      };

      final contract = DiagnosisContractModel.fromJson(json);
      expect(contract.diagnosisStatus, 'complete');
      expect(contract.possibleCauses.first.title, 'مكثف معطل');
      expect(contract.inspectionSteps.first.description, 'افحص المكثف');
      expect(contract.oshaWarnings.first.recommendation, 'افصل التيار قبل الفحص.');

      final roundTrip = DiagnosisContractModel.fromJson(contract.toJson());
      expect(roundTrip.knowledgeSummary, 'سبب واضح: المكثف معطل.');
      expect(roundTrip.followUpQuestions, ['ما هي القراءة الحالية؟']);
    });
  });
}
