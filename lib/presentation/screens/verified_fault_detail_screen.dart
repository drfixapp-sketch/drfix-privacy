import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dr_fix/data/models/verified_fault_model.dart';
import 'package:dr_fix/main.dart';

/// شاشة تفاصيل العطل الموثق في الموسوعة الهندسية
class VerifiedFaultDetailScreen extends ConsumerWidget {
  final VerifiedFault fault;

  const VerifiedFaultDetailScreen({Key? key, required this.fault}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isRtl = ref.watch(localeProvider).languageCode == 'ar';

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 450),
          child: Scaffold(
            backgroundColor: const Color(0xFFF8FAFC),
            appBar: AppBar(
              title: Text(
                isRtl ? 'تفاصيل العطل الموثق' : 'Verified Fault Details',
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              centerTitle: true,
              backgroundColor: const Color(0xFF0F75BC),
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── بطاقة المعلومات الرأسية ──
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // شارة معتمد + اسم الكاتب
                          Row(
                            children: [
                              const Icon(Icons.verified_rounded, color: Color(0xFF0F75BC), size: 16),
                              const SizedBox(width: 6),
                              Text(
                                fault.authorName,
                                style: const TextStyle(
                                  fontFamily: 'Tajawal',
                                  fontSize: 12,
                                  color: Color(0xFF0F75BC),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              // القطاع
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F75BC).withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  fault.sector,
                                  style: const TextStyle(
                                    fontFamily: 'Tajawal',
                                    fontSize: 11,
                                    color: Color(0xFF0F75BC),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // عنوان العطل
                          Text(
                            fault.title,
                            style: const TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 10),
                          // عداد المشاهدات + التاريخ
                          Row(
                            children: [
                              const Icon(Icons.visibility_outlined, size: 14, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(
                                '${fault.viewsCount} ${isRtl ? 'مشاهدة' : 'views'}',
                                style: const TextStyle(fontFamily: 'Tajawal', fontSize: 12, color: Colors.grey),
                              ),
                              const SizedBox(width: 14),
                              const Icon(Icons.calendar_today_outlined, size: 13, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(
                                '${fault.createdAt.year}/${fault.createdAt.month.toString().padLeft(2, '0')}/${fault.createdAt.day.toString().padLeft(2, '0')}',
                                style: const TextStyle(fontFamily: 'Tajawal', fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── قسم التفاصيل الكاملة ──
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.description_outlined, color: Color(0xFF0F75BC), size: 18),
                              const SizedBox(width: 6),
                              Text(
                                isRtl ? 'التفاصيل الهندسية الكاملة' : 'Full Engineering Details',
                                style: const TextStyle(
                                  fontFamily: 'Tajawal',
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          const Divider(height: 1),
                          const SizedBox(height: 10),
                          Text(
                            fault.description,
                            style: const TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 13,
                              height: 1.7,
                              color: Color(0xFF334155),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── تذييل: شارة الجودة ──
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF86EFAC)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.verified_user_outlined, color: Color(0xFF15803D), size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              isRtl
                                  ? 'هذا العطل موثق ومعتمد من فريق Dr. Fix الهندسي'
                                  : 'This fault is documented & verified by Dr. Fix engineering team',
                              style: const TextStyle(
                                fontFamily: 'Tajawal',
                                fontSize: 11,
                                color: Color(0xFF15803D),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
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
