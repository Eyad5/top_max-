import 'package:dio/dio.dart';

class LocationApi {
  final Dio _dio;
  LocationApi(this._dio);

  // ===== Countries =====
  Future<Response> getCountries() {
    return _dio.get('location/countries');
  }

  // ===== Cities =====
  Future<Map<String, dynamic>> getCities(int countryId) async {
    final res = await _dio.get('location/countries/$countryId/cities');
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<Map<String, dynamic>> getDefaultCities(int countryId) async {
    final res = await _dio.get(
      'location/cities/$countryId',
      queryParameters: {'return_default_cities': true},
    );
    return Map<String, dynamic>.from(res.data as Map);
  }
}
