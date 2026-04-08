import '../models/home_model.dart';
import '../models/job_model.dart';
import '../models/search_result_model.dart';
import 'home_api.dart';

class HomeRepo {
  final HomeApi api;
  HomeRepo(this.api);

  Future<HomeModel> getHomeData() async {
    final json = await api.getMobileHome();
    print('\n📡 ENDPOINT: GET /mobile/home');
    print('   - Keys: ${json.keys.toList()}');

    if (json['data'] is Map) {
      final data = json['data'] as Map;
      print('   - data keys: ${data.keys.toList()}');
      print('   - featured_jobs: ${(data['featured_jobs'] is List) ? (data['featured_jobs'] as List).length : "not a list"}');
      print('   - recent_openings: ${(data['recent_openings'] is List) ? (data['recent_openings'] as List).length : "not a list"}');
      print('   - disability_jobs: ${(data['disability_jobs'] is List) ? (data['disability_jobs'] as List).length : "not a list"}');

      // 💰 AUDIT: Log raw salary fields from /mobile/home for first 3 jobs
      print('\n💰 SALARY AUDIT: /mobile/home endpoint');
      final allJobs = <Map>[];
      if (data['featured_jobs'] is List) allJobs.addAll((data['featured_jobs'] as List).cast<Map>());
      if (data['recent_openings'] is List) allJobs.addAll((data['recent_openings'] as List).cast<Map>());
      if (data['disability_jobs'] is List) allJobs.addAll((data['disability_jobs'] as List).cast<Map>());

      for (var i = 0; i < allJobs.length && i < 3; i++) {
        final job = allJobs[i];
        print('   Job #${job['id']} "${job['job_title']}" from /mobile/home:');
        print('      - formatted_salary: ${job['formatted_salary']}');
        print('      - min_salary: ${job['min_salary']}');
        print('      - max_salary: ${job['max_salary']}');
        print('      - salary_to_be_discussed: ${job['salary_to_be_discussed']}');
        print('      - company_name: ${job['company_name']}');
      }
    }
    return HomeModel.fromJson(json);
  }

  Future<JobModel> getJobDetails(int jobId) async {
    final json = await api.getJobDetails(jobId);
    // Extract job data from response (usually in json['data'])
    final jobData = json['data'] is Map<String, dynamic>
        ? (json['data'] as Map<String, dynamic>)
        : json;

    // 💰 SALARY AUDIT: Log raw salary fields from /user/jobs/{id} endpoint
    print('\n💰 SALARY AUDIT: GET /user/jobs/$jobId endpoint');
    print('   Job #$jobId "${jobData['job_title']}" from /user/jobs/{id}:');
    print('      - formatted_salary: ${jobData['formatted_salary']}');
    print('      - min_salary: ${jobData['min_salary']}');
    print('      - max_salary: ${jobData['max_salary']}');
    print('      - salary_to_be_discussed: ${jobData['salary_to_be_discussed']}');
    print('      - company_name: ${jobData['company_name'] ?? (jobData['company'] is Map ? jobData['company']['name'] : null)}');

    return JobModel.fromJson(jobData);
  }

   Future<SearchResultModel> searchJobs({
    String? keyword,
    String? locationType,
    String? jobType,
    int page = 1,
    int perPage = 10,
  }) async {
    final json = await api.searchJobs(keyword: keyword, locationType: locationType, jobType: jobType, page: page, perPage: perPage);
    print('\n📡 ENDPOINT: GET /home/search?keyword=$keyword&location_type=$locationType&job_type=$jobType&page=$page');
    print('   - Keys: ${json.keys.toList()}');

    if (json['data'] is Map) {
      final data = json['data'] as Map;
      print('   - data keys: ${data.keys.toList()}');
      print('   - data["data"] is List: ${data['data'] is List}');

      if (data['data'] is List) {
        final jobs = (data['data'] as List);
        print('   - data["data"] length: ${jobs.length}');

        // 💰 AUDIT: Log raw salary fields from /home/search for first 3 jobs
        print('\n💰 SALARY AUDIT: /home/search endpoint');
        for (var i = 0; i < jobs.length && i < 3; i++) {
          final job = jobs[i] is Map ? jobs[i] as Map : null;
          if (job != null) {
            print('   Job #${job['id']} "${job['job_title']}" from /home/search:');
            print('      - formatted_salary: ${job['formatted_salary']}');
            print('      - min_salary: ${job['min_salary']}');
            print('      - max_salary: ${job['max_salary']}');
            print('      - salary_to_be_discussed: ${job['salary_to_be_discussed']}');
            print('      - company_name: ${job['company_name']}');
          }
        }
      }

      if (data['pagination'] is Map) {
        print('   - pagination: ${data['pagination']}');
      }
    }
    return SearchResultModel.fromJson(json);
  }

  Future<void> toggleSaveJob(int jobId) => api.toggleSaveJob(jobId);

  Future<void> toggleSaveCourse(int courseId) => api.toggleSaveCourse(courseId);

  /// Remove a saved item (job or course) by toggling its save state.
  Future<void> removeSavedItem({required String type, required int id}) async {
    if (type == 'courses') {
      await api.toggleSaveCourse(id);
    } else {
      await api.toggleSaveJob(id);
    }
  }

  Future<Map<String, dynamic>> getSavedItems({
    required String type,
    int page = 1,
    int perPage = 50,
  }) async {
    final json = await api.getSavedItems(type: type, page: page, perPage: perPage);

    print('\n📡 ENDPOINT: GET /user/saved-items?type=$type&page=$page');
    if (json['data'] is Map) {
      final data = json['data'] as Map;
      if (data['data'] is List) {
        final items = (data['data'] as List);
        print('   - Saved items count: ${items.length}');

        // 💰 AUDIT: Log raw salary fields from /user/saved-items for first 3 items
        if (type == 'jobs') {
          print('\n💰 SALARY AUDIT: /user/saved-items?type=jobs endpoint');
          for (var i = 0; i < items.length && i < 3; i++) {
            final item = items[i] is Map ? items[i] as Map : null;
            if (item != null) {
              // Saved items may nest job data under 'job', 'opening', or 'item'
              final job = item['job'] ?? item['opening'] ?? item['item'] ?? item;
              final jobId = job['id'] ?? item['id'];
              final jobTitle = job['job_title'] ?? item['job_title'];

              print('   Job #$jobId "$jobTitle" from /user/saved-items:');
              print('      - formatted_salary: ${job['formatted_salary']}');
              print('      - min_salary: ${job['min_salary']}');
              print('      - max_salary: ${job['max_salary']}');
              print('      - salary_to_be_discussed: ${job['salary_to_be_discussed']}');
              print('      - company_name: ${job['company_name'] ?? item['company_name']}');
            }
          }
        }
      }
    }

    return json;
  }
}
