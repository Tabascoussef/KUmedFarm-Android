import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import 'app_locale.dart';
import 'dashboard_screen.dart'; // For DoctorMascotWidget
import 'services/api_service.dart';

class PharmacyItem {
  final String id;
  final String name;
  final String address;
  final String phone;
  final String distance;
  final String eta;
  final String rating;
  final bool isOpen24h;
  final bool isClosed;
  final double x;
  final double y;

  const PharmacyItem({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    required this.distance,
    required this.eta,
    required this.rating,
    required this.isOpen24h,
    this.isClosed = false,
    required this.x,
    required this.y,
  });
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final List<PharmacyItem> _pharmacies = [
    const PharmacyItem(
      id: 'p1',
      name: 'KUmed Central Pharmacy 24/7',
      address: 'Amir Temur shoh koʻchasi, 108',
      phone: '+998712000024',
      distance: '0.8 km',
      eta: '3 min',
      rating: '4.9 / 5',
      isOpen24h: true,
      x: 140,
      y: 180,
    ),
    const PharmacyItem(
      id: 'p2',
      name: 'Shifo Farm Dorixonasi',
      address: 'Beruniy koʻchasi, 14-uy',
      phone: '+998712451122',
      distance: '1.9 km',
      eta: '6 min',
      rating: '4.8 / 5',
      isOpen24h: false,
      x: 70,
      y: 110,
    ),
    const PharmacyItem(
      id: 'p3',
      name: 'Kardiomed Filiali',
      address: 'Chilonzor 9-mavze, 2-uy',
      phone: '+998712778899',
      distance: '2.5 km',
      eta: '8 min',
      rating: '4.9 / 5',
      isOpen24h: true,
      x: 210,
      y: 280,
    ),
    const PharmacyItem(
      id: 'p4',
      name: 'Grand Pharm Yunusobod',
      address: 'Yunusobod 12-mavze, 4-uy',
      phone: '+998712234455',
      distance: '3.2 km',
      eta: '11 min',
      rating: '4.7 / 5',
      isOpen24h: false,
      x: 260,
      y: 90,
    ),
  ];

  late PharmacyItem _selected;
  final Set<String> _favorites = {};
  bool _showSearch = false;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selected = _pharmacies.first;
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
    _pulseAnimation = Tween<double>(
      begin: 0.3,
      end: 1.6,
    ).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeOut));

    _loadPharmaciesFromApi();
  }

  Future<void> _loadPharmaciesFromApi() async {
    try {
      final items = await ApiService.instance.getPharmacies();
      if (!mounted) return;

      if (items.isNotEmpty) {
        final List<PharmacyItem> loaded = [];
        final defaultCoords = [
          [140.0, 180.0],
          [70.0, 110.0],
          [210.0, 280.0],
          [260.0, 90.0],
          [180.0, 140.0],
        ];

        for (int i = 0; i < items.length; i++) {
          final p = items[i];
          final coord = defaultCoords[i % defaultCoords.length];
          final is247 = p['is_duty_24_7'] == true || p['is_duty_24_7'] == 1;

          loaded.add(PharmacyItem(
            id: 'p${p['id'] ?? (i + 1)}',
            name: p['name'] ?? 'Dorixona',
            address: p['address'] ?? 'Toshkent shahri',
            phone: (p['phone'] ?? '+998 71 200 00 24').toString().replaceAll(' ', ''),
            distance: '${(0.8 + (i * 0.7)).toStringAsFixed(1)} km',
            eta: '${3 + (i * 3)} min',
            rating: is247 ? '4.9 / 5' : '4.8 / 5',
            isOpen24h: is247,
            isClosed: false,
            x: coord[0],
            y: coord[1],
          ));
        }

        if (loaded.isNotEmpty) {
          setState(() {
            _pharmacies.clear();
            _pharmacies.addAll(loaded);
            _selected = _pharmacies.first;
          });
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _makePhoneCall(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Calling $phone...'),
            backgroundColor: const Color(0xFF173C43),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _startRoute(PharmacyItem item) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent('${item.name} ${item.address}')}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Route to ${item.name} started! (${item.distance} · ${item.eta})',
            ),
            backgroundColor: const Color(0xFF0E9680),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: const Color(0xFFE9F3F0),
      body: Stack(
        children: [
          // 1. MAP CANVAS (vector roads, blocks, route line, pins, you, doctor)
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            bottom: 270,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomLeft,
                  end: Alignment.topRight,
                  colors: [Color(0xFFE5F0ED), Color(0xFFF3F7F2)],
                ),
              ),
              child: ClipRect(
                child: Stack(
                  children: [
                    // Roads
                    // r1: width 520, height 55, left -70, top 175, rotate -13deg
                    Positioned(
                      left: -70,
                      top: 175,
                      child: Transform.rotate(
                        angle: -13 * math.pi / 180,
                        alignment: Alignment.center,
                        child: Container(
                          width: 520,
                          height: 55,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(40),
                            border: Border.all(color: const Color(0xFFDCE8E5)),
                          ),
                        ),
                      ),
                    ),
                    // r2: width 460, height 45, left 40, top 80, rotate 62deg
                    Positioned(
                      left: 40,
                      top: 80,
                      child: Transform.rotate(
                        angle: 62 * math.pi / 180,
                        alignment: Alignment.center,
                        child: Container(
                          width: 460,
                          height: 45,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(40),
                            border: Border.all(color: const Color(0xFFDCE8E5)),
                          ),
                        ),
                      ),
                    ),
                    // r3: width 300, height 38, left -70, top 355, rotate 18deg
                    Positioned(
                      left: -70,
                      top: 355,
                      child: Transform.rotate(
                        angle: 18 * math.pi / 180,
                        alignment: Alignment.center,
                        child: Container(
                          width: 300,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(40),
                            border: Border.all(color: const Color(0xFFDCE8E5)),
                          ),
                        ),
                      ),
                    ),

                    // City Blocks
                    // b1: width 90, height 80, left 20, top 240
                    Positioned(
                      left: 20,
                      top: 240,
                      child: Container(
                        width: 90,
                        height: 80,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD8E9E2),
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    ),
                    // b2: width 115, height 70, right 8, top 125
                    Positioned(
                      right: 8,
                      top: 125,
                      child: Container(
                        width: 115,
                        height: 70,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD8E9E2),
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    ),
                    // b3: width 85, height 100, right 20, top 290
                    Positioned(
                      right: 20,
                      top: 290,
                      child: Container(
                        width: 85,
                        height: 100,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD8E9E2),
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    ),

                    // Route Line SVG path: M65 90 C110 165 210 128 205 236 S305 278 317 359
                    CustomPaint(
                      size: Size.infinite,
                      painter: _RouteLinePainter(),
                    ),

                    // Map Pins
                    ..._pharmacies.map((item) => _buildMapPin(item)),

                    // "You" marker: left 45, top 70
                    Positioned(
                      left: 45,
                      top: 70,
                      child: Container(
                        width: 31,
                        height: 31,
                        decoration: BoxDecoration(
                          color: const Color(0xFF176DF5),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF176DF5)
                                  .withValues(alpha: 0.2),
                              spreadRadius: 9,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            'You',
                            style: GoogleFonts.dmSans(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Doctor mascot compact (right -3, bottom 5, width 90, height 115)
                    const Positioned(
                      right: -3,
                      bottom: 5,
                      width: 90,
                      height: 115,
                      child: DoctorMascotWidget(compact: true),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 2. MAP HEADER (Floating top bar)
          Positioned(
            top: topPadding + 10,
            left: 15,
            right: 15,
            child: Container(
              height: 62,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.86),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF214C45).withValues(alpha: 0.12),
                    blurRadius: 25,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Back button
                  GestureDetector(
                    onTap: () {
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      }
                    },
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.arrow_back_rounded,
                          size: 19,
                          color: Color(0xFF173C43),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Title & Subtitle
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr('map_nearby'),
                          style: GoogleFonts.manrope(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF173C43),
                          ),
                        ),
                        Text(
                          context.tr('map_stores_count'),
                          style: GoogleFonts.dmSans(
                            fontSize: 10,
                            color: const Color(0xFF758B8E),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Search button
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _showSearch = !_showSearch;
                      });
                    },
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Center(
                        child: Icon(
                          CupertinoIcons.search,
                          size: 19,
                          color: Color(0xFF173C43),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Search Dropdown if opened
          if (_showSearch)
            Positioned(
              top: topPadding + 78,
              left: 15,
              right: 15,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchCtrl,
                  autofocus: true,
                  style: GoogleFonts.dmSans(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Search pharmacy name or street...',
                    hintStyle: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  onSubmitted: (val) {
                    final found = _pharmacies.firstWhere(
                      (p) => p.name.toLowerCase().contains(val.toLowerCase()),
                      orElse: () => _pharmacies.first,
                    );
                    setState(() {
                      _selected = found;
                      _showSearch = false;
                    });
                  },
                ),
              ),
            ),

          // 3. BOTTOM SHEET (1:1 with D:\src\App.tsx sheet)
          Positioned(
            left: 0,
            right: 0,
            bottom: 82, // above bottom navigation bar
            child: Container(
              padding: const EdgeInsets.fromLTRB(21, 12, 21, 18),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.94),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF264F46).withValues(alpha: 0.12),
                    blurRadius: 40,
                    offset: const Offset(0, -15),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Grabber
                  Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD8E4E1),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // Pharmacy Head
                  Row(
                    children: [
                      // Store Pic: 58x58, radius 17, gradient #d9f5e9 -> #bce2d5
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFD9F5E9), Color(0xFFBCE2D5)],
                          ),
                          borderRadius: BorderRadius.circular(17),
                        ),
                        child: Center(
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                '+',
                                style: GoogleFonts.dmSans(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF0E9B83),
                                  height: 1.0,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 11),

                      // Title & Subtitle
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selected.isOpen24h
                                  ? context.tr('open_24_7')
                                  : context.tr('open_until'),
                              style: GoogleFonts.dmSans(
                                fontSize: 8,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.7,
                                color: _selected.isClosed
                                    ? Colors.grey
                                    : const Color(0xFF07966E),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _selected.name,
                              style: GoogleFonts.manrope(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF173C43),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const Icon(
                                  CupertinoIcons.location_solid,
                                  size: 13,
                                  color: Color(0xFF758B8E),
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  '${_selected.distance} away · ${_selected.eta}',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 10,
                                    color: const Color(0xFF758B8E),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Heart button (favorite)
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            if (_favorites.contains(_selected.id)) {
                              _favorites.remove(_selected.id);
                            } else {
                              _favorites.add(_selected.id);
                            }
                          });
                        },
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEDF8F5),
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: Center(
                            child: Icon(
                              _favorites.contains(_selected.id)
                                  ? CupertinoIcons.heart_fill
                                  : CupertinoIcons.heart,
                              size: 18,
                              color: const Color(0xFF168F7A),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Pharmacy Meta Box (3 columns: Distance, Open hours, Rating)
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 16),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F8F6),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                context.tr('distance'),
                                style: GoogleFonts.dmSans(
                                  fontSize: 8,
                                  color: const Color(0xFF758B8E),
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                _selected.distance,
                                style: GoogleFonts.dmSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF173C43),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 24,
                          color: const Color(0xFFDCE9E5),
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                context.tr('open_hours'),
                                style: GoogleFonts.dmSans(
                                  fontSize: 8,
                                  color: const Color(0xFF758B8E),
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                _selected.isOpen24h
                                    ? '24 hours'
                                    : '08:00 - 22:00',
                                style: GoogleFonts.dmSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF173C43),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 24,
                          color: const Color(0xFFDCE9E5),
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                context.tr('rating'),
                                style: GoogleFonts.dmSans(
                                  fontSize: 8,
                                  color: const Color(0xFF758B8E),
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                _selected.rating,
                                style: GoogleFonts.dmSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF173C43),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Sheet Actions: Call & Start route
                  Row(
                    children: [
                      // Call button
                      GestureDetector(
                        onTap: () => _makePhoneCall(_selected.phone),
                        child: Container(
                          width: 52,
                          height: 49,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: const Color(0xFFDBE9E5)),
                          ),
                          child: const Center(
                            child: Icon(
                              CupertinoIcons.phone_fill,
                              size: 19,
                              color: Color(0xFF0D927B),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Start route button: gradient #0E9680 -> #146ECB
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _startRoute(_selected),
                          child: Container(
                            height: 49,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF0E9680), Color(0xFF146ECB)],
                              ),
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF107E7B)
                                      .withValues(alpha: 0.22),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  CupertinoIcons.arrow_up_right_diamond_fill,
                                  size: 17,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  context.tr('start_route'),
                                  style: GoogleFonts.manrope(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapPin(PharmacyItem item) {
    final isClosed = item.isClosed;

    return Positioned(
      left: item.x,
      top: item.y,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selected = item;
          });
        },
        child: SizedBox(
          width: 44,
          height: 52,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // Pulse ring if open
              if (!isClosed)
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, _) {
                    final s = _pulseAnimation.value;
                    final op = (1.6 - s).clamp(0.0, 1.0);
                    return Positioned(
                      bottom: -4,
                      child: Transform.scale(
                        scale: s,
                        child: Container(
                          width: 36,
                          height: 16,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: const Color(0xFF25B990)
                                  .withValues(alpha: op * 0.8),
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    );
                  },
                ),

              // Pin marker
              Positioned(
                top: 0,
                child: Opacity(
                  opacity: isClosed ? 0.6 : 1.0,
                  child: Container(
                    width: 35,
                    height: 35,
                    decoration: BoxDecoration(
                      gradient: isClosed
                          ? const LinearGradient(
                              colors: [Colors.grey, Color(0xFF555555)],
                            )
                          : const LinearGradient(
                              colors: [Color(0xFF37D3A2), Color(0xFF0D8F78)],
                            ),
                      border: Border.all(color: Colors.white, width: 3),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(4),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0A856C).withValues(alpha: 0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 7),
                        ),
                      ],
                    ),
                    transform: Matrix4.rotationZ(-45 * math.pi / 180),
                    alignment: Alignment.center,
                    child: Transform.rotate(
                      angle: 45 * math.pi / 180,
                      child: const Icon(
                        CupertinoIcons.bag_fill,
                        size: 16,
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
    );
  }
}

// ROUTE LINE PAINTER (Exact cubic bezier from D:\src\App.tsx: M65 90 C110 165 210 128 205 236 S305 278 317 359)
class _RouteLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    path.moveTo(65, 90);
    path.cubicTo(110, 165, 210, 128, 205, 236);
    // Smooth cubic S305 278 317 359 (reflected control point from 205, 236 is 200, 344)
    path.cubicTo(200, 344, 305, 278, 317, 359);

    // Glow paint
    final glowPaint = Paint()
      ..color = const Color(0xFF4E8EFF).withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawPath(path, glowPaint);

    // Route paint
    final routePaint = Paint()
      ..color = const Color(0xFF176DF5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, routePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
