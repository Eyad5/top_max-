import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/home_repo.dart';
import 'saved_items_event.dart';
import 'saved_items_state.dart';

class SavedItemsBloc extends Bloc<SavedItemsEvent, SavedItemsState> {
  final HomeRepo repo;

  SavedItemsBloc(this.repo) : super(const SavedItemsState()) {
    on<SavedItemsLoadRequested>(_onLoad);
    on<SavedItemsNextPageRequested>(_onNextPage);
    on<SavedItemsRemoveRequested>(_onRemove);
    on<SavedItemsRefreshRequested>(_onRefresh);
  }

  Future<void> _onLoad(SavedItemsLoadRequested event, Emitter<SavedItemsState> emit) async {
    final type = event.type;
    emit(_updateLoading(type, true, clearError: true));

    try {
      final res = await repo.getSavedItems(type: type, page: 1, perPage: 12);
      final parsed = _parseResponse(res);

      final updatedItems = Map<String, List<Map<String, dynamic>>>.from(state.items);
      updatedItems[type] = parsed.items;

      final updatedPages = Map<String, int>.from(state.pages);
      updatedPages[type] = 1;

      final updatedHasMore = Map<String, bool>.from(state.hasMore);
      updatedHasMore[type] = parsed.hasMore;

      emit(state.copyWith(
        items: updatedItems,
        pages: updatedPages,
        hasMore: updatedHasMore,
        loading: _setLoading(type, false),
      ));
    } catch (e) {
      emit(_updateError(type, e.toString()));
    }
  }

  Future<void> _onNextPage(SavedItemsNextPageRequested event, Emitter<SavedItemsState> emit) async {
    final type = event.type;
    if (state.hasMore[type] != true || state.loading[type] == true) return;

    emit(_updateLoading(type, true));

    final nextPage = (state.pages[type] ?? 1) + 1;

    try {
      final res = await repo.getSavedItems(type: type, page: nextPage, perPage: 12);
      final parsed = _parseResponse(res);

      final updatedItems = Map<String, List<Map<String, dynamic>>>.from(state.items);
      updatedItems[type] = [...(state.items[type] ?? []), ...parsed.items];

      final updatedPages = Map<String, int>.from(state.pages);
      updatedPages[type] = nextPage;

      final updatedHasMore = Map<String, bool>.from(state.hasMore);
      updatedHasMore[type] = parsed.hasMore;

      emit(state.copyWith(
        items: updatedItems,
        pages: updatedPages,
        hasMore: updatedHasMore,
        loading: _setLoading(type, false),
      ));
    } catch (e) {
      emit(_updateLoading(type, false));
    }
  }

  Future<void> _onRemove(SavedItemsRemoveRequested event, Emitter<SavedItemsState> emit) async {
    final type = event.type;
    final currentItems = List<Map<String, dynamic>>.from(state.items[type] ?? []);
    final removedIndex = currentItems.indexWhere((item) {
      final id = item['id'] ?? item['job_id'] ?? item['course_id'];
      return id != null && int.tryParse(id.toString()) == event.id;
    });

    if (removedIndex == -1) return;

    final removedItem = currentItems[removedIndex];

    // Optimistic removal
    currentItems.removeAt(removedIndex);
    final updatedItems = Map<String, List<Map<String, dynamic>>>.from(state.items);
    updatedItems[type] = currentItems;
    emit(state.copyWith(items: updatedItems));

    try {
      await repo.removeSavedItem(type: type, id: event.id);
    } catch (_) {
      // Rollback
      final rollbackItems = Map<String, List<Map<String, dynamic>>>.from(state.items);
      final rollbackList = List<Map<String, dynamic>>.from(rollbackItems[type] ?? []);
      rollbackList.insert(removedIndex, removedItem);
      rollbackItems[type] = rollbackList;
      emit(state.copyWith(items: rollbackItems));
    }
  }

  Future<void> _onRefresh(SavedItemsRefreshRequested event, Emitter<SavedItemsState> emit) async {
    add(SavedItemsLoadRequested(event.type));
  }

  // Helpers
  SavedItemsState _updateLoading(String type, bool value, {bool clearError = false}) {
    final updatedLoading = Map<String, bool>.from(state.loading);
    updatedLoading[type] = value;

    if (clearError) {
      final updatedErrors = Map<String, String?>.from(state.errors);
      updatedErrors[type] = null;
      return state.copyWith(loading: updatedLoading, errors: updatedErrors);
    }
    return state.copyWith(loading: updatedLoading);
  }

  Map<String, bool> _setLoading(String type, bool value) {
    final m = Map<String, bool>.from(state.loading);
    m[type] = value;
    return m;
  }

  SavedItemsState _updateError(String type, String message) {
    final updatedErrors = Map<String, String?>.from(state.errors);
    updatedErrors[type] = message;
    return state.copyWith(
      errors: updatedErrors,
      loading: _setLoading(type, false),
    );
  }

  _ParsedPage _parseResponse(Map<String, dynamic> res) {
    final data = (res['data'] as Map?) ?? {};
    final list = (data['data'] as List?) ?? [];
    final pagination = (data['pagination'] as Map?) ?? {};
    final hasMore = pagination['has_more_pages'] == true;
    final items = list
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    return _ParsedPage(items: items, hasMore: hasMore && items.isNotEmpty);
  }
}

class _ParsedPage {
  final List<Map<String, dynamic>> items;
  final bool hasMore;
  const _ParsedPage({required this.items, required this.hasMore});
}
