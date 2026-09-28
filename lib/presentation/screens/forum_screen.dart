import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dr_fix/main.dart';
import 'package:dr_fix/presentation/widgets/forum_models_and_providers.dart';
import 'package:dr_fix/presentation/screens/community_dashboard_screen.dart';
import 'package:dr_fix/presentation/widgets/post_review_dialog.dart';
import 'package:dr_fix/presentation/widgets/custom_drawer.dart';
import 'package:dr_fix/presentation/widgets/forum_details_screen.dart';
import 'package:dr_fix/presentation/screens/admin_lock_screen.dart';

class ForumScreen extends ConsumerWidget {
  const ForumScreen({Key? key}) : super(key: key);

  void _showAddQuestionSheet(BuildContext context, WidgetRef ref, Map<String, String> txt) {
    ref.read(newPostProvider.notifier).reset();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => PostReviewDialog(txt: txt),
    );
  }

  void _checkAdminAccess(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AdminLockScreen()),
    );
  }

  Widget _buildFilterChip(WidgetRef ref, String label, String value, String selectedValue) {
    final isSelected = selectedValue == value;
    return FilterChip(
      label: Text(label, style: const TextStyle(fontFamily: 'Tajawal', fontSize: 12)),
      selected: isSelected,
      onSelected: (_) => ref.read(forumCategoryFilterProvider.notifier).state = value,
      backgroundColor: Colors.grey.shade100,
      selectedColor: const Color(0xFF0F75BC).withValues(alpha: 0.12),
      checkmarkColor: const Color(0xFF0F75BC),
      side: BorderSide(color: isSelected ? const Color(0xFF0F75BC) : Colors.grey.shade300),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localeState = ref.watch(localeProvider);
    final bool isRtl = localeState.languageCode == 'ar';

    final Map<String, String> txtAr = {
      'header_t': '💬 زاوية مجتمع تبادل الخبرات',
      'header_d': '👥 يوجد الآن 1436 فني متصل جاهز للمساعدة',
      'search_h': 'ابحث عن عطل أو منشور هندسي', 'filter_all': 'الكل', 'filter_hyd': 'هيدروليك', 'filter_hvac': 'تكييف', 'filter_elec': 'كهرباء', 'filter_ind': 'صناعي', 'filter_home': 'منزلي', 'filter_auto': 'سيارات', 'filter_plumb': 'سباكة', 'filter_other': 'أخرى',
      'sort_new': 'الأحدث', 'sort_view': 'الأكثر مشاهدة', 'sort_vote': 'الأعلى تقييماً', 'suggest_lbl': '💡 اقتراحات بحث مطابقة', 'fab_lbl': 'طرح عطل',
      'pop_title': '📥 إضافة ونشر عطل جديد بمجتمع الخبرات', 'pop_name_h': 'اسمك الكريم أو لقبك الفني الفعلي', 'pop_badge_h': 'تخصصك الميداني الفعلي', 'pop_topic_h': 'عنوان العطل والمشكلة باختصار وإيجاز', 'pop_desc_h': 'وصف المشكلة الهندسية بالتفصيل ليتسنى فحصها', 'pop_img_btn': 'إرفاق صورة العطل محلياً', 'pop_img_ok': 'تم إرفاق صورة العطل بنجاح', 'pop_submit': 'نشر وتعميم العطل حياً',
    };

    final Map<String, String> txtEn = {
      'header_t': '💬 Forum Base', 'header_d': '👥 1436 Live Online', 'search_h': 'Search engineering faults',
      'filter_all': 'All', 'filter_hyd': 'Hydraulics', 'filter_hvac': 'HVAC', 'filter_elec': 'Electrical', 'filter_ind': 'Industrial', 'filter_home': 'Appliances', 'filter_auto': 'Automotive', 'filter_plumb': 'Plumbing', 'filter_other': 'Other',
      'sort_new': 'Newest', 'sort_view': 'Most Viewed', 'sort_vote': 'Top Rated', 'suggest_lbl': 'Suggestions', 'fab_lbl': 'Post Fault',
      'pop_title': 'Post New Fault', 'pop_name_h': 'Your name signature', 'pop_badge_h': 'Your specialty expert', 'pop_topic_h': 'Summary of breakdown', 'pop_desc_h': 'Describe failure details', 'pop_img_btn': 'Attach Photo', 'pop_img_ok': 'Photo Attached', 'pop_submit': 'Publish Live',
    };

    final Map<String, String> txt = isRtl ? txtAr : txtEn;
    final livePostsAsync = ref.watch(liveApprovedForumPostsStreamProvider);
    final localPosts = ref.watch(forumProvider);
    final List<ForumPost> posts = livePostsAsync.maybeWhen(
      data: (liveList) {
        if (liveList.isEmpty) return localPosts;
        final list = List<ForumPost>.from(liveList);
        for (final p in localPosts) {
          if (!list.any((item) => item.id == p.id)) {
            list.add(p);
          }
        }
        return list;
      },
      orElse: () => localPosts,
    );
    final searchQuery = ref.watch(forumSearchProvider);
    final categoryFilter = ref.watch(forumCategoryFilterProvider);

    final filteredPosts = posts.where((post) {
      if (!post.isApproved) {
        return false;
      }

      final matchesSearch = searchQuery.isEmpty ||
          post.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
          post.description.toLowerCase().contains(searchQuery.toLowerCase()) ||
          post.category.toLowerCase().contains(searchQuery.toLowerCase());

      final matchesCategory = categoryFilter == 'all' ||
          categoryFilter == 'الكل' ||
          post.category.toLowerCase().contains(categoryFilter.toLowerCase()) ||
          post.title.toLowerCase().contains(categoryFilter.toLowerCase());

      return matchesSearch && matchesCategory;
    }).toList();

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        drawer: const CustomAppDrawer(),
        appBar: AppBar(
          title: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(txt['header_t']!, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
              Text(txt['header_d']!, style: const TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.w600)),
            ],
          ),
          centerTitle: true,
          backgroundColor: Colors.white,
          elevation: 0.5,
          automaticallyImplyLeading: true,
          actions: [
            GestureDetector(
              onLongPress: () => _checkAdminAccess(context),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Icon(Icons.admin_panel_settings_rounded, color: Colors.grey.shade400, size: 22),
              ),
            )
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: const Color(0xFF0F75BC),
          onPressed: () => _showAddQuestionSheet(context, ref, txt),
          icon: const Icon(Icons.add_comment_rounded, color: Colors.white, size: 18),
          label: Text(txt['fab_lbl']!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
        ),
        body: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 450),
            color: Colors.white,
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      txt['header_t']!,
                      style: const TextStyle(fontFamily: 'Tajawal', fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F75BC)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      txt['header_d']!,
                      style: const TextStyle(fontFamily: 'Tajawal', fontSize: 12, color: Colors.green, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const CommunityDashboardScreen()),
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F75BC),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isRtl ? "موسوعة الأعطال الموثقة" : "Documented Faults Encyclopedia",
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontFamily: 'Tajawal', fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFCFAF5),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 14,
                            offset: const Offset(0, 8),
                          ),
                        ],
                        border: Border.all(color: const Color(0xFFF2E6C2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.emoji_events_rounded, color: Color(0xFFB8860B), size: 18),
                              SizedBox(width: 6),
                              Text(
                                'الخبير المتميز اليوم',
                                style: TextStyle(fontFamily: 'Tajawal', fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F766E)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'م. يوسف محمد',
                            style: TextStyle(fontFamily: 'Tajawal', fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Text('🌟 4.9', style: TextStyle(fontFamily: 'Tajawal', fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFB8860B))),
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFECFDF5),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(color: const Color(0xFF86EFAC)),
                                ),
                                child: const Text(
                                  'خبير أنظمة معتمد',
                                  style: TextStyle(fontFamily: 'Tajawal', fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'ساهم في حل أكثر من 342 عطل موثق',
                            style: TextStyle(fontFamily: 'Tajawal', fontSize: 12, color: Color(0xFF475569)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      onChanged: (value) => ref.read(forumSearchProvider.notifier).state = value,
                      decoration: InputDecoration(
                        hintText: txt['search_h'],
                        prefixIcon: const Icon(Icons.search_rounded, size: 18),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      style: const TextStyle(fontFamily: 'Tajawal', fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: [
                        _buildFilterChip(ref, txt['filter_all']!, 'all', categoryFilter),
                        _buildFilterChip(ref, txt['filter_hyd']!, 'هيدروليك', categoryFilter),
                        _buildFilterChip(ref, txt['filter_hvac']!, 'تكييف', categoryFilter),
                        _buildFilterChip(ref, txt['filter_elec']!, 'كهرباء', categoryFilter),
                        _buildFilterChip(ref, txt['filter_ind']!, 'صناعي', categoryFilter),
                        _buildFilterChip(ref, txt['filter_home']!, 'أجهزة منزلية', categoryFilter),
                        _buildFilterChip(ref, txt['filter_auto']!, 'سيارات', categoryFilter),
                        _buildFilterChip(ref, txt['filter_plumb']!, 'سباكة', categoryFilter),
                        _buildFilterChip(ref, txt['filter_other']!, 'أخرى', categoryFilter),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      txt['suggest_lbl']!,
                      style: const TextStyle(fontFamily: 'Tajawal', fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                    ),
                    const SizedBox(height: 8),
                    if (filteredPosts.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10)),
                        child: Text(
                          isRtl ? 'لا توجد منشورات حالياً في هذا القسم.' : 'No posts are available in this section yet.',
                          style: const TextStyle(fontFamily: 'Tajawal', fontSize: 13, color: Colors.grey),
                        ),
                      )
                    else
                      ...filteredPosts.map((post) => InkWell(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => ForumDetailsScreen(postId: post.id)),
                        ),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ── الصف العلوي: العنوان + شارة المراجعة ──
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      post.title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontFamily: 'Tajawal', fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F75BC)),
                                    ),
                                  ),
                                  if (!post.isApproved)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(999)),
                                      child: Text(
                                        isRtl ? 'قيد المراجعة' : 'Pending',
                                        style: const TextStyle(fontFamily: 'Tajawal', fontSize: 10, color: Colors.orange),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 5),
                              // ── اسم الكاتب + التخصص ──
                              Text(
                                '${post.author} • ${post.specialty}',
                                style: const TextStyle(fontFamily: 'Tajawal', fontSize: 11, color: Colors.grey),
                              ),
                              const SizedBox(height: 8),
                              // ── الصف السفلي: التصنيف + العدادات + سهم التفاصيل ──
                              Row(
                                children: [
                                  // تصنيف القسم
                                  if (post.category.isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0F75BC).withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(post.category, style: const TextStyle(fontFamily: 'Tajawal', color: Color(0xFF0F75BC), fontSize: 10, fontWeight: FontWeight.bold)),
                                    ),
                                  const SizedBox(width: 8),
                                  // عدد الردود
                                  const Icon(Icons.chat_bubble_outline_rounded, size: 13, color: Colors.blue),
                                  const SizedBox(width: 3),
                                  Text('${post.replies.length}', style: const TextStyle(fontFamily: 'Tajawal', fontSize: 11, color: Colors.blue)),
                                  const SizedBox(width: 8),
                                  // عدد المشاهدات
                                  const Icon(Icons.visibility_outlined, size: 13, color: Colors.grey),
                                  const SizedBox(width: 3),
                                  Text('${post.views}', style: const TextStyle(fontFamily: 'Tajawal', fontSize: 11, color: Colors.grey)),
                                  const Spacer(),
                                  // سهم التفاصيل
                                  Icon(
                                    isRtl ? Icons.arrow_back_ios_rounded : Icons.arrow_forward_ios_rounded,
                                    size: 13,
                                    color: Colors.grey.shade400,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      )).toList(),
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
