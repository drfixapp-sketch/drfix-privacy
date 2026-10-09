import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dio/dio.dart' hide RequestOptions;
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:dr_fix/presentation/screens/diagnostic_report_screen.dart';
import 'package:dr_fix/data/network/ai_config.dart';
import 'package:dr_fix/main.dart';

class VisualAiUploadScreen extends StatefulWidget {
  const VisualAiUploadScreen({Key? key}) : super(key: key);

  @override
  State<VisualAiUploadScreen> createState() => _VisualAiUploadScreenState();
}

class _VisualAiUploadScreenState extends State<VisualAiUploadScreen> {
  // قائمة لحفظ الصور الملتقطة (حد أقصى 3 صور ومجانية)
  final List<XFile> _selectedImages = []; 
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  // دالة التقاط أو اختيار الصور من الكاميرا أو الاستوديو
  Future<void> _pickImage(ImageSource source) async {
    if (_selectedImages.length >= 3) {
      _showWarningSnackBar();
      return;
    }

    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 512, // ضغط وتصغير مقاسات الصورة للمساهمة في تقليل حجم البيانات
        maxHeight: 512,
        imageQuality: 50, // ضغط جودة الصورة ميدانياً لتسريع الرفع
      );
      if (pickedFile != null) {
        setState(() {
          _selectedImages.add(pickedFile);
        });
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  // ضغط موفر لإنترنت وحجم التوكينات قبل التحويل لـ Base64
  Future<Uint8List> _compressImage(Uint8List imageBytes) async {
    try {
      final ui.Codec codec = await ui.instantiateImageCodec(
        imageBytes,
        targetWidth: 384, // تصغير أبعاد الصورة لخفض التوكينات لأقل قدر ممكن
      );
      final ui.FrameInfo frame = await codec.getNextFrame();
      final ByteData? byteData = await frame.image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData != null) {
        return byteData.buffer.asUint8List();
      }
    } catch (e) {
      debugPrint("Error in _compressImage: $e");
    }
    return imageBytes;
  }

  // إرسال الصور وتشخيص العطل بالتدفق الشلالي المجاني (Gemini Direct SDK -> OpenRouter Fallback)
  Future<void> _analyzeWithGemini() async {
    if (_selectedImages.isEmpty) {
      final isAr = Localizations.localeOf(context).languageCode == 'ar';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isAr ? '⚠️ الرجاء التقاط أو اختيار صورة واحدة على الأقل للبدء!' : '⚠️ Please select at least one image to begin!'),
          backgroundColor: Colors.red.shade800,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final geminiApiKey = AiConfig.geminiApiKey;
      final openRouterApiKey = AiConfig.openRouterApiKey;

      final systemPrompt = '''
You are an expert industrial maintenance AI diagnostic engine specialized in "The 9 Maintenance Systems":
1. HVAC (تدفئة، تهوية وتكييف الهواء)
2. Plumbing (السباكة)
3. Electrical (الأنظمة الكهربائية)
4. Mechanical (الأنظمة الميكانيكية)
5. Fire Safety (سلامة مكافحة الحرائق)
6. Elevators & Escalators (المصاعد والسلالم المتحركة)
7. Building Envelope/Structure (الهيكل الخارجي والإنشائي للمبنى)
8. Automation & Control (التحكم والأتمتة - BMS)
9. Waste & Water Treatment (معالجة المياه والصرف الصحي)

Analyze the provided image(s) to diagnose the issue. Return a strict JSON response in Arabic containing exactly the following keys (do not rename):
- "PrimaryDiagnosis": an object containing:
  - "faultName": short Arabic diagnosis title (Initial Diagnosis / التشخيص المبدئي)
  - "confidenceScore": integer 0-100
  - "mechanicalExplanation": detailed root cause analysis in Arabic (Root Causes / الأسباب الجذرية)
- "DifferentialCauses": list of objects, each containing:
  - "faultName": alternative cause in Arabic
  - "probability": integer 0-100
- "SafetyProtocols": object containing:
  - "oshaAlerts": list of safety rules / instructions in Arabic (Safety Instructions / إرشادات السلامة والأمان)
  - "riskAssessmentQuestions": list of risk check questions in Arabic
- "ActionableSteps": list of troubleshooting check steps in Arabic (Troubleshooting Steps / خطوات استكشاف الأخطاء وإصلاحها)
- "PotentialPartsToInspect": list of parts to check or tools needed in Arabic (Tools Needed / الأدوات المطلوبة)

Do not include any explanation markdown wrappers (like ```json ... ```). Return only the JSON object.
''';

      String? rawText;

      // 🥇 الأولوية الأولى (الأساسية): محرك Google Gemini SDK المباشر بنموذج "gemini-1.5-flash" المستقر
      if (geminiApiKey.isNotEmpty) {
        try {
          final geminiModel = dotenv.env['GEMINI_MODEL']?.trim().isNotEmpty == true
              ? dotenv.env['GEMINI_MODEL']!.trim()
              : 'gemini-1.5-flash';

          debugPrint('>>> Priority 1: Direct Gemini SDK ($geminiModel v1beta)');
          final model = GenerativeModel(
            model: geminiModel,
            apiKey: geminiApiKey,
            requestOptions: const RequestOptions(apiVersion: 'v1beta'),
          );

          final List<Part> parts = [TextPart(systemPrompt)];
          for (final image in _selectedImages) {
            final rawBytes = await image.readAsBytes();
            final compressedBytes = await _compressImage(rawBytes);
            parts.add(DataPart('image/jpeg', compressedBytes));
          }

          final content = Content.multi(parts);
          final response = await model.generateContent([content]).timeout(
            const Duration(seconds: 40),
          );

          if (response.text != null && response.text!.trim().isNotEmpty) {
            rawText = response.text;
            debugPrint('✅ Direct Gemini SDK succeeded with $geminiModel');
          }
        } catch (e) {
          debugPrint('⚠️ Direct Gemini SDK failed: $e. Cascading to OpenRouter fallback...');
        }
      }

      // 🥈 الأولوية الثانية (الاحتياطية التلقائية): OpenRouter بنموذج "qwen/qwen3.8-27b:free"
      if ((rawText == null || rawText.trim().isEmpty) && openRouterApiKey.isNotEmpty) {
        final fallbackModel = (dotenv.env['OPENROUTER_MODEL']?.trim().isNotEmpty == true)
            ? dotenv.env['OPENROUTER_MODEL']!.trim()
            : 'qwen/qwen3.8-27b:free';

        // 🛡️ Vision Guard: Qwen3-8b:free وأغلب النماذج المجانية لا تدعم image_url
        final bool visionCapable = fallbackModel.toLowerCase().contains('vision') ||
            fallbackModel.toLowerCase().contains('-vl') ||
            fallbackModel.toLowerCase().contains('llava');

        final dynamic finalContent;
        if (visionCapable) {
          // ✅ نموذج Vision: أرسل نص + صور كـ List
          final List<Map<String, dynamic>> contentList = [
            {'type': 'text', 'text': systemPrompt}
          ];
          for (final image in _selectedImages) {
            final rawBytes = await image.readAsBytes();
            final compressedBytes = await _compressImage(rawBytes);
            final b64Str = base64Encode(compressedBytes);
            contentList.add({
              'type': 'image_url',
              'image_url': {'url': 'data:image/jpeg;base64,$b64Str'},
            });
          }
          finalContent = contentList;
          debugPrint('🖼️ [VisualAI] Vision payload: ${contentList.length} parts.');
        } else {
          // ✅ نموذج نصي فقط: تضمين إشعار الصور في النص بدلاً من image_url
          final imageCount = _selectedImages.length;
          finalContent = '$systemPrompt\n\n[تنبيه: تم إرفاق $imageCount صور ميدانية للعطل. يرجى التحليل بناءً على الوصف أعلاه.]';
          debugPrint('⚠️ [VisualAI] Model "$fallbackModel" is text-only — images stripped, notice embedded.');
        }

        final dio = Dio();
        dio.options.connectTimeout = const Duration(seconds: 45);
        dio.options.receiveTimeout = const Duration(seconds: 45);

        try {
          debugPrint('>>> Priority 2 Fallback: OpenRouter Model: $fallbackModel');
          final requestBody = {
            'model': fallbackModel,
            'messages': [
              {'role': 'user', 'content': finalContent},
            ],
          };

          final response = await dio.post(
            'https://openrouter.ai/api/v1/chat/completions',
            options: Options(
              contentType: 'application/json; charset=utf-8', // ✅ charset صريح
              headers: {
                'Authorization': 'Bearer $openRouterApiKey',
                'HTTP-Referer': 'https://drfix.app', // ✅ مطلوب من OpenRouter
                'X-Title': 'Dr Fix',
              },
            ),
            data: requestBody,
          );

          if (response.statusCode == 200 && response.data != null) {
            rawText = response.data['choices']?[0]?['message']?['content'] as String?;
            if (rawText != null && rawText.isNotEmpty) {
              debugPrint('✅ OpenRouter fallback succeeded with $fallbackModel');
            }
          }
        } catch (e) {
          debugPrint('❌ OpenRouter fallback failed: $e');
        }
      }

      if (rawText == null || rawText.trim().isEmpty) {
        throw Exception('فشل الحصول على تشخيص الرؤية من كلاً من محرك Gemini المباشر و OpenRouter الاحتياطي.');
      }

      debugPrint('Diagnostic raw response: $rawText');
      final report = DiagnosticReportModel.fromJson(rawText);

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DiagnosticReportView(initialReport: report),
        ),
      );
    } catch (e) {
      debugPrint('Diagnostic error: $e');
      if (mounted) {
        final isAr = Localizations.localeOf(context).languageCode == 'ar';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isAr ? '⚠️ فشل الاتصال بمحركات التشخيص الذكي البصري: $e' : '⚠️ Failed to connect to visual AI diagnostic engines: $e'),
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // تنبيه الفني عند الوصول للحد الأقصى للصور
  void _showWarningSnackBar() {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isAr ? '⚠️ الحد الأقصى هو 3 صور فقط لتحليل أدق ومجاني!' : 'Maximum 3 images allowed for free analysis!'),
        backgroundColor: Colors.orange.shade800,
      ),
    );
  }

  void _showPickerOptions(BuildContext context, bool isAr) {
    if (_selectedImages.length >= 3) {
      _showWarningSnackBar();
      return;
    }
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera_rounded, color: Colors.blue),
                title: Text(isAr ? 'التقاط صورة حية بالكاميرا' : 'Take Photo with Camera'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded, color: Colors.blue),
                title: Text(isAr ? 'اختيار من معرض الصور' : 'Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(isAr ? 'التحليل البصري الذكي' : 'Visual AI Analysis', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // 📦 الإطار الرئيسي لالتقاط الصور والتعليمات التوجيهية
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue.shade200, width: 2),
                ),
                child: InkWell(
                  onTap: () => _showPickerOptions(context, isAr),
                  child: Column(
                    children: [
                      const Icon(Icons.camera_enhance_rounded, size: 50, color: Colors.blue),
                      const SizedBox(height: 12),
                      Text(
                        isAr ? 'اضغط لإرفاق صور العطل (حتى 3 صور مجاناً)' : 'Tap to add fault photos (Up to 3 free)',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isAr 
                            ? 'التقط: صورة عامة، صورة للوحة البيانات، وصورة مقربة للعطل.' 
                            : 'Take: overall view, brand label, and defect zoom.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12, color: Colors.grey, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 🖼️ شريط عرض الصور الملتقطة أفقياً مع إمكانية الحذف الفردي
              Expanded(
                child: _selectedImages.isEmpty
                    ? Center(
                        child: Text(
                          isAr ? 'الرجاء التقاط صور للعطل لبدء التحليل البصري 📷' : 'Please take fault photos to begin visual analysis 📷',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      )
                    : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _selectedImages.length,
                        itemBuilder: (context, index) {
                          final file = _selectedImages[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10),
                            child: Stack(
                              children: [
                                Container(
                                  width: 160,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black12, 
                                        blurRadius: 4, 
                                        offset: Offset(0, 2)
                                      )
                                    ],
                                    border: Border.all(color: Colors.grey.shade300),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(11),
                                    child: kIsWeb
                                        ? Image.network(file.path, fit: BoxFit.cover)
                                        : Image.file(File(file.path), fit: BoxFit.cover),
                                  ),
                                ),
                                Positioned(
                                  top: 6,
                                  right: 6,
                                  child: CircleAvatar(
                                    radius: 14,
                                    backgroundColor: Colors.red.withOpacity(0.9),
                                    child: IconButton(
                                      padding: EdgeInsets.zero,
                                      icon: const Icon(Icons.close_rounded, size: 16, color: Colors.white),
                                      onPressed: () => setState(() => _selectedImages.removeAt(index)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 20),
              
              // 🚀 زر الإرسال للمحرك وتشخيص العطل مع مؤشر تحميل
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: _isLoading 
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.bolt_rounded, color: Colors.white),
                  label: Text(
                    _isLoading
                        ? AppLocalizations.of(context).translate('loading_images')
                        : (isAr ? 'بدء تشخيص العطل بالذكاء الاصطناعي 🚀' : 'Start AI Fault Diagnosis 🚀'),
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  onPressed: _isLoading ? null : _analyzeWithGemini,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
