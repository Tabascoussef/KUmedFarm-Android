import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_locale.dart';
import 'services/api_service.dart';

class NotificationNote {
  final String id;
  final String colorType; // 'mint' | 'blue' | 'violet' | 'peach'
  final String title;
  final String sub;
  final String body;
  final String time;
  bool isGlow;
  bool isTaken;

  NotificationNote({
    required this.id,
    required this.colorType,
    required this.title,
    required this.sub,
    required this.body,
    required this.time,
    this.isGlow = false,
    this.isTaken = false,
  });
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  final List<NotificationNote> _items = [
    NotificationNote(
      id: '1',
      colorType: 'mint',
      title: 'Medicine reminder',
      sub: 'Time to take Vitamin D3',
      body: 'Take 1 capsule after breakfast',
      time: '9:00 AM',
      isGlow: true,
    ),
    NotificationNote(
      id: '2',
      colorType: 'blue',
      title: 'Delivery on the way',
      sub: 'Your courier is 8 minutes away',
      body: 'Order #UF-2048',
      time: '10:32 AM',
      isGlow: false,
    ),
    NotificationNote(
      id: '3',
      colorType: 'violet',
      title: 'Prescription verified',
      sub: 'Your prescription is ready to shop',
      body: 'View recommended medicines',
      time: 'Yesterday',
      isGlow: false,
    ),
    NotificationNote(
      id: '4',
      colorType: 'peach',
      title: 'Weekly health tip',
      sub: 'Small walks make a big difference',
      body: 'A 15-minute walk can improve your mood.',
      time: 'Mon',
      isGlow: false,
    ),
  ];

  StreamSubscription? _realtimeSub;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _fetchApiNotifications();

    // Listen to real-time events triggered from Web
    _realtimeSub = ApiService.instance.realtimeStream.listen((event) {
      if (mounted) {
        _fetchApiNotifications();
      }
    });
  }

  @override
  void dispose() {
    _realtimeSub?.cancel();
    _glowController.dispose();
    super.dispose();
  }

  Future<void> _fetchApiNotifications() async {
    try {
      final list = await ApiService.instance.getNotifications();
      if (list.isNotEmpty && mounted) {
        setState(() {
          for (var item in list) {
            final id = item['id']?.toString() ?? UniqueKey().toString();
            if (!_items.any((n) => n.id == id)) {
              _items.insert(
                0,
                NotificationNote(
                  id: id,
                  colorType: item['type'] == 'alert' ? 'peach' : item['type'] == 'ai' ? 'violet' : 'mint',
                  title: item['title'] ?? 'System alert',
                  sub: item['time_label'] ?? item['group_label'] ?? 'Notification',
                  body: item['message'] ?? '',
                  time: item['time_label'] ?? 'Hozirgina',
                  isGlow: item['is_read'] != true,
                ),
              );
            }
          }
        });
      }
    } catch (_) {}
  }

  void _readAll() {
    setState(() {
      for (var item in _items) {
        item.isGlow = false;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          context.tr('all_read_toast'),
          style: GoogleFonts.dmSans(color: Colors.white, fontSize: 13),
        ),
        backgroundColor: const Color(0xFF173C43),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 10, 22, 110),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: STAY UPDATED / Notifications + Read all button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('alerts_eyebrow'),
                        style: GoogleFonts.dmSans(
                          fontSize: 9,
                          letterSpacing: 1.3,
                          color: const Color(0xFF0E8F7D),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        context.tr('notifications'),
                        style: GoogleFonts.manrope(
                          fontSize: 26,
                          letterSpacing: -0.8,
                          color: const Color(0xFF173C43),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: _readAll,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE6F5F1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.check_rounded,
                            size: 16,
                            color: Color(0xFF0B8C77),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            context.tr('read_all'),
                            style: GoogleFonts.dmSans(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0B8C77),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Group Label: Today
              Text(
                context.tr('today'),
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF173C43),
                ),
              ),
              const SizedBox(height: 10),

              // Note List
              AnimatedBuilder(
                animation: _glowAnimation,
                builder: (context, _) {
                  return Column(
                    children: _items.map((item) => _buildNoteCard(item)).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoteCard(NotificationNote item) {
    Color iconBg;
    Color iconColor;
    IconData iconData;

    switch (item.colorType) {
      case 'mint':
        iconBg = const Color(0xFFDFF5ED);
        iconColor = const Color(0xFF0C947A);
        iconData = CupertinoIcons.heart_fill;
        break;
      case 'blue':
        iconBg = const Color(0xFFE5F1FD);
        iconColor = const Color(0xFF267FC5);
        iconData = CupertinoIcons.car_detailed;
        break;
      case 'violet':
        iconBg = const Color(0xFFEEEBFF);
        iconColor = const Color(0xFF6F61D9);
        iconData = CupertinoIcons.viewfinder;
        break;
      case 'peach':
      default:
        iconBg = const Color(0xFFFFF0E9);
        iconColor = const Color(0xFFEF765B);
        iconData = CupertinoIcons.bell_fill;
        break;
    }

    final isGlowing = item.isGlow;
    final glowVal = _glowAnimation.value;

    return Dismissible(
      key: Key(item.id + item.title),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        setState(() {
          _items.removeWhere((x) => x.id == item.id);
        });
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 9),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 22),
        decoration: BoxDecoration(
          color: const Color(0xFFEE6C66),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          'Dismiss',
          style: GoogleFonts.dmSans(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 9),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isGlowing
                ? Color.lerp(
                    const Color(0xFFE5EFEC),
                    const Color(0xFF0E9B83),
                    glowVal * 0.7,
                  )!
                : const Color(0xFFE5EFEC),
            width: isGlowing ? 1.4 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1E4A40).withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 7),
            ),
            if (isGlowing)
              BoxShadow(
                color: const Color(0xFF0E917B).withValues(alpha: 0.14 * glowVal),
                blurRadius: 25,
                spreadRadius: 2 * glowVal,
                offset: const Offset(0, 8),
              ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 39,
              height: 39,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Center(
                child: Icon(iconData, size: 20, color: iconColor),
              ),
            ),
            const SizedBox(width: 11),

            // Copy
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item.title,
                        style: GoogleFonts.dmSans(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF55716F),
                        ),
                      ),
                      Text(
                        item.time,
                        style: GoogleFonts.dmSans(
                          fontSize: 8,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF9AACAB),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    item.sub,
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF173C43),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.body,
                    style: GoogleFonts.dmSans(
                      fontSize: 9,
                      color: const Color(0xFF718785),
                      height: 1.3,
                    ),
                  ),
                  // Taken button if item 1 (Medicine reminder)
                  if (item.title == 'Medicine reminder') ...[
                    const SizedBox(height: 9),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          item.isGlow = false;
                          item.isTaken = !item.isTaken;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                        decoration: BoxDecoration(
                          color: item.isTaken ? const Color(0xFF173C43) : const Color(0xFF0E917B),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.check_rounded,
                              size: 15,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              item.isTaken
                                  ? context.tr('taken')
                                  : context.tr('mark_as_taken'),
                              style: GoogleFonts.dmSans(
                                fontSize: 8,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
