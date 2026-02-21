import 'package:equatable/equatable.dart';

abstract class SavedItemsEvent extends Equatable {
  const SavedItemsEvent();

  @override
  List<Object?> get props => [];
}

class SavedItemsLoadRequested extends SavedItemsEvent {
  final String type;

  const SavedItemsLoadRequested(this.type);

  @override
  List<Object?> get props => [type];
}

class SavedItemsNextPageRequested extends SavedItemsEvent {
  final String type;

  const SavedItemsNextPageRequested(this.type);

  @override
  List<Object?> get props => [type];
}

class SavedItemsRemoveRequested extends SavedItemsEvent {
  final String type;
  final int id;

  const SavedItemsRemoveRequested({required this.type, required this.id});

  @override
  List<Object?> get props => [type, id];
}

class SavedItemsRefreshRequested extends SavedItemsEvent {
  final String type;

  const SavedItemsRefreshRequested(this.type);

  @override
  List<Object?> get props => [type];
}
