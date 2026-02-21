class CountryModel {
  final int id;
  final String name;
  final String iso;
  final String code;
  final String flag;

  CountryModel({
    required this.id,
    required this.name,
    required this.iso,
    required this.code,
    required this.flag,
  });

  factory CountryModel.fromJson(Map<String, dynamic> json) {
    return CountryModel(
      id: json['id'],
      name: json['name'],
      iso: json['iso'],
      code: json['code'],
      flag: json['flag'],
    );
  }
}
