
/// 📝 نموذج بيانات الملاحظات والشكاوى (Feedback Data Model)
class FeedbackModel {
  final String id;
  final String feedbackType; // e.g., 'Bug' (خلل برمجى), 'Suggestion' (اقتراح تحسين), 'Question' (استفسار عام)
  final String title;
  final String message;
  final String? contactEmail;
  final DateTime createdAt;
  final bool isSynced; // للتحقق من حالة المزامنة وحالة قائمة الانتظار دون اتصال (Offline Queue)
  final String status; // open / in_progress / closed
  final String? adminReply; // رد المشرف/الأدمن
  final DateTime? repliedAt; // تاريخ الرد
  final String? fcmToken; // رمز الجهاز لتوجيه الإشعارات المستهدفة

  FeedbackModel({
    required this.id,
    required this.feedbackType,
    required this.title,
    required this.message,
    this.contactEmail,
    required this.createdAt,
    this.isSynced = true,
    this.status = 'open',
    this.adminReply,
    this.repliedAt,
    this.fcmToken,
  });

  FeedbackModel copyWith({
    String? id,
    String? feedbackType,
    String? title,
    String? message,
    String? contactEmail,
    DateTime? createdAt,
    bool? isSynced,
    String? status,
    String? adminReply,
    DateTime? repliedAt,
    String? fcmToken,
  }) {
    return FeedbackModel(
      id: id ?? this.id,
      feedbackType: feedbackType ?? this.feedbackType,
      title: title ?? this.title,
      message: message ?? this.message,
      contactEmail: contactEmail ?? this.contactEmail,
      createdAt: createdAt ?? this.createdAt,
      isSynced: isSynced ?? this.isSynced,
      status: status ?? this.status,
      adminReply: adminReply ?? this.adminReply,
      repliedAt: repliedAt ?? this.repliedAt,
      fcmToken: fcmToken ?? this.fcmToken,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'feedbackType': feedbackType,
      'title': title,
      'message': message,
      'contactEmail': contactEmail,
      'createdAt': createdAt.toIso8601String(),
      'isSynced': isSynced ? 1 : 0,
      'status': status,
      'adminReply': adminReply,
      'repliedAt': repliedAt?.toIso8601String(),
      'fcmToken': fcmToken,
    };
  }

  factory FeedbackModel.fromMap(Map<String, dynamic> map) {
    return FeedbackModel(
      id: map['id'] ?? '',
      feedbackType: map['feedbackType'] ?? '',
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      contactEmail: map['contactEmail'],
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      isSynced: (map['isSynced'] ?? 1) == 1,
      status: map['status'] ?? 'open',
      adminReply: map['adminReply'],
      repliedAt: map['repliedAt'] != null ? DateTime.parse(map['repliedAt']) : null,
      fcmToken: map['fcmToken'],
    );
  }

  Map<String, dynamic> toJson() => toMap();

  factory FeedbackModel.fromJson(Map<String, dynamic> json) => FeedbackModel.fromMap(json);

  /// 🔥 Factory لتحويل مستند Firestore مباشرة مع دعم Timestamp
  factory FeedbackModel.fromFirestore(dynamic doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    final String id = doc.id as String? ?? '';

    DateTime parseDate(dynamic val) {
      if (val == null) return DateTime.now();
      // Firestore Timestamp
      if (val.runtimeType.toString().contains('Timestamp')) {
        return (val as dynamic).toDate() as DateTime;
      }
      return DateTime.tryParse(val.toString()) ?? DateTime.now();
    }

    return FeedbackModel(
      id: (data['id'] as String?)?.isNotEmpty == true ? data['id'] as String : id,
      feedbackType: data['feedbackType'] as String? ?? data['type'] as String? ?? 'other',
      title: data['title'] as String? ?? '',
      message: data['message'] as String? ?? '',
      contactEmail: data['contactEmail'] as String?,
      createdAt: parseDate(data['createdAt'] ?? data['created_at']),
      isSynced: true,
      status: data['status'] as String? ?? 'open',
      adminReply: data['adminReply'] as String?,
      repliedAt: data['repliedAt'] != null ? parseDate(data['repliedAt']) : null,
      fcmToken: data['fcmToken'] as String?,
    );
  }
}
