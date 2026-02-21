import 'package:equatable/equatable.dart';

enum SearchMode { jobs, courses }

abstract class SearchEvent extends Equatable {
  const SearchEvent();

  @override
  List<Object?> get props => [];
}

class SearchRequested extends SearchEvent {
  final String keyword;
  final SearchMode searchMode;

  const SearchRequested(this.keyword, {this.searchMode = SearchMode.jobs});

  @override
  List<Object?> get props => [keyword, searchMode];
}

class SearchNextPageRequested extends SearchEvent {
  const SearchNextPageRequested();
}

class SearchToggleSaveJob extends SearchEvent {
  final int jobId;

  const SearchToggleSaveJob(this.jobId);

  @override
  List<Object?> get props => [jobId];
}
