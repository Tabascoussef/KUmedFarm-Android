import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_locale.dart';
import 'cart_screen.dart';
import 'services/cart_service.dart';

import 'services/api_service.dart';

class ShopScreen extends StatefulWidget {
  final VoidCallback? onOpenCart;

  const ShopScreen({
    super.key,
    this.onOpenCart,
  });

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  String _selectedCategory = 'Barchasi';
  final Set<int> _cartItemIds = {};
  bool _isLoading = false;

  final List<String> _categories = [
    'Barchasi',
    'Kardiologiya',
    'Antibiotik',
    'Oshqozon-ichak',
    'Vitaminlar',
    'Ogʻriq qoldiruvchi',
  ];

  final List<Map<String, dynamic>> _products = [
    {
      'id': 1,
      'box_name': 'Kardiomagnil',
      'box_dose': '75 mg',
      'name': 'Kardiomagnil',
      'dose': '75 mg · 100 dona',
      'price': "42 000 so'm",
      'raw_price': 42000,
      'category': 'Kardiologiya',
      'status': 'Mavjud',
      'is_prescription': false,
      'pastel_bg': const Color(0xFFFEF3E2),
    },
    {
      'id': 2,
      'box_name': 'Amoksiklav',
      'box_dose': '625 mg',
      'name': 'Amoksiklav',
      'dose': '625 mg · 14 tabletka',
      'price': "68 000 so'm",
      'raw_price': 68000,
      'category': 'Antibiotik',
      'status': 'Retseptli',
      'is_prescription': true,
      'pastel_bg': const Color(0xFFE8F1FA),
    },
    {
      'id': 3,
      'box_name': 'Mezim',
      'box_dose': '10 000 TB',
      'name': 'Mezim Forte',
      'dose': '10 000 TB · 20 dona',
      'price': "31 500 so'm",
      'raw_price': 31500,
      'category': 'Oshqozon-ichak',
      'status': 'Mavjud',
      'is_prescription': false,
      'pastel_bg': const Color(0xFFE4F4EC),
    },
    {
      'id': 4,
      'box_name': 'D3 Vitamin',
      'box_dose': '15 000 XB/ml',
      'name': 'D3 Vitamini tomchi',
      'dose': '15 000 XB/ml · 10 ml',
      'price': "35 000 so'm",
      'raw_price': 35000,
      'category': 'Vitaminlar',
      'status': 'Mavjud',
      'is_prescription': false,
      'pastel_bg': const Color(0xFFEDE9FE),
    },
    {
      'id': 5,
      'box_name': 'Spasmalgon',
      'box_dose': '500 mg',
      'name': 'Spasmalgon',
      'dose': '500 mg · 20 dona',
      'price': "29 000 so'm",
      'raw_price': 29000,
      'category': 'Ogʻriq qoldiruvchi',
      'status': 'Mavjud',
      'is_prescription': false,
      'pastel_bg': const Color(0xFFFDE8EC),
    },
    {
      'id': 6,
      'box_name': 'Nimesil',
      'box_dose': '100 mg',
      'name': 'Nimesil',
      'dose': '100 mg · 30 paket',
      'price': "84 000 so'm",
      'raw_price': 84000,
      'category': 'Ogʻriq qoldiruvchi',
      'status': 'Mavjud',
      'is_prescription': false,
      'pastel_bg': const Color(0xFFFFF7ED),
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadMedicinesFromApi();
  }

  Future<void> _loadMedicinesFromApi() async {
    setState(() => _isLoading = true);
    try {
      final items = await ApiService.instance.getMedicines();
      if (!mounted) return;

      if (items.isNotEmpty) {
        final colors = [
          const Color(0xFFFEF3E2),
          const Color(0xFFE8F1FA),
          const Color(0xFFE4F4EC),
          const Color(0xFFEDE9FE),
          const Color(0xFFFDE8EC),
          const Color(0xFFFFF7ED),
        ];

        setState(() {
          _products.clear();
          for (int i = 0; i < items.length; i++) {
            final item = items[i];
            final rawPrice = (item['price'] is num) ? (item['price'] as num).toInt() : 45000;
            final priceStr = "${rawPrice.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ')} so'm";
            final category = item['category']?.toString() ?? 'Umumiy';

            _products.add({
              'id': item['id'] ?? (i + 1),
              'box_name': (item['name']?.toString() ?? 'Dori').split(' ').first,
              'box_dose': item['dose']?.toString() ?? 'Standart',
              'name': item['name']?.toString() ?? '',
              'dose': item['dose']?.toString() ?? 'Standart',
              'price': priceStr,
              'raw_price': rawPrice,
              'category': category,
              'status': ((item['stock'] is num) && (item['stock'] as num) < 20) ? 'Kam qoldi' : 'Mavjud',
              'is_prescription': item['requires_prescription'] == true || item['requires_prescription'] == 1,
              'pastel_bg': colors[i % colors.length],
            });
          }

          final dynamicCats = _products.map((p) => p['category'] as String).toSet().toList();
          for (var c in dynamicCats) {
            if (!_categories.contains(c)) {
              _categories.add(c);
            }
          }
        });
      }
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showOrderDialog(BuildContext context, Map<String, dynamic> product) {
    int qty = 1;
    final unitPrice = product['price'] as String;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
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
                        'Buyurtma berish',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
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
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: product['pastel_bg'] as Color,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            CupertinoIcons.capsule_fill,
                            color: Color(0xFF0C382E),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product['name'] as String,
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  color: const Color(0xFF0C382E),
                                ),
                              ),
                              Text(
                                product['dose'] as String,
                                style: const TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          unitPrice,
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF14C97E),
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Miqdori:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      Row(
                        children: [
                          IconButton(
                            onPressed: qty > 1 ? () => setModalState(() => qty--) : null,
                            icon: const Icon(CupertinoIcons.minus_circle_fill, color: Color(0xFF0C382E)),
                          ),
                          Text(
                            '$qty',
                            style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800),
                          ),
                          IconButton(
                            onPressed: () => setModalState(() => qty++),
                            icon: const Icon(CupertinoIcons.plus_circle_fill, color: Color(0xFF14C97E)),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0C382E),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        Navigator.of(ctx).pop();
                        setState(() => _cartItemIds.add(product['id'] as int));

                        CartService.instance.addItem(
                          id: product['id'] as int,
                          name: product['name'] as String,
                          dose: product['dose'] as String,
                          price: product['price'] as String,
                          rawPrice: product['raw_price'] as int,
                          pastelBg: product['pastel_bg'] as Color,
                          quantity: qty,
                        );

                        if (!mounted) return;
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text('${product['name']} ($qty dona) savatga qo\'shildi!'),
                            backgroundColor: const Color(0xFF0E9B83),
                            behavior: SnackBarBehavior.floating,
                            action: SnackBarAction(
                              label: 'Savatcha',
                              textColor: Colors.white,
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const CartScreen()),
                                );
                              },
                            ),
                          ),
                        );
                      },
                      child: const Text('Savatga qo\'shish', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
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

  Widget _buildMedicineBox({
    required String productName,
    required String dose,
    required Color pastelBg,
  }) {
    return Container(
      width: double.infinity,
      height: 126,
      decoration: BoxDecoration(
        color: pastelBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Transform.rotate(
          angle: -5 * math.pi / 180,
          child: Container(
            width: 67,
            height: 91,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.white, Color(0xFFEDF3F1)],
                begin: Alignment(-0.8, -0.6),
                end: Alignment(0.8, 0.6),
              ),
              borderRadius: BorderRadius.circular(5),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF374441).withValues(alpha: 0.16),
                  blurRadius: 18,
                  offset: const Offset(10, 12),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(7, 10, 7, 7),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'UMED',
                  style: GoogleFonts.dmSans(
                    fontSize: 6,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF158D7C),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  productName,
                  style: GoogleFonts.manrope(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF173C43),
                    height: 1.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  dose,
                  style: GoogleFonts.dmSans(
                    fontSize: 6,
                    color: const Color(0xFF879A98),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                Container(
                  height: 13,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF11A587), Color(0xFF2879DE)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _products.where((p) {
      if (_selectedCategory == 'Barchasi') return true;
      return p['category'] == _selectedCategory;
    }).toList();

    final displayList = filtered.isNotEmpty ? filtered : _products;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header (UMEDFARM STORE & Health essentials & Bag Button)
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 12, 22, 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('shop_store'),
                        style: GoogleFonts.dmSans(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0E8F7D),
                          letterSpacing: 1.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        context.tr('shop_essentials'),
                        style: GoogleFonts.manrope(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF173C43),
                          letterSpacing: -0.8,
                        ),
                      ),
                    ],
                  ),
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
                                border: Border.all(color: const Color(0xFFE5EDE9)),
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
              ),
            ),

            // 2. Category Filter Chips
            SizedBox(
              height: 36,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 22),
                itemCount: _categories.length,
                itemBuilder: (ctx, idx) {
                  final cat = _categories[idx];
                  final isSel = cat == _selectedCategory;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = cat),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: const EdgeInsets.only(right: 7),
                      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSel ? const Color(0xFF173F48) : Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: isSel ? const Color(0xFF173F48) : const Color(0xFFDEEBE7),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          cat,
                          style: GoogleFonts.dmSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isSel ? Colors.white : const Color(0xFF6C8382),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 14),

            // 3. 2-Column Product Cards matching D:\src\App.tsx
            Expanded(
              child: _isLoading && _products.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF0E9B83),
                        strokeWidth: 2.5,
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(22, 0, 22, 100),
                      itemCount: displayList.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 11,
                  mainAxisSpacing: 11,
                  childAspectRatio: 0.69,
                ),
                itemBuilder: (ctx, i) {
                  final p = displayList[i];
                  final isPrescription = p['is_prescription'] == true;

                  return Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.82),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: const Color(0xFFE7F0ED)),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF214F45).withValues(alpha: 0.06),
                          blurRadius: 22,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Pastel background with 3D medicine box
                        _buildMedicineBox(
                          productName: p['box_name'] as String,
                          dose: p['box_dose'] as String,
                          pastelBg: p['pastel_bg'] as Color,
                        ),

                        const SizedBox(height: 9),

                        // Rx / In stock badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE4F6F0),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isPrescription
                                ? context.tr('prescription_required')
                                : context.tr('in_stock'),
                            style: GoogleFonts.dmSans(
                              fontSize: 7.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF168F78),
                            ),
                          ),
                        ),

                        const SizedBox(height: 4),

                        // Title
                        Text(
                          p['name'] as String,
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF173C43),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),

                        const SizedBox(height: 2),

                        // Dosage
                        Text(
                          p['dose'] as String,
                          style: GoogleFonts.dmSans(
                            fontSize: 8.5,
                            color: const Color(0xFF758B8E),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),

                        const Spacer(),

                        // Price and Plus Button
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              p['price'] as String,
                              style: GoogleFonts.manrope(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF173C43),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => _showOrderDialog(context, p),
                              child: Container(
                                width: 29,
                                height: 29,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF173F48),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Center(
                                  child: Icon(
                                    CupertinoIcons.plus,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
