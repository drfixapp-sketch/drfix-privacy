import 'package:dr_fix/presentation/widgets/forum_models_and_providers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ForumNotifier edit actions', () {
    late ForumNotifier notifier;

    setUp(() {
      notifier = ForumNotifier();
    });

    test('updates post description immediately', () {
      notifier.updatePostDescription('1', 'تحديث نص العطل الجديد');

      expect(notifier.state.first.description, 'تحديث نص العطل الجديد');
    });

    test('updates reply content immediately', () {
      notifier.addReply('1', 'فني', 'تكييف', 'نص الرد القديم');
      final replyId = notifier.state.first.replies.first.id;

      notifier.updateReplyContent('1', replyId, 'نص الرد المعدل');

      expect(notifier.state.first.replies.first.content, 'نص الرد المعدل');
    });
  });
}
