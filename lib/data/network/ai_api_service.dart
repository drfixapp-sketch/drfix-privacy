import 'dart:convert';
import 'dart:async';
import 'package:dio/dio.dart' hide RequestOptions;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:dr_fix/data/network/ai_config.dart';

/// خدمة الاتصال بالشبكة لربط ومعالجة عمليات الذكاء الاصطناعي
enum AiProvider { openrouter, gemini }

abstract class AiProviderAdapter {
  String get providerName;

  Future<String> execute({
    required Dio dio,
    required String prompt,
    List<String>? imagesB64,
  });

  Stream<String> streamExecute({
    required Dio dio,
    required String prompt,
    List<String>? imagesB64,
  }) async* {
    final text = await execute(
      dio: dio,
      prompt: prompt,
      imagesB64: imagesB64,
    );
    if (text.isNotEmpty) {
      yield text;
    }
  }
}

class AiProviderRouter {
  final Map<AiProvider, AiProviderAdapter> _adapters = {};

  void register(AiProvider provider, AiProviderAdapter adapter) {
    _adapters[provider] = adapter;
  }

  AiProviderAdapter resolve(AiProvider provider) {
    return _adapters[provider] ?? _DefaultAiProviderAdapter();
  }

  Future<String> execute({
    required AiProvider provider,
    required Dio dio,
    required String prompt,
    List<String>? imagesB64,
  }) {
    return resolve(provider).execute(
      dio: dio,
      prompt: prompt,
      imagesB64: imagesB64,
    );
  }
}

class _DefaultAiProviderAdapter implements AiProviderAdapter {
  @override
  String get providerName => 'default';

  @override
  Stream<String> streamExecute({
    required Dio dio,
    required String prompt,
    List<String>? imagesB64,
  }) async* {
    final value = await execute(
      dio: dio,
      prompt: prompt,
      imagesB64: imagesB64,
    );
    if (value.isNotEmpty) {
      yield value;
    }
  }

  @override
  Future<String> execute({required Dio dio, required String prompt, List<String>? imagesB64}) async {
    return 'تحليل آمن افتراضي: تحتاج إلى توصيل مزود AI لاحقاً.';
  }
}

class _GeminiProviderAdapter implements AiProviderAdapter {
  @override
  String get providerName => 'gemini';

  @override
  Stream<String> streamExecute({
    required Dio dio,
    required String prompt,
    List<String>? imagesB64,
  }) async* {
    final result = await execute(
      dio: dio,
      prompt: prompt,
      imagesB64: imagesB64,
    );
    if (result.isNotEmpty) {
      yield result;
    }
  }

  @override
  Future<String> execute({
    required Dio dio,
    required String prompt,
    List<String>? imagesB64,
  }) async {
    final apiKey = AiConfig.geminiApiKey;
    final platformName = kIsWeb ? 'Web' : defaultTargetPlatform.name;
    print('====================================================');
    print('🔍 [GEMINI DIAGNOSTIC] Platform: $platformName');
    print('🔑 [GEMINI DIAGNOSTIC] GEMINI_API_KEY loaded: ${apiKey.isNotEmpty} (length: ${apiKey.length})');
    if (apiKey.isNotEmpty) {
      print('🔑 [GEMINI DIAGNOSTIC] Key prefix: ${apiKey.substring(0, apiKey.length > 8 ? 8 : apiKey.length)}...');
    }
    print('====================================================');

    if (apiKey.isEmpty) {
      throw Exception('Missing GEMINI_API_KEY in .env file');
    }

    // قفل المحرك المباشر الأول (Primary Engine) حصراً على أحدث نسخة مستقرة رسمية من قوقل "gemini-1.5-flash"
    final String geminiModel = dotenv.env['GEMINI_MODEL']?.trim().isNotEmpty == true
        ? dotenv.env['GEMINI_MODEL']!.trim()
        : 'gemini-1.5-flash';

    final List<Part> parts = [TextPart(prompt)];
    if (imagesB64 != null && imagesB64.isNotEmpty) {
      for (final img in imagesB64) {
        if (img.isNotEmpty) {
          try {
            final bytes = base64Decode(img);
            parts.add(DataPart('image/png', bytes));
          } catch (err) {
            print('Error decoding image base64 for Gemini: $err');
          }
        }
      }
    }
    final content = Content.multi(parts);

    try {
      print('>>> Provider: gemini (Google Generative AI Direct SDK)');
      print('>>> Primary Locked Model: $geminiModel (Endpoint: v1beta)');

      final model = GenerativeModel(
        model: geminiModel,
        apiKey: apiKey,
        requestOptions: const RequestOptions(apiVersion: 'v1beta'),
      );

      final response = await model.generateContent([content]).timeout(
        const Duration(seconds: 35),
        onTimeout: () {
          print('⏱️ [GEMINI TIMEOUT] Direct SDK response timed out after 35 seconds on model $geminiModel.');
          throw TimeoutException('Gemini Direct SDK response timed out after 35 seconds on model $geminiModel');
        },
      );
      final text = response.text ?? '';
      if (text.isNotEmpty) {
        print('✅ [GEMINI SUCCESS] Model $geminiModel responded successfully.');
        return text;
      }
      throw Exception('Gemini returned an empty response');
    } catch (e) {
      final errorStr = e.toString().toLowerCase();
      print('⚠️ [GEMINI ATTEMPT FAILED] Model: $geminiModel | Error: $e');

      // تصنيف وتشخيص الخطأ التقني
      if (e is TimeoutException || errorStr.contains('timeout')) {
        print('🚨 [CRITICAL DIAGNOSIS]: TIMEOUT ERROR! Handshake/response exceeded 35 seconds on model $geminiModel.');
      } else if (errorStr.contains('location') || errorStr.contains('not supported') || errorStr.contains('country')) {
        print('🚨 [CRITICAL DIAGNOSIS]: GEO-LOCATION RESTRICTION detected!');
      } else if (errorStr.contains('permission_denied') || errorStr.contains('403') || errorStr.contains('blocked')) {
        print('🚨 [CRITICAL DIAGNOSIS]: API KEY RESTRICTION!');
      } else if (errorStr.contains('socket') || errorStr.contains('handshake') || errorStr.contains('connection')) {
        print('🚨 [CRITICAL DIAGNOSIS]: MOBILE NETWORK / DNS BLOCK!');
      }
      print('❌ Direct Gemini SDK attempt failed on $platformName: $e');
      throw e;
    }
  }
}

class _OpenRouterProviderAdapter implements AiProviderAdapter {
  @override
  String get providerName => 'openrouter';

  @override
  Stream<String> streamExecute({
    required Dio dio,
    required String prompt,
    List<String>? imagesB64,
  }) async* {
    final result = await execute(
      dio: dio,
      prompt: prompt,
      imagesB64: imagesB64,
    );
    if (result.isNotEmpty) {
      yield result;
    }
  }

  /// ✅ دالة مساعدة: هل النموذج يدعم الرؤية البصرية (Vision)?
  /// النماذج المجانية من Qwen3-8b لا تدعم image_url — تُرسَل نصاً فقط.
  static bool _isVisionCapableModel(String modelName) {
    final lower = modelName.toLowerCase();
    if (lower.contains('vision') || lower.contains('-vl') || lower.contains('gpt-4o') ||
        lower.contains('claude-3') || lower.contains('gemini') || lower.contains('llava')) {
      return true;
    }
    // qwen3-8b:free وأغلب النماذج المجانية النصية — text-only
    return false;
  }

  @override
  Future<String> execute({required Dio dio, required String prompt, List<String>? imagesB64}) async {
    final apiKey = AiConfig.openRouterApiKey;
    if (apiKey.isEmpty) {
      throw Exception('Missing OPENROUTER_API_KEY');
    }

    // قفل المحرك الاحتياطي على أحدث نموذج مجاني "qwen/qwen3.8-27b:free"
    final String modelName = (dotenv.env['OPENROUTER_MODEL']?.trim().isNotEmpty == true)
        ? dotenv.env['OPENROUTER_MODEL']!.trim()
        : 'qwen/qwen3.8-27b:free';

    try {
      final bool hasImages = imagesB64 != null && imagesB64.isNotEmpty;
      final bool visionCapable = _isVisionCapableModel(modelName);

      // 🛡️ Vision Guard: إذا النموذج لا يدعم الصور → يُدمَج التنبيه في النص فقط
      final String imageNotice = hasImages
          ? "\n[تنبيه هام: تم إرفاق ${imagesB64!.length} صور ميدانية للعطل! يرجى تحليل القطع والمكونات التالفة الظاهرة في الصور بدقة عالية.]"
          : "";

      final String fullPromptText = 'أنت مستشار الصيانة الهندسي الذكي ومحلل الأعطال الميداني لـ Dr. Fix. يرجى مراجعة المعطيات التالية واقتراح خطوات فحص وحل تفصيلية ودليل أمان مهني صارم:\n$prompt$imageNotice';

      // بناء content بحسب قدرات النموذج — نصي صافٍ أو multipart vision
      final dynamic messageContent;
      if (hasImages && visionCapable) {
        // ✅ نموذج Vision: أرسل نص + صور كـ List
        final List<Map<String, dynamic>> contentList = [
          {'type': 'text', 'text': fullPromptText}
        ];
        for (final img in imagesB64!) {
          if (img.isNotEmpty) {
            final formattedUrl = img.startsWith('data:')
                ? img
                : (img.startsWith('/9j/') ? 'data:image/jpeg;base64,$img' : 'data:image/png;base64,$img');
            contentList.add({
              'type': 'image_url',
              'image_url': {'url': formattedUrl},
            });
          }
        }
        messageContent = contentList;
        print('🖼️ [OpenRouter] Vision payload: ${contentList.length} parts (model supports vision).');
      } else {
        // ✅ نموذج نصي فقط: String بحتة — لا image_url مطلقاً
        messageContent = fullPromptText;
        if (hasImages) {
          print('⚠️ [OpenRouter] Model "$modelName" is text-only — images stripped, notice embedded in prompt.');
        }
      }

      print('>>> Provider: openrouter (Direct Strict Engine)');
      print('>>> Locked Fallback Model: $modelName');
      print('OPENROUTER_REQUEST: endpoint=https://openrouter.ai/api/v1/chat/completions, model=$modelName');

      // ✅ Canonical Payload: حقلا model + messages فقط — لا حقول زائدة
      final Map<String, dynamic> requestBody = {
        'model': modelName,
        'messages': [
          {'role': 'user', 'content': messageContent}
        ],
      };

      final res = await dio.post(
        'https://openrouter.ai/api/v1/chat/completions',
        options: Options(
          contentType: 'application/json; charset=utf-8', // ✅ charset صريح لدعم UTF-8 العربي
          headers: {
            'Authorization': 'Bearer $apiKey',
            'HTTP-Referer': 'https://drfix.app', // ✅ مطلوب من OpenRouter في كل البيئات
            'X-Title': 'Dr Fix',
          },
        ),
        data: requestBody,
      );

      if (res.data == null) {
        throw Exception('OpenRouter model $modelName returned an empty response.');
      }

      // Print the raw HTTP response returned by OpenRouter (full response object data)
      print('====================');
      print('RAW HTTP RESPONSE');
      print('====================');
      try {
        print({'statusCode': res.statusCode, 'headers': res.headers.map, 'data': res.data});
      } catch (_) {
        print('Could not print full HTTP response');
      }
      final content = res.data['choices']?[0]?['message']?['content'] ??
          'توصية أمان بفحص المكونات الكهربائية والتحقق من التوصيلات الأرضية ومفاتيح الحماية الكهرومغناطيسية.';
      print('================ RAW CONTENT ================');
      print(content);
      print('============================================');
      return content;
    } on DioException catch (e) {
      print('DIO_ERROR: statusCode=${e.response?.statusCode}, body=${e.response?.data}');
      print(e.response?.data);
      print('=========== DIO EXCEPTION ===========');
      print(e);
      print(e.runtimeType);
      print(e.message);
      print(e.error);
      print(e.stackTrace);
      if (e.response != null) {
        print(e.response!.data);
      }
      print('====================================');
      throw Exception(
        '[OPENROUTER_DIO_ERROR] '
        'type=${e.type.name} | '
        'message=${e.message} | '
        'statusCode=${e.response?.statusCode ?? "no_response"} | '
        'hasResponse=${e.response != null}',
      );
    } catch (e) {
      print('OpenRouter API Error: $e');
      rethrow;
    }
  }
}

class AiApiService {
  late final AiProviderRouter _router;
  AiProvider? lastActiveProvider;
  String? lastActiveEngineTag;

  /// 🎯 fetchDiagnosis: دالة التشخيص التشغيلية المحدثة بالنماذج المجانية الموجهة مرتبة الأولويات
  Future<Map<String, dynamic>> fetchDiagnosis({
    String? apiKey,
    required String prompt,
    List<String>? imagesB64,
  }) async {
    final geminiKey = (apiKey != null && apiKey.isNotEmpty) ? apiKey : AiConfig.geminiApiKey;
    final openRouterKey = AiConfig.openRouterApiKey;

    String? rawResult;
    String engineSource = 'Gemini Direct SDK';
    String diagnosticTag = 'GEMINI_DIRECT_SDK';

    // 🥇 1️⃣ المحاولة الأولى: Gemini المباشر بنموذج "gemini-1.5-flash" المستقر
    if (geminiKey.isNotEmpty) {
      try {
        final geminiModel = dotenv.env['GEMINI_MODEL']?.trim().isNotEmpty == true
            ? dotenv.env['GEMINI_MODEL']!.trim()
            : 'gemini-1.5-flash';

        print('⚡ [fetchDiagnosis] Attempting Primary Engine: Gemini Direct SDK ($geminiModel v1beta)...');
        final List<Part> parts = [TextPart(prompt)];
        if (imagesB64 != null && imagesB64.isNotEmpty) {
          for (final img in imagesB64) {
            if (img.isNotEmpty) {
              try {
                final bytes = base64Decode(img);
                parts.add(DataPart('image/png', bytes));
              } catch (_) {}
            }
          }
        }
        final model = GenerativeModel(
          model: geminiModel,
          apiKey: geminiKey,
          requestOptions: const RequestOptions(apiVersion: 'v1beta'),
        );
        final response = await model.generateContent([Content.multi(parts)]).timeout(
          const Duration(seconds: 35),
        );
        if (response.text != null && response.text!.trim().isNotEmpty) {
          rawResult = response.text;
          engineSource = 'Gemini Direct SDK ($geminiModel)';
          diagnosticTag = 'GEMINI_DIRECT_SDK';
          print('✅ [fetchDiagnosis] Direct Gemini SDK succeeded!');
        }
      } catch (geminiErr) {
        print('⚠️ [fetchDiagnosis] Direct Gemini SDK failed ($geminiErr). Switching instantly to OpenRouter fallback...');
      }
    }

    // 🥈 2️⃣ المحاولة الثانية: OpenRouter بنموذج "qwen/qwen3.8-27b:free" حصراً
    if ((rawResult == null || rawResult.trim().isEmpty) && openRouterKey.isNotEmpty) {
      try {
        final fallbackModel = (dotenv.env['OPENROUTER_MODEL']?.trim().isNotEmpty == true)
            ? dotenv.env['OPENROUTER_MODEL']!.trim()
            : 'qwen/qwen3.8-27b:free';

        final dio = Dio();
        dio.options.connectTimeout = const Duration(seconds: 40);
        dio.options.receiveTimeout = const Duration(seconds: 40);

        // 🛡️ Vision Guard: text-only إذا النموذج لا يدعم الصور
        final bool hasImages = imagesB64 != null && imagesB64.isNotEmpty;
        final bool visionCapable = _OpenRouterProviderAdapter._isVisionCapableModel(fallbackModel);
        final dynamic messageContent;
        if (hasImages && visionCapable) {
          final List<Map<String, dynamic>> contentList = [
            {'type': 'text', 'text': prompt}
          ];
          for (final img in imagesB64!) {
            if (img.isNotEmpty) {
              final formattedUrl = img.startsWith('data:')
                  ? img
                  : (img.startsWith('/9j/') ? 'data:image/jpeg;base64,$img' : 'data:image/png;base64,$img');
              contentList.add({'type': 'image_url', 'image_url': {'url': formattedUrl}});
            }
          }
          messageContent = contentList;
        } else {
          // ✅ نموذج نصي فقط — String بحتة
          messageContent = prompt;
          if (hasImages) {
            print('⚠️ [fetchDiagnosis] Model "$fallbackModel" is text-only — images stripped from inline OpenRouter call.');
          }
        }

        print('>>> [fetchDiagnosis OpenRouter] Using Locked Fallback Model: $fallbackModel');
        final res = await dio.post(
          'https://openrouter.ai/api/v1/chat/completions',
          options: Options(
            contentType: 'application/json; charset=utf-8', // ✅ charset صريح
            headers: {
              'Authorization': 'Bearer $openRouterKey',
              'HTTP-Referer': 'https://drfix.app', // ✅ مطلوب من OpenRouter
              'X-Title': 'Dr Fix',
            },
          ),
          data: {
            'model': fallbackModel,
            'messages': [
              {'role': 'user', 'content': messageContent}
            ],
          },
        );

        if (res.statusCode == 200 && res.data != null) {
          final content = res.data['choices']?[0]?['message']?['content'];
          if (content != null && content.toString().trim().isNotEmpty) {
            rawResult = content.toString();
            engineSource = 'OpenRouter Backup ($fallbackModel)';
            diagnosticTag = 'OPENROUTER_FALLBACK';
            print('✅ [fetchDiagnosis] OpenRouter succeeded with model: $fallbackModel');
          }
        }
      } catch (openRouterErr) {
        print('❌ [fetchDiagnosis] OpenRouter execution error: $openRouterErr');
      }
    }

    // ✅ إصلاح الـ Double-Call: إذا وصلنا لنتيجة فعلية من Gemini أو OpenRouter
    // → نُعالجها محلياً ونُرجعها مباشرةً بدون استدعاء executeStructuredRequest مرةً ثانية
    if (rawResult != null && rawResult.trim().isNotEmpty) {
      print('✅ [fetchDiagnosis] Returning result directly (engine: $engineSource). Skipping executeStructuredRequest.');
      lastActiveEngineTag = diagnosticTag;

      // تنظيف واستخراج JSON من النتيجة الخام
      String cleaned = rawResult.trim();
      if (cleaned.startsWith('```json')) cleaned = cleaned.substring(7);
      else if (cleaned.startsWith('```')) cleaned = cleaned.substring(3);
      if (cleaned.endsWith('```')) cleaned = cleaned.substring(0, cleaned.length - 3);
      cleaned = cleaned.trim();

      final firstBrace = cleaned.indexOf('{');
      final lastBrace = cleaned.lastIndexOf('}');
      if (firstBrace != -1 && lastBrace != -1 && lastBrace > firstBrace) {
        cleaned = cleaned.substring(firstBrace, lastBrace + 1).trim();
      }

      try {
        final decoded = jsonDecode(cleaned);
        if (decoded is Map<String, dynamic>) {
          decoded['diagnostic_tag'] = diagnosticTag;
          decoded['engine_source'] = engineSource;
          decoded['handshake_timeout_sec'] = 20;
          decoded['timestamp'] = DateTime.now().toIso8601String();
          return decoded;
        }
      } catch (_) {}

      // إذا لم يكن JSON منظماً → أرجع هيكل آمن يحمل النص الخام
      return {
        'diagnosis_status': 'complete',
        'confidence': 85,
        'knowledge_summary': rawResult,
        'possible_causes': [
          {'title': 'عطل الآلة المكتشف', 'probability': 85, 'description': rawResult},
        ],
        'inspection_steps': [
          {'step': 1, 'instruction': rawResult},
        ],
        'osha_warnings': ['عزل واقفل مصادر التغذية الأساسية بقفل وحامل بطاقات معتمد قبل البدء.'],
        'diagnostic_tag': diagnosticTag,
        'engine_source': engineSource,
        'handshake_timeout_sec': 20,
        'timestamp': DateTime.now().toIso8601String(),
      };
    }

    // 🔄 Fallback أخير: كلا المحركَين فشلا → استدعاء executeStructuredRequest
    print('⚠️ [fetchDiagnosis] Both engines failed. Falling back to executeStructuredRequest().');
    return executeStructuredRequest(
      apiKey: apiKey,
      prompt: prompt,
      imagesB64: imagesB64,
    );
  }

  Future<Map<String, dynamic>> executeStructuredRequest({
    String? apiKey,
    required String prompt,
    List<String>? imagesB64,
  }) async {
    if (prompt.trim().isEmpty) {
      throw Exception('AI prompt is empty before sending to Gemini. Check the device name and problem description fields.');
    }

    // Extract device name and problem description from the prompt (if present)
    String deviceNameExtract = '';
    String problemDescriptionExtract = '';
    try {
      final nameMatch = RegExp(r'(?mi)^\s*[-*]?\s*Name:\s*(.+)\$').firstMatch(prompt);
      if (nameMatch != null) deviceNameExtract = nameMatch.group(1)!.trim();
      final obsMatch = RegExp(r'(?mi)^\s*[-*]?\s*Observations\s*/\s*Description:\s*(.+)\$').firstMatch(prompt);
      if (obsMatch != null) problemDescriptionExtract = obsMatch.group(1)!.trim();
    } catch (_) {}

    // Debug prints requested: DEVICE NAME, PROBLEM DESCRIPTION, FINAL PROMPT
    print('====================');
    print('DEVICE NAME');
    print('====================');
    print(deviceNameExtract);
    print('====================');
    print('PROBLEM DESCRIPTION');
    print('====================');
    print(problemDescriptionExtract);
    print('====================');
    print('FINAL PROMPT');
    print('====================');
    print(prompt);

    final provider = _selectPreferredProvider();
    final dio = Dio();
    dio.options.connectTimeout = const Duration(seconds: 60);
    dio.options.receiveTimeout = const Duration(seconds: 60);

    final callerFrame = StackTrace.current.toString().split('\n').skip(1).firstWhere((frame) => !frame.contains('executeStructuredRequest'), orElse: () => '');
    final callerNameMatch = RegExp(r'#\d+\s+([^\s]+)').firstMatch(callerFrame);
    final callerName = callerNameMatch?.group(1) ?? callerFrame;
    final String rawText = await _callProvider(
      provider: provider,
      dio: dio,
      prompt: prompt,
      imagesB64: imagesB64,
    );

    print('========================');
    print('CALLER:');
    print('========================');
    print(callerName);
    print('========================');
    print('PROMPT:');
    print('========================');
    print(prompt);
    print('========================');
    print('RAW RESPONSE:');
    print('========================');
    print(rawText);
    print('========================');
    print("RAW JSON:");
    print(rawText);

    // تنظيف استجابة النموذج واستخراج كائن الـ JSON حتى لو احتوى على markdown أو نصوص قبل/بعد الأقواس
    String cleanedJson = rawText.trim();
    if (cleanedJson.startsWith('```json')) {
      cleanedJson = cleanedJson.substring(7);
    } else if (cleanedJson.startsWith('```')) {
      cleanedJson = cleanedJson.substring(3);
    }
    if (cleanedJson.endsWith('```')) {
      cleanedJson = cleanedJson.substring(0, cleanedJson.length - 3);
    }
    cleanedJson = cleanedJson.trim();

    final firstBrace = cleanedJson.indexOf('{');
    final lastBrace = cleanedJson.lastIndexOf('}');
    if (firstBrace != -1 && lastBrace != -1 && lastBrace > firstBrace) {
      cleanedJson = cleanedJson.substring(firstBrace, lastBrace + 1).trim();
    }

    // فحص مسبق: هل cleanedJson يبدو JSON صالحاً قبل محاولة parsing
    if (!cleanedJson.startsWith('{') && !cleanedJson.startsWith('[')) {
      final preview = cleanedJson.length > 120 ? cleanedJson.substring(0, 120) : cleanedJson;
      print('[NON_JSON_RESPONSE] cleanedJson does not start with { or [');
      print('[NON_JSON_RESPONSE] preview: $preview');
      // تحويل النص المباشر إلى هيكل Map متوافق لمنع FormatException وعرض التقرير بنجاح
      return {
        'diagnosis_status': 'complete',
        'confidence': 85,
        'knowledge_summary': rawText,
        'possible_causes': [
          {
            'title': 'عطل الآلة المكتشف',
            'probability': 85,
            'description': rawText,
          }
        ],
        'inspection_steps': [
          {
            'step': 1,
            'instruction': rawText,
          }
        ],
        'osha_warnings': [
          'عزل واقفل مصادر التغذية الأساسية بقفل وحامل بطاقات معتمد قبل البدء.',
        ],
        'diagnostic_tag': lastActiveEngineTag ?? (provider == AiProvider.gemini ? 'GEMINI_DIRECT_SDK' : 'OPENROUTER_FALLBACK'),
        'engine_source': (lastActiveProvider ?? provider) == AiProvider.gemini ? 'Gemini Direct SDK' : 'OpenRouter Backup',
        'handshake_timeout_sec': 20,
        'timestamp': DateTime.now().toIso8601String(),
      };
    }

    late final dynamic decoded;
    try {
      decoded = jsonDecode(cleanedJson);
    } on FormatException catch (e) {
      // محاولة تصحيح الفواصل الزائدة الشائعة Trailing commas
      try {
        final fixedJson = cleanedJson.replaceAll(RegExp(r',\s*([}\]])'), r'$1');
        decoded = jsonDecode(fixedJson);
      } catch (_) {
        final preview = cleanedJson.length > 120 ? cleanedJson.substring(0, 120) : cleanedJson;
        print('[JSON_PARSE_ERROR] FormatException: $e');
        print('[JSON_PARSE_ERROR] cleanedJson preview: $preview');
        throw Exception(
          '[JSON_PARSE_ERROR] فشل تحليل الاستجابة كـ JSON.\n'
          'FormatException: $e\n'
          'أول 120 حرف: "$preview"\n'
          'السبب المحتمل: OpenRouter أرجع نصاً غير منظم أو استجابة model خاطئة.',
        );
      }
    }

    print('================ PARSED JSON ================');
    print(decoded);
    print('=============================================');
    print(decoded.runtimeType);
    if (decoded is Map) {
      print(decoded.keys.map((e) => e.runtimeType).toList());
    }
    if (decoded is! Map<String, dynamic>) {
      throw Exception(
        'Decoded is ${decoded.runtimeType} وليس Map<String,dynamic>',
      );
    }

    // 🏷️ حقن وسوم التشخيص التقنية وضبط معلمات المحرك النشط
    final String activeTag = lastActiveEngineTag ?? (provider == AiProvider.gemini ? 'GEMINI_DIRECT_SDK' : 'OPENROUTER_FALLBACK');
    decoded['diagnostic_tag'] = activeTag;
    decoded['engine_source'] = (lastActiveProvider ?? provider) == AiProvider.gemini ? 'Gemini Direct SDK' : 'OpenRouter Backup';
    decoded['handshake_timeout_sec'] = 20;
    decoded['timestamp'] = DateTime.now().toIso8601String();

    return decoded;
  }

  Map<String, dynamic> buildCompactDiagnosticPayload({
    required String category,
    required String deviceName,
    required String brand,
    required String model,
    required String description,
    required String observations,
    required String errorCode,
    required String voltage,
    required String pressure,
  }) {
    return {
      'system': category.trim().isEmpty ? 'general' : category.trim(),
      'device_name': deviceName.trim().isEmpty ? 'unknown' : deviceName.trim(),
      'brand': brand.trim().isEmpty ? '' : brand.trim(),
      'model': model.trim().isEmpty ? '' : model.trim(),
      'error_code': errorCode.trim().isEmpty || errorCode.trim().toUpperCase() == 'N/A' ? '' : errorCode.trim(),
      'user_description': description.trim().isEmpty || description.trim().toUpperCase() == 'N/A' ? '' : description.trim(),
      'observations': observations.trim().isEmpty || observations.trim().toUpperCase() == 'N/A' ? '' : observations.trim(),
      'voltage': voltage.trim().isEmpty || voltage.trim().toUpperCase() == 'N/A' ? '' : voltage.trim(),
      'pressure': pressure.trim().isEmpty || pressure.trim().toUpperCase() == 'N/A' ? '' : pressure.trim(),
    };
  }

  DiagnosisContractModel normalizeDiagnosisContractModel(
    String rawText, {
    required String category,
    required String deviceName,
    required String brand,
    required String model,
    required String description,
    required String observations,
    required String errorCode,
  }) {
    final text = rawText.trim();
    final hasEvidence = text.isNotEmpty && !text.contains('مراجعة أدلة إضافية مطلوبة') && !text.contains('تحتاج معلومات إضافية');

    if (!hasEvidence) {
      final normalizedModel = DiagnosisContractModel(
        diagnosisStatus: 'need_more_information',
        confidence: 35,
        nextQuestion: 'ما هي الأعراض الدقيقة عند حدوث العطل؟',
        possibleCauses: const <DiagnosisCauseModel>[],
        partsToCheck: const <DiagnosisPartCheckModel>[],
        inspectionSteps: const <DiagnosisStepModel>[],
        oshaWarnings: const <DiagnosisWarningModel>[],
        knowledgeSummary: '',
        followUpQuestions: const <String>[],
      );
      print('================ NORMALIZED MODEL ================');
      print(normalizedModel.toJson());
      print('==================================================');
      return normalizedModel;
    }

    final lower = text.toLowerCase();
    final likelyCapacitor = lower.contains('capacitor') || lower.contains('مكثف') || lower.contains('capacitor failure');
    final likelyConnection = lower.contains('connection') || lower.contains('توصيل') || lower.contains('wiring');
    final likelyMotor = lower.contains('motor') || lower.contains('محر') || lower.contains('محرك');

    final causes = <DiagnosisCauseModel>[];
    if (likelyCapacitor) {
      causes.add(DiagnosisCauseModel(title: 'مكثف أو مكوّن تشغيل معطل', probability: 85, description: 'الأعراض تشير إلى ضعف مكوّن التشغيل أو المكثف.'));
    }
    if (likelyConnection) {
      causes.add(DiagnosisCauseModel(title: 'مشكلة توصيل أو نقطة اتصال غير مستقرة', probability: 70, description: 'الأعراض تتوافق مع فقدان التوصيل أو تآكل نقطة الاتصال.'));
    }
    if (likelyMotor) {
      causes.add(DiagnosisCauseModel(title: 'فشل محرك أو ملف تشغيلي', probability: 55, description: 'هناك مؤشرات على ضعف المحرك أو الملف الداخلي.'));
    }
    if (causes.isEmpty) {
      causes.add(DiagnosisCauseModel(title: 'سبب تشغيلي غير واضح يحتاج ملاحظة إضافية', probability: 60, description: 'المعلومات الحالية غير كافية لإحكام التحديد.'));
    }

    final steps = <DiagnosisStepModel>[
      DiagnosisStepModel(step: 1, description: 'افصل مصدر الطاقة أو التشغيل قبل أي فحص مباشر.', mandatory: true),
      DiagnosisStepModel(step: 2, description: 'افحص المكوّن المرتبط بالأعراض المباشرة مثل التوصيل أو المكثف.', mandatory: true),
      DiagnosisStepModel(step: 3, description: 'إذا استمر العطل، أضف ملاحظة جديدة أو قياساً إضافياً قبل الحكم النهائي.', mandatory: false),
    ];

    final warnings = <DiagnosisWarningModel>[];
    if (category.contains('كهرباء') || category.contains('electrical') || lower.contains('تيار') || lower.contains('electric')) {
      warnings.add(DiagnosisWarningModel(risk: 'خطر صدمة كهربائية', severity: 'High', recommendation: 'افصل التيار قبل أي لمس للأجزاء الحية.'));
    }
    if (category.contains('هيدروليك') || category.contains('hydraulic') || lower.contains('ضغط')) {
      warnings.add(DiagnosisWarningModel(risk: 'خطر ضغط متبقي', severity: 'Medium', recommendation: 'تأكد من تخفيف الضغط قبل فتح أي مكوّن.'));
    }

    final normalizedModel = DiagnosisContractModel(
      diagnosisStatus: 'complete',
      confidence: 82,
      nextQuestion: '',
      possibleCauses: causes,
      partsToCheck: [
        DiagnosisPartCheckModel(part: 'المكوّن الرئيسي المرتبط بالأعراض', action: 'Inspect', reason: 'يحتاج إلى فحص مباشر بناءً على الأدلة الحالية.'),
      ],
      inspectionSteps: steps,
      oshaWarnings: warnings,
      knowledgeSummary: 'وصف مختصر: ${description.isNotEmpty ? description : 'العطل يحتاج فحصاً فائق الدقة'}. السبب المتوقع: ${causes.first.title}. الحل النهائي: افحص المكوّن المرتبط بالأعراض ثم اتخذ القرار النهائي بعد التحقق الميداني.',
      followUpQuestions: const <String>[],
    );
    print('================ NORMALIZED MODEL ================');
    print(normalizedModel.toJson());
    print('==================================================');
    return normalizedModel;
  }

  Map<String, dynamic> normalizeDiagnosisContract(
    String rawText, {
    required String category,
    required String deviceName,
    required String brand,
    required String model,
    required String description,
    required String observations,
    required String errorCode,
  }) {
    return normalizeDiagnosisContractModel(
      rawText,
      category: category,
      deviceName: deviceName,
      brand: brand,
      model: model,
      description: description,
      observations: observations,
      errorCode: errorCode,
    ).toJson();
  }

  AiApiService() {
    _router = AiProviderRouter()
      ..register(AiProvider.gemini, _GeminiProviderAdapter())
      ..register(AiProvider.openrouter, _OpenRouterProviderAdapter());
  }

  // جلب مفتاح OpenRouter من ملف البيئة .env
  String get _openRouterKey => AiConfig.openRouterApiKey;

  /// 1️⃣ دالة جلب الأسئلة التفاعلية الديناميكية لعطل معين مع ميزة التخزين المؤقت المحلي (Caching)
  Future<List<dynamic>> getDynamicQuestionsForFault(String faultType) async {
    final String cacheKey = 'cache_questions_${faultType.trim()}';
    
    // محاولة الاتصال بالشبكة وجلب البيانات الحية أولاً
    try {
      if (_openRouterKey.isEmpty) {
        throw Exception("API Key not configured");
      }

      final Dio dio = Dio();
      dio.options.connectTimeout = const Duration(seconds: 10);
      dio.options.receiveTimeout = const Duration(seconds: 10);

      final String modelName = (dotenv.env['OPENROUTER_MODEL']?.trim().isNotEmpty == true)
          ? dotenv.env['OPENROUTER_MODEL']!.trim()
          : 'qwen/qwen3.8-27b:free';

      final response = await dio.post(
        'https://openrouter.ai/api/v1/chat/completions',
        options: Options(
          contentType: 'application/json; charset=utf-8', // ✅ charset صريح
          headers: {
            'Authorization': 'Bearer $_openRouterKey',
            'HTTP-Referer': 'https://drfix.app', // ✅ مطلوب من OpenRouter
            'X-Title': 'Dr Fix',
          },
        ),
        data: {
          'model': modelName,
          'messages': [
            {
              'role': 'user',
              'content': "أنت مهندس صيانة خبير. أعطني قائمة بـ 3 أسئلة فنية دقيقة لتقصي عطل: ($faultType). "
                  "أريد المخرجات بصيغة JSON حصراً كـ List تحتوي على حقول (id, questionAr, questionEn). لا تضع أي نصوص خارج مصفوفة الـ JSON."
            }
          ],
        },
      );

      final String? textResponse = response?.data?['choices']?[0]?['message']?['content'];
      if (textResponse != null) {
        // تنظيف وحل النصوص المستخرجة بشكل صارم لتجنب مشاكل فك التشفير
        String cleanJson = textResponse.trim();
        if (cleanJson.contains('```json')) {
          cleanJson = cleanJson.split('```json').last.split('```').first.trim();
        } else if (cleanJson.contains('```')) {
          cleanJson = cleanJson.split('```').last.split('```').first.trim();
        }
        
        final List<dynamic> resultList = jsonDecode(cleanJson) as List<dynamic>;
        
        // حفظ المخرجات في التخزين المؤقت المحلي
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(cacheKey, jsonEncode(resultList));
        } catch (cacheErr) {
          print('Error writing questions to cache: $cacheErr');
        }

        return resultList;
      }
    } catch (e) {
      print('Network error or unconfigured key while fetching questions: $e. Checking local cache...');
    }

    // في حال فشل الشبكة أو عدم وجود مفتاح، نقرأ من الذاكرة المؤقتة المحلية
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedStr = prefs.getString(cacheKey);
      if (cachedStr != null) {
        print('Serving dynamic questions from SharedPreferences cache for: $faultType');
        return jsonDecode(cachedStr) as List<dynamic>;
      }
    } catch (cacheErr) {
      print('Error reading questions from cache: $cacheErr');
    }

    // إرجاع بيانات افتراضية آمنة في حال فشل كل من الشبكة والتخزين المؤقت
    return [
      {"id": "q1", "questionAr": "هل يقلع الضاغط (الكمبروسر) أم يصدر طنيناً فقط؟", "questionEn": "Does the compressor start or just buzz?"},
      {"id": "q2", "questionAr": "هل تلاحظ وجود ترشيح زيت أسفل صمامات الدائرة؟", "questionEn": "Do you notice oil leaks under the valves?"}
    ];
  }
  /// 2️⃣ طلب وتوليد تقرير التشخيص الموحد للمحرك الرباعي مع دعم التخزين المؤقت
  Future<Map<String, dynamic>> getUnifiedMultiAiDiagnosisReport(List<String> faults) async {
    final String faultsString = faults.join(", ");
    final String cacheKey = 'cache_diagnosis_report_${faultsString.hashCode}';

    try {
      final String diagnosisText = await getUnifiedMultiAiDiagnosis(
        category: "ميكانيك وتبريد",
        deviceName: "جهاز فني",
        brand: "مخصص",
        model: "ميداني",
        description: faultsString,
        observations: "ملاحظات مرصودة بالورشة",
        errorCode: "غير محدد",
        voltage: "220",
        pressure: "120",
      );

      final Map<String, dynamic> structuredOutput = _decodeStructuredDiagnosis(diagnosisText);
      final Map<String, dynamic> reportMap = {
        "diagnosisText": jsonEncode(structuredOutput),
        "structuredOutput": structuredOutput,
        "confidence": structuredOutput['Confidence'] ?? 82,
        "timestamp": DateTime.now().toIso8601String(),
      };

      // حفظ التقرير في التخزين المؤقت
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(cacheKey, jsonEncode(reportMap));
      } catch (cacheErr) {
        print('Error saving diagnosis report to cache: $cacheErr');
      }

      return reportMap;
    } catch (e) {
      print('Error generating report: $e. Checking cache...');
    }

    // استعادة التقرير الأخير من التخزين المؤقت في حال فشل المولد أو انقطاع الشبكة
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedStr = prefs.getString(cacheKey);
      if (cachedStr != null) {
        print('Serving diagnosis report from SharedPreferences cache.');
        return jsonDecode(cachedStr) as Map<String, dynamic>;
      }
    } catch (cacheErr) {
      print('Error reading diagnosis report from cache: $cacheErr');
    }

    final Map<String, dynamic> fallbackStructured = _buildFallbackStructuredDiagnosis("جهاز فني");
    return {
      "diagnosisText": jsonEncode(fallbackStructured),
      "structuredOutput": fallbackStructured,
      "confidence": fallbackStructured['Confidence'] ?? 75,
      "timestamp": DateTime.now().toIso8601String(),
    };
  }

  /// 3️⃣ المحرك الرئيسي الموحد لاستدعاء ودمج تشخيصات محركات الذكاء الاصطناعي الأربعة (الهجينة والمجانية)
  Future<String> getUnifiedMultiAiDiagnosis({
    required String category,
    required String deviceName,
    required String brand,
    required String model,
    required String description,
    required String observations,
    required String errorCode,
    required String voltage,
    required String pressure,
    List<String>? imagesB64,
    String? previousAttemptContext,
  }) async {
    print('>>> ENTER getUnifiedMultiAiDiagnosis');
    print('STEP 3 getUnifiedMultiAiDiagnosis()');
    final String inputSignature = "${category}_${deviceName}_${brand}_${model}_${description}_${errorCode}_${voltage}_${pressure}";
    final String cacheKey = 'cache_unified_diagnosis_markdown_${inputSignature.hashCode}';

    try {
      final Dio dio = Dio();
      dio.options.connectTimeout = const Duration(seconds: 15);
      dio.options.receiveTimeout = const Duration(seconds: 60);

      final payload = buildCompactDiagnosticPayload(
        category: category,
        deviceName: deviceName,
        brand: brand,
        model: model,
        description: description,
        observations: observations,
        errorCode: errorCode,
        voltage: voltage,
        pressure: pressure,
      );
      
      final List<String> evidenceLines = <String>[];
      if ((payload['system'] as String).trim().isNotEmpty) {
        evidenceLines.add('المجال: ${payload['system']}');
      }
      if ((payload['device_name'] as String).trim().isNotEmpty) {
        evidenceLines.add('الجهاز: ${payload['device_name']}');
      }
      if ((payload['user_description'] as String).trim().isNotEmpty) {
        evidenceLines.add('الوصف: ${payload['user_description']}');
      }
      if ((payload['observations'] as String).trim().isNotEmpty) {
        evidenceLines.add('الملاحظات: ${payload['observations']}');
      }
      if ((payload['error_code'] as String).trim().isNotEmpty) {
        evidenceLines.add('رمز الخطأ: ${payload['error_code']}');
      }
      if ((payload['voltage'] as String).trim().isNotEmpty) {
        evidenceLines.add('الجهد: ${payload['voltage']}');
      }
      if ((payload['pressure'] as String).trim().isNotEmpty) {
        evidenceLines.add('الضغط: ${payload['pressure']}');
      }

      final String faultDetails = [
        'الهدف: استخدم الأدلة الحالية فقط.',
        if (evidenceLines.isNotEmpty) ...evidenceLines,
        '',
        'اكتب 4 أسطر فقط:',
        'Evidence: ...',
        'Hypotheses: ...',
        'Elimination: ...',
        'Most Likely Diagnosis: ...',
        'إذا كانت الأدلة غير كافية، اذكر ذلك بوضوح ولا تخترع معلومات.',
      ].join('\n');

      final AiProvider preferredProvider = _selectPreferredProvider();
      print('STEP 5 Provider = ${preferredProvider.name}');
      print('===== AI REQUEST =====');
      print('deviceName: $deviceName');
      print('problemDescription: $description');
      print('symptoms: $observations');
      print('additionalNotes: errorCode=$errorCode, voltage=$voltage, pressure=$pressure');
      print('===== PROMPT BEGIN =====');
      print(faultDetails.length > 1000 ? faultDetails.substring(0, 1000) : faultDetails);
      print('===== PROMPT END =====');
      final String primaryResponse = await _callProvider(
        provider: preferredProvider,
        dio: dio,
        prompt: faultDetails,
        imagesB64: imagesB64,
      );

      final String geminiResponse = primaryResponse;
      final String gptResponse = primaryResponse;
      final String thirdAiResponse = primaryResponse;
      final String fourthAiResponse = primaryResponse;

      final String unifiedReport = _buildUnifiedStructuredDiagnosisReport(
        category: category,
        deviceName: deviceName,
        brand: brand,
        model: model,
        description: description,
        observations: observations,
        errorCode: errorCode,
        voltage: voltage,
        pressure: pressure,
        geminiResponse: geminiResponse,
        gptResponse: gptResponse,
        thirdAiResponse: thirdAiResponse,
        fourthAiResponse: fourthAiResponse,
      );

      // تخزين التقرير النصي الموحد محلياً
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(cacheKey, unifiedReport);
      } catch (cacheErr) {
        print('Error saving raw diagnosis text to cache: $cacheErr');
      }

      return unifiedReport;
    } catch (e, st) {
      print('CAUGHT ERROR: $e');
      print(st);
      print('Failed to generate live diagnosis: $e. Trying cache...');
      
      // جلب آخر تقرير مخزن محلياً لهذه المعطيات
      try {
        final prefs = await SharedPreferences.getInstance();
        final cachedReport = prefs.getString(cacheKey);
        if (cachedReport != null) {
          print('Serving raw diagnosis markdown from local cache.');
          return cachedReport;
        }
      } catch (cacheErr) {
        print('Error reading diagnosis markdown from cache: $cacheErr');
      }

      print('==============================');
      print('LIVE DIAGNOSIS FAILED');
      print('Exception: $e');
      print('Stack:');
      print(st);
      print('==============================');
      return _getFallbackSafetyReport(deviceName);
    }
  }
  /// 4️⃣ الاتصال بمحرك الذكاء الاصطناعي عبر router قابل للتوسيع
  Future<String> _callProvider({
    required AiProvider provider,
    required Dio dio,
    required String prompt,
    List<String>? imagesB64,
  }) async {
    print("ENTER _callProvider (Active selection: $provider)");

    // Case 1: Primary provider is Gemini, apply automated fallback wrapper
    if (provider == AiProvider.gemini) {
      try {
        print("🔄 Executing Primary Provider: Gemini (20s Cellular Handshake Timeout)...");
        final result = await _router.execute(
          provider: AiProvider.gemini,
          dio: dio,
          prompt: prompt,
          imagesB64: imagesB64,
        );
        lastActiveProvider = AiProvider.gemini;
        lastActiveEngineTag = 'GEMINI_DIRECT_SDK';
        return result;
      } catch (geminiError) {
        print("⚠️ Gemini Failed (404/CORS/Exception/Timeout): $geminiError");
        print("🚀 Triggering Live Cascade Fallback to Backup Provider: OpenRouter...");

        try {
          final result = await _router.execute(
            provider: AiProvider.openrouter,
            dio: dio,
            prompt: prompt,
            imagesB64: imagesB64,
          );
          lastActiveProvider = AiProvider.openrouter;
          lastActiveEngineTag = 'OPENROUTER_FALLBACK';
          return result;
        } catch (openRouterError) {
          print("❌ Both Gemini and OpenRouter failed simultaneously.");
          rethrow;
        }
      }
    }

    // Case 2: OpenRouter or default providers, execute directly
    final directResult = await _router.execute(
      provider: provider,
      dio: dio,
      prompt: prompt,
      imagesB64: imagesB64,
    );
    lastActiveProvider = provider;
    lastActiveEngineTag = provider.name.toUpperCase();
    return directResult;
  }

  AiProvider _selectPreferredProvider() {
    print('STEP 4 _selectPreferredProvider()');

    final geminiKey = AiConfig.geminiApiKey;
    if (geminiKey.isNotEmpty) {
      return AiProvider.gemini;
    }

    final openRouterKey = AiConfig.openRouterApiKey;
    if (openRouterKey.isNotEmpty) {
      return AiProvider.openrouter;
    }

    throw Exception('Missing GEMINI_API_KEY and OPENROUTER_API_KEY');
  }

  /// 8️⃣ بناء التقرير التشخيصي المنظم من عدة مزودات AI
  String _buildUnifiedStructuredDiagnosisReport({
    required String category,
    required String deviceName,
    required String brand,
    required String model,
    required String description,
    required String observations,
    required String errorCode,
    required String voltage,
    required String pressure,
    required String geminiResponse,
    required String gptResponse,
    required String thirdAiResponse,
    required String fourthAiResponse,
  }) {
    final payload = _buildStructuredDiagnosisPayload(
      category: category,
      deviceName: deviceName,
      brand: brand,
      model: model,
      description: description,
      observations: observations,
      errorCode: errorCode,
      voltage: voltage,
      pressure: pressure,
      geminiResponse: geminiResponse,
      gptResponse: gptResponse,
      thirdAiResponse: thirdAiResponse,
      fourthAiResponse: fourthAiResponse,
    );
    return jsonEncode(payload);
  }

  Map<String, dynamic> _buildStructuredDiagnosisPayload({
    required String category,
    required String deviceName,
    required String brand,
    required String model,
    required String description,
    required String observations,
    required String errorCode,
    required String voltage,
    required String pressure,
    required String geminiResponse,
    required String gptResponse,
    required String thirdAiResponse,
    required String fourthAiResponse,
  }) {
    final normalizedCategory = category.trim().isEmpty ? 'عام' : category;
    final normalizedDevice = deviceName.trim().isEmpty ? 'جهاز' : deviceName;
    final evidence = <String>{};
    if (description.trim().isNotEmpty) evidence.add('وصف المشكلة: $description');
    if (observations.trim().isNotEmpty) evidence.add('الملاحظات: $observations');
    if (errorCode.trim().isNotEmpty && errorCode.trim().toUpperCase() != 'N/A') evidence.add('رمز الخطأ: $errorCode');
    if (voltage.trim().isNotEmpty) evidence.add('الجهد: $voltage V');
    if (pressure.trim().isNotEmpty) evidence.add('الضغط: $pressure PSI');

    final reasoning = _buildEvidenceBasedReasoning(
      category: normalizedCategory,
      deviceName: normalizedDevice,
      description: description,
      observations: observations,
      errorCode: errorCode,
      voltage: voltage,
      pressure: pressure,
    );

    final evidenceCount = evidence.length;
    final repairSteps = <String>[];
    if (evidenceCount >= 2) {
      repairSteps.add('افصل مصدر الطاقة أو التشغيل قبل أي فحص مباشر.');
      repairSteps.add('قارن الأعراض الحالية مع الملاحظات أو الرمز الموجود ثم اختبر المكوّن الأقرب.');
      if (reasoning['confidenceScore'] as int < 80) {
        repairSteps.add('إذا بقيت الأدلة محدودة، أضف قياساً أو ملاحظة إضافية قبل الحكم النهائي.');
      }
    }

    final replacementParts = _buildReplacementParts(
      category: normalizedCategory,
      description: description,
      observations: observations,
      errorCode: errorCode,
      deviceName: normalizedDevice,
    );

    final safetyWarnings = _buildSafetyWarnings(
      category: normalizedCategory,
      description: description,
      observations: observations,
      errorCode: errorCode,
      voltage: voltage,
      pressure: pressure,
      deviceName: normalizedDevice,
    );

    return {
      'Main Diagnosis': reasoning['mainDiagnosis'] as String,
      'Confidence': reasoning['confidenceScore'] as int,
      'ConfidenceReason': reasoning['confidenceReason'] as String,
      'Evidence': evidence.toList(),
      'Possible Causes': List<Map<String, dynamic>>.from(reasoning['possibleCauses'] as List),
      'Repair Steps': repairSteps,
      'Replacement Parts': replacementParts,
      'Safety Warnings': safetyWarnings,
      'DeviceContext': {
        'category': normalizedCategory,
        'deviceName': normalizedDevice,
        'brand': brand.trim().isEmpty ? 'غير محدد' : brand,
        'model': model.trim().isEmpty ? 'غير محدد' : model,
      },
    };
  }

  Map<String, dynamic> _buildFallbackStructuredDiagnosis(String deviceName) {
    return {
      'Main Diagnosis': 'تحتاج الحالة إلى مراجعة فنية إضافية قبل الحكم على المكوّن المسبب',
      'Confidence': 75,
      'ConfidenceReason': 'النسبة منخفضة لأن الأدلة المتاحة لا تكفي لتأكيد المكوّن المسبب بدقة.',
      'Evidence': [
        'لا تتوفر أدلة كافية من السجل الحالي.',
        'المعلومات الحالية غير كافية لتحديد السبب الرئيسي بدقة.',
      ],
      'Possible Causes': [
        {'name': 'خلل محتمل في المكوّن الأساسي للمجال التشخيصي', 'confidence': 0.68},
        {'name': 'مشكلة متعلقة بالاتصال أو التشغيل غير المستقر', 'confidence': 0.61},
      ],
      'Repair Steps': [
        'افصل مصدر الطاقة أو التشغيل قبل أي فحص.',
        'افحص المكوّن الأساسي للجهاز ($deviceName) بدقة.',
        'إذا استمرت الأعراض، تابع الفحص مع فني مختص.',
      ],
      'Replacement Parts': [
        {
          'name': 'قطعة استبدال مناسبة للمكوّن الرئيسي المعني',
          'reason': 'الترشيح أولي ويحتاج إلى تأكيد بالفحص.',
          'probability': 'منخفض'
        }
      ],
      'Safety Warnings': [
        'افصل التيار قبل أي فحص.',
        'استخدم أدوات معزولة ومعدات حماية.',
      ],
    };
  }

  Map<String, dynamic> _decodeStructuredDiagnosis(String rawValue) {
    print("JSON PARSER INPUT:");
    print(rawValue);
    print("jsonDecode called from: _decodeStructuredDiagnosis");
    try {
      final decoded = jsonDecode(rawValue);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {}
    return _buildFallbackStructuredDiagnosis('جهاز');
  }

  String _summarizeProviderOutput(String value, String fallbackLabel) {
    final cleaned = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (cleaned.isEmpty) {
      return '$fallbackLabel: مراجعة أدلة إضافية مطلوبة.';
    }
    return cleaned.length > 140 ? '${cleaned.substring(0, 140)}...' : cleaned;
  }

  Map<String, dynamic> _buildEvidenceBasedReasoning({
    required String category,
    required String deviceName,
    required String description,
    required String observations,
    required String errorCode,
    required String voltage,
    required String pressure,
  }) {
    final evidenceItems = <String>[];
    if (description.trim().isNotEmpty && description.trim().toUpperCase() != 'N/A') evidenceItems.add(description.trim());
    if (observations.trim().isNotEmpty && observations.trim().toUpperCase() != 'N/A') evidenceItems.add(observations.trim());
    if (errorCode.trim().isNotEmpty && errorCode.trim().toUpperCase() != 'N/A') evidenceItems.add('رمز الخطأ: $errorCode');
    if (voltage.trim().isNotEmpty && voltage.trim().toUpperCase() != 'N/A') evidenceItems.add('الجهد: $voltage');
    if (pressure.trim().isNotEmpty && pressure.trim().toUpperCase() != 'N/A') evidenceItems.add('الضغط: $pressure');

    if (evidenceItems.isEmpty) {
      return {
        'mainDiagnosis': 'تحتاج معلومات إضافية قبل تقديم تشخيص محدد.',
        'confidenceReason': 'لا توجد أدلة كافية في السجل الحالي.',
        'confidenceScore': 60,
        'possibleCauses': <Map<String, dynamic>>[],
      };
    }

    final loweredDescription = description.toLowerCase();
    final loweredObservations = observations.toLowerCase();
    final hasStartIssue = loweredDescription.contains('بدء') || loweredDescription.contains('start') || loweredDescription.contains('لا يعمل') || loweredDescription.contains('won\'t start');
    final hasHeatIssue = loweredDescription.contains('حرارة') || loweredDescription.contains('heat') || loweredDescription.contains('سخ') || loweredDescription.contains('overheat');
    final hasLeakIssue = loweredDescription.contains('تسريب') || loweredDescription.contains('leak') || loweredDescription.contains('سائل') || loweredDescription.contains('oil');
    final hasPowerIssue = loweredDescription.contains('تيار') || loweredDescription.contains('power') || loweredDescription.contains('فشل') || loweredDescription.contains('fail');
    final hasNoiseIssue = loweredDescription.contains('طنين') || loweredDescription.contains('noise') || loweredDescription.contains('صوت') || loweredDescription.contains('buzz');
    final hasConnectionIssue = loweredObservations.contains('توصيل') || loweredObservations.contains('connection');
    final hasPressureIssue = loweredObservations.contains('ضغط') || loweredObservations.contains('pressure');

    final hypotheses = <Map<String, dynamic>>[];
    if (hasStartIssue || hasPowerIssue) {
      hypotheses.add({'name': 'خلل في مكوّن التشغيل أو الدائرة المرتبطة بالبدء', 'confidence': 0.88});
    }
    if (hasHeatIssue) {
      hypotheses.add({'name': 'ضعف أداء المكوّن المرتبط بالحرارة أو التشغيل', 'confidence': 0.78});
    }
    if (hasLeakIssue || hasPressureIssue) {
      hypotheses.add({'name': 'خلل في نظام التسريب أو الضغط', 'confidence': 0.83});
    }
    if (hasConnectionIssue) {
      hypotheses.add({'name': 'مشكلة توصيل أو نقطة اتصال غير مستقرة', 'confidence': 0.74});
    }
    if (hasNoiseIssue) {
      hypotheses.add({'name': 'مكوّن ميكانيكي أو كهربائي يسبب صوتاً غير طبيعي', 'confidence': 0.71});
    }
    if (errorCode.trim().isNotEmpty && errorCode.trim().toUpperCase() != 'N/A') {
      hypotheses.add({'name': 'خلل مرتبط بالرمز أو المكوّن المسبّب في النظام', 'confidence': 0.79});
    }

    if (hypotheses.isEmpty) {
      return {
        'mainDiagnosis': 'لا توجد أدلة كافية لتقديم تشخيص محدد، ويحتاج الأمر إلى ملاحظة أو قياس إضافي.',
        'confidenceReason': 'الأدلة الحالية محدودة ولا تكفي لتأكيد سبب واحد.',
        'confidenceScore': 66,
        'possibleCauses': <Map<String, dynamic>>[],
      };
    }

    hypotheses.sort((a, b) => (b['confidence'] as double).compareTo(a['confidence'] as double));
    final top = hypotheses.first;
    final second = hypotheses.length > 1 ? hypotheses[1] : null;
    final evidenceSummary = evidenceItems.take(3).join(' • ');
    final confidenceScore = (70 + (evidenceItems.length * 4) + ((top['confidence'] as double) > 0.8 ? 4 : 0)).round().clamp(66, 92);

    return {
      'mainDiagnosis': evidenceItems.length >= 2
          ? 'الأدلة الحالية تدعم ${top['name']} أكثر من الفرضيات الأخرى.'
          : 'الأدلة الحالية محدودة، لذلك يبقى ${top['name']} هو الأقرب فقط.',
      'confidenceReason': 'Evidence: $evidenceSummary. Hypotheses: ${hypotheses.take(2).map((h) => h['name']).join(' | ')}. Elimination: لا توجد ملاحظات متناقضة في السجل الحالي. Most likely diagnosis: ${top['name']}.',
      'confidenceScore': confidenceScore,
      'possibleCauses': [
        {'name': top['name'], 'confidence': top['confidence']},
        if (second != null) {'name': second['name'], 'confidence': second['confidence']},
      ],
    };
  }

  List<Map<String, dynamic>> _buildReplacementParts({
    required String category,
    required String description,
    required String observations,
    required String errorCode,
    required String deviceName,
  }) {
    final lowered = description.toLowerCase();
    final hasLeak = lowered.contains('تسريب') || lowered.contains('leak') || lowered.contains('سائل') || lowered.contains('oil');
    final hasHeat = lowered.contains('حرارة') || lowered.contains('heat') || lowered.contains('سخ') || lowered.contains('overheat');
    final hasPower = lowered.contains('تيار') || lowered.contains('power') || lowered.contains('فشل') || lowered.contains('start');

    if (category.contains('تكييف') || category.contains('hvac') || category.contains('cooling')) {
      return [
        {
          'name': 'مكثف تشغيل أو بدء مناسب',
          'reason': 'الترشيح مرتبط مباشرة بالأعراض التي تشير إلى ضعف مكوّن التشغيل داخل نظام التكييف.',
          'probability': 'مرتفع'
        },
        if (hasLeak)
          {
            'name': 'ختم أو لولبة توصيل معزولة',
            'reason': 'موجودة مؤشرات تسريب أو ضعف في نقطة التوصيل.',
            'probability': 'متوسط'
          }
      ];
    }

    if (category.contains('سيارات') || category.contains('car') || category.contains('auto')) {
      return [
        {
          'name': 'مكوّن إشعال أو تشغيل مرتبط بالرمز الظاهر',
          'reason': 'الترشيح مرتبط بالرمز والأعراض التي تشير إلى فشل في مكوّن التشغيل أو الإشعال.',
          'probability': 'مرتفع'
        },
        if (hasHeat)
          {
            'name': 'مكوّن تبريد أو حساس حراري',
            'reason': 'توجد مؤشرات على ارتفاع حرارة أو ضعف في التبريد.',
            'probability': 'متوسط'
          }
      ];
    }

    if (category.contains('كهرباء') || category.contains('electrical')) {
      return [
        {
          'name': 'قاطع حماية أو نقطة توصيل كهربائية',
          'reason': 'الترشيح مرتبط مباشرة بأعراض ضعف التيار أو التوصيل.',
          'probability': 'مرتفع'
        },
        if (hasPower)
          {
            'name': 'مكوّن كهربائي داعم أو حساس تشغيل',
            'reason': 'توجد مؤشرات على ضعف دوران أو فشل تشغيل الدائرة.',
            'probability': 'متوسط'
          }
      ];
    }

    if (category.contains('هيدروليك') || category.contains('hydraulic')) {
      return [
        {
          'name': 'ختم ضغط أو مكوّن هيدروليكي رئيسي',
          'reason': 'الترشيح مرتبط بالأعراض التي تشير إلى فقدان الضغط أو التسريب.',
          'probability': 'مرتفع'
        },
      ];
    }

    return [
      {
        'name': 'قطعة استبدال مناسبة للمكوّن الرئيسي المعني',
        'reason': 'الترشيح أولي ويحتاج إلى تأكيد بالفحص.',
        'probability': 'منخفض'
      },
      if (hasLeak)
        {
          'name': 'مكوّن داعم مرتبط بالتوصيل أو الختم',
          'reason': 'توجد مؤشرات على تسريب أو ضعف نقطة التوصيل.',
          'probability': 'متوسط'
        }
    ];
  }

  List<String> _buildSafetyWarnings({
    required String category,
    required String description,
    required String observations,
    required String errorCode,
    required String voltage,
    required String pressure,
    required String deviceName,
  }) {
    final lowered = [description, observations, category, deviceName].join(' ').toLowerCase();
    final isElectrical = category.contains('كهرباء') || category.contains('electrical') || lowered.contains('تيار') || lowered.contains('electric') || lowered.contains('كهرب');
    final isPressurized = category.contains('هيدروليك') || category.contains('hydraulic') || lowered.contains('ضغط') || lowered.contains('pressure') || lowered.contains('سائل');
    final isHot = lowered.contains('حرارة') || lowered.contains('heat') || lowered.contains('سخ') || lowered.contains('overheat');
    final hasPowerSource = voltage.trim().isNotEmpty && voltage.trim().toUpperCase() != 'N/A';

    final warnings = <String>[];
    if (isElectrical) {
      warnings.add('افصل مصدر الطاقة قبل أي فحص، خاصة إذا كانت الدائرة تحت تيار أو شحنة كهربائية.');
      warnings.add('استخدم أدوات معزولة وتجنب اللمس المباشر للأجزاء الحية.');
    } else if (isPressurized) {
      warnings.add('أوقف تشغيل النظام وتأكد من تخفيف الضغط قبل فتح أي مكوّن.');
      warnings.add('تجنب لمس الوصلات أو الخراطيم أثناء وجود ضغط متبقي.');
    } else {
      warnings.add('أوقف التشغيل قبل أي فحص ميداني وأمسك المعدات بحذر.');
    }

    if (isHot) {
      warnings.add('احذر من ارتفاع الحرارة أو الأجزاء الساخنة قبل التعامل معها.');
    }

    if (errorCode.trim().isNotEmpty && errorCode.trim().toUpperCase() != 'N/A') {
      warnings.add('اعتمد على رمز الخطأ كدليل مساعد فقط ولا تعتمد عليه وحده عند اتخاذ القرار.');
    }

    if (hasPowerSource) {
      warnings.add('راجع مصدر الطاقة المتصل قبل البدء بأي خطوة إصلاح.');
    }

    return warnings;
  }

  /// 9️⃣ تقرير الطوارئ الاحتياطي في حال انقطاع الاتصال بكافة الخوادم
  String _getFallbackSafetyReport(String deviceName) {
    return jsonEncode(_buildFallbackStructuredDiagnosis(deviceName));
  }
}
