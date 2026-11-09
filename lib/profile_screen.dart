import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'app_locale.dart';
import 'login_screen.dart';
import 'screens/antigravity_showcase_screen.dart';
import 'services/api_service.dart';
import 'services/location_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _selectedTab = 0; // 0: Profile & Sozlamalar, 1: Analitika

  // User profile state
  String _userName = 'Aziza Usmanova';
  String _userRole = 'Medical client';
  String _userCity = 'Tashkent';
  String _userPhone = '+998 90 123 45 67';
  String _userEmail = 'aziza.usmanova@gmail.com';

  // Settings state
  bool _notifPush = true;
  bool _notifReminders = true;
  bool _notifOrders = true;
  bool _biometricEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadProfileFromApi();
  }

  Future<void> _loadProfileFromApi() async {
    try {
      final user = await ApiService.instance.getProfile();
      if (mounted) {
        setState(() {
          if (user['name'] != null && (user['name'] as String).isNotEmpty) {
            String name = (user['name'] as String)
                .replaceAll(RegExp(r'\(.*rejim.*\)', caseSensitive: false), '')
                .replaceAll('rejim)', '')
                .replaceAll('(offline)', '')
                .replaceAll('(Offline)', '')
                .trim();
            if (name == 'KUAFmedFarm Admin' || name == 'KUmedFarm Admin' || name.isEmpty) {
              name = 'Aziza Usmanova';
            }
            _userName = name;
          }
          if (user['email'] != null && (user['email'] as String).isNotEmpty) {
            _userEmail = user['email'];
          }
          if (user['phone'] != null && (user['phone'] as String).isNotEmpty) {
            _userPhone = user['phone'];
          }
          if (user['role'] != null && (user['role'] as String).isNotEmpty) {
            _userRole = user['role'];
          }
          if (user['city'] != null && (user['city'] as String).isNotEmpty) {
            _userCity = user['city'];
          }
          final locCity = LocationService.instance.currentLocation.value?.city;
          if (locCity != null && locCity.isNotEmpty) {
            _userCity = locCity;
          }
        });
      }
    } catch (_) {}
  }

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return 'AU';
  }

  void _showEditProfileModal() {
    final nameCtrl = TextEditingController(text: _userName);
    final phoneCtrl = TextEditingController(text: _userPhone);
    final emailCtrl = TextEditingController(text: _userEmail);
    final cityCtrl = TextEditingController(text: _userCity);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Color(0x1F22584D),
              blurRadius: 30,
              offset: Offset(0, -10),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              22,
              14,
              22,
              MediaQuery.of(ctx).viewInsets.bottom + 16,
            ),
            child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Grabber
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD8E4E1),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('profile_eyebrow'),
                        style: GoogleFonts.dmSans(
                          fontSize: 9,
                          letterSpacing: 1.3,
                          color: const Color(0xFF0E8F7D),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        context.tr('edit'),
                        style: GoogleFonts.manrope(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF173C43),
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F7F5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: Color(0xFF758B8E),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              _buildInputField('F.I.SH / Ism', nameCtrl, CupertinoIcons.person),
              const SizedBox(height: 12),
              _buildInputField('Telefon raqam', phoneCtrl, CupertinoIcons.phone),
              const SizedBox(height: 12),
              _buildInputField('Email pochta', emailCtrl, CupertinoIcons.mail),
              const SizedBox(height: 12),
              _buildInputField('Shahar / Hudud', cityCtrl, CupertinoIcons.location),
              const SizedBox(height: 20),

              // Save button
              GestureDetector(
                onTap: () {
                  setState(() {
                    if (nameCtrl.text.trim().isNotEmpty) _userName = nameCtrl.text.trim();
                    if (phoneCtrl.text.trim().isNotEmpty) _userPhone = phoneCtrl.text.trim();
                    if (emailCtrl.text.trim().isNotEmpty) _userEmail = emailCtrl.text.trim();
                    if (cityCtrl.text.trim().isNotEmpty) _userCity = cityCtrl.text.trim();
                  });
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        context.tr('save_changes'),
                        style: GoogleFonts.dmSans(color: Colors.white, fontSize: 13),
                      ),
                      backgroundColor: const Color(0xFF173C43),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                },
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF173F48),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF173F48).withValues(alpha: 0.25),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      context.tr('save_changes'),
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  ),
);
}

  Widget _buildInputField(String label, TextEditingController ctrl, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF758B8E),
          ),
        ),
        const SizedBox(height: 5),
        Container(
          height: 46,
          decoration: BoxDecoration(
            color: const Color(0xFFF7FBF9),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2EDE9)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              Icon(icon, size: 16, color: const Color(0xFF0E8F7D)),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: ctrl,
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    color: const Color(0xFF173C43),
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showLanguageModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ValueListenableBuilder<AppLanguage>(
        valueListenable: languageNotifier,
        builder: (context, currentLang, _) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 14, 22, 16),
                child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD8E4E1),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      context.tr('language'),
                      style: GoogleFonts.manrope(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF173C43),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF758B8E)),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                for (final lang in AppLanguage.values) ...[
                  GestureDetector(
                    onTap: () {
                      S.setLanguage(lang);
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: currentLang == lang ? const Color(0xFFEDF8F5) : const Color(0xFFF8FCFA),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: currentLang == lang ? const Color(0xFF0E9B83) : const Color(0xFFE2EDE9),
                          width: currentLang == lang ? 1.5 : 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE0F2ED),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              lang.flag,
                              style: GoogleFonts.manrope(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0E9B83),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              lang.name,
                              style: GoogleFonts.dmSans(
                                fontSize: 14,
                                fontWeight: currentLang == lang ? FontWeight.w700 : FontWeight.w500,
                                color: currentLang == lang ? const Color(0xFF0E8F7D) : const Color(0xFF173C43),
                              ),
                            ),
                          ),
                          if (currentLang == lang)
                            const Icon(
                              Icons.check_circle_rounded,
                              color: Color(0xFF0E9B83),
                              size: 20,
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    },
      ),
    );
  }

  void _showNotificationsModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 16),
              child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD8E4E1),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                context.tr('notifications'),
                style: GoogleFonts.manrope(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF173C43),
                ),
              ),
              const SizedBox(height: 16),
              _buildSwitchRow(
                title: 'Push bildirishnomalar',
                subtitle: 'Muhim retseptlar va xabarlar',
                value: _notifPush,
                onChanged: (v) {
                  setSheetState(() => _notifPush = v);
                  setState(() => _notifPush = v);
                },
              ),
              const Divider(height: 20, color: Color(0xFFEDF4F2)),
              _buildSwitchRow(
                title: 'Dori eslatmalari',
                subtitle: 'Kunlik qabul vaqtlari eslatmasi',
                value: _notifReminders,
                onChanged: (v) {
                  setSheetState(() => _notifReminders = v);
                  setState(() => _notifReminders = v);
                },
              ),
              const Divider(height: 20, color: Color(0xFFEDF4F2)),
              _buildSwitchRow(
                title: 'Buyurtmalar holati',
                subtitle: 'Kuryer va dorixona yangiliklari',
                value: _notifOrders,
                onChanged: (v) {
                  setSheetState(() => _notifOrders = v);
                  setState(() => _notifOrders = v);
                },
              ),
            ],
          ),
        ),
      ),
    ),
  ),
);
}

  void _showSecurityModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 16),
              child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD8E4E1),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                context.tr('security'),
                style: GoogleFonts.manrope(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF173C43),
                ),
              ),
              const SizedBox(height: 16),
              _buildSwitchRow(
                title: 'Biometrik kirish (Face ID / Barmoq)',
                subtitle: 'Ilovaga tez va xavfsiz kirish',
                value: _biometricEnabled,
                onChanged: (v) {
                  setSheetState(() => _biometricEnabled = v);
                  setState(() => _biometricEnabled = v);
                },
              ),
            ],
          ),
        ),
      ),
    ),
  ),
);
}

  void _showSupportModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 14, 22, 16),
            child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD8E4E1),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              context.tr('help_support'),
              style: GoogleFonts.manrope(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF173C43),
              ),
            ),
            const SizedBox(height: 16),
            _buildActionCard(
              icon: CupertinoIcons.phone_fill,
              iconBg: const Color(0xFFDFF5ED),
              iconColor: const Color(0xFF0E987E),
              title: 'Mijozlar bilan aloqa markazi',
              subtitle: '+998 71 200 00 24 · 24/7 Yordam',
              onTap: () async {
                final uri = Uri.parse('tel:+998712000024');
                if (await canLaunchUrl(uri)) await launchUrl(uri);
              },
            ),
            const SizedBox(height: 10),
            _buildActionCard(
              icon: CupertinoIcons.paperplane_fill,
              iconBg: const Color(0xFFE1EFFC),
              iconColor: const Color(0xFF2782CC),
              title: 'Telegram yordam boti',
              subtitle: '@kuafmedfarm_support',
              onTap: () async {
                final uri = Uri.parse('https://t.me/telegram');
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
            ),
          ],
        ),
      ),
    ),
  ),
);
}

  void _showLogoutDialog() {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(
          context.tr('logout_confirm_title'),
          style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
        ),
        content: Text(
          context.tr('logout_confirm_desc'),
          style: GoogleFonts.dmSans(fontSize: 13),
        ),
        actions: [
          CupertinoDialogAction(
            child: Text(context.tr('cancel'), style: GoogleFonts.dmSans()),
            onPressed: () => Navigator.pop(ctx),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: Text(context.tr('logout'), style: GoogleFonts.dmSans(fontWeight: FontWeight.w700)),
            onPressed: () async {
              Navigator.pop(ctx);
              await ApiService.instance.logout();
              if (mounted) {
                Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
    );
  }

  void _downloadPdfReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                context.tr('pdf_downloading_toast'),
                style: GoogleFonts.dmSans(color: Colors.white, fontSize: 13),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF0E9680),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final initials = _getInitials(_userName);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 10, 22, 110),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header (Eyebrow & Title)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('profile_eyebrow'),
                        style: GoogleFonts.dmSans(
                          fontSize: 9,
                          letterSpacing: 1.3,
                          color: const Color(0xFF0E8F7D),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _selectedTab == 0 ? context.tr('nav_profile') : context.tr('tab_analytics'),
                        style: GoogleFonts.manrope(
                          fontSize: 26,
                          letterSpacing: -0.8,
                          color: const Color(0xFF173C43),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  if (_selectedTab == 0)
                    GestureDetector(
                      onTap: _showEditProfileModal,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE6F5F1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              CupertinoIcons.pencil,
                              size: 15,
                              color: Color(0xFF0B8C77),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              context.tr('edit'),
                              style: GoogleFonts.dmSans(
                                fontSize: 10,
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
              const SizedBox(height: 16),

              // 2. Segmented Tabs Switcher (Profile / Sozlamalar VS Analitika)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F7F5),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFFE2EDE9)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedTab = 0),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          decoration: BoxDecoration(
                            color: _selectedTab == 0 ? const Color(0xFF173F48) : Colors.transparent,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: _selectedTab == 0
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFF173F48).withValues(alpha: 0.2),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  CupertinoIcons.person_fill,
                                  size: 15,
                                  color: _selectedTab == 0 ? Colors.white : const Color(0xFF758B8E),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  context.tr('tab_profile'),
                                  style: GoogleFonts.dmSans(
                                    fontSize: 11.5,
                                    fontWeight: _selectedTab == 0 ? FontWeight.w700 : FontWeight.w600,
                                    color: _selectedTab == 0 ? Colors.white : const Color(0xFF758B8E),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedTab = 1),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          decoration: BoxDecoration(
                            color: _selectedTab == 1 ? const Color(0xFF173F48) : Colors.transparent,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: _selectedTab == 1
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFF173F48).withValues(alpha: 0.2),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  CupertinoIcons.chart_bar_alt_fill,
                                  size: 15,
                                  color: _selectedTab == 1 ? Colors.white : const Color(0xFF758B8E),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  context.tr('tab_analytics'),
                                  style: GoogleFonts.dmSans(
                                    fontSize: 11.5,
                                    fontWeight: _selectedTab == 1 ? FontWeight.w700 : FontWeight.w600,
                                    color: _selectedTab == 1 ? Colors.white : const Color(0xFF758B8E),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // TAB 0: PROFILE & SETTINGS
              if (_selectedTab == 0) ...[
                // User Hero Card (1:1 with avatar squircle and gradients)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: const Color(0xFFE5EFEC)),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF20564B).withValues(alpha: 0.07),
                        blurRadius: 24,
                        offset: const Offset(0, 9),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Squircle avatar: 54x54, gradient #164C57 -> #1B87A6, #35D39A dot
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFF164C57), Color(0xFF1B87A6)],
                              ),
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF164C57).withValues(alpha: 0.25),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                initials,
                                style: GoogleFonts.dmSans(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            right: -2,
                            bottom: 0,
                            child: Container(
                              width: 13,
                              height: 13,
                              decoration: BoxDecoration(
                                color: const Color(0xFF35D39A),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2.5),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 14),

                      // User name & subtitle
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _userName,
                              style: GoogleFonts.manrope(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF173C43),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$_userRole · $_userCity',
                              style: GoogleFonts.dmSans(
                                fontSize: 11,
                                color: const Color(0xFF758B8E),
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _userPhone,
                              style: GoogleFonts.dmSans(
                                fontSize: 10.5,
                                color: const Color(0xFF0E8F7D),
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Quick Health & Activity Stats (4 cards matching .quick-grid)
                Text(
                  context.tr('health_overview'),
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF173C43),
                  ),
                ),
                const SizedBox(height: 10),

                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.85,
                  children: [
                    _buildQuickStatCard(
                      title: context.tr('stat_prescriptions'),
                      subtitle: '3 tasdiqlangan',
                      icon: CupertinoIcons.doc_text_fill,
                      iconBg: const Color(0xFFECEAFD),
                      iconColor: const Color(0xFF665BE4),
                    ),
                    _buildQuickStatCard(
                      title: context.tr('stat_orders'),
                      subtitle: '5 yetkazilgan',
                      icon: CupertinoIcons.bag_fill,
                      iconBg: const Color(0xFFE1EFFC),
                      iconColor: const Color(0xFF2782CC),
                    ),
                    _buildQuickStatCard(
                      title: context.tr('stat_saved'),
                      subtitle: '12 dori',
                      icon: CupertinoIcons.heart_fill,
                      iconBg: const Color(0xFFDFF5ED),
                      iconColor: const Color(0xFF0E987E),
                    ),
                    _buildQuickStatCard(
                      title: context.tr('stat_reminders'),
                      subtitle: '4 faol',
                      icon: CupertinoIcons.bell_fill,
                      iconBg: const Color(0xFFFFF0E9),
                      iconColor: const Color(0xFFEF795C),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Settings Sections
                Text(
                  context.tr('settings_pref'),
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF173C43),
                  ),
                ),
                const SizedBox(height: 10),

                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE5EFEC)),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1E4A40).withValues(alpha: 0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 7),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildSettingsRow(
                        icon: CupertinoIcons.globe,
                        iconBg: const Color(0xFFEDF8F5),
                        iconColor: const Color(0xFF0E9B83),
                        title: context.tr('language'),
                        subtitle: S.lang.name,
                        onTap: _showLanguageModal,
                      ),
                      _buildDivider(),
                      _buildSettingsRow(
                        icon: CupertinoIcons.bell_fill,
                        iconBg: const Color(0xFFFFF0E9),
                        iconColor: const Color(0xFFEF795C),
                        title: context.tr('notifications'),
                        subtitle: 'Eslatmalar, buyurtmalar va push',
                        onTap: _showNotificationsModal,
                      ),
                      _buildDivider(),
                      _buildSettingsRow(
                        icon: CupertinoIcons.lock_shield_fill,
                        iconBg: const Color(0xFFECEAFD),
                        iconColor: const Color(0xFF665BE4),
                        title: context.tr('security'),
                        subtitle: 'Biometriya va parollar',
                        onTap: _showSecurityModal,
                      ),
                      _buildDivider(),
                      _buildSettingsRow(
                        icon: CupertinoIcons.sparkles,
                        iconBg: const Color(0xFFE8F5E9),
                        iconColor: const Color(0xFF0E9B83),
                        title: 'Antigravitatsiya Fizikasi',
                        subtitle: '60-120 FPS suzuvchi kosmik elementlar',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const AntigravityShowcaseScreen(),
                            ),
                          );
                        },
                      ),
                      _buildDivider(),
                      _buildSettingsRow(
                        icon: CupertinoIcons.question_circle_fill,
                        iconBg: const Color(0xFFE1EFFC),
                        iconColor: const Color(0xFF2782CC),
                        title: context.tr('help_support'),
                        subtitle: '24/7 Call center & Telegram chat',
                        onTap: _showSupportModal,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Logout Button
                GestureDetector(
                  onTap: _showLogoutDialog,
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF1F0),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFFFD9D6)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          CupertinoIcons.square_arrow_right,
                          size: 18,
                          color: Color(0xFFEE6C66),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          context.tr('logout'),
                          style: GoogleFonts.manrope(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFEE6C66),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              // TAB 1: ANALYTICS (ANALITIKA & HISOBOT)
              if (_selectedTab == 1) ...[
                // KPI Grid
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.6,
                  children: [
                    _buildKpiCard(
                      label: context.tr('kpi_plan'),
                      value: context.tr('kpi_plan_value'),
                      badge: '+6% o\'sish',
                      icon: CupertinoIcons.chart_pie_fill,
                      accentColor: const Color(0xFF0E9B83),
                      bgColor: const Color(0xFFE8F7F3),
                    ),
                    _buildKpiCard(
                      label: context.tr('kpi_visits'),
                      value: context.tr('kpi_visits_value'),
                      badge: 'Norma: 40',
                      icon: CupertinoIcons.location_solid,
                      accentColor: const Color(0xFF2782CC),
                      bgColor: const Color(0xFFE5F1FC),
                    ),
                    _buildKpiCard(
                      label: context.tr('kpi_orders'),
                      value: context.tr('kpi_orders_value'),
                      badge: '100% yetkazildi',
                      icon: CupertinoIcons.cube_box_fill,
                      accentColor: const Color(0xFF665BE4),
                      bgColor: const Color(0xFFECEAFD),
                    ),
                    _buildKpiCard(
                      label: context.tr('kpi_turnover'),
                      value: context.tr('kpi_turnover_value'),
                      badge: 'Bu oy',
                      icon: CupertinoIcons.money_dollar_circle_fill,
                      accentColor: const Color(0xFFEF795C),
                      bgColor: const Color(0xFFFFF0E9),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Weekly Visit Dynamics Card (Haftalik grafik)
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: const Color(0xFFE5EFEC)),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1E4A40).withValues(alpha: 0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 7),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.tr('weekly_visits_title'),
                                style: GoogleFonts.manrope(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF173C43),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Dush - Yaksh oralig\'idagi tashriflar',
                                style: GoogleFonts.dmSans(
                                  fontSize: 10,
                                  color: const Color(0xFF758B8E),
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F7F3),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Ort. 7.5 / kun',
                              style: GoogleFonts.dmSans(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0E9B83),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Bar visual chart
                      SizedBox(
                        height: 110,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            _buildBarCol('Dush', 6, 10),
                            _buildBarCol('Sesh', 8, 10),
                            _buildBarCol('Chor', 9, 10),
                            _buildBarCol('Pay', 7, 10),
                            _buildBarCol('Juma', 10, 10, isPeak: true),
                            _buildBarCol('Shan', 5, 10),
                            _buildBarCol('Yak', 0, 10),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Pharmacy Monitoring Card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: const Color(0xFFE5EFEC)),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1E4A40).withValues(alpha: 0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 7),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('pharmacy_monitoring_title'),
                        style: GoogleFonts.manrope(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF173C43),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildPharmacyRow('Oqtepa Pharmacy', context.tr('pharmacy_1_status'), '1.2 km', true),
                      const Divider(height: 18, color: Color(0xFFEDF4F2)),
                      _buildPharmacyRow('Shifo Farm Central', context.tr('pharmacy_2_status'), '2.4 km', true),
                      const Divider(height: 18, color: Color(0xFFEDF4F2)),
                      _buildPharmacyRow('Grand Dori-Darmon', context.tr('pharmacy_3_status'), '3.1 km', false),
                      const Divider(height: 18, color: Color(0xFFEDF4F2)),
                      _buildPharmacyRow('Eco Farma', context.tr('pharmacy_4_status'), '3.8 km', true),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Download PDF Analytical Report Button
                GestureDetector(
                  onTap: _downloadPdfReport,
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0E9680), Color(0xFF146ECB)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0E9680).withValues(alpha: 0.28),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          CupertinoIcons.arrow_down_doc_fill,
                          size: 18,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          context.tr('download_pdf_btn'),
                          style: GoogleFonts.manrope(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 14),

              Center(
                child: Text(
                  'KUAFmedFarm Medical App v2.4.0',
                  style: GoogleFonts.dmSans(
                    fontSize: 10,
                    color: const Color(0xFF9AACAB),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKpiCard({
    required String label,
    required String value,
    required String badge,
    required IconData icon,
    required Color accentColor,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5EFEC)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF20564B).withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Center(
                  child: Icon(icon, size: 17, color: accentColor),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F6F4),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badge,
                  style: GoogleFonts.dmSans(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0E8F7D),
                  ),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.manrope(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF173C43),
                ),
              ),
              const SizedBox(height: 1),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.dmSans(
                  fontSize: 10,
                  color: const Color(0xFF758B8E),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBarCol(String day, int val, int max, {bool isPeak = false}) {
    final heightRatio = val / max;
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (val > 0)
          Text(
            '$val',
            style: GoogleFonts.dmSans(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: isPeak ? const Color(0xFF0E9B83) : const Color(0xFF758B8E),
            ),
          ),
        const SizedBox(height: 4),
        Container(
          width: 24,
          height: 65 * heightRatio + 4,
          decoration: BoxDecoration(
            gradient: isPeak
                ? const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF35D39A), Color(0xFF0E9B83)],
                  )
                : const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF146ECB), Color(0xFF0E9680)],
                  ),
            borderRadius: BorderRadius.circular(7),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          day,
          style: GoogleFonts.dmSans(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF758B8E),
          ),
        ),
      ],
    );
  }

  Widget _buildPharmacyRow(String name, String sub, String dist, bool isOpen) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: isOpen ? const Color(0xFF35D39A) : const Color(0xFFEF795C),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF173C43),
                ),
              ),
              Text(
                sub,
                style: GoogleFonts.dmSans(
                  fontSize: 9.5,
                  color: const Color(0xFF758B8E),
                ),
              ),
            ],
          ),
        ),
        Text(
          dist,
          style: GoogleFonts.dmSans(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF0E8F7D),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStatCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.7)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF20564B).withValues(alpha: 0.07),
            blurRadius: 24,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Icon(icon, size: 20, color: iconColor),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.dmSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF173C43),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.dmSans(
                    fontSize: 9.5,
                    color: const Color(0xFF758B8E),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsRow({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Center(
                child: Icon(icon, size: 19, color: iconColor),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF173C43),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.dmSans(
                      fontSize: 10,
                      color: const Color(0xFF758B8E),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              CupertinoIcons.chevron_forward,
              size: 14,
              color: Color(0xFF9AACAB),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 14),
      color: const Color(0xFFEDF4F2),
    );
  }

  Widget _buildSwitchRow({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF173C43),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.dmSans(
                  fontSize: 10,
                  color: const Color(0xFF758B8E),
                ),
              ),
            ],
          ),
        ),
        CupertinoSwitch(
          value: value,
          activeTrackColor: const Color(0xFF0E9B83),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF7FBF9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2EDE9)),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Center(
                child: Icon(icon, size: 19, color: iconColor),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF173C43),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.dmSans(
                      fontSize: 10,
                      color: const Color(0xFF758B8E),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              CupertinoIcons.arrow_up_right,
              size: 14,
              color: Color(0xFF758B8E),
            ),
          ],
        ),
      ),
    );
  }
}
