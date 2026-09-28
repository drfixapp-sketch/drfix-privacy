import 'package:flutter/material.dart';
import 'package:dr_fix/data/network/exceptions.dart';

/// ويدجت احترافية مخصصة لعرض الأخطاء بشكل تفاعلي وجميل للمستخدم
/// تمنع تجمد التطبيق أو ظهور واجهة فارغة، وتوفر زر "إعادة المحاولة" مع تفاصيل الخطأ الفنية مخفية بشكل افتراضي
class ErrorPlaceholderWidget extends StatefulWidget {
  final AppException exception;
  final VoidCallback? onRetry;
  final String languageCode;

  const ErrorPlaceholderWidget({
    Key? key,
    required this.exception,
    this.onRetry,
    this.languageCode = 'ar',
  }) : super(key: key);

  @override
  State<ErrorPlaceholderWidget> createState() => _ErrorPlaceholderWidgetState();
}

class _ErrorPlaceholderWidgetState extends State<ErrorPlaceholderWidget> {
  bool _showTechnicalDetails = false;

  @override
  Widget build(BuildContext context) {
    final bool isAr = widget.languageCode == 'ar';
    final message = widget.exception.getLocalizedMessage(widget.languageCode);
    
    // تحديد الأيقونة واللون بناءً على نوع الاستثناء المخصص
    IconData errorIcon = Icons.error_outline_rounded;
    Color iconColor = Colors.red.shade600;
    Color bgColor = Colors.red.shade100.withOpacity(0.5);

    if (widget.exception is NetworkException) {
      errorIcon = Icons.wifi_off_rounded;
      iconColor = Colors.orange.shade700;
      bgColor = Colors.orange.shade100.withOpacity(0.5);
    } else if (widget.exception is UnauthorizedException) {
      errorIcon = Icons.lock_person_rounded;
      iconColor = Colors.red.shade700;
      bgColor = Colors.red.shade100.withOpacity(0.6);
    } else if (widget.exception is ApiKeyException) {
      errorIcon = Icons.vpn_key_rounded;
      iconColor = Colors.amber.shade800;
      bgColor = Colors.amber.shade100.withOpacity(0.5);
    } else if (widget.exception is ServerException) {
      errorIcon = Icons.cloud_off_rounded;
    }

    return Center(
      child: Container(
        margin: const EdgeInsets.all(16.0),
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // أيقونة الخطأ المعبرة والمتحركة بحذر
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                errorIcon,
                color: iconColor,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            
            // عنوان الخطأ بناء على النوع
            Text(
              _getErrorTitle(widget.exception, isAr),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: iconColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            
            // الرسالة الودية والمفهومة للمستخدم
            Text(
              message,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF475569),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 18),
            
            // صف أزرار التحكم (إعادة المحاولة والتفاصيل الفنية)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.onRetry != null)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F75BC),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    onPressed: widget.onRetry,
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: Text(
                      isAr ? 'إعادة المحاولة' : 'Retry',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                const SizedBox(width: 8),
                TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF64748B),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  onPressed: () {
                    setState(() {
                      _showTechnicalDetails = !_showTechnicalDetails;
                    });
                  },
                  icon: Icon(
                    _showTechnicalDetails ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                    size: 16,
                  ),
                  label: Text(
                    isAr ? 'التفاصيل الفنية' : 'Technical Info',
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
              ],
            ),
            
            // قسم التفاصيل الفنية المخفية (الأكواد والسجلات) لمديري النظام والمطورين
            if (_showTechnicalDetails) ...[
              const SizedBox(height: 12),
              const Divider(color: Color(0xFFE2E8F0)),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Technical Log:',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey.shade800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    SelectableText(
                      widget.exception.technicalMessage ?? 'No technical logs recorded.',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    if (widget.exception.statusCode != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'HTTP Status Code: ${widget.exception.statusCode}',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getErrorTitle(AppException ex, bool isAr) {
    if (ex is NetworkException) {
      return isAr ? 'فشل في الاتصال' : 'Connection Failed';
    } else if (ex is UnauthorizedException) {
      return isAr ? 'انتهت الجلسة الأمنية' : 'Session Expired';
    } else if (ex is ApiKeyException) {
      return isAr ? 'خطأ في إعدادات الخدمة' : 'Service Config Error';
    } else if (ex is ServerException) {
      return isAr ? 'عطل بخادم النظام' : 'Server System Fault';
    } else {
      return isAr ? 'تنبيه فني طارئ' : 'Technical Alert';
    }
  }
}

/// فئة خدمات وتنبيهات لعرض الأخطاء بصورة فورية وسريعة (SnackBars / Dialogs)
class ErrorUiPresenter {
  
  /// عرض تنبيه شريطي سفلي (SnackBar) منسق ومخصص حسب نوع الاستثناء المالي والفني
  static void showErrorSnackbar(
    BuildContext context, 
    AppException exception, {
    String languageCode = 'ar',
  }) {
    final bool isAr = languageCode == 'ar';
    final message = exception.getLocalizedMessage(languageCode);
    
    IconData snackIcon = Icons.error_rounded;
    Color snackColor = Colors.red.shade700;

    if (exception is NetworkException) {
      snackIcon = Icons.wifi_off_rounded;
      snackColor = Colors.orange.shade800;
    } else if (exception is UnauthorizedException) {
      snackIcon = Icons.lock_reset_rounded;
      snackColor = Colors.red.shade900;
    }

    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: snackColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(12),
        duration: const Duration(seconds: 4),
        content: Row(
          children: [
            Icon(snackIcon, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// عرض صندوق حواري جميل ومنسق للسلامة الفورية والأخطاء المعقدة
  static void showErrorDialog(
    BuildContext context, 
    AppException exception, {
    String languageCode = 'ar',
    VoidCallback? onRetry,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: ErrorPlaceholderWidget(
            exception: exception,
            languageCode: languageCode,
            onRetry: onRetry != null 
              ? () {
                  Navigator.pop(context);
                  onRetry();
                }
              : null,
          ),
        ),
      ),
    );
  }
}
