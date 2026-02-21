import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/home_repo.dart';
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
      // TODO: Implement courses search when event.searchMode == SearchMode.courses
      // For now, only jobs search is supported
      final result = await repo.searchJobs(keyword: event.keyword, page: 1, perPage: 10);
      final savedIds = <int>{};
      for (final job in result.jobs) {
        if (job.isSaved) savedIds.add(job.id);
      }
      emit(SearchLoaded(
        jobs: result.jobs,
        keyword: event.keyword,
        searchMode: event.searchMode,
        currentPage: result.currentPage,
        hasMore: result.hasMorePages,
        savedJobIds: savedIds,
      ));
    } catch (e) {
      emit(SearchError(message: e.toString(), keyword: event.keyword));
    }
  }

  Future<void> _onNextPage(SearchNextPageRequested event, Emitter<SearchState> emit) async {
    final current = state;
    if (current is! SearchLoaded || !current.hasMore || current.isLoadingMore) return;

    emit(current.copyWith(isLoadingMore: true));

    try {
      final result = await repo.searchJobs(
        keyword: current.keyword,
        page: current.currentPage + 1,
        perPage: 10,
      );
      final updatedSavedIds = Set<int>.from(current.savedJobIds);
      for (final job in result.jobs) {
        if (job.isSaved) updatedSavedIds.add(job.id);
      }
      emit(current.copyWith(
        jobs: [...current.jobs, ...result.jobs],
        currentPage: result.currentPage,
        hasMore: result.hasMorePages,
        isLoadingMore: false,
        savedJobIds: updatedSavedIds,
      ));
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
