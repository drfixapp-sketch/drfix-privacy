import 'package:flutter_riverpod/flutter_riverpod.dart';

// حالات إدارة الموقع الجغرافي والبحث التراجعي
enum LocationSearchStatus { loading, permissionDenied, locateSuccess, manualSearchMode }

class LocationState {
  final LocationSearchStatus status;
  final String currentCity;
  final double? latitude;
  final double? longitude;

  LocationState({
    required this.status,
    this.currentCity = '',
    this.latitude,
    this.longitude,
  });

  LocationState copyWith({
    LocationSearchStatus? status,
    String? currentCity,
    double? latitude,
    double? longitude,
  }) {
    return LocationState(
      status: status ?? this.status,
      currentCity: currentCity ?? this.currentCity,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }
}

class LocationNotifier extends StateNotifier<LocationState> {
  LocationNotifier() : super(LocationState(status: LocationSearchStatus.loading)) {
    requestLocationAndFetchPromos();
  }

  // خوارزمية معالجة الصلاحيات واستراتيجية التراجع الآمن (Fallback Strategy)
  Future<void> requestLocationAndFetchPromos() async {
    state = state.copyWith(status: LocationSearchStatus.loading);
    
    try {
      // محاكاة استدعاء الـ Geolocation API الخاص بالنظام
      await Future.delayed(const Duration(seconds: 1));
      bool isPermissionGranted = true; // يتم ربطه بـ Geolocator.requestPermission()
      
      if (isPermissionGranted) {
        // حالة النجاح: سحب إحداثيات الفني وتصفية الشركات الأقرب جغرافياً تلقائياً
        state = LocationState(
          status: LocationSearchStatus.locateSuccess,
          currentCity: 'الرياض', // مثال افتراضي للموقع الحالي
          latitude: 24.7136,
          longitude: 46.6753,
        );
      } else {
        // حالة الرفض: الانتقال التلقائي لخطة التراجع والبحث اليدوي لحماية التصميم من التجميد
        state = LocationState(status: LocationSearchStatus.permissionDenied, currentCity: '');
      }
    } catch (e) {
      // عند حدوث أي استثناء برمي، يتحول النظام آلياً لطور البحث اليدوي الآمن
      state = LocationState(status: LocationSearchStatus.manualSearchMode, currentCity: '');
    }
  }

  // دالة تمكين الفني من كتابة اسم المدينة أو الحي يدوياً في حال رفض الصلاحية
  void setManualCitySearch(String city) {
    state = LocationState(
      status: LocationSearchStatus.manualSearchMode,
      currentCity: city,
    );
    // هنا يتم إعادة عمل Fetch للأكواد والورش بناءً على المدينة المدخلة يدوياً
  }
}

// الـ Provider المركزي لإدارة الموقع والبحث اللوجستي المشروط لدى الفني
final locationProvider = StateNotifierProvider<LocationNotifier, LocationState>((ref) {
  return LocationNotifier();
});
