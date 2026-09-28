import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../data/network/forum_storage_service.dart';

// 1. موديل الردود الميدانية الصافية المحدث بحقل موافقة الأدمن الصارم ودعم Subcollections
class ForumReply {
  final String id;
  final String author;
  final String specialty;
  final String content;
  final DateTime createdAt;
  final bool isApproved;

  ForumReply({
    required this.id,
    required this.author,
    required this.specialty,
    required this.content,
    required this.createdAt,
    this.isApproved = false,
  });

  factory ForumReply.fromJson(Map<String, dynamic> json) {
    DateTime parsedCreatedAt = DateTime.now();
    if (json['createdAt'] != null) {
      parsedCreatedAt = DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now();
    } else if (json['created_at'] != null) {
      parsedCreatedAt = DateTime.tryParse(json['created_at'] as String) ?? DateTime.now();
    }
    return ForumReply(
      id: json['id'] as String? ?? '',
      author: json['author'] as String? ?? '',
      specialty: json['specialty'] as String? ?? '',
      content: json['content'] as String? ?? '',
      createdAt: parsedCreatedAt,
      isApproved: json['is_approved'] as bool? ?? (json['isApproved'] as bool? ?? false),
    );
  }

  factory ForumReply.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    DateTime parsedCreatedAt = DateTime.now();
    if (data['created_at'] is Timestamp) {
      parsedCreatedAt = (data['created_at'] as Timestamp).toDate();
    } else if (data['createdAt'] is String) {
      parsedCreatedAt = DateTime.tryParse(data['createdAt'] as String) ?? DateTime.now();
    }
    return ForumReply(
      id: doc.id,
      author: data['author'] as String? ?? 'فني ميداني',
      specialty: data['specialty'] as String? ?? 'عام',
      content: data['content'] as String? ?? '',
      createdAt: parsedCreatedAt,
      isApproved: data['is_approved'] as bool? ?? (data['isApproved'] as bool? ?? false),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'author': author,
      'specialty': specialty,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'is_approved': isApproved,
      'isApproved': isApproved,
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'author': author,
      'specialty': specialty,
      'content': content,
      'created_at': FieldValue.serverTimestamp(),
      'is_approved': isApproved,
    };
  }

  ForumReply copyWith({
    String? id,
    String? author,
    String? specialty,
    String? content,
    DateTime? createdAt,
    bool? isApproved,
  }) {
    return ForumReply(
      id: id ?? this.id,
      author: author ?? this.author,
      specialty: specialty ?? this.specialty,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      isApproved: isApproved ?? this.isApproved,
    );
  }
}

// 2. موديل المنشور الهندسي المتكامل مع دعم روابط الصور السحابية ومجموعات الردود
class ForumPost {
  final String id;
  final String author;
  final String specialty;
  final String title;
  final String description;
  final String category;
  final String? localImagePath;
  final String? imageUrl;
  final int upvotes;
  final int downvotes;
  final int views;
  final List<ForumReply> replies;
  final bool isApproved;
  final List<Map<String, dynamic>>? chatLogs;
  final DateTime? createdAt;

  ForumPost({
    required this.id,
    required this.author,
    required this.specialty,
    required this.title,
    required this.description,
    required this.category,
    this.localImagePath,
    this.imageUrl,
    this.upvotes = 0,
    this.downvotes = 0,
    this.views = 1,
    this.replies = const [],
    this.isApproved = false,
    this.chatLogs,
    this.createdAt,
  });

  ForumPost copyWith({
    int? upvotes,
    int? downvotes,
    int? views,
    List<ForumReply>? replies,
    bool? isApproved,
    String? title,
    String? description,
    String? imageUrl,
    String? localImagePath,
    List<Map<String, dynamic>>? chatLogs,
    DateTime? createdAt,
  }) {
    return ForumPost(
      id: id,
      author: author,
      specialty: specialty,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category,
      localImagePath: localImagePath ?? this.localImagePath,
      imageUrl: imageUrl ?? this.imageUrl,
      upvotes: upvotes ?? this.upvotes,
      downvotes: downvotes ?? this.downvotes,
      views: views ?? this.views,
      replies: replies ?? this.replies,
      isApproved: isApproved ?? this.isApproved,
      chatLogs: chatLogs ?? this.chatLogs,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory ForumPost.fromJson(Map<String, dynamic> json) {
    final repliesList = json['replies'] as List? ?? [];
    DateTime? parsedCreatedAt;
    if (json['createdAt'] != null) {
      parsedCreatedAt = DateTime.tryParse(json['createdAt'] as String);
    } else if (json['created_at'] != null) {
      parsedCreatedAt = DateTime.tryParse(json['created_at'] as String);
    }
    return ForumPost(
      id: json['id'] as String? ?? '',
      author: json['author'] as String? ?? '',
      specialty: json['specialty'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? '',
      localImagePath: json['localImagePath'] as String?,
      imageUrl: json['imageUrl'] as String? ?? (json['image_url'] as String?),
      upvotes: json['upvotes'] as int? ?? 0,
      downvotes: json['downvotes'] as int? ?? 0,
      views: json['views'] as int? ?? 1,
      replies: repliesList.map((r) => ForumReply.fromJson(r as Map<String, dynamic>)).toList(),
      isApproved: json['is_approved'] as bool? ?? (json['isApproved'] as bool? ?? false),
      chatLogs: (json['chat_logs'] as List?)?.map((e) => Map<String, dynamic>.from(e as Map)).toList(),
      createdAt: parsedCreatedAt,
    );
  }

  factory ForumPost.fromFirestore(DocumentSnapshot doc, [List<ForumReply> replies = const []]) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    DateTime? parsedCreatedAt;
    if (data['created_at'] is Timestamp) {
      parsedCreatedAt = (data['created_at'] as Timestamp).toDate();
    }
    return ForumPost(
      id: doc.id,
      author: data['author'] as String? ?? 'فني مجهول',
      specialty: data['specialty'] as String? ?? 'فني ميداني',
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      category: data['category'] as String? ?? 'أخرى',
      localImagePath: data['localImagePath'] as String?,
      imageUrl: data['imageUrl'] as String? ?? (data['image_url'] as String?),
      upvotes: (data['upvotes'] as num?)?.toInt() ?? 0,
      downvotes: (data['downvotes'] as num?)?.toInt() ?? 0,
      views: (data['views'] as num?)?.toInt() ?? 1,
      replies: replies,
      isApproved: data['is_approved'] as bool? ?? (data['isApproved'] as bool? ?? false),
      chatLogs: (data['chat_logs'] as List?)?.map((e) => Map<String, dynamic>.from(e as Map)).toList(),
      createdAt: parsedCreatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'author': author,
      'specialty': specialty,
      'title': title,
      'description': description,
      'category': category,
      if (localImagePath != null) 'localImagePath': localImagePath,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (imageUrl != null) 'image_url': imageUrl,
      'upvotes': upvotes,
      'downvotes': downvotes,
      'views': views,
      'replies': replies.map((r) => r.toJson()).toList(),
      'is_approved': isApproved,
      'isApproved': isApproved,
      if (chatLogs != null && chatLogs!.isNotEmpty) 'chat_logs': chatLogs,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'author': author,
      'specialty': specialty,
      'title': title,
      'description': description,
      'category': category,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (imageUrl != null) 'image_url': imageUrl,
      if (localImagePath != null) 'localImagePath': localImagePath,
      'upvotes': upvotes,
      'downvotes': downvotes,
      'views': views,
      'is_approved': isApproved,
      'status': isApproved ? 'active' : 'pending_approval',
      'created_at': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      if (chatLogs != null && chatLogs!.isNotEmpty) 'chat_logs': chatLogs,
    };
  }
}

// 3. موديل الكود الترويجي والخصومات من الشركات والوكلاء
class PromoCode {
  final String code;
  final int discountPercentage;
  PromoCode({required this.code, required this.discountPercentage});

  factory PromoCode.fromJson(Map<String, dynamic> json) => PromoCode(
    code: json['code'] as String? ?? '',
    discountPercentage: (json['discountPercentage'] as num?)?.toInt() ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'code': code,
    'discountPercentage': discountPercentage,
  };
}

// 4. متحكم الإدارة لإضافة وتفعيل الأكواد الترويجية من قبل الأدمن
class PromoCodeNotifier extends StateNotifier<List<PromoCode>> {
  PromoCodeNotifier() : super([]) {
    _loadFromFirestore();
  }

  Future<void> _loadFromFirestore() async {
    if (Firebase.apps.isEmpty) return;
    try {
      final snap = await FirebaseFirestore.instance.collection('promo_codes').get();
      final loaded = snap.docs.map((d) => PromoCode.fromJson(d.data())).toList();
      if (loaded.isNotEmpty) {
        state = loaded;
      }
    } catch (e) {
      debugPrint('Firestore load promo_codes error: $e');
    }
  }

  Future<void> addPromoCode(String newCode, int discount) async {
    final newPromo = PromoCode(code: newCode, discountPercentage: discount);
    state = [...state.where((p) => p.code != newCode), newPromo];
    if (Firebase.apps.isNotEmpty) {
      try {
        await FirebaseFirestore.instance.collection('promo_codes').doc(newCode).set(newPromo.toJson());
      } catch (e) {
        debugPrint('Firestore save promo_codes error: $e');
      }
    }
  }

  Future<void> removePromoCode(String targetCode) async {
    state = state.where((p) => p.code != targetCode).toList();
    if (Firebase.apps.isNotEmpty) {
      try {
        await FirebaseFirestore.instance.collection('promo_codes').doc(targetCode).delete();
      } catch (e) {
        debugPrint('Firestore delete promo_codes error: $e');
      }
    }
  }
}

// 5. متحكم الحالة الرئيسي للمنشورات وطابور مراجعة الأدمن مع المزامنة السحابية الفورية
class ForumNotifier extends StateNotifier<List<ForumPost>> {
  FirebaseFirestore? get _db => Firebase.apps.isNotEmpty ? FirebaseFirestore.instance : null;

  ForumNotifier() : super(_initialData) {
    _loadFromFirestore();
  }

  static final List<ForumPost> _initialData = [
    ForumPost(
      id: "1",
      author: "المهندس أحمد صالح",
      specialty: "أنظمة تبريد وتكييف",
      title: "عطل متكرر في كمبروسر Chiller من نوع Carrier",
      description: "يحدث فصل مفاجئ بسبب ارتفاع درجة حرارة الموتور (Overheating) بعد تشغيله بـ 20 دقيقة متواصلة. تم فحص الفريون والضغط طبيعي.",
      category: "تكييف وتبريد",
      upvotes: 14,
      views: 142,
      isApproved: true,
      replies: [],
    ),
  ];

  Future<void> _loadFromFirestore() async {
    final db = _db;
    if (db == null) return;
    try {
      // 1. جلب المنشورات المعتمدة من الإنتاج (forum_posts)
      final approvedSnap = await db.collection('forum_posts').get();
      final List<ForumPost> approvedLoaded = [];
      for (var doc in approvedSnap.docs) {
        try {
          approvedLoaded.add(ForumPost.fromFirestore(doc));
        } catch (_) {}
      }

      // 2. جلب المنشورات المعلقة من (pending_faults)
      final pendingSnap = await db.collection('pending_faults').get();
      final List<ForumPost> pendingLoaded = [];
      for (var doc in pendingSnap.docs) {
        try {
          pendingLoaded.add(ForumPost.fromFirestore(doc));
        } catch (_) {}
      }

      final combined = <ForumPost>[];
      // المنشورات الافتراضية المعتمدة
      combined.addAll(_initialData.where((p) => p.isApproved));

      // استبدال المنشورات الافتراضية إذا تكررت مع السحابة
      for (final post in approvedLoaded) {
        final idx = combined.indexWhere((p) => p.id == post.id);
        if (idx >= 0) {
          combined[idx] = post;
        } else {
          combined.add(post);
        }
      }

      // إضافة المعلقة
      for (final post in pendingLoaded) {
        if (!combined.any((p) => p.id == post.id)) {
          combined.add(post);
        }
      }

      if (combined.isNotEmpty) {
        state = combined;
      }
    } catch (e) {
      debugPrint('Firestore load forum posts error: $e');
    }
  }

  /// إرسال منشور جديد إلى طابور الانتظار (pending_faults) مع دعم رفع الصورة السحابية
  Future<void> submitForReview({
    required String author,
    required String specialty,
    required String title,
    required String description,
    required String category,
    String? imagePath,
    String? imageUrl,
    List<Map<String, dynamic>>? chatLogs,
  }) async {
    final newId = DateTime.now().millisecondsSinceEpoch.toString();
    String? finalImageUrl = imageUrl;

    // رفع الصورة إلى Firebase Storage إذا توفر مسار محلي ولم يُرفع بعد
    if (finalImageUrl == null && imagePath != null && imagePath.isNotEmpty) {
      try {
        finalImageUrl = await ForumStorageService.uploadPostImage(
          postId: newId,
          localPath: imagePath,
        );
      } catch (e) {
        debugPrint('Error uploading image in submitForReview: $e');
      }
    }

    final newPost = ForumPost(
      id: newId,
      author: author.isEmpty ? "فني مجهول" : author,
      specialty: specialty.isEmpty ? "فني ميداني" : specialty,
      title: title,
      description: description,
      category: category,
      localImagePath: imagePath,
      imageUrl: finalImageUrl,
      isApproved: false,
      chatLogs: chatLogs,
      createdAt: DateTime.now(),
    );

    state = [...state, newPost];

    // حفظ في Firestore بمسار pending_faults مع حقن معرّف القطاع المسمط لمنع null
    final db = _db;
    if (db == null) return;
    try {
      final String rawSector = category.replaceAll(RegExp(r'\[(Expert|KB)\]'), '').trim();
      final String normalizedSector = rawSector.isNotEmpty ? rawSector : 'تكييف وتبريد';

      final data = {
        ...newPost.toJson(),
        'sector_id': normalizedSector,
        'sector': normalizedSector,
        'system_type': normalizedSector,
        'systemType': normalizedSector,
        'status': 'pending_approval',
        'is_approved': false,
        'created_at': FieldValue.serverTimestamp(),
        'submitted_at': FieldValue.serverTimestamp(),
      };
      await db.collection('pending_faults').doc(newPost.id).set(data);
      debugPrint('Post submitted to pending_faults with sector_id ($normalizedSector): ${newPost.id}');
    } catch (e) {
      debugPrint('Firestore save pending_faults error: $e');
    }
  }

  /// موافقة الأدمن على المنشور: نقله فوراً إلى forum_posts وحذفه من pending_faults
  Future<void> approvePost(String id) async {
    ForumPost? targetPost;
    for (final p in state) {
      if (p.id == id) {
        targetPost = p.copyWith(isApproved: true);
        break;
      }
    }

    state = [
      for (final p in state)
        if (p.id == id) p.copyWith(isApproved: true) else p
    ];

    final db = _db;
    if (db == null) return;

    try {
      // 1. القراءة من pending_faults للنسخ الدقيق إن وجد
      final pendingDoc = await db.collection('pending_faults').doc(id).get();
      Map<String, dynamic> docData = {};

      if (pendingDoc.exists && pendingDoc.data() != null) {
        docData = Map<String, dynamic>.from(pendingDoc.data()!);
      } else if (targetPost != null) {
        docData = targetPost.toJson();
      }

      docData['is_approved'] = true;
      docData['isApproved'] = true;
      docData['status'] = 'active';
      docData['approved_at'] = FieldValue.serverTimestamp();

      // 2. الكتابة الفورية والدائمة في مجموعة الإنتاج forum_posts
      await db.collection('forum_posts').doc(id).set(docData, SetOptions(merge: true));
      debugPrint('Post copied to forum_posts production: $id');

      // 3. نقل أي ردود كانت معلقة في pending_faults/{id}/replies إن وجدت
      try {
        final repliesSnap = await db.collection('pending_faults').doc(id).collection('replies').get();
        for (final replyDoc in repliesSnap.docs) {
          await db.collection('forum_posts').doc(id).collection('replies').doc(replyDoc.id).set(replyDoc.data());
          await replyDoc.reference.delete();
        }
      } catch (e) {
        debugPrint('Error transferring replies: $e');
      }

      // 4. الحذف من طابور pending_faults
      await db.collection('pending_faults').doc(id).delete();
      debugPrint('Post removed from pending_faults: $id');
    } catch (e) {
      debugPrint('Firestore approvePost error: $e');
    }
  }

  /// رفض المنشور: حذفه من pending_faults وإلغاء صورته
  Future<void> rejectPost(String id) async {
    state = state.where((p) => p.id != id).toList();

    final db = _db;
    if (db == null) return;
    try {
      await db.collection('pending_faults').doc(id).delete();
      await db.collection('forum_posts').doc(id).delete();
      // حذف الصورة من Storage إن وُجدت
      await ForumStorageService.deletePostImage(id);
      debugPrint('Firestore reject delete completed: $id');
    } catch (e) {
      debugPrint('Firestore reject delete error: $e');
    }
  }

  /// إضافة رد جديد: يُخزن في Subcollection: forum_posts/{postId}/replies/{replyId} بحالة is_approved: false
  Future<void> addReply(String postId, String author, String specialty, String content) async {
    final replyId = DateTime.now().millisecondsSinceEpoch.toString();
    final newReply = ForumReply(
      id: replyId,
      author: author,
      specialty: specialty,
      content: content,
      createdAt: DateTime.now(),
      isApproved: false,
    );

    // تحديث الحالة المحلية فوراً
    state = [
      for (final p in state)
        if (p.id == postId)
          p.copyWith(replies: [...p.replies, newReply])
        else
          p
    ];

    final db = _db;
    if (db == null) return;

    try {
      final replyData = {
        'id': replyId,
        'postId': postId,
        'author': author,
        'specialty': specialty,
        'content': content,
        'created_at': FieldValue.serverTimestamp(),
        'is_approved': false,
        'isApproved': false,
      };

      // الحفظ في Subcollection المستقلة forum_posts/{postId}/replies/{replyId}
      await db
          .collection('forum_posts')
          .doc(postId)
          .collection('replies')
          .doc(replyId)
          .set(replyData);

      // في حال كان المنشور لا يزال معلقاً، يتم حفظ الرد أيضاً في pending_faults/{postId}/replies/{replyId}
      final postDoc = await db.collection('pending_faults').doc(postId).get();
      if (postDoc.exists) {
        await db
            .collection('pending_faults')
            .doc(postId)
            .collection('replies')
            .doc(replyId)
            .set(replyData);
      }

      debugPrint('Reply saved to subcollection forum_posts/$postId/replies/$replyId (is_approved: false)');
    } catch (e) {
      debugPrint('Firestore addReply error: $e');
    }
  }

  void addPendingReply(String postId, String author, String specialty, String content) {
    addReply(postId, author, specialty, content);
  }

  /// اعتماد رد من قبل الأدمن: تحديث is_approved: true في السحابة
  Future<void> approveReply(String postId, String replyId) async {
    state = [
      for (final p in state)
        if (p.id == postId)
          p.copyWith(replies: [
            for (final r in p.replies)
              if (r.id == replyId) r.copyWith(isApproved: true) else r
          ])
        else
          p
    ];

    final db = _db;
    if (db == null) return;
    try {
      await db
          .collection('forum_posts')
          .doc(postId)
          .collection('replies')
          .doc(replyId)
          .update({'is_approved': true, 'isApproved': true});
      debugPrint('Reply approved in cloud: forum_posts/$postId/replies/$replyId');
    } catch (e) {
      debugPrint('Firestore approveReply error: $e');
    }
  }

  /// رفض أو حذف رد نهائياً من Subcollection السحابية
  Future<void> rejectReply(String postId, String replyId) async {
    state = [
      for (final p in state)
        if (p.id == postId)
          p.copyWith(replies: p.replies.where((r) => r.id != replyId).toList())
        else
          p
    ];

    final db = _db;
    if (db == null) return;
    try {
      await db
          .collection('forum_posts')
          .doc(postId)
          .collection('replies')
          .doc(replyId)
          .delete();
      debugPrint('Reply deleted from subcollection: forum_posts/$postId/replies/$replyId');
    } catch (e) {
      debugPrint('Firestore rejectReply error: $e');
    }
  }

  void updatePostDescription(String postId, String newDescription) {
    state = [
      for (final p in state)
        if (p.id == postId)
          p.copyWith(description: newDescription)
        else
          p
    ];
  }

  void updatePostTitle(String postId, String newTitle) {
    state = [
      for (final p in state)
        if (p.id == postId)
          p.copyWith(title: newTitle)
        else
          p
    ];
  }

  Future<void> updateReplyContent(String postId, String replyId, String newContent) async {
    state = [
      for (final p in state)
        if (p.id == postId)
          p.copyWith(replies: [
            for (final r in p.replies)
              if (r.id == replyId)
                r.copyWith(content: newContent)
              else
                r
          ])
        else
          p
    ];

    final db = _db;
    if (db == null) return;
    try {
      await db
          .collection('forum_posts')
          .doc(postId)
          .collection('replies')
          .doc(replyId)
          .update({'content': newContent});
      debugPrint('Reply content updated in cloud: forum_posts/$postId/replies/$replyId');
    } catch (e) {
      debugPrint('Firestore updateReplyContent error: $e');
    }
  }

  void upvote(String id) {
    state = [for (final p in state) if (p.id == id) p.copyWith(upvotes: p.upvotes + 1) else p];
  }

  void downvote(String id) {
    state = [for (final p in state) if (p.id == id) p.copyWith(downvotes: p.downvotes + 1) else p];
  }
}

// 6. مزودات الحالة العالمية لـ Riverpod مع البث السحابي الحي (Firestore Snapshots Streams)
final forumProvider = StateNotifierProvider<ForumNotifier, List<ForumPost>>((ref) => ForumNotifier());
final approvedPostsProvider = Provider<List<ForumPost>>((ref) => ref.watch(forumProvider).where((p) => p.isApproved).toList());
final adminQueueProvider = Provider<List<ForumPost>>((ref) => ref.watch(forumProvider).where((p) => !p.isApproved).toList());
final kbQueueProvider = Provider<List<ForumPost>>((ref) => ref.watch(forumProvider).where((p) => !p.isApproved && p.category.startsWith('[KB]')).toList());
final expertQueueProvider = Provider<List<ForumPost>>((ref) => ref.watch(forumProvider).where((p) => !p.isApproved && p.category.startsWith('[Expert]')).toList());
final expertApprovedProvider = Provider<List<ForumPost>>((ref) => ref.watch(forumProvider).where((p) => p.isApproved && p.category.startsWith('[Expert]')).toList());

final promoCodeProvider = StateNotifierProvider<PromoCodeNotifier, List<PromoCode>>((ref) => PromoCodeNotifier());

final forumSearchProvider = StateProvider<String>((ref) => '');
final forumCategoryFilterProvider = StateProvider<String>((ref) => 'all');
final forumSortProvider = StateProvider<String>((ref) => 'newest');

/// 📡 بث حي ومباشر للمنشورات المعتمدة من Firestore (Live Stream < 300ms)
final liveApprovedForumPostsStreamProvider = StreamProvider<List<ForumPost>>((ref) {
  if (Firebase.apps.isEmpty) {
    return Stream.value(ref.watch(forumProvider).where((p) => p.isApproved).toList());
  }

  return FirebaseFirestore.instance
      .collection('forum_posts')
      .where('is_approved', isEqualTo: true)
      .snapshots()
      .map((snapshot) {
        return snapshot.docs.map((doc) => ForumPost.fromFirestore(doc)).toList();
      });
});

/// 📡 بث حي للردود المعتمدة في منشور محدد من Subcollection المستقلة
final liveApprovedRepliesStreamProvider = StreamProvider.family<List<ForumReply>, String>((ref, postId) {
  if (Firebase.apps.isEmpty) {
    final posts = ref.watch(forumProvider);
    final post = posts.firstWhere((p) => p.id == postId, orElse: () => ForumPost(id: '', author: '', specialty: '', title: '', description: '', category: ''));
    return Stream.value(post.replies.where((r) => r.isApproved).toList());
  }

  return FirebaseFirestore.instance
      .collection('forum_posts')
      .doc(postId)
      .collection('replies')
      .where('is_approved', isEqualTo: true)
      .snapshots()
      .map((snapshot) {
        return snapshot.docs.map((doc) => ForumReply.fromFirestore(doc)).toList();
      });
});

/// 📡 بث حي للردود المعلقة في منشور محدد لطابور مراجعة الأدمن
final livePendingRepliesStreamProvider = StreamProvider.family<List<ForumReply>, String>((ref, postId) {
  if (Firebase.apps.isEmpty) {
    final posts = ref.watch(forumProvider);
    final post = posts.firstWhere((p) => p.id == postId, orElse: () => ForumPost(id: '', author: '', specialty: '', title: '', description: '', category: ''));
    return Stream.value(post.replies.where((r) => !r.isApproved).toList());
  }

  return FirebaseFirestore.instance
      .collection('forum_posts')
      .doc(postId)
      .collection('replies')
      .where('is_approved', isEqualTo: false)
      .snapshots()
      .map((snapshot) {
        return snapshot.docs.map((doc) => ForumReply.fromFirestore(doc)).toList();
      });
});

/// 📡 بث حي موحد لجميع الردود المعلقة عبر كل المنشورات (CollectionGroup Query)
/// يستمع لـ subcollection "replies" في كل مستندات forum_posts دفعة واحدة
/// يتطلب: Firestore Index على (is_approved ASC, created_at DESC) في مجموعة replies
final liveAllPendingRepliesStreamProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  if (Firebase.apps.isEmpty) {
    // Fallback: بناء القائمة من الحالة المحلية
    final posts = ref.watch(forumProvider);
    final localPending = <Map<String, dynamic>>[];
    for (final post in posts) {
      for (final reply in post.replies) {
        if (!reply.isApproved) {
          localPending.add({'reply': reply, 'postId': post.id, 'postTitle': post.title});
        }
      }
    }
    return Stream.value(localPending);
  }

  return FirebaseFirestore.instance
      .collectionGroup('replies')
      .where('is_approved', isEqualTo: false)
      .orderBy('created_at', descending: true)
      .snapshots()
      .map<List<Map<String, dynamic>>>((snap) {
        return snap.docs.map<Map<String, dynamic>>((doc) {
          final ForumReply reply = ForumReply.fromFirestore(doc);
          final String postId = (doc.data()['postId'] as String?)
              ?? doc.reference.parent.parent?.id
              ?? '';
          return <String, dynamic>{
            'reply': reply,
            'postId': postId,
            'postTitle': (doc.data()['postTitle'] as String?) ?? '',
          };
        }).toList();
      });
});

/// 📡 بث حي مستمر لأكواد الخصم من Firestore (Real-time Promo Codes Stream)
/// يستبدل one-time get() الموجود في PromoCodeNotifier بمزامنة حية فورية
final livePromoCodesStreamProvider = StreamProvider<List<PromoCode>>((ref) {
  if (Firebase.apps.isEmpty) {
    return Stream.value(ref.watch(promoCodeProvider));
  }

  return FirebaseFirestore.instance
      .collection('promo_codes')
      .snapshots()
      .map<List<PromoCode>>((snap) {
        return snap.docs.map<PromoCode>((doc) => PromoCode.fromJson(doc.data())).toList();
      });
});

class NewPostState {
  final String? localImagePath;
  final String? imageUrl;
  final bool isUploading;

  NewPostState({
    this.localImagePath,
    this.imageUrl,
    this.isUploading = false,
  });

  NewPostState copyWith({
    String? localImagePath,
    String? imageUrl,
    bool? isUploading,
  }) {
    return NewPostState(
      localImagePath: localImagePath ?? this.localImagePath,
      imageUrl: imageUrl ?? this.imageUrl,
      isUploading: isUploading ?? this.isUploading,
    );
  }
}

class NewPostNotifier extends StateNotifier<NewPostState> {
  NewPostNotifier() : super(NewPostState());

  void updateImagePath(String path) => state = state.copyWith(localImagePath: path);
  void updateImageUrl(String url) => state = state.copyWith(imageUrl: url);
  void setUploading(bool uploading) => state = state.copyWith(isUploading: uploading);
  void reset() => state = NewPostState();
}

final newPostProvider = StateNotifierProvider<NewPostNotifier, NewPostState>((ref) => NewPostNotifier());

