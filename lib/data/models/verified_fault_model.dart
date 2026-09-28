import 'package:cloud_firestore/cloud_firestore.dart';

/// 📚 موديل العطل الموثق في الموسوعة الهندسية (Verified Fault Model)
/// يتميز ببنية بيانات صافية واقتصادية خالية من الردود لتوفير استهلاك الباقة
class VerifiedFault {
  final String id;
  final String title;
  final String description;
  final String sector;
  final int viewsCount;
  final String authorName;
  final DateTime createdAt;
  final String? authorEmail;
  final String? authorId;

  const VerifiedFault({
    required this.id,
    required this.title,
    required this.description,
    required this.sector,
    this.viewsCount = 1,
    required this.authorName,
    required this.createdAt,
    this.authorEmail,
    this.authorId,
  });

  VerifiedFault copyWith({
    String? id,
    String? title,
    String? description,
    String? sector,
    int? viewsCount,
    String? authorName,
    DateTime? createdAt,
    String? authorEmail,
    String? authorId,
  }) {
    return VerifiedFault(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      sector: sector ?? this.sector,
      viewsCount: viewsCount ?? this.viewsCount,
      authorName: authorName ?? this.authorName,
      createdAt: createdAt ?? this.createdAt,
      authorEmail: authorEmail ?? this.authorEmail,
      authorId: authorId ?? this.authorId,
    );
  }

  factory VerifiedFault.fromJson(Map<String, dynamic> json) {
    DateTime parsedCreatedAt = DateTime.now();
    if (json['created_at'] != null) {
      if (json['created_at'] is String) {
        parsedCreatedAt = DateTime.tryParse(json['created_at'] as String) ?? DateTime.now();
      } else if (json['created_at'] is Timestamp) {
        parsedCreatedAt = (json['created_at'] as Timestamp).toDate();
      }
    } else if (json['createdAt'] != null) {
      if (json['createdAt'] is String) {
        parsedCreatedAt = DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now();
      } else if (json['createdAt'] is Timestamp) {
        parsedCreatedAt = (json['createdAt'] as Timestamp).toDate();
      }
    }

    return VerifiedFault(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      sector: json['sector'] as String? ?? 'أخرى',
      viewsCount: (json['views_count'] as num?)?.toInt() ?? (json['viewsCount'] as num?)?.toInt() ?? 1,
      authorName: json['author_name'] as String? ?? (json['authorName'] as String? ?? 'مهندس معتمد'),
      createdAt: parsedCreatedAt,
      authorEmail: json['author_email'] as String? ?? (json['authorEmail'] as String?),
      authorId: json['author_id'] as String? ?? (json['authorId'] as String?),
    );
  }

  factory VerifiedFault.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    DateTime parsedCreatedAt = DateTime.now();
    if (data['created_at'] is Timestamp) {
      parsedCreatedAt = (data['created_at'] as Timestamp).toDate();
    } else if (data['created_at'] is String) {
      parsedCreatedAt = DateTime.tryParse(data['created_at'] as String) ?? DateTime.now();
    }

    return VerifiedFault(
      id: doc.id,
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      sector: data['sector'] as String? ?? 'أخرى',
      viewsCount: (data['views_count'] as num?)?.toInt() ?? 1,
      authorName: data['author_name'] as String? ?? 'مهندس معتمد',
      createdAt: parsedCreatedAt,
      authorEmail: data['author_email'] as String? ?? (data['authorEmail'] as String?),
      authorId: data['author_id'] as String? ?? (data['authorId'] as String?),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'sector': sector,
      'views_count': viewsCount,
      'author_name': authorName,
      'created_at': createdAt.toIso8601String(),
      if (authorEmail != null) 'author_email': authorEmail,
      if (authorId != null) 'author_id': authorId,
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'sector': sector,
      'views_count': viewsCount,
      'author_name': authorName,
      'created_at': Timestamp.fromDate(createdAt),
      if (authorEmail != null) 'author_email': authorEmail,
      if (authorId != null) 'author_id': authorId,
    };
  }

  /// البيانات المرجعية الأولية للقطاعات الـ 9 في حال عدم توفر اتصال لحظي
  static final List<VerifiedFault> initialSeedData = [
    VerifiedFault(
      id: 'vf_1',
      sector: 'تبريد وتكييف',
      authorName: 'مهندس سليم',
      title: 'ارتفاع حرارة المبخر خلال التشغيل المستمر في أنظمة التكييف',
      description: 'أسباب ارتفاع الحرارة عند التبديل بين المراحل في التثبيتات الخارجية المزدحمة وطرق فحص توازن الفريون وضغط السحب والمعايرة الدقيقة لبلف التمدد.',
      viewsCount: 128,
      createdAt: DateTime(2026, 1, 15),
    ),
    VerifiedFault(
      id: 'vf_2',
      sector: 'كهرباء',
      authorName: 'مهندس فادي',
      title: 'انقطاع التيار المؤقت في لوحات التحكم الصناعية عند بدء الحمل العالي',
      description: 'فحص هبوط الجهد اللحظي (Voltage Sag) وتذبذب إشارة الترحيل عند بدء تشغيل المحركات الحثية الكبيرة وحلول إضافة مكثفات تحسين معامل القدرة.',
      viewsCount: 96,
      createdAt: DateTime(2026, 2, 1),
    ),
    VerifiedFault(
      id: 'vf_3',
      sector: 'ميكانيك',
      authorName: 'مهندس رامي',
      title: 'اهتزاز غير طبيعي في وحدة الدوران الحركية بعد الصيانة الميكانيكية',
      description: 'تقييم اختلال المحاذاة المحورية (Shaft Misalignment) وتلف كراسي التحميل (Bearings) واستخدام جهاز قياس الاهتزازات لضبط الاتزان الحركي بدقة.',
      viewsCount: 84,
      createdAt: DateTime(2026, 2, 10),
    ),
    VerifiedFault(
      id: 'vf_4',
      sector: 'أنظمة الهيدروليك',
      authorName: 'مهندس هاني',
      title: 'ضغط غير مستقر في الدائرة الهيدروليكية وتكهف مضخة التروس',
      description: 'تحليل أسباب تراجع الضغط التشغيلي وتسريب الهواء عبر خط السحب، وتنظيف الفلاتر المعلقة وتغيير حلقات الإحكام المانعة للتسريب.',
      viewsCount: 72,
      createdAt: DateTime(2026, 2, 18),
    ),
    VerifiedFault(
      id: 'vf_5',
      sector: 'أجهزة منزلية',
      authorName: 'مهندس لينا',
      title: 'توقف الغسالة الأوتوماتيكية عند دورة العصر مع استمرار تصريف المياه',
      description: 'فحص مستشعر السرعة والدوران (Tachometer Sensor) ومفتاح قفل الباب الحراري والتأكد من استقرار توازن الحلة الداخلية ومساعدات التثبيت.',
      viewsCount: 111,
      createdAt: DateTime(2026, 2, 22),
    ),
    VerifiedFault(
      id: 'vf_6',
      sector: 'صناعي',
      authorName: 'مهندس محمد',
      title: 'توقف مفاجئ لخط الإنتاج بسبب إنذار Overload في محول التردد VFD',
      description: 'تحليل أسباب ارتفاع درجة حرارة المشتت الحراري ومروحة التبريد الداخلية وضبط إعدادات زمن التسارع (Acceleration Time) لمنع الانهيار الكهربائي.',
      viewsCount: 142,
      createdAt: DateTime(2026, 2, 28),
    ),
    VerifiedFault(
      id: 'vf_7',
      sector: 'سيارات ومركبات',
      authorName: 'مهندس يزن',
      title: 'تذبذب قراءة حساس تدفق الهواء MAF وارتفاع استهلاك الوقود',
      description: 'تنظيف سلك الحساس بالبخاخ المخصص وفحص تسريبات الهواء غير المحسوبة في مجرى السحب والتأكد من استجابة حساس الأكسجين O2 في درجات الحرارة العالية.',
      viewsCount: 90,
      createdAt: DateTime(2026, 3, 2),
    ),
    VerifiedFault(
      id: 'vf_8',
      sector: 'سباكة',
      authorName: 'مهندس إسلام',
      title: 'ظاهرة المطرقة المائية (Water Hammer) وانخفاض الضغط في الخط الرئيسي',
      description: 'تركيب صمامات مانعة لارتداد الصدمات المائية وموازنة منظم ضغط الدخول وتنظيف فلاتر الرواسب لضمان تدفق مستقر وشبكة أنابيب آمنة.',
      viewsCount: 67,
      createdAt: DateTime(2026, 3, 5),
    ),
    VerifiedFault(
      id: 'vf_9',
      sector: 'أخرى',
      authorName: 'مهندس علاء',
      title: 'تداخل الإشارات الكهرومغناطيسية EMI في كابلات نقل البيانات التناظرية',
      description: 'حلول فصل مسارات كابلات القدرة عن كابلات الإشارة واستخدام الكابلات المجدولة والمحمية وتأريض الشيلد من جهة واحدة لتجنب الحلقات الأرضية.',
      viewsCount: 58,
      createdAt: DateTime(2026, 3, 7),
    ),
  ];
}
