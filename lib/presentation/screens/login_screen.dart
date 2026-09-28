import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dr_fix/main.dart';
import '../providers/auth_provider.dart';
import 'home_screen.dart';
import 'otp_verification_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  final bool isSignUp;

  const LoginScreen({
    super.key,
    this.isSignUp = false,
  });

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isSignUp = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isPolicyAccepted = false;
  bool _userInitiatedAction = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _isSignUp = widget.isSignUp;

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeOutCubic,
      ),
    );

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showErrorDialog({
    required BuildContext context,
    required String title,
    required String message,
    required bool isArabic,
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Colors.white,
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
          contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  color: Color(0xFFEF4444),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                    fontFamily: 'Cairo',
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF475569),
              height: 1.5,
              fontFamily: 'Cairo',
            ),
          ),
          actions: [
            if (actionLabel != null && onAction != null)
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  onAction();
                },
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFFEFF6FF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: Text(
                  actionLabel,
                  style: const TextStyle(
                    color: Color(0xFF2563EB),
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                  ),
                ),
              ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              style: TextButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: Text(
                isArabic ? 'حسناً' : 'OK',
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cairo',
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showPrivacyPolicy(BuildContext context, bool isArabic) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          isArabic ? 'سياسة الخصوصية وحماية البيانات' : 'Privacy Policy & Terms',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isArabic ? 'الامتثال القانوني والمعايير المهنية:' : 'Legal Compliance & Standards:',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                isArabic
                    ? '1. تشريعات السلامة المهنية (OSHA):\nنلتزم بأعلى معايير وإرشادات السلامة العامة في توثيق وتحليل الأعطال الهندسية.\n\n'
                      '2. قوانين حماية البيانات والخصوصية:\nنلتزم بالأنظمة واللوائح المعتمدة في المملكة الأردنية الهاشمية ودول الخليج العربي (المملكة العربية السعودية، الإمارات العربية المتحدة، وغيرها) فيما يخص حفظ سرية البيانات الهندسية والشخصية وعدم مشاركتها مع أطراف ثالثة دون إذن صريح.\n\n'
                      '3. إخلاء المسؤولية الهندسية:\nالتحليلات والتوصيات المقدمة عبر التطبيق استرشادية مبنية على الذكاء الاصطناعي ويجب مراجعتها من قبل مهندس مختص ومعتمد في موقع العمل قبل اتخاذ أي قرار تنفيذي أو تصحيحي نهائي.'
                    : '1. Occupational Safety (OSHA):\nWe adhere to general safety guidelines in identifying structural and engineering hazards.\n\n'
                      '2. Data Privacy Laws:\nWe comply with data protection regulations applicable in Jordan and GCC countries regarding data confidentiality.\n\n'
                      '3. Engineering Disclaimer:\nAnalyses provided are AI-assisted recommendations and must be verified by a licensed engineer on site.',
                style: const TextStyle(fontSize: 13, height: 1.5),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(isArabic ? 'إغلاق' : 'Close'),
          ),
        ],
      ),
    );
  }

  void _toggleAuthMode() {
    setState(() {
      _isSignUp = !_isSignUp;
      _formKey.currentState?.reset();
      _confirmPasswordController.clear();
      _isPolicyAccepted = false;
    });
    _animController.reset();
    _animController.forward();
  }

  Future<void> _submit() async {
    final isArabic = ref.read(localeProvider).languageCode == 'ar';

    if (_isSignUp && !_isPolicyAccepted) {
      _showErrorDialog(
        context: context,
        title: isArabic ? 'موافقة إلزامية' : 'Agreement Required',
        message: isArabic
            ? 'يجب الموافقة على سياسة الخصوصية وحماية البيانات وإقرار السلامة المهنية (OSHA) لإنشاء حساب جديد.'
            : 'You must agree to the Privacy Policy and OSHA guidelines to create a new account.',
        isArabic: isArabic,
      );
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    _userInitiatedAction = true;
    final authNotifier = ref.read(authProvider.notifier);
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (_isSignUp) {
      final name = _nameController.text.trim();
      await authNotifier.signUpWithEmailAndPassword(
        email,
        password,
        name,
      );
    } else {
      await authNotifier.signInWithEmailAndPassword(
        email,
        password,
      );
    }
  }

  Future<void> _signInWithGoogle() async {
    final isArabic = ref.read(localeProvider).languageCode == 'ar';
    if (_isSignUp && !_isPolicyAccepted) {
      _showErrorDialog(
        context: context,
        title: isArabic ? 'موافقة إلزامية' : 'Agreement Required',
        message: isArabic
            ? 'يجب الموافقة على سياسة الخصوصية وشروط الاستخدام أولاً.'
            : 'You must agree to the Privacy Policy and Terms first.',
        isArabic: isArabic,
      );
      return;
    }
    _userInitiatedAction = true;
    await ref.read(authProvider.notifier).signInWithGoogle();
  }

  Future<void> _continueAsGuest() async {
    final isArabic = ref.read(localeProvider).languageCode == 'ar';
    if (_isSignUp && !_isPolicyAccepted) {
      _showErrorDialog(
        context: context,
        title: isArabic ? 'موافقة إلزامية' : 'Agreement Required',
        message: isArabic
            ? 'يجب الموافقة على سياسة الخصوصية وشروط الاستخدام أولاً.'
            : 'You must agree to the Privacy Policy and Terms first.',
        isArabic: isArabic,
      );
      return;
    }
    _userInitiatedAction = true;
    await ref.read(authProvider.notifier).signInAsGuest();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isArabic = ref.watch(localeProvider).languageCode == 'ar';
    final isRtl = isArabic;
    final isLoading = authState.status == AuthStatus.loading;

    ref.listen<AuthState>(authProvider, (previous, next) {
      if (!_userInitiatedAction) return;

      if (next.status == AuthStatus.authenticated) {
        _userInitiatedAction = false;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      } else if (next.status == AuthStatus.unverified) {
        // ℹ️ [OTP Disabled] هذه الحالة معطَّلة — الحسابات تُفعَّل مباشرة بدون OTP
        // في حال عودة هذا المسار مستقبلاً: إعادة تفعيل السطر أدناه
        // Navigator.of(context).push(MaterialPageRoute(builder: (_) => OtpVerificationScreen(email: targetEmail)));
        _userInitiatedAction = false;
        // توجيه للـ HomeScreen كبديل آمن
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      } else if (next.errorMessage != null && next.errorMessage != previous?.errorMessage) {
        _userInitiatedAction = false;
        final errorMsg = next.errorMessage!;
        final isEmailInUse = errorMsg.contains('مسجل بالفعل') ||
            errorMsg.toLowerCase().contains('already in use') ||
            errorMsg.contains('email-already-in-use');

        _showErrorDialog(
          context: context,
          title: isArabic ? 'تنبيه' : 'Notice',
          message: errorMsg,
          isArabic: isArabic,
          actionLabel: isEmailInUse ? (isArabic ? 'تسجيل الدخول الآن' : 'Sign In Now') : null,
          onAction: isEmailInUse
              ? () {
                  if (_isSignUp) {
                    _toggleAuthMode();
                  }
                }
              : null,
        );
      }
    });

    final bool canProceed = !_isSignUp || _isPolicyAccepted;

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
          child: Stack(
            children: [
              Positioned(
                top: 40,
                left: isRtl ? null : 16,
                right: isRtl ? 16 : null,
                child: SafeArea(
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1E293B)),
                    onPressed: () {
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      } else {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => const HomeScreen()),
                        );
                      }
                    },
                    tooltip: isArabic ? 'رجوع' : 'Back',
                  ),
                ),
              ),
              SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 460),
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: AnimatedBuilder(
                          animation: _slideAnimation,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(0, _slideAnimation.value),
                              child: child,
                            );
                          },
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Center(
                                child: Container(
                                  width: 54,
                                  height: 54,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.08),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.engineering_rounded,
                                    size: 32,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _isSignUp
                                    ? (isArabic ? 'إنشاء حساب فني جديد' : 'Create Technician Account')
                                    : (isArabic ? 'بوابة تسجيل الدخول' : 'Sign In Portal'),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                  fontFamily: 'Cairo',
                                ),
                              ),
                              const SizedBox(height: 12),
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
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF1F5F9),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        padding: const EdgeInsets.all(4),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: ElevatedButton(
                                                onPressed: _isSignUp ? _toggleAuthMode : null,
                                                style: ElevatedButton.styleFrom(
                                                  elevation: _isSignUp ? 0 : 2,
                                                  backgroundColor: _isSignUp
                                                      ? Colors.transparent
                                                      : const Color(0xFF1E293B),
                                                  foregroundColor: _isSignUp
                                                      ? const Color(0xFF64748B)
                                                      : Colors.white,
                                                  disabledBackgroundColor: const Color(0xFF1E293B),
                                                  disabledForegroundColor: Colors.white,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(10),
                                                  ),
                                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                                ),
                                                child: Text(
                                                  isArabic ? 'تسجيل الدخول' : 'Sign In',
                                                  style: TextStyle(
                                                    fontWeight: !_isSignUp
                                                        ? FontWeight.bold
                                                        : FontWeight.normal,
                                                    fontSize: 14,
                                                    fontFamily: 'Cairo',
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: ElevatedButton(
                                                onPressed: !_isSignUp ? _toggleAuthMode : null,
                                                style: ElevatedButton.styleFrom(
                                                  elevation: !_isSignUp ? 0 : 2,
                                                  backgroundColor: !_isSignUp
                                                      ? Colors.transparent
                                                      : const Color(0xFF1E293B),
                                                  foregroundColor: !_isSignUp
                                                      ? const Color(0xFF64748B)
                                                      : Colors.white,
                                                  disabledBackgroundColor: const Color(0xFF1E293B),
                                                  disabledForegroundColor: Colors.white,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(10),
                                                  ),
                                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                                ),
                                                child: Text(
                                                  isArabic ? 'إنشاء حساب' : 'Sign Up',
                                                  style: TextStyle(
                                                    fontWeight: _isSignUp
                                                        ? FontWeight.bold
                                                        : FontWeight.normal,
                                                    fontSize: 14,
                                                    fontFamily: 'Cairo',
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      if (isLoading) ...[
                                        const Center(
                                          child: Padding(
                                            padding: EdgeInsets.all(32.0),
                                            child: CircularProgressIndicator(),
                                          ),
                                        ),
                                      ] else ...[
                                        Form(
                                          key: _formKey,
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.stretch,
                                            children: [
                                              if (_isSignUp) ...[
                                                TextFormField(
                                                  controller: _nameController,
                                                   decoration: InputDecoration(
                                                    labelText: isArabic ? 'الاسم بالكامل' : 'Full Name',
                                                    hintText: isArabic ? 'مثال: أحمد' : 'e.g. Ahmed',
                                                    prefixIcon: const Icon(Icons.person_outline),
                                                    border: OutlineInputBorder(
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                  ),
                                                  validator: (value) {
                                                    if (_isSignUp && (value == null || value.trim().isEmpty)) {
                                                      return isArabic ? 'يرجى إدخال الاسم بالكامل' : 'Please enter your name';
                                                    }
                                                    return null;
                                                  },
                                                ),
                                                const SizedBox(height: 16),
                                              ],
                                              TextFormField(
                                                controller: _emailController,
                                                keyboardType: TextInputType.emailAddress,
                                                decoration: InputDecoration(
                                                  labelText: isArabic ? 'البريد الإلكتروني' : 'Email Address',
                                                  hintText: isArabic ? 'example@domain.com' : 'example@domain.com',
                                                  prefixIcon: const Icon(Icons.email_outlined),
                                                  border: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                ),
                                                validator: (value) {
                                                  if (value == null || value.trim().isEmpty) {
                                                    return isArabic
                                                        ? 'يرجى إدخال البريد الإلكتروني'
                                                        : 'Please enter your email';
                                                  }
                                                  if (!value.contains('@') || !value.contains('.')) {
                                                    return isArabic
                                                        ? 'يرجى إدخال بريد إلكتروني صالح'
                                                        : 'Please enter a valid email';
                                                  }
                                                  return null;
                                                },
                                              ),
                                              const SizedBox(height: 16),
                                              TextFormField(
                                                controller: _passwordController,
                                                obscureText: _obscurePassword,
                                                decoration: InputDecoration(
                                                  labelText: isArabic ? 'كلمة المرور' : 'Password',
                                                  prefixIcon: const Icon(Icons.lock_outline),
                                                  border: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  suffixIcon: IconButton(
                                                    icon: Icon(
                                                      _obscurePassword
                                                          ? Icons.visibility_off_outlined
                                                          : Icons.visibility_outlined,
                                                    ),
                                                    onPressed: () {
                                                      setState(() {
                                                        _obscurePassword = !_obscurePassword;
                                                      });
                                                    },
                                                  ),
                                                ),
                                                validator: (value) {
                                                  if (value == null || value.isEmpty) {
                                                    return isArabic
                                                        ? 'يرجى إدخال كلمة المرور'
                                                        : 'Please enter password';
                                                  }
                                                  if (value.length < 6) {
                                                    return isArabic
                                                        ? 'كلمة المرور يجب أن لا تقل عن 6 خانات'
                                                        : 'Password must be at least 6 characters';
                                                  }
                                                  return null;
                                                },
                                              ),
                                              if (_isSignUp) ...[
                                                const SizedBox(height: 16),
                                                TextFormField(
                                                  controller: _confirmPasswordController,
                                                  obscureText: _obscureConfirmPassword,
                                                  decoration: InputDecoration(
                                                    labelText: isArabic ? 'تأكيد كلمة المرور' : 'Confirm Password',
                                                    prefixIcon: const Icon(Icons.lock_clock_outlined),
                                                    border: OutlineInputBorder(
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                    suffixIcon: IconButton(
                                                      icon: Icon(
                                                        _obscureConfirmPassword
                                                            ? Icons.visibility_off_outlined
                                                            : Icons.visibility_outlined,
                                                      ),
                                                      onPressed: () {
                                                        setState(() {
                                                          _obscureConfirmPassword = !_obscureConfirmPassword;
                                                        });
                                                      },
                                                    ),
                                                  ),
                                                  validator: (value) {
                                                    if (_isSignUp) {
                                                      if (value == null || value.isEmpty) {
                                                        return isArabic
                                                            ? 'يرجى تأكيد كلمة المرور'
                                                            : 'Please confirm password';
                                                      }
                                                      if (value.trim() != _passwordController.text.trim()) {
                                                        return isArabic
                                                            ? 'كلمتا المرور غير متطابقتين'
                                                            : 'Passwords do not match';
                                                      }
                                                    }
                                                    return null;
                                                  },
                                                ),
                                              ],
                                              if (_isSignUp) ...[
                                                const SizedBox(height: 12),
                                                Material(
                                                  color: Colors.transparent,
                                                  child: CheckboxListTile(
                                                    value: _isPolicyAccepted,
                                                    onChanged: (val) {
                                                      setState(() {
                                                        _isPolicyAccepted = val ?? false;
                                                      });
                                                    },
                                                    controlAffinity: ListTileControlAffinity.leading,
                                                    contentPadding: EdgeInsets.zero,
                                                    dense: true,
                                                    title: GestureDetector(
                                                      onTap: () => _showPrivacyPolicy(context, isArabic),
                                                      child: Text(
                                                        isArabic
                                                            ? 'أوافق على سياسة الخصوصية وحماية البيانات المعمول بها في الأردن ودول الخليج العربي، وأقر بمسؤوليتي المهنية عن تطبيق خطوات السلامة (OSHA).'
                                                            : 'I agree to the Privacy Policy applicable in Jordan & GCC, and adhere to OSHA safety standards.',
                                                        style: const TextStyle(
                                                          fontSize: 12,
                                                          color: Color(0xFF334155),
                                                          height: 1.4,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                              const SizedBox(height: 20),
                                              ElevatedButton(
                                                onPressed: canProceed ? _submit : null,
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: const Color(0xFF0F172A),
                                                  foregroundColor: Colors.white,
                                                  disabledBackgroundColor: Colors.grey.shade300,
                                                  disabledForegroundColor: Colors.grey.shade500,
                                                  padding: const EdgeInsets.symmetric(vertical: 15),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  elevation: 2,
                                                ),
                                                child: Text(
                                                  _isSignUp
                                                      ? (isArabic ? 'تأكيد التسجيل وإنشاء الحساب' : 'Confirm Registration & Sign Up')
                                                      : (isArabic ? 'تسجيل الدخول' : 'Sign In'),
                                                  style: const TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.bold,
                                                    fontFamily: 'Cairo',
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 12),
                                              ElevatedButton(
                                                onPressed: canProceed ? _signInWithGoogle : null,
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.white,
                                                  foregroundColor: const Color(0xFF1E293B),
                                                  disabledBackgroundColor: Colors.grey.shade100,
                                                  disabledForegroundColor: Colors.grey.shade400,
                                                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  elevation: 0,
                                                ),
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    // Official Google "G" colored logo
                                                    RichText(
                                                      text: const TextSpan(
                                                        style: TextStyle(
                                                          fontSize: 22,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                        children: [
                                                          TextSpan(text: 'G', style: TextStyle(color: Color(0xFF4285F4))),
                                                        ],
                                                      ),
                                                    ),
                                                    const SizedBox(width: 10),
                                                    Flexible(
                                                      child: Text(
                                                        isArabic ? 'تسجيل الدخول عن طريق حساب Google' : 'Sign in with Google Account',
                                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(height: 10),
                                              ElevatedButton(
                                                onPressed: canProceed ? _continueAsGuest : null,
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: const Color(0xFF0F75BC),
                                                  foregroundColor: Colors.white,
                                                  disabledBackgroundColor: const Color(0xFFE2E8F0),
                                                  disabledForegroundColor: Colors.grey.shade400,
                                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  elevation: 2,
                                                ),
                                                child: Text(
                                                  isArabic ? 'ابدأ الآن كضيف ➡️' : 'Start as Guest ➡️',
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                    fontFamily: 'Cairo',
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 16),
                                              TextButton(
                                                onPressed: _toggleAuthMode,
                                                child: Text(
                                                  _isSignUp
                                                      ? (isArabic ? 'لديك حساب بالفعل؟ سجل دخولك' : 'Already have an account? Sign In')
                                                      : (isArabic ? 'ليس لديك حساب؟ اشترك الآن' : "Don't have an account? Sign Up"),
                                                  style: const TextStyle(
                                                    color: Color(0xFF2563EB),
                                                    fontWeight: FontWeight.w600,
                                                    fontFamily: 'Cairo',
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ],
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
            ],
          ),
        ),
      ),
    );
  }
}
