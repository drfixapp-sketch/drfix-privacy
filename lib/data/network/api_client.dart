import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'exceptions.dart';

class ApiClient {
  final Dio _dio;

  ApiClient({String? baseUrl}) : _dio = Dio(BaseOptions(
    baseUrl: baseUrl ?? 'https://api.drfix.com/',
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
  ));

  Future<T> get<T>(String path, {Map<String, dynamic>? queryParameters}) async {
    final String cacheKey = 'cache_api_get_${path}_${queryParameters?.toString().hashCode ?? 0}';
    try {
      final response = await _dio.get(path, queryParameters: queryParameters);
      final data = response.data;
      
      // حفظ الاستجابة محلياً لضمان توفرها لاحقاً بلا إنترنت
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(cacheKey, jsonEncode(data));
      } catch (cacheError) {
        print('Error saving GET response to cache: $cacheError');
      }
      
      return data as T;
    } catch (e) {
      // محاولة تلبية الطلب من الذاكرة المؤقتة المحلية في حال فشل الاتصال بالشبكة
      try {
        final prefs = await SharedPreferences.getInstance();
        final cachedDataStr = prefs.getString(cacheKey);
        if (cachedDataStr != null) {
          print('Network failed. Serving cached data for path: $path');
          return jsonDecode(cachedDataStr) as T;
        }
      } catch (cacheError) {
        print('Error reading GET response from cache: $cacheError');
      }

      if (e is DioException) {
        _handleDioException(e);
      }
      throw UnknownException(technicalMessage: e.toString());
    }
  }

  Future<T> post<T>(String path, {Map<String, dynamic>? data}) async {
    try {
      final response = await _dio.post(path, data: data);
      return response.data as T;
    } catch (e) {
      if (e is DioException) {
        _handleDioException(e);
      }
      throw UnknownException(technicalMessage: e.toString());
    }
  }

  void _handleDioException(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      throw NetworkException(technicalMessage: e.message);
    } else if (e.response != null) {
      final statusCode = e.response!.statusCode;
      if (statusCode == 401 || statusCode == 403) {
        throw UnauthorizedException(technicalMessage: e.response?.statusMessage);
      } else {
        throw ServerException(
          statusCode: statusCode,
          technicalMessage: e.response?.data?.toString() ?? e.response?.statusMessage,
        );
      }
    } else {
      throw UnknownException(technicalMessage: e.message);
    }
  }
}