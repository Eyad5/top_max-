import '../models/home_model.dart';
import '../models/job_model.dart';
import '../models/search_result_model.dart';
import 'home_api.dart';

class HomeRepo {
  final HomeApi api;
  HomeRepo(this.api);

  Future<HomeModel> getHomeData() async {
    final json = await api.getMobileHome();
    return HomeModel.fromJson(json);
  }

  Future<JobModel> getJobDetails(int jobId) async {
    final json = await api.getJobDetails(jobId);
    // Extract job data from response (usually in json['data'])
    final jobData = json['data'] is Map<String, dynamic>
        ? (json['data'] as Map<String, dynamic>)
        : json;
    return JobModel.fromJson(jobData);
  }

   Future<SearchResultModel> searchJobs({
    String? keyword,
    int page = 1,
    int perPage = 10,
  }) async {
    final json = await api.searchJobs(keyword: keyword, page: page, perPage: perPage);
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
  }) =>
      api.getSavedItems(type: type, page: page, perPage: perPage);
}
