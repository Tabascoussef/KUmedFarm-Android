import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'app_locale.dart';
import 'cart_screen.dart';
import 'services/api_service.dart';
import 'services/cart_service.dart';
import 'services/location_service.dart';
import 'theme.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback? onOpenMap;
  final VoidCallback? onOpenScanner;
  final VoidCallback? onOpenNotifications;
  final VoidCallback? onOpenProfile;

  const DashboardScreen({
    super.key,
    this.onOpenMap,
    this.onOpenScanner,
    this.onOpenNotifications,
    this.onOpenProfile,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _search = '';
  bool _isLoadingData = false;
  int _activeDealIndex = 0;
  final PageController _dealPageController = PageController();
  Timer? _dealTimer;

  final List<Map<String, dynamic>> _deals = [
    {
      'title': 'Daily essentials',
      'sub': 'Save 25% on vitamins',
      'product': 'VITAMIN C',
      'off': '25%',
      'dose': '60 gummies',
      'raw_price': 85000,
      'price': "85 000 so'm",
    },
    {
      'title': 'Care for your heart',
      'sub': 'Wellness picks for every day',
      'product': 'OMEGA 3',
      'off': '20%',
      'dose': '1000 mg · 90 caps',
      'raw_price': 110000,
      'price': "110 000 so'm",
    },
    {
      'title': 'Better sleep',
      'sub': 'Nighttime care collection',
      'product': 'MAGNESIUM',
      'off': '15%',
      'dose': '30 capsules',
      'raw_price': 54000,
      'price': "54 000 so'm",
    },
  ];

  final List<Map<String, dynamic>> _medicines = [
    {
      'id': 1,
      'name': 'Kardiomagnil',
      'dose': '75 mg · 100 dona',
      'price': "42 000 so'm",
      'raw_price': 42000,
      'category': 'Kardiologiya',
      'stock': 140,
      'icon': CupertinoIcons.heart_fill,
      'tag': 'Yurak uchun',
    },
    {
      'id': 2,
      'name': 'Amoksiklav',
      'dose': '625 mg · 14 tabletka',
      'price': "68 000 so'm",
      'raw_price': 68000,
      'category': 'Antibiotik',
      'stock': 85,
      'icon': CupertinoIcons.bandage_fill,
      'tag': 'Retseptli',
    },
    {
      'id': 3,
      'name': 'D3 Vitamini',
      'dose': '15 000 XB/ml · Tomchi',
      'price': "35 000 so'm",
      'raw_price': 35000,
      'category': 'Vitaminlar',
      'stock': 110,
      'icon': CupertinoIcons.capsule_fill,
      'tag': 'Immunitet',
    },
    {
      'id': 4,
      'name': 'Nurofen Forte',
      'dose': '400 mg · 12 kapsula',
      'price': "28 000 so'm",
      'raw_price': 28000,
      'category': "Og'riq qoldiruvchi",
      'stock': 95,
      'icon': CupertinoIcons.bolt_fill,
      'tag': 'Tezkor',
    },
    {
      'id': 5,
      'name': 'Magniy B6',
      'dose': '500 mg · 60 tabletka',
      'price': "54 000 so'm",
      'raw_price': 54000,
      'category': 'Sedativ',
      'stock': 70,
      'icon': CupertinoIcons.moon_stars_fill,
      'tag': 'Uyqu uchun',
    },
  ];

  final List<Map<String, dynamic>> _todayTasks = [
    {
      'time': '14:30',
      'title': 'Shifo Farm dorixonasi',
      'sub': 'Dori vositalarini qabul qilish',
    },
    {
      'time': '16:00',
      'title': 'Kardiologiya markazi',
      'sub': 'Taqdimot va shifokorlar uchrashuvi',
    },
    {
      'time': '18:15',
      'title': 'Markaziy ombor',
      'sub': 'Zaxiralar va partiya monitoringi',
    },
  ];

  List<Map<String, dynamic>> _livePharmacies = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardFromApi();
    LocationService.instance.detectCurrentLocation().then((loc) {
      if (mounted) {
        _loadRealPharmacies(loc.latitude, loc.longitude);
      }
    });
    LocationService.instance.currentLocation.addListener(_onDashboardLocationChanged);
    _dealTimer = Timer.periodic(const Duration(milliseconds: 3800), (t) {
      if (!mounted || !_dealPageController.hasClients) return;
      final next = (_activeDealIndex + 1) % _deals.length;
      _dealPageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 700),
        curve: const Cubic(0.2, 0.8, 0.2, 1.0),
      );
    });
  }

  @override
  void dispose() {
    LocationService.instance.currentLocation.removeListener(_onDashboardLocationChanged);
    _dealTimer?.cancel();
    _dealPageController.dispose();
    super.dispose();
  }

  void _onDashboardLocationChanged() {
    final loc = LocationService.instance.currentLocation.value;
    if (loc != null && mounted) {
      _loadRealPharmacies(loc.latitude, loc.longitude);
    }
  }

  void _loadRealPharmacies(double lat, double lng) async {
    try {
      final list = await LocationService.instance.fetchRealPharmaciesFromMap(lat, lng);
      if (mounted && list.isNotEmpty) {
        setState(() {
          _livePharmacies = list;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadDashboardFromApi() async {
    setState(() => _isLoadingData = true);
    try {
      final data = await ApiService.instance.getDashboardData();
      if (!mounted) return;

      if (data['today_tasks'] != null && (data['today_tasks'] as List).isNotEmpty) {
        final serverTasks = data['today_tasks'] as List;
        setState(() {
          _todayTasks.clear();
          for (var t in serverTasks) {
            _todayTasks.add({
              'time': t['time'] ?? '14:00',
              'title': t['title'] ?? '',
              'sub': t['sub'] ?? '',
            });
          }
        });
      }

      if (data['medicines'] != null && (data['medicines'] as List).isNotEmpty) {
        final serverMeds = data['medicines'] as List;
        setState(() {
          _medicines.clear();
          for (var m in serverMeds) {
            _medicines.add({
              'id': m['id'],
              'name': m['name'] ?? '',
              'dose': m['dose'] ?? '',
              'price': m['price'] ?? '',
              'raw_price': m['raw_price'] ?? 42000,
              'category': m['category'] ?? 'Umumiy',
              'stock': m['stock'] ?? 100,
              'icon': CupertinoIcons.capsule_fill,
              'tag': m['category'] ?? 'Dori',
            });
          }
        });
      }
    } catch (_) {
      // Graceful fallback to default data
    } finally {
      if (mounted) {
        setState(() => _isLoadingData = false);
      }
    }
  }

  void _showDoctorConsultation(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  CupertinoIcons.videocam_fill,
                  color: Color(0xFFF97316),
                  size: 36,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Onlayn Shifokor Konsultatsiyasi',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0C382E),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Malakali shifokorlarimiz sizga 24/7 rejimida video va chat orqali tibbiy maslahat berishga tayyor.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0C382E),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  icon: const Icon(CupertinoIcons.phone_fill, color: Colors.white, size: 18),
                  label: const Text(
                    'Shifokorga bog\'lanish',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Navbatchi shifokor bilan video aloqa o\'rnatilmoqda...'),
                        backgroundColor: Color(0xFF14C97E),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  },
);
}

  void _showOrderDialog(BuildContext context, [Map<String, dynamic>? preselectedMedicine]) {
    final med = preselectedMedicine ?? (_medicines.isNotEmpty ? _medicines.first : null);
    if (med == null) return;

    final pharmacyCtrl = TextEditingController(text: 'Shifo Farm dorixonasi');
    final notesCtrl = TextEditingController();
    int qty = 10;
    double unitPrice = 0.0;

    if (med['raw_price'] != null) {
      unitPrice = (med['raw_price'] as num).toDouble();
    } else {
      final cleaned = med['price'].toString().replaceAll(RegExp(r'[^0-9]'), '');
      unitPrice = double.tryParse(cleaned) ?? 42000.0;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final total = unitPrice * qty;
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.only(
                    top: 20,
                    left: 20,
                    right: 20,
                    bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Dori Buyurtmasi Berish',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0C382E),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20, color: Colors.grey),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4FBF7),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF14C97E).withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF14C97E),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(CupertinoIcons.capsule_fill, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                med['name'] ?? '',
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                              ),
                              Text(
                                med['dose'] ?? '',
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${unitPrice.toInt()} so\'m',
                          style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF14C97E), fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text('Dorixona / Qabul qiluvchi', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: pharmacyCtrl,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF9FDFB),
                      hintText: 'Dorixona nomi',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Buyurtma soni (dona):', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      Row(
                        children: [
                          IconButton(
                            onPressed: qty > 1 ? () => setModalState(() => qty--) : null,
                            icon: const Icon(CupertinoIcons.minus_circle_fill, color: Color(0xFF14C97E)),
                          ),
                          Text(
                            '$qty',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            onPressed: () => setModalState(() => qty++),
                            icon: const Icon(CupertinoIcons.plus_circle_fill, color: Color(0xFF14C97E)),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Jami summa:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey)),
                      Text(
                        '${total.toInt()} so\'m',
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF0C382E)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF14C97E),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        Navigator.of(ctx).pop();
                        final pharmacyName = pharmacyCtrl.text.trim().isNotEmpty
                            ? pharmacyCtrl.text.trim()
                            : 'Shifo Farm dorixonasi';

                        final res = await ApiService.instance.createOrder(
                          pharmacyName: pharmacyName,
                          totalAmount: total,
                          items: [
                            {
                              'name': med['name'],
                              'dose': med['dose'],
                              'qty': qty,
                              'price': unitPrice,
                            }
                          ],
                          notes: notesCtrl.text.trim().isNotEmpty ? notesCtrl.text.trim() : 'Mobil ilova orqali buyurtma berildi',
                        );

                        if (!mounted) return;
                        if (res['success'] == true) {
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('Buyurtma muvaffaqiyatli qabul qilindi va navbatga joylashtirildi!'),
                              backgroundColor: Color(0xFF14C97E),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          _loadDashboardFromApi();
                        } else {
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(res['message'] ?? 'Buyurtma berishda xatolik yuz berdi'),
                              backgroundColor: Colors.redAccent,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                      child: const Text('Buyurtmani Tasdiqlash', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    return ValueListenableBuilder<AppLanguage>(
      valueListenable: languageNotifier,
      builder: (context, lang, _) => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Color(0xFFF4FAF8)],
            begin: Alignment(-0.8, -0.6),
            end: Alignment(0.8, 0.6),
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 10, 22, 0),
            children: [
              // 1. Exact Top Bar (Avatar AU with online dot, Good morning Aziza Usmanova, Cart 2)
              _buildFigmaHeader(p),

              if (_isLoadingData) ...[
                const SizedBox(height: 8),
                const LinearProgressIndicator(
                  minHeight: 2,
                  color: Color(0xFF0E9B83),
                  backgroundColor: Colors.transparent,
                ),
              ],

              const SizedBox(height: 18),

              // 2. Exact Search Bar
              _buildFigmaSearchBar(p),

              const SizedBox(height: 14),

              // 3. Exact Hero Banner with Animated Doctor Mascot
              _buildHealthAssistantBanner(),

              const SizedBox(height: 21),

              // 4. Exact Quick Access Grid (4 cards)
              _buildQuickAccessSection(p),

              const SizedBox(height: 21),

              // 5. Exact Daily Deals Carousel (3 deals)
              _buildDailyDealsSection(),

              const SizedBox(height: 24),

              // 6. Nearest Pharmacies Section (Eng yaqin dorixonalar)
              _buildNearestPharmaciesSection(p),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // 1. TOP BAR (1:1 with D:\src\App.tsx topbar)
  // ===========================================================================
  Widget _buildFigmaHeader(Palette p) {
    final user = ApiService.instance.currentUser;
    final rawName = user?['name']?.toString() ?? 'Aziza Usmanova';
    final cleaned = rawName
        .replaceAll('(Offline rejim)', '')
        .replaceAll('(offline rejim)', '')
        .replaceAll('(offline)', '')
        .trim();
    final userName = (cleaned == 'KUmedFarm Admin' || cleaned.isEmpty)
        ? 'Aziza Usmanova'
        : cleaned;

    String initials = 'AU';
    final parts = userName.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      initials = (parts[0][0] + parts[1][0]).toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      initials = parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Avatar: 42x42, radius 15, linear-gradient(145deg, #164c57, #1b87a6)
        GestureDetector(
          onTap: () => widget.onOpenProfile?.call(),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF164C57), Color(0xFF1B87A6)],
                    begin: Alignment(-0.8, -0.6),
                    end: Alignment(0.8, 0.6),
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              // Online dot: 10x10, #35d39a, 2px white border
              Positioned(
                bottom: 1,
                right: -2,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: const Color(0xFF35D39A),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 11),

        // Greeting: Good morning / Aziza Usmanova
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                context.tr('greeting_morning'),
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF758B8E),
                ),
              ),
              const SizedBox(height: 1),
              Text(
                userName,
                style: GoogleFonts.manrope(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF173C43),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              // Live GPS Location Indicator
              ValueListenableBuilder<UserLocation?>(
                valueListenable: LocationService.instance.currentLocation,
                builder: (context, loc, _) {
                  final text = loc?.shortAddress ?? 'Joylashuv aniqlanmoqda...';
                  return GestureDetector(
                    onTap: () {
                      LocationService.instance.detectCurrentLocation(force: true);
                      widget.onOpenMap?.call();
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          CupertinoIcons.location_solid,
                          size: 11,
                          color: Color(0xFF0E9B83),
                        ),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            text,
                            style: GoogleFonts.dmSans(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF0E8F7D),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          size: 13,
                          color: Color(0xFF0E8F7D),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),

        // Cart icon button with live badge
        ValueListenableBuilder<List<CartItem>>(
          valueListenable: CartService.instance.items,
          builder: (context, cartItems, _) {
            final count = CartService.instance.totalCount;
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CartScreen()),
                );
              },
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF22584D).withValues(alpha: 0.08),
                          blurRadius: 18,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        CupertinoIcons.bag,
                        color: Color(0xFF173C43),
                        size: 20,
                      ),
                    ),
                  ),
                  if (count > 0)
                    Positioned(
                      top: -3,
                      right: -2,
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF6F61),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Center(
                          child: Text(
                            '$count',
                            style: GoogleFonts.dmSans(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              height: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  // ===========================================================================
  // 2. SEARCH BAR (1:1 with D:\src\App.tsx search)
  // ===========================================================================
  Widget _buildFigmaSearchBar(Palette p) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 13),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFE0EEEA)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2A554C).withValues(alpha: 0.06),
            blurRadius: 25,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            CupertinoIcons.search,
            color: Color(0xFF8AA09F),
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              onChanged: (v) => setState(() => _search = v.trim()),
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: const Color(0xFF173C43),
                fontWeight: FontWeight.w400,
              ),
              decoration: InputDecoration(
                hintText: context.tr('search_placeholder'),
                hintStyle: GoogleFonts.dmSans(
                  fontSize: 13,
                  color: const Color(0xFF8AA09F),
                  fontWeight: FontWeight.w400,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          if (_search.isNotEmpty)
            GestureDetector(
              onTap: () => setState(() => _search = ''),
              child: const Padding(
                padding: EdgeInsets.only(right: 6),
                child: Icon(CupertinoIcons.clear_circled_solid, color: Colors.grey, size: 18),
              ),
            ),
          GestureDetector(
            onTap: () => widget.onOpenScanner?.call(),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFE5F5F1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Icon(
                  CupertinoIcons.qrcode_viewfinder,
                  color: Color(0xFF0E8E78),
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 3. HERO BANNER (1:1 with D:\src\App.tsx hero + Doctor mascot)
  // ===========================================================================
  Widget _buildHealthAssistantBanner() {
    return Container(
      width: double.infinity,
      height: 205,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE3F7F0), Color(0xFFD9F0F4), Color(0xFFE6EAFD)],
          stops: [0.0, 0.55, 1.0],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(27),
        border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF173C43).withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(27),
        child: Stack(
          children: [
            // Circular halo: width 160, height 160, right -40, top -55
            Positioned(
              right: -40,
              top: -55,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 1),
                ),
              ),
            ),

            // Left copy content strictly constrained to avoid any mascot overlap
            Positioned(
              left: 20,
              top: 18,
              bottom: 18,
              right: 146,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    context.tr('hero_eyebrow'),
                    style: GoogleFonts.dmSans(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0E8F7D),
                      letterSpacing: 1.2,
                    ),
                  ),
                  Text(
                    context.tr('hero_title'),
                    style: GoogleFonts.manrope(
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF143E49),
                      height: 1.15,
                      letterSpacing: -0.5,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    context.tr('hero_subtitle'),
                    style: GoogleFonts.dmSans(
                      fontSize: 10.5,
                      color: const Color(0xFF557578),
                      fontWeight: FontWeight.w400,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  GestureDetector(
                    onTap: () => _showDoctorConsultation(context),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          context.tr('hero_explore'),
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF087D76),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          color: Color(0xFF087D76),
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Exact Doctor mascot (width 164, height 205, right -8, bottom -15)
            const Positioned(
              right: -8,
              bottom: -15,
              width: 164,
              height: 205,
              child: DoctorMascotWidget(),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 4. QUICK ACCESS GRID (1:1 with D:\src\App.tsx quick-grid)
  // ===========================================================================
  Widget _buildQuickAccessSection(Palette p) {
    final List<Map<String, dynamic>> items = [
      {
        'title': context.tr('action_prescription'),
        'sub': context.tr('action_prescription_sub'),
        'icon': CupertinoIcons.viewfinder,
        'accent': const Color(0xFF665BE4),
        'bg': const Color(0xFFECEAFD),
        'onTap': () => widget.onOpenScanner?.call(),
      },
      {
        'title': context.tr('action_pharmacies'),
        'sub': context.tr('action_pharmacies_sub'),
        'icon': CupertinoIcons.location_solid,
        'accent': const Color(0xFF0E987E),
        'bg': const Color(0xFFDFF5ED),
        'onTap': () => widget.onOpenMap?.call(),
      },
      {
        'title': context.tr('action_delivery'),
        'sub': context.tr('action_delivery_sub'),
        'icon': CupertinoIcons.car_fill,
        'accent': const Color(0xFF2782CC),
        'bg': const Color(0xFFE1EFFC),
        'onTap': () => _showOrderDialog(context),
      },
      {
        'title': context.tr('action_doctor'),
        'sub': context.tr('action_doctor_sub'),
        'icon': CupertinoIcons.videocam, // Outline only, not filled!
        'accent': const Color(0xFFEF795C),
        'bg': const Color(0xFFFFF0E9),
        'onTap': () => _showDoctorConsultation(context),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              context.tr('quick_access'),
              style: GoogleFonts.manrope(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF173C43),
              ),
            ),
            GestureDetector(
              onTap: () => widget.onOpenMap?.call(),
              child: Text(
                context.tr('view_all'),
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0E8D7A),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.75,
          ),
          itemBuilder: (ctx, i) {
            final item = items[i];
            return GestureDetector(
              onTap: item['onTap'] as VoidCallback,
              child: Container(
                height: 94,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.74),
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
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: item['bg'] as Color,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        item['icon'] as IconData,
                        color: item['accent'] as Color,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            item['title'] as String,
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF173C43),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item['sub'] as String,
                            style: GoogleFonts.dmSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFF758B8E),
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
            );
          },
        ),
      ],
    );
  }

  // ===========================================================================
  // 5. DAILY DEALS (1:1 with D:\src\App.tsx deal-window & medicine-box)
  // ===========================================================================
  Widget _buildDailyDealsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              context.tr('daily_deals'),
              style: GoogleFonts.manrope(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF173C43),
              ),
            ),
            // Dots: inactive 5x5 #c6d8d4, active 15x5 #15947e
            Row(
              children: List.generate(_deals.length, (idx) {
                final isSel = idx == _activeDealIndex;
                return GestureDetector(
                  onTap: () {
                    _dealPageController.animateToPage(
                      idx,
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    width: isSel ? 15 : 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: isSel ? const Color(0xFF15947E) : const Color(0xFFC6D8D4),
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 148,
          child: PageView.builder(
            clipBehavior: Clip.none,
            controller: _dealPageController,
            onPageChanged: (idx) => setState(() => _activeDealIndex = idx),
            itemCount: _deals.length,
            itemBuilder: (ctx, idx) {
              final d = _deals[idx];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF153F49), Color(0xFF0C7F81)],
                    begin: Alignment(-0.8, -0.6),
                    end: Alignment(0.8, 0.6),
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF153F49).withValues(alpha: 0.22),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Padding(
                    padding: const EdgeInsets.all(17),
                    child: Row(
                  children: [
                    // Left textual content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${d['off']} OFF',
                              style: GoogleFonts.dmSans(
                                fontSize: 8,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.0,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          Text(
                            d['title']!,
                            style: GoogleFonts.manrope(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            d['sub']!,
                            style: GoogleFonts.dmSans(
                              fontSize: 10,
                              color: const Color(0xFFBFE0DC),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _showOrderDialog(context, {
                              'name': d['product'],
                              'dose': d['dose'],
                              'raw_price': d['raw_price'],
                              'price': d['price'],
                            }),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  context.tr('shop_now'),
                                  style: GoogleFonts.dmSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.arrow_forward_rounded,
                                  color: Colors.white,
                                  size: 15,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Right 3D medicine box: 75x95, rotate 8deg, shadow 12px 14px 22px
                    Transform.rotate(
                      angle: 8 * math.pi / 180,
                      child: Container(
                        width: 75,
                        height: 95,
                        margin: const EdgeInsets.symmetric(horizontal: 7, vertical: 8),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Colors.white, Color(0xFFDCECEA)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(7),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.22),
                              blurRadius: 22,
                              offset: const Offset(12, 14),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'UMED',
                              style: GoogleFonts.dmSans(
                                fontSize: 7,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF176268),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              d['product']!,
                              style: GoogleFonts.manrope(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF176268),
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '30 capsules',
                              style: GoogleFonts.dmSans(
                                fontSize: 6,
                                color: const Color(0xFF809998),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    ),
    const SizedBox(height: 12),
      ],
    );
  }

  // ===========================================================================
  // 6. NEAREST PHARMACIES SECTION (Eng yaqin dorixonalar)
  // ===========================================================================
  Widget _buildNearestPharmaciesSection(Palette p) {
    return ValueListenableBuilder<UserLocation?>(
      valueListenable: LocationService.instance.currentLocation,
      builder: (context, userLoc, _) {
        final double userLat = userLoc?.latitude ?? 41.3111;
        final double userLng = userLoc?.longitude ?? 69.2797;

        final List<Map<String, dynamic>> sourceList = _livePharmacies.isNotEmpty
            ? _livePharmacies
            : LocationService.verifiedTashkentPharmacies;

        // Compute distances dynamically from real user location
        final List<Map<String, dynamic>> sortedList = sourceList.map((item) {
          final meters = LocationService.instance.calculateDistance(
            userLat,
            userLng,
            item['lat'] as double,
            item['lng'] as double,
          );
          return {
            ...item,
            'distanceMeters': meters,
            'distanceStr': LocationService.instance.formatDistance(meters),
            'walkEta': LocationService.instance.formatWalkTime(meters),
            'driveEta': LocationService.instance.formatDriveTime(meters),
          };
        }).toList();

        // Sort ascending by distance: closest first!
        sortedList.sort((a, b) =>
            (a['distanceMeters'] as double).compareTo(b['distanceMeters'] as double));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'YAQIN MANZILLAR',
                      style: GoogleFonts.dmSans(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: const Color(0xFF0E8F7D),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Eng yaqin dorixonalar',
                      style: GoogleFonts.manrope(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF173C43),
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () => widget.onOpenMap?.call(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2F7EF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Xaritada',
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0E7A5D),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          size: 13,
                          color: Color(0xFF0E7A5D),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Top 3 Nearest Pharmacy Cards
            ...sortedList.take(3).map((pharm) {
              final isClosest = pharm['id'] == sortedList.first['id'];
              return _buildPharmacyCard(pharm, isClosest);
            }),
          ],
        );
      },
    );
  }

  Widget _buildPharmacyCard(Map<String, dynamic> pharm, bool isClosest) {
    return GestureDetector(
      onTap: () => widget.onOpenMap?.call(),
      child: Container(
        margin: const EdgeInsets.only(bottom: 11),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isClosest ? const Color(0xFFF6FCF9) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isClosest
                ? const Color(0xFF0E9B83).withValues(alpha: 0.35)
                : const Color(0xFFE5EEEA),
            width: isClosest ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isClosest
                  ? const Color(0xFF0E9B83).withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.03),
              blurRadius: 16,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Store Icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isClosest
                          ? [const Color(0xFFD4F7EB), const Color(0xFFB8EFE0)]
                          : [const Color(0xFFEDF8F5), const Color(0xFFD8EFE9)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Center(
                        child: Text(
                          '+',
                          style: GoogleFonts.dmSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0E9B83),
                            height: 1.0,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Name & Address
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (isClosest) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                              margin: const EdgeInsets.only(right: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0E9B83),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.star, size: 8, color: Colors.white),
                                  const SizedBox(width: 2),
                                  Text(
                                    'ENG YAQIN',
                                    style: GoogleFonts.dmSans(
                                      fontSize: 7.5,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          Text(
                            pharm['isOpen24'] == true ? '24/7 OCHIQ' : (pharm['hours'] ?? 'OCHIQ'),
                            style: GoogleFonts.dmSans(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                              color: const Color(0xFF07966E),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        pharm['name'] ?? '',
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF173C43),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 1),
                      Text(
                        pharm['address'] ?? '',
                        style: GoogleFonts.dmSans(
                          fontSize: 10.5,
                          color: const Color(0xFF758B8E),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Rating Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF9E6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_rounded, size: 12, color: Colors.amber),
                      const SizedBox(width: 2),
                      Text(
                        pharm['rating'] ?? '4.9',
                        style: GoogleFonts.dmSans(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF9E7000),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Bottom Info & Quick Actions
            Row(
              children: [
                // Distance badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDF8F5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        CupertinoIcons.location_solid,
                        size: 11,
                        color: Color(0xFF0E9B83),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${pharm['distanceStr']} · ${pharm['walkEta']}',
                        style: GoogleFonts.dmSans(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0E7A5D),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),

                // Phone Call button
                GestureDetector(
                  onTap: () async {
                    final uri = Uri.parse('tel:${pharm['phone']}');
                    if (await canLaunchUrl(uri)) launchUrl(uri);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F7F5),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFDEEBE7)),
                    ),
                    child: const Icon(
                      CupertinoIcons.phone_fill,
                      size: 14,
                      color: Color(0xFF0E9B83),
                    ),
                  ),
                ),
                const SizedBox(width: 6),

                // Route button
                GestureDetector(
                  onTap: () async {
                    final uri = Uri.parse(
                      'https://www.google.com/maps/dir/?api=1&destination=${pharm['lat']},${pharm['lng']}',
                    );
                    if (await canLaunchUrl(uri)) {
                      launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0E9B83), Color(0xFF146ECB)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          CupertinoIcons.arrow_up_right_diamond_fill,
                          size: 11,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Marshrut',
                          style: GoogleFonts.manrope(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// DOCTOR MASCOT WIDGET (1:1 with D:\src\App.tsx Doctor + breath & wave anim)
// =============================================================================
class DoctorMascotWidget extends StatefulWidget {
  final bool compact;
  const DoctorMascotWidget({super.key, this.compact = false});

  @override
  State<DoctorMascotWidget> createState() => _DoctorMascotWidgetState();
}

class _DoctorMascotWidgetState extends State<DoctorMascotWidget>
    with TickerProviderStateMixin {
  late final AnimationController _breathController;
  late final AnimationController _waveController;
  bool _showGreeting = false;

  @override
  void initState() {
    super.initState();
    // breath: 3.4s ease-in-out infinite
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3400),
    )..repeat(reverse: true);

    // wave: 1.1s ease-in-out 0 to -18deg
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _breathController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  void _onTap() {
    setState(() => _showGreeting = true);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showGreeting = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onTap,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Breath animation: 50% { transform: translateY(-3px) scale(1.012) }
          AnimatedBuilder(
            animation: Listenable.merge([_breathController, _waveController]),
            builder: (context, child) {
              final breathProgress = math.sin(_breathController.value * math.pi);
              final dy = -3.0 * breathProgress;
              final scale = 1.0 + 0.012 * breathProgress;
              final waveAngle = -18.0 * math.pi / 180.0 * math.sin(_waveController.value * math.pi);

              return Transform.translate(
                offset: Offset(0, dy),
                child: Transform.scale(
                  scale: scale,
                  child: CustomPaint(
                    size: Size(widget.compact ? 90 : 164, widget.compact ? 115 : 205),
                    painter: _DoctorMascotPainter(waveAngle: waveAngle),
                  ),
                ),
              );
            },
          ),

          // Cheerful speech bubble on tap
          if (_showGreeting)
            Positioned(
              top: 5,
              right: 15,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF173C43),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.16),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  'Salom!\nDr. Umed xizmatingizda!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(
                    color: Colors.white,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// =============================================================================
// VECTOR PAINTER FOR DOCTOR MASCOT (Exact SVG paths from D:\src\App.tsx)
// =============================================================================
class _DoctorMascotPainter extends CustomPainter {
  final double waveAngle;

  const _DoctorMascotPainter({required this.waveAngle});

  @override
  void paint(Canvas canvas, Size size) {
    // Original viewBox is 170 x 220
    final scaleX = size.width / 170.0;
    final scaleY = size.height / 220.0;
    canvas.save();
    canvas.scale(scaleX, scaleY);

    // 1. Ellipse shadow: cx="88" cy="205" rx="48" ry="9" fill="#0e8388" opacity=".12"
    final shadowPaint = Paint()..color = const Color(0xFF0E8388).withValues(alpha: 0.12);
    canvas.drawOval(Rect.fromCenter(center: const Offset(88, 205), width: 96, height: 18), shadowPaint);

    // 2. White doctor coat gradient (#fff to #dcefeb)
    final coatPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Colors.white, Color(0xFFDCEFEB)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(const Rect.fromLTWH(0, 0, 170, 220));

    // Coat Left: M63 79c-21 7-29 30-30 67l30 3 6-43z
    final coatLeft = Path()
      ..moveTo(63, 79)
      ..cubicTo(42, 86, 34, 109, 33, 146)
      ..lineTo(63, 149)
      ..lineTo(69, 106)
      ..close();
    canvas.drawPath(coatLeft, coatPaint);

    // Coat Right: M106 80c23 7 28 31 30 66l-31 3-7-42z
    final coatRight = Path()
      ..moveTo(106, 80)
      ..cubicTo(129, 87, 134, 111, 136, 146)
      ..lineTo(105, 149)
      ..lineTo(98, 107)
      ..close();
    canvas.drawPath(coatRight, coatPaint);

    // Coat Center: M56 93c9-18 54-20 65 1l-5 82H59z
    final coatCenter = Path()
      ..moveTo(56, 93)
      ..cubicTo(65, 75, 110, 73, 121, 94)
      ..lineTo(116, 176)
      ..lineTo(59, 176)
      ..close();
    canvas.drawPath(coatCenter, coatPaint);

    // Collar: m83 87 7 15 9-15 fill #c9e8e1
    final collarPaint = Paint()..color = const Color(0xFFC9E8E1);
    final collarPath = Path()
      ..moveTo(83, 87)
      ..lineTo(90, 102)
      ..lineTo(99, 87)
      ..close();
    canvas.drawPath(collarPath, collarPaint);

    // Lapels: m74 86 12 18-12 12-10-24 & m118 80 -13 18 12 12 10-24
    final lapelPaint = Paint()..color = Colors.white;
    final lapelStroke = Paint()
      ..color = const Color(0xFFD7EBE6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final lapelLeft = Path()
      ..moveTo(74, 86)
      ..lineTo(86, 104)
      ..lineTo(74, 116)
      ..lineTo(64, 92)
      ..close();
    canvas.drawPath(lapelLeft, lapelPaint);
    canvas.drawPath(lapelLeft, lapelStroke);

    final lapelRight = Path()
      ..moveTo(118, 80)
      ..lineTo(105, 98)
      ..lineTo(117, 110)
      ..lineTo(127, 86)
      ..close();
    canvas.drawPath(lapelRight, lapelPaint);
    canvas.drawPath(lapelRight, lapelStroke);

    // Center seam: M84 104v65 stroke #c7dfda width 2
    final seamPaint = Paint()
      ..color = const Color(0xFFC7DFDA)
      ..strokeWidth = 2;
    canvas.drawLine(const Offset(84, 104), const Offset(84, 169), seamPaint);

    // Buttons: circle cx="89" cy="126" r="3" & cy="143" r="3" fill="#0e8388"
    final btnPaint = Paint()..color = const Color(0xFF0E8388);
    canvas.drawCircle(const Offset(89, 126), 3, btnPaint);
    canvas.drawCircle(const Offset(89, 143), 3, btnPaint);

    // Pants: M65 176 58 207h23l8-31m19 0 7 31H92l-3-31 fill #215c70
    final pantsPaint = Paint()..color = const Color(0xFF215C70);
    final pantsPath = Path()
      ..moveTo(65, 176)
      ..lineTo(58, 207)
      ..lineTo(81, 207)
      ..lineTo(89, 176)
      ..lineTo(108, 176)
      ..lineTo(115, 207)
      ..lineTo(92, 207)
      ..lineTo(89, 176)
      ..close();
    canvas.drawPath(pantsPath, pantsPaint);

    // Left Arm: M53 103c-11 10-17 30-18 43 stroke #f0b793 width 13 round
    final skinPaint = Paint()
      ..color = const Color(0xFFF0B793)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 13
      ..strokeCap = StrokeCap.round;

    final leftArm = Path()
      ..moveTo(53, 103)
      ..cubicTo(42, 113, 36, 133, 35, 146);
    canvas.drawPath(leftArm, skinPaint);

    // Waving Arm (Class .wave in React): rotate around 35, 145
    canvas.save();
    canvas.translate(35, 145);
    canvas.rotate(waveAngle);
    canvas.translate(-35, -145);

    // M35 145c-4-18-14-26-19-34
    final waveArm = Path()
      ..moveTo(35, 145)
      ..cubicTo(31, 127, 21, 119, 16, 111);
    canvas.drawPath(waveArm, skinPaint);

    // Hand: circle cx="15" cy="107" r="8" fill="#f0b793"
    final handPaint = Paint()..color = const Color(0xFFF0B793);
    canvas.drawCircle(const Offset(15, 107), 8, handPaint);
    canvas.restore();

    // Right Arm: M116 109c9 8 13 18 10 30 stroke #efb28d width 13 round
    final rightSkinPaint = Paint()
      ..color = const Color(0xFFEFB28D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 13
      ..strokeCap = StrokeCap.round;
    final rightArm = Path()
      ..moveTo(116, 109)
      ..cubicTo(125, 117, 129, 127, 126, 139);
    canvas.drawPath(rightArm, rightSkinPaint);

    // Tablet: rect x="104" y="125" width="42" height="52" rx="8" fill="#173c55" rotate(7 104 125)
    canvas.save();
    canvas.translate(104, 125);
    canvas.rotate(7 * math.pi / 180);
    canvas.translate(-104, -125);

    final tabletCasePaint = Paint()..color = const Color(0xFF173C55);
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(104, 125, 42, 52), const Radius.circular(8)),
      tabletCasePaint,
    );

    // Screen: rect x="109" y="131" width="32" height="40" rx="5" fill url(#tab) (#12b99f to #1b4dff)
    final tabScreenPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF12B99F), Color(0xFF1B4DFF)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(const Rect.fromLTWH(109, 131, 32, 40));
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(109, 131, 32, 40), const Radius.circular(5)),
      tabScreenPaint,
    );
    canvas.restore();

    // Head: circle cx="86" cy="49" r="37" fill="#f2ba97"
    final facePaint = Paint()..color = const Color(0xFFF2BA97);
    canvas.drawCircle(const Offset(86, 49), 37, facePaint);

    // Hair: M53 46c-2-28 20-42 39-38 16 2 27 13 28 34-10-4-16-13-20-20-10 12-27 20-47 24Z fill #213b51
    final hairPaint = Paint()..color = const Color(0xFF213B51);
    final hairPath = Path()
      ..moveTo(53, 46)
      ..cubicTo(51, 18, 73, 4, 92, 8)
      ..cubicTo(108, 10, 119, 21, 120, 42)
      ..cubicTo(110, 38, 104, 29, 100, 22)
      ..cubicTo(90, 34, 73, 42, 53, 46)
      ..close();
    canvas.drawPath(hairPath, hairPaint);

    // Glasses: circle cx="72" cy="51" r="12" & cx="100" cy="51" r="12" fill #fff opacity .5 stroke #23465a width 3
    final glassFill = Paint()..color = Colors.white.withValues(alpha: 0.5);
    final glassStroke = Paint()
      ..color = const Color(0xFF23465A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawCircle(const Offset(72, 51), 12, glassFill);
    canvas.drawCircle(const Offset(72, 51), 12, glassStroke);

    canvas.drawCircle(const Offset(100, 51), 12, glassFill);
    canvas.drawCircle(const Offset(100, 51), 12, glassStroke);

    // Bridge: M84 50h4 stroke #23465a width 3
    canvas.drawLine(const Offset(84, 50), const Offset(88, 50), glassStroke);

    // Eyes: circle cx="75" cy="52" r="2" & cx="97" cy="52" r="2" fill #213b51
    final eyePaint = Paint()..color = const Color(0xFF213B51);
    canvas.drawCircle(const Offset(75, 52), 2, eyePaint);
    canvas.drawCircle(const Offset(97, 52), 2, eyePaint);

    // Smile: M77 65c6 6 13 6 19 0 stroke #a95755 width 3 round
    final smilePaint = Paint()
      ..color = const Color(0xFFA95755)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final smilePath = Path()
      ..moveTo(77, 65)
      ..cubicTo(83, 71, 90, 71, 96, 65);
    canvas.drawPath(smilePath, smilePaint);

    // Stethoscope: M65 95c-7 15-5 27 5 35 5 4 9 2 8-4-1-4-7-3-10 1m44-31c4 12 3 23-4 30 stroke #245166 width 3
    final stethoPaint = Paint()
      ..color = const Color(0xFF245166)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final stethoLeft = Path()
      ..moveTo(65, 95)
      ..cubicTo(58, 110, 60, 122, 70, 130)
      ..cubicTo(75, 134, 79, 132, 78, 126)
      ..cubicTo(77, 122, 71, 123, 68, 127);
    canvas.drawPath(stethoLeft, stethoPaint);

    final stethoRight = Path()
      ..moveTo(112, 64)
      ..cubicTo(116, 76, 115, 87, 108, 94);
    canvas.drawPath(stethoRight, stethoPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _DoctorMascotPainter oldDelegate) =>
      oldDelegate.waveAngle != waveAngle;
}
