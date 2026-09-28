import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:dr_fix/data/models/community_post_model.dart';
import 'package:dr_fix/data/network/admin_notification_service.dart';

/// 🛠️ القطاعات الهندسية الـ 9 المعتمدة في تطبيق Dr. Fix
class EngineeringSectors {
  static const String hvac = 'تكييف وتبريد';
  static const String electrical = 'كهرباء';
  static const String homeAppliances = 'أجهزة منزلية';
  static const String hydraulics = 'أنظمة هيدروليك';
  static const String industrialMechanics = 'ميكانيكا صناعية';
  static const String automotive = 'سيارات';
  static const String automationPlc = 'أتمتة وPLC';
  static const String gasPetroleum = 'غاز وبترول';
  static const String medicalCommercial = 'أجهزة طبية وتجارية';

  static const List<String> approvedSectors = [
    hvac,
    electrical,
    homeAppliances,
    hydraulics,
    industrialMechanics,
    automotive,
    automationPlc,
    gasPetroleum,
    medicalCommercial,
  ];

  /// دالة استخراج وتعيين معرّف القطاع الهندسي (Category/Sector ID) مسمط مسبقاً لتفادي قيم الـ null
  static String normalizeSector(String? input) {
    if (input == null || input.trim().isEmpty) return hvac;
    final cleaned = input.replaceAll(RegExp(r'\[(Expert|KB)\]'), '').trim();

    for (final sector in approvedSectors) {
      if (cleaned.contains(sector) || sector.contains(cleaned)) {
        return sector;
      }
    }

    final lower = cleaned.toLowerCase();
    if (lower.contains('hvac') || lower.contains('تبريد') || lower.contains('تكييف') || lower.contains('ac')) return hvac;
    if (lower.contains('electric') || lower.contains('كهربا')) return electrical;
    if (lower.contains('appliance') || lower.contains('غسال') || lower.contains('منزل')) return homeAppliances;
    if (lower.contains('hydraulic') || lower.contains('هيدروليك')) return hydraulics;
    if (lower.contains('mechanic') || lower.contains('ميكانيك')) return industrialMechanics;
    if (lower.contains('auto') || lower.contains('car') || lower.contains('سيار')) return automotive;
    if (lower.contains('plc') || lower.contains('automation') || lower.contains('أتمتة')) return automationPlc;
    if (lower.contains('gas') || lower.contains('petrol') || lower.contains('غاز')) return gasPetroleum;
    if (lower.contains('medical') || lower.contains('طبي')) return medicalCommercial;

    return hvac; // ضمان عدم إرجاع قيمة null تحت أي ظرف
  }
}

class CommunityState {
  final List<CommunityPost> posts;
  final String searchQuery;
  final String selectedCategory; // 'الكل' or 'All' or empty

  CommunityState({
    required this.posts,
    required this.searchQuery,
    required this.selectedCategory,
  });

  CommunityState copyWith({
    List<CommunityPost>? posts,
    String? searchQuery,
    String? selectedCategory,
  }) {
    return CommunityState(
      posts: posts ?? this.posts,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategory: selectedCategory ?? this.selectedCategory,
    );
  }
}

class CommunityNotifier extends StateNotifier<CommunityState> {
  FirebaseFirestore? get _db => Firebase.apps.isNotEmpty ? FirebaseFirestore.instance : null;
  final Ref? _ref;

  CommunityNotifier([this._ref]) : super(CommunityState(posts: _initialData, searchQuery: '', selectedCategory: 'الكل')) {
    _loadFromFirestore();
  }

  static final List<CommunityPost> _initialData = [
    CommunityPost(
      id: 'ency_1',
      systemType: 'تكييف وتبريد',
      deviceModel: 'Gree Inverter Split AC 2-Ton',
      issueDescription: 'ظهور كود الخطأ E6 بشكل متكرر مع توقف الضاغط الخارجي بعد دقائق من التشغيل، مع اهتزاز ضعيف في مروحة الوحدة الخارجية.',
      successfulSolution: '1. تم فحص كابلات الإشارة بين الوحدة الداخلية والخارجية وتبين تآكل جزئي بسبب الرطوبة.\n2. تم استبدال الكابل بالكامل بكابل نحاسي معزول عالي الجودة.\n3. تم تنظيف نقاط التوصيل بالـ Contact Cleaner وإعادة ضبط الإشارة.\n4. بعد إعادة التشغيل عاد النظام للعمل بشكل طبيعي وزال كود E6.',
      approximateCost: '150 - 200 SAR',
      isPublic: true,
      isVerified: true,
      isApproved: true,
      authorName: 'المهندس رامي فؤاد',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      comments: [
        CommunityComment(
          id: 'comm_1_1',
          authorName: 'الفني عماد شكري',
          text: 'حل ممتاز وفعال! هذا من أكثر الأسباب شيوعاً في وحدات غري.',
          isExpert: true,
          isApproved: true,
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
        ),
      ],
    ),
    CommunityPost(
      id: 'ency_2',
      systemType: 'كهرباء',
      deviceModel: 'Schneider EasyPact TVS Contactor 220V',
      issueDescription: 'سماع طنين قوي من الكونتاكتور مع سخونة مرتفعة في ملف التحكم.',
      successfulSolution: '1. تم فحص ملف التحكم وتبين ضعف التلامس المغناطيسي.\n2. تم تنظيف القلب الحديدي واستبدال النابض التالف.\n3. بعد إعادة التشغيل اختفى الطنين وارتفعت ثباتية النظام.',
      approximateCost: '80 - 120 SAR',
      isPublic: true,
      isVerified: true,
      isApproved: true,
      authorName: 'الخبير أبو يوسف الكهربائي',
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      comments: [
        CommunityComment(
          id: 'comm_2_1',
          authorName: 'المهندس بهاء الدين',
          text: 'التحقق من الجهد على الملف قبل الاستبدال أمر مهم جداً.',
          isExpert: true,
          isApproved: true,
          createdAt: DateTime.now().subtract(const Duration(days: 4)),
        ),
      ],
    ),
    CommunityPost(
      id: 'ency_3',
      systemType: 'أجهزة منزلية',
      deviceModel: 'LG Front Load Washer 9KG (F4R5)',
      issueDescription: 'ظهور رمز الخطأ OE عند مرحلة العصر والتجفيف مع بقاء الماء محبوساً داخل الحلة.',
      successfulSolution: '1. تم تصريف المياه يدوياً عن طريق خرطوم الطوارئ.\n2. تم إزالة عائق معدني من مضخة الطرد.\n3. تم استبدال المضخة وإعادة تشغيل الدورة بنجاح.',
      approximateCost: '110 - 140 SAR',
      isPublic: true,
      isVerified: true,
      isApproved: true,
      authorName: 'فني غسالات محترف',
      createdAt: DateTime.now().subtract(const Duration(days: 7)),
      comments: [
        CommunityComment(
          id: 'comm_3_1',
          authorName: 'المهندس مصطفى عادل',
          text: 'التحقق من فلتر المضخة قبل استبدال أي قطعة يعطي نتائج أسرع.',
          isExpert: true,
          isApproved: true,
          createdAt: DateTime.now().subtract(const Duration(days: 6)),
        ),
      ],
    ),
    CommunityPost(
      id: 'ency_4',
      systemType: 'أنظمة هيدروليك',
      deviceModel: 'Rexroth Hydraulic Gear Pump (AZPF)',
      issueDescription: 'حدوث تكهف وضجيج شديد في مضخة التروس الهيدروليكية مع هبوط ضغط واضح.',
      successfulSolution: '1. تم فحص خط السحب وتبين تسريب هواء بسيط.\n2. تم تنظيف الفلتر وتغيير الحشية.\n3. بعد إعادة التعبئة والتشغيل عاد الضغط إلى وضعه الطبيعي.',
      approximateCost: '350 - 450 SAR',
      isPublic: true,
      isVerified: true,
      isApproved: true,
      authorName: 'مهندس هيدروليك صناعي',
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
      comments: [],
    ),
    CommunityPost(
      id: 'ency_5',
      systemType: 'ميكانيكا صناعية',
      deviceModel: 'Siemens Gearbox Reducer 7.5kW',
      issueDescription: 'تسرب زيت كبير من غلاف الترس مع ارتفاع حرارة العلبة.',
      successfulSolution: '1. تم فحص الختم الدائري وتبين تلفه.\n2. تم استبدال الختم وإعادة محاذاة المحور.\n3. تم تقليل الحمل مؤقتاً إلى أن استقرت الحرارة.',
      approximateCost: '220 - 300 SAR',
      isPublic: true,
      isVerified: true,
      isApproved: true,
      authorName: 'الخبير سمير جنيدي',
      createdAt: DateTime.now().subtract(const Duration(days: 12)),
      comments: [],
    ),
    CommunityPost(
      id: 'ency_6',
      systemType: 'سيارات',
      deviceModel: 'Toyota Corolla 2018 - ECU / Fuel Pump',
      issueDescription: 'انقطاع تشغيل المحرك مع ظهور ضوء فحص المحرك وارتفاع استهلاك الوقود.',
      successfulSolution: '1. تم قراءة الأخطاء الرقمية وتبين خلل في دائرة مضخة الوقود.\n2. تم فحص الموصلات وإزالة التآكل.\n3. بعد استبدال المكوّن التالف استعاد المحرك أداءه الطبيعي.',
      approximateCost: '180 - 260 SAR',
      isPublic: true,
      isVerified: true,
      isApproved: true,
      authorName: 'فني سيارات مختص',
      createdAt: DateTime.now().subtract(const Duration(days: 9)),
      comments: [],
    ),
    CommunityPost(
      id: 'ency_7',
      systemType: 'أتمتة وPLC',
      deviceModel: 'Allen Bradley CompactLogix',
      issueDescription: 'تعطل في الاتصال بين وحدة التحكم والـ I/O مع توقف البرنامج عن التحديث.',
      successfulSolution: '1. تم فحص كابل الشبكة وملفات الإعداد.\n2. تم التأكد من صحة عنوان IP ووحدة المنفذ.\n3. بعد إعادة برمجة الاتصال عاد النظام إلى التشغيل.',
      approximateCost: '300 - 420 SAR',
      isPublic: true,
      isVerified: true,
      isApproved: true,
      authorName: 'مهندس أتمتة',
      createdAt: DateTime.now().subtract(const Duration(days: 11)),
      comments: [],
    ),
    CommunityPost(
      id: 'ency_8',
      systemType: 'غاز وبترول',
      deviceModel: 'Gas Pressure Regulator 3-Stage',
      issueDescription: 'هبوط ضغط الغاز بشكل مفاجئ خلال التشغيل مع اهتزازات غير طبيعية في المنظم.',
      successfulSolution: '1. تم فحص المرشح والضغط الداخل والخارج.\n2. تم تنظيف المنظم واستبدال الحشية المتآكلة.\n3. عاد النظام إلى التوازن واستقر الضغط على المستوى المطلوب.',
      approximateCost: '260 - 340 SAR',
      isPublic: true,
      isVerified: true,
      isApproved: true,
      authorName: 'فني سلامة غاز',
      createdAt: DateTime.now().subtract(const Duration(days: 13)),
      comments: [],
    ),
    CommunityPost(
      id: 'ency_9',
      systemType: 'أجهزة طبية وتجارية',
      deviceModel: 'Dolphin Medical Refrigerator',
      issueDescription: 'ارتفاع غير طبيعي في درجة حرارة وحدة التبريد الطبية مع تنبيه نظام الحارس.',
      successfulSolution: '1. تم فحص مروحة التبريد ومقاومة المروحة.\n2. تم تنظيف فتحات التهوية واستبدال حساس الحرارة التالف.\n3. أعيد التشغيل بنجاح واستقرت القراءة داخل الحدود المسموح بها.',
      approximateCost: '190 - 250 SAR',
      isPublic: true,
      isVerified: true,
      isApproved: true,
      authorName: 'فني أجهزة طبية',
      createdAt: DateTime.now().subtract(const Duration(days: 8)),
      comments: [],
    ),
  ];

  Future<void> _loadFromFirestore() async {
    final db = _db;
    if (db == null) return;
    try {
      final snap = await db.collection('verified_faults').get();
      final List<CommunityPost> loaded = [];
      for (var doc in snap.docs) {
        try {
          loaded.add(CommunityPost.fromJson(doc.data()));
        } catch (_) {}
      }
      if (loaded.isNotEmpty) {
        state = state.copyWith(posts: [...loaded, ..._initialData]);
      }
    } catch (e) {
      print('Firestore load verified_faults error: $e');
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setCategoryFilter(String category) {
    state = state.copyWith(selectedCategory: category);
  }

  void addPost({
    required String systemType,
    required String deviceModel,
    required String issueDescription,
    required String successfulSolution,
    required String approximateCost,
    required bool isPublic,
    required String authorName,
    bool isVerified = false,
  }) async {
    final newPost = CommunityPost(
      id: 'ency_${DateTime.now().millisecondsSinceEpoch}',
      systemType: systemType,
      deviceModel: deviceModel,
      issueDescription: issueDescription,
      successfulSolution: successfulSolution,
      approximateCost: approximateCost,
      isPublic: false,
      isVerified: false,
      isApproved: false,
      authorName: authorName.isEmpty ? 'عضو مجهول' : authorName,
      comments: [],
      createdAt: DateTime.now(),
    );

    // تحديث الحالة المحلية فوراً
    state = state.copyWith(posts: [newPost, ...state.posts]);

    // ✅ [Firestore Sync] حفظ المنشور الجديد في pending_faults للمراجعة الإدارية
    final db = _db;
    if (db != null) {
      try {
        await db.collection('pending_faults').doc(newPost.id).set({
          ...newPost.toJson(),
          'submitted_at': FieldValue.serverTimestamp(),
          'status': 'pending_review',
        });
      } catch (e) {
        print('Firestore pending_faults save error: $e');
      }
    }

    // 📡 إطلاق إشعار للإدارة عند تقديم عطل جديد للمراجعة
    if (_ref != null) {
      _ref!.read(adminNotificationServiceProvider).triggerNewPostNotification(
        systemType: systemType,
        deviceModel: deviceModel,
        description: issueDescription,
      );
    }
  }

  Future<void> addVerifiedPost({
    required String systemType,
    required String deviceModel,
    required String issueDescription,
    required String successfulSolution,
    String approximateCost = '',
    String authorName = 'نظام التشخيص الذكي',
    String? publisherComment,
    String? publisherName,
    String? publisherExperience,
    bool? showName,
  }) async {
    final String normalizedSector = EngineeringSectors.normalizeSector(systemType);

    final newPost = CommunityPost(
      id: 'kb_${DateTime.now().millisecondsSinceEpoch}',
      systemType: normalizedSector,
      deviceModel: deviceModel,
      issueDescription: issueDescription,
      successfulSolution: successfulSolution,
      approximateCost: approximateCost.isEmpty ? 'غير محدد' : approximateCost,
      isPublic: true,
      isVerified: true,
      isApproved: true,
      authorName: authorName,
      comments: [],
      createdAt: DateTime.now(),
    );
    state = state.copyWith(posts: [newPost, ...state.posts]);

    // حفظ في Firestore بالهيكل الموحد المعتمد للموسوعة الموثقة
    final db = _db;
    if (db == null) return;
    try {
      final docData = newPost.toJson();
      if (publisherComment != null) docData['publisherComment'] = publisherComment;
      if (publisherName != null) docData['publisherName'] = publisherName;
      if (publisherExperience != null) docData['publisherExperience'] = publisherExperience;
      if (showName != null) docData['showName'] = showName;

      // 🛡️ حقن معرّف القطاع الهندسي المسمط لمنع الـ null في الموسوعة والمنتدى
      docData['sector_id'] = normalizedSector;
      docData['sector'] = normalizedSector;
      docData['system_type'] = normalizedSector;
      docData['category'] = normalizedSector;

      docData['title'] = deviceModel.isNotEmpty ? deviceModel : normalizedSector;
      docData['description'] = successfulSolution.isNotEmpty && successfulSolution != issueDescription
          ? '$issueDescription\n\n$successfulSolution'
          : issueDescription;
      docData['views_count'] = 1;
      docData['author_name'] = authorName;
      docData['created_at'] = FieldValue.serverTimestamp();
      docData['submitted_at'] = FieldValue.serverTimestamp();

      await db.collection('verified_faults').doc(newPost.id).set(docData, SetOptions(merge: true));
    } catch (e) {
      print('Firestore save verified_faults error: $e');
    }
  }

  void addApprovedPost(String id) {
    final updatedPosts = state.posts.map((post) {
      if (post.id == id) {
        return post.copyWith(isApproved: true, isPublic: true, isVerified: true);
      }
      return post;
    }).toList();

    if (updatedPosts.every((post) => post.id != id)) {
      final fallbackPost = CommunityPost(
        id: id,
        systemType: 'غير مصنف',
        deviceModel: 'إضافة جديدة',
        issueDescription: 'تمت إضافة منشور جديد بمراجعة مبكرة.',
        successfulSolution: 'سيتم مراجعة الحل وإصداره لاحقاً.',
        approximateCost: 'تحدد لاحقاً',
        isPublic: true,
        isVerified: true,
        isApproved: true,
        authorName: 'مراجع',
        comments: [],
        createdAt: DateTime.now(),
      );
      state = state.copyWith(posts: [fallbackPost, ...updatedPosts]);
      return;
    }

    state = state.copyWith(posts: updatedPosts);
  }

  // Immediate UI streaming update + Firestore persistence when a new comment is pushed
  void addComment(String postId, {required String authorName, required String text, bool isExpert = false}) async {
    final newComment = CommunityComment(
      id: 'comm_${DateTime.now().millisecondsSinceEpoch}',
      authorName: authorName.isEmpty ? 'عضو مجهول' : authorName,
      text: text,
      isExpert: isExpert,
      isApproved: false,
      createdAt: DateTime.now(),
    );

    final updatedPosts = state.posts.map((post) {
      if (post.id == postId) {
        return post.copyWith(
          comments: [...post.comments, newComment],
        );
      }
      return post;
    }).toList();

    state = state.copyWith(posts: updatedPosts);

    // ✅ [Firestore Sync] حفظ التعليق سحابياً لضمان عدم فقدانه عند إغلاق التطبيق
    final db = _db;
    if (db != null) {
      try {
        // أولاً: حفظ في verified_faults/{postId}/comments
        await db
            .collection('verified_faults')
            .doc(postId)
            .collection('comments')
            .doc(newComment.id)
            .set({
          ...newComment.toJson(),
          'is_approved': false,
          'created_at': FieldValue.serverTimestamp(),
        });
      } catch (_) {
        // ثانياً: بديل — حفظ في pending_faults إذا لم يكن postId في verified_faults
        try {
          await db
              .collection('pending_faults')
              .doc(postId)
              .collection('comments')
              .doc(newComment.id)
              .set({
            ...newComment.toJson(),
            'is_approved': false,
            'created_at': FieldValue.serverTimestamp(),
          });
        } catch (e) {
          print('Firestore comment save error: $e');
        }
      }
    }

    // 📡 إطلاق إشعار للإدارة عند إرسال تعليق جديد
    if (_ref != null) {
      final post = state.posts.firstWhere((p) => p.id == postId);
      _ref!.read(adminNotificationServiceProvider).triggerNewCommentNotification(
        author: authorName.isEmpty ? 'عضو مجهول' : authorName,
        commentText: text,
        targetItem: post.deviceModel,
      );
    }
  }

  void addPendingReply(String postId, String name, String experience, String body) {
    final safeName = name.trim().isEmpty ? 'عضو مجهول' : name.trim();
    final safeExperience = experience.trim().isEmpty ? 'مشارك' : experience.trim();
    final safeBody = body.trim().isEmpty ? 'لم يتم إدخال محتوى.' : body.trim();
    final pendingReply = CommunityComment(
      id: 'comm_${DateTime.now().millisecondsSinceEpoch}',
      authorName: safeName,
      text: '[$safeExperience] $safeBody',
      isExpert: safeExperience.isNotEmpty,
      isApproved: false,
      createdAt: DateTime.now(),
    );

    final updatedPosts = state.posts.map((post) {
      if (post.id == postId) {
        return post.copyWith(comments: [...post.comments, pendingReply]);
      }
      return post;
    }).toList();

    state = state.copyWith(posts: updatedPosts);
  }

  void approveReply(String postId, int replyIndex) {
    final updatedPosts = state.posts.map((post) {
      if (post.id != postId) {
        return post;
      }

      if (replyIndex < 0 || replyIndex >= post.comments.length) {
        return post;
      }

      final updatedComments = List<CommunityComment>.from(post.comments);
      updatedComments[replyIndex] = updatedComments[replyIndex].copyWith(isApproved: true);
      return post.copyWith(comments: updatedComments);
    }).toList();

    state = state.copyWith(posts: updatedPosts);
  }

  void rejectReply(String postId, int replyIndex) {
    final updatedPosts = state.posts.map((post) {
      if (post.id != postId) {
        return post;
      }

      if (replyIndex < 0 || replyIndex >= post.comments.length) {
        return post;
      }

      final updatedComments = List<CommunityComment>.from(post.comments);
      updatedComments.removeAt(replyIndex);
      return post.copyWith(comments: updatedComments);
    }).toList();

    state = state.copyWith(posts: updatedPosts);
  }

  // Helper function to simulated expert verification if desired
  void verifyPost(String postId) {
    final updatedPosts = state.posts.map((post) {
      if (post.id == postId) {
        return post.copyWith(isVerified: true);
      }
      return post;
    }).toList();

    state = state.copyWith(posts: updatedPosts);
  }

  /// ✅ قبول ونشر العطل من لوحة الإشراف
  void approvePost(String postId) {
    final updatedPosts = state.posts.map((post) {
      if (post.id == postId) {
        return post.copyWith(isPublic: true, isVerified: true, isApproved: true);
      }
      return post;
    }).toList();
    state = state.copyWith(posts: updatedPosts);
  }

  /// ❌ رفض وحذف العطل من لوحة الإشراف
  void rejectPost(String postId) {
    final updatedPosts = state.posts.where((post) => post.id != postId).toList();
    state = state.copyWith(posts: updatedPosts);
  }
}

// Global Providers for community state management
final communityProvider = StateNotifierProvider<CommunityNotifier, CommunityState>((ref) {
  return CommunityNotifier(ref);
});

// Selector provider for filtered posts
final filteredCommunityPostsProvider = Provider<List<CommunityPost>>((ref) {
  final CommunityState state = ref.watch(communityProvider);
  return state.posts.where((CommunityPost post) {
    // عرض المنشورات العامة المعتمدة فقط للجمهور
    if (!post.isPublic) return false;

    // 1. Filter by category
    final bool matchesCategory = state.selectedCategory == 'الكل' || 
        state.selectedCategory == 'All' || 
        post.systemType.toLowerCase() == state.selectedCategory.toLowerCase();

    // 2. Filter by search query (title, description, solutions, model)
    final bool matchesSearch = state.searchQuery.isEmpty ||
        post.deviceModel.toLowerCase().contains(state.searchQuery.toLowerCase()) ||
        post.issueDescription.toLowerCase().contains(state.searchQuery.toLowerCase()) ||
        post.successfulSolution.toLowerCase().contains(state.searchQuery.toLowerCase()) ||
        post.systemType.toLowerCase().contains(state.searchQuery.toLowerCase());

    return matchesCategory && matchesSearch;
  }).toList();
});
