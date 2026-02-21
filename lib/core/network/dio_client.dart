import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../storage/token_storage.dart';

class DioClient {
  static late final Dio dio;
  static final TokenStorage tokenStorage = TokenStorage();

  static const String baseUrl = 'https://flutter.topmax.ae/api-test/';

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
          if (kDebugMode) {
            print('✅ ${response.statusCode} ${response.requestOptions.uri}');
            if (response.statusCode != null && response.statusCode! >= 400) {
              print('⚠️ response data: ${response.data}');
            }
          }
          handler.next(response);
        },

        onError: (e, handler) {
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
