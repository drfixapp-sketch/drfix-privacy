import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dr_fix/data/models/community_post_model.dart';
import 'package:dr_fix/presentation/widgets/community_provider.dart';
import 'package:dr_fix/main.dart'; // central localeProvider
import 'package:dr_fix/presentation/widgets/custom_drawer.dart';

class PostDetailsScreen extends ConsumerStatefulWidget {
  final String postId;
  const PostDetailsScreen({Key? key, required this.postId}) : super(key: key);

  @override
  ConsumerState<PostDetailsScreen> createState() => _PostDetailsScreenState();
}

class _PostDetailsScreenState extends ConsumerState<PostDetailsScreen> {
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  bool _isExpertComment = false; // toggle for simulating expert posting

  @override
  void dispose() {
    _commentController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _submitComment(CommunityPost post, bool isRtl) {
    final commentText = _commentController.text.trim();
    if (commentText.isEmpty) return;

    final author = _nameController.text.trim();
    final authorName = author.isEmpty ? (isRtl ? 'عضو مجهول' : 'Anonymous Member') : author;

    // Trigger state notifier update in Riverpod immediately
    ref.read(communityProvider.notifier).addComment(
          post.id,
          authorName: authorName,
          text: commentText,
          isExpert: _isExpertComment,
        );

    // Clear and show toast
    _commentController.clear();
    setState(() {
      _isExpertComment = false; // Reset toggle
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isRtl ? '✅ تم نشر تعليقك فوراً في المجتمع!' : '✅ Your comment was posted instantly!',
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1E293B),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isRtl = ref.watch(localeProvider).languageCode == 'ar';
    final communityState = ref.watch(communityProvider);

    // Find the current live post from the state to ensure immediate UI updates when comment is added
    final post = communityState.posts.firstWhere(
      (p) => p.id == widget.postId,
      orElse: () => CommunityPost(
        id: 'fallback',
        systemType: 'HVAC',
        deviceModel: 'Unknown Device',
        issueDescription: 'Not found',
        successfulSolution: '',
        approximateCost: '',
        comments: [],
        createdAt: DateTime.now(),
      ),
    );

    if (post.id == 'fallback') {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Post not found')),
      );
    }

    final String difficultyTitle = isRtl ? 'درجة تعقيد العطل وصعوبة الحل' : 'Fault Complexity & Repair Level';
    final String solutionTitle = isRtl ? '🛠️ الحل الناجح والخطوات الهندسية المتبعة' : '🛠️ Successful Solution & Engineering Steps';
    final String commentsHeader = isRtl ? '💬 نقاشات المجتمع والخبرات الميدانية' : '💬 Community Discussions & Field Feedback';
    final String addCommentTitle = isRtl ? 'أضف تعليقك الفني أو استفسارك:' : 'Add technical comment or question:';
    final String postCommentButton = isRtl ? 'نشر التعليق فوراً' : 'Post Comment';
    final String authorLabel = isRtl ? 'الكاتب: ' : 'Author: ';
    final String costLabel = isRtl ? 'الميزانية التقريبية: ' : 'Approx. Budget: ';
    final String inputNameHint = isRtl ? 'اسمك أو لقبك الفني (اختياري)' : 'Your name or signature (optional)';
    final String inputCommentHint = isRtl ? 'اكتب تفاصيل تعليقك أو نصيحة فنية إضافية...' : 'Write comment or technical tips...';
    final String expertToggleText = isRtl ? 'التعليق كخبير معتمد (تفعيل وسام الخبراء ⭐)' : 'Comment as certified expert (Show Expert Badge ⭐)';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: const CustomAppDrawer(),
      appBar: AppBar(
        title: Text(
          isRtl ? 'تفاصيل العطل والحل الموثق' : 'Fault & Verified Solution',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0.5,
        automaticallyImplyLeading: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Core Post Info Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2)),
                  ],
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // System Badge and Verification
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
                            post.systemType,
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0F75BC)),
                          ),
                        ),
                        if (post.isVerified)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFBBF7D0)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.verified_rounded, color: Color(0xFF15803D), size: 12),
                                const SizedBox(width: 4),
                                Text(
                                  isRtl ? 'حل موثق من الخبراء ✔️' : 'Verified Solution ✔️',
                                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Device Model Title
                    Text(
                      post.deviceModel,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                    ),
                    const SizedBox(height: 8),

                    // Metadata
                    Row(
                      children: [
                        const Icon(Icons.person_outline_rounded, size: 12, color: Color(0xFF64748B)),
                        const SizedBox(width: 4),
                        Text(
                          '$authorLabel${post.authorName}',
                          style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                        ),
                        const SizedBox(width: 16),
                        const Icon(Icons.monetization_on_outlined, size: 12, color: Colors.green),
                        const SizedBox(width: 4),
                        Text(
                          '$costLabel${post.approximateCost}',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green),
                        ),
                      ],
                    ),
                    const Divider(height: 24, color: Color(0xFFF1F5F9)),

                    // Issue Description
                    const Text(
                      '🚨 وصف العطل والمشكلة:',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      post.issueDescription,
                      style: const TextStyle(fontSize: 11.5, color: Color(0xFF1E293B), height: 1.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 2. Verified Solutions Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2)),
                  ],
                  border: Border.all(color: const Color(0xFFBBF7D0)), // subtle green highlight
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      solutionTitle,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      post.successfulSolution,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF1E293B), height: 1.6),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 3. Comments section
              Row(
                children: [
                  const Icon(Icons.forum_outlined, size: 16, color: Color(0xFF1E293B)),
                  const SizedBox(width: 8),
                  Text(
                    commentsHeader,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Comment Feed List
              if (post.comments.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Center(
                    child: Text(
                      isRtl ? 'لا توجد تعليقات بعد. كن أول من يشارك رأيه الهندسي!' : 'No comments yet. Be the first to share your input!',
                      style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold),
                    ),
                  ),
                )
              else
                ...post.comments.map((comment) {
                  return Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: comment.isExpert ? const Color(0xFFF0FDF4) : Colors.white, // Custom background for expert
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: comment.isExpert ? const Color(0xFF22C55E) : const Color(0xFFE2E8F0), // Green border for expert comments
                        width: comment.isExpert ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 12,
                                  backgroundColor: comment.isExpert ? const Color(0xFF22C55E) : const Color(0xFF94A3B8),
                                  child: Icon(
                                    comment.isExpert ? Icons.star_rounded : Icons.person_rounded,
                                    size: 12,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  comment.authorName,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: comment.isExpert ? const Color(0xFF15803D) : const Color(0xFF1E293B),
                                  ),
                                ),
                                if (comment.isExpert) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFDCFCE7),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.verified_rounded, color: Color(0xFF15803D), size: 10),
                                        const SizedBox(width: 2),
                                        Text(
                                          isRtl ? 'خبير معتمد' : 'Verified Expert',
                                          style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            Text(
                              '${comment.createdAt.hour}:${comment.createdAt.minute}',
                              style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          comment.text,
                          style: const TextStyle(fontSize: 11, color: Color(0xFF334155), height: 1.4),
                        ),
                      ],
                    ),
                  );
                }).toList(),

              const SizedBox(height: 16),

              // Add Comment Box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      addCommentTitle,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                    ),
                    const SizedBox(height: 10),

                    // Name Input
                    TextField(
                      controller: _nameController,
                      style: const TextStyle(fontSize: 11),
                      decoration: InputDecoration(
                        hintText: inputNameHint,
                        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Comment Input
                    TextField(
                      controller: _commentController,
                      maxLines: 3,
                      style: const TextStyle(fontSize: 11),
                      decoration: InputDecoration(
                        hintText: inputCommentHint,
                        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Expert Simulation Switch
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            expertToggleText,
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                          ),
                        ),
                        Switch(
                          value: _isExpertComment,
                          activeColor: const Color(0xFF22C55E),
                          onChanged: (val) {
                            setState(() {
                              _isExpertComment = val;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 38,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F75BC),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                        onPressed: () => _submitComment(post, isRtl),
                        child: Text(
                          postCommentButton,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    ),
  );
  }
}
