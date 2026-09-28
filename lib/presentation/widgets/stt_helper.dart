import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

/// دالة مساعدة مخصصة لحساب واختيار أفضل رمز لغة (LocaleId) لـ SpeechToText
/// تضمن التوافق التام مع محركات سامسونج (Samsung Voice Service) وجوجل
Future<String> resolveBestSttLocale(stt.SpeechToText speech, bool isRtl) async {
  try {
    final systemLocale = await speech.systemLocale();
    final systemId = systemLocale?.localeId ?? '';

    if (isRtl) {
      final locales = await speech.locales();
      // 1. التفضيل الأساسي والمستهدف لأجهزة سامسونج بالشرق الأوسط: البحث عن ar-SA أو ar_SA
      for (final l in locales) {
        final id = l.localeId.replaceAll('_', '-').toLowerCase();
        if (id == 'ar-sa') {
          return l.localeId;
        }
      }
      // 2. فحص لغة النظام إن كانت عربية
      if (systemId.toLowerCase().startsWith('ar')) {
        return systemId;
      }
      // 3. البحث عن أي ترميز عربي آخر متوفر في الجهاز (مثل ar-JO, ar-EG...)
      for (final l in locales) {
        final id = l.localeId.replaceAll('_', '-').toLowerCase();
        if (id.startsWith('ar')) {
          return l.localeId;
        }
      }
      // 4. خيار احتياطي افتراضي مضمون لسامسونج
      return 'ar_SA';
    } else {
      if (systemId.toLowerCase().startsWith('en')) {
        return systemId;
      }
      final locales = await speech.locales();
      for (final l in locales) {
        final id = l.localeId.replaceAll('_', '-').toLowerCase();
        if (id.startsWith('en')) {
          return l.localeId;
        }
      }
      return 'en_US';
    }
  } catch (e) {
    debugPrint('STT resolveBestSttLocale error: $e');
    return isRtl ? 'ar_SA' : 'en_US';
  }
}
