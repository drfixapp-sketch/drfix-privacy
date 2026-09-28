import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'forum_models_and_providers.dart';

class PostReviewDialog extends ConsumerStatefulWidget {
  final Map<String, String> txt;
  const PostReviewDialog({Key? key, required this.txt}) : super(key: key);

  @override
  ConsumerState<PostReviewDialog> createState() => _PostReviewDialogState();
}

class _PostReviewDialogState extends ConsumerState<PostReviewDialog> {
  final _name = TextEditingController();
  final _title = TextEditingController();
  final _desc = TextEditingController();
  String _selectedCat = 'أنظمة صناعية';
  bool _isSubmitting = false;
  final List<String> _profanityList = ['سياسة', 'شتم', 'اساءة', 'مسيء', 'انقلاب', 'fraud', 'abuse'];

  @override
  void initState() {
    super.initState();
    _loadSavedName();
  }

  Future<void> _loadSavedName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedName = prefs.getString('user_saved_name');
      if (savedName != null && savedName.isNotEmpty) {
        setState(() {
          _name.text = savedName;
        });
      }
    } catch (e) {
      debugPrint("Error loading saved name: $e");
    }
  }

  Future<void> _saveName(String name) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_saved_name', name);
    } catch (e) {
      debugPrint("Error saving name: $e");
    }
  }

  bool _hasProfanity(String text) {
    return _profanityList.any((word) => text.toLowerCase().contains(word));
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
      if (image != null) {
        ref.read(newPostProvider.notifier).updateImagePath(image.path);
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _title.dispose();
    _desc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(newPostProvider);
    final bool hasImg = formState.localImagePath != null;

    return Padding(
      padding: EdgeInsets.only(
        top: 20, 
        left: 16, 
        right: 16, 
        bottom: MediaQuery.of(context).viewInsets.bottom + 20
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.txt['pop_title']!, 
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F75BC))
            ),
            const SizedBox(height: 12),
            
            // 👤 حقل اسم الفني الشخصي
            TextField(
              controller: _name,
              decoration: const InputDecoration(
                hintText: 'أدخل اسمك الشخصي أو المهني...',
                hintStyle: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                border: OutlineInputBorder(),
              ),
              style: const TextStyle(fontSize: 14, fontFamily: 'Tajawal'),
            ),
            const SizedBox(height: 8),

            // 🔓 تم عزل وحذف حقل الرمز السري للمشرفين من هنا نهائياً لراحة الفنيين وتسهيل النشر للمراجعة
            // 📝 حقل عنوان العطل الفني
            TextField(
              controller: _title,
              decoration: InputDecoration(
                hintText: widget.txt['pop_topic_h']!,
                hintStyle: const TextStyle(fontSize: 11),
                border: const OutlineInputBorder()
              ),
              style: const TextStyle(fontSize: 14, fontFamily: 'Tajawal'),
            ),
            const SizedBox(height: 8),

            // 📝 حقل وصف المشكلة الفنية بالتفصيل
            TextField(
              controller: _desc,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: widget.txt['pop_desc_h']!,
                hintStyle: const TextStyle(fontSize: 11),
                border: const OutlineInputBorder()
              ),
              style: const TextStyle(fontSize: 14, fontFamily: 'Tajawal'),
            ),
            const SizedBox(height: 12),

            // 📁 قائمة اختيار قسم العطل الفني
            DropdownButtonFormField<String>(
              value: _selectedCat,
              items: [
                'أنظمة هيدروليك',
                'تكييف وتبريد',
                'كهرباء',
                'أنظمة صناعية',
                'أجهزة منزلية',
                'سيارات ومركبات',
                'سباكة',
                'أخرى'
              ].map((cat) => DropdownMenuItem(
                  value: cat,
                  child: Text(cat, style: const TextStyle(fontSize: 12))
                )).toList(),
              onChanged: (val) => _selectedCat = val!,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)
              ),
            ),
            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 📷 زر إرفاق صورة العطل الفني
                TextButton.icon(
                  onPressed: _pickImage,
                  icon: Icon(
                    hasImg ? Icons.check_circle : Icons.add_photo_alternate_rounded,
                    color: hasImg ? Colors.green : Colors.grey
                  ),
                  label: Text(
                    hasImg ? widget.txt['pop_img_ok']! : widget.txt['pop_img_btn']!,
                    style: const TextStyle(fontSize: 11)
                  ),
                ),

                // 🚀 زر الإرسال المطور المباشر لطابور المراجعة والاعتماد
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F75BC),
                    foregroundColor: Colors.white
                  ),
                  onPressed: _isSubmitting ? null : () async {
                    final titleText = _title.text.trim();
                    final descText = _desc.text.trim();

                    // 1️⃣ التحقق من تعبئة الحقول الأساسية المطلوبة للنشر
                    if (titleText.isEmpty || descText.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("يرجى ملء الحقول المطلوبة (العنوان والوصف)"))
                      );
                      return;
                    }

                    final nameText = _name.text.trim();
                    final authorName = nameText.isEmpty ? 'مجهول' : nameText;

                    // 2️⃣ الفحص الأمني للألفاظ والكلمات المحظورة لحماية بيئة المجتمع
                    if (_hasProfanity(titleText) || _hasProfanity(descText) || _hasProfanity(authorName)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("تحذير أمني: يحتوي المنشور على كلمات غير لائقة"))
                      );
                      return;
                    }

                    if (nameText.isNotEmpty) {
                      _saveName(nameText);
                    }

                    setState(() {
                      _isSubmitting = true;
                    });

                    // 3️⃣ 🔓 إرسال العطل مباشرة إلى طابور الانتظار (Pending Queue) مع رفع الصورة السحابية
                    try {
                      await ref.read(forumProvider.notifier).submitForReview(
                        author: authorName,
                        specialty: _selectedCat,
                        title: titleText,
                        description: descText,
                        category: _selectedCat,
                        imagePath: formState.localImagePath,
                      );

                      if (mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("تم إرسال العطل للمراجعة وسوف يظهر فور موافقة الأدمن بسلامة."),
                            backgroundColor: Colors.blue,
                          )
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        setState(() {
                          _isSubmitting = false;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("حدث خطأ أثناء الإرسال: $e"))
                        );
                      }
                    }
                  },
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          widget.txt['pop_submit']!,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)
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
