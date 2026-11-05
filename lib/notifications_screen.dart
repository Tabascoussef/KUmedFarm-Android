import 'dart:async';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_locale.dart';
import 'scanner_screen.dart';
import 'services/api_service.dart';
import 'services/gemini_scanner_service.dart';
import 'services/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  // Real dynamic notifications (static hardcoded mock items removed completely)
  List<AppNotification> _items = [];

  StreamSubscription? _localNotifSub;
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

    _loadNotifications();

    // Listen to local notifications stream (Gemini AI analysis, reminders, etc.)
    _localNotifSub = NotificationService.instance.stream.listen((list) {
      if (mounted) {
        setState(() {
          _items = List.from(list);
        });
      }
    });

    // Listen to real-time events triggered from Web
    _realtimeSub = ApiService.instance.realtimeStream.listen((event) {
      if (mounted) {
        _fetchApiNotifications();
      }
    });
  }

  @override
  void dispose() {
    _localNotifSub?.cancel();
    _realtimeSub?.cancel();
    _glowController.dispose();
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    // 1. Load local dynamic notifications (including Gemini AI scans)
    final localList = NotificationService.instance.items;
    if (mounted) {
      setState(() {
        _items = List.from(localList);
      });
    }

    // 2. Fetch server notifications if connected
    await _fetchApiNotifications();
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
                AppNotification(
                  id: id,
                  colorType: item['type'] == 'alert'
                      ? 'peach'
                      : item['type'] == 'ai'
                          ? 'violet'
                          : 'mint',
                  title: item['title'] ?? 'Tizim xabari',
                  sub: item['time_label'] ?? item['group_label'] ?? 'Bildirishnoma',
                  body: item['message'] ?? '',
                  time: item['time_label'] ?? 'Hozirgina',
                  type: item['type'] ?? 'system',
                  isGlow: item['is_read'] != true,
                ),
              );
            }
          }
        });
      }
    } catch (_) {}
  }

  void _readAll() async {
    await NotificationService.instance.markAllAsRead();
    setState(() {
      for (var item in _items) {
        item.isGlow = false;
      }
    });
    if (!mounted) return;
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

  void _openGeminiChatModal(AppNotification item) {
    NotificationService.instance.toggleTaken(item.id);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _GeminiConsultationSheet(item: item),
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
                  if (_items.isNotEmpty)
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

              if (_items.isEmpty)
                _buildEmptyState()
              else ...[
                // Group Label
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Soʻnggi xabarlar (${_items.length})',
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF173C43),
                      ),
                    ),
                    Text(
                      'Oʻchirish uchun suring',
                      style: GoogleFonts.dmSans(
                        fontSize: 10,
                        color: const Color(0xFF88A09D),
                      ),
                    ),
                  ],
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 44),
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFBFDFD),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2EDE9)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E4A40).withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF0E9B83).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              CupertinoIcons.bell_slash,
              size: 38,
              color: Color(0xFF0E9B83),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Hozircha yangi bildirishnomalar yoʻq',
            style: GoogleFonts.manrope(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF173C43),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'AI Scanner orqali dori qutisi yoki retseptni suratga olsangiz, Gemini 1.5 Flash tahlil natijalari avtomatik ravishda shu yerga yuboriladi.',
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              fontSize: 12.5,
              color: const Color(0xFF678582),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ScannerScreen()),
              );
            },
            icon: const Icon(CupertinoIcons.camera_viewfinder, size: 18, color: Colors.white),
            label: Text(
              'AI Skanerni ochish',
              style: GoogleFonts.manrope(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0E9B83),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteCard(AppNotification item) {
    if (item.isProcessing) {
      return _buildProcessingCard(item);
    }

    if (item.type == 'ai') {
      return _buildAiCard(item);
    }

    return _buildStandardCard(item);
  }

  /// 1. Pending "AI tahlili tayyorlanmoqda..." state card
  Widget _buildProcessingCard(AppNotification item) {
    final glowVal = _glowAnimation.value;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Color.lerp(
            const Color(0xFFEDE9FE),
            const Color(0xFF7C3AED),
            glowVal * 0.7,
          )!,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withValues(alpha: 0.12 * glowVal),
            blurRadius: 20,
            spreadRadius: 2 * glowVal,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6F61D9), Color(0xFF9061F9)],
                  ),
                  borderRadius: BorderRadius.circular(13),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7C3AED).withValues(alpha: 0.3),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          item.title,
                          style: GoogleFonts.dmSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF6F61D9),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEDE9FE),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 5,
                                height: 5,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF7C3AED),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Tahlil ketmoqda',
                                style: GoogleFonts.manrope(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF7C3AED),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'AI tahlili tayyorlanmoqda...',
                      style: GoogleFonts.manrope(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF173C43),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFAF8FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFEDE9FE)),
            ),
            child: Row(
              children: [
                const Icon(CupertinoIcons.sparkles, color: Color(0xFF7C3AED), size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Gemini AI dori qutisi yoki retseptni tahlil qilmoqda. Natija tayyor boʻlishi bilan shu yerda paydo boʻladi.',
                    style: GoogleFonts.dmSans(
                      fontSize: 11.5,
                      color: const Color(0xFF5B4687),
                      height: 1.35,
                      fontWeight: FontWeight.w500,
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

  /// 2. Finished AI Analysis Notification Card (Tap opens Gemini consultation modal)
  Widget _buildAiCard(AppNotification item) {
    final isGlowing = item.isGlow;
    final glowVal = _glowAnimation.value;
    final bool isMed = item.scanData?['isMedicine'] != false && !item.title.contains('Dori emas');

    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        NotificationService.instance.removeNotification(item.id);
        setState(() {
          _items.removeWhere((x) => x.id == item.id);
        });
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 22),
        decoration: BoxDecoration(
          color: const Color(0xFFEE6C66),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          'Oʻchirish',
          style: GoogleFonts.dmSans(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      child: GestureDetector(
        onTap: () => _openGeminiChatModal(item),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isGlowing
                  ? Color.lerp(
                      const Color(0xFFE5EFEC),
                      isMed ? const Color(0xFF6F61D9) : const Color(0xFFF59E0B),
                      glowVal * 0.7,
                    )!
                  : const Color(0xFFE5EFEC),
              width: isGlowing ? 1.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: (isMed ? const Color(0xFF6F61D9) : const Color(0xFFF59E0B)).withValues(alpha: 0.08),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
              if (isGlowing)
                BoxShadow(
                  color: (isMed ? const Color(0xFF6F61D9) : const Color(0xFFF59E0B)).withValues(alpha: 0.14 * glowVal),
                  blurRadius: 24,
                  spreadRadius: 2 * glowVal,
                  offset: const Offset(0, 8),
                ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isMed
                            ? const [Color(0xFF6F61D9), Color(0xFF0E9B83)]
                            : const [Color(0xFFF59E0B), Color(0xFFEA580C)],
                      ),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Center(
                      child: Icon(
                        isMed ? CupertinoIcons.sparkles : CupertinoIcons.search,
                        size: 22,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                item.title,
                                style: GoogleFonts.dmSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: isMed ? const Color(0xFF6F61D9) : const Color(0xFFD97706),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              item.time,
                              style: GoogleFonts.dmSans(
                                fontSize: 9,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF9AACAB),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item.sub,
                          style: GoogleFonts.manrope(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF173C43),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                item.body,
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  color: const Color(0xFF4A6562),
                  height: 1.4,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),

              // Interactive Consultation Action Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isMed
                        ? const [Color(0xFFEDE9FE), Color(0xFFE6F5F1)]
                        : const [Color(0xFFFEF3C7), Color(0xFFFFF7ED)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isMed ? const Color(0xFFDCD6FD) : const Color(0xFFFDE68A),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isMed ? CupertinoIcons.chat_bubble_2_fill : CupertinoIcons.question_circle_fill,
                      color: isMed ? const Color(0xFF6F61D9) : const Color(0xFFD97706),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isMed ? 'AI Maslahatchi bilan suhbatlashish' : 'AI Maslahatchidan soʻrash',
                        style: GoogleFonts.manrope(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: isMed ? const Color(0xFF53389E) : const Color(0xFFB45309),
                        ),
                      ),
                    ),
                    Icon(
                      CupertinoIcons.chevron_right,
                      color: isMed ? const Color(0xFF6F61D9) : const Color(0xFFD97706),
                      size: 14,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 3. Standard Notification Card
  Widget _buildStandardCard(AppNotification item) {
    Color iconBg;
    Color iconColor;
    IconData iconData;

    switch (item.colorType) {
      case 'blue':
        iconBg = const Color(0xFFE5F1FD);
        iconColor = const Color(0xFF267FC5);
        iconData = CupertinoIcons.car_detailed;
        break;
      case 'mint':
        iconBg = const Color(0xFFDFF5ED);
        iconColor = const Color(0xFF0C947A);
        iconData = CupertinoIcons.heart_fill;
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
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        NotificationService.instance.removeNotification(item.id);
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
          'Oʻchirish',
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
          color: Colors.white.withValues(alpha: 0.95),
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
            // Icon or Scanned Image Thumbnail
            if (item.imagePath != null && File(item.imagePath!).existsSync())
              ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: Image.file(
                  File(item.imagePath!),
                  width: 39,
                  height: 39,
                  fit: BoxFit.cover,
                ),
              )
            else
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
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF55716F),
                        ),
                      ),
                      Text(
                        item.time,
                        style: GoogleFonts.dmSans(
                          fontSize: 8.5,
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
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF173C43),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.body,
                    style: GoogleFonts.dmSans(
                      fontSize: 10,
                      color: const Color(0xFF5A7572),
                      height: 1.35,
                    ),
                  ),
                  // If unread, quick mark as read
                  if (item.isGlow) ...[
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () {
                        NotificationService.instance.toggleTaken(item.id);
                        setState(() {
                          item.isGlow = false;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0E9B83),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.check_rounded,
                              size: 14,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Oʻqilgan deb belgilash',
                              style: GoogleFonts.dmSans(
                                fontSize: 8.5,
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

/// 4. Interactive Gemini Medical Consultation Chat Modal
/// STRICT SAFETY: Answers MUST only be general advice, never prescriptive diagnosis.
class _GeminiConsultationSheet extends StatefulWidget {
  final AppNotification item;
  const _GeminiConsultationSheet({required this.item});

  @override
  State<_GeminiConsultationSheet> createState() => _GeminiConsultationSheetState();
}

class _GeminiConsultationSheetState extends State<_GeminiConsultationSheet> {
  final TextEditingController _ctrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final List<Map<String, String>> _messages = [];
  bool _isGenerating = false;
  Timer? _typingTimer;
  final StringBuffer _typewriterQueue = StringBuffer();

  late final List<String> _quickPrompts;

  @override
  void initState() {
    super.initState();
    final bool isMed = widget.item.scanData?['isMedicine'] != false &&
        !widget.item.title.contains('Dori emas');
    final cleanTitle = widget.item.title
        .replaceAll(RegExp(r'Gemini.*?AI:\s*'), '')
        .replaceAll(' (Dori emas)', '')
        .trim();

    _quickPrompts = isMed
        ? [
            'Qachon va qanday ichish kerak?',
            'Nojoʻya taʼsirlari bormi?',
            'Och qoringa ichsa boʻladimi?',
            'Boshqa dorilar bilan mumkinmi?',
          ]
        : [
            'Nega bu dori emas?',
            'Qanday dori skanerlash kerak?',
            'Retsept qanday skanerlanadi?',
          ];

    if (isMed) {
      _messages.add({
        'role': 'assistant',
        'text': '"$cleanTitle" boʻyicha tahlil tayyor. Qanday savolingiz bor?',
      });
    } else {
      _messages.add({
        'role': 'assistant',
        'text': 'Rasmda "$cleanTitle" aniqlandi. Bu dori vositasi emas. Biron maʼlumot kerakmi?',
      });
    }
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showFullscreenImage(BuildContext context, String path) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(File(path), fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: GestureDetector(
                onTap: () => Navigator.pop(ctx),
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendMessage(String text) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty || _isGenerating) return;

    final bool isMed = widget.item.scanData?['isMedicine'] != false &&
        !widget.item.title.contains('Dori emas');

    _ctrl.clear();

    // Index of the new streaming assistant message
    final int assistantIndex = _messages.length + 1;
    setState(() {
      _messages.add({'role': 'user', 'text': cleanText});
      _messages.add({'role': 'assistant', 'text': '', 'typing': 'true'});
      _isGenerating = true;
    });
    _scrollToBottom();

    // Smooth real-time typewriter queue: types out character-by-character smoothly
    _typewriterQueue.clear();
    _typingTimer?.cancel();
    _typingTimer = Timer.periodic(const Duration(milliseconds: 18), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_typewriterQueue.isNotEmpty) {
        final str = _typewriterQueue.toString();
        // Adaptive speed: slightly faster if chunks pile up, else 1-2 chars
        final take = str.length > 30 ? 4 : (str.length > 12 ? 2 : 1);
        final chunk = str.substring(0, take);
        _typewriterQueue.clear();
        if (str.length > take) {
          _typewriterQueue.write(str.substring(take));
        }

        setState(() {
          if (assistantIndex < _messages.length) {
            final cur = _messages[assistantIndex]['text'] ?? '';
            _messages[assistantIndex]['text'] = cur + chunk;
          }
        });
        _scrollToBottom();
      } else if (!_isGenerating) {
        // Stream completed and queue fully revealed
        setState(() {
          if (assistantIndex < _messages.length) {
            _messages[assistantIndex]['typing'] = 'false';
          }
        });
        timer.cancel();
      }
    });

    // Context from scanned analysis
    final contextBuffer = StringBuffer();
    contextBuffer.writeln('Skanerlangan obʼekt/dori: ${widget.item.title}');
    contextBuffer.writeln('AI xulosasi: ${widget.item.body}');
    if (widget.item.scanData != null) {
      final data = widget.item.scanData!;
      if (data['isMedicine'] != null) {
        contextBuffer.writeln('Dori vositasi ekanligi: ${data['isMedicine']}');
      }
      if (data['detectedObject'] != null) {
        contextBuffer.writeln('Aniqlangan obʼekt: ${data['detectedObject']}');
      }
      if (data['medicines'] != null) {
        contextBuffer.writeln('Dorilar roʻyxati: ${data['medicines']}');
      }
      if (data['doctorNotes'] != null) {
        contextBuffer.writeln('Shifokor eslatmasi: ${data['doctorNotes']}');
      }
    }

    try {
      final stream = GeminiScannerService.instance.askConsultationStream(
        question: cleanText,
        medicineContext: contextBuffer.toString(),
        previousMessages: _messages,
      );

      await for (final chunk in stream) {
        if (!mounted) return;
        _typewriterQueue.write(chunk);
      }
    } catch (_) {
      _typewriterQueue.write(isMed
          ? 'Hozirda ulanishda vaqtinchalik uzilish boʻldi. Iltimos, savolingizni qayta yuboring.'
          : 'Ushbu buyum dori vositasi emas. Dori preparatlari yoki retseptlar boʻyicha savollaringizni berishingiz mumkin.');
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardOpen = bottomInset > 0;
    final bool isMed = widget.item.scanData?['isMedicine'] != false &&
        !widget.item.title.contains('Dori emas');
    final cleanTitle = widget.item.title
        .replaceAll(RegExp(r'Gemini.*?AI:\s*'), '')
        .replaceAll(' (Dori emas)', '')
        .trim();

    if (isKeyboardOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }

    return Container(
      height: MediaQuery.of(context).size.height * (isKeyboardOpen ? 0.95 : 0.88),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: Column(
            children: [
              // 1. Grab handle
              const SizedBox(height: 10),
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD2E4DF),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),

              // 2. Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 14, 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isMed
                              ? const [Color(0xFF6F61D9), Color(0xFF0E9B83)]
                              : const [Color(0xFFF59E0B), Color(0xFFEA580C)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isMed ? CupertinoIcons.sparkles : CupertinoIcons.search,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dr. Shifo AI (Gemini)',
                            style: GoogleFonts.manrope(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF173C43),
                            ),
                          ),
                          Text(
                            isMed
                                ? 'Skanerlangan dori boʻyicha maslahat'
                                : 'Skanerlangan obʼekt boʻyicha maʼlumot',
                            style: GoogleFonts.dmSans(
                              fontSize: 11.5,
                              color: isMed ? const Color(0xFF6F61D9) : const Color(0xFFD97706),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(CupertinoIcons.clear_circled_solid, color: Color(0xFF9EBEB7)),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // 1. Scanned Image & Context Area (Yuklangan rasm va aniqlangan ob'ekt)
              if (widget.item.imagePath != null &&
                  File(widget.item.imagePath!).existsSync()) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isMed ? const Color(0xFFF6F4FF) : const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isMed ? const Color(0xFFDDD6FE) : const Color(0xFFFDE68A),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (isMed ? const Color(0xFF7C3AED) : const Color(0xFFD97706)).withValues(alpha: 0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Scanned photo thumbnail with tap-to-zoom
                        GestureDetector(
                          onTap: () => _showFullscreenImage(context, widget.item.imagePath!),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  File(widget.item.imagePath!),
                                  width: isKeyboardOpen ? 44 : 58,
                                  height: isKeyboardOpen ? 44 : 58,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                right: 3,
                                bottom: 3,
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.65),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(CupertinoIcons.zoom_in, color: Colors.white, size: 9),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Information & Tag
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    isMed ? CupertinoIcons.capsule_fill : CupertinoIcons.camera_fill,
                                    color: isMed ? const Color(0xFF7C3AED) : const Color(0xFFD97706),
                                    size: 13,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    isMed ? 'AI ga yuklangan dori vositasi' : 'AI ga yuklangan rasm',
                                    style: GoogleFonts.dmSans(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: isMed ? const Color(0xFF7C3AED) : const Color(0xFFD97706),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                cleanTitle,
                                style: GoogleFonts.manrope(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                  color: isMed ? const Color(0xFF4C1D95) : const Color(0xFF78350F),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Kattalashtirish uchun rasm ustiga bosing',
                                style: GoogleFonts.dmSans(
                                  fontSize: 9.5,
                                  color: const Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isMed ? const Color(0xFFF3F0FF) : const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isMed ? const Color(0xFFDDD6FE) : const Color(0xFFFDE68A),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isMed ? CupertinoIcons.capsule_fill : CupertinoIcons.search,
                          color: isMed ? const Color(0xFF7C3AED) : const Color(0xFFD97706),
                          size: 14,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            isMed ? 'Aniqlangan dori: $cleanTitle' : 'Aniqlangan obʼekt: $cleanTitle',
                            style: GoogleFonts.manrope(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: isMed ? const Color(0xFF6D28D9) : const Color(0xFF92400E),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              // 2. Strict Safety Advisory Disclaimer Banner (shown when keyboard is closed to maximize chat area)
              if (!isKeyboardOpen) ...[
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFFEDD5)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(CupertinoIcons.shield_lefthalf_fill, color: Color(0xFFEA580C), size: 15),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Muhim eslatma: Ushbu AI javoblari inson salomatligiga qatʼiy tashxis emas, balki faqat umumiy axborot va maslahat tariqasida beriladi. Doimo shifokor bilan maslahatlashing.',
                          style: GoogleFonts.dmSans(
                            fontSize: 10.5,
                            color: const Color(0xFF9A3412),
                            height: 1.3,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 10, color: Color(0xFFE5EFEC)),
              ],

              // 4. Chat Messages List
              Expanded(
                child: ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: _messages.length,
                  itemBuilder: (context, idx) {
                    final msg = _messages[idx];
                    final isUser = msg['role'] == 'user';
                    final isTyping = msg['typing'] == 'true';
                    return _buildChatBubble(
                      text: msg['text'] ?? '',
                      isUser: isUser,
                      isTyping: isTyping,
                    );
                  },
                ),
              ),

              // 5. Quick Suggestion Chips (shown when keyboard is closed)
              if (!isKeyboardOpen) ...[
                SizedBox(
                  height: 38,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: _quickPrompts.length,
                    separatorBuilder: (context, index) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      final prompt = _quickPrompts[i];
                      return GestureDetector(
                        onTap: () => _sendMessage(prompt),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFFBBF7D0)),
                          ),
                          child: Text(
                            prompt,
                            style: GoogleFonts.dmSans(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF15803D),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
              ],

              // 6. Input Field + Send Button
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFA),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: const Color(0xFFD2E4DF)),
                        ),
                        child: TextField(
                          controller: _ctrl,
                          onSubmitted: _sendMessage,
                          style: GoogleFonts.dmSans(fontSize: 13.5, color: const Color(0xFF132F2B)),
                          decoration: InputDecoration(
                            hintText: 'Dori haqida savol bering...',
                            hintStyle: GoogleFonts.dmSans(color: const Color(0xFF8BA5A1), fontSize: 13),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _sendMessage(_ctrl.text),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0E9B83), Color(0xFF10B981)],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0E9B83).withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(CupertinoIcons.arrow_up, color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChatBubble({
    required String text,
    required bool isUser,
    bool isTyping = false,
  }) {
    if (isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10, left: 40),
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0E9B83), Color(0xFF10B981)],
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(4),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0E9B83).withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            text,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              color: Colors.white,
              fontWeight: FontWeight.w500,
              height: 1.35,
            ),
          ),
        ),
      );
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12, right: 30),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFB),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomRight: Radius.circular(18),
            bottomLeft: Radius.circular(4),
          ),
          border: Border.all(color: const Color(0xFFE2EDE9)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(CupertinoIcons.sparkles, color: Color(0xFF6F61D9), size: 13),
                const SizedBox(width: 4),
                Text(
                  'Dr. Shifo AI',
                  style: GoogleFonts.manrope(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF6F61D9),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (text.isEmpty && isTyping)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Color(0xFF6F61D9)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Javob yozilmoqda...',
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: const Color(0xFF6F61D9),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              )
            else
              RichText(
                text: TextSpan(
                  text: text,
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    color: const Color(0xFF1E3A36),
                    height: 1.4,
                  ),
                  children: [
                    if (isTyping)
                      TextSpan(
                        text: ' ▍',
                        style: GoogleFonts.dmSans(
                          color: const Color(0xFF6F61D9),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                  ],
                ),
              ),
            if (!isTyping || text.length > 20) ...[
              const SizedBox(height: 6),
              Text(
                '* Faqat umumiy maslahat tariqasida.',
                style: GoogleFonts.dmSans(
                  fontSize: 9.5,
                  color: const Color(0xFF9AACAB),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
