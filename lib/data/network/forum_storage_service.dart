import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ForumStorageService {
  /// رفع صورة العطل إلى Firebase Storage والحصول على رابط التحميل المباشر
  static Future<String?> uploadPostImage({
    required String postId,
    required String localPath,
  }) async {
    try {
      if (Firebase.apps.isEmpty) {
        debugPrint('Firebase not initialized. Cannot upload to Storage.');
        return null;
      }

      final file = File(localPath);
      if (!await file.exists()) {
        debugPrint('Image file does not exist at path: $localPath');
        return null;
      }

      final storageRef = FirebaseStorage.instance
          .ref()
          .child('forum_images')
          .child('$postId.jpg');

      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'postId': postId,
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );

      final uploadTask = storageRef.putFile(file, metadata);
      final snapshot = await uploadTask.whenComplete(() {});

      if (snapshot.state == TaskState.success) {
        final downloadUrl = await storageRef.getDownloadURL();
        debugPrint('Post image uploaded successfully: $downloadUrl');
        return downloadUrl;
      } else {
        debugPrint('Upload failed with state: ${snapshot.state}');
        return null;
      }
    } catch (e) {
      debugPrint('Error uploading post image to Firebase Storage: $e');
      return null;
    }
  }

  /// حذف صورة العطل السحابية عند قيام الأدمن بالحذف النهائي
  static Future<void> deletePostImage(String postId) async {
    try {
      if (Firebase.apps.isEmpty) return;
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('forum_images')
          .child('$postId.jpg');
      await storageRef.delete();
      debugPrint('Post image deleted from Storage: $postId');
    } catch (e) {
      debugPrint('Error deleting post image from Storage: $e');
    }
  }
}
