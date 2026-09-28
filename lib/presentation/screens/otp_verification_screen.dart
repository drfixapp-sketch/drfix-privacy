import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dr_fix/main.dart';
import '../providers/auth_provider.dart';
import 'home_screen.dart';
import 'welcome_screen.dart';

class OtpVerificationScreen extends ConsumerStatefulWidget {
  final String email;

  const OtpVerificationScreen({
    super.key,
    required this.email,
  });

  @override
  ConsumerState<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _isSubmitting = false;
  String? _errorMessage;

  // Rate-limiting / Debounce timer (60 seconds)
  int _resendCooldown = 60;
  Timer? _cooldownTimer;
  bool _canResend = false;
  String? _debugOtpCode;

  @override
  void initState() {
    super.initState();
    _startCooldownTimer();
    _loadDebugOtp();
  }

  Future<void> _loadDebugOtp() async {
    // محجوب تماماً في الإنتاج (Release Mode) ولا يُحمّل إطلاقاً إلا في بيئة التطوير والاختبار
    if (!kDebugMode) return;

    final user = ref.read(authProvider).user;
    if (user != null) {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString('dr_fix_pending_otp_${user.uid}');
      if (mounted && code != null && code.isNotEmpty) {
        setState(() {
          _debugOtpCode = code;
        });
        debugPrint("🧪 [Dr. Fix Field Test] Active Verification OTP: $code");
      }
    }
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    for (var c in _controllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _startCooldownTimer() {
    setState(() {
      _resendCooldown = 60;
      _canResend = false;
    });
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_resendCooldown > 1) {
        setState(() {
          _resendCooldown--;
        });
      } else {
        setState(() {
          _resendCooldown = 0;
          _canResend = true;
        });
        timer.cancel();
      }
    });
  }

  String _getEnteredOtp() {
    return _controllers.map((c) => c.text.trim()).join();
  }

  Future<void> _verifyOtp() async {
    final otp = _getEnteredOtp();
    final isArabic = ref.read(localeProvider).languageCode == 'ar';

    if (otp.length != 6) {
      setState(() {
        _errorMessage = isArabic
            ? 'يرجى إدخال الرمز السري كاملاً المكون من 6 أرقام'
            : 'Please enter the complete 6-digit code';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final success = await ref.read(authProvider.notifier).verifyEmailOtp(otp);

    if (!mounted) return;

    setState(() {
      _isSubmitting = false;
    });

    if (success) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } else {
      final authError = ref.read(authProvider).errorMessage;
      setState(() {
        _errorMessage = authError ??
            (isArabic
                ? 'رمز التحقق غير صحيح أو منتهي الصلاحية'
                : 'Invalid or expired verification code');
      });
    }
  }

  Future<void> _resendOtp() async {
    if (!_canResend) return;

    final isArabic = ref.read(localeProvider).languageCode == 'ar';
    setState(() {
      _errorMessage = null;
    });

    final success = await ref.read(authProvider.notifier).resendEmailOtp();
    if (!mounted) return;

    if (success) {
      _startCooldownTimer();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic
                ? 'تم إرسال كود تحقق سري جديد إلى بريدك الإلكتروني'
                : 'A new verification code has been sent to your email',
            style: const TextStyle(fontFamily: 'Cairo'),
          ),
          backgroundColor: const Color(0xFF0F172A),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      setState(() {
        _errorMessage = isArabic
            ? 'تعذر إعادة إرسال الرمز، يرجى المحاولة لاحقاً'
            : 'Failed to resend code, please try again later';
      });
    }
  }

  Future<void> _cancelAndSignOut() async {
    await ref.read(authProvider.notifier).signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = ref.watch(localeProvider).languageCode == 'ar';
    final isRtl = isArabic;

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F5F9),
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFF1F5F9), Color(0xFFE2E8F0)],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // أيقونة الأمان والتوثيق
                      Center(
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.mark_email_read_rounded,
                            size: 42,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      Text(
                        isArabic ? 'التحقق من البريد الإلكتروني' : 'Verify Email Address',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                          fontFamily: 'Cairo',
                        ),
                      ),
                      const SizedBox(height: 8),

                      Text(
                        isArabic
                            ? 'تم إرسال كود التحقق السري (6 أرقام) إلى صندوق الوارد للبريد:'
                            : 'A 6-digit verification code was sent to your inbox:',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF64748B),
                          fontFamily: 'Cairo',
                        ),
                      ),
                      const SizedBox(height: 4),

                      Text(
                        widget.email,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2563EB),
                          fontFamily: 'Cairo',
                        ),
                      ),

                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFBFDBFE)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.access_time_rounded, size: 16, color: Color(0xFF2563EB)),
                            const SizedBox(width: 6),
                            Text(
                              isArabic ? 'صلاحية الكود: 24 ساعة فقط' : 'Code validity: 24 hours only',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E40AF),
                                fontFamily: 'Cairo',
                              ),
                            ),
                          ],
                        ),
                      ),

                      // شريط مساعد الفحص الميداني والتجربة السريعة (محجوب تلقائياً في نسخة الإنتاج kDebugMode)
                      if (kDebugMode && _debugOtpCode != null) ...[
                        const SizedBox(height: 10),
                        InkWell(
                          onTap: () {
                            for (int i = 0; i < 6 && i < _debugOtpCode!.length; i++) {
                              _controllers[i].text = _debugOtpCode![i];
                            }
                            _verifyOtp();
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFF59E0B)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.bug_report_rounded, size: 16, color: Color(0xFFB45309)),
                                const SizedBox(width: 8),
                                Text(
                                  isArabic
                                      ? 'رمز الفحص الميداني: $_debugOtpCode (اضغط للملء التلقائي)'
                                      : 'Field Test OTP: $_debugOtpCode (Tap to fill)',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF92400E),
                                    fontFamily: 'Cairo',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),

                      Card(
                        elevation: 4,
                        shadowColor: Colors.black.withOpacity(0.08),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // 6 مربعات إدخال الـ OTP
                              Directionality(
                                textDirection: TextDirection.ltr,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: List.generate(6, (index) {
                                    return SizedBox(
                                      width: 44,
                                      height: 54,
                                      child: TextFormField(
                                        controller: _controllers[index],
                                        focusNode: _focusNodes[index],
                                        keyboardType: TextInputType.number,
                                        textAlign: TextAlign.center,
                                        maxLength: 1,
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF0F172A),
                                        ),
                                        inputFormatters: [
                                          FilteringTextInputFormatter.digitsOnly,
                                        ],
                                        decoration: InputDecoration(
                                          counterText: '',
                                          contentPadding: EdgeInsets.zero,
                                          filled: true,
                                          fillColor: const Color(0xFFF8FAFC),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(10),
                                            borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(10),
                                            borderSide: const BorderSide(
                                              color: Color(0xFF0F172A),
                                              width: 2,
                                            ),
                                          ),
                                        ),
                                        onChanged: (value) {
                                          if (value.isNotEmpty) {
                                            if (index < 5) {
                                              _focusNodes[index + 1].requestFocus();
                                            } else {
                                              _focusNodes[index].unfocus();
                                              _verifyOtp();
                                            }
                                          } else if (value.isEmpty && index > 0) {
                                            _focusNodes[index - 1].requestFocus();
                                          }
                                        },
                                      ),
                                    );
                                  }),
                                ),
                              ),

                              if (_errorMessage != null) ...[
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEF2F2),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: const Color(0xFFFCA5A5)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.error_outline, size: 20, color: Color(0xFFDC2626)),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _errorMessage!,
                                          style: const TextStyle(
                                            color: Color(0xFFDC2626),
                                            fontSize: 12,
                                            fontFamily: 'Cairo',
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              const SizedBox(height: 24),

                              // زر تأكيد الرمز وتفعيل الحساب
                              ElevatedButton(
                                onPressed: _isSubmitting ? null : _verifyOtp,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0F172A),
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor: Colors.grey.shade300,
                                  disabledForegroundColor: Colors.grey.shade500,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 2,
                                ),
                                child: _isSubmitting
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : Text(
                                        isArabic ? 'تأكيد الرمز وتفعيل الحساب' : 'Verify Code & Activate',
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Cairo',
                                        ),
                                      ),
                              ),

                              const SizedBox(height: 16),

                              // زر إعادة إرسال الكود مع Debounce Timer (60 ثانية)
                              TextButton.icon(
                                onPressed: _canResend ? _resendOtp : null,
                                icon: Icon(
                                  Icons.refresh_rounded,
                                  size: 18,
                                  color: _canResend ? const Color(0xFF2563EB) : const Color(0xFF94A3B8),
                                ),
                                label: Text(
                                  _canResend
                                      ? (isArabic ? 'إعادة إرسال كود التحقق' : 'Resend Verification Code')
                                      : (isArabic
                                          ? 'إعادة الإرسال متاحة بعد $_resendCooldown ثانية'
                                          : 'Resend available in ${_resendCooldown}s'),
                                  style: TextStyle(
                                    color: _canResend ? const Color(0xFF2563EB) : const Color(0xFF94A3B8),
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Cairo',
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // زر التراجع وتغيير البريد أو تسجيل الخروج
                      TextButton(
                        onPressed: _cancelAndSignOut,
                        child: Text(
                          isArabic ? 'الرجوع وتغيير البريد الإلكتروني' : 'Back to Sign In / Change Email',
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontFamily: 'Cairo',
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
