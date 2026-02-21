import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/network/dio_client.dart';
import '../auth/data/auth_api.dart';
import '../auth/data/auth_repo.dart';
import '../auth/ui/auth_gate.dart';
import '../home/bloc/home_bloc.dart';
import '../home/bloc/home_event.dart';
import '../home/data/home_api.dart';
import '../home/data/home_repo.dart';
import '../home/ui/home_page.dart';
import '../home/ui/saved_items_page.dart';
import '../home/ui/search_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;
  int _previousIndex = 0;

  late final HomeRepo _homeRepo;
  final GlobalKey<_SavedItemsPageWrapperState> _savedItemsKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _homeRepo = HomeRepo(HomeApi(DioClient.dio));
  }

  void _onTabChanged(int newIndex) {
    setState(() {
      _previousIndex = _index;
      _index = newIndex;
    });

    // Refresh SavedItems when navigating to it (with small delay to ensure API calls finish)
    if (newIndex == 3 && _previousIndex != 3) {
      // Add small delay to ensure any pending save/unsave API calls complete
      Future.delayed(const Duration(milliseconds: 300), () {
        _savedItemsKey.currentState?.refresh();
      });
    }
  }

  late final List<Widget> _tabs = [
    BlocProvider(
      create: (_) => HomeBloc(_homeRepo)..add(const HomeLoadRequested()),
      child: HomePage(
        onTapSearch: () => _onTabChanged(1),
      ),
    ),
    const SearchPage(),
    const _TodoPage(title: 'Post Job'),
    _SavedItemsPageWrapper(
      key: _savedItemsKey,
      onBackToHome: () => _onTabChanged(0),
    ),
    const _MorePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: Container(
  decoration: const BoxDecoration(
    color: Colors.white,
    border: Border(
      top: BorderSide(
        color: Color(0xFFCAC9C9), // نفس اللي ظاهر بالفيمجا
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
                isSelected: _index == 0,
                onTap: () => _onTabChanged(0),
              ),
              _NavItem(
                icon: Icons.search,
                activeIcon: Icons.search,
                label: 'Explore',
                isSelected: _index == 1,
                onTap: () => _onTabChanged(1),
              ),
              // Post Job - center button exactly like Figma
              GestureDetector(
                onTap: () => _onTabChanged(2),
                child: Container(
                  width: 88,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2B9FDB), // Figma blue color
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
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
                isSelected: _index == 3,
                onTap: () => _onTabChanged(3),
              ),
              _NavItemWithCircle(
                label: 'More',
                isSelected: _index == 4,
                onTap: () => _onTabChanged(4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Figma colors - blue for selected, gray for unselected
    final color = isSelected ? const Color(0xFF2B9FDB) : const Color(0xFF8F959E);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 60,
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

// Custom widget for More button with circle and dots
class _NavItemWithCircle extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItemWithCircle({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? const Color(0xFF2B9FDB) : const Color(0xFF8F959E);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 60,
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

// Small dot widget
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

class _TodoPage extends StatelessWidget {
  final String title;
  const _TodoPage({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: const Center(
        child: Text(
          'Coming soon',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _MorePage extends StatefulWidget {
  const _MorePage();

  @override
  State<_MorePage> createState() => _MorePageState();
}

class _MorePageState extends State<_MorePage> {
  bool _loggingOut = false;
  bool _clearingCache = false;

  Future<void> _clearCache() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text(
          'This will clear all cached data including:\n'
          '• Saved authentication token\n'
          '• Local preferences\n'
          '• Cached API responses\n\n'
          'You will need to login again. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: const Text('Clear Cache'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _clearingCache = true);

    try {
      // Clear token
      await DioClient.tokenStorage.clearToken();

      // Clear shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // Show success message
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Cache cleared successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      // Navigate to auth gate after a short delay
      await Future.delayed(const Duration(seconds: 1));

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthGate()),
        (_) => false,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error clearing cache: $e'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _clearingCache = false);
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Logout')),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _loggingOut = true);

    final repo = AuthRepo(
      api: AuthApi(DioClient.dio),
      tokenStorage: DioClient.tokenStorage,
    );
    await repo.logout();

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthGate()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        title: const Text('More'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 20),

          // Clear Cache
          ListTile(
            leading: const Icon(Icons.cleaning_services, color: Colors.orange),
            title: const Text(
              'Clear Cache',
              style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w700),
            ),
            subtitle: const Text(
              'Clear all cached data and reset app',
              style: TextStyle(fontSize: 12),
            ),
            trailing: _clearingCache
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.chevron_right),
            onTap: _clearingCache ? null : _clearCache,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            tileColor: Colors.white,
          ),

          const SizedBox(height: 12),

          // Logout
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700)),
            trailing: _loggingOut
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.chevron_right),
            onTap: _loggingOut ? null : _logout,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            tileColor: Colors.white,
          ),
        ],
      ),
    );
  }
}

class _SavedItemsPageWrapper extends StatefulWidget {
  final VoidCallback? onBackToHome;

  const _SavedItemsPageWrapper({super.key, this.onBackToHome});

  @override
  State<_SavedItemsPageWrapper> createState() => _SavedItemsPageWrapperState();
}

class _SavedItemsPageWrapperState extends State<_SavedItemsPageWrapper> {
  final GlobalKey<_SavedItemsPageInternalState> _pageKey = GlobalKey();

  void refresh() {
    _pageKey.currentState?.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return _SavedItemsPageInternal(
      key: _pageKey,
      onBackToHome: widget.onBackToHome,
    );
  }
}

class _SavedItemsPageInternal extends StatefulWidget {
  final VoidCallback? onBackToHome;

  const _SavedItemsPageInternal({super.key, this.onBackToHome});

  @override
  State<_SavedItemsPageInternal> createState() => _SavedItemsPageInternalState();
}

class _SavedItemsPageInternalState extends State<_SavedItemsPageInternal> {
  int _refreshKey = 0;

  void refresh() {
    setState(() {
      _refreshKey++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Use UniqueKey to force rebuild when refresh is called
    return SavedItemsPage(
      key: ValueKey(_refreshKey),
      onBackToHome: widget.onBackToHome,
    );
  }
}
