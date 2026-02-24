import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/home_bloc.dart';
import '../bloc/home_event.dart';
import '../bloc/home_state.dart';
import '../models/job_model.dart';
import '../models/course_model.dart';
import '../models/home_model.dart';

class HomePage extends StatelessWidget {
  final VoidCallback onTapSearch;
  const HomePage({super.key, required this.onTapSearch});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = constraints.maxWidth;
          final screenHeight = constraints.maxHeight;

          // Responsive gradient height (20-40% of screen height)
          final gradientHeight = (screenHeight * 0.35).clamp(220.0, 500.0);

          return Stack(
            children: [
              // White background
              const Positioned.fill(
                child: ColoredBox(color: Colors.white),
              ),

              // Responsive gradient at top
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: gradientHeight,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color.fromARGB(255, 197, 217, 255),
                        Color.fromARGB(255, 255, 255, 255),
                      ],
                    ),
                  ),
                ),
              ),

              // Content
              SafeArea(
                child: BlocBuilder<HomeBloc, HomeState>(
                  builder: (context, state) {
                    if (state is HomeLoading || state is HomeInitial) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (state is HomeError) {
                      return _ErrorView(
                        message: state.message,
                        onRetry: () =>
                            context.read<HomeBloc>().add(const HomeLoadRequested()),
                      );
                    }

                    if (state is HomeLoaded) {
                      return _HomeContent(
                        data: state.homeData,
                        onTapSearch: onTapSearch,
                        screenWidth: screenWidth,
                        onRefresh: () async {
                          context.read<HomeBloc>().add(const HomeRefreshRequested());
                        },
                      );
                    }

                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final errorImageHeight = (screenWidth * 0.65).clamp(200.0, 280.0);

    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.085, // ~32px on 375px
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'lib/app/assets/images/Frame 427319163.png',
              height: errorImageHeight,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Icon(
                Icons.error_outline,
                size: screenWidth * 0.17, // ~64px on 375px
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Oops! Something went wrong',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              child: const Text(
                'Try Again',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  final HomeModel data;
  final VoidCallback onTapSearch;
  final double screenWidth;
  final Future<void> Function() onRefresh;

  const _HomeContent({
    required this.data,
    required this.onTapSearch,
    required this.screenWidth,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            // Top section with padding
            Padding(
              padding: EdgeInsets.fromLTRB(
                screenWidth * 0.048, // ~18px
                14,
                screenWidth * 0.048,
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TopBar(screenWidth: screenWidth),
                  const SizedBox(height: 16),
                  const _HeroTitle(),
                  const SizedBox(height: 16),
                  _SearchBar(onTap: onTapSearch),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // White card with rounded top
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  screenWidth * 0.048,
                  22,
                  screenWidth * 0.048,
                  24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Jobs for Special Abilities
                    if (data.disabilityJobs.isNotEmpty) ...[
                      const _SectionHeader(title: 'Jobs for Special Abilities'),
                      const SizedBox(height: 12),
                      const _ChipsRow(labels: ['All', 'Deaf', 'Blind']),
                      const SizedBox(height: 14),
                      _HorizontalCards<JobModel>(
                        height: 348,
                        screenWidth: screenWidth,
                        items: data.disabilityJobs.take(8).toList(),
                        cardBuilder: (ctx, job, index) =>
                            _SpecialJobCard(job: job, index: index),
                      ),
                      const SizedBox(height: 28),
                    ],

                    // Featured Jobs
                    if (data.featuredJobs.isNotEmpty) ...[
                      const _SectionHeader(title: 'Featured Jobs'),
                      const SizedBox(height: 14),
                      _HorizontalCards<JobModel>(
                        height: 348,
                        screenWidth: screenWidth,
                        items: data.featuredJobs.take(8).toList(),
                        cardBuilder: (ctx, job, index) =>
                            _FeaturedJobCard(job: job, index: index),
                      ),
                      const SizedBox(height: 28),
                    ],

                    // Courses for You
                    if (data.coursesForYou.isNotEmpty) ...[
                      const _SectionHeader(title: 'Courses for You'),
                      const SizedBox(height: 14),
                      _HorizontalCards<CourseModel>(
                        height: 220,
                        screenWidth: screenWidth,
                        items: data.coursesForYou,
                        cardBuilder: (ctx, course, index) =>
                            _CourseCard(course: course),
                      ),
                      const SizedBox(height: 28),
                    ],

                    // Recent Openings
                    if (data.recentOpenings.isNotEmpty) ...[
                      const _SectionHeader(title: 'Recent Openings'),
                      const SizedBox(height: 12),
                      const _ChipsRow(
                        labels: ['All', 'Full Time', 'Part Time', 'On site', 'Hybrid'],
                      ),
                      const SizedBox(height: 14),
                      ListView.separated(
                        itemCount: data.recentOpenings.take(5).length,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, i) => _RecentOpeningCard(
                          job: data.recentOpenings[i],
                          index: i,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ===================== UI PARTS ===================== */

class _TopBar extends StatelessWidget {
  final double screenWidth;
  const _TopBar({required this.screenWidth});

  @override
  Widget build(BuildContext context) {
    // Responsive logo size
    final logoSize = (screenWidth * 0.16).clamp(54.0, 70.0);
    final notificationSize = (screenWidth * 0.117).clamp(40.0, 48.0);

    return Row(
      children: [
        Container(
          width: logoSize,
          height: logoSize,
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Image.asset(
            'lib/app/assets/images/Rec.png',
            fit: BoxFit.contain,
            width: logoSize + 10,
            height: logoSize + 10,
          ),
        ),
        const Spacer(),
        Container(
          width: notificationSize,
          height: notificationSize,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(50),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(Icons.notifications_none,
              size: 22, color: Color(0xFF111827)),
        ),
      ],
    );
  }
}

class _HeroTitle extends StatelessWidget {
  const _HeroTitle();

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: const TextSpan(
        style: TextStyle(
          fontSize: 28,
          height: 1.2,
          fontWeight: FontWeight.w500,
          color: Color(0xFF111827),
        ),
        children: [
          TextSpan(text: "Let's help you find the perfect\n"),
          TextSpan(text: "job", style: TextStyle(color: Color(0xFF2563EB))),
          TextSpan(text: " or "),
          TextSpan(
              text: "course,", style: TextStyle(color: Color(0xFF2563EB))),
          TextSpan(text: " you deserve!"),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final VoidCallback onTap;
  const _SearchBar({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.search, color: Color(0xFF9CA3AF), size: 22),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Search for jobs and courses',
                style: TextStyle(
                  color: Color(0xFF9CA3AF),
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Jobs',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Color(0xFF374151),
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.keyboard_arrow_down,
                      size: 18, color: Color(0xFF374151)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
            ),
          ),
        ),
        const Text(
          'See More',
          style: TextStyle(
            color: Color(0xFF2563EB),
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

class _ChipsRow extends StatelessWidget {
  final List<String> labels;
  const _ChipsRow({required this.labels});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(labels.length, (i) {
          final selected = i == 0;
          return Padding(
            padding: EdgeInsets.only(right: i == labels.length - 1 ? 0 : 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: selected ? const Color(0xFF2563EB) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color:
                      selected ? const Color(0xFF2563EB) : const Color(0xFFE5E7EB),
                  width: 1.5,
                ),
                boxShadow: selected
                    ? []
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
              ),
              child: Text(
                labels[i],
                style: TextStyle(
                  color: selected ? Colors.white : const Color(0xFF374151),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _HorizontalCards<T> extends StatelessWidget {
  final List<T> items;
  final double height;
  final double screenWidth;
  final Widget Function(BuildContext, T, int) cardBuilder;

  const _HorizontalCards({
    super.key,
    required this.items,
    required this.cardBuilder,
    required this.screenWidth,
    this.height = 348,
  });

  @override
  Widget build(BuildContext context) {
    // Responsive card width: 85-95% of screen width, clamped
    final cardWidth = (screenWidth * 0.9).clamp(280.0, 420.0);

    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, i) => SizedBox(
          width: cardWidth,
          child: cardBuilder(context, items[i], i),
        ),
      ),
    );
  }
}

/* ===================== CARDS ===================== */

class _SpecialJobCard extends StatelessWidget {
  final JobModel job;
  final int index;
  const _SpecialJobCard({required this.job, required this.index});

  static const _colors = [
    Color(0xFFF1F4FD),
    Color(0xFFF1F4FD),
    Color(0xFFF1F4FD),
    Color(0xFFF1F4FD),
    Color(0xFFF1F4FD),
    Color(0xFFF1F4FD),
    Color(0xFFF1F4FD),
    Color(0xFFF1F4FD),
  ];

  static const _badgeTypes = {
    'sign': {
      'text': 'Sign-Enabled Roles',
      'bg': Color(0xFFBFDBFE),
      'fg': Color(0xFF1E40AF)
    },
    'touch': {
      'text': 'Touch-Enabled Roles',
      'bg': Color(0xFFFED7AA),
      'fg': Color(0xFF92400E)
    },
    'urgent': {
      'text': 'Urgent',
      'bg': Color(0xFFFECDD3),
      'fg': Color(0xFF991B1B)
    },
    'hiring': {
      'text': 'Hiring Multiple Candidates',
      'bg': Color(0xFFD4EDDA),
      'fg': Color(0xFF166534)
    },
    'new': {'text': 'New', 'bg': Color(0xFFC7D2FE), 'fg': Color(0xFF3730A3)},
  };

  List<String> _getBadgesForJob(JobModel job, int index) {
    final badges = <String>[];
    if (index % 2 == 0) {
      badges.add('sign');
    } else {
      badges.add('touch');
    }

    if (job.isUrgent == true) {
      badges.add('urgent');
    } else if (job.isMultipleHires == true) {
      badges.add('hiring');
    }

    return badges;
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = _colors[index % _colors.length];
    final badges = _getBadgesForJob(job, index);

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (badges.isNotEmpty)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (int i = 0; i < badges.length; i++) ...[
                        if (i > 0) const SizedBox(height: 6),
                        _Badge(config: _badgeTypes[badges[i]]!),
                      ],
                    ],
                  ),
                )
              else
                const Spacer(),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  context.read<HomeBloc>().add(HomeToggleSaveJob(job.id));
                },
                child: Icon(
                  job.isSaved ? Icons.bookmark : Icons.bookmark_border,
                  color: const Color(0xFF3170CE),
                  size: 22,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            job.jobTitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            job.jobDescription ?? '',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  [job.companyName, job.officeLocation]
                      .where((s) => s != null && s.isNotEmpty)
                      .join('  •  '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _TagPill(text: job.salaryDisplayForUi),
              if (job.locationPriority != null && job.locationPriority!.isNotEmpty)
                _TagPill(text: job.locationPriority!),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            job.activeSince ?? job.createdAt ?? '',
            style: const TextStyle(
              color: Color(0xFF9CA3AF),
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final Map<String, dynamic> config;
  const _Badge({required this.config});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: config['bg'] as Color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        config['text'] as String,
        style: TextStyle(
          color: config['fg'] as Color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _FeaturedJobCard extends StatelessWidget {
  final JobModel job;
  final int index;
  const _FeaturedJobCard({required this.job, required this.index});

  static const _colors = [
    Color.fromARGB(255, 248, 227, 233),
    Color.fromARGB(255, 250, 243, 213),
    Color.fromARGB(255, 236, 236, 237),
    Color.fromARGB(255, 229, 248, 234),
    Color(0xFFDCEFFD),
    Color(0xFFFED7D7),
  ];

  @override
  Widget build(BuildContext context) {
    final bgColor = _colors[index % _colors.length];

    const cardHeight = 348.0;
    const outerRadius = 28.0;
    const innerRadius = 22.0;
    const borderColor = Color(0xFFD1D5DB);
    const innerBorderColor = Color(0xFFE5E7EB);

    const outerPadding = 12.0;
    const bottomAreaHeight = 72.0;
    const gapBetween = 10.0;

    return SizedBox(
      height: cardHeight,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(outerRadius),
          border: Border.all(color: borderColor, width: 1.2),
        ),
        padding: const EdgeInsets.all(outerPadding),
        child: Stack(
          children: [
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              bottom: bottomAreaHeight + gapBetween,
              child: Container(
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(innerRadius),
                  border: Border.all(color: innerBorderColor, width: 1),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: innerBorderColor, width: 1),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: (job.companyLogo != null && job.companyLogo!.isNotEmpty)
                              ? Image.network(
                                  job.companyLogo!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.business,
                                    size: 22,
                                    color: Color(0xFF9CA3AF),
                                  ),
                                )
                              : const Icon(
                                  Icons.business,
                                  size: 22,
                                  color: Color(0xFF9CA3AF),
                                ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                job.companyName ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: Color(0xFF111827),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                job.officeLocation ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () =>
                              context.read<HomeBloc>().add(HomeToggleSaveJob(job.id)),
                          child: Icon(
                            job.isSaved ? Icons.bookmark : Icons.bookmark_border,
                            size: 24,
                            color: const Color(0xFF3170CE),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      job.jobTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      job.jobDescription ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF4B5563),
                        fontWeight: FontWeight.w500,
                        fontSize: 14.5,
                        height: 1.45,
                      ),
                    ),
                    const Spacer(),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        if (job.jobType != null && job.jobType!.isNotEmpty)
                          _IconTagPill(icon: Icons.access_time, text: job.jobType!),
                        if (job.locationPriority != null &&
                            job.locationPriority!.isNotEmpty)
                          _IconTagPill(
                              icon: Icons.place_outlined,
                              text: job.locationPriority!),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: bottomAreaHeight,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                        ),
                        child: Text(
                          job.salaryDisplayForUi,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: Color(0xFF111827),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: borderColor, width: 1.2),
                      ),
                      child: const Text(
                        'Details',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: Color(0xFF111827),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  final CourseModel course;
  const _CourseCard({required this.course});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  course.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            course.description ?? '',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
          const Spacer(),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (course.courseCategory != null && course.courseCategory!.isNotEmpty)
                _CourseBadge(
                    text: course.courseCategory!, color: const Color(0xFF2563EB)),
              if (course.level != null && course.level!.isNotEmpty)
                _CourseBadge(text: course.level!, color: const Color(0xFF7C3AED)),
              if (course.hasCertificate == true)
                const _CourseBadge(text: 'Certificate', color: Color(0xFF059669)),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecentOpeningCard extends StatelessWidget {
  final JobModel job;
  final int index;
  const _RecentOpeningCard({required this.job, required this.index});

  static const _badgeConfigs = [
    {'text': 'New', 'bg': Color(0xFFE0E7FF), 'fg': Color(0xFF3730A3)},
    {'text': 'Hiring Multiple Candidates', 'bg': Color(0xFFDCFCE7), 'fg': Color(0xFF166534)},
    {'text': 'Urgent', 'bg': Color(0xFFFEE2E2), 'fg': Color(0xFF991B1B)},
    {'text': 'Featured', 'bg': Color(0xFFFEF3C7), 'fg': Color(0xFF92400E)},
    {'text': 'New', 'bg': Color(0xFFE0E7FF), 'fg': Color(0xFF3730A3)},
  ];

  static const _colors = [
    Color(0xFFF1F4FD),
    Color(0xFFDCFCE7),
    Color(0xFFDCEFFD),
    Color(0xFFFEF3C7),
    Color(0xFFFCE7F3),
  ];

  @override
  Widget build(BuildContext context) {
    final bgColor = _colors[index % _colors.length];
    final badgeConfig = index < _badgeConfigs.length ? _badgeConfigs[index] : null;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (badgeConfig != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: badgeConfig['bg'] as Color,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    badgeConfig['text'] as String,
                    style: TextStyle(
                      color: badgeConfig['fg'] as Color,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                )
              else
                const SizedBox.shrink(),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  context.read<HomeBloc>().add(HomeToggleSaveJob(job.id));
                },
                child: Icon(
                  job.isSaved ? Icons.bookmark : Icons.bookmark_border,
                  size: 22,
                  color: const Color(0xFF3170CE),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            job.jobTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827),
              height: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            job.companyName ?? '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            job.officeLocation ?? '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 15),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE5E7EB), width: 1.2),
                ),
                child: Text(
                  job.salaryDisplayForUi,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
              if (job.jobType != null && job.jobType!.isNotEmpty)
                _SmallTagPill(text: job.jobType!),
              if (job.locationPriority != null && job.locationPriority!.isNotEmpty)
                _SmallTagPill(text: job.locationPriority!),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            job.activeSince ?? job.createdAt ?? '',
            style: const TextStyle(
              color: Color(0xFF9CA3AF),
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

/* ===================== SMALL UI COMPONENTS ===================== */

class _TagPill extends StatelessWidget {
  final String text;
  const _TagPill({required this.text});

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12,
          color: Color(0xFF374151),
        ),
      ),
    );
  }
}

class _IconTagPill extends StatelessWidget {
  final IconData icon;
  final String text;
  const _IconTagPill({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF2563EB)),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: Color(0xFF374151),
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallTagPill extends StatelessWidget {
  final String text;
  const _SmallTagPill({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 11,
          color: Color(0xFF374151),
        ),
      ),
    );
  }
}

class _CourseBadge extends StatelessWidget {
  final String text;
  final Color color;
  const _CourseBadge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}
