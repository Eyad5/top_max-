import 'package:flutter/material.dart';

/// Static UI-only Bookmarks page matching Figma design
/// No API calls, no Bloc - purely demo data for design showcase
class SavedItemsPage extends StatefulWidget {
  final VoidCallback? onBackToHome;

  const SavedItemsPage({super.key, this.onBackToHome});

  @override
  State<SavedItemsPage> createState() => _SavedItemsPageState();
}

class _SavedItemsPageState extends State<SavedItemsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // Hardcoded demo data for Figma design
  final List<Map<String, dynamic>> _demoJobs = [
    {
      'title': 'Ui/Ux Designer',
      'company': 'Top Max Technology',
      'location': 'Al Muteena, Dubai',
      'salary': 'From AED 15000 / month',
      'jobType': 'Full Time',
      'locationType': 'Remote',
      'status': 'New',
      'statusColor': const Color(0xFFE8E9FF),
      'statusTextColor': const Color(0xFF5B5FC7),
      'appliedDate': '12 Dec 2024',
    },
    {
      'title': 'Senior Flutter Developer',
      'company': 'Tech Innovations LLC',
      'location': 'Business Bay, Dubai',
      'salary': 'From AED 18000 / month',
      'jobType': 'Full Time',
      'locationType': 'Hybrid',
      'status': 'Applied',
      'statusColor': const Color(0xFFFEE2E2),
      'statusTextColor': const Color(0xFF991B1B),
      'appliedDate': '10 Dec 2024',
    },
    {
      'title': 'Product Manager',
      'company': 'Digital Solutions',
      'location': 'Dubai Marina, Dubai',
      'salary': 'From AED 20000 / month',
      'jobType': 'Full Time',
      'locationType': 'On-site',
      'status': 'New',
      'statusColor': const Color(0xFFE8E9FF),
      'statusTextColor': const Color(0xFF5B5FC7),
      'appliedDate': '8 Dec 2024',
    },
    {
      'title': 'Backend Developer',
      'company': 'Cloud Systems Inc',
      'location': 'Downtown Dubai',
      'salary': 'From AED 12000 / month',
      'jobType': 'Part Time',
      'locationType': 'Remote',
      'status': 'Applied',
      'statusColor': const Color(0xFFFEE2E2),
      'statusTextColor': const Color(0xFF991B1B),
      'appliedDate': '5 Dec 2024',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

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
            child: TabBarView(
              controller: _tabController,
              children: [
                // Saved Jobs Tab
                ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _demoJobs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final job = _demoJobs[index];
                    return _JobCard(job: job);
                  },
                ),

                // Saved Courses Tab (empty for now)
                const Center(
                  child: Text(
                    'No saved courses',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Job card widget matching Figma design exactly
/// Job card widget matching Figma design exactly
class _JobCard extends StatefulWidget {
  final Map<String, dynamic> job;

  const _JobCard({required this.job});

  @override
  State<_JobCard> createState() => _JobCardState();
}

class _JobCardState extends State<_JobCard> {
  bool isSaved = true; // ✅ لأننا داخل Bookmarks افتراضياً محفوظ

  @override
  Widget build(BuildContext context) {
    final job = widget.job;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F4FD), // Light bluish background
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
                  color: job['statusColor'],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  job['status'],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: job['statusTextColor'],
                  ),
                ),
              ),
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
                      ? const Color(0xFF2563EB)
                      : const Color(0xFF9CA3AF),
                  size: 24,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Job Title
          Text(
            job['title'],
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
          Text(
            job['company'],
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
          Text(
            job['location'],
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
              _Pill(text: job['salary']),
              _Pill(text: job['jobType']),
              _Pill(text: job['locationType']),
            ],
          ),

          const SizedBox(height: 12),

          // Applied date
          Text(
            'Applied on ${job['appliedDate']}',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6B7280),
            ),
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
        borderRadius: BorderRadius.circular(999), // Full capsule
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
