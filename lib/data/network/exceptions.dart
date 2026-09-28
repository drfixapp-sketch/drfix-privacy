class AppException implements Exception {
  final String messageAr;
  final String messageEn;
  final String? technicalMessage;
  final int? statusCode;

  AppException({
    required this.messageAr,
    required this.messageEn,
    this.technicalMessage,
    this.statusCode,
  });

  String getLocalizedMessage(String lang) {
    return lang == 'ar' ? messageAr : messageEn;
  }

  @override
  String toString() => 'AppException: $messageAr ($messageEn). Detail: $technicalMessage';
}

class NetworkException extends AppException {
  NetworkException({String? technicalMessage})
      : super(
          messageAr: 'لا يوجد اتصال بالإنترنت أو انتهت مهلة الاتصال. يرجى التحقق من الشبكة.',
          messageEn: 'No internet connection or request timeout. Please check your network.',
          technicalMessage: technicalMessage,
        );
}

class ServerException extends AppException {
  ServerException({int? statusCode, String? technicalMessage})
      : super(
          messageAr: 'حدث خطأ في خادم الخدمة الميدانية ($statusCode). يرجى المحاولة لاحقاً.',
          messageEn: 'Server error occurred ($statusCode). Please try again later.',
          statusCode: statusCode,
          technicalMessage: technicalMessage,
        );
}

class UnauthorizedException extends AppException {
  UnauthorizedException({String? technicalMessage})
      : super(
          messageAr: 'انتهت الجلسة المعتمدة فنيّاً، يرجى إعادة تسجيل الدخول للحماية.',
          messageEn: 'Session expired. Please log in again for verification and security.',
          statusCode: 401,
          technicalMessage: technicalMessage,
        );
}

class ApiKeyException extends AppException {
  ApiKeyException({String? technicalMessage})
      : super(
          messageAr: 'رمز أو مفتاح الربط بالذكاء الاصطناعي (API Key) غير مهيأ أو مقيد فنيّاً.',
          messageEn: 'AI API Key is not configured or restricted in your environment.',
          technicalMessage: technicalMessage,
        );
}

class CacheException extends AppException {
  CacheException({String? technicalMessage})
      : super(
          messageAr: 'تعذر استرجاع البيانات المؤقتة المخزنة محليّاً على الهاتف.',
          messageEn: 'Failed to retrieve cached offline data from storage.',
          technicalMessage: technicalMessage,
        );
}

class UnknownException extends AppException {
  UnknownException({String? technicalMessage})
      : super(
          messageAr: 'حدث خطأ فني غير متوقع بالمنظومة أثناء معالجة الطلب.',
          messageEn: 'An unexpected technical error occurred while processing the request.',
          technicalMessage: technicalMessage,
        );
}
