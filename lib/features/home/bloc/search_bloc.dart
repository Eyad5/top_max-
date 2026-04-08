import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/home_repo.dart';
import '../models/job_model.dart';
import 'search_event.dart';
import 'search_state.dart';

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final HomeRepo repo;

  SearchBloc(this.repo) : super(const SearchInitial()) {
    on<SearchRequested>(_onSearch);
    on<SearchNextPageRequested>(_onNextPage);
    on<SearchToggleSaveJob>(_onToggleSave);
  }

  Future<void> _onSearch(SearchRequested event, Emitter<SearchState> emit) async {
    emit(const SearchLoading());
    try {
      print('\n🟢 SearchBloc: Searching for "${event.keyword}" (mode: ${event.searchMode})...');
      print('   📤 API Request: /home/search?keyword=${event.keyword}&location_type=${event.locationType}&job_type=${event.jobType}&page=1&per_page=10');

      // TODO: Implement courses search when event.searchMode == SearchMode.courses
      // For now, only jobs search is supported
      final result = await repo.searchJobs(
        keyword: event.keyword.isEmpty ? null : event.keyword,
        locationType: event.locationType,
        jobType: event.jobType,
        page: 1,
        perPage: 10,
      );

      print('🟢 SearchBloc: Parsed SearchResultModel:');
      print('   - Jobs found: ${result.jobs.length}');
      print('   - Total: ${result.total}');
      print('   - Current page: ${result.currentPage}');
      print('   - Last page: ${result.lastPage}');
      print('   - Has more: ${result.hasMorePages}');

      final savedIds = <int>{};
      for (final job in result.jobs) {
        if (job.isSaved) savedIds.add(job.id);
      }

      // Emit initial state with partial data
      emit(SearchLoaded(
        jobs: result.jobs,
        keyword: event.keyword,
        searchMode: event.searchMode,
        currentPage: result.currentPage,
        hasMore: result.hasMorePages,
        savedJobIds: savedIds,
        locationType: event.locationType,
        jobType: event.jobType,
      ));
      print('🟢 SearchBloc: Emitted SearchLoaded state with ${result.jobs.length} jobs (partial data)\n');

      // Enrich search results with full job details
      await _enrichSearchResults(result.jobs, emit, event.keyword, event.searchMode, result.currentPage, result.hasMorePages, savedIds, event.locationType, event.jobType);
    } catch (e) {
      print('🔴 SearchBloc ERROR: $e');
      emit(SearchError(
        message: e.toString(),
        keyword: event.keyword,
        searchMode: event.searchMode,
        locationType: event.locationType,
        jobType: event.jobType,
      ));
    }
  }

  /// Enrich search results by fetching full job details for jobs missing rich fields
  Future<void> _enrichSearchResults(
    List<dynamic> jobs,
    Emitter<SearchState> emit,
    String keyword,
    dynamic searchMode,
    int currentPage,
    bool hasMore,
    Set<int> savedIds,
    String? locationType,
    String? jobType,
  ) async {
    // Check which jobs need enrichment (missing companyName or other key fields)
    final jobsNeedingEnrichment = jobs.where((job) =>
      job.companyName == null ||
      job.officeLocation == null ||
      job.formattedSalary == null
    ).toList();

    if (jobsNeedingEnrichment.isEmpty) {
      print('✅ All search results already have full data');
      return;
    }

    print('💎 Enriching ${jobsNeedingEnrichment.length}/${jobs.length} search results with full job details...');

    // Fetch full details with concurrency limit of 3
    final Map<int, dynamic> enrichedData = {};

    for (int i = 0; i < jobsNeedingEnrichment.length; i += 3) {
      final batch = jobsNeedingEnrichment.skip(i).take(3).toList();
      final futures = batch.map((job) => _fetchJobDetails(job.id)).toList();
      final results = await Future.wait(futures);

      for (var result in results) {
        if (result != null) {
          enrichedData[result.id] = result;
        }
      }
    }

    if (enrichedData.isEmpty) {
      print('⚠️ No enriched data fetched');
      return;
    }

    // Merge enriched data into search results
    final enrichedJobs = jobs.map<JobModel>((job) {
      if (!enrichedData.containsKey(job.id)) return job as JobModel;
      final details = enrichedData[job.id] as JobModel;

      print('   ✓ Enriched job #${job.id}:');
      print('      companyName: "${details.companyName}"');
      print('      officeLocation: "${details.officeLocation}"');
      print('      formattedSalary: "${details.formattedSalary}"');
      print('      salaryDisplayResolved: "${details.salaryDisplayResolved}"');
      print('      minSalary: ${details.minSalary}, maxSalary: ${details.maxSalary}');
      print('      salaryToBeDiscussed: ${details.salaryToBeDiscussed}');

      // Return the full detailed job model
      return details;
    }).toList();

    // Emit updated state with enriched data
    emit(SearchLoaded(
      jobs: enrichedJobs,
      keyword: keyword,
      searchMode: searchMode,
      currentPage: currentPage,
      hasMore: hasMore,
      savedJobIds: savedIds,
      locationType: locationType,
      jobType: jobType,
    ));

    print('✅ Search result enrichment complete: ${enrichedData.length}/${jobsNeedingEnrichment.length} jobs enriched\n');
  }

  /// Fetch full job details for enrichment
  Future<dynamic> _fetchJobDetails(int jobId) async {
    try {
      final details = await repo.getJobDetails(jobId);
      return details;
    } catch (e) {
      print('   ✗ Failed to fetch details for job #$jobId: $e');
      return null;
    }
  }

  Future<void> _onNextPage(SearchNextPageRequested event, Emitter<SearchState> emit) async {
    final current = state;
    if (current is! SearchLoaded || !current.hasMore || current.isLoadingMore) return;

    emit(current.copyWith(isLoadingMore: true));

    try {
      final result = await repo.searchJobs(
        keyword: current.keyword.isEmpty ? null : current.keyword,
        locationType: current.locationType,
        jobType: current.jobType,
        page: current.currentPage + 1,
        perPage: 10,
      );
      final updatedSavedIds = Set<int>.from(current.savedJobIds);
      for (final job in result.jobs) {
        if (job.isSaved) updatedSavedIds.add(job.id);
      }

      // Emit with partial data first
      final combinedJobs = [...current.jobs, ...result.jobs];
      emit(current.copyWith(
        jobs: combinedJobs,
        currentPage: result.currentPage,
        hasMore: result.hasMorePages,
        isLoadingMore: false,
        savedJobIds: updatedSavedIds,
      ));

      // Then enrich the new jobs in background
      await _enrichSearchResults(
        combinedJobs,
        emit,
        current.keyword,
        current.searchMode,
        result.currentPage,
        result.hasMorePages,
        updatedSavedIds,
        current.locationType,
        current.jobType,
      );
    } catch (e) {
      emit(current.copyWith(isLoadingMore: false));
    }
  }

  Future<void> _onToggleSave(SearchToggleSaveJob event, Emitter<SearchState> emit) async {
    final current = state;
    if (current is! SearchLoaded) return;

    final wasSaved = current.savedJobIds.contains(event.jobId);
    final updatedIds = Set<int>.from(current.savedJobIds);

    // Optimistic UI
    if (wasSaved) {
      updatedIds.remove(event.jobId);
    } else {
      updatedIds.add(event.jobId);
    }
    emit(current.copyWith(savedJobIds: updatedIds));

    try {
      await repo.toggleSaveJob(event.jobId);
    } catch (_) {
      // Rollback
      final rollbackIds = Set<int>.from(updatedIds);
      if (wasSaved) {
        rollbackIds.add(event.jobId);
      } else {
        rollbackIds.remove(event.jobId);
      }
      if (state is SearchLoaded) {
        emit((state as SearchLoaded).copyWith(savedJobIds: rollbackIds));
      }
    }
  }
}
