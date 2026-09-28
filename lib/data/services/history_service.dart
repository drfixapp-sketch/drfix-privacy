import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:dr_fix/presentation/widgets/ai_report_state_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 🔄 خدمة المزامنة السحابية للتشخيصات (Diagnostic History Cloud Sync Service)
/// تضمن حفظ بيانات التشخيصات بشكل متكامل محلياً وسحابياً مع توفير الحماية التامة والامتثال
/// الكامل لسياسات الخصوصية وحذف الحسابات التابعة لـ Google و Apple.
class HistorySyncService {
  static const String _historyKey = 'dr_fix_diagnosis_history_v1';
  static FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  static bool get _firebaseReady => Firebase.apps.isNotEmpty;

  /// 📥 مزامنة البيانات بين السحابية والتخزين المحلي (Two-way Synchronization)
  static Future<List<AIReportState>> syncCloudAndLocal(String uid) async {
    if (!_firebaseReady || uid.startsWith('GUEST_') || uid == 'GUEST_USER') {
      return await DiagnosisHistoryManager.getHistory();
    }
    try {
      debugPrint("Starting cloud history sync for user: $uid");
      
      // 1. استرجاع السجلات المحلية
      final localHistory = await DiagnosisHistoryManager.getHistory();
      
      // 2. استرجاع السجلات السحابية من Firestore
      final cloudSnap = await _firestore
          .collection('users')
          .doc(uid)
          .collection('diagnostic_history')
          .orderBy('timestamp', descending: true)
          .get();

      final List<AIReportState> cloudHistory = [];
      for (var doc in cloudSnap.docs) {
        try {
          final data = doc.data();
          final reportJson = data['reportData'] as String;
          final map = jsonDecode(reportJson) as Map<String, dynamic>;
          cloudHistory.add(AIReportState.fromJson(map));
        } catch (e) {
          debugPrint("Failed decoding single cloud document: $e");
        }
      }

      // 3. دمج السجلات تفادياً للتكرار (Merge using unique keys)
      final List<AIReportState> mergedHistory = List.from(localHistory);
      
      for (final cloudReport in cloudHistory) {
        bool exists = mergedHistory.any((localReport) =>
            localReport.deviceName == cloudReport.deviceName &&
            localReport.dateStr == cloudReport.dateStr &&
            localReport.categoryName == cloudReport.categoryName);
        
        if (!exists) {
          mergedHistory.add(cloudReport);
        }
      }

      // ترتيب السجل المدمج ليكون الأحدث دائماً بالقمة
      mergedHistory.sort((a, b) {
        final aDate = a.dateStr != null ? DateTime.tryParse(a.dateStr!) ?? DateTime.now() : DateTime.now();
        final bDate = b.dateStr != null ? DateTime.tryParse(b.dateStr!) ?? DateTime.now() : DateTime.now();
        return bDate.compareTo(aDate);
      });

      // 4. تحديث التخزين المحلي والرفع إلى السحابة
      await _saveMergedToLocal(mergedHistory);
      await uploadHistory(mergedHistory, uid);

      debugPrint("Successfully finished cloud sync! Merged list total: ${mergedHistory.length}");
      return mergedHistory;
    } catch (e) {
      debugPrint("Error syncing local & cloud history: $e");
      // في حالة الفشل أو عدم تفعيل قاعدة البيانات، يستمر العمل محلياً كلياً دون أي تأثير على المستخدم
      return await DiagnosisHistoryManager.getHistory();
    }
  }

  /// 📤 رفع السجلات المحلية كاملة إلى حساب المستخدم في السحابة
  static Future<void> uploadHistory(List<AIReportState> reports, String uid) async {
    if (!_firebaseReady || uid.startsWith('GUEST_') || uid == 'GUEST_USER') {
      return;
    }

    try {
      final WriteBatch batch = _firestore.batch();
      final collectionRef = _firestore
          .collection('users')
          .doc(uid)
          .collection('diagnostic_history');

      // رفع كل السجلات كـ Batch لرفع الكفاءة وضغط استهلاك البيانات
      for (final report in reports) {
        final String docId = _generateDocId(report);
        final docRef = collectionRef.doc(docId);
        
        batch.set(docRef, {
          'deviceName': report.deviceName,
          'categoryName': report.categoryName,
          'dateStr': report.dateStr,
          'timestamp': FieldValue.serverTimestamp(),
          'reportData': jsonEncode(report.toJson()),
        }, SetOptions(merge: true));
      }

      await batch.commit();
      debugPrint("Uploaded batch of ${reports.length} reports successfully.");
    } catch (e) {
      debugPrint("Error uploading diagnostic history batch: $e");
    }
  }

  /// 💾 حفظ تقرير تشخيصي فردي (مزدوج محلي + سحابي إن وجد حساب مسجل)
  static Future<void> saveReport(AIReportState report, {String? uid}) async {
    // 1. الحفظ محلياً أولاً لضمان تجربة الأوفلاين والسلاسة المطلقة
    await DiagnosisHistoryManager.saveReportToHistory(report);

    // تحديث المعرف تلقائياً من FirebaseAuth إن لم يمرر ووجد مستخدم مسجل
    final String? activeUid = _firebaseReady
        ? (uid ?? FirebaseAuth.instance.currentUser?.uid)
        : null;

    // 2. إذا كان مسجلاً بالكامل، يتم تحديثه ومزامنته سحابياً على الفور
    if (activeUid != null && !activeUid.startsWith('GUEST_') && activeUid != 'GUEST_USER') {
      try {
        final docId = _generateDocId(report);
        await _firestore
            .collection('users')
            .doc(activeUid)
            .collection('diagnostic_history')
            .doc(docId)
            .set({
          'deviceName': report.deviceName,
          'categoryName': report.categoryName,
          'dateStr': report.dateStr,
          'timestamp': FieldValue.serverTimestamp(),
          'reportData': jsonEncode(report.toJson()),
        }, SetOptions(merge: true));
        debugPrint("Successfully synced saved report to Firestore cloud.");
      } catch (e) {
        debugPrint("Failed to push report to cloud on-the-fly: $e");
      }
    }
  }

  /// 🗑️ حذف تشخيص معين نهائياً (محلي وسحابي)
  static Future<void> deleteReport(AIReportState report, {String? uid}) async {
    // 1. حذف محلي
    await DiagnosisHistoryManager.deleteReportFromHistory(report);

    if (!_firebaseReady) {
      return;
    }

    // 2. حذف سحابي فوري
    if (uid != null && !uid.startsWith('GUEST_') && uid != 'GUEST_USER') {
      try {
        final docId = _generateDocId(report);
        await _firestore
            .collection('users')
            .doc(uid)
            .collection('diagnostic_history')
            .doc(docId)
            .delete();
        debugPrint("Successfully deleted report from Firestore cloud.");
      } catch (e) {
        debugPrint("Failed to delete report from cloud: $e");
      }
    }
  }

  /// 🧹 مسح السجل بالكامل (محلي وسحابي)
  static Future<void> clearAllHistory({String? uid}) async {
    // 1. مسح محلي
    await DiagnosisHistoryManager.clearHistory();

    if (!_firebaseReady) {
      return;
    }

    // 2. مسح سحابي كامل
    if (uid != null && !uid.startsWith('GUEST_') && uid != 'GUEST_USER') {
      try {
        final collectionRef = _firestore
            .collection('users')
            .doc(uid)
            .collection('diagnostic_history');
        
        final snapshots = await collectionRef.get();
        final WriteBatch batch = _firestore.batch();
        for (var doc in snapshots.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
        debugPrint("Successfully cleared all history from Firestore cloud.");
      } catch (e) {
        debugPrint("Failed to clear all history from cloud: $e");
      }
    }
  }

  /// ⚖️ تطهير وحذف كافة بيانات المستخدم نهائياً (Purge and Account Deletion Compliance)
  /// يحذف ملف المستخدم وكل سجلاته الفرعية للامتثال الصارم لإرشادات Google و Apple لحماية الخصوصية.
  static Future<bool> purgeUserDataAndCloudHistory(String uid) async {
    if (!_firebaseReady) {
      await DiagnosisHistoryManager.clearHistory();
      return false;
    }

    try {
      debugPrint("⚠️ GDPR/Apple Policy Compliance: Purging all database records for user: $uid");
      
      // 1. حذف جميع وثائق السجل التشخيصي
      final collectionRef = _firestore
          .collection('users')
          .doc(uid)
          .collection('diagnostic_history');
      
      final snapshots = await collectionRef.get();
      final WriteBatch batch = _firestore.batch();
      for (var doc in snapshots.docs) {
        batch.delete(doc.reference);
      }
      
      // 2. حذف الوثيقة الرئيسية للمستخدم
      final userDocRef = _firestore.collection('users').doc(uid);
      batch.delete(userDocRef);
      
      await batch.commit();
      
      // 3. مسح الهوية والبيانات محلياً تماماً
      await DiagnosisHistoryManager.clearHistory();
      
      debugPrint("🔒 Cloud and Local purge completed successfully for user: $uid");
      return true;
    } catch (e) {
      debugPrint("Error purging user database records: $e");
      return false;
    }
  }

  /// مساعد لإنشاء معرف مستند فريد ومطابق مبني على خصائص التقرير لمنع الازدواجية
  static String _generateDocId(AIReportState report) {
    final String base = "${report.deviceName}_${report.categoryName}_${report.dateStr}";
    return base.replaceAll(RegExp(r'[^\w\-]'), '_');
  }

  /// مساعد لحفظ السجل المحلي
  static Future<void> _saveMergedToLocal(List<AIReportState> reports) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> jsonList = reports.map((r) => jsonEncode(r.toJson())).toList();
      await prefs.setStringList(_historyKey, jsonList);
    } catch (e) {
      debugPrint("Error saving merged list to shared prefs: $e");
    }
  }
}
