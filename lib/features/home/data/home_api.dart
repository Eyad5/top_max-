import 'package:dio/dio.dart';

class HomeApi {
  final Dio dio;
  HomeApi(this.dio);

  // ===== Home =====
  Future<Map<String, dynamic>> getMobileHome({int page = 1, int perPage = 0}) async {
    final res = await dio.get(
      'mobile/home',
      queryParameters: {'page': page, 'per_page': perPage},
    );
    return Map<String, dynamic>.from(res.data as Map);
  }

  // ===== Search with all filters =====
  Future<Map<String, dynamic>> searchJobs({
    String? keyword,
    String? location,
    num? salaryMin,
    num? salaryMax,
    String? experience,
    String? jobType,
    String? locationType,
    int? disability,
    int page = 1,
    int perPage = 10,
  }) async {
    final res = await dio.get(
      'home/search',
      queryParameters: {
        if (keyword != null && keyword.trim().isNotEmpty) 'keyword': keyword.trim(),
        if (location != null && location.isNotEmpty) 'location': location,
        if (salaryMin != null) 'salary_min': salaryMin,
        if (salaryMax != null) 'salary_max': salaryMax,
        if (experience != null && experience.isNotEmpty) 'experience': experience,
        if (jobType != null && jobType.isNotEmpty) 'job_type': jobType,
        if (locationType != null && locationType.isNotEmpty) 'location_type': locationType,
        if (disability != null) 'disability': disability,
        'page': page,
        'per_page': perPage,
      },
    );
    return Map<String, dynamic>.from(res.data as Map);
  }

  // ===== Jobs list (user/jobs) =====
  Future<Map<String, dynamic>> getJobs({
    String? search,
    String? officeLocation,
    String? jobType,
    String? experienceLevel,
    num? minSalary,
    num? maxSalary,
    int page = 1,
    int perPage = 12,
  }) async {
    final res = await dio.get(
      'user/jobs',
      queryParameters: {
        if (search != null && search.isNotEmpty) 'search': search,
        if (officeLocation != null && officeLocation.isNotEmpty) 'office_location': officeLocation,
        if (jobType != null && jobType.isNotEmpty) 'job_type': jobType,
        if (experienceLevel != null && experienceLevel.isNotEmpty) 'experience_level': experienceLevel,
        if (minSalary != null) 'min_salary': minSalary,
        if (maxSalary != null) 'max_salary': maxSalary,
        'page': page,
        'per_page': perPage,
      },
    );
    return Map<String, dynamic>.from(res.data as Map);
  }

  // ===== Job details (user/jobs/{id}) =====
  Future<Map<String, dynamic>> getJobDetails(int jobId) async {
    final res = await dio.get('user/jobs/$jobId');
    return Map<String, dynamic>.from(res.data as Map);
  }

  // ===== Courses list (user/courses) =====
  Future<Map<String, dynamic>> getCourses({
    int? categoryId,
    String? level,
    String? type,
    bool? hasCertificate,
    String? search,
    bool? coursesForYou,
    String? startDate,
    int page = 1,
    int perPage = 8,
  }) async {
    final res = await dio.get(
      'user/courses',
      queryParameters: {
        if (categoryId != null) 'category_id': categoryId,
        if (level != null && level.isNotEmpty) 'level': level,
        if (type != null && type.isNotEmpty) 'type': type,
        if (hasCertificate != null) 'has_certificate': hasCertificate ? 1 : 0,
        if (search != null && search.isNotEmpty) 'search': search,
        if (coursesForYou == true) 'courses_for_you': true,
        if (startDate != null && startDate.isNotEmpty) 'start_date': startDate,
        'page': page,
        'per_page': perPage,
      },
    );
    return Map<String, dynamic>.from(res.data as Map);
  }

  // ===== Course details (user/courses/{id}) =====
  Future<Map<String, dynamic>> getCourseDetails(int courseId) async {
    final res = await dio.get('user/courses/$courseId');
    return Map<String, dynamic>.from(res.data as Map);
  }

  // ===== Toggle save =====
  Future<void> toggleSaveJob(int jobId) async {
    await dio.post('user/jobs/$jobId/toggle-save');
  }

  Future<void> toggleSaveCourse(int courseId) async {
    await dio.post('user/courses/$courseId/save');
  }

  // ===== Saved items =====
  Future<Map<String, dynamic>> getSavedItems({
    required String type,
    int page = 1,
    int perPage = 50,
  }) async {
    final res = await dio.get(
      'user/saved-items',
      queryParameters: {'type': type, 'page': page, 'per_page': perPage},
    );
    return Map<String, dynamic>.from(res.data as Map);
  }
}
