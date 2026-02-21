import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/home_repo.dart';
import '../models/home_model.dart';
import '../models/job_model.dart';
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
      final data = await repo.getHomeData();
      emit(HomeLoaded(data));

      // Hydrate missing salaries in background
      await _hydrateMissingSalaries(data, emit);
    } catch (e) {
      emit(HomeError(e.toString()));
    }
  }

  Future<void> _onRefresh(HomeRefreshRequested event, Emitter<HomeState> emit) async {
    try {
      final data = await repo.getHomeData();
      emit(HomeLoaded(data));

      // Hydrate missing salaries in background
      await _hydrateMissingSalaries(data, emit);
    } catch (e) {
      emit(HomeError(e.toString()));
    }
  }

  /// Hydrate salary data for jobs that are missing min_salary/max_salary
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
        .toList();

    if (jobsNeedingSalary.isEmpty) {
      print('✅ All jobs have salary data');
      return;
    }

    print('💰 Hydrating salaries for ${jobsNeedingSalary.length} jobs...');

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

  /// Merge salary data from details into home data jobs
  HomeModel _mergeSalaryData(HomeModel homeData, Map<int, JobModel> salaryData) {
    JobModel mergeJob(JobModel job) {
      if (!salaryData.containsKey(job.id)) return job;
      final details = salaryData[job.id]!;
      return job.copyWithSalary(
        minSalary: details.minSalary,
        maxSalary: details.maxSalary,
        salaryToBeDiscussed: details.salaryToBeDiscussed,
        formattedSalary: details.formattedSalary,
      );
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
    );
    emit(HomeLoaded(updatedData));

    // Call API
    try {
      await repo.toggleSaveJob(event.jobId);
    } catch (e) {
      // Rollback on error
      emit(currentState);
    }
  }

  Future<void> _onToggleSaveCourse(HomeToggleSaveCourse event, Emitter<HomeState> emit) async {
    final currentState = state;
    if (currentState is! HomeLoaded) return;

    // Call API (courses don't have isSaved field in the model, so we just call the API)
    try {
      await repo.toggleSaveCourse(event.courseId);
    } catch (e) {
      // Ignore error silently or show a snackbar
    }
  }
}
