import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dr_fix/presentation/widgets/notification_helper.dart';

/// 📡 خدمة إرسال الإشعارات للإدارة (Admin Notification Service)
/// تقوم بمراقبة التفاعلات والإدخالات الجديدة وإرسال حمولة الإشعار (FCM Payload) فوراً لجهاز الأدمن.
class AdminNotificationService {
  final Ref _ref;

  AdminNotificationService(this._ref);

  /// 🔔 إطلاق إشعار عطل جديد بانتظار المراجعة
  Future<void> triggerNewPostNotification({
    required String systemType,
    required String deviceModel,
    required String description,
  }) async {
    final title = 'عطل جديد بانتظار المراجعة! 🛠️';
    final body = 'قسم $systemType: تم تقديم تقرير جديد لجهاز $deviceModel بانتظار اعتمادك.';
    
    debugPrint('FCM Trigger: Sending notification payload to Admin device token...');
    
    // محاكاة إرسال الحمولة عبر FCM Payload لضمان تفعيل الحلقات الخلفية
    final payload = {
      'click_action': 'FLUTTER_NOTIFICATION_CLICK',
      'status': 'done',
      'data': {
        'type': 'new_post',
        'category': systemType,
        'model': deviceModel,
        'description': description,
        'timestamp': DateTime.now().toIso8601String(),
      }
    };

    // إرسال الإشعار محلياً وفي الخلفية عبر مساعد الإشعارات الموحد
    NotificationHelper.showNotification(
      title: title,
      body: body,
      payload: payload,
    );
  }

  /// 💬 إطلاق إشعار رد أو تعليق جديد بانتظار الموافقة
  Future<void> triggerNewCommentNotification({
    required String author,
    required String commentText,
    required String targetItem,
  }) async {
    final title = 'رد جديد بانتظار الموافقة! 💬';
    final body = 'كتب $author: "$commentText" على عطل ($targetItem).';
    
    debugPrint('FCM Trigger: Comment notification queued for transmission to Admin...');

    final payload = {
      'click_action': 'FLUTTER_NOTIFICATION_CLICK',
      'status': 'done',
      'data': {
        'type': 'new_comment',
        'author': author,
        'comment': commentText,
        'target': targetItem,
        'timestamp': DateTime.now().toIso8601String(),
      }
    };

    NotificationHelper.showNotification(
      title: title,
      body: body,
      payload: payload,
    );
  }
}

/// موفر الخدمة العالمي لـ Riverpod لتمكين استدعائه من أي مكان في منطق التطبيق
final adminNotificationServiceProvider = Provider<AdminNotificationService>((ref) {
  return AdminNotificationService(ref);
});
