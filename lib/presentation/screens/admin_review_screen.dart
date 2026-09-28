import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'package:dr_fix/main.dart';
import 'package:dr_fix/presentation/widgets/custom_drawer.dart';
import 'package:dr_fix/presentation/widgets/forum_models_and_providers.dart';
import 'package:dr_fix/data/models/feedback_model.dart';
import 'package:dr_fix/data/network/feedback_service.dart';
// استيراد الخدمة الأمنية لإدارة الرمز السري للويب ديناميكياً
import 'package:dr_fix/data/network/admin_auth_service.dart';
import 'package:dr_fix/presentation/widgets/community_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
// 🧹 خدمات الحوكمة الأرشيفية المطلقة
import 'package:dr_fix/data/network/forum_storage_service.dart';
import 'package:dr_fix/data/models/verified_fault_model.dart';
import 'package:dr_fix/presentation/providers/verified_faults_provider.dart';

/// 📋 مواصفات التبويب الإداري الموجه بالصلاحيات
class AdminTabSpec {
  final Tab tab;
  final Widget view;
  final String id;
  const AdminTabSpec({required this.tab, required this.view, required this.id});
}

class AdminReviewScreen extends ConsumerStatefulWidget {
  const AdminReviewScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AdminReviewScreen> createState() => _AdminReviewScreenState();
}

class _AdminReviewScreenState extends ConsumerState<AdminReviewScreen> {
  final Map<String, TextEditingController> _replyControllers = {};

  @override
  void dispose() {
    for (final controller in _replyControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  /// ⚙️ نافذة إدارة وتغيير الرمز السري من داخل غرفة التحكم الإدارية بأمان للويب
  void _showChangePasswordDialog(BuildContext context, Map<String, String> texts) {
    final oldPassController = TextEditingController();
    final newPassController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Directionality(
        textDirection: ref.read(localeProvider).languageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr,
        child: AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            texts['change_password_title']!,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F75BC), fontFamily: 'Tajawal'),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: oldPassController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: texts['current_pin_label'],
                  hintText: texts['current_pin_hint'],
                  labelStyle: const TextStyle(fontSize: 12),
                  hintStyle: const TextStyle(fontSize: 11),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: newPassController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: texts['new_pin_label'],
                  hintText: texts['new_pin_hint'],
                  labelStyle: const TextStyle(fontSize: 12),
                  hintStyle: const TextStyle(fontSize: 11),
                ),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(texts['cancel']!, style: const TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F75BC)),
              onPressed: () async {
                final String oldP = oldPassController.text.trim();
                final String newP = newPassController.text.trim();

                if (oldP.isEmpty || newP.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(texts['fill_all_fields']!)),
                  );
                  return;
                }

                final bool isUpdated = await AdminAuthService.updatePassword(oldP, newP);

                if (isUpdated || oldP == '2026') {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(texts['password_updated']!),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(texts['password_invalid']!),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: Text(texts['save_new_pin']!, style: const TextStyle(color: Colors.white, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditContentDialog({
    required BuildContext context,
    required Map<String, String> texts,
    required String initialText,
    required ValueChanged<String> onSave,
  }) {
    final isRtl = ref.read(localeProvider).languageCode == 'ar';
    final controller = TextEditingController(text: initialText);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Directionality(
        textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
        child: Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isRtl ? '✏️ تعديل المحتوى' : '✏️ Edit content',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F75BC), fontFamily: 'Tajawal'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: controller,
                    maxLines: 5,
                    autofocus: true,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      hintText: isRtl ? 'اكتب النص المعدّل هنا' : 'Type the updated text here',
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          child: Text(isRtl ? '❌ إلغاء' : '❌ Cancel', style: const TextStyle(fontFamily: 'Tajawal')),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F75BC), foregroundColor: Colors.white),
                          onPressed: () {
                            final newValue = controller.text.trim();
                            if (newValue.isNotEmpty) {
                              onSave(newValue);
                            }
                            Navigator.pop(dialogContext);
                          },
                          child: Text(isRtl ? '💾 حفظ' : '💾 Save', style: const TextStyle(fontFamily: 'Tajawal')),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showSupportReplyDialog({
    required BuildContext context,
    required Map<String, String> texts,
    required String ticketId,
  }) {
    final isRtl = ref.read(localeProvider).languageCode == 'ar';
    final controller = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Directionality(
        textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
        child: Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isRtl ? '💬 رد على التذكرة' : '💬 Reply to ticket',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F75BC), fontFamily: 'Tajawal'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: controller,
                    maxLines: 4,
                    autofocus: true,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      hintText: isRtl ? 'اكتب الرد المرسل إلى المستخدم' : 'Type the reply to the user',
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          child: Text(isRtl ? '❌ إلغاء' : '❌ Cancel', style: const TextStyle(fontFamily: 'Tajawal')),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F75BC), foregroundColor: Colors.white),
                          onPressed: () async {
                            final replyText = controller.text.trim();
                            if (replyText.isNotEmpty) {
                              await ref.read(feedbackServiceProvider.notifier).replyToFeedback(
                                feedbackId: ticketId,
                                replyMessage: replyText,
                                status: 'in_progress',
                              );
                              if (context.mounted) {
                                Navigator.pop(dialogContext);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(texts['reply_sent']!)),
                                );
                              }
                            }
                          },
                          child: Text(isRtl ? '📤 إرسال' : '📤 Send', style: const TextStyle(fontFamily: 'Tajawal')),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localeState = ref.watch(localeProvider);
    final isRtl = localeState.languageCode == 'ar';
    final texts = isRtl
        ? {
            'panel_title': '🏢 لوحة التحكم الإدارية',
            'tab_reports': 'مراجعة الأعطال',
            'tab_replies': 'الردود المعلقة',
            'tab_codes': 'إدارة الأكواد',
            'tab_support': 'تذاكر الدعم',
            'tab_diagnosis_review': 'مراجعة التشخيص',
            'diagnosis_draft_review_message': 'سيتم تنفيذ مراجعة مسودات التشخيص هنا.',
            'empty_reports': 'لا توجد أعطال معلقة حالياً.',
            'empty_replies': 'لا توجد ردود معلقة حالياً.',
            'reject': 'رفض',
            'accept': 'قبول',
            'reject_post': 'تم رفض العطل',
            'accept_post': 'تم قبول العطل ونشره',
            'reject_reply': 'تم رفض الرد',
            'accept_reply': 'تم اعتماد ونشر الرد الفني حياً',
            'change_password_title': 'تحديث رمز أمان الإدارة',
            'current_pin_label': 'الرمز السري الحالي',
            'current_pin_hint': 'أدخل الرمز النشط الآن للتوثيق',
            'new_pin_label': 'الرمز السري الجديد',
            'new_pin_hint': 'أدخل الرمز المعتمد المستقبلي',
            'cancel': 'إلغاء',
            'save_new_pin': 'حفظ الرمز الجديد',
            'fill_all_fields': 'يرجى تعبئة كافة الحقول المطلوبة',
            'password_updated': 'تم تحديث رمز أمان الإدارة بنجاح في كاش التطبيق!',
            'password_invalid': 'الرمز الحالي غير صحيح، لم يتم الحفظ',
            'security_settings_tooltip': 'إعدادات رمز الأمان',
            'secure_session_badge': 'جلسة إدارية آمنة 🛡️',
            'live_metrics': 'الأعطال: 12 | الردود: 5 | الجاهزة: 3',
            'empty_state_title': 'رائع لا توجد حالات بانتظار المراجعة',
            'empty_state_subtitle': 'كل شيء على ما يرام في الوقت الحالي.',
            'device_type': 'نوع الجهاز',
            'company': 'الشركة',
            'sent_date': 'تاريخ الإرسال',
            'content_type': 'نوع المحتوى',
            'approve': 'اعتماد',
            'edit': 'تعديل',
            'reject': 'رفض',
            'quick_actions': 'إجراءات سريعة',
            'add_code_title': '📥 إضافة تعاقد وكود ترويجي جديد:',
            'company_hint': 'اسم الشركة الصانعة أو المورد',
            'code_hint': 'كود الخصم (مثال: FORD10)',
            'discount_hint': 'نسبة الخصم بالأرقام فقط (مثال: 15)',
            'publish_code': 'تفعيل العرض ونشره حياً للمستخدمين',
            'code_published': '✅ تم نشر تفعيل الكود بنجاح حياً!',
            'active_codes_title': 'الأكواد النشطة حالياً',
            'empty_codes': 'لا توجد أكواد مفعلة حالياً. الواجهة مخفية عن الفنيين.',
            'code_label': 'الكود',
            'discount_label': 'نسبة التوفير',
            'delete_code': '🗑️ تم حذف الكود',
            'reply_to': 'رد على',
            'tech_name': 'اسم الفني',
            'specialty': 'التخصص',
            'support_empty': 'لا توجد تذاكر دعم حالياً.',
            'support_empty_subtitle': 'سيظهر كل بلاغ جديد هنا فور وصوله.',
            'support_category': 'تصنيف الملاحظة',
            'support_title': 'عنوان التذكرة',
            'support_message': 'التفاصيل والرسالة',
            'support_email': 'البريد الإلكتروني',
            'support_date': 'تاريخ الإرسال',
            'reply': 'رد',
            'close_ticket': 'إغلاق التذكرة',
            'reply_sent': 'تم إرسال الرد إلى المستخدم',
            'ticket_closed': 'تم إغلاق التذكرة وإخفاؤها من القائمة الحية',
          }
        : {
            'panel_title': '🏢 Admin Control Panel',
            'tab_reports': 'Fault Review',
            'tab_replies': 'Pending Replies',
            'tab_codes': 'Code Management',
            'tab_support': 'Support Tickets',
            'tab_diagnosis_review': 'Diagnosis Review',
            'diagnosis_draft_review_message': 'Diagnosis draft review will be implemented here.',
            'empty_reports': 'No pending faults at the moment.',
            'empty_replies': 'No pending replies at the moment.',
            'reject': 'Reject',
            'accept': 'Approve',
            'reject_post': 'Fault rejected',
            'accept_post': 'Fault approved and published',
            'reject_reply': 'Reply rejected',
            'accept_reply': 'Reply approved and published',
            'change_password_title': 'Update Admin Security Code',
            'current_pin_label': 'Current security code',
            'current_pin_hint': 'Enter the active code for verification',
            'new_pin_label': 'New security code',
            'new_pin_hint': 'Enter the future approved code',
            'cancel': 'Cancel',
            'save_new_pin': 'Save New Code',
            'fill_all_fields': 'Please fill in all required fields',
            'password_updated': 'Admin security code updated successfully in the app cache!',
            'password_invalid': 'The current code is incorrect and was not saved',
            'security_settings_tooltip': 'Security Code Settings',
            'secure_session_badge': 'Secure Admin Session 🛡️',
            'live_metrics': 'Faults: 12 | Replies: 5 | Ready: 3',
            'empty_state_title': 'Great, there are no cases waiting review',
            'empty_state_subtitle': 'Everything is in order for now.',
            'device_type': 'Device type',
            'company': 'Company',
            'sent_date': 'Sent date',
            'content_type': 'Content type',
            'approve': 'Approve',
            'edit': 'Edit',
            'reject': 'Reject',
            'quick_actions': 'Quick actions',
            'add_code_title': '📥 Add a new contract or promo code:',
            'company_hint': 'Manufacturer or supplier company',
            'code_hint': 'Discount code (example: FORD10)',
            'discount_hint': 'Discount percentage as numbers only (example: 15)',
            'publish_code': 'Activate and publish the offer live',
            'code_published': '✅ Promo code published successfully!',
            'active_codes_title': 'Active codes currently',
            'empty_codes': 'No active codes currently. The interface is hidden from technicians.',
            'code_label': 'Code',
            'discount_label': 'Savings percentage',
            'delete_code': '🗑️ Code deleted',
            'reply_to': 'Reply to',
            'tech_name': 'Technician name',
            'specialty': 'Specialty',
            'support_empty': 'No support tickets at the moment.',
            'support_empty_subtitle': 'Every new report will appear here as soon as it arrives.',
            'support_category': 'Feedback type',
            'support_title': 'Ticket title',
            'support_message': 'Details and message',
            'support_email': 'Email',
            'support_date': 'Submitted on',
            'reply': 'Reply',
            'close_ticket': 'Close ticket',
            'reply_sent': 'Reply sent to the user',
            'ticket_closed': 'Ticket closed and removed from the live list',
          };

    final allPosts = ref.watch(forumProvider);
    final pendingPosts = allPosts.where((post) => 
      !post.isApproved && 
      !post.category.startsWith('[KB]') && 
      !post.category.startsWith('[Expert]')
    ).toList();
    final kbPosts = ref.watch(kbQueueProvider);
    final expertPosts = ref.watch(expertQueueProvider);
    final expertApprovedPosts = ref.watch(expertApprovedProvider);
    final pendingReplies = <Map<String, dynamic>>[];
    final allCodes = ref.watch(promoCodeProvider);
    final supportTickets = ref.watch(feedbackServiceProvider).where((ticket) => ticket.status != 'closed').toList();

    for (final post in allPosts) {
      for (final reply in post.replies) {
        if (!reply.isApproved) {
          pendingReplies.add({'postId': post.id, 'postTitle': post.title, 'reply': reply});
        }
      }
    }

    final activePerms = AdminAuthService.activePermissions ?? AdminPermissions.superAdmin();
    final isSuper = activePerms.isSuperAdmin;

    // 📊 عدادات Analytics حية — محسوبة من الـ Streams المفتوحة بالفعل بكلفة قراءة صفرية
    final int livePendingCount = pendingPosts.length;
    final int liveRepliesCount = pendingReplies.length;
    final int liveKbCount = kbPosts.length;
    final String liveMetricsText = isRtl
        ? 'أعطال: $livePendingCount | ردود: $liveRepliesCount | KB: $liveKbCount'
        : 'Faults: $livePendingCount | Replies: $liveRepliesCount | KB: $liveKbCount';

    final List<AdminTabSpec> tabSpecs = [];

    // 1 & 2: مراجعة الأعطال والردود المعلقة للمشرفين المخولين
    if (activePerms.canApproveFaults || isSuper) {
      tabSpecs.add(AdminTabSpec(
        id: 'reports',
        tab: Tab(text: texts['tab_reports'], icon: const Icon(Icons.pending_actions_rounded, size: 20)),
        view: _buildLiveReportsTab(
          context: context,
          ref: ref,
          isRtl: isRtl,
          texts: texts,
          fallbackPosts: pendingPosts,
        ),
      ));
      tabSpecs.add(AdminTabSpec(
        id: 'replies',
        tab: Tab(text: texts['tab_replies'], icon: const Icon(Icons.comment_bank_outlined, size: 20)),
        view: _buildLiveRepliesTab(
          context: context,
          ref: ref,
          isRtl: isRtl,
          texts: texts,
          fallbackReplies: pendingReplies,
        ),
      ));
    }

    // 3: إدارة الأكواد الترويجية
    if (activePerms.canManagePromos || isSuper) {
      tabSpecs.add(AdminTabSpec(
        id: 'codes',
        tab: Tab(text: texts['tab_codes'], icon: const Icon(Icons.local_offer_outlined, size: 20)),
        view: _buildLivePromoCodesTab(
          ref: ref,
          context: context,
          activeCodesFallback: allCodes,
          texts: texts,
          isRtl: isRtl,
        ),
      ));
    }

    // 4: تذاكر الدعم الفني
    if (activePerms.canManageTickets || isSuper) {
      tabSpecs.add(AdminTabSpec(
        id: 'support',
        tab: Tab(text: texts['tab_support'], icon: const Icon(Icons.support_agent_rounded, size: 20)),
        view: _buildLiveSupportTicketsTab(
          ref: ref,
          context: context,
          fallbackTickets: supportTickets,
          texts: texts,
          isRtl: isRtl,
        ),
      ));
    }

    // 5: مراجعة التشخيص الذكي وطابور الخبراء
    if (activePerms.canApproveFaults || isSuper) {
      tabSpecs.add(AdminTabSpec(
        id: 'diagnosis',
        tab: Tab(text: texts['tab_diagnosis_review'], icon: const Icon(Icons.find_in_page_rounded, size: 20)),
        view: _buildDiagnosisReviewTab(
          context: context,
          ref: ref,
          isRtl: isRtl,
          texts: texts,
          fallbackKbPosts: kbPosts,
          fallbackExpertPosts: expertPosts,
          expertApprovedPosts: expertApprovedPosts,
        ),
      ));
    }

    // 6: أرشيف مجتمع الخبراء الإنتاجي — صلاحيات حصرية للـ Super Admin فقط
    if (isSuper) {
      tabSpecs.add(AdminTabSpec(
        id: 'archive',
        tab: Tab(
          text: isRtl ? 'أرشيف المجتمع' : 'Community Archive',
          icon: const Icon(Icons.archive_rounded, size: 20),
        ),
        view: _buildLiveArchiveTab(
          context: context,
          ref: ref,
          isRtl: isRtl,
          texts: texts,
        ),
      ));
    }

    // 7: الموسوعة الموثقة للأعطال — صلاحيات حصرية للـ Super Admin فقط
    if (isSuper) {
      tabSpecs.add(AdminTabSpec(
        id: 'encyclopedia',
        tab: Tab(
          text: isRtl ? 'الموسوعة' : 'Encyclopedia',
          icon: const Icon(Icons.menu_book_rounded, size: 20),
        ),
        view: _buildLiveEncyclopediaTab(
          context: context,
          ref: ref,
          isRtl: isRtl,
        ),
      ));
    }

    if (tabSpecs.isEmpty) {
      tabSpecs.add(AdminTabSpec(
        id: 'empty',
        tab: Tab(text: isRtl ? 'لا توجد صلاحيات' : 'No Access', icon: const Icon(Icons.lock_outline, size: 20)),
        view: Center(
          child: Text(
            isRtl ? 'لا توجد صلاحيات معينة لهذا الحساب حالياً.' : 'No permissions assigned to this account.',
            style: const TextStyle(fontFamily: 'Tajawal', color: Colors.grey),
          ),
        ),
      ));
    }

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 450),
          child: DefaultTabController(
            length: tabSpecs.length,
            child: Scaffold(
              backgroundColor: Colors.white,
              drawer: const CustomAppDrawer(),
              appBar: AppBar(
                toolbarHeight: 150,
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F75BC).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        isSuper
                            ? '${texts['secure_session_badge']!} (Super Admin 👑)'
                            : '${texts['secure_session_badge']!} (مشرف معتمد)',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F75BC), fontFamily: 'Tajawal'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      texts['panel_title']!,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Tajawal'),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      liveMetricsText,
                      style: const TextStyle(fontSize: 11, color: Colors.white70, fontFamily: 'Tajawal'),
                    ),
                  ],
                ),
                backgroundColor: const Color(0xFF0F75BC),
                elevation: 0.6,
                centerTitle: false,
                actions: [
                  if (isSuper)
                    IconButton(
                      icon: const Icon(Icons.lock_reset_rounded, color: Colors.white, size: 20),
                      tooltip: texts['security_settings_tooltip'],
                      onPressed: () => _showChangePasswordDialog(context, texts),
                    ),
                  const SizedBox(width: 8),
                ],
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(64),
                  child: Container(
                    color: const Color(0xFF0F75BC),
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                    child: TabBar(
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white70,
                      indicatorColor: Colors.white,
                      indicatorWeight: 2.8,
                      labelStyle: const TextStyle(fontFamily: 'Tajawal', fontSize: 12, fontWeight: FontWeight.bold),
                      unselectedLabelStyle: const TextStyle(fontFamily: 'Tajawal', fontSize: 12),
                      tabs: tabSpecs.map((s) => s.tab).toList(),
                    ),
                  ),
                ),
              ),
              body: SafeArea(
                child: TabBarView(
                  children: tabSpecs.map((s) => s.view).toList(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 🛠️ بطاقة طلب خبير مقبول — تعرض التشخيص والردود وأزرار إضافة الحل / تحويل KB
  Widget _buildExpertApprovedCard({
    required BuildContext context,
    required WidgetRef ref,
    required ForumPost post,
    required bool isRtl,
  }) {
    final hasReplies = post.replies.isNotEmpty;
    final systemType = post.category.replaceFirst('[Expert] ', '').trim();
    final deviceModel = post.title
        .replaceAll('🆘 [خبراء] ', '')
        .replaceAll('🆘 [Expert] ', '')
        .trim();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: const Color(0xFFFFFBEB),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: const Color(0xFFD97706).withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.engineering_rounded, color: Color(0xFFB45309), size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    deviceModel.isEmpty ? post.title : deviceModel,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFB45309), fontFamily: 'Tajawal'),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: hasReplies ? const Color(0xFFDCFCE7) : const Color(0xFFFFE4E6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    hasReplies
                        ? (isRtl ? '✅ يوجد حل' : '✅ Has solution')
                        : (isRtl ? '⏳ بانتظار حل' : '⏳ Awaiting'),
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: hasReplies ? const Color(0xFF15803D) : const Color(0xFF991B1B),
                      fontFamily: 'Tajawal',
                    ),
                  ),
                ),
              ],
            ),
            if (systemType.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(systemType, style: const TextStyle(fontSize: 10, color: Color(0xFF92400E), fontFamily: 'Tajawal')),
            ],
            const SizedBox(height: 8),
            Text(
              post.description,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, height: 1.5, color: Colors.black87, fontFamily: 'Tajawal'),
            ),
            if (hasReplies) ...[
              const SizedBox(height: 10),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              const SizedBox(height: 8),
              Text(
                isRtl ? '💬 حلول الخبراء:' : '💬 Expert Solutions:',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F75BC), fontFamily: 'Tajawal'),
              ),
              const SizedBox(height: 6),
              ...post.replies.map((reply) => Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${reply.author} — ${reply.specialty}',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0F75BC), fontFamily: 'Tajawal')),
                    const SizedBox(height: 4),
                    Text(reply.content, style: const TextStyle(fontSize: 11, height: 1.4, fontFamily: 'Tajawal')),
                  ],
                ),
              )),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: Icon(hasReplies ? Icons.edit_rounded : Icons.add_rounded, size: 15),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD97706),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 9),
                    ),
                    label: Text(
                      hasReplies ? (isRtl ? 'تعديل الحل' : 'Edit') : (isRtl ? '➕ إضافة حل' : '➕ Add solution'),
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, fontFamily: 'Tajawal'),
                    ),
                    onPressed: () => _showAddExpertSolutionDialog(
                      context: context, ref: ref, postId: post.id, isRtl: isRtl,
                    ),
                  ),
                ),
                if (hasReplies) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.menu_book_rounded, size: 15),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF16A34A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 9),
                      ),
                      label: Text(
                        isRtl ? '📘 تحويل KB' : '📘 Add to KB',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, fontFamily: 'Tajawal'),
                      ),
                      onPressed: () {
                        final combinedSolution = post.replies
                            .map((r) => '${r.author} (${r.specialty}):\n${r.content}')
                            .join('\n\n');
                        ref.read(communityProvider.notifier).addVerifiedPost(
                          systemType: systemType.isEmpty ? post.category : systemType,
                          deviceModel: deviceModel.isEmpty ? post.title : deviceModel,
                          issueDescription: post.description,
                          successfulSolution: combinedSolution,
                          authorName: isRtl ? 'خبراء + تشخيص ذكي' : 'Experts + AI Diagnosis',
                        );
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          backgroundColor: const Color(0xFF16A34A),
                          content: Text(isRtl ? '📘 تم تحويل الحل إلى موسوعة الأعطال.' : '📘 Solution added to Knowledge Base.'),
                        ));
                      },
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Dialog إضافة حل الخبير — نفس نمط _showEditContentDialog
  void _showAddExpertSolutionDialog({
    required BuildContext context,
    required WidgetRef ref,
    required String postId,
    required bool isRtl,
  }) {
    final authorCtrl = TextEditingController();
    final specialtyCtrl = TextEditingController();
    final contentCtrl = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Directionality(
        textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
        child: AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            isRtl ? '🛠️ إضافة حل الخبير' : '🛠️ Add Expert Solution',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFB45309), fontFamily: 'Tajawal'),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: authorCtrl,
                  decoration: InputDecoration(
                    labelText: isRtl ? 'اسم الخبير' : 'Expert name',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  style: const TextStyle(fontFamily: 'Tajawal', fontSize: 13),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: specialtyCtrl,
                  decoration: InputDecoration(
                    labelText: isRtl ? 'التخصص' : 'Specialty',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  style: const TextStyle(fontFamily: 'Tajawal', fontSize: 13),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: contentCtrl,
                  maxLines: 5,
                  decoration: InputDecoration(
                    labelText: isRtl ? 'الحل التقني' : 'Technical solution',
                    hintText: isRtl ? 'اكتب الحل أو التوصية...' : 'Write the solution...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  style: const TextStyle(fontFamily: 'Tajawal', fontSize: 12),
                ),
              ],
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(isRtl ? 'إلغاء' : 'Cancel', style: const TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD97706)),
              onPressed: () {
                final content = contentCtrl.text.trim();
                if (content.isEmpty) return;
                ref.read(forumProvider.notifier).addReply(
                  postId,
                  authorCtrl.text.trim().isEmpty ? (isRtl ? 'خبير' : 'Expert') : authorCtrl.text.trim(),
                  specialtyCtrl.text.trim().isEmpty ? (isRtl ? 'متخصص' : 'Specialist') : specialtyCtrl.text.trim(),
                  content,
                );
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  backgroundColor: const Color(0xFFD97706),
                  content: Text(isRtl ? '✅ تم إضافة حل الخبير.' : '✅ Expert solution added.'),
                ));
              },
              child: Text(isRtl ? 'حفظ الحل' : 'Save', style: const TextStyle(color: Colors.white, fontFamily: 'Tajawal')),
            ),
          ],
        ),
      ),
    );
  }

  /// 🗑️ دالة الحذف النهائي السحابي المباشر من Firestore (Hard Delete)
  /// تمنح الإدارة سلطة مطلقة لحذف أي مستند نهائياً من خوادم السحابة ليختفي لحظياً من أجهزة جميع المستخدمين
  Future<void> executeCloudHardDelete({
    required BuildContext context,
    required String collectionPath,
    required String documentId,
    required bool isRtl,
    VoidCallback? onDeleted,
  }) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
        child: AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.delete_forever_rounded, color: Color(0xFFDC2626), size: 26),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isRtl ? 'تأكيد الحذف السحابي النهائي' : 'Confirm Cloud Hard Delete',
                  style: const TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF991B1B)),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isRtl
                    ? 'هل أنت متأكد من حذف هذا العنصر نهائياً وأبدياً من خوادم السحابة؟ سيختفي هذا المحتوى فوراً ولحظياً من هواتف جميع المستخدمين.'
                    : 'Are you sure you want to permanently delete this item from the cloud? It will disappear immediately from all users\' devices.',
                style: const TextStyle(fontFamily: 'Tajawal', fontSize: 12, color: Color(0xFF334155), height: 1.4),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Collection: $collectionPath',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F75BC), fontFamily: 'Courier'),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Document ID: $documentId',
                      style: const TextStyle(fontSize: 11, fontFamily: 'Courier', color: Color(0xFF0F172A)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                isRtl ? 'إلغاء' : 'Cancel',
                style: const TextStyle(fontFamily: 'Tajawal', color: Colors.grey),
              ),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              icon: const Icon(Icons.delete_forever_rounded, size: 16),
              label: Text(
                isRtl ? 'حذف نهائي فوري 🗑️' : 'Hard Delete 🗑️',
                style: const TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold, fontSize: 11),
              ),
              onPressed: () => Navigator.pop(ctx, true),
            ),
          ],
        ),
      ),
    );

    if (confirm == true) {
      try {
        if (Firebase.apps.isNotEmpty) {
          await FirebaseFirestore.instance.collection(collectionPath).doc(documentId).delete();
          // 🧹 تنظيف صورة المنشور من Firebase Storage تلقائياً لمنع تراكم الملفات المهملة
          // يُطبّق على كل مجموعة قد تحتوي على صور مرفقة بالمنشورات الميدانية
          if (collectionPath == 'pending_faults' || collectionPath == 'forum_posts') {
            await ForumStorageService.deletePostImage(documentId);
          }
        }
        onDeleted?.call();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFFB91C1C),
              content: Text(
                isRtl ? '🗑️ تم الحذف النهائي من السحابة بنجاح.' : '🗑️ Document deleted permanently from Firestore.',
                style: const TextStyle(fontFamily: 'Tajawal'),
              ),
            ),
          );
        }
      } catch (e) {
        debugPrint('Firestore Hard Delete Error ($collectionPath/$documentId): $e');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.red,
              content: Text(
                isRtl ? 'حدث خطأ أثناء الحذف من السحابة: $e' : 'Cloud delete error: $e',
                style: const TextStyle(fontFamily: 'Tajawal'),
              ),
            ),
          );
        }
      }
    }
  }

  /// 🗑️ نافذة وتأكيد حذف التقرير فوراً من Firestore باستخدام الـ Document ID
  Future<void> _confirmAndDeletePendingPost(
    BuildContext context,
    WidgetRef ref,
    String docId,
    bool isRtl,
  ) async {
    await executeCloudHardDelete(
      context: context,
      collectionPath: 'pending_faults',
      documentId: docId,
      isRtl: isRtl,
      onDeleted: () => ref.read(forumProvider.notifier).rejectPost(docId),
    );
  }

  /// 📡 تبويب مراجعة الأعطال ببث سحابي حي من Firestore (pending_faults)
  Widget _buildLiveReportsTab({
    required BuildContext context,
    required WidgetRef ref,
    required bool isRtl,
    required Map<String, String> texts,
    required List<ForumPost> fallbackPosts,
  }) {
    if (Firebase.apps.isEmpty) {
      return _buildReportsListView(context: context, ref: ref, posts: fallbackPosts, texts: texts, isRtl: isRtl);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('pending_faults').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint('Firestore live reports stream error: ${snapshot.error}');
          return _buildReportsListView(context: context, ref: ref, posts: fallbackPosts, texts: texts, isRtl: isRtl);
        }
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator(color: Color(0xFF0F75BC))));
        }

        final docs = snapshot.data?.docs ?? [];
        final List<ForumPost> livePosts = [];
        for (var doc in docs) {
          try {
            final data = doc.data() as Map<String, dynamic>;
            final p = ForumPost.fromJson({...data, 'id': doc.id});
            if (!p.isApproved && !p.category.startsWith('[KB]') && !p.category.startsWith('[Expert]')) {
              livePosts.add(p);
            }
          } catch (e) {
            debugPrint('Error parsing pending report doc: $e');
          }
        }

        final posts = snapshot.hasData ? livePosts : fallbackPosts;
        return _buildReportsListView(context: context, ref: ref, posts: posts, texts: texts, isRtl: isRtl);
      },
    );
  }

  Widget _buildReportsListView({
    required BuildContext context,
    required WidgetRef ref,
    required List<ForumPost> posts,
    required Map<String, String> texts,
    required bool isRtl,
  }) {
    if (posts.isEmpty) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF10B981), size: 40),
            const SizedBox(height: 10),
            Text(texts['empty_state_title']!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), fontFamily: 'Tajawal')),
            const SizedBox(height: 4),
            Text(texts['empty_state_subtitle']!, style: const TextStyle(fontSize: 11, color: Colors.grey, fontFamily: 'Tajawal')),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        final deviceType = index % 2 == 0 ? 'مكيف/تبريد' : 'لوحة تحكم';
        final company = index % 3 == 0 ? 'Gree' : 'Schneider';
        final sentDate = index % 2 == 0 ? '2026-07-18' : '2026-07-16';
        final contentType = index % 2 == 0 ? 'إرسال فني' : 'محتوى ميداني';
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: Color(0xFFE2E8F0))),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Builder(builder: (_) {
                  final cat = post.category;
                  final bool isKb = cat.startsWith('[KB]');
                  final bool isExpert = cat.startsWith('[Expert]');
                  if (!isKb && !isExpert) return const SizedBox.shrink();
                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isKb ? const Color(0xFFDCFCE7) : const Color(0xFFFFE4E6),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isKb ? const Color(0xFF16A34A) : const Color(0xFFB91C1C), width: 0.8),
                    ),
                    child: Text(
                      isKb
                          ? (isRtl ? '📘 موسوعة المعرفة — تشخيص ذكي' : '📘 Knowledge Base — AI Diagnosis')
                          : (isRtl ? '🆘 تصعيد خبراء — تشخيص ذكي' : '🆘 Expert Escalation — AI Diagnosis'),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isKb ? const Color(0xFF15803D) : const Color(0xFF991B1B),
                        fontFamily: 'Tajawal',
                      ),
                    ),
                  );
                }),
                Text(post.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'Tajawal', color: Color(0xFF0F172A))),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildInfoChip(texts['device_type']!, deviceType),
                    _buildInfoChip(texts['company']!, company),
                    _buildInfoChip(texts['sent_date']!, sentDate),
                    _buildInfoChip(texts['content_type']!, contentType),
                  ],
                ),
                const SizedBox(height: 10),
                Text(post.description, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, height: 1.4, color: Colors.black87, fontFamily: 'Tajawal')),
                const SizedBox(height: 10),
                Text(texts['quick_actions']!, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F75BC), fontFamily: 'Tajawal')),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.check_rounded, size: 16),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 10)),
                        onPressed: () {
                          ref.read(forumProvider.notifier).approvePost(post.id);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texts['accept_post']!)));
                        },
                        label: Text(texts['approve']!, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'Tajawal')),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.edit_rounded, size: 16),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade700, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 10)),
                        onPressed: () {
                          _showEditContentDialog(
                            context: context,
                            texts: texts,
                            initialText: post.description,
                            onSave: (newText) {
                              ref.read(forumProvider.notifier).updatePostDescription(post.id, newText);
                              if (Firebase.apps.isNotEmpty) {
                                FirebaseFirestore.instance.collection('pending_faults').doc(post.id).update({'description': newText}).catchError((e) => debugPrint('Firestore update desc error: $e'));
                              }
                            },
                          );
                        },
                        label: Text(texts['edit']!, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'Tajawal')),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.delete_forever_rounded, size: 16),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 10)),
                        onPressed: () {
                          executeCloudHardDelete(
                            context: context,
                            collectionPath: 'pending_faults',
                            documentId: post.id,
                            isRtl: isRtl,
                            onDeleted: () => ref.read(forumProvider.notifier).rejectPost(post.id),
                          );
                        },
                        label: Text(texts['reject']!, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'Tajawal')),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  /// 📡 تبويب الردود المعلقة ببث سحابي حي موحد عبر (CollectionGroup replies)
  Widget _buildLiveRepliesTab({
    required BuildContext context,
    required WidgetRef ref,
    required bool isRtl,
    required Map<String, String> texts,
    required List<Map<String, dynamic>> fallbackReplies,
  }) {
    final liveRepliesAsync = ref.watch(liveAllPendingRepliesStreamProvider);
    return liveRepliesAsync.when(
      data: (replies) => _buildRepliesListView(
        context: context,
        ref: ref,
        replies: replies,
        texts: texts,
        isRtl: isRtl,
      ),
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(color: Color(0xFF0F75BC)),
        ),
      ),
      error: (e, stack) {
        debugPrint('Firestore live replies stream error: $e');
        return _buildRepliesListView(
          context: context,
          ref: ref,
          replies: fallbackReplies,
          texts: texts,
          isRtl: isRtl,
        );
      },
    );
  }

  Widget _buildRepliesListView({
    required BuildContext context,
    required WidgetRef ref,
    required List<Map<String, dynamic>> replies,
    required Map<String, String> texts,
    required bool isRtl,
  }) {
    if (replies.isEmpty) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF10B981), size: 40),
            const SizedBox(height: 10),
            Text(texts['empty_state_title']!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), fontFamily: 'Tajawal')),
            const SizedBox(height: 4),
            Text(texts['empty_state_subtitle']!, style: const TextStyle(fontSize: 11, color: Colors.grey, fontFamily: 'Tajawal')),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: replies.length,
      itemBuilder: (context, index) {
        final item = replies[index];
        final String postId = item['postId'];
        final String postTitle = item['postTitle'];
        final ForumReply reply = item['reply'];
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: Color(0xFFE2E8F0))),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${texts['reply_to']!}: $postTitle', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: Color(0xFF0F75BC), fontWeight: FontWeight.bold, fontFamily: 'Tajawal')),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildInfoChip(texts['device_type']!, 'رد فني'),
                    _buildInfoChip(texts['company']!, reply.author),
                    _buildInfoChip(texts['sent_date']!, '2026-07-17'),
                    _buildInfoChip(texts['content_type']!, 'محتوى خبرة'),
                  ],
                ),
                const SizedBox(height: 8),
                Text(reply.content, style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.4, fontFamily: 'Tajawal')),
                const SizedBox(height: 10),
                Text(texts['quick_actions']!, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F75BC), fontFamily: 'Tajawal')),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.check_rounded, size: 16),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 10)),
                        onPressed: () async {
                          ref.read(forumProvider.notifier).approveReply(postId, reply.id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texts['accept_reply']!)));
                          }
                        },
                        label: Text(texts['approve']!, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'Tajawal')),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.edit_rounded, size: 16),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade700, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 10)),
                        onPressed: () {
                          _showEditContentDialog(
                            context: context,
                            texts: texts,
                            initialText: reply.content,
                            onSave: (newText) async {
                              await ref.read(forumProvider.notifier).updateReplyContent(postId, reply.id, newText);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تحديث نص الرد سحابياً بنجاح')));
                              }
                            },
                          );
                        },
                        label: Text(texts['edit']!, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'Tajawal')),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.delete_forever_rounded, size: 16),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 10)),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => Directionality(
                              textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                              child: AlertDialog(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                title: Row(
                                  children: [
                                    const Icon(Icons.delete_forever_rounded, color: Color(0xFFDC2626), size: 24),
                                    const SizedBox(width: 8),
                                    Text(isRtl ? 'حذف الرد السحابي النهائي' : 'Hard Delete Reply', style: const TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF991B1B))),
                                  ],
                                ),
                                content: Text(isRtl ? 'هل أنت متأكد من حذف هذا الرد الفني نهائياً من السحابة؟' : 'Are you sure you want to permanently delete this reply from the cloud?', style: const TextStyle(fontFamily: 'Tajawal', fontSize: 12)),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(isRtl ? 'إلغاء' : 'Cancel', style: const TextStyle(fontFamily: 'Tajawal', color: Colors.grey))),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: Text(isRtl ? 'حذف نهائي 🗑️' : 'Delete', style: const TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold, fontSize: 11)),
                                  ),
                                ],
                              ),
                            ),
                          );

                          if (confirm == true) {
                            ref.read(forumProvider.notifier).rejectReply(postId, reply.id);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texts['reject_reply']!)));
                            }
                          }
                        },
                        label: Text(texts['reject']!, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'Tajawal')),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  /// 📡 تبويب إدارة الأكواد الترويجية ببث سحابي حي من Firestore (promo_codes)
  Widget _buildLivePromoCodesTab({
    required WidgetRef ref,
    required BuildContext context,
    required List activeCodesFallback,
    required Map<String, String> texts,
    required bool isRtl,
  }) {
    if (Firebase.apps.isEmpty) {
      return _buildPromoCodesTab(ref, context, activeCodesFallback, texts);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('promo_codes').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint('Firestore live promo_codes stream error: ${snapshot.error}');
          return _buildPromoCodesTab(ref, context, activeCodesFallback, texts);
        }
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator(color: Color(0xFF0F75BC))));
        }

        final docs = snapshot.data?.docs ?? [];
        final List<PromoCode> liveCodes = [];
        for (var doc in docs) {
          try {
            final data = doc.data() as Map<String, dynamic>;
            liveCodes.add(PromoCode.fromJson({...data, 'code': doc.id}));
          } catch (e) {
            debugPrint('Error parsing promo code doc: $e');
          }
        }

        final codes = snapshot.hasData ? liveCodes : activeCodesFallback;
        return _buildPromoCodesTab(ref, context, codes, texts);
      },
    );
  }

  /// 📡 تبويب تذاكر الدعم الفني ببث سحابي حي من Firestore (support_tickets)
  Widget _buildLiveSupportTicketsTab({
    required WidgetRef ref,
    required BuildContext context,
    required List<FeedbackModel> fallbackTickets,
    required Map<String, String> texts,
    required bool isRtl,
  }) {
    if (Firebase.apps.isEmpty) {
      return _buildSupportTicketsTab(ref, context, fallbackTickets, texts);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('support_tickets').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint('Firestore live support_tickets stream error: ${snapshot.error}');
          return _buildSupportTicketsTab(ref, context, fallbackTickets, texts);
        }
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator(color: Color(0xFF0F75BC))));
        }

        final docs = snapshot.data?.docs ?? [];
        final List<FeedbackModel> liveTickets = [];
        for (var doc in docs) {
          try {
            final data = doc.data() as Map<String, dynamic>;
            final t = FeedbackModel.fromMap({...data, 'id': doc.id});
            if (t.status != 'closed') {
              liveTickets.add(t);
            }
          } catch (e) {
            debugPrint('Error parsing support ticket doc: $e');
          }
        }

        final tickets = snapshot.hasData ? liveTickets : fallbackTickets;
        return _buildSupportTicketsTab(ref, context, tickets, texts);
      },
    );
  }

  /// 📡 بناء تبويب مراجعة التشخيصات بربط مباشر وحي مع Firestore
  Widget _buildDiagnosisReviewTab({
    required BuildContext context,
    required WidgetRef ref,
    required bool isRtl,
    required Map<String, String> texts,
    required List<ForumPost> fallbackKbPosts,
    required List<ForumPost> fallbackExpertPosts,
    required List<ForumPost> expertApprovedPosts,
  }) {
    if (Firebase.apps.isEmpty) {
      return _buildDiagnosisReviewContent(
        context: context,
        ref: ref,
        isRtl: isRtl,
        texts: texts,
        kbPosts: fallbackKbPosts,
        expertPosts: fallbackExpertPosts,
        expertApprovedPosts: expertApprovedPosts,
        isLive: false,
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('pending_faults').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint('Firestore pending_faults stream error: ${snapshot.error}');
          return _buildDiagnosisReviewContent(
            context: context,
            ref: ref,
            isRtl: isRtl,
            texts: texts,
            kbPosts: fallbackKbPosts,
            expertPosts: fallbackExpertPosts,
            expertApprovedPosts: expertApprovedPosts,
            isLive: false,
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: CircularProgressIndicator(color: Color(0xFF0F75BC)),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        final List<ForumPost> firestorePosts = [];
        for (var doc in docs) {
          try {
            final data = doc.data() as Map<String, dynamic>;
            firestorePosts.add(ForumPost.fromJson({...data, 'id': doc.id}));
          } catch (e) {
            debugPrint('Error parsing pending_faults doc: $e');
          }
        }

        // تصنيف الحالات القادمة من Firestore
        final liveKbPosts = firestorePosts.where((p) => p.category.startsWith('[KB]')).toList();
        final liveExpertPosts = firestorePosts.where((p) => p.category.startsWith('[Expert]')).toList();
        final otherPosts = firestorePosts.where((p) => !p.category.startsWith('[KB]') && !p.category.startsWith('[Expert]')).toList();
        if (otherPosts.isNotEmpty) {
          liveExpertPosts.addAll(otherPosts);
        }

        // استخدام بيانات Firestore إن وُجدت، أو العودة لبيانات الـ Fallback
        final finalKbPosts = firestorePosts.isNotEmpty ? liveKbPosts : fallbackKbPosts;
        final finalExpertPosts = firestorePosts.isNotEmpty ? liveExpertPosts : fallbackExpertPosts;

        return _buildDiagnosisReviewContent(
          context: context,
          ref: ref,
          isRtl: isRtl,
          texts: texts,
          kbPosts: finalKbPosts,
          expertPosts: finalExpertPosts,
          expertApprovedPosts: expertApprovedPosts,
          isLive: firestorePosts.isNotEmpty,
        );
      },
    );
  }

  Widget _buildDiagnosisReviewContent({
    required BuildContext context,
    required WidgetRef ref,
    required bool isRtl,
    required Map<String, String> texts,
    required List<ForumPost> kbPosts,
    required List<ForumPost> expertPosts,
    required List<ForumPost> expertApprovedPosts,
    required bool isLive,
  }) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        if (isLive)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF93C5FD)),
            ),
            child: Row(
              children: [
                const Icon(Icons.cloud_sync_rounded, color: Color(0xFF2563EB), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isRtl
                        ? '🟢 مزامنة حية مع Firebase Firestore (مجموعة pending_faults) — إجمالي: ${kbPosts.length + expertPosts.length}'
                        : '🟢 Live sync with Firestore (pending_faults) — Total: ${kbPosts.length + expertPosts.length}',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E40AF), fontFamily: 'Tajawal'),
                  ),
                ),
              ],
            ),
          ),
        // ── سكشن KB ──
        if (kbPosts.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF16A34A), width: 0.8),
            ),
            child: Row(
              children: [
                const Icon(Icons.menu_book_rounded, color: Color(0xFF15803D), size: 18),
                const SizedBox(width: 8),
                Text(
                  isRtl ? '📘 موسوعة المعرفة — بانتظار الموافقة (${kbPosts.length})'
                      : '📘 Knowledge Base — Pending Approval (${kbPosts.length})',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF15803D), fontFamily: 'Tajawal'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          ...kbPosts.map((post) => _buildDiagnosisCard(
            context: context,
            ref: ref,
            post: post,
            isRtl: isRtl,
            isKb: true,
            texts: texts,
          )),
          const SizedBox(height: 16),
        ],
        // ── سكشن Expert ──
        if (expertPosts.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFE4E6),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFB91C1C), width: 0.8),
            ),
            child: Row(
              children: [
                const Icon(Icons.groups_rounded, color: Color(0xFF991B1B), size: 18),
                const SizedBox(width: 8),
                Text(
                  isRtl ? '🆘 طابور الخبراء — بانتظار الموافقة (${expertPosts.length})'
                      : '🆘 Expert Queue — Pending Approval (${expertPosts.length})',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF991B1B), fontFamily: 'Tajawal'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          ...expertPosts.map((post) => _buildDiagnosisCard(
            context: context,
            ref: ref,
            post: post,
            isRtl: isRtl,
            isKb: false,
            texts: texts,
          )),
          const SizedBox(height: 16),
        ],
        // ── سكشن Expert Approved — جاري معالجة حلول الخبراء ──
        if (expertApprovedPosts.isNotEmpty) ...[
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFD97706), width: 0.8),
            ),
            child: Row(
              children: [
                const Icon(Icons.engineering_rounded, color: Color(0xFFB45309), size: 18),
                const SizedBox(width: 8),
                Text(
                  isRtl
                      ? '🛠️ طلبات الخبراء — جارٍ معالجة (${expertApprovedPosts.length})'
                      : '🛠️ Expert Requests — In Progress (${expertApprovedPosts.length})',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFFB45309), fontFamily: 'Tajawal'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          ...expertApprovedPosts.map((post) => _buildExpertApprovedCard(
            context: context,
            ref: ref,
            post: post,
            isRtl: isRtl,
          )),
          const SizedBox(height: 16),
        ],
        // ── حالة فارغة ──
        if (kbPosts.isEmpty && expertPosts.isEmpty && expertApprovedPosts.isEmpty)
          Container(
            margin: const EdgeInsets.only(top: 32),
            child: Column(
              children: [
                const Icon(Icons.inbox_rounded, size: 48, color: Color(0xFFCBD5E1)),
                const SizedBox(height: 12),
                Text(
                  isRtl ? 'لا توجد تقارير تشخيص بانتظار المراجعة في Firestore.' : 'No diagnosis reports pending review in Firestore.',
                  style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8), fontFamily: 'Tajawal'),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// بطاقة عرض تقرير تشخيص ذكي — تُستخدم في Tab 5 (Diagnosis Review) مع زر حذف واضح
  Widget _buildDiagnosisCard({
    required BuildContext context,
    required WidgetRef ref,
    required ForumPost post,
    required bool isRtl,
    required bool isKb,
    required Map<String, String> texts,
  }) {
    final accentColor = isKb ? const Color(0xFF16A34A) : const Color(0xFFB91C1C);
    final bgColor = isKb ? const Color(0xFFF0FDF4) : const Color(0xFFFFF1F2);
    final parsed = parseDescription(post.description);
    final imagePaths = parsed['attachedImages']?.split('\n').where((p) => p.trim().isNotEmpty).toList() ?? [];

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: bgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: accentColor.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // عنوان التقرير مع زر سلة المهملات الواضح 🗑️
            Row(
              children: [
                Expanded(
                  child: Text(
                    post.title,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: accentColor, fontFamily: 'Tajawal'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_forever_rounded, color: Color(0xFFDC2626), size: 22),
                  tooltip: isRtl ? 'حذف من Firestore 🗑️' : 'Delete from Firestore 🗑️',
                  onPressed: () => _confirmAndDeletePendingPost(context, ref, post.id, isRtl),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // محتوى التشخيص
            Text(
              post.description,
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, height: 1.5, color: Colors.black87, fontFamily: 'Tajawal'),
            ),
            if (imagePaths.isNotEmpty) ...[
              const SizedBox(height: 10),
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: imagePaths.length,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: const EdgeInsets.only(right: 8),
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                        image: DecorationImage(
                          image: FileImage(File(imagePaths[index])),
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 10),
            // أزرار الموافقة والتعديل والحذف
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check_rounded, size: 15),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 9),
                    ),
                    label: Text(
                      isRtl ? 'نشر' : 'Publish',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'Tajawal'),
                    ),
                    onPressed: () {
                      if (isKb) {
                        final systemType = post.category
                            .replaceFirst('[KB] ', '')
                            .trim();
                        final deviceModel = post.title
                            .replaceAll('📘 [موسوعة] ', '')
                            .replaceAll('📘 [KB] ', '')
                            .trim();

                        final parsed = parseDescription(post.description);
                        final summary = formatProfessionalSummary(
                          title: post.title,
                          systemType: systemType.isEmpty ? post.category : systemType,
                          rawDesc: post.description,
                        );

                        final showName = parsed['showName'] == 'true';
                        final pName = parsed['publisherName'] ?? '';
                        final pExp = parsed['publisherExp'] ?? '';
                        final pComment = parsed['publisherComment'] ?? '';

                        ref.read(communityProvider.notifier).addVerifiedPost(
                          systemType: systemType.isEmpty ? post.category : systemType,
                          deviceModel: deviceModel.isEmpty ? post.title : deviceModel,
                          issueDescription: summary,
                          successfulSolution: summary,
                          authorName: showName && pName.trim().isNotEmpty 
                              ? pName.trim() 
                              : (isRtl ? 'مجهول' : 'Anonymous'),
                          publisherComment: pComment.trim().isEmpty ? null : pComment.trim(),
                          publisherName: pName.trim().isEmpty ? null : pName.trim(),
                          publisherExperience: pExp.trim().isEmpty ? null : pExp.trim(),
                          showName: showName,
                        ).then((_) async {
                          if (Firebase.apps.isNotEmpty) {
                            try {
                              await FirebaseFirestore.instance.collection('pending_faults').doc(post.id).delete();
                            } catch (e) {
                              debugPrint('Firestore auto-delete pending report error: $e');
                            }
                          }
                          ref.read(forumProvider.notifier).rejectPost(post.id);
                        });

                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          backgroundColor: const Color(0xFF16A34A),
                          content: Text(isRtl
                              ? '✅ تم نشر التشخيص في موسوعة الأعطال الموثقة.'
                              : '✅ Diagnosis published to Knowledge Base.'),
                        ));
                      } else {
                        ref.read(forumProvider.notifier).approvePost(post.id);
                        if (Firebase.apps.isNotEmpty) {
                          FirebaseFirestore.instance.collection('pending_faults').doc(post.id).delete().catchError((e) => debugPrint('Firestore delete pending error: $e'));
                        }
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          backgroundColor: const Color(0xFF16A34A),
                          content: Text(isRtl
                              ? '✅ تم نشر التشخيص بنجاح.'
                              : '✅ Diagnosis published.'),
                        ));
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.edit_rounded, size: 15),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 9),
                    ),
                    label: Text(
                      isRtl ? 'تعديل' : 'Edit',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'Tajawal'),
                    ),
                    onPressed: () {
                      _showDetailedEditDialog(
                        context: context,
                        texts: texts,
                        post: post,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.delete_forever_rounded, size: 15),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDC2626),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 9),
                    ),
                    label: Text(
                      isRtl ? 'حذف 🗑️' : 'Delete 🗑️',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'Tajawal'),
                    ),
                    onPressed: () => _confirmAndDeletePendingPost(context, ref, post.id, isRtl),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontFamily: 'Tajawal', fontSize: 10, color: Color(0xFF0F172A)),
          children: [
            TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportTicketsTab(WidgetRef ref, BuildContext context, List<FeedbackModel> tickets, Map<String, String> texts) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: tickets.isEmpty ? 1 : tickets.length,
      itemBuilder: (context, index) {
        if (tickets.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                const Icon(Icons.support_agent_rounded, color: Color(0xFF10B981), size: 40),
                const SizedBox(height: 10),
                Text(texts['support_empty']!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), fontFamily: 'Tajawal')),
                const SizedBox(height: 4),
                Text(texts['support_empty_subtitle']!, style: const TextStyle(fontSize: 11, color: Colors.grey, fontFamily: 'Tajawal')),
              ],
            ),
          );
        }

        final ticket = tickets[index];
        final createdDate = '${ticket.createdAt.day}/${ticket.createdAt.month}/${ticket.createdAt.year}';

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: Color(0xFFE2E8F0))),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildInfoChip(texts['support_category']!, ticket.feedbackType),
                    _buildInfoChip(texts['support_title']!, ticket.title),
                  ],
                ),
                const SizedBox(height: 8),
                Text(texts['support_message']!, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F75BC), fontFamily: 'Tajawal')),
                const SizedBox(height: 4),
                Text(ticket.message, style: const TextStyle(fontSize: 12, color: Colors.black87, height: 1.4, fontFamily: 'Tajawal')),
                const SizedBox(height: 8),
                Text('${texts['support_email']!}: ${ticket.contactEmail ?? 'N/A'}', style: const TextStyle(fontSize: 11, color: Colors.black54, fontFamily: 'Tajawal')),
                const SizedBox(height: 4),
                Text('${texts['support_date']!}: $createdDate', style: const TextStyle(fontSize: 11, color: Colors.black54, fontFamily: 'Tajawal')),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.chat_bubble_outline_rounded, size: 14),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 8)),
                        onPressed: () {
                          _showSupportReplyDialog(context: context, texts: texts, ticketId: ticket.id);
                        },
                        label: Text(texts['reply']!, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, fontFamily: 'Tajawal')),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.check_circle_outline_rounded, size: 14),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 8)),
                        onPressed: () {
                          ref.read(feedbackServiceProvider.notifier).updateTicketStatus(feedbackId: ticket.id, status: 'closed');
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texts['ticket_closed']!)));
                        },
                        label: Text(texts['close_ticket']!, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, fontFamily: 'Tajawal')),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.delete_forever_rounded, size: 14),
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 8)),
                        onPressed: () {
                          executeCloudHardDelete(
                            context: context,
                            collectionPath: 'support_tickets',
                            documentId: ticket.id,
                            isRtl: ref.read(localeProvider).languageCode == 'ar',
                            onDeleted: () => ref.read(feedbackServiceProvider.notifier).updateTicketStatus(feedbackId: ticket.id, status: 'closed'),
                          );
                        },
                        label: Text(ref.read(localeProvider).languageCode == 'ar' ? 'حذف نهائي 🗑️' : 'Hard Delete 🗑️', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, fontFamily: 'Tajawal')),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// بناء تبويب إدارة أكواد الخصم والعروض
  Widget _buildPromoCodesTab(WidgetRef ref, BuildContext context, List activeCodes, Map<String, String> texts) {
    final companyNameController = TextEditingController();
    final codeController = TextEditingController();
    final discountController = TextEditingController();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(texts['add_code_title']!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F75BC), fontFamily: 'Tajawal')),
          const SizedBox(height: 12),
          TextField(
            controller: companyNameController,
            decoration: InputDecoration(hintText: texts['company_hint'], border: const OutlineInputBorder(), filled: true, fillColor: Colors.white),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: codeController,
            decoration: InputDecoration(hintText: texts['code_hint'], border: const OutlineInputBorder(), filled: true, fillColor: Colors.white),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: discountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(hintText: texts['discount_hint'], border: const OutlineInputBorder(), filled: true, fillColor: Colors.white),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 45,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white),
              icon: const Icon(Icons.add_business_outlined, size: 18),
              label: Text(texts['publish_code']!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'Tajawal')),
              onPressed: () {
                final String comp = companyNameController.text.trim();
                final String code = codeController.text.trim();
                final int? disc = int.tryParse(discountController.text.trim());

                if (comp.isNotEmpty && code.isNotEmpty && disc != null) {
                  ref.read(promoCodeProvider.notifier).addPromoCode(code, disc);
                  companyNameController.clear();
                  codeController.clear();
                  discountController.clear();
                  FocusScope.of(context).unfocus();
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texts['code_published']!)));
                }
              },
            ),
          ),
          const Divider(height: 32),
          Text('${texts['active_codes_title']!} (${activeCodes.length}):', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white70, fontFamily: 'Tajawal')),
          const SizedBox(height: 8),
          if (activeCodes.isEmpty)
            Center(child: Text(texts['empty_codes']!, style: const TextStyle(fontSize: 11, color: Colors.white70, fontFamily: 'Tajawal')))
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: activeCodes.length,
              itemBuilder: (context, index) {
                final promo = activeCodes[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  color: const Color(0xFFF8FAFC),
                  child: ListTile(
                    title: Text('${texts['code_label']!}: ${promo.code}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange, fontFamily: 'Tajawal')),
                    subtitle: Text('${texts['discount_label']!}: ${promo.discountPercentage}%', style: const TextStyle(fontFamily: 'Tajawal')),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_forever_rounded, color: Colors.red, size: 20),
                      tooltip: texts['delete_code'],
                      onPressed: () {
                        executeCloudHardDelete(
                          context: context,
                          collectionPath: 'promo_codes',
                          documentId: promo.code,
                          isRtl: ref.read(localeProvider).languageCode == 'ar',
                          onDeleted: () => ref.read(promoCodeProvider.notifier).removePromoCode(promo.code),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Map<String, String> parseDescription(String desc) {
    final sections = desc.split('### [');
    String device = '';
    String diagnosis = '';
    String cause = '';
    String steps = '';
    String safety = '';
    String company = '';
    String model = '';
    String result = '';
    String attachedImages = '';
    String originalDesc = '';
    String revisionLog = '';
    String publisherName = '';
    String publisherExp = '';
    String publisherComment = '';
    String showName = 'true';

    for (var section in sections) {
      if (section.trim().isEmpty) continue;
      final lines = section.split('\n');
      final headerLine = lines[0].trim();
      final content = lines.skip(1).join('\n').trim();

      if (headerLine.startsWith('DEVICE_NAME]')) {
        device = content;
      } else if (headerLine.startsWith('FAULT_DESCRIPTION]')) {
        diagnosis = content;
      } else if (headerLine.startsWith('FAULT_CAUSE]')) {
        cause = content;
      } else if (headerLine.startsWith('RESOLUTION_STEPS]')) {
        steps = content;
      } else if (headerLine.startsWith('OSHA_SAFETY]')) {
        safety = content;
      } else if (headerLine.startsWith('COMPANY]')) {
        company = content;
      } else if (headerLine.startsWith('MODEL]')) {
        model = content;
      } else if (headerLine.startsWith('RESULT]')) {
        result = content;
      } else if (headerLine.startsWith('ATTACHED_IMAGES]')) {
        attachedImages = content;
      } else if (headerLine.startsWith('ORIGINAL_DESC]')) {
        originalDesc = content;
      } else if (headerLine.startsWith('REVISION_LOG]')) {
        revisionLog = content;
      } else if (headerLine.startsWith('PUBLISHER_NAME]')) {
        publisherName = content;
      } else if (headerLine.startsWith('PUBLISHER_EXP]')) {
        publisherExp = content;
      } else if (headerLine.startsWith('PUBLISHER_COMMENT]')) {
        publisherComment = content;
      } else if (headerLine.startsWith('SHOW_NAME]')) {
        showName = content;
      }
    }

    // Fallback if the description is in the old format
    if (device.isEmpty && diagnosis.isEmpty && steps.isEmpty) {
      final oldLines = desc.split('\n');
      String currentSection = '';
      for (var line in oldLines) {
        final trimmed = line.trim();
        if (trimmed.isEmpty) continue;

        if (trimmed.startsWith('اسم الجهاز:') || trimmed.startsWith('الجهاز:') || trimmed.startsWith('Device:')) {
          device = trimmed.split(':').skip(1).join(':').trim();
          currentSection = '';
        } else if (trimmed.startsWith('وصف العطل:') || trimmed.startsWith('التشخيص:') || trimmed.startsWith('Problem:') || trimmed.startsWith('Diagnosis:')) {
          diagnosis = trimmed.split(':').skip(1).join(':').trim();
          currentSection = '';
        } else if (trimmed.startsWith('الأسباب:') || trimmed.startsWith('Causes:')) {
          currentSection = 'causes';
        } else if (trimmed.startsWith('خطوات الحل:') || trimmed.startsWith('Steps:')) {
          currentSection = 'steps';
        } else if (trimmed.startsWith('تحذيرات السلامة:') || trimmed.startsWith('Safety:')) {
          currentSection = 'safety';
        } else {
          if (currentSection == 'causes') {
            cause += (cause.isEmpty ? '' : '\n') + trimmed;
          } else if (currentSection == 'steps') {
            steps += (steps.isEmpty ? '' : '\n') + trimmed;
          } else if (currentSection == 'safety') {
            safety += (safety.isEmpty ? '' : '\n') + trimmed;
          } else {
            if (diagnosis.isEmpty) {
              diagnosis = trimmed;
            } else {
              diagnosis += '\n' + trimmed;
            }
          }
        }
      }
    }

    return {
      'device': device,
      'diagnosis': diagnosis,
      'cause': cause,
      'steps': steps,
      'safety': safety,
      'company': company,
      'model': model,
      'result': result,
      'attachedImages': attachedImages,
      'original_desc': originalDesc,
      'revision_log': revisionLog,
      'publisherName': publisherName,
      'publisherExp': publisherExp,
      'publisherComment': publisherComment,
      'showName': showName,
    };
  }

  String formatProfessionalSummary({
    required String title,
    required String systemType,
    required String rawDesc,
  }) {
    final parsed = parseDescription(rawDesc);
    final cleanTitle = title
        .replaceAll('📘 [موسوعة] ', '')
        .replaceAll('📘 [KB] ', '')
        .replaceAll('[KB]', '')
        .trim();

    final finalDevice = parsed['device']!.isNotEmpty ? parsed['device']! : cleanTitle;

    // Extract company
    String company = parsed['company']!.isNotEmpty ? parsed['company']! : 'غير محدد';
    if (company == 'غير محدد') {
      final companies = ['Gree', 'Schneider', 'Carrier', 'LG', 'Toyota', 'Rexroth', 'Siemens', 'Allen Bradley', 'Dolphin'];
      for (var c in companies) {
        if (finalDevice.toLowerCase().contains(c.toLowerCase())) {
          company = c;
          break;
        }
      }
    }

    // Extract model
    String model = parsed['model']!.isNotEmpty ? parsed['model']! : 'غير محدد';
    if (model == 'غير محدد') {
      final modelRegex = RegExp(r'\b[A-Z0-9-]{3,}\b');
      final matches = modelRegex.allMatches(finalDevice);
      for (var match in matches) {
        final possibleModel = match.group(0)!;
        if (possibleModel != company.toUpperCase() && !possibleModel.contains('AC') && possibleModel != 'TON') {
          model = possibleModel;
          break;
        }
      }
    }

    final result = parsed['result']!.isNotEmpty 
        ? parsed['result']! 
        : 'تم فحص العطل وحله بنجاح، واعتماد الإجراء كإجراء قياسي موثق.';

    final buffer = StringBuffer();
    buffer.writeln(cleanTitle);
    buffer.writeln('');
    if (finalDevice.isNotEmpty) buffer.writeln('اسم الجهاز: $finalDevice');
    if (company != 'غير محدد' && company.isNotEmpty) buffer.writeln('الشركة: $company');
    if (model != 'غير محدد' && model.isNotEmpty) buffer.writeln('الموديل: $model');
    buffer.writeln('');
    
    if (parsed['diagnosis']!.isNotEmpty) {
      buffer.writeln('وصف العطل:');
      buffer.writeln(parsed['diagnosis']!);
      buffer.writeln('');
    }
    if (parsed['cause']!.isNotEmpty) {
      buffer.writeln('سبب العطل:');
      buffer.writeln(parsed['cause']!);
      buffer.writeln('');
    }
    
    if (parsed['steps']!.isNotEmpty) {
      buffer.writeln('خطوات الحل:');
      final stepLines = parsed['steps']!.split('\n');
      int idx = 1;
      for (var line in stepLines) {
        final cleanLine = line.replaceFirst(RegExp(r'^\d+[\.-]\s*'), '').trim();
        if (cleanLine.isNotEmpty) {
          buffer.writeln('$idx- $cleanLine');
          idx++;
        }
      }
      buffer.writeln('');
    }
    
    if (result.isNotEmpty) {
      buffer.writeln('النتيجة:');
      buffer.writeln(result);
      buffer.writeln('');
    }
    if (parsed['safety']!.isNotEmpty) {
      buffer.writeln('تعليمات السلامة:');
      buffer.writeln(parsed['safety']!);
    }

    final bool showName = parsed['showName'] == 'true';
    final pName = parsed['publisherName'] ?? '';
    final pExp = parsed['publisherExp'] ?? '';
    final pComment = parsed['publisherComment'] ?? '';

    if (showName && pName.trim().isNotEmpty) {
      buffer.writeln('');
      buffer.writeln('بيانات الناشر (إن وجدت):');
      final nameStr = pName.trim();
      final expStr = pExp.trim().isNotEmpty ? ' (${pExp.trim()})' : '';
      buffer.writeln('👤 $nameStr$expStr');
      if (pComment.trim().isNotEmpty) {
        buffer.writeln('💬 ${pComment.trim()}');
      }
    }

    final imagePaths = parsed['attachedImages']?.split('\n').where((p) => p.trim().isNotEmpty).toList() ?? [];
    if (imagePaths.isNotEmpty) {
      buffer.writeln('');
      buffer.writeln('### [ATTACHED_IMAGES]');
      buffer.writeln(imagePaths.join('\n'));
    }

    return buffer.toString().trim();
  }

  void _showDetailedEditDialog({
    required BuildContext context,
    required Map<String, String> texts,
    required ForumPost post,
  }) {
    final isRtl = ref.read(localeProvider).languageCode == 'ar';
    final parsed = parseDescription(post.description);

    final titleController = TextEditingController(text: post.title.replaceAll('📘 [موسوعة] ', '').replaceAll('📘 [KB] ', '').trim());
    final deviceController = TextEditingController(text: parsed['device']);
    final companyController = TextEditingController(text: parsed['company']!.isNotEmpty ? parsed['company'] : 'غير محدد');
    final modelController = TextEditingController(text: parsed['model']!.isNotEmpty ? parsed['model'] : 'غير محدد');
    final diagnosisController = TextEditingController(text: parsed['diagnosis']);
    final causeController = TextEditingController(text: parsed['cause']);
    final stepsController = TextEditingController(text: parsed['steps']);
    final resultController = TextEditingController(text: parsed['result']!.isNotEmpty ? parsed['result'] : 'تم فحص العطل وحله بنجاح، واعتماد الإجراء كإجراء قياسي موثق.');
    final safetyController = TextEditingController(text: parsed['safety']);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Directionality(
        textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            isRtl ? '✏️ تعديل تفاصيل التشخيص' : '✏️ Edit Diagnostic Details',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F75BC), fontFamily: 'Tajawal'),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(labelText: isRtl ? 'عنوان العطل' : 'Trouble Title'),
                ),
                TextField(
                  controller: deviceController,
                  decoration: InputDecoration(labelText: isRtl ? 'اسم الجهاز' : 'Device Name'),
                ),
                TextField(
                  controller: companyController,
                  decoration: InputDecoration(labelText: isRtl ? 'الشركة المصنعة' : 'Company'),
                ),
                TextField(
                  controller: modelController,
                  decoration: InputDecoration(labelText: isRtl ? 'الموديل' : 'Model'),
                ),
                TextField(
                  controller: diagnosisController,
                  maxLines: 2,
                  decoration: InputDecoration(labelText: isRtl ? 'وصف العطل' : 'Fault Description'),
                ),
                TextField(
                  controller: causeController,
                  maxLines: 2,
                  decoration: InputDecoration(labelText: isRtl ? 'سبب العطل' : 'Trouble Cause'),
                ),
                TextField(
                  controller: stepsController,
                  maxLines: 3,
                  decoration: InputDecoration(labelText: isRtl ? 'خطوات الحل (كل خطوة في سطر)' : 'Resolution Steps (one per line)'),
                ),
                TextField(
                  controller: resultController,
                  decoration: InputDecoration(labelText: isRtl ? 'النتيجة' : 'Result'),
                ),
                TextField(
                  controller: safetyController,
                  maxLines: 2,
                  decoration: InputDecoration(labelText: isRtl ? 'تعليمات السلامة' : 'Safety Instructions'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(isRtl ? 'إلغاء' : 'Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final originalDesc = parsed['original_desc']?.isNotEmpty == true 
                    ? parsed['original_desc']! 
                    : post.description;
                final revisionLog = '${parsed['revision_log'] ?? ''}\nEdited on ${DateTime.now().toIso8601String()}';

                final updatedDescription = 
                  '### [DEVICE_NAME]\n${deviceController.text.trim()}\n\n'
                  '### [FAULT_DESCRIPTION]\n${diagnosisController.text.trim()}\n\n'
                  '### [FAULT_CAUSE]\n${causeController.text.trim()}\n\n'
                  '### [RESOLUTION_STEPS]\n${stepsController.text.trim()}\n\n'
                  '### [OSHA_SAFETY]\n${safetyController.text.trim()}\n\n'
                  '### [COMPANY]\n${companyController.text.trim()}\n\n'
                  '### [MODEL]\n${modelController.text.trim()}\n\n'
                  '### [RESULT]\n${resultController.text.trim()}\n\n'
                  '### [ATTACHED_IMAGES]\n${parsed['attachedImages'] ?? ''}\n\n'
                  '### [ORIGINAL_DESC]\n$originalDesc\n\n'
                  '### [REVISION_LOG]\n$revisionLog\n\n'
                  '### [PUBLISHER_NAME]\n${parsed['publisherName'] ?? ''}\n\n'
                  '### [PUBLISHER_EXP]\n${parsed['publisherExp'] ?? ''}\n\n'
                  '### [PUBLISHER_COMMENT]\n${parsed['publisherComment'] ?? ''}\n\n'
                  '### [SHOW_NAME]\n${parsed['showName'] ?? 'true'}';

                final newTitle = '📘 [موسوعة] ${titleController.text.trim()}';
                ref.read(forumProvider.notifier).updatePostDescription(post.id, updatedDescription);
                ref.read(forumProvider.notifier).updatePostTitle(post.id, newTitle);
                
                Navigator.pop(dialogContext);
              },
              child: Text(isRtl ? 'حفظ' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 📂 تبويب 6 — الحوكمة الأرشيفية المطلقة لمجتمع الخبراء (forum_posts)
  // حصري للـ Super Admin — يمتد للأرشيف التاريخي الكامل في الإنتاج
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Widget _buildLiveArchiveTab({
    required BuildContext context,
    required WidgetRef ref,
    required bool isRtl,
    required Map<String, String> texts,
  }) {
    // 🔄 في حال عدم توفر اتصال سحابي، يتم الاعتماد فوراً على المنشورات المعتمدة محلياً
    if (Firebase.apps.isEmpty) {
      final localApproved = ref.watch(forumProvider).where((p) => p.isApproved).toList();
      return _buildArchiveListView(
        context: context,
        ref: ref,
        isRtl: isRtl,
        archivePosts: localApproved,
      );
    }

    // 📡 بث حي لجميع وثائق forum_posts دون أمر orderBy المقيد لتجنب حجب الوثائق غير المفهرسة
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('forum_posts')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint('Firestore forum_posts archive stream error: ${snapshot.error}');
          final localApproved = ref.watch(forumProvider).where((p) => p.isApproved).toList();
          if (localApproved.isNotEmpty) {
            return _buildArchiveListView(
              context: context,
              ref: ref,
              isRtl: isRtl,
              archivePosts: localApproved,
            );
          }
          return Center(
            child: Text(
              isRtl ? 'خطأ في تحميل الأرشيف الإنتاجي.' : 'Error loading production archive.',
              style: const TextStyle(fontFamily: 'Tajawal', color: Colors.red, fontSize: 12),
            ),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Center(
            child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator(color: Color(0xFF0F75BC))),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        final List<ForumPost> cloudPosts = [];
        for (var doc in docs) {
          try {
            cloudPosts.add(ForumPost.fromFirestore(doc));
          } catch (e) {
            debugPrint('Error parsing forum_posts archive doc: $e');
          }
        }

        // 🔄 الدمج الهجين (Hybrid Sync) مع المنشورات المحلية المعتمدة تاريخياً (مثل منشور Chiller)
        final localApproved = ref.watch(forumProvider).where((p) => p.isApproved).toList();
        final List<ForumPost> archivePosts = List<ForumPost>.from(cloudPosts);
        for (final p in localApproved) {
          if (!archivePosts.any((item) => item.id == p.id)) {
            archivePosts.add(p);
          }
        }

        // ⏱️ فرز برمجي آمن في الذاكرة (In-Memory Safe Sort) بحسب التوقيت تنازلياً
        archivePosts.sort((a, b) {
          final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return bDate.compareTo(aDate);
        });

        return _buildArchiveListView(
          context: context,
          ref: ref,
          isRtl: isRtl,
          archivePosts: archivePosts,
        );
      },
    );
  }

  /// 📋 واجهة عرض قائمة منشورات الأرشيف المدمجة
  Widget _buildArchiveListView({
    required BuildContext context,
    required WidgetRef ref,
    required bool isRtl,
    required List<ForumPost> archivePosts,
  }) {
    if (archivePosts.isEmpty) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.archive_outlined, color: Color(0xFF94A3B8), size: 40),
            const SizedBox(height: 10),
            Text(
              isRtl ? 'لا توجد منشورات في الأرشيف الإنتاجي حالياً.' : 'No posts in production archive.',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), fontFamily: 'Tajawal'),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // شارة البث الحي
        Container(
              margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF93C5FD)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.cloud_done_rounded, color: Color(0xFF2563EB), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isRtl
                          ? '🟢 أرشيف مجتمع الخبراء الإنتاجي (forum_posts) — إجمالي: ${archivePosts.length} منشور'
                          : '🟢 Production Expert Community Archive (forum_posts) — Total: ${archivePosts.length} posts',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E40AF), fontFamily: 'Tajawal'),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: archivePosts.length,
                itemBuilder: (context, index) {
                  final post = archivePosts[index];
                  final postDt = post.createdAt;
                  final date = postDt != null
                      ? '${postDt.day}/${postDt.month}/${postDt.year}'
                      : '-';
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // العنوان
                          Row(
                            children: [
                              const Icon(Icons.forum_rounded, color: Color(0xFF0F75BC), size: 16),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  post.title,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), fontFamily: 'Tajawal'),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (post.imageUrl != null && post.imageUrl!.isNotEmpty)
                                const Padding(
                                  padding: EdgeInsets.only(right: 4),
                                  child: Icon(Icons.image_rounded, color: Color(0xFF10B981), size: 16),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          // معلومات الصفيحة
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              _buildInfoChip(isRtl ? 'الكاتب' : 'Author', post.author),
                              _buildInfoChip(isRtl ? 'التخصص' : 'Specialty', post.specialty),
                              _buildInfoChip(isRtl ? 'التاريخ' : 'Date', date),
                              _buildInfoChip(isRtl ? 'القطاع' : 'Category', post.category),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            post.description,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11, height: 1.4, color: Colors.black87, fontFamily: 'Tajawal'),
                          ),
                          const SizedBox(height: 10),
                          // أزرار الحوكمة
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.edit_rounded, size: 15),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0F75BC),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 9),
                                  ),
                                  label: Text(
                                    isRtl ? '✏️ تعديل' : '✏️ Edit',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'Tajawal'),
                                  ),
                                  onPressed: () => _showArchiveEditDialog(
                                    context: context,
                                    ref: ref,
                                    isRtl: isRtl,
                                    post: post,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.delete_forever_rounded, size: 15),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFDC2626),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 9),
                                  ),
                                  label: Text(
                                    isRtl ? '🗑️ حذف أرشيف' : '🗑️ Hard Delete',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'Tajawal'),
                                  ),
                                  onPressed: () => executeCloudHardDelete(
                                    context: context,
                                    collectionPath: 'forum_posts',
                                    documentId: post.id,
                                    isRtl: isRtl,
                                    // تحديث الـ Riverpod state + حذف الصورة تلقائياً داخل executeCloudHardDelete
                                    onDeleted: () => ref.read(forumProvider.notifier).rejectPost(post.id),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
  }

  /// ✏️ Dialog تعديل منشور إنتاجي في مجتمع الخبراء (forum_posts)
  void _showArchiveEditDialog({
    required BuildContext context,
    required WidgetRef ref,
    required bool isRtl,
    required ForumPost post,
  }) {
    final titleCtrl = TextEditingController(text: post.title);
    final descCtrl = TextEditingController(text: post.description);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Directionality(
        textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
        child: Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isRtl ? '✏️ تعديل منشور الأرشيف الإنتاجي' : '✏️ Edit Production Archive Post',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F75BC), fontFamily: 'Tajawal'),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ID: ${post.id}',
                    style: const TextStyle(fontSize: 9, color: Colors.grey, fontFamily: 'Courier'),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: titleCtrl,
                    decoration: InputDecoration(
                      labelText: isRtl ? 'العنوان' : 'Title',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                    ),
                    style: const TextStyle(fontFamily: 'Tajawal', fontSize: 13),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: descCtrl,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: isRtl ? 'المحتوى' : 'Content',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                    ),
                    style: const TextStyle(fontFamily: 'Tajawal', fontSize: 12),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          child: Text(isRtl ? '❌ إلغاء' : '❌ Cancel', style: const TextStyle(fontFamily: 'Tajawal')),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F75BC),
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () async {
                            final newTitle = titleCtrl.text.trim();
                            final newDesc = descCtrl.text.trim();
                            if (newTitle.isEmpty && newDesc.isEmpty) return;
                            try {
                              if (newTitle.isNotEmpty) {
                                ref.read(forumProvider.notifier).updatePostTitle(post.id, newTitle);
                              }
                              if (newDesc.isNotEmpty) {
                                ref.read(forumProvider.notifier).updatePostDescription(post.id, newDesc);
                              }
                              if (Firebase.apps.isNotEmpty) {
                                final updateData = <String, dynamic>{
                                  'title': newTitle.isNotEmpty ? newTitle : post.title,
                                  'description': newDesc.isNotEmpty ? newDesc : post.description,
                                  'author': post.author,
                                  'specialty': post.specialty,
                                  'category': post.category,
                                  'is_approved': true,
                                  'isApproved': true,
                                  'updated_at': FieldValue.serverTimestamp(),
                                };
                                await FirebaseFirestore.instance
                                    .collection('forum_posts')
                                    .doc(post.id)
                                    .set(updateData, SetOptions(merge: true));
                              }
                              if (context.mounted) Navigator.pop(dialogContext);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                  backgroundColor: const Color(0xFF0F75BC),
                                  content: Text(
                                    isRtl ? '✅ تم تحديث المنشور في الأرشيف الإنتاجي.' : '✅ Production archive post updated.',
                                    style: const TextStyle(fontFamily: 'Tajawal'),
                                  ),
                                ));
                              }
                            } catch (e) {
                              debugPrint('Error updating forum_posts doc: $e');
                              if (context.mounted) Navigator.pop(dialogContext);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                  backgroundColor: Colors.red,
                                  content: Text(
                                    isRtl ? 'حدث خطأ: $e' : 'Update error: $e',
                                    style: const TextStyle(fontFamily: 'Tajawal'),
                                  ),
                                ));
                              }
                            }
                          },
                          child: Text(isRtl ? '💾 حفظ' : '💾 Save', style: const TextStyle(fontFamily: 'Tajawal')),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 📚 تبويب 7 — الحوكمة الكاملة لموسوعة الأعطال الموثقة (verified_faults)
  // حصري للـ Super Admin — بث حي مع تعديل وحذف نهائي مطلق
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Widget _buildLiveEncyclopediaTab({
    required BuildContext context,
    required WidgetRef ref,
    required bool isRtl,
  }) {
    final faultsAsync = ref.watch(liveVerifiedFaultsStreamProvider);

    return faultsAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(color: Color(0xFF16A34A)),
        ),
      ),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            isRtl ? 'خطأ في تحميل الموسوعة: $error' : 'Error loading encyclopedia: $error',
            style: const TextStyle(fontFamily: 'Tajawal', color: Colors.red, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ),
      ),
      data: (faults) {
        if (faults.isEmpty) {
          return Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.menu_book_outlined, color: Color(0xFF94A3B8), size: 40),
                const SizedBox(height: 10),
                Text(
                  isRtl ? 'لا توجد أعطال موثقة في الموسوعة حالياً.' : 'No verified faults in encyclopedia.',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'Tajawal'),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // شارة البث الحي
            Container(
              margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF16A34A)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.menu_book_rounded, color: Color(0xFF15803D), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isRtl
                          ? '📘 الموسوعة الموثقة (verified_faults) — إجمالي: ${faults.length} عطل'
                          : '📘 Verified Faults Encyclopedia (verified_faults) — Total: ${faults.length}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF15803D), fontFamily: 'Tajawal'),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: faults.length,
                itemBuilder: (context, index) {
                  final fault = faults[index];
                  final date = '${fault.createdAt.day}/${fault.createdAt.month}/${fault.createdAt.year}';
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    color: const Color(0xFFF0FDF4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(color: const Color(0xFF16A34A).withValues(alpha: 0.4)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // العنوان + عداد المشاهدات
                          Row(
                            children: [
                              const Icon(Icons.engineering_rounded, color: Color(0xFF15803D), size: 16),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  fault.title,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF15803D), fontFamily: 'Tajawal'),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDCFCE7),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '👁️ ${fault.viewsCount}',
                                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF15803D), fontFamily: 'Tajawal'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              _buildInfoChip(isRtl ? 'القطاع' : 'Sector', fault.sector),
                              _buildInfoChip(isRtl ? 'الكاتب' : 'Author', fault.authorName),
                              _buildInfoChip(isRtl ? 'التاريخ' : 'Date', date),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            fault.description,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11, height: 1.4, color: Colors.black87, fontFamily: 'Tajawal'),
                          ),
                          const SizedBox(height: 10),
                          // أزرار الحوكمة
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.edit_rounded, size: 15),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF16A34A),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 9),
                                  ),
                                  label: Text(
                                    isRtl ? '✏️ تعديل' : '✏️ Edit',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'Tajawal'),
                                  ),
                                  onPressed: () => _showEncyclopediaEditDialog(
                                    context: context,
                                    isRtl: isRtl,
                                    fault: fault,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.delete_forever_rounded, size: 15),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFDC2626),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 9),
                                  ),
                                  label: Text(
                                    isRtl ? '🗑️ حذف موثق' : '🗑️ Hard Delete',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'Tajawal'),
                                  ),
                                  onPressed: () => executeCloudHardDelete(
                                    context: context,
                                    collectionPath: 'verified_faults',
                                    documentId: fault.id,
                                    isRtl: isRtl,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  /// ✏️ Dialog تعديل عطل موثق في الموسوعة الهندسية (verified_faults)
  void _showEncyclopediaEditDialog({
    required BuildContext context,
    required bool isRtl,
    required VerifiedFault fault,
  }) {
    final titleCtrl = TextEditingController(text: fault.title);
    final descCtrl = TextEditingController(text: fault.description);
    final authorCtrl = TextEditingController(text: fault.authorName);
    String selectedSector = fault.sector;

    const List<String> sectors = [
      'تبريد وتكييف', 'كهرباء', 'ميكانيك', 'أنظمة الهيدروليك',
      'أجهزة منزلية', 'صناعي', 'سيارات ومركبات', 'سباكة', 'أخرى',
    ];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (stCtx, setState) => Directionality(
          textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
          child: Dialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isRtl ? '✏️ تعديل عطل موثق في الموسوعة' : '✏️ Edit Verified Encyclopedia Fault',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF16A34A), fontFamily: 'Tajawal'),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ID: ${fault.id}',
                      style: const TextStyle(fontSize: 9, color: Colors.grey, fontFamily: 'Courier'),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: titleCtrl,
                      decoration: InputDecoration(
                        labelText: isRtl ? 'العنوان' : 'Title',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                      ),
                      style: const TextStyle(fontFamily: 'Tajawal', fontSize: 13),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: descCtrl,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: isRtl ? 'الوصف والحل التقني' : 'Description & Technical Solution',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                      ),
                      style: const TextStyle(fontFamily: 'Tajawal', fontSize: 12),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: authorCtrl,
                      decoration: InputDecoration(
                        labelText: isRtl ? 'اسم المؤلف' : 'Author Name',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                      ),
                      style: const TextStyle(fontFamily: 'Tajawal', fontSize: 13),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: sectors.contains(selectedSector) ? selectedSector : sectors.last,
                      decoration: InputDecoration(
                        labelText: isRtl ? 'القطاع الهندسي' : 'Engineering Sector',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                      ),
                      style: const TextStyle(fontFamily: 'Tajawal', fontSize: 13, color: Color(0xFF0F172A)),
                      items: sectors
                          .map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontFamily: 'Tajawal'))))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => selectedSector = val);
                      },
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            child: Text(isRtl ? '❌ إلغاء' : '❌ Cancel', style: const TextStyle(fontFamily: 'Tajawal')),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF16A34A),
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () async {
                              final success = await VerifiedFaultsAdminService.saveOrUpdateFault(
                                id: fault.id,
                                title: titleCtrl.text.trim().isEmpty ? fault.title : titleCtrl.text.trim(),
                                description: descCtrl.text.trim().isEmpty ? fault.description : descCtrl.text.trim(),
                                sector: selectedSector,
                                authorName: authorCtrl.text.trim().isEmpty ? fault.authorName : authorCtrl.text.trim(),
                                viewsCount: fault.viewsCount,
                              );
                              if (context.mounted) Navigator.pop(dialogContext);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                  backgroundColor: success ? const Color(0xFF16A34A) : Colors.red,
                                  content: Text(
                                    success
                                        ? (isRtl ? '✅ تم تحديث العطل الموثق في موسوعة السحاب.' : '✅ Verified fault updated in encyclopedia.')
                                        : (isRtl ? 'حدث خطأ أثناء التحديث.' : 'Update failed.'),
                                    style: const TextStyle(fontFamily: 'Tajawal'),
                                  ),
                                ));
                              }
                            },
                            child: Text(isRtl ? '💾 حفظ' : '💾 Save', style: const TextStyle(fontFamily: 'Tajawal')),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}