import 'package:flutter_riverpod/flutter_riverpod.dart';

/// كلاس نمذجة الرد المطور لحفظ هوية المهندس وتجربته الفنية
class LiveReplyModel {
  final String id;
  final String postId;
  final String authorName;
  final String content;
  final bool isApproved; // يتحكم في ظهور الرد حياً بناءً على موافقة الأدمن

  LiveReplyModel({
    required this.id,
    required this.postId,
    required this.authorName,
    required this.content,
    this.isApproved = false, // الحالة الافتراضية معلقة دائمًا لحين موافقة الأدمن
  });

  LiveReplyModel copyWith({bool? isApproved}) {
    return LiveReplyModel(
      id: id,
      postId: postId,
      authorName: authorName,
      content: content,
      isApproved: isApproved ?? this.isApproved,
    );
  }
}

class CommunityReplyNotifier extends StateNotifier<List<LiveReplyModel>> {
  CommunityReplyNotifier() : super([]);

  // خوارزمية حقن واستقبال الرد المباشر المطور مع دمج حقل الاسم (Inline Name-Field Pipeline)
  void submitInlineReply({
    required String postId,
    required String authorName,
    required String content,
  }) {
    // بناء كائن الرد الجديد بحالة معلقة مع حفظ وتوثيق الاسم المدخل من شريط الرد
    final newReply = LiveReplyModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      postId: postId,
      authorName: authorName.trim().isEmpty ? 'فني مجهول الهوية' : authorName.trim(),
      content: content.trim(),
      isApproved: false, // لا ينشر حياً للمجتمع فوراً بل يوجه لغرفة التحكم الإدارية
    );

    // حقن الرد في المستودع المحلي المؤقت وتحديث الـ State
    state = [...state, newReply];
    
    // بروتوكول الأتمتة المتبادل: هنا يتم عمل POST للـ API وضخ الرد في "الردود المعلقة" بلوحة الأدمن
    // _apiService.post('/admin/moderation/replies', data: newReply.toMap());
  }

  // بروتوكول التحكم والموافقة الإدارية (Admin Approval Workflow)
  void approveReplyFromAdmin(String replyId) {
    state = [
      for (final reply in state)
        if (reply.id == replyId) reply.copyWith(isApproved: true) else reply
    ];
  }

  // بروتوكول الرفض والحذف الحتمي والنهائي من قاعدة البيانات عند نقر "رفض" في لوحة الأدمن
  void rejectAndDeleteReplyFromAdmin(String replyId) {
    // إزالة الرد بالكامل من مصفوفة الحالة وتطهير الذاكرة لمنع تراكم البيانات المرفوضة
    state = state.where((reply) => reply.id != replyId).toList();
  }
}

// الـ Provider المركزي والموحد المسؤول عن تدفق ومراقبة الردود المعلقة والمعتمدة في مجتمع الخبرات
final communityReplyProvider = StateNotifierProvider<CommunityReplyNotifier, List<LiveReplyModel>>((ref) {
  return CommunityReplyNotifier();
});
