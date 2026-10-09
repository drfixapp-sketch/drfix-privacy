import 'package:flutter_dotenv/flutter_dotenv.dart';

/// 🛡️ Dedicated AI Configuration helper for isolated Android & iOS credential handling.
class AiConfig {
  /// Returns the active Gemini API Key for the current platform.
  /// Priority order:
  /// 1. Compile-time --dart-define=ANDROID_GEMINI_API_KEY
  /// 2. dotenv ANDROID_GEMINI_API_KEY
  /// 3. Compile-time --dart-define=GEMINI_API_KEY
  /// 4. dotenv GEMINI_API_KEY fallback
  static String get geminiApiKey {
    const compileTimeAndroidKey = String.fromEnvironment('ANDROID_GEMINI_API_KEY');
    if (compileTimeAndroidKey.isNotEmpty) return compileTimeAndroidKey;

    final dotenvAndroidKey = dotenv.env['ANDROID_GEMINI_API_KEY']?.trim();
    if (dotenvAndroidKey != null && dotenvAndroidKey.isNotEmpty) return dotenvAndroidKey;

    const compileTimeGenericKey = String.fromEnvironment('GEMINI_API_KEY');
    if (compileTimeGenericKey.isNotEmpty) return compileTimeGenericKey;

    return dotenv.env['GEMINI_API_KEY']?.trim() ?? '';
  }

  /// Returns the active OpenRouter API Key for the current platform.
  /// Priority order:
  /// 1. Compile-time --dart-define=ANDROID_OPENROUTER_API_KEY
  /// 2. dotenv ANDROID_OPENROUTER_API_KEY
  /// 3. Compile-time --dart-define=OPENROUTER_API_KEY
  /// 4. dotenv OPENROUTER_API_KEY fallback
  static String get openRouterApiKey {
    const compileTimeAndroidKey = String.fromEnvironment('ANDROID_OPENROUTER_API_KEY');
    if (compileTimeAndroidKey.isNotEmpty) return compileTimeAndroidKey;

    final dotenvAndroidKey = dotenv.env['ANDROID_OPENROUTER_API_KEY']?.trim();
    if (dotenvAndroidKey != null && dotenvAndroidKey.isNotEmpty) return dotenvAndroidKey;

    const compileTimeGenericKey = String.fromEnvironment('OPENROUTER_API_KEY');
    if (compileTimeGenericKey.isNotEmpty) return compileTimeGenericKey;

    return dotenv.env['OPENROUTER_API_KEY']?.trim() ?? '';
  }

  /// Active Gemini Model
  static String get geminiModel {
    final m = dotenv.env['GEMINI_MODEL']?.trim();
    return (m != null && m.isNotEmpty) ? m : 'gemini-1.5-flash';
  }

  /// Active OpenRouter Model
  static String get openRouterModel {
    final m = dotenv.env['OPENROUTER_MODEL']?.trim();
    return (m != null && m.isNotEmpty) ? m : 'qwen/qwen3.8-27b:free';
  }
}
