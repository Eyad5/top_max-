import 'package:equatable/equatable.dart';

abstract class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object?> get props => [];
}

class HomeLoadRequested extends HomeEvent {
  const HomeLoadRequested();
}

class HomeRefreshRequested extends HomeEvent {
  const HomeRefreshRequested();
}

class HomeToggleSaveJob extends HomeEvent {
  final int jobId;
  const HomeToggleSaveJob(this.jobId);

  @override
  List<Object?> get props => [jobId];
}

class HomeToggleSaveCourse extends HomeEvent {
  final int courseId;
  const HomeToggleSaveCourse(this.courseId);

  @override
  List<Object?> get props => [courseId];
}
