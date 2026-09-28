import 'package:flutter_riverpod/flutter_riverpod.dart';

class AdminAuthState {
  final bool isAdminAuthenticated;
  final bool isFirstGatePassed;
  final String currentHashedPassword;
  final String securityErrorMessage;

  AdminAuthState({
    required this.isAdminAuthenticated,
    required this.isFirstGatePassed,
    required this.currentHashedPassword,
    this.securityErrorMessage = '',
  });

  AdminAuthState copyWith({
    bool? isAdminAuthenticated,
    bool? isFirstGatePassed,
    String? currentHashedPassword,
    String? securityErrorMessage,
  }) {
    return AdminAuthState(
      isAdminAuthenticated: isAdminAuthenticated ?? this.isAdminAuthenticated,
      isFirstGatePassed: isFirstGatePassed ?? this.isFirstGatePassed,
      currentHashedPassword: currentHashedPassword ?? this.currentHashedPassword,
      securityErrorMessage: securityErrorMessage ?? this.securityErrorMessage,
    );
  }
}

class AdminAuthNotifier extends StateNotifier<AdminAuthState> {
  AdminAuthNotifier() : super(AdminAuthState(
    isAdminAuthenticated: false,
    isFirstGatePassed: false,
    currentHashedPassword: 'FixAdmin2026', 
  ));

  bool verifyFirstGateSecretDialog(String enteredCode) {
    if (enteredCode.trim() == state.currentHashedPassword) {
      state = state.copyWith(isFirstGatePassed: true, securityErrorMessage: '');
      return true;
    } else {
      state = state.copyWith(securityErrorMessage: 'خطأ: الرمز السري غير صحيح.');
      return false;
    }
  }

  bool verifySecondGateFinalAccess(String enteredCode) {
    if (state.isFirstGatePassed && enteredCode.trim() == state.currentHashedPassword) {
      state = state.copyWith(isAdminAuthenticated: true, securityErrorMessage: '');
      return true;
    } else {
      state = state.copyWith(securityErrorMessage: '🚨 رفض العبور: فشل بروتوكول التحقق الثنائي.');
      return false;
    }
  }

  bool updateAdminPasswordTripleCheck({
    required String oldPassword,
    required String newPassword,
    required String confirmNewPassword,
  }) {
    if (oldPassword.trim() != state.currentHashedPassword) {
      state = state.copyWith(securityErrorMessage: 'فشل التعديل: الرمز الحالي غير مطابِق.');
      return false;
    }
    if (newPassword.trim().isEmpty || newPassword.trim() != confirmNewPassword.trim()) {
      state = state.copyWith(securityErrorMessage: 'فشل التعديل: الرموز غير متطابقة.');
      return false;
    }
    state = state.copyWith(currentHashedPassword: newPassword.trim(), securityErrorMessage: '');
    return true;
  }

  void secureLogoutAndLockAllGates() {
    state = state.copyWith(isAdminAuthenticated: false, isFirstGatePassed: false, securityErrorMessage: '');
  }
}

final adminAuthInterlockProvider = StateNotifierProvider<AdminAuthNotifier, AdminAuthState>((ref) {
  return AdminAuthNotifier();
});
