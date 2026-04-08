import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/search_bloc.dart';
import '../bloc/search_event.dart';
import '../bloc/search_state.dart';
import '../models/job_model.dart';

/// Search Results page with real API integration via SearchBloc
class SearchResultsPage extends StatefulWidget {
  final String keyword;
  final SearchMode searchMode;
  final String? locationType;
  final String? jobType;

  const SearchResultsPage({
    super.key,
    required this.keyword,
    this.searchMode = SearchMode.jobs,
    this.locationType,
    this.jobType,
  });

  @override
  State<SearchResultsPage> createState() => _SearchResultsPageState();
}

class _SearchResultsPageState extends State<SearchResultsPage> {
  @override
  void initState() {
    super.initState();
    // Trigger search when page loads
    context.read<SearchBloc>().add(SearchRequested(
      widget.keyword,
      searchMode: widget.searchMode,
      locationType: widget.locationType,
      jobType: widget.jobType,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return _SearchResultsView(searchMode: widget.searchMode);
  }
}

class _SearchResultsView extends StatefulWidget {
  final SearchMode searchMode;

  const _SearchResultsView({required this.searchMode});

  @override
  State<_SearchResultsView> createState() => _SearchResultsViewState();
}

class _SearchResultsViewState extends State<_SearchResultsView> {
  late SearchMode _searchMode;

  @override
  void initState() {
    super.initState();
    _searchMode = widget.searchMode;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SearchBloc, SearchState>(
      builder: (context, state) {
        return Scaffold(
          body: Stack(
            children: [
              // Background gradient (light blue to white)
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.center,
                      colors: [
                        Color(0xFFD0E3FF), // Light blue top
                        Color(0xFFFFFFFF), // White bottom
                      ],
                    ),
                  ),
                ),
              ),

              SafeArea(
                child: Column(
                  children: [
                    const SizedBox(height: 16),

                    // Search Bar with back button
                    _buildSearchBar(context),

                    const SizedBox(height: 16),

                    // Filter chips row
                    _buildFilterChipsRow(),

                    const SizedBox(height: 12),

                    // White container with rounded top corners
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(36),
                            topRight: Radius.circular(36),
                          ),
                        ),
                        child: _buildResults(context, state),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Bottom Navigation - matching AppShell design
          bottomNavigationBar: _buildBottomNav(context),
        );
      },
    );
  }

  Widget _buildResults(BuildContext context, SearchState state) {
    // Loading state
    if (state is SearchLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // Error state
    if (state is SearchError) {
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
                state.message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  context.read<SearchBloc>().add(SearchRequested(
                    state.keyword,
                    searchMode: state.searchMode ?? _searchMode,
                    locationType: state.locationType,
                    jobType: state.jobType,
                  ));
                },
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

    // Loaded state with results
    if (state is SearchLoaded) {
      final jobs = state.jobs;
      print('\n📋 _buildResults: SearchLoaded state');
      print('   - jobs.length: ${jobs.length}');
      print('   - keyword: "${state.keyword}"');
      print('   - savedJobIds: ${state.savedJobIds}');

      if (jobs.isEmpty) {
        return const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.search_off,
                size: 64,
                color: Color(0xFF9CA3AF),
              ),
              SizedBox(height: 16),
              Text(
                'No results found',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        );
      }

      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Results count
            Text(
              'Results: ${jobs.length}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF9CA3AF),
              ),
            ),

            const SizedBox(height: 12),

            // Cards list
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.only(bottom: 16),
                itemCount: jobs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 15),
                itemBuilder: (context, index) {
                  final job = jobs[index];
                  final isSaved = state.savedJobIds.contains(job.id);
                  print('   📌 Building card #$index for job #${job.id}: "${job.jobTitle}"');
                  return _JobCard(
                    job: job,
                    isSaved: isSaved,
                    onToggleSave: () {
                      context.read<SearchBloc>().add(SearchToggleSaveJob(job.id));
                    },
                  );
                },
              ),
            ),
          ],
        ),
      );
    }

    // Initial state - empty
    return const Center(
      child: Text(
        'Start searching...',
        style: TextStyle(
          fontSize: 16,
          color: Color(0xFF6B7280),
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(50),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 16,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Back button
            GestureDetector(
              onTap: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              },
              child: const Icon(Icons.arrow_back, color: Color(0xFF6B7280), size: 20),
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Builder(
                builder: (context) {
                  final blocState = context.watch<SearchBloc>().state;
                  final displayText = blocState is SearchLoaded
                      ? blocState.keyword
                      : (blocState is SearchError ? blocState.keyword : '');
                  return Text(
                    displayText.isEmpty ? 'Search' : displayText,
                    style: const TextStyle(
                      color: Color(0xFF111827),
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                    ),
                  );
                },
              ),
            ),

            const SizedBox(width: 12),

            // Search mode selector
            PopupMenuButton<SearchMode>(
              color: Colors.white,
              initialValue: _searchMode,
              onSelected: (SearchMode mode) {
                setState(() {
                  _searchMode = mode;
                });
              },
              offset: const Offset(0, 40),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE3E8F0)),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _searchMode == SearchMode.jobs ? 'Jobs' : 'Courses',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF2B2B2B),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.arrow_drop_down,
                        size: 20, color: Color(0xFF2B2B2B)),
                  ],
                ),
              ),
              itemBuilder: (BuildContext context) =>
                  const <PopupMenuEntry<SearchMode>>[
                PopupMenuItem<SearchMode>(
                  value: SearchMode.jobs,
                  child: Text('Jobs'),
                ),
                PopupMenuItem<SearchMode>(
                  value: SearchMode.courses,
                  child: Text('Courses'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChipsRow() {
    final chips = [
      {'label': 'Easy Apply', 'icon': Icons.flash_on, 'hasDropdown': false},
      {'label': 'Location', 'icon': Icons.location_on_outlined, 'hasDropdown': true},
      {'label': 'Date Posted', 'icon': Icons.calendar_today_outlined, 'hasDropdown': true},
      {'label': 'Salary', 'icon': Icons.attach_money, 'hasDropdown': true},
      {'label': 'Experience', 'icon': Icons.work_outline, 'hasDropdown': false},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        height: 32,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: chips.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            return _FilterChip(
              label: chips[i]['label'] as String,
              icon: chips[i]['icon'] as IconData,
              hasDropdown: chips[i]['hasDropdown'] as bool,
            );
          },
        ),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;

        // Responsive nav item width (matching AppShell)
        final navItemWidth = (screenWidth * 0.16).clamp(54.0, 70.0);

        // Responsive center button size (matching AppShell)
        final centerButtonWidth = (screenWidth * 0.235).clamp(80.0, 98.0);
        final centerButtonHeight = (navItemWidth * 0.93).clamp(50.0, 60.0);

        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(
                color: Color(0xFFCAC9C9),
                width: 1,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0x0D000000),
                offset: Offset(0, -2),
                blurRadius: 8,
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: SafeArea(
            top: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home,
                  label: 'Home',
                  isSelected: false,
                  onTap: () {
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    }
                  },
                  width: navItemWidth,
                ),
                _NavItem(
                  icon: Icons.search,
                  activeIcon: Icons.search,
                  label: 'Explore',
                  isSelected: true,
                  onTap: () {
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    }
                  },
                  width: navItemWidth,
                ),
                // Post Job - center button (matching AppShell)
                GestureDetector(
                  onTap: () {
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    }
                  },
                  child: Container(
                    width: centerButtonWidth,
                    height: centerButtonHeight,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2B9FDB), // Fixed: was 0xFF3B82F6
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_circle,
                          color: Colors.white,
                          size: 24,
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Post Job',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                _NavItem(
                  icon: Icons.person_outline,
                  activeIcon: Icons.person,
                  label: 'Profile',
                  isSelected: false,
                  onTap: () {
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    }
                  },
                  width: navItemWidth,
                ),
                _NavItemWithCircle(
                  label: 'More',
                  isSelected: false,
                  onTap: () {
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    }
                  },
                  width: navItemWidth,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

}

/// Filter chip widget
class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool hasDropdown;

  const _FilterChip({
    required this.label,
    required this.icon,
    required this.hasDropdown,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE8ECEF), width: 1),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF6B7280)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF111827),
            ),
          ),
          if (hasDropdown) ...[
            const SizedBox(width: 6),
            const Icon(
              Icons.keyboard_arrow_down,
              size: 16,
              color: Color(0xFF3B82F6),
            ),
          ],
        ],
      ),
    );
  }
}

/// Job card widget matching Figma design exactly
class _JobCard extends StatelessWidget {
  final JobModel job;
  final bool isSaved;
  final VoidCallback onToggleSave;

  const _JobCard({
    required this.job,
    required this.isSaved,
    required this.onToggleSave,
  });

  @override
  Widget build(BuildContext context) {
    // 🔍 DEBUG: Print all job field values
    print('\n📱 _JobCard rendering job #${job.id}:');
    print('   jobTitle: "${job.jobTitle}"');
    print('   companyName: ${job.companyName != null ? "\"${job.companyName}\"" : "NULL"}');
    print('   officeLocation: ${job.officeLocation != null ? "\"${job.officeLocation}\"" : "NULL"}');
    print('   formattedSalary: ${job.formattedSalary != null ? "\"${job.formattedSalary}\"" : "NULL"}');
    print('   salaryDisplayResolved: ${job.salaryDisplayResolved != null ? "\"${job.salaryDisplayResolved}\"" : "NULL"} ← USED IN UI');
    print('   jobType: ${job.jobType != null ? "\"${job.jobType}\"" : "NULL"}');
    print('   locationPriority: ${job.locationPriority != null ? "\"${job.locationPriority}\"" : "NULL"}');
    print('   status: ${job.status != null ? "\"${job.status}\"" : "NULL"}');
    print('   activeSince: ${job.activeSince != null ? "\"${job.activeSince}\"" : "NULL"}');
    print('   isSaved: $isSaved');

    final hasNewBadge = job.status?.toLowerCase() == 'opened' || job.status == 'New';

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FD),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: Status badge + Bookmark
          Row(
            children: [
              if (hasNewBadge)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8E9FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'New',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF5B5FC7),
                    ),
                  ),
                )
              else
                const SizedBox.shrink(),

              const Spacer(),

              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: onToggleSave,
                child: Icon(
                  isSaved ? Icons.bookmark : Icons.bookmark_border,
                  color: isSaved
                      ? const Color(0xFF3170CE)
                      : const Color(0xFFB0B5BE),
                  size: 24,
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),

          Text(
            job.jobTitle,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 6),

          if (job.companyName != null)
            Text(
              job.companyName!,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF6B7280),
              ),
            ),

          const SizedBox(height: 4),

          if (job.officeLocation != null)
            Text(
              job.officeLocation!,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: Color(0xFF9CA3AF),
              ),
            ),

          const SizedBox(height: 15),

          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              // Use salaryDisplayResolved which handles all salary logic (formatted, min/max, discussed)
              if (job.salaryDisplayResolved != null)
                _Pill(text: job.salaryDisplayResolved!),
              if (job.jobType != null)
                _Pill(text: _formatJobType(job.jobType!)),
              if (job.locationPriority != null)
                _Pill(text: _formatLocationType(job.locationPriority!)),
            ],
          ),

          const SizedBox(height: 15),

          if (job.activeSince != null)
            Text(
              job.activeSince!,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: Color(0xFF9CA3AF),
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

class _Pill extends StatelessWidget {
  final String text;

  const _Pill({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Color(0xFF111827),
        ),
      ),
    );
  }
}

// Navigation item widget matching AppShell design
class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final double width;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? const Color(0xFF2B9FDB) : const Color(0xFF8F959E);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: width,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: color,
              size: 26,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom widget for More button with circle and dots (matching AppShell)
class _NavItemWithCircle extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final double width;

  const _NavItemWithCircle({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? const Color(0xFF2B9FDB) : const Color(0xFF8F959E);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: width,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Circle with 3 dots inside
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: color,
                  width: 2,
                ),
              ),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _Dot(color: color),
                    const SizedBox(width: 2),
                    _Dot(color: color),
                    const SizedBox(width: 2),
                    _Dot(color: color),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Small dot widget for More button
class _Dot extends StatelessWidget {
  final Color color;
  const _Dot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 3,
      height: 3,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}

