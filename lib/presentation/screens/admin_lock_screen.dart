import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dr_fix/main.dart';
import 'package:dr_fix/data/network/admin_auth_service.dart';

class AdminLockState {
  final int failedAttempts;
  final bool isLocked;
  final int remainingSeconds;
  final bool isLoading;

  const AdminLockState({
    this.failedAttempts = 0,
    this.isLocked = false,
    this.remainingSeconds = 0,
    this.isLoading = false,
  });

  AdminLockState copyWith({
    int? failedAttempts,
    bool? isLocked,
    int? remainingSeconds,
    bool? isLoading,
  }) {
    return AdminLockState(
      failedAttempts: failedAttempts ?? this.failedAttempts,
      isLocked: isLocked ?? this.isLocked,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class AdminLockNotifier extends StateNotifier<AdminLockState> {
  Timer? _timer;

  AdminLockNotifier() : super(const AdminLockState());

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> attemptAdminLogin({
    required String email,
    required String password,
    required VoidCallback onSuccess,
    required ValueChanged<String> onFailure,
  }) async {
    if (state.isLocked) {
      onFailure('بوابة الإدارة مقفلة مؤقتاً لحماية النظام. يرجى الانتظار.');
      return;
    }

    state = state.copyWith(isLoading: true);

    try {
      final result = await AdminAuthService.authenticateAdmin(
        email: email,
        password: password,
      );

      state = state.copyWith(isLoading: false);

      if (result.isAuthorized) {
        _timer?.cancel();
        state = state.copyWith(failedAttempts: 0, isLocked: false, remainingSeconds: 0);
        onSuccess();
        return;
      }

      final nextAttempts = state.failedAttempts + 1;
      if (nextAttempts >= 3) {
        startLockout();
        onFailure('تم تجاوز الحد الأقصى للمحاولات (3). تم قفل الدخول مؤقتاً لمدة 30 ثانية.');
      } else {
        state = state.copyWith(failedAttempts: nextAttempts);
        onFailure(result.errorMessage ?? 'فشل التحقق من بيانات المشرف.');
      }
    } catch (e) {
      state = state.copyWith(isLoading: false);
      final nextAttempts = state.failedAttempts + 1;
      if (nextAttempts >= 3) {
        startLockout();
      } else {
        state = state.copyWith(failedAttempts: nextAttempts);
      }
      onFailure('حدث خطأ أثناء الاتصال: $e');
    }
  }

  void startLockout() {
    _timer?.cancel();
    final lockUntil = DateTime.now().add(const Duration(seconds: 30));
    state = state.copyWith(failedAttempts: 3, isLocked: true, remainingSeconds: 30);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final diff = lockUntil.difference(DateTime.now()).inSeconds;
      if (diff <= 0) {
        _timer?.cancel();
        state = state.copyWith(failedAttempts: 0, isLocked: false, remainingSeconds: 0);
      } else {
        state = state.copyWith(remainingSeconds: diff);
      }
    });
  }
}

final adminLockProvider = StateNotifierProvider<AdminLockNotifier, AdminLockState>((ref) {
  return AdminLockNotifier();
});

class AdminLockScreen extends ConsumerStatefulWidget {
  const AdminLockScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AdminLockScreen> createState() => _AdminLockScreenState();
}

class _AdminLockScreenState extends ConsumerState<AdminLockScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final isRtl = ref.read(localeProvider).languageCode == 'ar';

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isRtl
              ? 'يرجى إدخال البريد الإلكتروني وكلمة المرور للمشرف.'
              : 'Please enter admin email and password.'),
        ),
      );
      return;
    }

    ref.read(adminLockProvider.notifier).attemptAdminLogin(
      email: email,
      password: password,
      onSuccess: () {
        Navigator.pushReplacementNamed(context, '/admin-review');
      },
      onFailure: (errorMsg) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFB91C1C),
            content: Text(errorMsg),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final localeState = ref.watch(localeProvider);
    final adminState = ref.watch(adminLockProvider);
    final isRtl = localeState.languageCode == 'ar';

    final texts = isRtl
        ? {
            'title': 'بوابة تسجيل دخول المشرفين',
            'subtitle': 'تسجيل الدخول الآمن للمشرفين المعتمدين والمالك الرئيسي (Super Admin).',
            'email_label': 'البريد الإلكتروني للإدارة',
            'email_hint': 'admin@drfix.app',
            'password_label': 'كلمة المرور',
            'password_hint': '••••••••',
            'button': 'تسجيل الدخول للوحة التحكم',
            'security_note': 'محمي بنظام تشفير Firebase Authentication وسجلات الصلاحيات.',
            'locked': 'تم قفل محاولات الدخول مؤقتاً، يرجى الانتظار:',
            'seconds': 'ثانية',
          }
        : {
            'title': 'Admin Sign-In Portal',
            'subtitle': 'Secure access for authorized administrators & Super Admin.',
            'email_label': 'Admin Email',
            'email_hint': 'admin@drfix.app',
            'password_label': 'Password',
            'password_hint': '••••••••',
            'button': 'Sign In to Admin Panel',
            'security_note': 'Protected by Firebase Auth and dynamic Firestore admin roles.',
            'locked': 'Access temporarily locked. Please wait:',
            'seconds': 'seconds',
          };

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 450),
            color: Colors.white,
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F75BC)),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0F75BC), Color(0xFF1E293B)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 18,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 26),
                              const SizedBox(width: 10),
                              Text(
                                texts['title']!,
                                style: const TextStyle(
                                  fontFamily: 'Tajawal',
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            texts['subtitle']!,
                            style: const TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 12.5,
                              color: Color(0xFFCBD5E1),
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // حقل البريد الإلكتروني
                          Text(
                            texts['email_label']!,
                            style: const TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            enabled: !adminState.isLocked && !adminState.isLoading,
                            decoration: InputDecoration(
                              hintText: texts['email_hint'],
                              prefixIcon: const Icon(Icons.email_outlined, size: 18),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                            style: const TextStyle(fontSize: 13),
                          ),
                          const SizedBox(height: 16),

                          // حقل كلمة المرور
                          Text(
                            texts['password_label']!,
                            style: const TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            enabled: !adminState.isLocked && !adminState.isLoading,
                            decoration: InputDecoration(
                              hintText: texts['password_hint'],
                              prefixIcon: const Icon(Icons.lock_outline_rounded, size: 18),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                  size: 18,
                                ),
                                onPressed: () {
                                  setState(() => _obscurePassword = !_obscurePassword);
                                },
                              ),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                            style: const TextStyle(fontSize: 13),
                            onSubmitted: (_) => _handleLogin(),
                          ),
                          const SizedBox(height: 20),

                          // زر تسجيل الدخول
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: (adminState.isLocked || adminState.isLoading)
                                  ? null
                                  : _handleLogin,
                              icon: adminState.isLoading
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Icon(Icons.login_rounded, size: 18),
                              label: Text(
                                texts['button']!,
                                style: const TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0F75BC),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // مؤقت الإغلاق في حال القفل
                          if (adminState.isLocked)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF2F2),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFEF4444)),
                              ),
                              child: Text(
                                '${texts['locked']} ${adminState.remainingSeconds} ${texts['seconds']}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontFamily: 'Tajawal',
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFB91C1C),
                                ),
                              ),
                            )
                          else
                            Text(
                              texts['security_note']!,
                              style: const TextStyle(fontFamily: 'Tajawal', fontSize: 10.5, color: Colors.grey),
                            ),
                        ],
                      ),
                    ),
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
