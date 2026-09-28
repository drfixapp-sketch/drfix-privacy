import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dr_fix/main.dart';
import 'package:dr_fix/presentation/widgets/custom_drawer.dart';
import 'package:dr_fix/presentation/widgets/community_provider.dart';
import 'package:dr_fix/data/models/community_post_model.dart';
import 'package:dr_fix/data/models/verified_fault_model.dart';
import 'package:dr_fix/presentation/providers/verified_faults_provider.dart';
import 'package:dr_fix/presentation/screens/verified_fault_detail_screen.dart';

class CommunityDashboardContent extends ConsumerStatefulWidget {
  final bool showPostFeed;

  const CommunityDashboardContent({Key? key, this.showPostFeed = true}) : super(key: key);

  @override
  ConsumerState<CommunityDashboardContent> createState() => _CommunityDashboardContentState();
}

class _CommunityDashboardContentState extends ConsumerState<CommunityDashboardContent> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isRtl = ref.watch(localeProvider).languageCode == 'ar';
    // أعطال موثقة من التشخيص الذكي — تتحدث فور موافقة الأدمن
    final List<CommunityPost> aiVerifiedPosts = ref.watch(filteredCommunityPostsProvider)
        .where((CommunityPost p) => p.id.startsWith('kb_'))
        .toList();
    final String searchText = _searchController.text.trim();
    final String kbSearchText = searchText.toLowerCase();
    final List<CommunityPost> filteredKbPosts = aiVerifiedPosts.where((CommunityPost post) {
      if (kbSearchText.isEmpty) return true;
      final String haystack = '${post.deviceModel} ${post.systemType} ${post.issueDescription}'.toLowerCase();
      return haystack.contains(kbSearchText);
    }).toList();

    final List<VerifiedFault> filteredFaults = ref.watch(filteredVerifiedFaultsProvider);
    final String activeTag = ref.watch(verifiedFaultsSelectedSectorProvider);

    final String philosophyTitle = isRtl ? 'قاعدة معرفية تقنية مختصرة' : 'Compact technical knowledge base';
    final String philosophyBody = isRtl
        ? 'موسوعة موثقة ومختصرة لتسريع التعرّف على الأعطال الشائعة، مع بيانات تشغيلية واضحة ومحدثة دون أي محتوى شخصي أو نقاشات غير تقنية.'
        : 'A concise, documented encyclopedia for faster recognition of common faults, with clear operating notes and no personal or non-technical discussion.';
    final String searchHint = isRtl ? 'ابحث في الشركة، الجهاز، العطل أو النظام' : 'Search by manufacturer, device, fault or system';
    final String headerLabel = isRtl ? 'أحدث حالات الاعتماد الموثقة' : 'Latest verified cases';

    final tags = ['الكل', 'صناعي', 'كهرباء', 'ميكانيك', 'أنظمة الهيدروليك', 'أجهزة منزلية', 'تبريد وتكييف', 'سيارات ومركبات', 'سباكة', 'أخرى'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                philosophyTitle,
                style: const TextStyle(fontFamily: 'Tajawal', fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 6),
              Text(
                philosophyBody,
                style: const TextStyle(fontFamily: 'Tajawal', fontSize: 12, height: 1.5, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _searchController,
          textAlign: isRtl ? TextAlign.right : TextAlign.left,
          style: const TextStyle(fontFamily: 'Tajawal', fontSize: 13),
          onChanged: (val) {
            ref.read(verifiedFaultsSearchQueryProvider.notifier).state = val;
          },
          decoration: InputDecoration(
            hintText: searchHint,
            prefixIcon: const Icon(Icons.search_rounded, size: 18),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: tags.map((String tag) {
            final selected = activeTag == tag;
            return ChoiceChip(
              label: Text(tag, style: const TextStyle(fontFamily: 'Tajawal', fontSize: 12)),
              selected: selected,
              onSelected: (_) {
                ref.read(verifiedFaultsSelectedSectorProvider.notifier).state = tag;
              },
              selectedColor: const Color(0xFF0F75BC).withOpacity(0.12),
              side: BorderSide(color: selected ? const Color(0xFF0F75BC) : const Color(0xFFE2E8F0)),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              headerLabel,
              style: const TextStyle(fontFamily: 'Tajawal', fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            Text(
              '(${filteredFaults.length})',
              style: const TextStyle(fontFamily: 'Tajawal', fontSize: 12, color: Color(0xFF0F75BC), fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (filteredFaults.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Text(
              isRtl ? 'لا توجد نتائج تطابق البحث الحالي.' : 'No results match the current search.',
              style: const TextStyle(fontFamily: 'Tajawal', fontSize: 12, color: Colors.grey),
            ),
          )
        else
          ...filteredFaults.map((VerifiedFault fault) {
            final bool canManageFault = VerifiedFaultsAdminService.canManageFault(fault);
            return InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => VerifiedFaultDetailScreen(fault: fault),
                ),
              ),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── الصف العلوي: معتمد + الكاتب + أدوات الأدمن ──
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.verified_rounded, color: Color(0xFF0F75BC), size: 16),
                            const SizedBox(width: 6),
                            Text(
                              fault.authorName,
                              style: const TextStyle(fontFamily: 'Tajawal', fontSize: 11, color: Color(0xFF0F75BC), fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        if (canManageFault)
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_rounded, color: Colors.amber, size: 18),
                                tooltip: isRtl ? 'تعديل العطل' : 'Edit Fault',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () => _showEditFaultDialog(context, fault, isRtl),
                              ),
                              const SizedBox(width: 10),
                              IconButton(
                                icon: const Icon(Icons.delete_forever_rounded, color: Colors.red, size: 18),
                                tooltip: isRtl ? 'حذف العطل' : 'Delete Fault',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () => _confirmHardDeleteFault(context, fault, isRtl),
                              ),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // ── عنوان العطل (سطران كحد أقصى) ──
                    Text(
                      fault.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontFamily: 'Tajawal', fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 8),
                    // ── الصف السفلي: القطاع + المشاهدات + سهم التفاصيل ──
                    Row(
                      children: [
                        _buildMetaChip(fault.sector),
                        const SizedBox(width: 6),
                        _buildMetaChip('${fault.viewsCount} ${isRtl ? 'مشاهدة' : 'views'}'),
                        const Spacer(),
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
            );
          }).toList(),
        // ── قسم الأعطال الموثقة من التشخيص الذكي ──────────────────────
        // يظهر فقط بعد موافقة الأدمن على طلبات [KB] — يتحدث تلقائياً
        if (aiVerifiedPosts.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF16A34A), width: 0.8),
            ),
            child: Row(
              children: [
                const Icon(Icons.memory_rounded, color: Color(0xFF15803D), size: 16),
                const SizedBox(width: 6),
                Text(
                  isRtl
                      ? '🧠 أعطال من التشخيص الذكي — معتمدة (${filteredKbPosts.length}/${aiVerifiedPosts.length})'
                      : '🧠 AI Diagnosed Faults — Verified (${filteredKbPosts.length}/${aiVerifiedPosts.length})',
                  style: const TextStyle(fontFamily: 'Tajawal', fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          if (filteredKbPosts.isNotEmpty)
            ...filteredKbPosts.map((CommunityPost post) => _buildKbCard(post, isRtl))
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Text(
                isRtl ? 'لا توجد أعطال مطابقة لعملية البحث.' : 'No matching faults found.',
                style: const TextStyle(fontFamily: 'Tajawal', fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ],
    );
  }


  Widget _buildKbCard(CommunityPost post, bool isRtl) {
    final descParts = post.issueDescription.split('### [ATTACHED_IMAGES]');
    final cleanDesc = descParts[0].trim();
    final List<String> imagePaths = descParts.length > 1
        ? descParts[1].split('\n').map((p) => p.trim()).where((p) => p.isNotEmpty).toList()
        : [];

    return InkWell(
      onTap: () => _showKbDetailSheet(context, post, cleanDesc, imagePaths, isRtl),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── شارة AI معتمد ──
            Row(
              children: [
                const Icon(Icons.verified_rounded, color: Color(0xFF16A34A), size: 14),
                const SizedBox(width: 5),
                Text(
                  isRtl ? '🧠 تشخيص ذكي — معتمد' : '🧠 AI Diagnosis — Verified',
                  style: const TextStyle(fontFamily: 'Tajawal', fontSize: 10, color: Color(0xFF15803D), fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // ── اسم الجهاز (العنوان الرئيسي للبطاقة) ──
            Text(
              post.deviceModel,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontFamily: 'Tajawal', fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 6),
            // ── الصف السفلي: نوع النظام + عداد الصور + سهم ──
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16A34A).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    post.systemType,
                    style: const TextStyle(fontFamily: 'Tajawal', fontSize: 10, color: Color(0xFF16A34A), fontWeight: FontWeight.w600),
                  ),
                ),
                if (imagePaths.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.photo_library_outlined, size: 13, color: Colors.grey),
                  const SizedBox(width: 3),
                  Text('${imagePaths.length}', style: const TextStyle(fontFamily: 'Tajawal', fontSize: 11, color: Colors.grey)),
                ],
                const Spacer(),
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
    );
  }

  /// Bottom Sheet تفاصيل بطاقة التشخيص الذكي
  void _showKbDetailSheet(BuildContext context, CommunityPost post, String cleanDesc, List<String> imagePaths, bool isRtl) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Directionality(
        textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
        child: DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollController) => SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── مقبض السحب ──
                Center(
                  child: Container(
                    width: 40, height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(99)),
                  ),
                ),
                // ── شارة AI ──
                Row(
                  children: [
                    const Icon(Icons.verified_rounded, color: Color(0xFF16A34A), size: 16),
                    const SizedBox(width: 6),
                    Text(
                      isRtl ? '🧠 تشخيص ذكي — معتمد' : '🧠 AI Diagnosis — Verified',
                      style: const TextStyle(fontFamily: 'Tajawal', fontSize: 11, color: Color(0xFF15803D), fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // ── اسم الجهاز ──
                Text(
                  post.deviceModel,
                  style: const TextStyle(fontFamily: 'Tajawal', fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), height: 1.4),
                ),
                const SizedBox(height: 6),
                // ── نوع النظام ──
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16A34A).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(post.systemType, style: const TextStyle(fontFamily: 'Tajawal', fontSize: 11, color: Color(0xFF16A34A), fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 14),
                const Divider(),
                const SizedBox(height: 12),
                // ── وصف المشكلة ──
                _sheetSection(isRtl ? '📋 وصف المشكلة' : '📋 Issue Description', cleanDesc),
                if (post.successfulSolution.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _sheetSection(isRtl ? '✅ الحل الناجح' : '✅ Successful Solution', post.successfulSolution, color: const Color(0xFF15803D)),
                ],
                if (post.approximateCost.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _sheetSection(isRtl ? '💰 التكلفة التقريبية' : '💰 Approximate Cost', post.approximateCost, color: const Color(0xFF0F75BC)),
                ],
                // ── الصور المرفقة ──
                if (imagePaths.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    isRtl ? '📷 الصور المرفقة' : '📷 Attached Photos',
                    style: const TextStyle(fontFamily: 'Tajawal', fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 110,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: imagePaths.length,
                      itemBuilder: (_, i) => Container(
                        margin: const EdgeInsets.only(right: 8),
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          image: !kIsWeb
                              ? DecorationImage(image: FileImage(File(imagePaths[i])), fit: BoxFit.cover)
                              : null,
                        ),
                        child: kIsWeb ? const Center(child: Icon(Icons.image_rounded, color: Color(0xFF94A3B8), size: 32)) : null,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sheetSection(String title, String body, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontFamily: 'Tajawal', fontSize: 13, fontWeight: FontWeight.bold, color: color ?? const Color(0xFF0F172A))),
        const SizedBox(height: 6),
        Text(body, style: const TextStyle(fontFamily: 'Tajawal', fontSize: 13, height: 1.7, color: Color(0xFF334155))),
      ],
    );
  }


  Widget _buildMetaChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(fontFamily: 'Tajawal', fontSize: 11, color: Color(0xFF0F75BC)),
      ),
    );
  }

  void _showEditFaultDialog(BuildContext context, VerifiedFault fault, bool isRtl) {
    if (!VerifiedFaultsAdminService.canManageFault(fault)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(isRtl ? '⚠️ لا تملك صلاحية تعديل هذا العطل الموثق.' : '⚠️ You are not authorized to edit this fault.'),
        ),
      );
      return;
    }

    final titleController = TextEditingController(text: fault.title);
    final descController = TextEditingController(text: fault.description);
    String selectedSector = fault.sector;

    final sectors = ['صناعي', 'كهرباء', 'ميكانيك', 'أنظمة الهيدروليك', 'أجهزة منزلية', 'تبريد وتكييف', 'سيارات ومركبات', 'سباكة', 'أخرى'];
    if (!sectors.contains(selectedSector)) {
      sectors.add(selectedSector);
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Directionality(
          textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
          child: AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                const Icon(Icons.edit_note_rounded, color: Color(0xFF0F75BC), size: 24),
                const SizedBox(width: 8),
                Text(
                  isRtl ? 'تعديل العطل الموثق' : 'Edit Verified Fault',
                  style: const TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(isRtl ? 'القطاع الهندسي:' : 'Sector:', style: const TextStyle(fontFamily: 'Tajawal', fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: selectedSector,
                    items: sectors.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontFamily: 'Tajawal', fontSize: 12)))).toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedSector = val);
                    },
                    decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                  ),
                  const SizedBox(height: 12),
                  Text(isRtl ? 'عنوان العطل:' : 'Title:', style: const TextStyle(fontFamily: 'Tajawal', fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                    style: const TextStyle(fontFamily: 'Tajawal', fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  Text(isRtl ? 'الوصف الهندسي والحل:' : 'Description & Solution:', style: const TextStyle(fontFamily: 'Tajawal', fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: descController,
                    maxLines: 4,
                    decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.all(10)),
                    style: const TextStyle(fontFamily: 'Tajawal', fontSize: 12),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(isRtl ? 'إلغاء' : 'Cancel', style: const TextStyle(fontFamily: 'Tajawal', color: Colors.grey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F75BC), foregroundColor: Colors.white),
                onPressed: () async {
                  final newTitle = titleController.text.trim();
                  final newDesc = descController.text.trim();
                  if (newTitle.isEmpty || newDesc.isEmpty) return;

                  Navigator.pop(ctx);
                  final success = await VerifiedFaultsAdminService.saveOrUpdateFault(
                    id: fault.id,
                    title: newTitle,
                    description: newDesc,
                    sector: selectedSector,
                    authorName: fault.authorName,
                    authorEmail: fault.authorEmail,
                    authorId: fault.authorId,
                    viewsCount: fault.viewsCount,
                  );

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: success ? const Color(0xFF16A34A) : Colors.red,
                        content: Text(
                          success
                              ? (isRtl ? '✅ تم تحديث العطل الموثق سحابياً.' : '✅ Verified fault updated successfully.')
                              : (isRtl ? '⚠️ تعذر تعديل العطل (تحقق من الصلاحيات أو الاتصال).' : '⚠️ Failed to update fault (check permissions or connection).'),
                        ),
                      ),
                    );
                  }
                },
                child: Text(isRtl ? 'حفظ التعديلات' : 'Save', style: const TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmHardDeleteFault(BuildContext context, VerifiedFault fault, bool isRtl) {
    if (!VerifiedFaultsAdminService.canManageFault(fault)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(isRtl ? '⚠️ لا تملك صلاحية حذف هذا العطل الموثق.' : '⚠️ You are not authorized to delete this fault.'),
        ),
      );
      return;
    }
    showDialog(
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
                    ? 'هل أنت متأكد من حذف هذا العطل الموثق نهائياً من سحابة Firestore؟ سيختفي هذا المحتوى فوراً ولحظياً (< 300ms) من هواتف جميع الفنيين.'
                    : 'Are you sure you want to permanently delete this verified fault from Firestore? It will disappear immediately (< 300ms) from all technicians\' devices.',
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
                    const Text('Collection: verified_faults', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F75BC), fontFamily: 'Courier')),
                    const SizedBox(height: 3),
                    Text('Document ID: ${fault.id}', style: const TextStyle(fontSize: 11, fontFamily: 'Courier', color: Color(0xFF0F172A)), overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 3),
                    Text('Title: ${fault.title}', style: const TextStyle(fontSize: 11, color: Color(0xFF475569)), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(isRtl ? 'إلغاء' : 'Cancel', style: const TextStyle(fontFamily: 'Tajawal', color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
              onPressed: () async {
                Navigator.pop(ctx);
                final success = await VerifiedFaultsAdminService.hardDeleteFault(fault.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: success ? const Color(0xFF16A34A) : Colors.red,
                      content: Text(
                        success
                            ? (isRtl ? '🗑️ تم الحذف النهائي من السحابة بنجاح.' : '🗑️ Permanently deleted from cloud.')
                            : (isRtl ? 'فشل حذف المستند السحابي.' : 'Failed to delete cloud document.'),
                      ),
                    ),
                  );
                }
              },
              child: Text(isRtl ? 'حذف نهائي 🗑️' : 'Delete', style: const TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold, fontSize: 11)),
            ),
          ],
        ),
      ),
    );
  }
}

class CommunityDashboardScreen extends ConsumerWidget {
  const CommunityDashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isRtl = ref.watch(localeProvider).languageCode == 'ar';
    final String titleText = isRtl ? '📚 موسوعة الأعطال الموثقة' : '📚 Verified Faults Encyclopedia';
    final String activeExpertLabel = isRtl ? 'مراجعة فورية من كبار خبراء الصيانة والمهندسين' : 'Reviewed instantly by top engineering experts';

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        drawer: const CustomAppDrawer(),
        appBar: AppBar(
          title: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(titleText, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B))),
              Text(activeExpertLabel, style: const TextStyle(fontSize: 9, color: Colors.green, fontWeight: FontWeight.bold)),
            ],
          ),
          centerTitle: true,
          backgroundColor: Colors.white,
          elevation: 0.5,
          automaticallyImplyLeading: true,
        ),
        body: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 450),
            color: Colors.white,
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: const CommunityDashboardContent(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
