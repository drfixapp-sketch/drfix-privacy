import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dr_fix/main.dart';

class WelcomeBrandSection extends ConsumerWidget {
  const WelcomeBrandSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isRtl = ref.watch(localeProvider).languageCode == 'ar';

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // استدعاء الشعار الجديد المطابق للصورة المرفقة
        Image.asset(
          'assets/logo.png',
          height: 180,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            // أيقونة احتياطية في حال لم يتم تحديث ملف الـ assets بعد
            return const Icon(Icons.build_circle, size: 120, color: Color(0xFF0F75BC));
          },
        ),
        const SizedBox(height: 16),
        const Text(
          'Dr. Fix',
          style: TextStyle(
            fontSize: 42,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F75BC),
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        // العبارة التسويقية — مترجمة حسب اللغة الحالية
        Text(
          isRtl
              ? 'تشخيص ذكي • حلول دقيقة • مجتمع خبراء'
              : 'Smart Diagnosis • Precise Solutions • Expert Community',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF556080),
          ),
        ),
        const SizedBox(height: 48),

        // أزرار التحكم والولوج محددة العرض بـ 450 بكسل لحل مشكلة التمدد على الويب
        Container(
          constraints: const BoxConstraints(maxWidth: 450),
          child: Column(
            children: [
              ElevatedButton(
                onPressed: () {
                  // منطق الانتقال لصفحة تسجيل الدخول
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F75BC),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: Text(
                  isRtl ? 'تسجيل الدخول' : 'Log In',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () {
                  // منطق الانتقال لصفحة إنشاء الحساب
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0F75BC),
                  side: const BorderSide(color: Color(0xFF0F75BC), width: 2),
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  isRtl ? 'إنشاء حساب' : 'Create Account',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  // منطق الدخول كضيف للتصفح السريع
                },
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF707D93),
                  minimumSize: const Size(double.infinity, 44),
                ),
                child: Text(
                  isRtl ? 'التصفح كضيف' : 'Browse as Guest',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
