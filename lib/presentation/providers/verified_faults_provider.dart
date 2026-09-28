import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/models/verified_fault_model.dart';
import '../../data/network/admin_auth_service.dart';

/// 📡 مزود البث السحابي الحي والمباشر لـ (verified_faults)
/// ينقل التحديثات والحذف والإضافة لجميع هواتف الفنيين فوراً في أقل من 300 مللي ثانية
final liveVerifiedFaultsStreamProvider = StreamProvider<List<VerifiedFault>>((ref) {
  if (Firebase.apps.isEmpty) {
    return Stream.value(VerifiedFault.initialSeedData);
  }

  return FirebaseFirestore.instance
      .collection('verified_faults')
      .orderBy('created_at', descending: true)
      .snapshots()
      .map<List<VerifiedFault>>((snapshot) {
        if (snapshot.docs.isEmpty) {
          return VerifiedFault.initialSeedData;
        }
        return snapshot.docs.map<VerifiedFault>((doc) => VerifiedFault.fromFirestore(doc)).toList();
      })
      .handleError((error) {
        debugPrint('Error listening to verified_faults stream: $error');
      });
});

/// 🔍 مزود حالة نص البحث في الموسوعة
final verifiedFaultsSearchQueryProvider = StateProvider<String>((ref) => '');

/// 🏷️ مزود حالة القطاع المختار من التبويبات التسعة + الكل
final verifiedFaultsSelectedSectorProvider = StateProvider<String>((ref) => 'الكل');

/// ⚡ الفلترة الذكية الاقتصادية من جانب العميل (Client-Side Filtering)
/// تستهلك الـ Stream لمرة واحدة وتجري كافة عمليات الفلترة والبحث في ذاكرة جهاز الفني
/// لتوفير باقة الإنترنت الميدانية وتجنب أي قراءات إضافية من Firestore
final filteredVerifiedFaultsProvider = Provider<List<VerifiedFault>>((ref) {
  final AsyncValue<List<VerifiedFault>> streamAsync = ref.watch(liveVerifiedFaultsStreamProvider);
  
  // 1. تعيين النوع الصريح <List<VerifiedFault>> للـ when لمنع تفجير الـ dynamic
  final List<VerifiedFault> allFaults = streamAsync.when<List<VerifiedFault>>(
    data: (List<VerifiedFault> data) => data.isEmpty ? VerifiedFault.initialSeedData : data,
    loading: () => VerifiedFault.initialSeedData,
    error: (Object error, StackTrace stack) {
      debugPrint('⚠️ Firestore Stream failed. Serving Local Seed Data. Error: $error');
      return VerifiedFault.initialSeedData;
    },
  );
  
  final String rawSearch = ref.watch(verifiedFaultsSearchQueryProvider).trim();
  final String selectedSector = ref.watch(verifiedFaultsSelectedSectorProvider);

  String normalize(String text) {
    return text
        .toLowerCase()
        .replaceAll('ال', '')
        .replaceAll('ة', 'ه')
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .trim();
  }

  final String normalizedQuery = normalize(rawSearch);

  // 2. تعيين نوع المعامل VerifiedFault الصريح مع ضمان إرجاع bool
  return allFaults.where((VerifiedFault fault) {
    // فحص مطابقة القطاع الهندسي
    final bool matchesSector = selectedSector == 'الكل' || fault.sector == selectedSector;
    if (!matchesSector) return false;

    // فحص مطابقة البحث النصي
    if (normalizedQuery.isEmpty) return true;
    final String haystack = normalize('${fault.title} ${fault.description} ${fault.sector} ${fault.authorName}');
    return haystack.contains(normalizedQuery);
  }).toList();
});

/// 🛡️ دوال التحكم السحابي المباشر للأدمن وإدارة الصلاحيات (Admin & Author Governance Service)
class VerifiedFaultsAdminService {
  /// التحقق من صلاحيات المشرف العام أو المشرف المخول
  static bool isUserAdmin() {
    try {
      if (Firebase.apps.isNotEmpty) {
        final user = FirebaseAuth.instance.currentUser;
        final email = user?.email?.toLowerCase().trim();
        if (email == 'drfixapp@gmail.com') return true;
      }
    } catch (_) {}
    final perms = AdminAuthService.activePermissions;
    if (perms != null && (perms.isSuperAdmin || perms.canApproveFaults)) {
      return true;
    }
    return false;
  }

  /// التحقق مما إذا كان المستخدم الحالي هو كاتب هذا العطل الموثق
  static bool isAuthor(VerifiedFault fault) {
    try {
      if (Firebase.apps.isNotEmpty) {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) return false;

        final currentUid = user.uid;
        final currentEmail = user.email?.toLowerCase().trim();

        // 1. الفحص عبر الـ UID المسجل
        if (fault.authorId != null && fault.authorId!.isNotEmpty && fault.authorId == currentUid) {
          return true;
        }

        // 2. الفحص عبر البريد الإلكتروني للكاتب
        if (currentEmail != null && currentEmail.isNotEmpty) {
          if (fault.authorEmail != null && fault.authorEmail!.toLowerCase().trim() == currentEmail) {
            return true;
          }
        }

        // 3. الفحص عبر الاسم المسجل إن لم يكن اسماً افتراضياً عاماً
        final authorClean = fault.authorName.toLowerCase().trim();
        final isGeneric = authorClean.isEmpty ||
            authorClean == 'مهندس معتمد' ||
            authorClean == 'فني ميداني' ||
            authorClean == 'فني مجهول' ||
            authorClean == 'مجهول' ||
            authorClean == 'anonymous';
        if (!isGeneric) {
          final displayName = user.displayName?.toLowerCase().trim();
          if (displayName != null && displayName == authorClean) return true;
          if (currentEmail != null && currentEmail.split('@').first.toLowerCase() == authorClean) return true;
        }
      }
    } catch (_) {}
    return false;
  }

  /// 🔒 فحص الأهلية الشامل: هل يحق للمستخدم تعديل أو حذف هذا العطل؟
  /// الشروط الصارمة: إما مشرف معتمد (Admin) أو الكاتب الفعلي للمنشور (Author).
  static bool canManageFault(VerifiedFault fault) {
    return isUserAdmin() || isAuthor(fault);
  }

  /// حفظ أو تحديث عطل موثق في Firestore مع حماية خلفية صارمة
  static Future<bool> saveOrUpdateFault({
    required String id,
    required String title,
    required String description,
    required String sector,
    String? authorName,
    String? authorEmail,
    String? authorId,
    int? viewsCount,
  }) async {
    try {
      if (Firebase.apps.isEmpty) return false;

      // 🛡️ فحص الحماية الخلفية
      final user = FirebaseAuth.instance.currentUser;
      final bool isAdmin = isUserAdmin();

      if (!isAdmin) {
        if (user == null) {
          debugPrint('⛔ Access Denied: Anonymous/guest users cannot modify verified faults.');
          return false;
        }

        // في حال كان عطلاً قائماً، نتحقق من ملكية الكاتب من المستند السحابي
        final existingDoc = await FirebaseFirestore.instance.collection('verified_faults').doc(id).get();
        if (existingDoc.exists) {
          final data = existingDoc.data() ?? {};
          final existingAuthorId = data['author_id'] as String?;
          final existingAuthorEmail = (data['author_email'] as String?)?.toLowerCase().trim();
          final userEmail = user.email?.toLowerCase().trim();

          final bool isOwner = (existingAuthorId != null && existingAuthorId == user.uid) ||
              (existingAuthorEmail != null && userEmail != null && existingAuthorEmail == userEmail);

          if (!isOwner) {
            debugPrint('⛔ Access Denied: User ${user.uid} is not authorized to edit fault $id');
            return false;
          }
        }
      }

      final docRef = FirebaseFirestore.instance.collection('verified_faults').doc(id);
      final updateData = <String, dynamic>{
        'id': id,
        'title': title.trim(),
        'description': description.trim(),
        'sector': sector.trim(),
        'views_count': viewsCount ?? 1,
        'updated_at': FieldValue.serverTimestamp(),
      };

      if (authorName != null && authorName.isNotEmpty) {
        updateData['author_name'] = authorName;
      }
      if (authorEmail != null && authorEmail.isNotEmpty) {
        updateData['author_email'] = authorEmail;
      } else if (user?.email != null) {
        updateData['author_email'] = user!.email;
      }
      if (authorId != null && authorId.isNotEmpty) {
        updateData['author_id'] = authorId;
      } else if (user?.uid != null) {
        updateData['author_id'] = user!.uid;
      }

      await docRef.set(updateData, SetOptions(merge: true));

      debugPrint('Verified fault successfully saved to Firestore: $id');
      return true;
    } catch (e) {
      debugPrint('Error saving verified fault: $e');
      return false;
    }
  }

  /// حذف عطل موثق نهائياً من سحابة Firestore مع حماية خلفية صارمة
  static Future<bool> hardDeleteFault(String faultId) async {
    try {
      if (Firebase.apps.isEmpty) return false;

      // 🛡️ فحص الحماية الخلفية
      final user = FirebaseAuth.instance.currentUser;
      final bool isAdmin = isUserAdmin();

      if (!isAdmin) {
        if (user == null) {
          debugPrint('⛔ Access Denied: Anonymous/guest users cannot delete verified faults.');
          return false;
        }

        final existingDoc = await FirebaseFirestore.instance.collection('verified_faults').doc(faultId).get();
        if (existingDoc.exists) {
          final data = existingDoc.data() ?? {};
          final existingAuthorId = data['author_id'] as String?;
          final existingAuthorEmail = (data['author_email'] as String?)?.toLowerCase().trim();
          final userEmail = user.email?.toLowerCase().trim();

          final bool isOwner = (existingAuthorId != null && existingAuthorId == user.uid) ||
              (existingAuthorEmail != null && userEmail != null && existingAuthorEmail == userEmail);

          if (!isOwner) {
            debugPrint('⛔ Access Denied: User ${user.uid} is not authorized to delete fault $faultId');
            return false;
          }
        }
      }

      await FirebaseFirestore.instance
          .collection('verified_faults')
          .doc(faultId)
          .delete();

      debugPrint('Verified fault permanently deleted from Firestore: $faultId');
      return true;
    } catch (e) {
      debugPrint('Error deleting verified fault: $e');
      return false;
    }
  }

  /// زيادة عدد المشاهدات لعطل موثق
  static Future<void> incrementViews(String faultId) async {
    try {
      if (Firebase.apps.isEmpty) return;

      await FirebaseFirestore.instance
          .collection('verified_faults')
          .doc(faultId)
          .update({'views_count': FieldValue.increment(1)});
    } catch (_) {
      // Ignored for performance
    }
  }
}
