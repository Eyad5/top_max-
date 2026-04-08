import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/saved_items_bloc.dart';
import '../bloc/saved_items_event.dart';
import '../bloc/saved_items_state.dart';
import '../models/job_model.dart';
import '../models/course_model.dart';

/// Saved Items (Bookmarks) page with real API integration
/// Uses SavedItemsBloc to load jobs and courses from backend
class SavedItemsPage extends StatefulWidget {
  final VoidCallback? onBackToHome;

  const SavedItemsPage({super.key, this.onBackToHome});

  @override
  State<SavedItemsPage> createState() => _SavedItemsPageState();
}

class _SavedItemsPageState extends State<SavedItemsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // ❌ REMOVED: Duplicate loading in initState
    // Reason: app_shell.dart refresh() already loads items when navigating to this tab
    // This was causing double API calls (4 total: 2 in initState + 2 in refresh)
    // _loadSavedItems();
  }

  // ❌ REMOVED: Unused method
  // void _loadSavedItems() {
  //   final bloc = context.read<SavedItemsBloc>();
  //   bloc.add(const SavedItemsLoadRequested('jobs'));
  //   bloc.add(const SavedItemsLoadRequested('courses'));
  // }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // AppBar with back button and title
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                const SizedBox(height: 16),
                // Back button + Title
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 48,
                        height: 48,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () async {
                              final didPop = await Navigator.of(context).maybePop();
                              if (!didPop && widget.onBackToHome != null) {
                                widget.onBackToHome!();
                              }
                            },
                            customBorder: const CircleBorder(),
                            child: Container(
                              margin: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFF9AA3B2),
                                  width: 1.8,
                                ),
                              ),
                              child: const Icon(
                                Icons.chevron_left,
                                color: Color(0xFF111827),
                                size: 28,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const Expanded(
                        child: Center(
                          child: Text(
                            'Bookmarks',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Tabs
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    padding: EdgeInsets.zero,
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicatorPadding: EdgeInsets.zero,
                    labelPadding: EdgeInsets.zero,
                    indicator: const BoxDecoration(color: Color(0xFF2563EB)),
                    labelColor: Colors.white,
                    unselectedLabelColor: const Color(0xFF2563EB),
                    labelStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                    tabs: const [
                      Tab(
                        child: SizedBox.expand(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.work_outline, size: 20),
                              SizedBox(width: 8),
                              Text('Saved Jobs'),
                            ],
                          ),
                        ),
                      ),
                      Tab(
                        child: SizedBox.expand(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.school_outlined, size: 20),
                              SizedBox(width: 8),
                              Text('Saved Courses'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: BlocBuilder<SavedItemsBloc, SavedItemsState>(
              builder: (context, state) {
                return TabBarView(
                  controller: _tabController,
                  children: [
                    // Saved Jobs Tab
                    _SavedJobsTab(state: state),

                    // Saved Courses Tab
                    _SavedCoursesTab(state: state),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Saved Jobs Tab Content
class _SavedJobsTab extends StatelessWidget {
  final SavedItemsState state;

  const _SavedJobsTab({required this.state});

  @override
  Widget build(BuildContext context) {
    final isLoading = state.loading['jobs'] == true;
    final error = state.errors['jobs'];
    final rawJobs = state.items['jobs'] ?? [];

    // Show loading on first load
    if (isLoading && rawJobs.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // Show error if no data
    if (error != null && rawJobs.isEmpty) {
      return _ErrorView(
        message: error,
        onRetry: () {
          context.read<SavedItemsBloc>().add(const SavedItemsLoadRequested('jobs'));
        },
      );
    }

    // Show empty state
    if (rawJobs.isEmpty) {
      return const _EmptyState(
        icon: Icons.work_outline,
        message: 'No saved jobs yet',
      );
    }

    // Parse jobs from raw data
    final jobs = rawJobs.map((json) => JobModel.fromJson(json)).toList();

    return RefreshIndicator(
      onRefresh: () async {
        context.read<SavedItemsBloc>().add(const SavedItemsRefreshRequested('jobs'));
      },
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: jobs.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final job = jobs[index];
          return _JobCard(job: job);
        },
      ),
    );
  }
}

/// Saved Courses Tab Content
class _SavedCoursesTab extends StatelessWidget {
  final SavedItemsState state;

  const _SavedCoursesTab({required this.state});

  @override
  Widget build(BuildContext context) {
    final isLoading = state.loading['courses'] == true;
    final error = state.errors['courses'];
    final rawCourses = state.items['courses'] ?? [];

    // Show loading on first load
    if (isLoading && rawCourses.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // Show error if no data
    if (error != null && rawCourses.isEmpty) {
      return _ErrorView(
        message: error,
        onRetry: () {
          context.read<SavedItemsBloc>().add(const SavedItemsLoadRequested('courses'));
        },
      );
    }

    // Show empty state
    if (rawCourses.isEmpty) {
      return const _EmptyState(
        icon: Icons.school_outlined,
        message: 'No saved courses yet',
      );
    }

    // Parse courses from raw data
    final courses = rawCourses.map((json) => CourseModel.fromJson(json)).toList();

    return RefreshIndicator(
      onRefresh: () async {
        context.read<SavedItemsBloc>().add(const SavedItemsRefreshRequested('courses'));
      },
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: courses.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final course = courses[index];
          return _CourseCard(course: course);
        },
      ),
    );
  }
}

/// Job card widget matching Figma design exactly
class _JobCard extends StatelessWidget {
  final JobModel job;

  const _JobCard({required this.job});

  @override
  Widget build(BuildContext context) {
    // 🔖 DEBUG: Saved Items page card rendering
    print('\n🔖 SavedItems _JobCard job #${job.id}:');
    print('   salaryDisplayResolved: ${job.salaryDisplayResolved} ← USED IN UI');
    print('   formattedSalary: ${job.formattedSalary}');
    print('   minSalary: ${job.minSalary}, maxSalary: ${job.maxSalary}');

    // Determine status badge (based on app_status or default to "Saved")
    final status = job.appStatus ?? 'Saved';
    final Color statusColor;
    final Color statusTextColor;

    // Map status to colors (matching original design)
    switch (status.toLowerCase()) {
      case 'new':
        statusColor = const Color(0xFFE8E9FF);
        statusTextColor = const Color(0xFF5B5FC7);
        break;
      case 'applied':
        statusColor = const Color(0xFFFEE2E2);
        statusTextColor = const Color(0xFF991B1B);
        break;
      default:
        statusColor = const Color(0xFFE8E9FF);
        statusTextColor = const Color(0xFF5B5FC7);
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F4FD),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE3EAF8), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: Status badge + Bookmark icon
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: statusTextColor,
                  ),
                ),
              ),
              const Spacer(),

              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  // Remove from saved items
                  context.read<SavedItemsBloc>().add(
                    SavedItemsRemoveRequested(type: 'jobs', id: job.id),
                  );
                },
                child: const Icon(
                  Icons.bookmark,
                  color: Color(0xFF2563EB),
                  size: 24,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Job Title
          Text(
            job.jobTitle,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
              height: 1.15,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 10),

          // Company Name
          if (job.companyName != null)
            Text(
              job.companyName!,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

          const SizedBox(height: 8),

          // Location
          if (job.officeLocation != null)
            Text(
              job.officeLocation!,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

          const SizedBox(height: 16),

          // Pills row: Salary + Job Type + Location Type
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // ✅ UNIFIED: Use salaryDisplayResolved (same as Home and Search Results)
              if (job.salaryDisplayResolved != null)
                _Pill(text: job.salaryDisplayResolved!),
              if (job.jobType != null)
                _Pill(text: _formatJobType(job.jobType!)),
              if (job.locationPriority != null)
                _Pill(text: _formatLocationType(job.locationPriority!)),
            ],
          ),

          const SizedBox(height: 12),

          // Active since date
          if (job.activeSince != null)
            Text(
              job.activeSince!,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF6B7280),
              ),
            ),
        ],
      ),
    );
  }

  String _formatJobType(String type) {
    // Capitalize first letter of each word
    return type.split('-').map((word) =>
      word[0].toUpperCase() + word.substring(1)
    ).join(' ');
  }

  String _formatLocationType(String type) {
    // Capitalize first letter
    return type[0].toUpperCase() + type.substring(1);
  }
}

/// Course card widget matching design
class _CourseCard extends StatelessWidget {
  final CourseModel course;

  const _CourseCard({required this.course});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F4FD),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE3EAF8), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: Badge + Bookmark icon
          Row(
            children: [
              if (course.isFree == true)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Free',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF15803D),
                    ),
                  ),
                ),
              const Spacer(),

              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  // Remove from saved items
                  context.read<SavedItemsBloc>().add(
                    SavedItemsRemoveRequested(type: 'courses', id: course.id),
                  );
                },
                child: const Icon(
                  Icons.bookmark,
                  color: Color(0xFF2563EB),
                  size: 24,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Course Title
          Text(
            course.title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
              height: 1.15,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 10),

          // Category
          if (course.courseCategory != null)
            Text(
              course.courseCategory!,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

          const SizedBox(height: 16),

          // Pills row
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (course.level != null)
                _Pill(text: course.level![0].toUpperCase() + course.level!.substring(1)),
              if (course.type != null)
                _Pill(text: course.type![0].toUpperCase() + course.type!.substring(1)),
              if (course.hasCertificate == true)
                const _Pill(text: 'Certificate'),
            ],
          ),
        ],
      ),
    );
  }
}

/// White pill/chip widget matching Figma design
class _Pill extends StatelessWidget {
  final String text;

  const _Pill({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFF111827),
        ),
      ),
    );
  }
}

/// Empty state widget
class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 64,
            color: const Color(0xFF9CA3AF),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }
}

/// Error view widget
class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Color(0xFFEF4444),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
