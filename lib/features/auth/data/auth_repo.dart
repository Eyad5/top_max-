import 'package:dio/dio.dart';
import '../../../core/storage/token_storage.dart';
import 'auth_api.dart';

class VerifyOtpResult {
  final String token;
  final String? nextStep;

  VerifyOtpResult({required this.token, required this.nextStep});
}

class AuthRepo {
  final AuthApi api;
  final TokenStorage tokenStorage;

  AuthRepo({required this.api, required this.tokenStorage});

  Future<void> requestOtp(String phone, int countryId) async {
    final res = await api.requestOtp(phone: phone, countryId: countryId);
    if (res.statusCode == null || res.statusCode! >= 400) {
      throw DioException(
        requestOptions: res.requestOptions,
        response: res,
        type: DioExceptionType.badResponse,
      );
    }
  }

  Future<VerifyOtpResult> verifyOtp(String phone, String otp, int countryId) async {
    final res = await api.verifyOtp(phone: phone, otp: otp, countryId: countryId);

    // dio عندك validateStatus صار يقبل 401/500، فلازم نفحص يدويًا
    if (res.statusCode == null || res.statusCode! >= 400) {
      throw DioException(
        requestOptions: res.requestOptions,
        response: res,
        type: DioExceptionType.badResponse,
      );
    }

    final raw = (res.data is Map) ? Map<String, dynamic>.from(res.data as Map) : <String, dynamic>{};

    // ✅ جرّب كل المسارات الشائعة للتوكن
    final data = raw['data'];
    String token = '';

    String pickToken(dynamic obj) {
      if (obj is Map) {
        final m = Map<String, dynamic>.from(obj);
        final t1 = (m['token'] ?? '').toString();
        if (t1.isNotEmpty) return t1;

        final t2 = (m['access_token'] ?? '').toString();
        if (t2.isNotEmpty) return t2;

        final t3 = (m['bearer_token'] ?? '').toString();
        if (t3.isNotEmpty) return t3;
      }
      return '';
    }

    token = pickToken(raw);
    if (token.isEmpty) token = pickToken(data);
    if (token.isEmpty && data is Map && data['data'] is Map) {
      token = pickToken(data['data']);
    }

    // next_step ممكن يكون في نفس الأماكن
    String? nextStep;
    String? pickNextStep(dynamic obj) {
      if (obj is Map) {
        final m = Map<String, dynamic>.from(obj);
        final ns = m['next_step']?.toString();
        if (ns != null && ns.isNotEmpty) return ns;
      }
      return null;
    }

    nextStep = pickNextStep(raw) ?? pickNextStep(data);
    if (nextStep == null && data is Map && data['data'] is Map) {
      nextStep = pickNextStep(data['data']);
    }

    if (token.isEmpty) {
      // هذا أهم سطر: لو ما لقينا توكن، معناته parsing غلط أو السيرفر ما رجعه
      throw Exception('Token not found in verify-otp response: $raw');
    }

    await tokenStorage.saveToken(token);

    return VerifyOtpResult(token: token, nextStep: nextStep);
  }

  Future<void> resendOtp(String phone, int countryId) async {
    final res = await api.resendOtp(phone: phone, countryId: countryId);
    if (res.statusCode == null || res.statusCode! >= 400) {
      throw DioException(
        requestOptions: res.requestOptions,
        response: res,
        type: DioExceptionType.badResponse,
      );
    }
  }

  Future<void> logout() async {
    try {
      await api.logout();
    } catch (_) {
      // ignore
    }
    await tokenStorage.clearToken();
  }

  static String friendlyDioError(Object e) {
    if (e is DioException) {
      final code = e.response?.statusCode;
      final msg = e.response?.data?.toString();
      return 'Error ${code ?? ''}\n${msg ?? e.message ?? ''}'.trim();
    }
    return e.toString();
  }
}
