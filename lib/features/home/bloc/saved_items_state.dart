import 'package:equatable/equatable.dart';

class SavedItemsState extends Equatable {
  final Map<String, List<Map<String, dynamic>>> items;
  final Map<String, bool> loading;
  final Map<String, String?> errors;
  final Map<String, int> pages;
  final Map<String, bool> hasMore;

  const SavedItemsState({
    this.items = const {'jobs': [], 'courses': []},
    this.loading = const {'jobs': false, 'courses': false},
    this.errors = const {'jobs': null, 'courses': null},
    this.pages = const {'jobs': 1, 'courses': 1},
    this.hasMore = const {'jobs': true, 'courses': true},
  });

  SavedItemsState copyWith({
    Map<String, List<Map<String, dynamic>>>? items,
    Map<String, bool>? loading,
    Map<String, String?>? errors,
    Map<String, int>? pages,
    Map<String, bool>? hasMore,
  }) {
    return SavedItemsState(
      items: items ?? this.items,
      loading: loading ?? this.loading,
      errors: errors ?? this.errors,
      pages: pages ?? this.pages,
      hasMore: hasMore ?? this.hasMore,
    );
  }

  @override
  List<Object?> get props => [items, loading, errors, pages, hasMore];
}
