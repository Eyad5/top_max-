import 'course_model.dart';
import 'job_model.dart';

class HomeModel {
  final List<JobModel> featuredJobs;
  final List<JobModel> recentOpenings;
  final List<JobModel> disabilityJobs;
  final List<CourseModel> coursesForYou;
  final List<JobModel> featuredJobsForYou;
  final List<JobModel> matchedJobs;

  const HomeModel({
    required this.featuredJobs,
    required this.recentOpenings,
    required this.disabilityJobs,
    required this.coursesForYou,
    required this.featuredJobsForYou,
    required this.matchedJobs,
  });

  factory HomeModel.fromJson(Map<String, dynamic> json) {
    // object داخل "data": { ... }
    final data = (json['data'] is Map<String, dynamic>)
        ? (json['data'] as Map<String, dynamic>)
        : <String, dynamic>{};

    List<T> list<T>(dynamic raw, T Function(Map<String, dynamic>) fromJson) {
      if (raw is! List) return <T>[];
      return raw
          .whereType<Map>()
          .map((e) => fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    final featuredJobs = list(data['featured_jobs'], JobModel.fromJson);
    final recentOpenings = list(data['recent_openings'], JobModel.fromJson);
    final matchedJobs = list(data['matched_jobs'], JobModel.fromJson);

    return HomeModel(
      featuredJobs: featuredJobs,
      recentOpenings: recentOpenings,
      disabilityJobs: list(data['disability_jobs'], JobModel.fromJson),
      coursesForYou: list(data['courses_for_you'], CourseModel.fromJson),
      featuredJobsForYou: list(data['featured_jobs_for_you'], JobModel.fromJson),
      matchedJobs: matchedJobs,
    );
  }

  HomeModel copyWith({
    List<JobModel>? featuredJobs,
    List<JobModel>? recentOpenings,
    List<JobModel>? disabilityJobs,
    List<CourseModel>? coursesForYou,
    List<JobModel>? featuredJobsForYou,
    List<JobModel>? matchedJobs,
  }) {
    return HomeModel(
      featuredJobs: featuredJobs ?? this.featuredJobs,
      recentOpenings: recentOpenings ?? this.recentOpenings,
      disabilityJobs: disabilityJobs ?? this.disabilityJobs,
      coursesForYou: coursesForYou ?? this.coursesForYou,
      featuredJobsForYou: featuredJobsForYou ?? this.featuredJobsForYou,
      matchedJobs: matchedJobs ?? this.matchedJobs,
    );
  }
}
