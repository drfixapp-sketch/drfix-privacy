import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dr_fix/presentation/widgets/community_provider.dart';
import 'package:dr_fix/main.dart';
import 'package:dr_fix/data/network/feedback_service.dart';
import 'package:dr_fix/data/models/feedback_model.dart';
import 'package:url_launcher/url_launcher.dart';

/// 🛡️ لوحة الإشراف والمراجعة المصغرة للأدمن (Micro Admin Moderation Panel)
/// تتيح مراجعة المنشورات والتعليقات المعلقة، واعتمادها ونشرها للعامة، أو رفضها وحذفها لضمان سلامة المجتمع.
class AdminApprovalWidget extends ConsumerWidget {
  const AdminApprovalWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isRtl = ref.watch(localeProvider).languageCode == 'ar';
    final communityState = ref.watch(communityProvider);
    final feedbacks = ref.watch(feedbackServiceProvider);
    
    // تصفية المنشورات المعلقة والمنشورات العامة للمراجعة
    final pendingPosts = communityState.posts.where((post) => !post.isPublic).toList();
    final approvedPosts = communityState.posts.where((post) => post.isPublic).toList();

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: DefaultTabController(
        length: 3,
        child: Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            backgroundColor: const Color(0xFF1E293B), // مظهر تكنولوجي للإشراف
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              isRtl ? '🛡️ لوحة الإشراف وإدارة المحتوى' : '🛡️ Content Moderation Panel',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            centerTitle: true,
            bottom: TabBar(
              indicatorColor: const Color(0xFF38BDF8),
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: const Color(0xFF94A3B8),
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5),
              tabs: [
                Tab(
                  text: isRtl ? 'منشورات بانتظار الاعتماد (${pendingPosts.length})' : 'Pending Approvals (${pendingPosts.length})',
                  icon: const Icon(Icons.hourglass_empty_rounded, size: 18),
                ),
                Tab(
                  text: isRtl ? 'الأعطال المنشورة للعامة (${approvedPosts.length})' : 'Published Feed (${approvedPosts.length})',
                  icon: const Icon(Icons.verified_user_rounded, size: 18),
                ),
                Tab(
                  text: isRtl ? 'الشكاوى والملاحظات (${feedbacks.length})' : 'Feedbacks (${feedbacks.length})',
                  icon: const Icon(Icons.mark_email_unread_rounded, size: 18),
                ),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              // التبويب الأول: المنشورات المعلقة
              _buildPendingList(context, ref, pendingPosts, isRtl),
              
              // التبويب الثاني: المنشورات المعتمدة والمنشورة
              _buildApprovedList(context, ref, approvedPosts, isRtl),

              // التبويب الثالث: شكاوى وملاحظات المستخدمين مع قنوات الرد التلقائية والذكية
              _buildFeedbackList(context, ref, feedbacks, isRtl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPendingList(BuildContext context, WidgetRef ref, List<dynamic> posts, bool isRtl) {
    if (posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_outline_rounded, size: 48, color: Colors.green),
            ),
            const SizedBox(height: 16),
            Text(
              isRtl ? 'طابور المراجعة فارغ بالكامل! 🎉' : 'All caught up! No pending reviews. 🎉',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isRtl ? 'المجتمع آمن ومحدث بانتظام.' : 'The community is safe and up-to-date.',
              style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: posts.length,
      padding: const EdgeInsets.all(12),
      itemBuilder: (context, index) {
        final post = posts[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFFF1F5F9)),
          ),
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // رأس البطاقة: القسم التقني والتاريخ
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        post.systemType,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ),
                    Text(
                      isRtl ? 'معلق ⏳' : 'Pending ⏳',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.amber,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // اسم الجهاز والموديل
                Text(
                  post.deviceModel,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 8),

                // وصف المشكلة المستلمة
                _buildSectionLabel(isRtl ? 'وصف المشكلة وعلامات التلف:' : 'Problem Description:'),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(top: 4, bottom: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Text(
                    post.issueDescription,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF475569), height: 1.4),
                  ),
                ),

                // خطوات الحل الموثقة والمنجزة
                _buildSectionLabel(isRtl ? 'خطوات الإصلاح المقترحة والحلول:' : 'Proposed Solution & Steps:'),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(top: 4, bottom: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4), // خلفية هادئة بلون الإصلاح الموثق
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFDCFCE7)),
                  ),
                  child: Text(
                    post.successfulSolution,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF15803D), height: 1.4),
                  ),
                ),

                // التكلفة التقريبية
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isRtl ? 'التكلفة التقريبية للقطع:' : 'Estimated Cost:',
                      style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                    ),
                    Text(
                      post.approximateCost,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                  ],
                ),
                const Divider(height: 24, color: Color(0xFFE2E8F0)),

                // أزرار اتخاذ القرار للإشراف
                Row(
                  children: [
                    // زر الرفض والحذف
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.redAccent, width: 1.2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          foregroundColor: Colors.redAccent,
                          padding: const EdgeInsets.symmetric(vertical: 11),
                        ),
                        onPressed: () {
                          ref.read(communityProvider.notifier).rejectPost(post.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: Colors.red,
                              content: Text(isRtl ? '🗑️ تم رفض وحذف المنشور من النظام.' : '🗑️ Post rejected and purged successfully.'),
                            ),
                          );
                        },
                        child: Text(
                          isRtl ? 'رفض وحذف (Reject)' : 'Reject & Purge',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // زر القبول والنشر
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF16A34A),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          elevation: 0,
                        ),
                        onPressed: () {
                          ref.read(communityProvider.notifier).approvePost(post.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: Colors.green,
                              content: Text(isRtl ? '✅ تم قبول ونشر التقرير للمجتمع بنجاح!' : '✅ Post approved and published to the feed!'),
                            ),
                          );
                        },
                        child: Text(
                          isRtl ? 'قبول ونشر (Approve)' : 'Approve & Publish',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
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
    );
  }

  Widget _buildApprovedList(BuildContext context, WidgetRef ref, List<dynamic> posts, bool isRtl) {
    if (posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.feed_outlined, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              isRtl ? 'لا توجد منشورات منشورة للعامة حالياً.' : 'No published posts yet.',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: posts.length,
      padding: const EdgeInsets.all(12),
      itemBuilder: (context, index) {
        final post = posts[index];
        return Card(
          elevation: 1,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        post.systemType,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF15803D),
                        ),
                      ),
                    ),
                    const Row(
                      children: [
                        Icon(Icons.verified_user_rounded, color: Colors.green, size: 14),
                        SizedBox(width: 4),
                        Text(
                          'نشط وعام ✔️',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  post.deviceModel,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  post.issueDescription,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), height: 1.4),
                ),
                const Divider(height: 24, color: Color(0xFFE2E8F0)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isRtl ? 'بواسطة: ${post.authorName}' : 'By: ${post.authorName}',
                      style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                    ),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () {
                        ref.read(communityProvider.notifier).rejectPost(post.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: Colors.red,
                            content: Text(isRtl ? '🗑️ تم إلغاء النشر وحذف العطل.' : '🗑️ Post unpublished and removed.'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.delete_outline_rounded, size: 14),
                      label: Text(
                        isRtl ? 'سحب ونقض النشر' : 'Unpublish & Purge',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
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

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Color(0xFF475569),
        ),
      ),
    );
  }

  Widget _buildFeedbackList(BuildContext context, WidgetRef ref, List<FeedbackModel> feedbacks, bool isRtl) {
    if (feedbacks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFE2E8F0),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.mark_email_read_outlined,
                size: 32,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              isRtl ? 'لا يوجد أي ملاحظات أو شكاوى مستلمة حالياً' : 'No feedbacks or suggestions received yet',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: feedbacks.length,
      itemBuilder: (context, index) {
        final fb = feedbacks[index];
        return AdminFeedbackCard(
          feedback: fb,
          isRtl: isRtl,
        );
      },
    );
  }
}

class AdminFeedbackCard extends ConsumerStatefulWidget {
  final FeedbackModel feedback;
  final bool isRtl;

  const AdminFeedbackCard({
    Key? key,
    required this.feedback,
    required this.isRtl,
  }) : super(key: key);

  @override
  ConsumerState<AdminFeedbackCard> createState() => _AdminFeedbackCardState();
}

class _AdminFeedbackCardState extends ConsumerState<AdminFeedbackCard> {
  final _replyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.feedback.adminReply != null) {
      _replyController.text = widget.feedback.adminReply!;
    }
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _launchEmail(String email, String subject, String body) async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {
        'subject': subject,
        'body': body,
      },
    );
    try {
      if (await canLaunchUrl(emailLaunchUri)) {
        await launchUrl(emailLaunchUri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(emailLaunchUri);
      }
    } catch (e) {
      debugPrint('Error launching email client: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            widget.isRtl 
                ? 'فشل فتح عميل البريد الإلكتروني: $e' 
                : 'Failed to open email client: $e',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final fb = widget.feedback;
    final isRtl = widget.isRtl;

    final String typeLabel = _getTypeLabelAr(fb.feedbackType, isRtl);
    final hasEmail = fb.contactEmail != null && fb.contactEmail!.trim().isNotEmpty;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Head: Category & Time
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F75BC).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    typeLabel,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F75BC),
                    ),
                  ),
                ),
                Text(
                  fb.createdAt.toLocal().toString().substring(0, 16),
                  style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Title
            Text(
              fb.title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 6),

            // Message Body
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Text(
                fb.message,
                style: const TextStyle(fontSize: 11, color: Color(0xFF475569), height: 1.4),
              ),
            ),
            const SizedBox(height: 10),

            // Sender Details (Email or Anonymous)
            Row(
              children: [
                Icon(
                  hasEmail ? Icons.alternate_email_rounded : Icons.person_outline_rounded,
                  size: 14,
                  color: const Color(0xFF64748B),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    hasEmail 
                        ? '${isRtl ? 'البريد الالكتروني للاتصال:' : 'Contact Email:'} ${fb.contactEmail}'
                        : (isRtl ? 'مرسل مجهول الهوية (Anonymous)' : 'Anonymous Sender'),
                    style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),

            if (fb.fcmToken != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.phone_android_rounded,
                    size: 14,
                    color: Color(0xFF64748B),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${isRtl ? 'رمز الجهاز (FCM Token):' : 'FCM Token:'} ${fb.fcmToken}',
                      style: const TextStyle(fontSize: 9.5, color: Color(0xFF94A3B8), fontStyle: FontStyle.italic),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],

            // Admin reply history (if any)
            if (fb.adminReply != null) ...[
              const Divider(height: 24, color: Color(0xFFE2E8F0)),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isRtl ? '✍️ رد الإدارة:' : '✍️ Admin Reply:',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
                        ),
                        if (fb.repliedAt != null)
                          Text(
                            fb.repliedAt!.toLocal().toString().substring(0, 16),
                            style: const TextStyle(fontSize: 8.5, color: Color(0xFF16A34A)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      fb.adminReply!,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF166534), height: 1.4),
                    ),
                  ],
                ),
              ),
            ],

            const Divider(height: 24, color: Color(0xFFE2E8F0)),

            // Decision actions
            if (hasEmail) ...[
              // EMAIL FALLBACK CHANNEL
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F75BC),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                  ),
                  onPressed: () {
                    final subject = isRtl 
                        ? 'متابعة بخصوص ملاحظتك: ${fb.title}' 
                        : 'Follow-up regarding your feedback: ${fb.title}';
                    final body = isRtl
                        ? 'مرحباً،\n\nنشكرك على ملاحظتك بخصوص "${fb.message}".\n\n[اكتب ردك هنا]\n\nمع تحيات إدارة Dr Fix'
                        : 'Hello,\n\nThank you for your feedback regarding "${fb.message}".\n\n[Write your reply here]\n\nBest regards,\nDr Fix Admin';
                    _launchEmail(fb.contactEmail!, subject, body);
                  },
                  icon: const Icon(Icons.alternate_email_rounded, size: 16),
                  label: Text(
                    isRtl ? 'رد عبر البريد الإلكتروني' : 'Reply via Email',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ] else ...[
              // TARGETED PUSH NOTIFICATION REPLY CHANNEL
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isRtl ? 'الرد الفوري عبر إشعار دفع مستهدف (FCM):' : 'Instant Reply via Targeted Push (FCM):',
                    style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _replyController,
                          style: const TextStyle(fontSize: 12),
                          decoration: InputDecoration(
                            hintText: isRtl ? 'اكتب ردك هنا...' : 'Type your reply here...',
                            hintStyle: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                            fillColor: const Color(0xFFF8FAFC),
                            filled: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.all(12),
                        ),
                        onPressed: () async {
                          final replyText = _replyController.text.trim();
                          if (replyText.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: Colors.orange,
                                content: Text(isRtl ? 'يرجى كتابة نص الرد أولاً!' : 'Please enter a reply message first!'),
                              ),
                            );
                            return;
                          }

                          await ref.read(feedbackServiceProvider.notifier).replyToFeedback(
                            feedbackId: fb.id,
                            replyMessage: replyText,
                          );

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: Colors.green,
                              content: Text(
                                isRtl 
                                    ? 'تم إرسال إشعار الدفع الفوري المستهدف بنجاح!' 
                                    : 'Targeted push notification fired instantly!',
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.send_rounded, size: 16),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getTypeLabelAr(String type, bool isRtl) {
    if (isRtl) {
      switch (type.toLowerCase()) {
        case 'bug':
          return '🐛 إبلاغ عن مشكلة (Bug)';
        case 'suggestion':
          return '💡 اقتراح تحسين (Suggestion)';
        case 'question':
          return '❓ استفسار عام (Question)';
        default:
          return 'أخرى';
      }
    } else {
      switch (type.toLowerCase()) {
        case 'bug':
          return '🐛 Bug Report';
        case 'suggestion':
          return '💡 Suggestion';
        case 'question':
          return '❓ Question';
        default:
          return 'Other';
      }
    }
  }
}

// امتداد ذكي لتسهيل برمجة تصميم الأزرار في دارت
extension _ButtonUtils on Widget {
  Widget applyTo({required void Function()? onPressed, required Widget child}) {
    if (this is ElevatedButton) {
      return ElevatedButton(
        style: (this as ElevatedButton).style,
        onPressed: onPressed,
        child: child,
      );
    } else if (this is OutlinedButton) {
      return OutlinedButton(
        style: (this as OutlinedButton).style,
        onPressed: onPressed,
        child: child,
      );
    }
    return this;
  }
}
