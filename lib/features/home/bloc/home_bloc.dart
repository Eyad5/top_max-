import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/home_repo.dart';
import '../models/home_model.dart';
import '../models/job_model.dart';
import '../models/course_model.dart';
import 'home_event.dart';
import 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final HomeRepo repo;

  HomeBloc(this.repo) : super(const HomeInitial()) {
    on<HomeLoadRequested>(_onLoad);
    on<HomeRefreshRequested>(_onRefresh);
    on<HomeToggleSaveJob>(_onToggleSaveJob);
    on<HomeToggleSaveCourse>(_onToggleSaveCourse);
  }

  Future<void> _onLoad(HomeLoadRequested event, Emitter<HomeState> emit) async {
    emit(const HomeLoading());
    try {
      print('\n🔵 HomeBloc: Fetching /mobile/home...');
      final data = await repo.getHomeData();

      print('🔵 HomeBloc: Parsed HomeModel:');
      print('   - Featured Jobs: ${data.featuredJobs.length}');
      print('   - Recent Openings: ${data.recentOpenings.length}');
      print('   - Disability Jobs: ${data.disabilityJobs.length}');
      print('   - Courses For You: ${data.coursesForYou.length}');
      print('   - Featured Jobs For You: ${data.featuredJobsForYou.length}');
      print('   - Matched Jobs: ${data.matchedJobs.length}');
      print('   - TOTAL ITEMS: ${data.featuredJobs.length + data.recentOpenings.length + data.disabilityJobs.length + data.coursesForYou.length + data.featuredJobsForYou.length + data.matchedJobs.length}');

      emit(HomeLoaded(data));
      print('🔵 HomeBloc: Emitted HomeLoaded state\n');

      // Hydrate missing salaries in background
      await _hydrateMissingSalaries(data, emit);
    } catch (e) {
      print('🔴 HomeBloc ERROR: $e');
      emit(HomeError(e.toString()));
    }
  }

  Future<void> _onRefresh(HomeRefreshRequested event, Emitter<HomeState> emit) async {
    print('\n🔄 HOME REFRESH triggered');
    try {
      final data = await repo.getHomeData();
      emit(HomeLoaded(data));

      // ❌ REMOVED: Salary hydration on refresh
      // Reason: Prevents excessive API calls when navigating between tabs
      // Salary hydration should only run on initial load, not on every refresh
      // await _hydrateMissingSalaries(data, emit);

      print('   ✅ Home refresh complete (no salary hydration on refresh)');
    } catch (e) {
      print('   ❌ Home refresh failed: $e');
      emit(HomeError(e.toString()));
    }
  }

  /// Hydrate salary data for jobs that are missing min_salary/max_salary
  /// Limited to max 10 jobs to prevent API rate limiting
  Future<void> _hydrateMissingSalaries(HomeModel homeData, Emitter<HomeState> emit) async {
    // Collect all jobs from all lists
    final allJobs = [
      ...homeData.featuredJobs,
      ...homeData.recentOpenings,
      ...homeData.disabilityJobs,
      ...homeData.featuredJobsForYou,
      ...homeData.matchedJobs,
    ];

    // Find jobs with missing salary (salaryDisplayResolved returns null)
    final jobsNeedingSalary = allJobs
        .where((job) => job.salaryDisplayResolved == null)
        .take(10) // ⚠️ LIMIT: Max 10 jobs to prevent 429 rate limiting
        .toList();

    if (jobsNeedingSalary.isEmpty) {
      print('✅ All jobs have salary data');
      return;
    }

    print('💰 Hydrating salaries for ${jobsNeedingSalary.length} jobs (max 10 to avoid rate limits)...');

    // Fetch job details with concurrency limit of 4
    final Map<int, JobModel> salaryData = {};

    for (int i = 0; i < jobsNeedingSalary.length; i += 4) {
      final batch = jobsNeedingSalary.skip(i).take(4).toList();
      final futures = batch.map((job) => _fetchJobSalary(job.id)).toList();
      final results = await Future.wait(futures);

      for (var result in results) {
        if (result != null) {
          salaryData[result.id] = result;
        }
      }
    }

    if (salaryData.isEmpty) {
      print('⚠️ No salary data fetched');
      return;
    }

    // Merge salary data into existing jobs
    final updatedData = _mergeSalaryData(homeData, salaryData);

    // Emit updated state
    emit(HomeLoaded(updatedData));

    print('✅ Salary hydration complete: ${salaryData.length}/${jobsNeedingSalary.length} jobs updated');
  }

  /// Fetch job details to get salary information
  Future<JobModel?> _fetchJobSalary(int jobId) async {
    try {
      final details = await repo.getJobDetails(jobId);
      print('   ✓ Fetched salary for job #$jobId: ${details.salaryDisplayResolved ?? "still null"}');
      return details;
    } catch (e) {
      print('   ✗ Failed to fetch salary for job #$jobId: $e');
      return null;
    }
  }

  /// Merge enriched job details into home data jobs using full model replacement.
  /// Preserves isSaved from original home data since details endpoint may not include it.
  HomeModel _mergeSalaryData(HomeModel homeData, Map<int, JobModel> salaryData) {
    JobModel mergeJob(JobModel job) {
      if (!salaryData.containsKey(job.id)) return job;
      final details = salaryData[job.id]!;
      // Full replacement: use the richer details model, but preserve isSaved from home data
      return details.copyWith(isSaved: job.isSaved);
    }

    return homeData.copyWith(
      featuredJobs: homeData.featuredJobs.map(mergeJob).toList(),
      recentOpenings: homeData.recentOpenings.map(mergeJob).toList(),
      disabilityJobs: homeData.disabilityJobs.map(mergeJob).toList(),
      featuredJobsForYou: homeData.featuredJobsForYou.map(mergeJob).toList(),
      matchedJobs: homeData.matchedJobs.map(mergeJob).toList(),
    );
  }

  Future<void> _onToggleSaveJob(HomeToggleSaveJob event, Emitter<HomeState> emit) async {
    final currentState = state;
    if (currentState is! HomeLoaded) return;

    final job = _findJob(currentState.homeData, event.jobId);
    final wasSaved = job?.isSaved ?? false;

    print('\n💾 TOGGLE SAVE JOB #${event.jobId}: ${wasSaved ? "UNSAVE" : "SAVE"}');

    // Optimistic update
    final updatedData = currentState.homeData.copyWith(
      disabilityJobs: currentState.homeData.disabilityJobs
          .map((j) => j.id == event.jobId ? j.copyWith(isSaved: !j.isSaved) : j)
          .toList(),
      featuredJobs: currentState.homeData.featuredJobs
          .map((j) => j.id == event.jobId ? j.copyWith(isSaved: !j.isSaved) : j)
          .toList(),
      recentOpenings: currentState.homeData.recentOpenings
          .map((j) => j.id == event.jobId ? j.copyWith(isSaved: !j.isSaved) : j)
          .toList(),
      featuredJobsForYou: currentState.homeData.featuredJobsForYou
          .map((j) => j.id == event.jobId ? j.copyWith(isSaved: !j.isSaved) : j)
          .toList(),
      matchedJobs: currentState.homeData.matchedJobs
          .map((j) => j.id == event.jobId ? j.copyWith(isSaved: !j.isSaved) : j)
          .toList(),
    );
    emit(HomeLoaded(updatedData));

    // Call API
    try {
      await repo.toggleSaveJob(event.jobId);
      print('   ✅ Toggle save API succeeded for job #${event.jobId}');
    } catch (e) {
      final errorMsg = e.toString();
      print('   ❌ Toggle save API failed for job #${event.jobId}: $errorMsg');

      // Check if it's a 429 rate limit error
      if (errorMsg.contains('429') || errorMsg.toLowerCase().contains('too many')) {
        print('   ⚠️  429 RATE LIMIT - Rolling back optimistic state');
      }

      // Rollback on error
      emit(currentState);
    }
  }

  // Helper to find job across all lists
  JobModel? _findJob(HomeModel data, int jobId) {
    return [
      ...data.featuredJobs,
      ...data.recentOpenings,
      ...data.disabilityJobs,
      ...data.featuredJobsForYou,
      ...data.matchedJobs,
    ].cast<JobModel?>().firstWhere((j) => j?.id == jobId, orElse: () => null);
  }

  Future<void> _onToggleSaveCourse(HomeToggleSaveCourse event, Emitter<HomeState> emit) async {
    final currentState = state;
    if (currentState is! HomeLoaded) return;

    final course = currentState.homeData.coursesForYou
        .cast<CourseModel?>()
        .firstWhere((c) => c?.id == event.courseId, orElse: () => null);
    final wasSaved = course?.isSaved ?? false;

    print('\n💾 TOGGLE SAVE COURSE #${event.courseId}: ${wasSaved ? "UNSAVE" : "SAVE"}');

    // Optimistic update - toggle isSaved for the course
    final updatedData = currentState.homeData.copyWith(
      coursesForYou: currentState.homeData.coursesForYou
          .map((c) => c.id == event.courseId ? c.copyWith(isSaved: !c.isSaved) : c)
          .toList(),
    );
    emit(HomeLoaded(updatedData));

    // Call API
    try {
      await repo.toggleSaveCourse(event.courseId);
      print('   ✅ Toggle save API succeeded for course #${event.courseId}');
    } catch (e) {
      final errorMsg = e.toString();
      print('   ❌ Toggle save API failed for course #${event.courseId}: $errorMsg');

      // Check if it's a 429 rate limit error
      if (errorMsg.contains('429') || errorMsg.toLowerCase().contains('too many')) {
        print('   ⚠️  429 RATE LIMIT - Rolling back optimistic state');
      }

      // Rollback on error
      emit(currentState);
    }
  }
}
