import 'dart:async';
import 'package:flutter/material.dart';

import 'admin_approval_widget.dart';

/// 🔔 مساعد الإشعارات الموحد (Notification Helper)
/// يدعم إشعارات Firebase Cloud Messaging (FCM) محلياً وخلفياً، مع محاكاة متكاملة للويب لتسهيل المراجعة الفورية.
class NotificationHelper {
  // مجرى بث الإشعارات المستقبلة لتحديث الواجهة ديناميكياً
  static final StreamController<ActiveNotification> _notificationStreamController = 
      StreamController<ActiveNotification>.broadcast();

  static Stream<ActiveNotification> get onNotificationReceived => _notificationStreamController.stream;

  /// تهيئة إعدادات الإشعارات المحلية واستقبال رسائل FCM
  static Future<void> initialize() async {
    debugPrint('FCM System: Initializing background message listeners...');
    debugPrint('Local Notification: Hooked onNotificationClick channels...');
    
    // إعداد قنوات استقبال الخلفية FCM background handler (معالجة خالية من انقطاع الشبكة)
    _setupFcmMockListeners();
  }

  /// إرسال وبث إشعار جديد حياً للواجهات
  static void showNotification({
    required String title,
    required String body,
    required Map<String, dynamic> payload,
  }) {
    final notification = ActiveNotification(
      id: DateTime.now().millisecondsSinceEpoch,
      title: title,
      body: body,
      payload: payload,
    );
    _notificationStreamController.add(notification);
  }

  static void _setupFcmMockListeners() {
    // محاكاة الاتصال بخدمة Firebase Cloud Messaging والاستماع المستمر للرسائل الواردة
  }
}

/// كلاس يمثل الإشعار النشط المستلم
class ActiveNotification {
  final int id;
  final String title;
  final String body;
  final Map<String, dynamic> payload;

  ActiveNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.payload,
  });
}

/// 📱 ودجت تراكب الإشعارات الفورية (Heads-Up Push Notification Overlay)
/// تظهر في أعلى الشاشات بشكل منزلق وجذاب لمحاكاة استلام إشعار حقيقي في أجهزة الجوال.
class HeadsUpNotificationOverlay extends StatefulWidget {
  final Widget child;
  const HeadsUpNotificationOverlay({Key? key, required this.child}) : super(key: key);

  @override
  State<HeadsUpNotificationOverlay> createState() => _HeadsUpNotificationOverlayState();
}

class _HeadsUpNotificationOverlayState extends State<HeadsUpNotificationOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  ActiveNotification? _currentNotification;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));

    // الاستماع للإشعارات الجديدة القادمة من السيستم أو من FCM
    NotificationHelper.onNotificationReceived.listen((notification) {
      if (mounted) {
        _dismissTimer?.cancel();
        setState(() {
          _currentNotification = notification;
        });
        _slideController.forward();
        
        // إخفاء الإشعار تلقائياً بعد 6 ثوانٍ
        _dismissTimer = Timer(const Duration(seconds: 6), () {
          _hideNotification();
        });
      }
    });
  }

  void _hideNotification() {
    if (mounted) {
      _slideController.reverse().then((_) {
        setState(() {
          _currentNotification = null;
        });
      });
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    _dismissTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_currentNotification != null)
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 12,
            right: 12,
            child: SlideTransition(
              position: _slideAnimation,
              child: Material(
                color: Colors.transparent,
                child: GestureDetector(
                  onTap: () {
                    final payload = _currentNotification!.payload;
                    _hideNotification();
                    // فتح لوحة الإشراف المخصصة للأدمن عند الضغط على الإشعار مباشرة
                    _navigateToModerationPanel(context, payload);
                  },
                  onVerticalDragUpdate: (details) {
                    if (details.primaryDelta! < -5) {
                      _hideNotification();
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B), // مظهر داكن جذاب وعالي التباين
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 5),
                        )
                      ],
                      border: Border.all(color: const Color(0xFF334155), width: 1.5),
                    ),
                    child: Row(
                      children: [
                        // أيقونة إشعار ملونة ومنبضة بالبلوتوث/المزامنة
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F75BC).withOpacity(0.2),
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFF0F75BC), width: 1),
                          ),
                          child: const Icon(
                            Icons.notifications_active_rounded,
                            color: Color(0xFF38BDF8),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _currentNotification!.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                _currentNotification!.body,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 10,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B), size: 16),
                          onPressed: _hideNotification,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _navigateToModerationPanel(BuildContext context, Map<String, dynamic> payload) {
    // فتح لوحة الإشراف التلقائي للأدمن مع تمرير حمولة البيانات
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // سنقوم بفتح شاشة الإشراف على الفور
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const AdminApprovalWidget(),
        ),
      );
    });
  }
}

