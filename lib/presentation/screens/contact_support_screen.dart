import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dr_fix/main.dart';
import 'package:dr_fix/data/models/feedback_model.dart';
import 'package:dr_fix/data/network/feedback_service.dart';
import 'package:dr_fix/presentation/widgets/custom_drawer.dart';

/// ✉️ شاشة الدعم الفني وإرسال الملاحظات والشكاوى (Contact Support & User Feedback Screen)
/// واجهة بتصميم مميز وعصري (Material 3) تدعم اللغتين العربية والإنجليزية.
/// تتيح إرسال الاقتراحات والإبلاغ عن المشاكل مع اختبار المزامنة في وضع عدم الاتصال (Offline).
class ContactSupportScreen extends ConsumerStatefulWidget {
  const ContactSupportScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ContactSupportScreen> createState() => _ContactSupportScreenState();
}

class _ContactSupportScreenState extends ConsumerState<ContactSupportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  final _emailController = TextEditingController();
  
  String _selectedType = 'Bug'; // القيمة الافتراضية للنوع

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  /// محاكاة إرسال بريد إلكتروني مباشر (Option B)
  void _launchNativeMailClient(BuildContext context, bool isRtl) {
    final String subject = _titleController.text.isNotEmpty 
        ? _titleController.text 
        : (isRtl ? 'ملاحظات مستخدم Dr Fix' : 'Dr Fix User Feedback');
    
    final String body = 'النوع: $_selectedType\n'
        'البريد للتواصل: ${_emailController.text}\n\n'
        'الرسالة:\n${_messageController.text}';

    // سنقوم بمحاكاة فتح بريد إلكتروني حقيقي بشكل رائع داخل التطبيق
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.mail_outline_rounded, color: Color(0xFF0F75BC)),
            const SizedBox(width: 8),
            Text(
              isRtl ? 'محاكاة عميل البريد الإلكتروني' : 'Email Client Simulation',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDialogInfo(isRtl ? 'المرسل إليه:' : 'To:', 'support@drfix.app'),
            const SizedBox(height: 8),
            _buildDialogInfo(isRtl ? 'الموضوع:' : 'Subject:', '[Dr Fix Feedback] - $subject'),
            const SizedBox(height: 8),
            _buildDialogInfo(isRtl ? 'محتوى الرسالة:' : 'Email Body:', body),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(isRtl ? 'إغلاق' : 'Close', style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F75BC)),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: Colors.green,
                  content: Text(
                    isRtl 
                        ? '📩 تم فتح تطبيق البريد ومسودة الرسالة جاهزة!' 
                        : '📩 Email client opened with populated draft!',
                  ),
                ),
              );
            },
            child: Text(isRtl ? 'إرسال الآن' : 'Send Now', style: const TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  Widget _buildDialogInfo(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 2),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
          child: Text(value, style: const TextStyle(fontSize: 11, color: Color(0xFF1E293B))),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final localeState = ref.watch(localeProvider);
    final bool isRtl = localeState.languageCode == 'ar';
    final feedbackNotifier = ref.read(feedbackServiceProvider.notifier);
    final feedbacks = ref.watch(feedbackServiceProvider);

    final pendingCount = feedbacks.where((fb) => !fb.isSynced).length;

    final titleLabel = isRtl ? 'الدعم الفني وإرسال الملاحظات' : 'Technical Support & Feedback';
    final descText = isRtl
        ? 'يسعدنا سماع رأيك! يرجى ملء النموذج أدناه لإرسال استفسارك أو مشكلتك مباشرة للإدارة.'
        : 'We would love to hear from you! Please fill the form below to submit your query or issue directly to the admin.';
    final typeLabel = isRtl ? 'تصنيف الملاحظة' : 'Feedback Category';
    final feedbackTypes = isRtl
        ? {
            'Bug': '🐛 إبلاغ عن مشكلة برمجية (Bug)',
            'Suggestion': '💡 اقتراح تحسين للتطبيق (Suggestion)',
            'Question': '❓ استفسار أو سؤال عام (Question)'
          }
        : {
            'Bug': '🐛 Bug Report',
            'Suggestion': '💡 Feature Suggestion',
            'Question': '❓ General Question'
          };

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        drawer: const CustomAppDrawer(),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.5,
          automaticallyImplyLeading: true,
          title: Text(
            titleLabel,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          ),
          centerTitle: true,
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Tooltip(
                message: isRtl ? 'محاكاة وضع عدم الاتصال بالشبكة' : 'Simulate Offline Mode',
                child: Row(
                  children: [
                    Text(
                      feedbackNotifier.isOfflineMode
                          ? (isRtl ? 'أوفلاين 📡' : 'Offline 📡')
                          : (isRtl ? 'أونلاين 🌐' : 'Online 🌐'),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: feedbackNotifier.isOfflineMode ? Colors.red : Colors.green,
                      ),
                    ),
                    Switch(
                      value: !feedbackNotifier.isOfflineMode,
                      activeColor: Colors.green,
                      inactiveThumbColor: Colors.red,
                      inactiveTrackColor: Colors.red.withOpacity(0.2),
                      onChanged: (val) {
                        setState(() {
                          feedbackNotifier.toggleOfflineMode();
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: feedbackNotifier.isOfflineMode ? Colors.orange : Colors.green,
                            content: Text(
                              feedbackNotifier.isOfflineMode
                                  ? (isRtl ? 'تم تفعيل وضع الأوفلاين! سيتم وضع الملاحظات في قائمة الانتظار.' : 'Offline mode active! Feedbacks will be queued.')
                                  : (isRtl ? 'أنت متصل بالإنترنت الآن! يمكنك المزامنة.' : 'You are online now! Ready to sync.'),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 450),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (pendingCount > 0)
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.orange.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.cloud_off_rounded, color: Colors.orange, size: 24),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isRtl ? 'توجد ملاحظات معلقة دون اتصال' : 'Pending Offline Feedbacks',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, color: Colors.orange),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      isRtl
                                          ? 'توجد $pendingCount ملاحظات مخزنة محلياً بانتظار المزامنة.'
                                          : 'There are $pendingCount unsynced items waiting for network.',
                                      style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                                    ),
                                  ],
                                ),
                              ),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: () async {
                                  final count = await feedbackNotifier.syncOfflineFeedbacks();
                                  if (count > 0) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        backgroundColor: Colors.green,
                                        content: Text(
                                          isRtl
                                              ? '✅ تم بنجاح مزامنة وإرسال $count ملاحظة معلقة للإدارة!'
                                              : '✅ Successfully synced and sent $count pending feedbacks!',
                                        ),
                                      ),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        backgroundColor: Colors.red,
                                        content: Text(
                                          isRtl
                                              ? 'يرجى تعطيل وضع الأوفلاين أولاً للمزامنة.'
                                              : 'Please disable Offline mode first to sync.',
                                        ),
                                      ),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.sync_rounded, size: 14),
                                label: Text(isRtl ? 'مزامنة' : 'Sync', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ),
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F75BC).withOpacity(0.06),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.support_agent_rounded, size: 48, color: Color(0xFF0F75BC)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        descText,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.5),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        typeLabel,
                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        value: _selectedType,
                        style: const TextStyle(fontSize: 12.5, color: Color(0xFF1E293B), fontWeight: FontWeight.w600),
                        decoration: InputDecoration(
                          fillColor: Colors.white,
                          filled: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                        ),
                        items: feedbackTypes.entries.map((entry) {
                          return DropdownMenuItem<String>(
                            value: entry.key,
                            child: Text(entry.value),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedType = val;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      Text(
                        isRtl ? 'عنوان الملاحظة' : 'Feedback Title',
                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _titleController,
                        style: const TextStyle(fontSize: 12.5),
                        decoration: InputDecoration(
                          hintText: isRtl ? 'مثال: مشكلة في خريطة الورش' : 'e.g. Map search glitch',
                          hintStyle: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                          fillColor: Colors.white,
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return isRtl ? 'يرجى إدخال عنوان للملاحظة' : 'Please enter a title';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Text(
                        isRtl ? 'تفاصيل الملاحظة والرسالة' : 'Message Details',
                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _messageController,
                        maxLines: 5,
                        style: const TextStyle(fontSize: 12.5),
                        decoration: InputDecoration(
                          hintText: isRtl
                              ? 'اكتب تفاصيل مشكلتك، اقتراحك أو استفسارك هنا بكل تفصيل ليتسنى لنا الرد والحل المباشر...'
                              : 'Write details of your problem, suggestion or general question here...',
                          hintStyle: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                          fillColor: Colors.white,
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return isRtl ? 'يرجى كتابة نص الرسالة' : 'Please write your message';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Text(
                        isRtl ? 'بريدك الإلكتروني (اختياري للتواصل)' : 'Your Email (Optional)',
                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(fontSize: 12.5),
                        decoration: InputDecoration(
                          hintText: isRtl ? 'example@mail.com' : 'example@mail.com',
                          hintStyle: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                          fillColor: Colors.white,
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFF0F75BC), width: 1.2),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                foregroundColor: const Color(0xFF0F75BC),
                              ),
                              onPressed: () => _launchNativeMailClient(context, isRtl),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.alternate_email_rounded, size: 16),
                                  const SizedBox(width: 6),
                                  Text(
                                    isRtl ? 'مسودة البريد' : 'Email Draft',
                                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 3,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0F75BC),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                elevation: 0,
                              ),
                              onPressed: () async {
                                if (_formKey.currentState!.validate()) {
                                  final isOnlineTransmitted = await feedbackNotifier.submitFeedback(
                                    type: _selectedType,
                                    title: _titleController.text,
                                    message: _messageController.text,
                                    email: _emailController.text.trim().isNotEmpty ? _emailController.text : null,
                                  );

                                  _showSuccessDialog(context, isRtl, isOnlineTransmitted);
                                  _titleController.clear();
                                  _messageController.clear();
                                  _emailController.clear();
                                }
                              },
                              child: Text(
                                isRtl ? 'إنشاء تذكرة جديدة' : 'Create Ticket',
                                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      if (feedbacks.isNotEmpty) ...[
                        const Divider(height: 32, color: Color(0xFFE2E8F0)),
                        Text(
                          isRtl ? '📜 سجل ملاحظاتك المرسلة' : '📜 History of Sent Feedbacks',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                        ),
                        const SizedBox(height: 12),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: feedbacks.length,
                          itemBuilder: (context, index) {
                            final fb = feedbacks[index];
                            final String typeName = feedbackTypes[fb.feedbackType] ?? fb.feedbackType;
                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              color: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                              child: ListTile(
                                dense: true,
                                title: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        fb.title,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: fb.isSynced ? Colors.green.withOpacity(0.08) : Colors.orange.withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        fb.isSynced
                                            ? (isRtl ? 'تم إنشاء التذكرة ✔️' : 'Ticket Created ✔️')
                                            : (isRtl ? 'في الانتظار ⏳' : 'Queued ⏳'),
                                        style: TextStyle(
                                          fontSize: 9,
                                          color: fb.isSynced ? Colors.green : Colors.orange,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(typeName, style: TextStyle(fontSize: 9.5, color: Colors.blue.shade800, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 2),
                                    Text(fb.message, style: const TextStyle(fontSize: 10.5, color: Color(0xFF475569))),
                                    const SizedBox(height: 4),
                                    Text(
                                      isRtl
                                          ? 'الحالة: ${_getTicketStatusLabel(fb.status, true)}'
                                          : 'Status: ${_getTicketStatusLabel(fb.status, false)}',
                                      style: const TextStyle(fontSize: 8.5, color: Color(0xFF0F75BC), fontWeight: FontWeight.bold),
                                    ),
                                    if (fb.adminReply != null && fb.adminReply!.trim().isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF8FAFC),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              isRtl ? 'رد الإدارة:' : 'Admin reply:',
                                              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              fb.adminReply!,
                                              style: const TextStyle(fontSize: 10, color: Color(0xFF1E293B)),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 4),
                                    Text(
                                      fb.createdAt.toLocal().toString().substring(0, 16),
                                      style: const TextStyle(fontSize: 8.5, color: Color(0xFF94A3B8)),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showSuccessDialog(BuildContext context, bool isRtl, bool isOnlineTransmitted) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Center(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isOnlineTransmitted ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isOnlineTransmitted ? Icons.check_circle_rounded : Icons.hourglass_top_rounded,
                  color: isOnlineTransmitted ? Colors.green : Colors.orange,
                  size: 40,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                isOnlineTransmitted 
                    ? (isRtl ? 'تم إنشاء التذكرة بنجاح!' : 'Ticket Created Successfully!')
                    : (isRtl ? 'تم الحفظ محلياً!' : 'Saved Locally!'),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        content: Text(
          isOnlineTransmitted
              ? (isRtl 
                  ? 'شكراً لك على تذكرة الدعم. تم إنشاء التذكرة للإدارة فوراً، وسيظهر الرد داخل التطبيق بمجرد متابعة المشرف.' 
                  : 'Thank you! Your support ticket has been created and will appear in the admin panel for follow-up.')
              : (isRtl
                  ? 'أنت خارج شبكة الإنترنت حالياً. تم حفظ ملاحظتك بأمان في طابور الانتظار المحلي، وسيتم مزامنتها تلقائياً بمجرد عودتك أونلاين.'
                  : 'You are currently offline. Your feedback is safely queued locally, and will be auto-synced as soon as connection is re-established.'),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 11, color: Color(0xFF475569), height: 1.5),
        ),
        actions: [
          Center(
            child: SizedBox(
              width: 120,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isOnlineTransmitted ? Colors.green : Colors.orange,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => Navigator.pop(context),
                child: Text(isRtl ? 'موافق' : 'OK', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ),
          )
        ],
      ),
    );
  }

  String _getTicketStatusLabel(String status, bool isRtl) {
    switch (status) {
      case 'in_progress':
        return isRtl ? 'قيد المعالجة' : 'In Progress';
      case 'closed':
        return isRtl ? 'مغلقة' : 'Closed';
      default:
        return isRtl ? 'مفتوحة' : 'Open';
    }
  }
}
