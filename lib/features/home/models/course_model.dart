class CourseModel {
  final int id;
  final String title;
  final String? description;
  final String? featuredImage;
  final String? courseCategory;
  final String? price;

  final bool? isFree;
  final String? level;
  final bool? hasCertificate;
  final int? availableSeats;
  final int? companyId;
  final String? status;

  final int? totalEnrolled;
  final num? seatsPercentage;

  // Course details extra fields
  final List<String>? highlights;
  final String? startDate;
  final String? startTime;
  final String? type;
  final String? location;

  // Save state (for bookmarks)
  final bool isSaved;

  const CourseModel({
    required this.id,
    required this.title,
    this.description,
    this.featuredImage,
    this.courseCategory,
    this.price,
    this.isFree,
    this.level,
    this.hasCertificate,
    this.availableSeats,
    this.companyId,
    this.status,
    this.totalEnrolled,
    this.seatsPercentage,
    this.highlights,
    this.startDate,
    this.startTime,
    this.type,
    this.location,
    this.isSaved = false,
  });

  factory CourseModel.fromJson(Map<String, dynamic> json) {
    // Parse highlights array
    List<String>? highlights;
    if (json['highlights'] is List) {
      highlights = (json['highlights'] as List)
          .map((e) => e.toString())
          .toList();
    }

    return CourseModel(
      id: _asInt(json['id']) ?? 0,
      title: (json['title'] ?? '').toString(),
      description: json['description']?.toString(),
      featuredImage: json['featured_image']?.toString(),
      courseCategory: json['course_category']?.toString(),
      price: json['price']?.toString(),

      // السيرفر عندكم مرات بيرسل 1/0 بدل true/false
      isFree: _asBool(json['is_free']),
      level: json['level']?.toString(),
      hasCertificate: _asBool(json['has_certificate']),
      availableSeats: _asInt(json['available_seats']),
      companyId: _asInt(json['company_id']),
      status: json['status']?.toString(),
      totalEnrolled: _asInt(json['total_enrolled']),
      seatsPercentage: _asNum(json['seats_percentage']),

      // Course details extra fields
      highlights: highlights,
      startDate: json['start_date']?.toString(),
      startTime: json['start_time']?.toString(),
      type: json['type']?.toString(),
      location: json['location']?.toString(),

      // Save state
      isSaved: _asBool(json['is_saved']) ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'featured_image': featuredImage,
        'course_category': courseCategory,
        'price': price,
        'is_free': isFree,
        'level': level,
        'has_certificate': hasCertificate,
        'available_seats': availableSeats,
        'company_id': companyId,
        'status': status,
        'total_enrolled': totalEnrolled,
        'seats_percentage': seatsPercentage,
        'highlights': highlights,
        'start_date': startDate,
        'start_time': startTime,
        'type': type,
        'location': location,
        'is_saved': isSaved,
      };

  CourseModel copyWith({bool? isSaved}) {
    return CourseModel(
      id: id,
      title: title,
      description: description,
      featuredImage: featuredImage,
      courseCategory: courseCategory,
      price: price,
      isFree: isFree,
      level: level,
      hasCertificate: hasCertificate,
      availableSeats: availableSeats,
      companyId: companyId,
      status: status,
      totalEnrolled: totalEnrolled,
      seatsPercentage: seatsPercentage,
      highlights: highlights,
      startDate: startDate,
      startTime: startTime,
      type: type,
      location: location,
      isSaved: isSaved ?? this.isSaved,
    );
  }

  static int? _asInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  static num? _asNum(dynamic v) {
    if (v == null) return null;
    if (v is num) return v;
    return num.tryParse(v.toString());
  }

  static bool? _asBool(dynamic v) {
    if (v == null) return null;
    if (v is bool) return v;
    if (v is num) return v != 0;
    final s = v.toString().toLowerCase().trim();
    if (s == 'true' || s == '1') return true;
    if (s == 'false' || s == '0') return false;
    return null;
  }
}
