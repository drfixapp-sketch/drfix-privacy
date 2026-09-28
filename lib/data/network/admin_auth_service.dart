import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// نموذج صلاحيات المشرفين الفرعية
class AdminPermissions {
  final bool isSuperAdmin;
  final bool canApproveFaults;
  final bool canManagePromos;
  final bool canManageTickets;

  const AdminPermissions({
    required this.isSuperAdmin,
    required this.canApproveFaults,
    required this.canManagePromos,
    required this.canManageTickets,
  });

  factory AdminPermissions.superAdmin() => const AdminPermissions(
    isSuperAdmin: true,
    canApproveFaults: true,
    canManagePromos: true,
    canManageTickets: true,
  );

  factory AdminPermissions.fromFirestore(Map<String, dynamic> data) => AdminPermissions(
    isSuperAdmin: false,
    canApproveFaults: data['can_approve_faults'] as bool? ?? false,
    canManagePromos: data['can_manage_promos'] as bool? ?? false,
    canManageTickets: data['can_manage_tickets'] as bool? ?? true,
  );
}

/// نتيجة فحص ومصادقة المشرف
class AdminAuthResult {
  final bool isAuthorized;
  final String? errorMessage;
  final User? user;
  final AdminPermissions? permissions;

  const AdminAuthResult({
    required this.isAuthorized,
    this.errorMessage,
    this.user,
    this.permissions,
  });

  factory AdminAuthResult.authorized({required User user, required AdminPermissions permissions}) =>
      AdminAuthResult(isAuthorized: true, user: user, permissions: permissions);

  factory AdminAuthResult.unauthorized(String message) =>
      AdminAuthResult(isAuthorized: false, errorMessage: message);
}

/// خدمة إدارة وتأمين صلاحيات المشرفين
class AdminAuthService {
  static const String superAdminEmail = "drfixapp@gmail.com";
  static AdminPermissions? activePermissions;

  static const String _passKey = "admin_secure_password";
  static const String _defaultPassword = "053655";

  /// مصادقة المشرف عبر Firebase Auth والتحقق من الصلاحيات
  static Future<AdminAuthResult> authenticateAdmin({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    if (cleanEmail.isEmpty || password.isEmpty) {
      return AdminAuthResult.unauthorized('يرجى إدخال البريد الإلكتروني وكلمة المرور.');
    }

    try {
      if (Firebase.apps.isEmpty) {
        // Fallback في حال عدم توفر اتصال Firebase الفوري
        if (cleanEmail == superAdminEmail) {
          activePermissions = AdminPermissions.superAdmin();
          return AdminAuthResult(isAuthorized: true, permissions: activePermissions);
        }
      }

      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: cleanEmail,
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        return AdminAuthResult.unauthorized('فشلت المصادقة.');
      }

      // 1. فحص المالك الرئيسي (Super Admin)
      if (cleanEmail == superAdminEmail) {
        activePermissions = AdminPermissions.superAdmin();
        return AdminAuthResult.authorized(user: user, permissions: activePermissions!);
      }

      // 2. فحص مجموعة admins في Firestore للمشرفين الآخرين
      if (Firebase.apps.isNotEmpty) {
        final adminDoc = await FirebaseFirestore.instance.collection('admins').doc(user.uid).get();
        if (adminDoc.exists) {
          final data = adminDoc.data() ?? {};
          final bool isActive = data['is_active'] as bool? ?? true;
          if (isActive) {
            activePermissions = AdminPermissions.fromFirestore(data);
            return AdminAuthResult.authorized(user: user, permissions: activePermissions!);
          } else {
            await FirebaseAuth.instance.signOut();
            return AdminAuthResult.unauthorized('تم تعطيل حساب المشرف هذا من قبل الإدارة العليا.');
          }
        }
      }

      // في حال لم يكن مسجلاً في مجموعة المشرفين
      await FirebaseAuth.instance.signOut();
      return AdminAuthResult.unauthorized('هذا الحساب لا يمتلك صلاحيات إدارية كافية.');
    } on FirebaseAuthException catch (e) {
      String msg = 'خطأ في تسجيل الدخول: ${e.message}';
      if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
        msg = 'بيانات الاعتماد غير صحيحة. يرجى التحقق من البريد وكلمة المرور.';
      }
      return AdminAuthResult.unauthorized(msg);
    } catch (e) {
      return AdminAuthResult.unauthorized('حدث خطأ أثناء فحص الصلاحيات: $e');
    }
  }

  /// تحويل النص إلى SHA-256 Hash كدالة مساعدة
  static String _hashPassword(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  static Future<bool> verifyPassword(String input) async {
    final prefs = await SharedPreferences.getInstance();
    String? stored = prefs.getString(_passKey);

    if (stored != null && stored.length != 64) {
      final upgraded = _hashPassword(stored);
      await prefs.setString(_passKey, upgraded);
      stored = upgraded;
    }

    final currentHash = stored ?? _hashPassword(_defaultPassword);
    return _hashPassword(input) == currentHash;
  }

  static Future<bool> updatePassword(String oldPassword, String newPassword) async {
    final prefs = await SharedPreferences.getInstance();
    String? stored = prefs.getString(_passKey);

    if (stored != null && stored.length != 64) {
      stored = _hashPassword(stored);
      await prefs.setString(_passKey, stored);
    }

    final currentHash = stored ?? _hashPassword(_defaultPassword);
    if (_hashPassword(oldPassword) == currentHash) {
      await prefs.setString(_passKey, _hashPassword(newPassword));
      return true;
    }
    return false;
  }

  static Future<void> changeAdminPassword(String newPassword) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_passKey, _hashPassword(newPassword));
  }
}
