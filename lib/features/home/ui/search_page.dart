import 'package:flutter/material.dart';
import '../bloc/search_event.dart';
import 'search_results_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _controller = TextEditingController();
  SearchMode _searchMode = SearchMode.jobs;

  final List<String> popular = const [
    'Remote Jobs',
    'Free Courses',
    'Entry-Level Data Entry',
    'Artificial Intelligence',
    'Sign Language Supported Courses',
    'Urgent Hiring',
  ];

  final List<String> quickFilters = const [
    'Jobs for People with Blindness',
    'Jobs for People with Deafness',
  ];

  void _goSearch(String text) {
    final keyword = text.trim();
    if (keyword.isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SearchResultsPage(
          keyword: keyword,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _chipKeyword(String text, {String? keywordOverride, bool fullWidth = false}) {
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
            _goSearch(keyword);
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
                          children: popular.map<Widget>((t) => _chipKeyword(t)).toList(),
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
                          children: quickFilters
                              .map<Widget>(
                                (t) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _chipKeyword(t),
                                ),
                              )
                              .toList(),
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