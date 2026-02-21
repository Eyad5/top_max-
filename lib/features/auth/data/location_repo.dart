import 'location_api.dart';
import 'package:top_max/features/auth/models/country_model.dart';
import 'package:top_max/features/auth/models/city_model.dart';

class LocationRepo {
  final LocationApi api;
  LocationRepo(this.api);

  // ===== Countries =====
  Future<List<CountryModel>> getCountries() async {
    final res = await api.getCountries();
    final list = (res.data['data'] as List)
        .map((e) => CountryModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return list;
  }

  // ===== Cities =====
  Future<List<CityModel>> getCities(int countryId) async {
    final json = await api.getCities(countryId);
    final list = (json['data'] as List)
        .map((e) => CityModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return list;
  }

  Future<List<CityModel>> getDefaultCities(int countryId) async {
    final json = await api.getDefaultCities(countryId);
    final list = (json['data'] as List)
        .map((e) => CityModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return list;
  }
}
