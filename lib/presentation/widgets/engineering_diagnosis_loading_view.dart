import 'dart:async';
import 'package:flutter/material.dart';

final List<String> engineeringLoadingPhrases = [
  "جاري إرسال البيانات والمعلومات الفنية...",
  "جاري إرسال وصف العطل...",
  "جاري إعداد التقرير للحالة...",
  "جاري صياغة الأسباب المحتملة...",
  "جاري ترتيب خطوات الحل...",
  "جاري إعداد تقرير كيف تحافظ على المعدة...",
  "جاري إعداد تقييم المخاطر والسلامة العامة...",
  "جاري إعداد المكونات وقطع الغيار المراد فحصها...",
];

/// مكون التحميل المعزول لمرحلة التشخيص الذكي مع تبديل دوري للعبارات كل 7 ثوانٍ
class EngineeringDiagnosisLoadingView extends StatefulWidget {
  final bool isRtl;
  const EngineeringDiagnosisLoadingView({super.key, required this.isRtl});

  @override
  State<EngineeringDiagnosisLoadingView> createState() => _EngineeringDiagnosisLoadingViewState();
}

class _EngineeringDiagnosisLoadingViewState extends State<EngineeringDiagnosisLoadingView> {
  int _currentIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 7), (_) {
      if (mounted) {
        setState(() {
          _currentIndex = (_currentIndex + 1) % engineeringLoadingPhrases.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final phrase = engineeringLoadingPhrases[_currentIndex];

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 36.0, horizontal: 24.0),
        child: Container(
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 52,
                height: 52,
                child: CircularProgressIndicator(
                  strokeWidth: 3.5,
                  color: Color(0xFF0F75BC),
                ),
              ),
              const SizedBox(height: 20),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 600),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.0, 0.25),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
                    child: child,
                  ),
                ),
                child: Text(
                  phrase,
                  key: ValueKey<int>(_currentIndex),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                    fontFamily: 'Tajawal',
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
