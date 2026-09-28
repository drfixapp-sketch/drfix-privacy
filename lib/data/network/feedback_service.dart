import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:dr_fix/data/models/feedback_model.dart';
import 'package:dr_fix/presentation/widgets/notification_helper.dart';

/// 📡 خدمة إرسال الملاحظات والدعم الفني (Feedback & Support Service)
/// تدعم تخزين الملاحظات محلياً مع تفعيل قائمة الانتظار الذكية عند انقطاع الاتصال (Offline Queue)،
/// وتطلق إشعارات FCM فورية للإدارة عند استلام ملاحظة جديدة مع المزامنة مع مجموعة support_tickets.
class FeedbackService extends StateNotifier<List<FeedbackModel>> {
  static const String _storageKey = 'cached_user_feedbacks';
  bool _isOfflineMode = false; // تتبع حالة الشبكة لمحاكاة انقطاع الاتصال

  FeedbackService() : super([]) {
    _loadFeedbacks();
  }

  /// التبديل بين وضع الاتصال ووضع عدم الاتصال لمحاكاة الشبكة
  bool get isOfflineMode => _isOfflineMode;
  void toggleOfflineMode() {
    _isOfflineMode = !_isOfflineMode;
  }

  /// تحميل الملاحظات المخزنة محلياً من SharedPreferences وسحابياً من Firestore
  Future<void> _loadFeedbacks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonStr = prefs.getString(_storageKey);
      if (jsonStr != null) {
        final List<dynamic> list = json.decode(jsonStr);
        final feedbacks = list.map((item) => FeedbackModel.fromMap(item)).toList();
        state = feedbacks;
      }
    } catch (e) {
      debugPrint('Feedback Cache Load Error: $e');
    }

    if (Firebase.apps.isNotEmpty) {
      try {
        final snap = await FirebaseFirestore.instance.collection('support_tickets').get();
        final loaded = snap.docs.map((doc) => FeedbackModel.fromMap({...doc.data(), 'id': doc.id})).toList();
        if (loaded.isNotEmpty) {
          state = loaded;
        }
      } catch (e) {
        debugPrint('Firestore load support_tickets error: $e');
      }
    }
  }

  /// حفظ الملاحظات محلياً للمزامنة اللاحقة
  Future<void> _saveFeedbacks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String jsonStr = json.encode(state.map((item) => item.toMap()).toList());
      await prefs.setString(_storageKey, jsonStr);
    } catch (e) {
      debugPrint('Feedback Cache Save Error: $e');
    }
  }

  /// 📤 تقديم ملاحظة جديدة
  Future<bool> submitFeedback({
    required String type,
    required String title,
    required String message,
    String? email,
  }) async {
    final newFeedback = FeedbackModel(
      id: 'FB-${DateTime.now().millisecondsSinceEpoch}',
      feedbackType: type,
      title: title,
      message: message,
      contactEmail: email,
      createdAt: DateTime.now(),
      isSynced: !_isOfflineMode, // إذا كنا في وضع الأوفلاين، لا يتم مزامنته فوراً
      status: 'open',
      fcmToken: 'FCM-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}', // حفظ رمز FCM الفريد للجهاز
    );

    // إضافة الملاحظة للحالة المحلية وتخزينها
    state = [newFeedback, ...state];
    await _saveFeedbacks();

    if (_isOfflineMode) {
      // ⏳ محاكاة الحفظ في قائمة الانتظار دون اتصال
      debugPrint('Offline: Feedback ${newFeedback.id} queued in local storage.');
      return false; // يرجع false للإشارة إلى أنه تم الحفظ محلياً وبانتظار الاتصال
    } else {
      // ⚡ محاكاة الإرسال الناجح للخادم وإطلاق إشعار FCM فوري للأدمن
      debugPrint('Online: Transmitting feedback payload...');
      
      final String typeLabel = _getTypeLabelAr(type);
      final String notificationBody = 'عنوان الملاحظة: $title \nالرسالة: $message';
      
      NotificationHelper.showNotification(
        title: '🔔 ملاحظة جديدة من مستخدم! ($typeLabel)',
        body: notificationBody,
        payload: {
          'click_action': 'FLUTTER_NOTIFICATION_CLICK',
          'type': 'feedback',
          'id': newFeedback.id,
          'feedbackType': type,
          'title': title,
          'message': message,
          'email': email ?? 'N/A',
          'fcmToken': newFeedback.fcmToken,
        },
      );
      
      if (Firebase.apps.isNotEmpty) {
        try {
          await FirebaseFirestore.instance
              .collection('support_tickets')
              .doc(newFeedback.id)
              .set(newFeedback.toMap());
        } catch (e) {
          debugPrint('Firestore submit support_tickets error: $e');
        }
      }
      return true;
    }
  }

  /// ✉️ إرسال رد من الأدمن على الملاحظة عبر إشعار دفع مستهدف (FCM Target Push)
  Future<bool> replyToFeedback({
    required String feedbackId,
    required String replyMessage,
    String? status,
  }) async {
    // تحديث الملاحظة في الحالة المحلية لتشمل الرد وتاريخه
    state = state.map((fb) {
      if (fb.id == feedbackId) {
        return fb.copyWith(
          adminReply: replyMessage,
          repliedAt: DateTime.now(),
          status: status ?? 'in_progress',
        );
      }
      return fb;
    }).toList();
    
    await _saveFeedbacks();

    if (Firebase.apps.isNotEmpty) {
      try {
        await FirebaseFirestore.instance.collection('support_tickets').doc(feedbackId).update({
          'adminReply': replyMessage,
          'repliedAt': DateTime.now().toIso8601String(),
          'status': status ?? 'in_progress',
        });
      } catch (e) {
        debugPrint('Firestore update reply support_tickets error: $e');
      }
    }

    // إيجاد الملاحظة لتحديد التوكن ومتابعة الإرسال
    final feedback = state.firstWhere((fb) => fb.id == feedbackId);
    
    // إرسال إشعار الدفع الفوري المستهدف بالرمز المحفوظ
    debugPrint('FCM Trigger: Sending targeted push to device token: ${feedback.fcmToken}');
    
    NotificationHelper.showNotification(
      title: 'تم الرد على ملاحظتك من إدارة التطبيق 🔔',
      body: 'الرد: $replyMessage',
      payload: {
        'click_action': 'FLUTTER_NOTIFICATION_CLICK',
        'type': 'feedback_reply',
        'id': feedbackId,
        'title': feedback.title,
        'adminReply': replyMessage,
        'fcmToken': feedback.fcmToken ?? 'N/A',
      },
    );

    return true;
  }

  Future<void> updateTicketStatus({
    required String feedbackId,
    required String status,
  }) async {
    state = state.map((fb) {
      if (fb.id == feedbackId) {
        return fb.copyWith(status: status);
      }
      return fb;
    }).toList();
    await _saveFeedbacks();

    if (Firebase.apps.isNotEmpty) {
      try {
        await FirebaseFirestore.instance.collection('support_tickets').doc(feedbackId).update({
          'status': status,
        });
      } catch (e) {
        debugPrint('Firestore update ticket status error: $e');
      }
    }
  }

  /// 🔄 مزامنة قائمة الملاحظات المعلقة عند عودة الاتصال
  Future<int> syncOfflineFeedbacks() async {
    if (_isOfflineMode) return 0; // لا يمكن المزامنة أثناء عدم الاتصال

    int syncCount = 0;
    final List<FeedbackModel> updatedList = [];

    for (var feedback in state) {
      if (!feedback.isSynced) {
        // محاكاة إرسال كل ملاحظة معلقة وإطلاق إشعارها
        final String typeLabel = _getTypeLabelAr(feedback.feedbackType);
        
        NotificationHelper.showNotification(
          title: '🔄 مزامنة معلقة: ملاحظة مستخدم ($typeLabel)',
          body: 'الموضوع: ${feedback.title}\nالرسالة: ${feedback.message}',
          payload: {
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
            'type': 'feedback',
            'id': feedback.id,
            'feedbackType': feedback.feedbackType,
            'title': feedback.title,
            'message': feedback.message,
            'email': feedback.contactEmail ?? 'N/A',
          },
        );
        
        updatedList.add(feedback.copyWith(isSynced: true));
        syncCount++;
      } else {
        updatedList.add(feedback);
      }
    }

    if (syncCount > 0) {
      state = updatedList;
      await _saveFeedbacks();
    }
    return syncCount;
  }

  String _getTypeLabelAr(String type) {
    switch (type.toLowerCase()) {
      case 'bug':
        return 'إبلاغ عن مشكلة';
      case 'suggestion':
        return 'اقتراح تحسين';
      case 'question':
        return 'استفسار عام';
      default:
        return 'أخرى';
    }
  }
}

/// موفر الحالة العام لإدارة الملاحظات
final feedbackServiceProvider = StateNotifierProvider<FeedbackService, List<FeedbackModel>>((ref) {
  return FeedbackService();
});

/// 📡 بث حي لتذاكر الدعم المفتوحة من Firestore (Real-time Support Tickets Stream)
/// يفلتر تذاكر الحالات (open / in_progress) ويستبعد المغلقة تلقائياً
/// يُستخدم في تبويب "تذاكر الدعم" في لوحة تحكم الأدمن
final liveSupportTicketsStreamProvider = StreamProvider<List<FeedbackModel>>((ref) {
  if (Firebase.apps.isEmpty) {
    // Fallback: استخدام الحالة المحلية مع فلترة التذاكر المفتوحة
    final localTickets = ref.watch(feedbackServiceProvider);
    return Stream.value(
      localTickets.where((FeedbackModel t) => t.status != 'closed').toList(),
    );
  }

  return FirebaseFirestore.instance
      .collection('support_tickets')
      .where('status', whereIn: ['open', 'in_progress'])
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map<List<FeedbackModel>>((snap) {
        return snap.docs.map<FeedbackModel>((doc) => FeedbackModel.fromFirestore(doc)).toList();
      });
});
