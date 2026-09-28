import 'package:geolocator/geolocator.dart';

class CurrencyGeoService {
  // دالة الفحص الجغرافي السريع لتحديد العملة الملحقة بالأسعار التقديرية حياً
  static Future<String> getCurrencyBasedOnLocation(bool isRtl) async {
    try {
      // 1. التحقق من تفعيل فني الميدان لخدمات الموقع بالجهاز
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return isRtl ? 'ريال سعودي' : 'SAR'; // العملة الافتراضية الاحتياطية في حال الإغلاق
      }

      // 2. التحقق من صلاحيات الوصول للموقع ومنحها الأمان
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return isRtl ? 'ريال سعودي' : 'SAR';
        }
      }

      // 3. قراءة الإحداثيات الجغرافية الحالية للفني بأعلى سرعة حفظاً للبطارية
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low, // دقة منخفضة لحفظ شحن بطارية الفني في الورشة
      );

      double lat = position.latitude;
      double lng = position.longitude;

      // 4. معالج الفحص الميداني (Geofencing النطاق الجغرافي التقريبي للأردن)
      // الحدود التقريبية للمملكة الأردنية الهاشمية 🇯🇴
      if (lat >= 29.18 && lat <= 33.37 && lng >= 34.95 && lng <= 39.30) {
        return isRtl ? 'دينار أردني' : 'JOD';
      }

      // 5. الحدود التقريبية للمملكة العربية السعودية وبقية دول الخليج العربي 🇸🇦
      if (lat >= 15.45 && lat <= 32.15 && lng >= 34.50 && lng <= 60.00) {
        return isRtl ? 'ريال سعودي' : 'SAR';
      }

      // في حال كان الفني في تخصص دولي آخر خارج النطاق نعود بالعملة الخليجية الافتراضية
      return isRtl ? 'ريال سعودي' : 'SAR';
    } catch (e) {
      // معالجة الأخطاء برمجياً لضمان عدم انهيار الواجهة إطلاقاً تحت أي ظرف
      return isRtl ? 'ريال سعودي' : 'SAR';
    }
  }
}
