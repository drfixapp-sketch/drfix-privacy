import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:dr_fix/firebase_options.dart';

/// 👤 نموذج بيانات المستخدم الخاص بـ Dr Fix مع دعم التحقق بالبريد (isVerified)
class AppUser {
  final String uid;
  final String? displayName;
  final String? email;
  final String? photoUrl;
  final bool isGuest;
  final bool isVerified;

  AppUser({
    required this.uid,
    this.displayName,
    this.email,
    this.photoUrl,
    required this.isGuest,
    this.isVerified = true,
  });

  factory AppUser.guest() {
    return AppUser(
      uid: 'GUEST_${DateTime.now().millisecondsSinceEpoch}',
      displayName: 'زائر التطبيق',
      email: 'guest@local',
      isGuest: true,
      isVerified: true,
    );
  }

  AppUser copyWith({
    String? uid,
    String? displayName,
    String? email,
    String? photoUrl,
    bool? isGuest,
    bool? isVerified,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      isGuest: isGuest ?? this.isGuest,
      isVerified: isVerified ?? this.isVerified,
    );
  }

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'displayName': displayName,
        'email': email,
        'photoUrl': photoUrl,
        'isGuest': isGuest,
        'isVerified': isVerified,
      };

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        uid: json['uid'] ?? '',
        displayName: json['displayName'],
        email: json['email'],
        photoUrl: json['photoUrl'],
        isGuest: json['isGuest'] ?? false,
        isVerified: json['isVerified'] ?? true,
      );
}

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unverified, // جلسة تتطلب إدخال كود OTP السري لتفعيل الحساب
  unauthenticated,
}

/// 🛡️ حالة المصادقة الموحدة
class AuthState {
  final AppUser? user;
  final AuthStatus status;
  final String? errorMessage;
  final String? errorCode;

  AuthState({
    this.user,
    required this.status,
    this.errorMessage,
    this.errorCode,
  });

  factory AuthState.initial() => AuthState(status: AuthStatus.initial);
  factory AuthState.loading() => AuthState(status: AuthStatus.loading);
  factory AuthState.authenticated(AppUser user) => AuthState(user: user, status: AuthStatus.authenticated);
  factory AuthState.unverified(AppUser user) => AuthState(user: user, status: AuthStatus.unverified);
  factory AuthState.unauthenticated({String? error, String? code}) => AuthState(status: AuthStatus.unauthenticated, errorMessage: error, errorCode: code);

  AuthState copyWith({
    AppUser? user,
    AuthStatus? status,
    String? errorMessage,
    String? errorCode,
  }) {
    return AuthState(
      user: user ?? this.user,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      errorCode: errorCode ?? this.errorCode,
    );
  }
}

/// 🔐 مزود إدارة حالة الجلسة والمصادقة (Authentication State Provider)
class AuthNotifier extends StateNotifier<AuthState> {
  static const String _userCacheKey = 'dr_fix_cached_user';
  fb_auth.FirebaseAuth? _firebaseAuth;
  FirebaseFirestore? _firestore;

  /// 🔄 دالة المرونة والتهيئة الذاتية لـ Firebase (Self-Healing Firebase Connector)
  Future<fb_auth.FirebaseAuth?> _ensureActiveFirebaseAuth() async {
    if (Firebase.apps.isEmpty) {
      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      } catch (e) {
        debugPrint("Self-healing Firebase init attempt: $e");
      }
    }
    if (Firebase.apps.isEmpty) {
      return null;
    }
    _firebaseAuth ??= fb_auth.FirebaseAuth.instance;
    return _firebaseAuth;
  }

  FirebaseFirestore? _getFirestore() {
    if (Firebase.apps.isNotEmpty) {
      _firestore ??= FirebaseFirestore.instance;
      return _firestore;
    }
    return null;
  }

  AuthNotifier() : super(AuthState.initial()) {
    _initializeAuth();
  }

  /// 🔄 بدء التحقق من الجلسة المخزنة عند الإقلاع مع دعم الكاش المحلي لـ is_verified
  Future<void> _initializeAuth() async {
    state = AuthState.loading();
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // أولاً: فحص التخزين المحلي السريع (Local Cache) لتوفير الباقة وسرعة التشغيل
      final String? cachedUserStr = prefs.getString(_userCacheKey);
      AppUser? cachedUser;
      if (cachedUserStr != null) {
        try {
          final Map<String, dynamic> userMap = jsonDecode(cachedUserStr) as Map<String, dynamic>;
          cachedUser = AppUser.fromJson(userMap);
        } catch (e) {
          debugPrint("Failed decoding cached user: $e");
        }
      }

      // ثانياً: التحقق من وجود مستخدم مسجل عبر Firebase عند توفر التطبيق
      final firebaseAuth = await _ensureActiveFirebaseAuth();
      if (firebaseAuth != null) {
        final fb_auth.User? currentUser = firebaseAuth.currentUser;
        if (currentUser != null) {
          // إذا كان مسجلاً في الكاش المحلي كـ verified، نعتمد الكاش مباشرة دون استعلام Firestore لتوفير الباقة
          bool verified = cachedUser != null && cachedUser.uid == currentUser.uid
              ? cachedUser.isVerified
              : false;

          // إذا لم تكن مؤكدة في الكاش، نتحقق لمرة واحدة من Firestore ونخزنها محلياً
          if (!verified) {
            final fs = _getFirestore();
            if (fs != null) {
              try {
                final userDoc = await fs.collection('users').doc(currentUser.uid).get();
                if (userDoc.exists) {
                  verified = userDoc.data()?['is_verified'] == true;
                }
              } catch (e) {
                debugPrint("Error fetching is_verified from Firestore: $e");
              }
            }
          }

          final user = AppUser(
            uid: currentUser.uid,
            displayName: currentUser.displayName ?? (cachedUser?.displayName ?? 'فني Dr Fix'),
            email: currentUser.email,
            photoUrl: currentUser.photoURL,
            isGuest: false,
            isVerified: verified,
          );

          if (!verified) {
            state = AuthState.unverified(user);
          } else {
            state = AuthState.authenticated(user);
          }
          await _cacheUser(user);
          return;
        }
      }

      // ثالثاً: فحص وجود مستخدم زائر نشط من الكاش المحلي
      if (cachedUser != null && cachedUser.isGuest) {
        state = AuthState.authenticated(cachedUser);
        return;
      }

      // رابعاً: لا توجد جلسة نشطة
      state = AuthState.unauthenticated();
    } catch (e) {
      debugPrint("Auth init error: $e");
      state = AuthState.unauthenticated(error: e.toString());
    }
  }

  /// 🌐 تسجيل الدخول عن طريق حساب جوجل (Sign in with Google)
  Future<bool> signInWithGoogle() async {
    state = AuthState.loading();
    try {
      final firebaseAuth = await _ensureActiveFirebaseAuth();
      if (firebaseAuth == null) {
        state = AuthState.unauthenticated(error: 'Firebase غير متوفر حالياً. يمكنك المتابعة كزائر.');
        return false;
      }

      fb_auth.UserCredential credential;

      if (kIsWeb) {
        // ── Web: استخدام Popup كما كان ──
        final googleProvider = fb_auth.GoogleAuthProvider();
        credential = await firebaseAuth.signInWithPopup(googleProvider);
      } else {
        // ── Android / iOS: استخدام google_sign_in native flow ──
        final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
        if (googleUser == null) {
          // المستخدم أغلق شاشة الاختيار
          state = AuthState.unauthenticated(error: 'تم إلغاء تسجيل الدخول.');
          return false;
        }
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final authCredential = fb_auth.GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        credential = await firebaseAuth.signInWithCredential(authCredential);
      }

      final fb_auth.User? fbUser = credential.user;
      if (fbUser != null) {
        final user = AppUser(
          uid: fbUser.uid,
          displayName: fbUser.displayName ?? 'مستخدم جوجل المعتمد',
          email: fbUser.email,
          photoUrl: fbUser.photoURL,
          isGuest: false,
          isVerified: true, // حسابات جوجل موثقة تلقائياً
        );
        state = AuthState.authenticated(user);
        await _cacheUser(user);
        return true;
      }

      state = AuthState.unauthenticated(error: 'فشل استرجاع بيانات المستخدم من جوجل');
      return false;
    } catch (e) {
      debugPrint("Google sign-in unavailable: $e");
      state = AuthState.unauthenticated(error: 'Google sign-in not available right now. Please continue as guest.');
      return false;
    }
  }

  /// 🍎 تسجيل الدخول عن طريق حساب Apple (Sign in with Apple - iOS حصرياً)
  Future<bool> signInWithApple() async {
    state = AuthState.loading();
    try {
      final firebaseAuth = await _ensureActiveFirebaseAuth();
      if (firebaseAuth == null) {
        state = AuthState.unauthenticated(error: 'Firebase غير متوفر حالياً. يمكنك المتابعة كزائر.');
        return false;
      }

      final appleProvider = fb_auth.AppleAuthProvider();
      appleProvider.addScope('email');
      appleProvider.addScope('name');

      final fb_auth.UserCredential credential = await firebaseAuth.signInWithProvider(appleProvider);
      final fb_auth.User? fbUser = credential.user;

      if (fbUser != null) {
        final user = AppUser(
          uid: fbUser.uid,
          displayName: fbUser.displayName ?? 'مستخدم Apple المعتمد',
          email: fbUser.email,
          photoUrl: fbUser.photoURL,
          isGuest: false,
          isVerified: true,
        );
        state = AuthState.authenticated(user);
        await _cacheUser(user);
        return true;
      }

      state = AuthState.unauthenticated(error: 'فشل استرجاع بيانات المستخدم من Apple');
      return false;
    } catch (e) {
      debugPrint("Apple sign-in error: $e");
      state = AuthState.unauthenticated(error: 'Apple sign-in غير متوفر حالياً.');
      return false;
    }
  }

  /// 📧 تسجيل الدخول بالبريد الإلكتروني وكلمة المرور (Sign In with Email & Password)
  Future<bool> signInWithEmailAndPassword(String email, String password) async {
    state = AuthState.loading();
    try {
      final firebaseAuth = await _ensureActiveFirebaseAuth();
      if (firebaseAuth == null) {
        state = AuthState.unauthenticated(error: 'Firebase غير متوفر حالياً. يمكنك المتابعة كزائر.');
        return false;
      }

      final credential = await firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final fb_auth.User? fbUser = credential.user;
      if (fbUser != null) {
        // التحقق من حالة التفعيل: الكاش المحلي أولاً ثم Firestore
        bool isVerified = false;
        final prefs = await SharedPreferences.getInstance();
        final cachedStr = prefs.getString(_userCacheKey);
        if (cachedStr != null) {
          try {
            final cachedMap = jsonDecode(cachedStr) as Map<String, dynamic>;
            if (cachedMap['uid'] == fbUser.uid && cachedMap['isVerified'] == true) {
              isVerified = true;
            }
          } catch (_) {}
        }

        if (!isVerified) {
          final fs = _getFirestore();
          if (fs != null) {
            try {
              final userDoc = await fs.collection('users').doc(fbUser.uid).get();
              if (userDoc.exists) {
                isVerified = userDoc.data()?['is_verified'] == true;
              }
            } catch (e) {
              debugPrint("Firestore is_verified check error: $e");
            }
          }
        }

        final user = AppUser(
          uid: fbUser.uid,
          displayName: fbUser.displayName ?? email.trim().split('@').first,
          email: fbUser.email,
          photoUrl: fbUser.photoURL,
          isGuest: false,
          isVerified: isVerified,
        );

        if (!isVerified) {
          // ✅ [Spark-Bypass] تجاوز OTP: تفعيل الحساب محلياً وفي Firestore مباشرة
          isVerified = true;
          final fs = _getFirestore();
          if (fs != null) {
            try {
              await fs.collection('users').doc(fbUser.uid).update({
                'is_verified': true,
                'verified_at': FieldValue.serverTimestamp(),
              });
            } catch (e) {
              debugPrint("Auto-verify on login Firestore update error: $e");
            }
          }
        }

        state = AuthState.authenticated(user);
        await _cacheUser(user);
        return true;
      }

      state = AuthState.unauthenticated(error: 'فشل استرجاع بيانات المستخدم');
      return false;
    } on fb_auth.FirebaseAuthException catch (e) {
      String errorMsg = 'حدث خطأ أثناء تسجيل الدخول';
      if (e.code == 'operation-not-allowed') {
        errorMsg = 'خدمة تسجيل الدخول بالبريد الإلكتروني غير مفعّلة في لوحة تحكم المشروع (Firebase Console). يرجى تفعيل Email/Password في قسم Sign-in method.';
      } else if (e.code == 'user-not-found') {
        errorMsg = 'لا يوجد حساب مسجل بهذا البريد الإلكتروني. يمكنك إنشاء حساب جديد الآن.';
      } else if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        errorMsg = 'بيانات تسجيل الدخول أو كلمة المرور غير صحيحة. يرجى التأكد وإعادة المحاولة.';
      } else if (e.code == 'invalid-email') {
        errorMsg = 'صيغة البريد الإلكتروني غير صحيحة، يرجى إدخال بريد صالح مثل name@example.com.';
      } else if (e.code == 'user-disabled') {
        errorMsg = 'تم تعطيل هذا الحساب مؤقتاً من قبل الإدارة.';
      } else if (e.code == 'network-request-failed') {
        errorMsg = 'تعذر الاتصال بالسيرفر السحابي. يرجى التحقق من اتصالك بالإنترنت والمحاولة مجدداً.';
      } else if (e.code == 'too-many-requests') {
        errorMsg = 'تم حظر الطلبات مؤقتاً بسبب المحاولات المتكررة. يرجى الانتظار دقيقة واحدة ثم إعادة المحاولة.';
      } else if (e.message != null && e.message!.isNotEmpty) {
        errorMsg = e.message!;
      }
      state = AuthState.unauthenticated(error: errorMsg, code: e.code);
      return false;
    } catch (e) {
      state = AuthState.unauthenticated(error: e.toString());
      return false;
    }
  }

  /// 📝 إنشاء حساب جديد بالبريد الإلكتروني وكلمة المرور وتوليد كود OTP للتأكيد
  Future<bool> signUpWithEmailAndPassword(String email, String password, String displayName) async {
    state = AuthState.loading();
    try {
      final firebaseAuth = await _ensureActiveFirebaseAuth();
      if (firebaseAuth == null) {
        state = AuthState.unauthenticated(error: 'Firebase غير متوفر حالياً. يمكنك المتابعة كزائر.');
        return false;
      }

      final credential = await firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final fb_auth.User? fbUser = credential.user;
      if (fbUser != null) {
        if (displayName.trim().isNotEmpty) {
          try {
            await fbUser.updateDisplayName(displayName.trim());
          } catch (_) {}
        }

        // ✅ [Spark-Bypass] تفعيل الحساب فوراً بعد إنشائه دون OTP (توفيراً لاستهلاك Cloud Functions)
        final user = AppUser(
          uid: fbUser.uid,
          displayName: displayName.trim().isNotEmpty ? displayName.trim() : email.trim().split('@').first,
          email: fbUser.email,
          photoUrl: fbUser.photoURL,
          isGuest: false,
          isVerified: true, // ✅ مُفعَّل مباشرة — لا حاجة لـ OTP
        );

        // إنشاء مستند المستخدم في Firestore بحالة is_verified = true مباشرة
        final fs = _getFirestore();
        if (fs != null) {
          try {
            await fs.collection('users').doc(user.uid).set({
              'uid': user.uid,
              'email': user.email,
              'display_name': user.displayName,
              'is_verified': true, // ✅ مُفعَّل فوراً
              'created_at': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
          } catch (e) {
            debugPrint("Firestore user doc creation error: $e");
          }
        }

        // ℹ️ [OTP Disabled] _generateAndStoreOtp معطَّلة — الحساب يُفعَّل تلقائياً
        // يمكن إعادة تفعيلها عند الترقية لباقة Blaze لاحقاً

        state = AuthState.authenticated(user); // ✅ تخطي unverified مباشرة للـ HomeScreen
        await _cacheUser(user);
        return true;
      }

      state = AuthState.unauthenticated(error: 'فشل إنشاء الحساب الجديد');
      return false;
    } on fb_auth.FirebaseAuthException catch (e) {
      String errorMsg = 'حدث خطأ أثناء إنشاء الحساب';
      if (e.code == 'operation-not-allowed') {
        errorMsg = 'خدمة تسجيل الدخول بالبريد الإلكتروني غير مفعّلة في لوحة تحكم المشروع (Firebase Console). يرجى تفعيل Email/Password في قسم Sign-in method.';
      } else if (e.code == 'email-already-in-use') {
        errorMsg = 'هذا البريد الإلكتروني مسجل بالفعل بحساب آخر. يمكنك الانتقال لتسجيل الدخول مباشرة.';
      } else if (e.code == 'weak-password') {
        errorMsg = 'كلمة المرور ضعيفة جداً، يرجى إدخال كلمة مرور تتكون من 6 خانات أو رموز أكثر قوة.';
      } else if (e.code == 'invalid-email') {
        errorMsg = 'صيغة البريد الإلكتروني غير صحيحة، يرجى إدخال بريد صالح مثل name@example.com.';
      } else if (e.code == 'network-request-failed') {
        errorMsg = 'تعذر الاتصال بالسيرفر السحابي. يرجى التحقق من اتصالك بالإنترنت والمحاولة مجدداً.';
      } else if (e.code == 'too-many-requests') {
        errorMsg = 'تم حظر الطلبات مؤقتاً بسبب المحاولات المتكررة. يرجى الانتظار دقيقة واحدة ثم إعادة المحاولة.';
      } else if (e.message != null && e.message!.isNotEmpty) {
        errorMsg = e.message!;
      }
      state = AuthState.unauthenticated(error: errorMsg, code: e.code);
      return false;
    } catch (e) {
      state = AuthState.unauthenticated(error: e.toString());
      return false;
    }
  }

  /// 🔢 توليد كود OTP من 6 أرقام وتخزينه في مسار: users/{uid}/security/email_otp
  /// وتفعيل إرسال البريد فورياً عبر مجموعة mail التابعة لامتداد Firebase Trigger Email
  Future<String?> _generateAndStoreOtp(String uid, String email) async {
    final random = Random.secure();
    final otpCode = (100000 + random.nextInt(900000)).toString();
    final now = DateTime.now();
    final expiresAt = now.add(const Duration(hours: 24));

    final fs = _getFirestore();
    if (fs != null) {
      try {
        // 1. حفظ كود الـ OTP في المسار المحمي للمستخدم
        await fs
            .collection('users')
            .doc(uid)
            .collection('security')
            .doc('email_otp')
            .set({
          'code': otpCode,
          'email': email,
          'created_at': Timestamp.fromDate(now),
          'expires_at': Timestamp.fromDate(expiresAt),
          'attempts': 0,
        });

        // 2. إنشاء مستند إرسال البريد التلقائي لـ Firebase Trigger Email Extension / Cloud Function
        await fs.collection('mail').add({
          'to': [email],
          'message': {
            'subject': 'رمز التحقق من حسابك في تطبيق Dr. Fix ($otpCode)',
            'text': 'مرحباً بك في منصة Dr. Fix الهندسية.\nرمز التحقق الخاص بك هو: $otpCode\nصلاحية هذا الرمز هي 24 ساعة فقط.',
            'html': '''
              <div dir="rtl" style="font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; max-width: 520px; margin: 0 auto; padding: 24px; border: 1px solid #e2e8f0; border-radius: 16px; background-color: #ffffff;">
                <div style="text-align: center; margin-bottom: 24px;">
                  <h1 style="color: #0f172a; margin: 0; font-size: 24px;">د. فيكس | Dr. Fix</h1>
                  <p style="color: #64748b; font-size: 13px; margin-top: 4px;">منصة التشخيص الهندسي والذكاء الاصطناعي</p>
                </div>
                <div style="background-color: #f8fafc; border-radius: 12px; padding: 20px; text-align: center; margin-bottom: 20px;">
                  <p style="color: #334155; font-size: 14px; margin-bottom: 12px;">رمز التحقق السري لتفعيل حسابك:</p>
                  <div style="font-size: 32px; font-weight: bold; letter-spacing: 8px; color: #0f172a; background: #ffffff; padding: 12px 24px; border-radius: 8px; display: inline-block; border: 1px solid #cbd5e1;">
                    $otpCode
                  </div>
                  <p style="color: #ef4444; font-size: 12px; margin-top: 14px; font-weight: bold;">⏱️ صلاحية الرمز: 24 ساعة فقط</p>
                </div>
                <p style="color: #64748b; font-size: 12px; line-height: 1.6; text-align: justify; margin: 0;">
                  إذا لم تقم بطلب هذا الرمز، يرجى تجاهل هذه الرسالة. لا تشارك هذا الرمز مع أي شخص لحماية بياناتك.
                </p>
                <hr style="border: none; border-top: 1px solid #e2e8f0; margin: 20px 0;" />
                <p style="color: #94a3b8; font-size: 11px; text-align: center; margin: 0;">© 2026 Dr. Fix Engineering Platform. All rights reserved.</p>
              </div>
            ''',
          },
          'created_at': FieldValue.serverTimestamp(),
          'uid': uid,
        });
      } catch (e) {
        debugPrint("Error saving OTP or Trigger Email to Firestore: $e");
      }
    }

    // حفظ كاش محلي مؤقت للكود وطباعته حصرياً في بيئة التطوير والاختبار (محجوب تماماً في الإنتاج)
    if (kDebugMode) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('dr_fix_pending_otp_$uid', otpCode);
      await prefs.setString('dr_fix_pending_otp_expires_$uid', expiresAt.toIso8601String());
      debugPrint("🔑 [Email OTP Generated] Code: $otpCode | Sent to: $email | Trigger Email Queued");
    }
    return otpCode;
  }

  /// 🔁 إعادة إرسال كود OTP جديد (Resend OTP)
  Future<bool> resendEmailOtp() async {
    final currentUser = state.user;
    if (currentUser == null || currentUser.email == null) {
      return false;
    }
    try {
      await _generateAndStoreOtp(currentUser.uid, currentUser.email!);
      return true;
    } catch (e) {
      debugPrint("Error resending OTP: $e");
      return false;
    }
  }

  /// ✅ التحقق من صحة كود الـ OTP وتفعيل الحساب (is_verified = true)
  Future<bool> verifyEmailOtp(String enteredCode) async {
    final currentUser = state.user;
    if (currentUser == null) return false;

    final trimmedCode = enteredCode.trim();
    if (trimmedCode.length != 6) return false;

    try {
      bool isMatch = false;
      bool isExpired = false;

      // 1. الفحص من Firestore
      final fs = _getFirestore();
      if (fs != null) {
        try {
          final otpDoc = await fs
              .collection('users')
              .doc(currentUser.uid)
              .collection('security')
              .doc('email_otp')
              .get();

          if (otpDoc.exists) {
            final data = otpDoc.data()!;
            final expectedCode = data['code']?.toString() ?? '';
            final Timestamp? expiresTimestamp = data['expires_at'] as Timestamp?;
            if (expiresTimestamp != null && expiresTimestamp.toDate().isBefore(DateTime.now())) {
              isExpired = true;
            } else if (expectedCode == trimmedCode) {
              isMatch = true;
            }
          }
        } catch (e) {
          debugPrint("Error reading OTP doc from Firestore: $e");
        }
      }

      // 2. الفحص من الكاش المحلي كبديل سريع في حال ضعف الاتصال
      if (!isMatch && !isExpired) {
        final prefs = await SharedPreferences.getInstance();
        final localOtp = prefs.getString('dr_fix_pending_otp_${currentUser.uid}');
        final localExpStr = prefs.getString('dr_fix_pending_otp_expires_${currentUser.uid}');
        if (localExpStr != null) {
          final localExp = DateTime.tryParse(localExpStr);
          if (localExp != null && localExp.isBefore(DateTime.now())) {
            isExpired = true;
          }
        }
        if (!isExpired && localOtp == trimmedCode) {
          isMatch = true;
        }
      }

      if (isExpired) {
        state = state.copyWith(
          errorMessage: 'انتهت صلاحية الرمز السري (24 ساعة). يرجى الضغط على إعادة إرسال الرمز.',
        );
        return false;
      }

      if (!isMatch) {
        state = state.copyWith(
          errorMessage: 'الرمز المدخل غير صحيح. يرجى التأكد وإعادة المحاولة.',
        );
        return false;
      }

      // 3. نجاح المطابقة -> تفعيل الحساب في Firestore
      if (fs != null) {
        try {
          await fs.collection('users').doc(currentUser.uid).update({
            'is_verified': true,
            'verified_at': FieldValue.serverTimestamp(),
          });
          // حذف وثيقة الـ OTP بعد الاستخدام لمنع إعادة استخدامها
          await fs
              .collection('users')
              .doc(currentUser.uid)
              .collection('security')
              .doc('email_otp')
              .delete();
        } catch (e) {
          debugPrint("Error updating is_verified in Firestore: $e");
        }
      }

      // 4. تحديث الكاش المحلي وتغيير الحالة إلى authenticated
      final updatedUser = currentUser.copyWith(isVerified: true);
      await _cacheUser(updatedUser);

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('dr_fix_pending_otp_${currentUser.uid}');
      await prefs.remove('dr_fix_pending_otp_expires_${currentUser.uid}');

      state = AuthState.authenticated(updatedUser);
      return true;
    } catch (e) {
      debugPrint("OTP verification error: $e");
      state = state.copyWith(errorMessage: 'تعذر التحقق من الرمز: $e');
      return false;
    }
  }

  /// 👤 الدخول كزائر (Continue as Guest)
  Future<void> signInAsGuest() async {
    state = AuthState.loading();
    try {
      await Future.delayed(const Duration(milliseconds: 600));
      final guestUser = AppUser.guest();
      state = AuthState.authenticated(guestUser);
      await _cacheUser(guestUser);
    } catch (e) {
      state = AuthState.unauthenticated(error: e.toString());
    }
  }

  /// 🚪 تسجيل الخروج (Sign Out)
  Future<void> signOut() async {
    state = AuthState.loading();
    try {
      final firebaseAuth = await _ensureActiveFirebaseAuth();
      if (firebaseAuth != null) {
        await firebaseAuth.signOut();
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userCacheKey);
      state = AuthState.unauthenticated();
    } catch (e) {
      state = AuthState.unauthenticated(error: e.toString());
    }
  }

  /// 🗑️ حذف الحساب بالكامل للامتثال لسياسات Google/Apple
  Future<bool> deleteAccount() async {
    try {
      state = AuthState.loading();
      
      final firebaseAuth = await _ensureActiveFirebaseAuth();
      if (firebaseAuth != null) {
        final currentUser = firebaseAuth.currentUser;
        if (currentUser != null) {
          final uid = currentUser.uid;
          final fs = _getFirestore();
          if (fs != null) {
            try {
              await fs.collection('users').doc(uid).delete();
            } catch (_) {}
          }
          await currentUser.delete();
        }
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userCacheKey);
      
      state = AuthState.unauthenticated();
      return true;
    } on fb_auth.FirebaseAuthException catch (e) {
      debugPrint("Account deletion FirebaseAuthException: ${e.code}");
      String errorMsg = 'تعذر حذف الحساب حالياً. يرجى المحاولة لاحقاً.';
      if (e.code == 'requires-recent-login') {
        errorMsg = 'لحماية بياناتك، يتطلب حذف الحساب تسجيل الدخول من جديد لتأكيد هويتك. يرجى إعادة تسجيل الدخول ثم إعادة المحاولة.';
      } else if (e.message != null && e.message!.isNotEmpty) {
        errorMsg = e.message!;
      }
      state = AuthState.unauthenticated(error: errorMsg, code: e.code);
      return false;
    } catch (e) {
      debugPrint("Account deletion failed: $e");
      state = AuthState.unauthenticated(error: 'يتطلب حذف الحساب إعادة تسجيل الدخول لتأكيد الهوية حمايةً لبياناتك.');
      return false;
    }
  }

  /// حفظ بيانات الجلسة محلياً للتذكر
  Future<void> _cacheUser(AppUser user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userCacheKey, jsonEncode(user.toJson()));
    } catch (e) {
      debugPrint("Error caching user session: $e");
    }
  }
}

/// المزود العالمي للمصادقة وإدارة الجلسة بالـ Riverpod
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
