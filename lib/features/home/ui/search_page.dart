import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/network/dio_client.dart';
import '../bloc/search_bloc.dart';
import '../bloc/search_event.dart';
import '../data/home_api.dart';
import '../data/home_repo.dart';
import 'search_results_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _controller = TextEditingController();
  SearchMode _searchMode = SearchMode.jobs;

  void _goSearch(String text, {String? locationType, String? jobType}) {
    final keyword = text.trim();
    // Allow empty keyword when filters are provided
    if (keyword.isEmpty && locationType == null && jobType == null) return;

    // Create SearchBloc and navigate
    final homeRepo = HomeRepo(HomeApi(DioClient.dio));
    final searchBloc = SearchBloc(homeRepo);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: searchBloc,
          child: SearchResultsPage(
            keyword: keyword,
            searchMode: _searchMode,
            locationType: locationType,
            jobType: jobType,
          ),
        ),
      ),
    ).then((_) {
      // Close bloc when page is popped
      searchBloc.close();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _chipKeyword(String text, {String? keywordOverride, SearchMode? modeOverride, String? locationType, String? jobType, bool fullWidth = false}) {
    return SizedBox(
      width: fullWidth ? double.infinity : null,
      child: Material(
        color: Colors.white,
        shape: const StadiumBorder(
          side: BorderSide(color: Color(0xFFE3E8F0), width: 1),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: () {
            final keyword = (keywordOverride ?? text).trim();
            _controller.text = keyword;

            // 🔍 DEBUG: Log chip search mapping
            print('\n🎯 Chip tapped: "$text"');
            print('   Mapped keyword: "$keyword" locationType=$locationType jobType=$jobType');
            print('   Search mode: ${modeOverride ?? _searchMode}');

            // Switch mode if specified
            if (modeOverride != null) {
              setState(() {
                _searchMode = modeOverride;
              });
            }

            _goSearch(keyword, locationType: locationType, jobType: jobType);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: Text(
              text,
                maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
        
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF2B2B2B),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // White background for entire page
          const Positioned.fill(
            child: ColoredBox(color: Colors.white),
          ),

          // Light blue gradient at top (matching HomePage)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 260,
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
            child: ListView(
              // ✅ مهم: بدون padding عشان الأبيض يلزق بالحواف
              padding: EdgeInsets.zero,
              children: [
                const SizedBox(height: 15),

                // ✅ Search Bar مع padding يمين/شمال فقط
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(50),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x14000000),
                          blurRadius: 18,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search, color: Color(0xFF2B2B2B)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            decoration: InputDecoration(
                              hintText: _searchMode == SearchMode.jobs
                                  ? 'Search for jobs and courses'
                                  : 'Search for courses',
                              hintStyle: const TextStyle(
                                color: Color(0xFF7A8797),
                                fontWeight: FontWeight.w400,
                              ),
                              border: InputBorder.none,
                            ),
                            textInputAction: TextInputAction.search,
                            onSubmitted: _goSearch,
                          ),
                        ),
                        const SizedBox(width: 8),
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
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                                const Icon(Icons.arrow_drop_down, size: 20, color: Color(0xFF2B2B2B)),
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
                ),

                const SizedBox(height: 18),

                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(28),
                      topRight: Radius.circular(28),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Popular Searches',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF111827),
                              ),
                        ),
                        const SizedBox(height: 14),

                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            // ✅ Remote jobs via location_type filter
                            _chipKeyword('Remote Jobs', keywordOverride: '', locationType: 'remote'),

                            // ✅ WORKING: Free courses (switches to courses mode)
                            _chipKeyword('Free Courses', keywordOverride: 'free', modeOverride: SearchMode.courses),

                            // ⚠️ BACKEND DATA: Returns results based on backend job listings
                            // If "data entry" returns 0, it means no jobs match this keyword in backend
                            _chipKeyword('Entry-Level Data Entry', keywordOverride: 'data entry'),

                            // ✅ WORKING: AI-related jobs keyword search
                            _chipKeyword('Artificial Intelligence', keywordOverride: 'AI'),

                            // ⚠️ BACKEND DATA: Sign language courses (switches to courses mode)
                            // Returns results based on backend course listings
                            _chipKeyword('Sign Language Supported Courses', keywordOverride: 'sign language', modeOverride: SearchMode.courses),

                            // ⚠️ BACKEND DATA: Urgent hiring jobs
                            // Returns results based on is_urgent flag in backend
                            _chipKeyword('Urgent Hiring', keywordOverride: 'urgent'),
                          ],
                        ),



                        const SizedBox(height: 22),

                        Text(
                          'Quick Filter',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF111827),
                              ),
                        ),
                        const SizedBox(height: 14),

                        Column(
                          children: [
                            // ⚠️ LIMITATION: These chips use keyword search, but should ideally use disability filter param
                            // API supports: disability=<id> filter (see home_api.dart line 25)
                            // Current implementation: Uses keyword search as fallback
                            // If these return 0 results, it means:
                            //   1. Backend has no jobs with "blindness"/"deafness" in title/description
                            //   2. OR these jobs use different keywords
                            //   3. OR they should use disability_id filter instead
                            // TODO: Implement filter-based search for disability chips
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _chipKeyword('Jobs for People with Blindness', keywordOverride: 'blindness'),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _chipKeyword('Jobs for People with Deafness', keywordOverride: 'deafness'),
                            ),
                          ],
                        ),

                        const SizedBox(height: 120),
                      ],
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