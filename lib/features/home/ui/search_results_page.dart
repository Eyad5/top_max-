import 'package:flutter/material.dart';
import '../bloc/search_event.dart';

/// Static UI-only Search Results page matching Figma design
/// No API calls, no Bloc - purely demo data for design showcase
class SearchResultsPage extends StatelessWidget {
  final String? keyword;

  const SearchResultsPage({super.key, this.keyword});

  @override
  Widget build(BuildContext context) {
    return const _SearchResultsView();
  }
}

class _SearchResultsView extends StatefulWidget {
  const _SearchResultsView();

  @override
  State<_SearchResultsView> createState() => _SearchResultsViewState();
}

class _SearchResultsViewState extends State<_SearchResultsView> {
  SearchMode _searchMode = SearchMode.jobs;

  // Hardcoded demo data for Figma design
  static final List<Map<String, dynamic>> _demoJobs = [
    {
      'title': 'Ui/Ux Designer',
      'company': 'Top Max Technology',
      'location': 'Al Muteena, Dubai',
      'salary': 'From AED 15000 / month',
      'jobType': 'Full Time',
      'locationType': 'On-site',
      'status': 'New',
      'activeDate': 'Active 2 days Ago',
    },
    {
      'title': 'Senior Flutter Developer',
      'company': 'Tech Innovations LLC',
      'location': 'Business Bay, Dubai',
      'salary': 'From AED 18000 / month',
      'jobType': 'Full Time',
      'locationType': 'Hybrid',
      'status': 'New',
      'activeDate': 'Active 1 day Ago',
    },
    {
      'title': 'Product Manager',
      'company': 'Digital Solutions',
      'location': 'Dubai Marina, Dubai',
      'salary': 'From AED 20000 / month',
      'jobType': 'Full Time',
      'locationType': 'Remote',
      'status': '',
      'activeDate': 'Active 3 days Ago',
    },
    {
      'title': 'Backend Developer',
      'company': 'Cloud Systems Inc',
      'location': 'Downtown Dubai',
      'salary': 'From AED 12000 / month',
      'jobType': 'Part Time',
      'locationType': 'Remote',
      'status': 'New',
      'activeDate': 'Active 5 days Ago',
    },
    {
      'title': 'iOS Developer',
      'company': 'Mobile Apps Co',
      'location': 'Jumeirah, Dubai',
      'salary': 'From AED 16000 / month',
      'jobType': 'Full Time',
      'locationType': 'On-site',
      'status': '',
      'activeDate': 'Active 1 week Ago',
    },
    {
      'title': 'DevOps Engineer',
      'company': 'Infrastructure Solutions',
      'location': 'Dubai Silicon Oasis',
      'salary': 'From AED 14000 / month',
      'jobType': 'Full Time',
      'locationType': 'Hybrid',
      'status': 'New',
      'activeDate': 'Active 4 days Ago',
    },
    {
      'title': 'Frontend Developer',
      'company': 'Web Solutions Ltd',
      'location': 'DIFC, Dubai',
      'salary': 'From AED 13000 / month',
      'jobType': 'Full Time',
      'locationType': 'Remote',
      'status': '',
      'activeDate': 'Active 6 days Ago',
    },
    {
      'title': 'QA Engineer',
      'company': 'Quality Systems',
      'location': 'Al Barsha, Dubai',
      'salary': 'From AED 11000 / month',
      'jobType': 'Full Time',
      'locationType': 'On-site',
      'status': 'New',
      'activeDate': 'Active 2 days Ago',
    },
  ];

  // ✅ (اختياري) ديمو كورسات عشان لما تختار Courses يتغير المحتوى فعلاً
  static final List<Map<String, dynamic>> _demoCourses = [
    {
      'title': 'UI/UX Fundamentals',
      'company': 'Top Max Academy',
      'location': 'Online',
      'salary': 'Free',
      'jobType': 'Course',
      'locationType': 'Remote',
      'status': 'New',
      'activeDate': 'Active today',
    },
    {
      'title': 'Flutter Bootcamp (Beginner → Pro)',
      'company': 'Tech Learning Hub',
      'location': 'Online',
      'salary': 'From AED 299 / month',
      'jobType': 'Course',
      'locationType': 'Remote',
      'status': '',
      'activeDate': 'Active 2 days Ago',
    },
    {
      'title': 'Product Management Essentials',
      'company': 'Digital Skills',
      'location': 'Dubai (On-site)',
      'salary': 'From AED 499 / month',
      'jobType': 'Course',
      'locationType': 'On-site',
      'status': 'New',
      'activeDate': 'Active 5 days Ago',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final list = _searchMode == SearchMode.jobs ? _demoJobs : _demoCourses;

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

                // Search Bar
                _buildSearchBar(),

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
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Results count
                          Text(
                            _searchMode == SearchMode.jobs
                                ? 'Results: 375'
                                : 'Results: 84',
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
                              itemCount: list.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 15),
                              itemBuilder: (context, index) {
                                final item = list[index];
                                return _JobCard(job: item);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      // Bottom Navigation
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildSearchBar() {
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
            const Icon(Icons.search, color: Color(0xFF6B7280), size: 20),
            const SizedBox(width: 12),

            // لو بدك تعرض keyword بدل النص الثابت، غيرها لاحقًا
            const Expanded(
              child: Text(
                'Ui Ux Design',
                style: TextStyle(
                  color: Color(0xFF111827),
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),

            const SizedBox(width: 12),

            // ✅ نفس PopupMenuButton الموجود في SearchPage
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
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x0D000000),
            offset: Offset(0, -2),
            blurRadius: 8,
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(
              icon: Icons.home_outlined,
              label: 'Home',
              isActive: false,
              onTap: () => Navigator.pop(context),
            ),
            _NavItem(
              icon: Icons.search,
              label: 'Explore',
              isActive: true,
              onTap: () {},
            ),
            GestureDetector(
              onTap: () {},
              child: Container(
                width: 80,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.add_circle, color: Colors.white, size: 22),
                    SizedBox(height: 2),
                    Text(
                      'Post Job',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _NavItem(
              icon: Icons.person_outline,
              label: 'Profile',
              isActive: false,
              onTap: () {},
            ),
            _NavItem(
              icon: Icons.more_horiz,
              label: 'More',
              isActive: false,
              onTap: () {},
            ),
          ],
        ),
      ),
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
class _JobCard extends StatefulWidget {
  final Map<String, dynamic> job;

  const _JobCard({required this.job});

  @override
  State<_JobCard> createState() => _JobCardState();
}

class _JobCardState extends State<_JobCard> {
  bool isSaved = false;

  @override
  Widget build(BuildContext context) {
    final job = widget.job;
    final hasNewBadge = job['status'] == 'New';

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
                onTap: () {
                  setState(() {
                    isSaved = !isSaved;
                  });
                },
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
            job['title'],
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

          Text(
            job['company'],
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF6B7280),
            ),
          ),

          const SizedBox(height: 4),

          Text(
            job['location'],
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
              _Pill(text: job['salary']),
              _Pill(text: job['jobType']),
              _Pill(text: job['locationType']),
            ],
          ),

          const SizedBox(height: 15),

          Text(
            job['activeDate'],
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

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? const Color(0xFF3B82F6) : const Color(0xFF9CA3AF);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}