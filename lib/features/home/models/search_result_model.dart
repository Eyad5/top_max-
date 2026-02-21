import 'job_model.dart';

class SearchResultModel {
  final List<JobModel> jobs;
  final int total;
  final int perPage;
  final int currentPage;
  final int lastPage;
  final bool hasMorePages;

  const SearchResultModel({
    required this.jobs,
    required this.total,
    required this.perPage,
    required this.currentPage,
    required this.lastPage,
    required this.hasMorePages,
  });

  factory SearchResultModel.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] is Map<String, dynamic>)
        ? json['data'] as Map<String, dynamic>
        : <String, dynamic>{};

    final rawList = (data['data'] is List) ? data['data'] as List : const [];

    final pagination = (data['pagination'] is Map<String, dynamic>)
        ? data['pagination'] as Map<String, dynamic>
        : <String, dynamic>{};

    int toInt(dynamic v, {int fallback = 0}) {
      if (v is int) return v;
      if (v is String) return int.tryParse(v) ?? fallback;
      return fallback;
    }

    final jobs = rawList
        .whereType<Map>()
        .map((e) => JobModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    final total = toInt(pagination['total'], fallback: jobs.length);
    final perPage = toInt(pagination['per_page'], fallback: jobs.length);
    final currentPage = toInt(pagination['current_page'], fallback: 1);
    final lastPage = toInt(pagination['last_page'], fallback: 1);

    final hasMorePagesRaw = pagination['has_more_pages'];
    final hasMorePages = hasMorePagesRaw is bool
        ? hasMorePagesRaw
        : (hasMorePagesRaw is String
            ? hasMorePagesRaw.toLowerCase() == 'true'
            : currentPage < lastPage);

    return SearchResultModel(
      jobs: jobs,
      total: total,
      perPage: perPage,
      currentPage: currentPage,
      lastPage: lastPage,
      hasMorePages: hasMorePages,
    );
  }
}
