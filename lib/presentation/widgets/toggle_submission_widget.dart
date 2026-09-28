import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dr_fix/main.dart'; // central localeProvider

// StateProvider to persist user's opt-in choice across screens easily
final communityOptInProvider = StateProvider<bool>((ref) => true);

class ToggleSubmissionWidget extends ConsumerWidget {
  const ToggleSubmissionWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isRtl = ref.watch(localeProvider).languageCode == 'ar';
    final isOptedIn = ref.watch(communityOptInProvider);

    final titleAr = 'مشاركة العطل بشكل مجهول في الموسوعة';
    final titleEn = 'Share this case anonymously with the community';
    final subtitleAr = 'شارك هذه الحالة ليستفيد منها الآخرون. سيتم نشر العطل بشكل مجهول بالكامل ولن تظهر أي معلومات شخصية أو بيانات تعريفية.';
    final subtitleEn = 'Share this case to help others. The fault will be posted completely anonymously; no personal or identifying information will be shown.';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      color: isOptedIn ? const Color(0xFFF8FFFB) : const Color(0xFFF8FAFC),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: isOptedIn ? const Color(0xFFBBF7D0) : const Color(0xFFE2E8F0))),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isRtl ? titleAr : titleEn,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 6),
            Text(
              isRtl ? subtitleAr : subtitleEn,
              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), height: 1.4),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: isOptedIn ? const Color(0xFFDCFCE7) : Colors.white,
                      side: const BorderSide(color: Color(0xFFBBF7D0)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => ref.read(communityOptInProvider.notifier).state = true,
                    child: Text(isRtl ? 'نعم' : 'Yes', style: const TextStyle(color: Color(0xFF064E3B), fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: !isOptedIn ? const Color(0xFFF1F5F9) : Colors.white,
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => ref.read(communityOptInProvider.notifier).state = false,
                    child: Text(isRtl ? 'لا' : 'No', style: const TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.bold)),
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
