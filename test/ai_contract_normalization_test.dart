import 'package:dr_fix/data/models/diagnosis_contract_model.dart';
import 'package:dr_fix/data/network/ai_api_service.dart';
import 'package:dr_fix/presentation/widgets/ai_report_state_notifier.dart';
import 'package:dr_fix/presentation/widgets/publication_draft_helper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AI response contract normalization', () {
    test('produces a stable contract shape from a raw diagnosis response', () {
      final service = AiApiService();

      final contract = service.normalizeDiagnosisContract(
        'Evidence: The unit is not cooling.\nHypotheses: Possible capacitor failure.\nElimination: Power is present.\nMost Likely Diagnosis: Faulty capacitor.',
        category: 'تكييف',
        deviceName: 'مكيف',
        brand: 'LG',
        model: 'AC-100',
        description: 'لا يبرد',
        observations: 'صوت طنين',
        errorCode: 'E1',
      );

      expect(contract['diagnosis_status'], 'complete');
      expect(contract['confidence'], isA<int>());
      expect(contract['possible_causes'], isA<List>());
      expect(contract['inspection_steps'], isA<List>());
      expect(contract['osha_warnings'], isA<List>());
      expect(contract['knowledge_summary'], isNotEmpty);
    });

    test('builds a compact payload with only essential diagnostic fields', () {
      final service = AiApiService();

      final payload = service.buildCompactDiagnosticPayload(
        category: 'تكييف',
        deviceName: 'مكيف',
        brand: 'LG',
        model: 'AC-100',
        description: 'لا يبرد',
        observations: 'صوت طنين',
        errorCode: 'E1',
        voltage: '220',
        pressure: '120',
      );

      expect(payload['system'], 'تكييف');
      expect(payload['device_name'], 'مكيف');
      expect(payload['error_code'], 'E1');
      expect(payload['user_description'], 'لا يبرد');
      expect(payload['observations'], 'صوت طنين');
    });

    test('returns a diagnosis contract model from the normalized AI response', () {
      final service = AiApiService();

      final contract = service.normalizeDiagnosisContractModel(
        'Evidence: The unit is not cooling.',
        category: 'تكييف',
        deviceName: 'مكيف',
        brand: 'LG',
        model: 'AC-100',
        description: 'لا يبرد',
        observations: 'صوت طنين',
        errorCode: 'E1',
      );

      expect(contract.diagnosisStatus, 'complete');
      expect(contract.confidence, greaterThan(0));
      expect(contract.possibleCauses, isNotEmpty);
      expect(contract.inspectionSteps, isNotEmpty);
    });

    test('injects a normalized AI contract into the session state', () {
      final notifier = AITroubleshootNotifier();
      notifier.ingestNormalizedDiagnosisContract(
        DiagnosisContractModel(
          diagnosisStatus: 'complete',
          confidence: 84,
          nextQuestion: '',
          possibleCauses: [
            DiagnosisCauseModel(title: 'مكثف معطل', probability: 84, description: 'الأعراض تشير إلى عطل المكثف.'),
          ],
          partsToCheck: const <DiagnosisPartCheckModel>[],
          inspectionSteps: [
            DiagnosisStepModel(step: 1, description: 'افحص المكثف', mandatory: true),
          ],
          oshaWarnings: const <DiagnosisWarningModel>[],
          knowledgeSummary: 'سبب واضح: المكثف معطل.',
          followUpQuestions: const <String>[],
        ),
      );

      expect(notifier.state.reasoningNarrativeAr, contains('المكثف'));
      expect(notifier.state.confidenceRate, greaterThan(0));
      expect(notifier.state.currentCauseIndex, 0);
      expect(notifier.state.diagnosisCompleted, isTrue);
      expect(notifier.state.diagnosisSolved, isTrue);
    });

    test('moves between inspection steps and records cause outcomes', () {
      final notifier = AITroubleshootNotifier();
      final initialStepCount = notifier.state.steps.length;
      if (initialStepCount > 1) {
        notifier.goToNextInspectionStep();
        expect(notifier.state.currentInspectionStep, lessThanOrEqualTo(initialStepCount - 1));
        notifier.goToPreviousInspectionStep();
        expect(notifier.state.currentInspectionStep, greaterThanOrEqualTo(0));
      }
      notifier.recordCurrentCauseResult('succeeded');
      expect(notifier.state.diagnosisCompleted, isTrue);
      expect(notifier.state.diagnosisSolved, isTrue);
    });

    test('does not create a PublicationDraft automatically when the journey ends (requires consent)', () {
      final notifier = AITroubleshootNotifier();
      notifier.recordCurrentCauseResult('failed');

      // PublicationDraft should NOT be created automatically; creation requires explicit user consent
      expect(notifier.state.publicationDraft, isNull);
    });

    test('marks successful and unsuccessful journeys as ready_for_admin_review when consent is granted', () {
      final successNotifier = AITroubleshootNotifier();
      successNotifier.recordCurrentCauseResult('succeeded');
      successNotifier.setUserConsentToShare(true);

      expect(successNotifier.state.publicationDraft, isNotNull);
      expect(successNotifier.state.publicationDraft!.solved, isTrue);
      expect(successNotifier.state.publicationDraft!.publicationType, 'knowledge_base');
      expect(successNotifier.state.publicationDraft!.status, 'ready_for_admin_review');

      final failureNotifier = AITroubleshootNotifier();
      failureNotifier.recordCurrentCauseResult('failed');
      failureNotifier.setUserConsentToShare(true);

      expect(failureNotifier.state.publicationDraft, isNotNull);
      expect(failureNotifier.state.publicationDraft!.solved, isFalse);
      expect(failureNotifier.state.publicationDraft!.publicationType, 'community_help');
      expect(failureNotifier.state.publicationDraft!.status, 'ready_for_admin_review');
    });

    test('routes solved journeys to knowledge_base drafts when consent is granted', () {
      final notifier = AITroubleshootNotifier();
      notifier.recordCurrentCauseResult('succeeded');
      notifier.setUserConsentToShare(true);

      expect(notifier.state.publicationDraft, isNotNull);
      expect(notifier.state.publicationDraft!.publicationType, 'knowledge_base');
      expect(notifier.state.publicationDraft!.status, 'ready_for_admin_review');
    });

    test('routes unsolved journeys to community_help drafts when consent is granted', () {
      final notifier = AITroubleshootNotifier();
      notifier.recordCurrentCauseResult('failed');
      notifier.setUserConsentToShare(true);

      expect(notifier.state.publicationDraft, isNotNull);
      expect(notifier.state.publicationDraft!.publicationType, 'community_help');
      expect(notifier.state.publicationDraft!.status, 'ready_for_admin_review');
    });

    test('redacts personal information before building a publication draft', () {
      final draft = PublicationDraftHelper.buildDraft(
        faultDescription: 'Contact John Doe at john@example.com',
        notes: 'Call 0501234567 for updates',
        solved: true,
        userConsentToShare: true,
      );

      expect(draft.faultDescription, contains('[REDACTED]'));
      expect(draft.notes, contains('[REDACTED]'));
    });
  });
}
