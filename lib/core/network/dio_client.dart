import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../storage/token_storage.dart';

class DioClient {
  static late final Dio dio;
  static final TokenStorage tokenStorage = TokenStorage();

  static const String baseUrl = 'https://flutter.topmax.ae/api-test/';

  // Production-grade logging (always active for critical endpoints)
  static Future<void> _logCriticalError(String endpoint, String errorType, String details) async {
    final timestamp = DateTime.now().toIso8601String();
    final logEntry = '[$timestamp] [COUNTRIES_ERROR_TYPE]: $errorType\nEndpoint: $endpoint\nDetails: $details';

    // Log to console (works in both debug and release)
    debugPrint('═══════════════════════════════════════════════════════════');
    debugPrint('🔴 CRITICAL NETWORK ERROR');
    debugPrint(logEntry);
    debugPrint('═══════════════════════════════════════════════════════════');

    // Store in SharedPreferences for later inspection
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_countries_error', logEntry);
      await prefs.setString('last_countries_error_time', timestamp);
    } catch (_) {
      // Ignore storage errors
    }
  }

  static Future<void> init() async {
    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
        validateStatus: (status) =>
            status != null && status >= 200 && status < 600,
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await tokenStorage.readToken();
          final hasToken = token != null && token.trim().isNotEmpty;

          if (hasToken) {
            options.headers['Authorization'] = 'Bearer $token';
          } else {
            options.headers.remove('Authorization');
          }

          // Always log critical endpoints (countries)
          if (options.path.contains('countries')) {
            debugPrint('🌍 [COUNTRIES] Full URL: ${options.uri}');
            debugPrint('🌍 [COUNTRIES] Expected: ${baseUrl}location/countries');
            debugPrint('🌍 [COUNTRIES] Method: ${options.method}');
          }

          if (kDebugMode) {
            print('🔐 ${options.path} hasToken=$hasToken authHeader=${options.headers['Authorization'] != null}');
            print('➡️ ${options.method} ${options.uri}');
            print('➡️ headers: ${options.headers}');
            if (options.queryParameters.isNotEmpty) {
              print('➡️ query: ${options.queryParameters}');
            }
            if (options.data != null) {
              print('➡️ data: ${options.data}');
            }
          }

          handler.next(options);
        },

        onResponse: (response, handler) {
          // Always log critical endpoints success
          if (response.requestOptions.path.contains('countries')) {
            debugPrint('✅ [COUNTRIES] Success: ${response.statusCode}');
          }

          if (kDebugMode) {
            print('✅ ${response.statusCode} ${response.requestOptions.uri}');
            if (response.statusCode != null && response.statusCode! >= 400) {
              print('⚠️ response data: ${response.data}');
            }
          }
          handler.next(response);
        },

        onError: (e, handler) async {
          // Categorize and log critical endpoint errors
          if (e.requestOptions.path.contains('countries')) {
            String errorType = 'UNKNOWN';
            String details = '';

            // Categorize the error
            if (e.error.toString().contains('Failed host lookup') ||
                e.error.toString().contains('SocketException')) {
              errorType = 'DNS';
              details = 'DNS resolution failed. Device cannot resolve ${e.requestOptions.uri.host}';
            } else if (e.error.toString().contains('HandshakeException') ||
                       e.error.toString().contains('CERTIFICATE_VERIFY_FAILED')) {
              errorType = 'SSL';
              details = 'SSL/TLS handshake failed. Certificate verification issue.';
            } else if (e.type == DioExceptionType.connectionTimeout) {
              errorType = 'TIMEOUT_CONNECT';
              details = 'Connection timeout after ${dio.options.connectTimeout?.inSeconds}s';
            } else if (e.type == DioExceptionType.receiveTimeout) {
              errorType = 'TIMEOUT_RECEIVE';
              details = 'Receive timeout after ${dio.options.receiveTimeout?.inSeconds}s';
            } else if (e.type == DioExceptionType.sendTimeout) {
              errorType = 'TIMEOUT_SEND';
              details = 'Send timeout';
            } else if (e.response?.statusCode == 403) {
              errorType = 'SERVER_403';
              details = 'Server returned 403 Forbidden';
            } else if (e.response?.statusCode == 401) {
              errorType = 'SERVER_401';
              details = 'Server returned 401 Unauthorized';
            } else if (e.type == DioExceptionType.connectionError) {
              errorType = 'CONNECTION';
              details = 'Connection error: ${e.message}';
            } else {
              details = 'Type: ${e.type}, Message: ${e.message}, Error: ${e.error}';
            }

            await _logCriticalError(
              e.requestOptions.uri.toString(),
              errorType,
              details,
            );
          }

          if (kDebugMode) {
            print('❌ DIO ERROR: ${e.type} ${e.message}');
            if (e.response != null) {
              print('❌ ${e.response?.statusCode} ${e.requestOptions.uri}');
              print('❌ data: ${e.response?.data}');
            }
          }
          handler.next(e);
        },
      ),
    );
  }
}
