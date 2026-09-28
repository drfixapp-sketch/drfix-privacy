import 'package:flutter/material.dart';

/// [المكون 1]: شريط الرد السفلي المطور والمدمج بصفحة التفاصيل لمجتمع الخبرات
/// يدمج حقل الاسم التفاعلي الذكي قبل كتابة التجربة دون كسر التوزيع البصري
class ExpandableReplyDock extends StatefulWidget {
  final String postId;
  const ExpandableReplyDock({Key? key, required this.postId}) : super(key: key);

  @override
  State<ExpandableReplyDock> createState() => _ExpandableReplyDockState();
}

class _ExpandableReplyDockState extends State<ExpandableReplyDock> {
  final _nameController = TextEditingController();
  final _replyController = TextEditingController();
  bool _isExpanded = false; // التحكم في تمدد الشريط لإظهار حقل الاسم الفني

  @override
  void dispose() {
    _nameController.dispose();
    _replyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, -2))
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // حقل الاسم المقترح يظهر ديناميكياً لتوفير المساحة عند بدء التفاعل فقط
            if (_isExpanded) ...[
              TextFormField(
                controller: _nameController,
                textDirection: TextDirection.rtl,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'اسم المهندس أو اللقب الفني (اختياري)...',
                  prefixIcon: const Icon(Icons.person_outline, size: 20),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                ),
              ),
              const SizedBox(height: 8),
            ],
            
            // شريط الإدخال الرئيسي المباشر المطابق للواجهة الحالية
            Row(
              children: [
                // سهم الإرسال والتوجيه لصفحة تحكم الأدمن بحالة معلقة (Pending)
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.blue, size: 26),
                  onPressed: () {
                    final replyText = _replyController.text.trim();
                    if (replyText.isNotEmpty) {
                      // جمع البيانات وتوجيهها للمستودع الإداري المراجِع
                      // ref.read(adminModerationProvider.notifier).submitReply(
                      //   postId: widget.postId,
                      //   name: _nameController.text.trim().isEmpty ? 'فني مجهول' : _nameController.text.trim(),
                      //   content: replyText,
                      // );
                      
                      _replyController.clear();
                      _nameController.clear();
                      setState(() => _isExpanded = false);
                      FocusScope.of(context).unfocus(); // إغلاق لوحة المفاتيح
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('🎉 تم إرسال ردك بنجاح، بانتظار موافقة واعتماد مدير النظام حياً'),
                          backgroundColor: Colors.blue,
                        ),
                      );
                    }
                  },
                ),
                
                // حقل كتابة الرد الهندسي والخبرات الميدانية
                Expanded(
                  child: TextFormField(
                    controller: _replyController,
                    textDirection: TextDirection.rtl,
                    style: const TextStyle(fontSize: 14),
                    onTap: () {
                      if (!_isExpanded) {
                        setState(() => _isExpanded = true);
                      }
                    },
                    decoration: const InputDecoration(
                      hintText: 'اكتب تجربتك أو حلك الهندسي المقترح للفني هنا...',
                      hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// [المكون 2]: كرت العرض الشرطي للأكواد والخصومات الجغرافية للموردين والشركات
/// يحجب القسم تماماً إذا كانت القائمة خالية لحفظ المظهر النظيف ومنع المساحات البيضاء
class ConditionalPromoGrid extends StatelessWidget {
  final List<dynamic> activePromoCodes; // مصفوفة الأكواد النشطة المستلمة من السيرفر
  const ConditionalPromoGrid({Key? key, required this.activePromoCodes}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // خط الدفاع البصري: إذا لم يقم الأدمن بتفعيل أي أكواد، يختفي الودجيت بالكامل من شاشة الفني
    if (activePromoCodes.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      color: const Color(0xFFE3F2FD), // لون أزرق لوجستي خفيف متناسق مع كرت الصيانة
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.blue.shade200, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.local_offer_outlined, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'أكواد الخصم والتعاقدات الحصرية المفعلة لك:',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blue),
                ),
              ],
            ),
            const Divider(color: Colors.blue, height: 16),
            Column(
              children: activePromoCodes.map((promo) {
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListTile(
                    dense: true,
                    title: Text(
                      'مورد معتمد: ${promo['company_name'] ?? "شركة صيانة"}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                    ),
                    subtitle: Text(
                      'كود الخصم الميداني: ${promo['code'] ?? ""}',
                      style: const TextStyle(color: Colors.blueGrey, fontSize: 12),
                    ),
                    trailing: Text(
                      '%${promo['discount_percentage'] ?? "0"}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
