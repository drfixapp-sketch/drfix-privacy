import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'forum_models_and_providers.dart';

class ForumDetailsScreen extends ConsumerStatefulWidget {
  final ForumPost? post;
  final String? postId;
  const ForumDetailsScreen({Key? key, this.post, this.postId}) : super(key: key);

  @override
  ConsumerState<ForumDetailsScreen> createState() => _ForumDetailsScreenState();
}

class _ForumDetailsScreenState extends ConsumerState<ForumDetailsScreen> {
  final TextEditingController _replyController = TextEditingController();
  final TextEditingController _technicalNameController = TextEditingController();
  final TextEditingController _experienceController = TextEditingController();

  @override
  void dispose() {
    _replyController.dispose();
    _technicalNameController.dispose();
    _experienceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allPosts = ref.watch(forumProvider);
    final currentPost = widget.post ?? (allPosts.where((p) => p.id == widget.postId).isNotEmpty ? allPosts.firstWhere((p) => p.id == widget.postId) : null);

    if (currentPost == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('تفاصيل المنشور', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Tajawal')),
          backgroundColor: const Color(0xFF1E293B),
          foregroundColor: Colors.white,
        ),
        body: const Center(child: Text('لم يتم العثور على المنشور المطلوب.', style: TextStyle(fontFamily: 'Tajawal'))),
      );
    }

    final approvedReplies = currentPost.replies.where((reply) => reply.isApproved).toList();

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 450),
        child: Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            title: const Text("تفاصيل العطل والخبرات والردود", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Tajawal')),
            elevation: 0,
            backgroundColor: const Color(0xFF1E293B),
            foregroundColor: Colors.white,
          ),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(currentPost.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87, fontFamily: 'Tajawal')),
                        const SizedBox(height: 8),
                        Text("بواسطة: ${currentPost.author} (${currentPost.specialty})", style: const TextStyle(color: Colors.grey, fontSize: 12, fontFamily: 'Tajawal')),
                        const Divider(height: 24),
                        Text(currentPost.description, style: const TextStyle(fontSize: 14, height: 1.5, color: Colors.black87, fontFamily: 'Tajawal')),
                        // ✅ عارض الصورة المرفقة — محمي بـ kIsWeb guard لمنع UnsupportedError على الويب
                        if (currentPost.imageUrl != null && currentPost.imageUrl!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 12.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                currentPost.imageUrl!,
                                width: double.infinity,
                                fit: BoxFit.contain,
                                loadingBuilder: (context, child, progress) {
                                  if (progress == null) return child;
                                  return Container(
                                    height: 180,
                                    color: Colors.grey.shade100,
                                    child: const Center(
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) => Container(
                                  height: 100,
                                  color: Colors.grey.shade100,
                                  child: const Center(
                                    child: Icon(Icons.broken_image_rounded, color: Colors.grey, size: 36),
                                  ),
                                ),
                              ),
                            ),
                          )
                        else if (currentPost.localImagePath != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 12.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              // 🛡️ kIsWeb guard: File() غير مدعوم على Flutter Web → Placeholder آمن
                              child: kIsWeb
                                  ? Container(
                                      width: double.infinity,
                                      height: 180,
                                      color: const Color(0xFFF1F5F9),
                                      child: const Center(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.image_rounded, color: Color(0xFF94A3B8), size: 36),
                                            SizedBox(height: 6),
                                            Text(
                                              'الصورة متاحة على التطبيق',
                                              style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontFamily: 'Tajawal'),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                  : Image.file(
                                      File(currentPost.localImagePath!),
                                      width: double.infinity,
                                      fit: BoxFit.contain,
                                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                                    ),
                            ),
                          ),
                        const SizedBox(height: 24),
                        // 📡 استماع حي للردود المعتمدة من Subcollection السحابية
                        Consumer(
                          builder: (context, ref, child) {
                            final repliesAsync = ref.watch(liveApprovedRepliesStreamProvider(currentPost.id));
                            return repliesAsync.when(
                              data: (liveReplies) {
                                final repliesToShow = liveReplies.isNotEmpty ? liveReplies : approvedReplies;
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "الردود الفنية المعتمدة (${repliesToShow.length})",
                                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F75BC), fontFamily: 'Tajawal'),
                                    ),
                                    const SizedBox(height: 12),
                                    if (repliesToShow.isEmpty)
                                      const Text("لا توجد ردود معتمدة بعد.", style: TextStyle(fontSize: 13, color: Colors.grey, fontFamily: 'Tajawal'))
                                    else
                                      ListView.builder(
                                        shrinkWrap: true,
                                        physics: const NeverScrollableScrollPhysics(),
                                        itemCount: repliesToShow.length,
                                        itemBuilder: (context, index) {
                                          final reply = repliesToShow[index];
                                          return Container(
                                            padding: const EdgeInsets.all(12),
                                            margin: const EdgeInsets.only(bottom: 8),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
                                            ),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Text(reply.author, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F75BC), fontFamily: 'Tajawal')),
                                                    Text(reply.specialty, style: const TextStyle(fontSize: 11, color: Colors.grey, fontFamily: 'Tajawal')),
                                                  ],
                                                ),
                                                const SizedBox(height: 6),
                                                Text(reply.content, style: const TextStyle(fontSize: 13, height: 1.4, color: Colors.black87, fontFamily: 'Tajawal')),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                  ],
                                );
                              },
                              loading: () => Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("الردود الفنية المعتمدة (${approvedReplies.length})", style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F75BC), fontFamily: 'Tajawal')),
                                  const SizedBox(height: 12),
                                  const Center(child: Padding(padding: EdgeInsets.all(12.0), child: CircularProgressIndicator(strokeWidth: 2))),
                                ],
                              ),
                              error: (e, _) => Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("الردود الفنية المعتمدة (${approvedReplies.length})", style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F75BC), fontFamily: 'Tajawal')),
                                  const SizedBox(height: 8),
                                  Text("تعذر جلب البث المباشر للردود: $e", style: const TextStyle(color: Colors.red, fontSize: 11)),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey.withValues(alpha: 0.2)))),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: _technicalNameController,
                        decoration: const InputDecoration(
                          hintText: "اسم الفني أو التخصص الهندسي",
                          border: OutlineInputBorder(),
                          hintStyle: TextStyle(fontSize: 13, fontFamily: 'Tajawal'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _experienceController,
                        decoration: const InputDecoration(
                          hintText: "سنوات الخبرة / المهارة",
                          border: OutlineInputBorder(),
                          hintStyle: TextStyle(fontSize: 13, fontFamily: 'Tajawal'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _replyController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText: "اكتب الحل الهندسي المقترح أو الخبرة العملية...",
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Color(0xFFF8FAFC),
                          hintStyle: TextStyle(fontSize: 13, fontFamily: 'Tajawal'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F75BC), foregroundColor: Colors.white),
                          icon: const Icon(Icons.send_rounded, size: 18),
                          label: const Text("إرسال الرد الهندسي", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'Tajawal')),
                          onPressed: () {
                            final name = _technicalNameController.text.trim();
                            final experience = _experienceController.text.trim();
                            final solution = _replyController.text.trim();

                            if (solution.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى إدخال نص الحل الهندسي أولاً')));
                              return;
                            }

                            ref.read(forumProvider.notifier).addPendingReply(
                              currentPost.id,
                              name.isEmpty ? 'فني مستضيف' : name,
                              experience.isEmpty ? 'مهارة غير محددة' : experience,
                              solution,
                            );

                            _replyController.clear();
                            _technicalNameController.clear();
                            _experienceController.clear();
                            FocusScope.of(context).unfocus();

                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إرسال ردك الهندسي المطور لطابور مراجعة الإدارة بنجاح')));
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
