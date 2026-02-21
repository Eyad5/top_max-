import 'package:dio/dio.dart';

class AuthApi {
  final Dio dio;
  AuthApi(this.dio);

  Future<Response> requestOtp({
    required String phone,
    required int countryId,
  }) {
    return dio.post(
      'user/request-otp',
      data: {'phone': phone, 'country_id': countryId},
    );
  }

  Future<Response> verifyOtp({
    required String phone,
    required String otp,
    required int countryId,
  }) {
    return dio.post(
      'user/verify-otp',
      data: {'phone': phone, 'otp': otp, 'country_id': countryId},
    );
  }

  Future<Response> resendOtp({
    required String phone,
    required int countryId,
  }) {
    return dio.post(
      'user/resend-otp',
      data: {'phone': phone, 'country_id': countryId},
    );
  }

  Future<Response> logout() {
    return dio.post('user/logout');
  }
}
