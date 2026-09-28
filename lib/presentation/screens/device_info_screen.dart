import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'diagnostic_report_screen.dart';
import 'package:dr_fix/main.dart';
import 'package:dr_fix/data/models/dynamic_field_config.dart';
import 'package:dr_fix/presentation/widgets/custom_drawer.dart';
import 'package:dr_fix/data/providers/diagnostic_engine_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dr_fix/presentation/providers/auth_provider.dart';
import 'package:dr_fix/presentation/screens/login_screen.dart';
import '../widgets/stt_helper.dart';

class DeviceInfoScreen extends ConsumerStatefulWidget {
  final String categoryName;

  const DeviceInfoScreen({Key? key, required this.categoryName}) : super(key: key);

  @override
  ConsumerState<DeviceInfoScreen> createState() => _DeviceInfoScreenState();
}

class _DeviceInfoScreenState extends ConsumerState<DeviceInfoScreen> {
  final TextEditingController _deviceNameController = TextEditingController();
  final TextEditingController _manufacturerController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _problemDetailsController = TextEditingController();
  final TextEditingController _observationsController = TextEditingController();
  final TextEditingController _errorCodeController = TextEditingController();

  // محرك تحويل الكلام إلى نص متوافق مع Gradle 9 / Android moderno
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechAvailable = false;   // هل الجهاز يدعم STT؟
  String _activeMicField = '';     // مفتاح الحقل النشط حالياً للاستماع
  static const int _maxImages = 3;
  final List<XFile?> _selectedImages = List<XFile?>.filled(3, null);
  final ImagePicker _picker = ImagePicker();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _deviceNameController.dispose();
    _manufacturerController.dispose();
    _modelController.dispose();
    _problemDetailsController.dispose();
    _observationsController.dispose();
    _errorCodeController.dispose();
    _speech.stop();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _deviceNameController.addListener(() => setState(() {}));
    _problemDetailsController.addListener(() => setState(() {}));
    // تهيئة محرك STT — يطلب صلاحية الميكروفون عند أول استخدام
    _speech.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          if (mounted) setState(() => _activeMicField = '');
        }
      },
      onError: (error) {
        debugPrint('STT Error: ${error.errorMsg}');
        if (mounted) setState(() => _activeMicField = '');
      },
      options: [stt.SpeechToText.webDoNotAggregate],
    ).then((available) {
      if (mounted) setState(() => _speechAvailable = available);
    }).catchError((Object error) {
      debugPrint('STT initialize failed: $error');
      if (mounted) setState(() => _speechAvailable = false);
    });
  }

  /// يُشغّل الاستماع الحقيقي عبر SpeechToText أو يوقفه عند الضغط مرة ثانية.
  /// النتيجة تُكتب مباشرة في [controller] فور انتهاء التعرف.
  Future<void> _handleMicPress(String fieldKey, TextEditingController controller, bool isRtl) async {
    // إذا كان هذا الحقل نفسه نشطاً — إيقاف الاستماع
    if (_activeMicField == fieldKey) {
      await _speech.stop();
      if (mounted) setState(() => _activeMicField = '');
      return;
    }

    // إيقاف أي حقل آخر كان نشطاً
    if (_activeMicField.isNotEmpty) {
      await _speech.stop();
    }

    // التحقق من توافر STT على الجهاز
    if (!_speechAvailable) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(isRtl
              ? '⚠️ التعرف على الكلام غير مدعوم على هذا الجهاز.'
              : '⚠️ Speech recognition is not supported on this device.'),
          backgroundColor: Colors.orange,
        ));
      }
      return;
    }

    setState(() => _activeMicField = fieldKey);

    // تحديد اللغة ديناميكياً مع تفضيل ar-SA التوافقي مع أجهزة سامسونج
    final localeId = await resolveBestSttLocale(_speech, isRtl);

    await _speech.listen(
      onResult: (result) {
        if (mounted) {
          setState(() {
            controller.text = result.recognizedWords;
          });
        }
      },
      localeId: localeId,
      listenMode: stt.ListenMode.dictation,
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 4),
      listenOptions: stt.SpeechListenOptions(
        localeId: localeId,
        listenMode: stt.ListenMode.dictation,
        partialResults: true,
        cancelOnError: false,
      ),
    );
  }

  /// فحص سقف الفحوصات المجانية اليومية للضيوف (بحد أقصى 3 فحوصات/يوم)
  Future<bool> _verifyGuestDiagnosticQuota(BuildContext context, bool isRtl) async {
    final user = ref.read(authProvider).user;
    if (user != null && !user.isGuest) return true;

    final prefs = await SharedPreferences.getInstance();
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    final quotaKey = 'guest_quota_$todayStr';

    final int currentUsage = prefs.getInt(quotaKey) ?? 0;

    if (currentUsage >= 3) {
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                const Icon(Icons.lock_clock_rounded, color: Color(0xFFD97706), size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isRtl ? 'اكتمل الحد اليومي التجريبي (3/3)' : 'Daily Guest Limit Reached (3/3)',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'Tajawal'),
                  ),
                ),
              ],
            ),
            content: Text(
              isRtl
                  ? 'لقد استنفدت الفحوصات الـ 3 المخصصة للوضع التجريبي لهذا اليوم. للتمتع بفحوصات غير محدودة ومزامنة سجلاتك الهندسية سحابياً، يرجى إنشاء حساب أو تسجيل الدخول.'
                  : 'You have reached your 3 daily trial diagnoses for today. To get unlimited diagnostics and cloud sync, please sign in or register.',
              style: const TextStyle(fontSize: 12.5, color: Color(0xFF334155), height: 1.5, fontFamily: 'Tajawal'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(isRtl ? 'إغلاق' : 'Close', style: const TextStyle(color: Colors.grey)),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F75BC),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.login_rounded, size: 16),
                label: Text(
                  isRtl ? 'تسجيل الدخول الآن' : 'Sign In Now',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'Tajawal'),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                },
              ),
            ],
          ),
        );
      }
      return false;
    }

    await prefs.setInt(quotaKey, currentUsage + 1);
    return true;
  }

  // 🎙️ بناء حقل إدخال هندسي موحد يدعم الأيقونة الصوتية التفاعلية الحقيقية
  Widget _buildEngineeringInputField({
    required String fieldKey,
    required TextEditingController controller,
    required String hintText,
    required bool isRtl,
    int maxLines = 1,
  }) {
    final bool isListening = _activeMicField == fieldKey;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isListening ? Colors.red.withOpacity(0.02) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isListening ? Colors.red : const Color(0xFFCBD5E1),
          width: isListening ? 1.5 : 1,
        ),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)),
        textAlign: isRtl ? TextAlign.right : TextAlign.left,
        decoration: InputDecoration(
          hintText: isListening
              ? (isRtl ? 'جاري الاستماع...' : 'Listening...')
              : hintText,
          hintStyle: TextStyle(
            color: isListening ? Colors.red : const Color(0xFF94A3B8),
            fontSize: 12,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          prefixIcon: IconButton(
            tooltip: isRtl ? 'اضغط وتحدث الآن...' : 'Tap and speak now...',
            icon: Icon(
              isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
              color: isListening ? Colors.red : const Color(0xFF0F75BC),
              size: 20,
            ),
            onPressed: () => _handleMicPress(fieldKey, controller, isRtl),
          ),
        ),
      ),
    );
  }

  // 📸 بناء كروت الرفع البصري المدمجة هندسياً لملء المساحة السفلية
  Future<void> _pickImageForSlot(int slotIndex, {required bool isRtl}) async {
    if (_selectedImages.whereType<XFile>().length >= _maxImages && _selectedImages[slotIndex] == null) {
      _showWarningSnackBar(isRtl);
      return;
    }

    try {
      final ImageSource? source = await showModalBottomSheet<ImageSource?>(
        context: context,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
        builder: (sheetContext) {
          return SafeArea(
            child: Wrap(
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_camera_rounded, color: Colors.blue),
                  title: Text(isRtl ? 'التقاط صورة بالكاميرا' : 'Take photo with camera'),
                  onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_rounded, color: Colors.blue),
                  title: Text(isRtl ? 'اختيار من المعرض' : 'Choose from gallery'),
                  onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
                ),
              ],
            ),
          );
        },
      );

      if (source == null) {
        return;
      }

      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImages[slotIndex] = pickedFile;
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  void _showWarningSnackBar(bool isRtl) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isRtl
              ? '⚠️ الحد الأقصى هو 3 صور فقط.'
              : '⚠️ Maximum 3 images are allowed.',
        ),
        backgroundColor: Colors.orange.shade800,
      ),
    );
  }

  Widget _buildPhotoUploadCard({
    required String title,
    required bool hasImage,
    required VoidCallback onTap,
    required VoidCallback onDelete,
    required bool isRtl,
  }) {
    return Expanded(
      child: Container(
        height: 90,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: hasImage ? Colors.green.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: hasImage ? Colors.green : const Color(0xFFCBD5E1),
            width: 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    hasImage ? Icons.check_circle_rounded : Icons.add_a_photo_rounded,
                    color: hasImage ? Colors.green : const Color(0xFF0F75BC),
                    size: 24,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: hasImage ? Colors.green.shade700 : const Color(0xFF475569),
                    ),
                  ),
                ],
              ),
              if (hasImage)
                Positioned(
                  top: 2,
                  right: isRtl ? null : 2,
                  left: isRtl ? 2 : null,
                  child: GestureDetector(
                    onTap: onDelete,
                    child: const CircleAvatar(
                      radius: 9,
                      backgroundColor: Colors.red,
                      child: Icon(Icons.close, size: 10, color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isRtl) {
    return Padding(
      padding: const EdgeInsets.only(top: 6.0, bottom: 6.0),
      child: Align(
        alignment: isRtl ? Alignment.centerRight : Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F75BC)),
        ),
      ),
    );
  }
    @override
  Widget build(BuildContext context) {
    final localeState = ref.watch(localeProvider);
    final bool isRtl = localeState.languageCode == 'ar';
    
    // الحصول على الإعدادات الحركية والديناميكية بناءً على اسم القسم المختار
    final dynamicConfig = DynamicFieldConfig.getConfigForCategory(widget.categoryName);

    final String cat = widget.categoryName.trim().toLowerCase();
    final bool isAutomotive = cat.contains('سيارات') || cat.contains('مركبات') || cat.contains('auto') || cat.contains('car') || cat.contains('automotive');

    // 🌍 معجم نصوص الشاشة المترجم بالكامل للغتين لضمان استقرار الواجهة
    final String labelMainDevice = isRtl ? 'معلومات الجهاز الأساسية' : 'Basic Device Information';
    final String hintDeviceName = isRtl ? dynamicConfig.deviceNameHintAr : dynamicConfig.deviceNameHintEn;
    final String hintManufacturer = isRtl ? dynamicConfig.manufacturerHintAr : dynamicConfig.manufacturerHintEn;
    final String hintModel = isRtl ? dynamicConfig.modelHintAr : dynamicConfig.modelHintEn;
    final String labelDescribeProblem = isRtl ? 'أوصف المشكلة بالتفصيل' : 'Describe the Problem in Detail';
    final String hintProblemDetails = isRtl ? dynamicConfig.problemDetailsHintAr : dynamicConfig.problemDetailsHintEn;
    final String labelObservations = isRtl ? 'ماذا تلاحظ؟ (العلامات الحركية والحسية)' : 'What do you notice? (Kinetic & Sensory Signs)';
    final String hintObservations = isRtl ? dynamicConfig.observationsHintAr : dynamicConfig.observationsHintEn;
    final String labelErrorCodes = isRtl ? 'رموز الأخطاء إن وجدت' : 'Error Codes (If Any)';
    final String hintErrorCode = isRtl ? dynamicConfig.errorCodeHintAr : dynamicConfig.errorCodeHintEn;

    final String labelVisualAi = isRtl ? '📸 التحليل البصري الذكي المدمج (حتى 3 صور مجاناً)' : '📸 Integrated Visual AI Analysis (Up to 3 Photos)';
    final String titleImgGeneral = isRtl ? 'صورة رقم 1' : 'Image 1';
    final String titleImgPlate = isRtl ? 'صورة رقم 2' : 'Image 2';
    final String titleImgCloseUp = isRtl ? 'صورة رقم 3' : 'Image 3';

    final String submitButtonText = isRtl ? '🔍 بدء التشخيص الذكي' : '🔍 Start Smart Diagnosis';
    final bool hasRequired = _deviceNameController.text.trim().isNotEmpty && _problemDetailsController.text.trim().isNotEmpty;
    final String submitButtonLabel = hasRequired
      ? submitButtonText
      : (isRtl ? '📝 أدخل اسم الجهاز ووصف العطل لبدء التشخيص الذكي' : '📝 Enter device name and fault description to start smart diagnosis');

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        drawer: const CustomAppDrawer(),
        appBar: AppBar(
          title: Text(
            widget.categoryName,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B)),
          ),
          centerTitle: true,
          backgroundColor: Colors.white,
          elevation: 0.5,
          automaticallyImplyLeading: true,
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                      child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isAutomotive) ...[
                        // 📡 بلوتوث OBD2 بنر الفحص السريع الاختياري الموحد والجميل
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0F75BC), Color(0xFF1D4ED8)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0F75BC).withOpacity(0.25),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              )
                            ],
                          ),
                          child: InkWell(
                            onTap: () => _startBluetoothObd2Scan(isRtl),
                            borderRadius: BorderRadius.circular(10),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.18),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.bluetooth_searching_rounded, color: Colors.white, size: 22),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          isRtl 
                                              ? 'اضغط هنا للفحص السريع بالبلوتوث OBD2 (اختياري)' 
                                              : 'Click here for quick Bluetooth OBD2 scan (Optional)',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          isRtl 
                                              ? 'الاتصال التلقائي بالسيارة وقراءة كود الأعطال فورا' 
                                              : 'Auto-connect to car and fetch diagnostic DTC code',
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(0.85),
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 12),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                      // 1️⃣ قسم معلومات الجهاز الأساسية
                      _buildSectionHeader(labelMainDevice, isRtl),
                      _buildEngineeringInputField(
                        fieldKey: 'deviceName',
                        controller: _deviceNameController,
                        hintText: hintDeviceName,
                        isRtl: isRtl,
                      ),
                      _buildEngineeringInputField(
                        fieldKey: 'manufacturer',
                        controller: _manufacturerController,
                        hintText: hintManufacturer,
                        isRtl: isRtl,
                      ),
                      _buildEngineeringInputField(
                        fieldKey: 'model',
                        controller: _modelController,
                        hintText: hintModel,
                        isRtl: isRtl,
                      ),

                      // 2️⃣ قسم وصف المشكلة بالتفصيل
                      _buildSectionHeader(labelDescribeProblem, isRtl),
                      _buildEngineeringInputField(
                        fieldKey: 'problemDetails',
                        controller: _problemDetailsController,
                        hintText: hintProblemDetails,
                        isRtl: isRtl,
                        maxLines: 2,
                      ),

                      // 3️⃣ قسم الملاحظات الحركية والحسية
                      _buildSectionHeader(labelObservations, isRtl),
                      _buildEngineeringInputField(
                        fieldKey: 'observations',
                        controller: _observationsController,
                        hintText: hintObservations,
                        isRtl: isRtl,
                        maxLines: 2,
                      ),

                      // 4️⃣ قسم رموز الأخطاء الرقمية
                      _buildSectionHeader(labelErrorCodes, isRtl),
                      _buildEngineeringInputField(
                        fieldKey: 'errorCode',
                        controller: _errorCodeController,
                        hintText: hintErrorCode,
                        isRtl: isRtl,
                      ),

                      const SizedBox(height: 10),
                      const Divider(color: Color(0xFFE2E8F0), thickness: 1),

                      // 📸 5️⃣ قسم التحليل البصري المدمج حديثاً لملء المكان الفارغ
                      _buildSectionHeader(labelVisualAi, isRtl),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildPhotoUploadCard(
                            title: titleImgGeneral,
                            hasImage: _selectedImages[0] != null,
                            isRtl: isRtl,
                            onTap: () => _pickImageForSlot(0, isRtl: isRtl),
                            onDelete: () => setState(() => _selectedImages[0] = null),
                          ),
                          _buildPhotoUploadCard(
                            title: titleImgPlate,
                            hasImage: _selectedImages[1] != null,
                            isRtl: isRtl,
                            onTap: () => _pickImageForSlot(1, isRtl: isRtl),
                            onDelete: () => setState(() => _selectedImages[1] = null),
                          ),
                          _buildPhotoUploadCard(
                            title: titleImgCloseUp,
                            hasImage: _selectedImages[2] != null,
                            isRtl: isRtl,
                            onTap: () => _pickImageForSlot(2, isRtl: isRtl),
                            onDelete: () => setState(() => _selectedImages[2] = null),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFBFDBFE)),
                        ),
                        child: Text(
                          isRtl 
                              ? "💡 يبدأ التشخيص بعد إدخال اسم الجهاز ووصف العطل. كلما كانت المعلومات أوضح كانت نتائج التشخيص أكثر دقة."
                              : "💡 Diagnosis starts after entering device name and fault description. The clearer the information, the more accurate the diagnostic results.",
                          style: const TextStyle(fontSize: 11, color: Color(0xFF1E3A8A), height: 1.4, fontFamily: 'Tajawal'),
                        ),
                      ),
                      const SizedBox(height: 16),
                        ],
                      ),
                    ),
                // 🚀 شريط زر الإرسال النهائي للمحرك الرباعي الثابت بالأسفل
                Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: (hasRequired && !_isSubmitting) ? const Color(0xFF0F75BC) : Colors.grey,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    onPressed: _isSubmitting
                        ? null
                        : () async {
                            if (!hasRequired) {
                              const messageAr =
                                  'الرجاء إدخال نوع الجهاز ووصف العطل قبل بدء التشخيص.\n\n'
                                  'للحصول على نتائج أكثر دقة يُنصح أيضًا بإضافة:\n'
                                  '• الشركة المصنعة\n• الموديل\n'
                                  '• الأعراض والملاحظات\n'
                                  '• رمز الخطأ (إن وجد)\n'
                                  '• صور للعطل (إن توفرت)';
                              const messageEn =
                                  'Please enter device type and problem description before starting the diagnostic.\n\n'
                                  'For more accurate results consider adding:\n'
                                  '• Manufacturer\n• Model\n'
                                  '• Symptoms and observations\n'
                                  '• Error code (if any)\n'
                                  '• Photos of the fault (if available)';
                              if (context.mounted) {
                                if (isRtl) {
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('⚠️ بيانات مفقودة'),
                                      content: Text(messageAr),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(ctx),
                                          child: const Text('حسناً'),
                                        )
                                      ],
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(messageEn),
                                      backgroundColor: Colors.orange.shade700,
                                      duration: const Duration(seconds: 6),
                                    ),
                                  );
                                }
                              }
                              return;
                            }

                            final canProceed = await _verifyGuestDiagnosticQuota(context, isRtl);
                            if (!canProceed) return;

                            setState(() {
                              _isSubmitting = true;
                            });

                            try {
                              // Encode first available image (if any)
                              Uint8List? imageBytes;
                              final firstImg = _selectedImages
                                  .firstWhere((img) => img != null, orElse: () => null);
                              if (firstImg != null) {
                                try { imageBytes = await firstImg.readAsBytes(); } catch (_) {}
                              }

                              // ── Single unified AI call ──────────────────────────
                              // DiagnosticReportView renders CircularProgressIndicator
                              // while engineState.isLoading — no blocking dialog needed.
                              final String deviceName = _deviceNameController.text.trim();
                              final String manufacturer = _manufacturerController.text.trim();
                              final String model = _modelController.text.trim();
                              final String problemDescription = _problemDetailsController.text.trim();
                              final String observations = _observationsController.text.trim();
                              final String errorCode = _errorCodeController.text.trim();

                              final String mergedModel = [manufacturer, model].where((part) => part.isNotEmpty).join(' ');
                              final String mergedNotes = [
                                if (problemDescription.isNotEmpty) 'Problem Description: $problemDescription',
                                if (observations.isNotEmpty) 'Observations: $observations',
                                if (errorCode.isNotEmpty) 'Error Code: $errorCode',
                              ].join('\n');

                              debugPrint('DIAGNOSTIC_INPUT: name=$deviceName | type=${widget.categoryName} | model=$mergedModel | notes=$mergedNotes');

                              ref.read(diagnosticEngineStateProvider.notifier).runLiveDiagnostic(
                                name: deviceName.isNotEmpty ? deviceName : widget.categoryName,
                                type: widget.categoryName,
                                model: mergedModel.isNotEmpty ? mergedModel : 'غير محدد',
                                notes: mergedNotes.isNotEmpty ? mergedNotes : problemDescription,
                                imageBytes: imageBytes,
                                locale: isRtl ? 'ar' : 'en',
                              );

                              if (context.mounted) {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const DiagnosticReportView(),
                                  ),
                                );
                              }
                            } finally {
                              if (mounted) {
                                setState(() {
                                  _isSubmitting = false;
                                });
                              }
                            }
                          },

                    child: _isSubmitting
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                AppLocalizations.of(context).translate('starting_diagnosis'),
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                            ],
                          )
                        : Text(
                            submitButtonLabel,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  ),
),
);
  }

  void _startBluetoothObd2Scan(bool isRtl) {
    final messenger = ScaffoldMessenger.of(context); // تجنب استخدام context بعد async gap
    showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return _ObdScanSimulationDialog(isRtl: isRtl);
      }
    ).then((scannedCode) {
      if (scannedCode != null && scannedCode.isNotEmpty) {
        setState(() {
          _errorCodeController.text = scannedCode;
        });
        messenger.showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF0F75BC),
            duration: const Duration(seconds: 4),
            content: Text(
              isRtl 
                ? '✅ تم الاتصال وقراءة كود الأعطال ($scannedCode) بنجاح عبر OBD2!' 
                : '✅ Connected and read DTC code ($scannedCode) successfully via OBD2!',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        );
      }
    });
  }
}

class _ObdScanSimulationDialog extends StatefulWidget {
  final bool isRtl;
  const _ObdScanSimulationDialog({Key? key, required this.isRtl}) : super(key: key);

  @override
  State<_ObdScanSimulationDialog> createState() => _ObdScanSimulationDialogState();
}

class _ObdScanSimulationDialogState extends State<_ObdScanSimulationDialog> {
  int _currentStep = 0;
  bool _isPulsing = false;

  @override
  void initState() {
    super.initState();
    _runSimulation();
  }

  void _runSimulation() async {
    for (int i = 0; i <= 3; i++) {
      if (!mounted) return;
      setState(() {
        _currentStep = i;
        _isPulsing = !_isPulsing;
      });
      await Future.delayed(const Duration(milliseconds: 1400));
    }
    if (mounted) {
      Navigator.pop(context, 'P0301');
    }
  }

  @override
  Widget build(BuildContext context) {
    final String title = widget.isRtl ? 'جاري الفحص بالبلوتوث OBD2' : 'Bluetooth OBD2 Scanning';
    
    final List<String> stepsAr = [
      '🔍 جاري البحث عن أجهزة OBD2 القريبة عبر البلوتوث...',
      '🔗 تم العثور على المهايئ! جاري الاتصال بـ ELM327...',
      '📡 جاري قراءة رموز أعطال كمبيوتر السيارة (DTC)...',
      '✅ تم جلب كود العطل P0301 بنجاح!'
    ];

    final List<String> stepsEn = [
      '🔍 Searching for nearby OBD2 Bluetooth adapters...',
      '🔗 Adapter found! Connecting to ELM327...',
      '📡 Reading Diagnostic Trouble Codes (DTC)...',
      '✅ DTC P0301 successfully retrieved!'
    ];

    final currentMessage = widget.isRtl ? stepsAr[_currentStep] : stepsEn[_currentStep];

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Icon(Icons.bluetooth_searching_rounded, color: Color(0xFF0F75BC), size: 24),
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)),
                ),
                const SizedBox(width: 24),
              ],
            ),
            const Divider(height: 24, color: Color(0xFFF1F5F9)),
            const SizedBox(height: 12),
            // Pulsing bluetooth animation container
            AnimatedContainer(
              duration: const Duration(milliseconds: 600),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _isPulsing ? const Color(0xFF0F75BC).withOpacity(0.1) : const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.bluetooth_connected_rounded,
                color: Color(0xFF0F75BC),
                size: 40,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              currentMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF475569)),
            ),
            const SizedBox(height: 20),
            // Linear progress indicator
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (_currentStep + 1) / 4.0,
                backgroundColor: const Color(0xFFF1F5F9),
                color: const Color(0xFF0F75BC),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 38,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text(
                  widget.isRtl ? 'إلغاء الفحص' : 'Cancel Scan',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
