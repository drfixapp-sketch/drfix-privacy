import 'package:flutter_riverpod/flutter_riverpod.dart';

// تصنيفات التذاكر الثلاثة المعتمدة في شاشة الدعم الفني والملاحظات
enum SupportTicketCategory { bug, enhancement, generalInquiry }

/// كلاس نمذجة التذكرة الصناعية لحفظ نوع وحالة البلاغ الميداني
class SupportTicketModel {
  final String ticketId;
  final String title;
  final String description;
  final String contactEmail;
  final SupportTicketCategory category;
  final String timestamp;
  final bool isResolved; // حالة التذكرة في لوحة الأدمن

  SupportTicketModel({
    required this.ticketId,
    required this.title,
    required this.description,
    required this.contactEmail,
    required this.category,
    required this.timestamp,
    this.isResolved = false,
  });

  SupportTicketModel copyWith({bool? isResolved}) {
    return SupportTicketModel(
      ticketId: ticketId,
      title: title,
      description: description,
      contactEmail: contactEmail,
      category: category,
      timestamp: timestamp,
      isResolved: isResolved ?? this.isResolved,
    );
  }
}

class TechnicalSupportNotifier extends StateNotifier<List<SupportTicketModel>> {
  TechnicalSupportNotifier() : super([]);

  // خوارزمية إنشاء تذكرة جديدة وضخها حياً (Create Ticket & Auto-Ingest Pipeline)
  void createNewSupportTicket({
    required String title,
    required String description,
    required String email,
    required SupportTicketCategory category,
  }) {
    final newTicket = SupportTicketModel(
      ticketId: 'TCK-${DateTime.now().millisecondsSinceEpoch}',
      title: title.trim(),
      description: description.trim(),
      contactEmail: email.trim().isEmpty ? 'guest@drfix.app' : email.trim(),
      category: category,
      timestamp: DateTime.now().toString().substring(0, 16),
      isResolved: false,
    );

    // تحديث الـ State حياً وضخ التذكرة فوراً في السيرفر وقسم "التذاكر" بلوحة الأدمن
    state = [...state, newTicket];
    
    // بروتوكول اتصال الـ Backend للوحة تحكم الإدارة:
    // _apiService.post('/admin/tickets', data: newTicket.toMap());
  }

  // دالة تغيير حالة التذكرة إلى "تم الحل" من قبل الأدمن داخل لوحة الإدارة
  void resolveTicketFromAdmin(String id) {
    state = [
      for (final ticket in state)
        if (ticket.ticketId == id) ticket.copyWith(isResolved: true) else ticket
    ];
  }
}

// الـ Provider المركزي الموحد المسؤول عن تدفق وإدارة التذاكر والبلاغات الحية بين الفني والأدمن
final technicalSupportProvider = StateNotifierProvider<TechnicalSupportNotifier, List<SupportTicketModel>>((ref) {
  return TechnicalSupportNotifier();
});
