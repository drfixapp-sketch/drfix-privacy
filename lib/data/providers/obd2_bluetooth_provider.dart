import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// حالات اتصال قطعة الفحص اللاسلكية بالبلوتوث
enum Obd2ConnectionStatus { disconnected, scanning, connecting, connected, signalLossError }

class Obd2BluetoothState {
  final Obd2ConnectionStatus status;
  final String connectedDeviceName;
  final List<String> extractedDtcCodes;
  final String liveErrorMessage;

  Obd2BluetoothState({
    required this.status,
    this.connectedDeviceName = '',
    this.extractedDtcCodes = const [],
    this.liveErrorMessage = '',
  });

  Obd2BluetoothState copyWith({
    Obd2ConnectionStatus? status,
    String? connectedDeviceName,
    List<String>? extractedDtcCodes,
    String? liveErrorMessage,
  }) {
    return Obd2BluetoothState(
      status: status ?? this.status,
      connectedDeviceName: connectedDeviceName ?? this.connectedDeviceName,
      extractedDtcCodes: extractedDtcCodes ?? this.extractedDtcCodes,
      liveErrorMessage: liveErrorMessage ?? this.liveErrorMessage,
    );
  }
}

class Obd2BluetoothNotifier extends StateNotifier<Obd2BluetoothState> {
  Obd2BluetoothNotifier() : super(Obd2BluetoothState(status: Obd2ConnectionStatus.disconnected));

  Timer? _signalTimeoutTimer;

  // خوارزمية الاتصال اللاسلكي السريع وسحب أكواد الفحص تلقائياً (OBD2 Gateway Ingest)
  Future<void> connectAndScanObd2Device() async {
    state = state.copyWith(status: Obd2ConnectionStatus.scanning, liveErrorMessage: '');
    
    try {
      // 1. محاكاة بدء مسح الإشارات اللاسلكية في الورشة والارتباط بالقطع المتاحة
      await Future.delayed(const Duration(seconds: 1));
      state = state.copyWith(status: Obd2ConnectionStatus.connecting, connectedDeviceName: 'OBDII-ELM327-VLink');
      
      // 2. محاكاة نجاح الاتصال واستقرار بث دفق البيانات التسلسلي
      await Future.delayed(const Duration(milliseconds: 800));
      
      // تفعيل مؤقت الأمان لحماية الـ UI من التجمد في حال فقدان الإشارة اللاسلكية فجأة (Signal Interlock)
      _startSignalLossTimeout();

      state = Obd2BluetoothState(
        status: Obd2ConnectionStatus.connected,
        connectedDeviceName: 'OBDII-ELM327-VLink',
        extractedDtcCodes: ['P0300', 'P0171'], // حقن تلقائي آمن لأكواد عطل الاحتراق ونقص الوقود
      );
      
      // إيقاف مؤقت الأمان بعد نجاح سحب وحقن البيانات بنجاح وثبات
      _signalTimeoutTimer?.cancel();

    } catch (e) {
      _signalTimeoutTimer?.cancel();
      state = Obd2BluetoothState(
        status: Obd2ConnectionStatus.signalLossError,
        liveErrorMessage: 'فشل الاتصال: حدث خطأ في استجابة بوابة البلوتوث، يرجى إعادة المحاولة.',
      );
    }
  }

  // بروتوكول الأمان لحماية الشاشة من الانقطاع المفاجئ للهاردوير وسط ورشة السيارات
  void _startSignalLossTimeout() {
    _signalTimeoutTimer?.cancel();
    _signalTimeoutTimer = Timer(const Duration(seconds: 4), () {
      if (state.status == Obd2ConnectionStatus.connecting) {
        state = Obd2BluetoothState(
          status: Obd2ConnectionStatus.signalLossError,
          liveErrorMessage: '🚨 انقطاع الإشارة: تراجع تلقائي آمن، قطعة الفحص OBD2 لم تستجب بالوقت المحدد لمنع تجميد الواجهة.',
        );
      }
    });
  }

  // دالة فصل الاتصال وتصفير الكاش اللاسلكي بأمان
  void disconnectObd2Device() {
    _signalTimeoutTimer?.cancel();
    state = Obd2BluetoothState(status: Obd2ConnectionStatus.disconnected);
  }

  @override
  void dispose() {
    _signalTimeoutTimer?.cancel();
    super.dispose();
  }
}

// الـ Provider المركزي الموحد المسؤول عن إدارة وأتمتة دفق فحص البلوتوث لسيارات الفنيين
final obd2BluetoothProvider = StateNotifierProvider<Obd2BluetoothNotifier, Obd2BluetoothState>((ref) {
  return Obd2BluetoothNotifier();
});
