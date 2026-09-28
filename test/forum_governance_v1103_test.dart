import 'package:flutter_test/flutter_test.dart';
import 'package:dr_fix/presentation/widgets/forum_models_and_providers.dart';

void main() {
  group('Forum Governance v1.1.0+3 Architecture Tests', () {
    late ForumNotifier notifier;

    setUp(() {
      notifier = ForumNotifier();
    });

    test('1. ForumReply model defaults to isApproved: false and serializes correctly for Subcollection', () {
      final reply = ForumReply(
        id: 'reply_999',
        author: 'مهندس فحص',
        specialty: 'تكييف وتبريد',
        content: 'فحص صمام التمدد الحراري وتنظيف الفلتر',
        createdAt: DateTime(2026, 9, 7),
      );

      // Default must be false for pending moderation pipeline
      expect(reply.isApproved, isFalse);

      final json = reply.toJson();
      expect(json['id'], 'reply_999');
      expect(json['is_approved'], isFalse);
      expect(json['isApproved'], isFalse);

      final fromJson = ForumReply.fromJson(json);
      expect(fromJson.id, 'reply_999');
      expect(fromJson.isApproved, isFalse);
      expect(fromJson.content, 'فحص صمام التمدد الحراري وتنظيف الفلتر');

      final approvedReply = reply.copyWith(isApproved: true);
      expect(approvedReply.isApproved, isTrue);
      expect(approvedReply.toJson()['is_approved'], isTrue);
    });

    test('2. ForumPost model supports imageUrl and status for Cloud Production', () {
      final post = ForumPost(
        id: 'post_101',
        author: 'الفني محمود',
        specialty: 'هيدروليك',
        title: 'تسريب زيت في المضخة الرئيسية',
        description: 'تسريب قوي عند صمام التوزيع تحت الضغط العالي',
        category: 'أنظمة هيدروليك',
        imageUrl: 'https://firebasestorage.googleapis.com/v0/b/drfix/o/forum_images%2Fpost_101.jpg',
        isApproved: false,
      );

      expect(post.imageUrl, isNotNull);
      expect(post.imageUrl, contains('forum_images%2Fpost_101.jpg'));
      expect(post.isApproved, isFalse);

      final json = post.toJson();
      expect(json['imageUrl'], post.imageUrl);
      expect(json['image_url'], post.imageUrl);
      expect(json['is_approved'], isFalse);

      final fromJson = ForumPost.fromJson(json);
      expect(fromJson.imageUrl, post.imageUrl);
      expect(fromJson.isApproved, isFalse);
    });

    test('3. submitForReview creates a pending post with isApproved: false', () async {
      await notifier.submitForReview(
        author: 'فني صناعي',
        specialty: 'كهرباء',
        title: 'احتراق فيوز الحماية الثلاثي',
        description: 'تلف مستمر في فيوزات لوحة التوزيع عند بدء تشغيل المحرك',
        category: 'كهرباء',
        imageUrl: 'https://storage.example.com/image.jpg',
      );

      final newlyAdded = notifier.state.last;
      expect(newlyAdded.title, 'احتراق فيوز الحماية الثلاثي');
      expect(newlyAdded.isApproved, isFalse);
      expect(newlyAdded.imageUrl, 'https://storage.example.com/image.jpg');
    });

    test('4. approvePost moves post to approved (isApproved: true)', () async {
      await notifier.submitForReview(
        author: 'فني معتمد',
        specialty: 'سيارات',
        title: 'عطل حساس الكرنك',
        description: 'صعوبة تشغيل المحرك صباحاً وظهور كود P0335',
        category: 'سيارات ومركبات',
      );

      final postId = notifier.state.last.id;
      expect(notifier.state.last.isApproved, isFalse);

      await notifier.approvePost(postId);

      final approvedPost = notifier.state.firstWhere((p) => p.id == postId);
      expect(approvedPost.isApproved, isTrue);
    });

    test('5. addReply adds a reply with default isApproved: false (Subcollection Pipeline)', () async {
      final initialPostId = notifier.state.first.id;
      final initialRepliesCount = notifier.state.first.replies.length;

      await notifier.addReply(
        initialPostId,
        'خبير استشاري',
        'تكييف',
        'يجب قياس المقاومة على ملفات الضاغط للتأكد من عدم وجود قصر داخلي',
      );

      final updatedPost = notifier.state.firstWhere((p) => p.id == initialPostId);
      expect(updatedPost.replies.length, equals(initialRepliesCount + 1));

      final lastReply = updatedPost.replies.last;
      expect(lastReply.author, 'خبير استشاري');
      expect(lastReply.isApproved, isFalse); // Subcollection reply must start pending
    });

    test('6. approveReply marks the specific reply as isApproved: true', () async {
      final targetPostId = notifier.state.first.id;
      await notifier.addReply(
        targetPostId,
        'مساعد فني',
        'تبريد',
        'تم حل المشكلة عبر استبدال الثرموستات',
      );

      final replyId = notifier.state.firstWhere((p) => p.id == targetPostId).replies.last.id;

      notifier.approveReply(targetPostId, replyId);

      final verifiedPost = notifier.state.firstWhere((p) => p.id == targetPostId);
      final verifiedReply = verifiedPost.replies.firstWhere((r) => r.id == replyId);
      expect(verifiedReply.isApproved, isTrue);
    });

    test('7. rejectReply removes the reply from the post subcollection state', () async {
      final targetPostId = notifier.state.first.id;
      await notifier.addReply(
        targetPostId,
        'سبام',
        'غير معروف',
        'محتوى مخالف للشروط',
      );

      final replyId = notifier.state.firstWhere((p) => p.id == targetPostId).replies.last.id;
      expect(notifier.state.firstWhere((p) => p.id == targetPostId).replies.any((r) => r.id == replyId), isTrue);

      await notifier.rejectReply(targetPostId, replyId);

      expect(notifier.state.firstWhere((p) => p.id == targetPostId).replies.any((r) => r.id == replyId), isFalse);
    });

    test('8. rejectPost removes the post completely from state', () async {
      await notifier.submitForReview(
        author: 'حساب ملغي',
        specialty: 'غير محدد',
        title: 'منشور غير صالح',
        description: 'سيتم حذفه من قبل الأدمن',
        category: 'أخرى',
      );

      final targetId = notifier.state.last.id;
      expect(notifier.state.any((p) => p.id == targetId), isTrue);

      await notifier.rejectPost(targetId);

      expect(notifier.state.any((p) => p.id == targetId), isFalse);
    });
  });
}
