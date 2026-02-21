import 'package:equatable/equatable.dart';
import '../models/job_model.dart';
import 'search_event.dart';

abstract class SearchState extends Equatable {
  const SearchState();

  @override
  List<Object?> get props => [];
}

class SearchInitial extends SearchState {
  const SearchInitial();
}

class SearchLoading extends SearchState {
  const SearchLoading();
}

class SearchLoaded extends SearchState {
  final List<JobModel> jobs;
  final String keyword;
  final SearchMode searchMode;
  final int currentPage;
  final bool hasMore;
  final bool isLoadingMore;
  final Set<int> savedJobIds;

  const SearchLoaded({
    required this.jobs,
    required this.keyword,
    required this.searchMode,
    required this.currentPage,
    required this.hasMore,
    this.isLoadingMore = false,
    this.savedJobIds = const {},
  });

  SearchLoaded copyWith({
    List<JobModel>? jobs,
    String? keyword,
    SearchMode? searchMode,
    int? currentPage,
    bool? hasMore,
    bool? isLoadingMore,
    Set<int>? savedJobIds,
  }) {
    return SearchLoaded(
      jobs: jobs ?? this.jobs,
      keyword: keyword ?? this.keyword,
      searchMode: searchMode ?? this.searchMode,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      savedJobIds: savedJobIds ?? this.savedJobIds,
    );
  }

  @override
  List<Object?> get props => [jobs, keyword, searchMode, currentPage, hasMore, isLoadingMore, savedJobIds];
}

class SearchError extends SearchState {
  final String message;
  final String keyword;

  const SearchError({required this.message, required this.keyword});

  @override
  List<Object?> get props => [message, keyword];
}
