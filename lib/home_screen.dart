import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_locale.dart';
import 'dashboard_screen.dart';
import 'map_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';
import 'scanner_screen.dart';
import 'shop_screen.dart';
import 'theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0; // Default to Home screen (Dashboard)
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      DashboardScreen(
        onOpenMap: () => setState(() => _index = 1),
        onOpenScanner: _openScanner,
        onOpenNotifications: () => setState(() => _index = 3),
        onOpenProfile: () => setState(() => _index = 4),
      ),
      const MapScreen(),
      ShopScreen(
        onOpenCart: () => setState(() => _index = 2),
      ),
      const NotificationsScreen(),
      const ProfileScreen(),
    ];
  }

  void _openScanner() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ScannerScreen()),
    );
  }

  static const _items = [
    _TabItem(
      unselected: CupertinoIcons.house,
      selected: CupertinoIcons.house_fill,
      labelKey: 'nav_home',
    ),
    _TabItem(
      unselected: CupertinoIcons.map,
      selected: CupertinoIcons.map_fill,
      labelKey: 'nav_map',
    ),
    _TabItem(
      unselected: CupertinoIcons.bag,
      selected: CupertinoIcons.bag_fill,
      labelKey: 'nav_shop',
    ),
    _TabItem(
      unselected: CupertinoIcons.bell,
      selected: CupertinoIcons.bell_fill,
      labelKey: 'nav_notifications',
      hasBadge: true,
    ),
    _TabItem(
      unselected: CupertinoIcons.person,
      selected: CupertinoIcons.person_fill,
      labelKey: 'nav_profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    return ValueListenableBuilder<AppLanguage>(
      valueListenable: languageNotifier,
      builder: (context, lang, _) => Scaffold(
        backgroundColor: p.bg,
        extendBody: false,
        body: IndexedStack(index: _index, children: _pages),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.94),
            border: const Border(
              top: BorderSide(
                color: Color(0xFFDAEAE5),
                width: 1,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF22584D).withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 64,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(_items.length, (i) {
                  final item = _items[i];
                  final sel = i == _index;
                  return _buildItem(i, item, sel);
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildItem(int i, _TabItem item, bool sel) {
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _index = i),
        behavior: HitTestBehavior.opaque,
        child: Container(
          color: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Active top indicator bar (exact Figma: width 27, height 3, #10A188)
              Container(
                height: 3,
                width: 27,
                decoration: BoxDecoration(
                  color: sel ? const Color(0xFF10A188) : Colors.transparent,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(height: 6),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedScale(
                    scale: sel ? 1.05 : 1.0,
                    duration: const Duration(milliseconds: 180),
                    child: Icon(
                      sel ? item.selected : item.unselected,
                      size: 21,
                      color: sel ? const Color(0xFF0B8D79) : const Color(0xFF9AAEAD),
                    ),
                  ),
                  if (item.hasBadge)
                    Positioned(
                      top: -2,
                      right: -3,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF6F61),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                context.tr(item.labelKey),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.dmSans(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                  color: sel ? const Color(0xFF0B8D79) : const Color(0xFF9AAEAD),
                ),
              ),
              const SizedBox(height: 6),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabItem {
  final IconData unselected;
  final IconData selected;
  final String labelKey;
  final bool hasBadge;

  const _TabItem({
    required this.unselected,
    required this.selected,
    required this.labelKey,
    this.hasBadge = false,
  });
}
