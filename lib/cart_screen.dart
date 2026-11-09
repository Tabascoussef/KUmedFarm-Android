import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_locale.dart';
import 'services/api_service.dart';
import 'services/cart_service.dart';
import 'services/location_service.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final TextEditingController _promoController = TextEditingController();
  bool _isPromoApplied = false;
  double _promoDiscountPercent = 0.0;
  String _promoMessage = '';

  void _applyPromo() {
    final code = _promoController.text.trim().toUpperCase();
    if (code.isEmpty) return;

    if (code == 'UMED20' || code == 'RAMAZON' || code == 'SALE20') {
      setState(() {
        _isPromoApplied = true;
        _promoDiscountPercent = 0.20;
        _promoMessage = '20% chegirma muvaffaqiyatli qo\'llandi!';
      });
    } else if (code == 'HEALTH10' || code == 'UZB10') {
      setState(() {
        _isPromoApplied = true;
        _promoDiscountPercent = 0.10;
        _promoMessage = '10% chegirma muvaffaqiyatli qo\'llandi!';
      });
    } else {
      setState(() {
        _isPromoApplied = false;
        _promoDiscountPercent = 0.0;
        _promoMessage = 'Noto\'g\'ri promokod kiritildi';
      });
    }
  }

  void _openCheckout(BuildContext context, int subtotal, int discount, int deliveryFee, int total) {
    final cachedLoc = LocationService.instance.currentLocation.value;
    final addressCtrl = TextEditingController(
      text: cachedLoc?.formattedAddress ?? '',
    );
    final phoneCtrl = TextEditingController(text: '+998 90 123 45 67');
    final notesCtrl = TextEditingController();
    String selectedPayment = 'payme'; // 'payme' | 'click' | 'cash'
    String selectedTime = 'fast'; // 'fast' | 'standard'
    bool isSubmitting = false;
    bool isLocating = false;
    bool locationAutoDetected = cachedLoc != null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          if (addressCtrl.text.isEmpty && !isLocating) {
            isLocating = true;
            LocationService.instance.detectCurrentLocation().then((loc) {
              if (ctx.mounted) {
                setSheetState(() {
                  addressCtrl.text = loc.formattedAddress;
                  isLocating = false;
                  locationAutoDetected = true;
                });
              }
            });
          }
          return Container(
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
                    // Handle
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
                              context.tr('shop_store'),
                              style: GoogleFonts.dmSans(
                                fontSize: 9,
                                letterSpacing: 1.3,
                                color: const Color(0xFF0E8F7D),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              context.tr('checkout_title'),
                              style: GoogleFonts.manrope(
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF173C43),
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF758B8E)),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Address
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          context.tr('checkout_address'),
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF173C43),
                          ),
                        ),
                        GestureDetector(
                          onTap: () async {
                            setSheetState(() => isLocating = true);
                            try {
                              final loc = await LocationService.instance.detectCurrentLocation(force: true);
                              addressCtrl.text = loc.formattedAddress;
                              setSheetState(() {
                                isLocating = false;
                                locationAutoDetected = true;
                              });
                            } catch (_) {
                              setSheetState(() => isLocating = false);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE2F7EF),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                isLocating
                                    ? const SizedBox(
                                        width: 10,
                                        height: 10,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 1.5,
                                          color: Color(0xFF0E9B83),
                                        ),
                                      )
                                    : const Icon(
                                        CupertinoIcons.location_fill,
                                        size: 11,
                                        color: Color(0xFF0E9B83),
                                      ),
                                const SizedBox(width: 4),
                                Text(
                                  isLocating ? 'Aniqlanmoqda...' : 'GPS orqali aniqlash',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF0E7A5D),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7FAF8),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2EBE8)),
                      ),
                      child: Row(
                        children: [
                          const Icon(CupertinoIcons.location_solid, size: 18, color: Color(0xFF0E9B83)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: addressCtrl,
                              style: GoogleFonts.dmSans(fontSize: 13, color: const Color(0xFF173C43)),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                isDense: true,
                                hintText: context.tr('checkout_address_hint'),
                                hintStyle: GoogleFonts.dmSans(fontSize: 12, color: Colors.grey),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (locationAutoDetected) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, size: 12, color: Color(0xFF0E9B83)),
                          const SizedBox(width: 4),
                          Text(
                            'GPS orqali avtomatik belgilandi',
                            style: GoogleFonts.dmSans(
                              fontSize: 10,
                              color: const Color(0xFF0E9B83),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 14),

                    // Phone
                    Text(
                      context.tr('checkout_phone'),
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF173C43),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7FAF8),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2EBE8)),
                      ),
                      child: Row(
                        children: [
                          const Icon(CupertinoIcons.phone_fill, size: 18, color: Color(0xFF0E9B83)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: phoneCtrl,
                              keyboardType: TextInputType.phone,
                              style: GoogleFonts.dmSans(fontSize: 13, color: const Color(0xFF173C43)),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                isDense: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Delivery Time Options
                    Text(
                      context.tr('checkout_delivery_time'),
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF173C43),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setSheetState(() => selectedTime = 'fast'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 10),
                              decoration: BoxDecoration(
                                color: selectedTime == 'fast' ? const Color(0xFFE6F7F2) : const Color(0xFFF7FAF8),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: selectedTime == 'fast' ? const Color(0xFF0E9B83) : const Color(0xFFE2EBE8),
                                  width: selectedTime == 'fast' ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    CupertinoIcons.bolt_fill,
                                    size: 15,
                                    color: selectedTime == 'fast' ? const Color(0xFF0E9B83) : const Color(0xFF758B8E),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    context.tr('checkout_time_fast'),
                                    style: GoogleFonts.dmSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: selectedTime == 'fast' ? const Color(0xFF0E9B83) : const Color(0xFF173C43),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setSheetState(() => selectedTime = 'standard'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 10),
                              decoration: BoxDecoration(
                                color: selectedTime == 'standard' ? const Color(0xFFE6F7F2) : const Color(0xFFF7FAF8),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: selectedTime == 'standard' ? const Color(0xFF0E9B83) : const Color(0xFFE2EBE8),
                                  width: selectedTime == 'standard' ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    CupertinoIcons.clock_fill,
                                    size: 15,
                                    color: selectedTime == 'standard' ? const Color(0xFF0E9B83) : const Color(0xFF758B8E),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    context.tr('checkout_time_standard'),
                                    style: GoogleFonts.dmSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: selectedTime == 'standard' ? const Color(0xFF0E9B83) : const Color(0xFF173C43),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Payment Method Options
                    Text(
                      context.tr('checkout_payment'),
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF173C43),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildPaymentOption(
                          title: 'Payme',
                          id: 'payme',
                          selected: selectedPayment == 'payme',
                          onTap: () => setSheetState(() => selectedPayment = 'payme'),
                        ),
                        const SizedBox(width: 8),
                        _buildPaymentOption(
                          title: 'Click',
                          id: 'click',
                          selected: selectedPayment == 'click',
                          onTap: () => setSheetState(() => selectedPayment = 'click'),
                        ),
                        const SizedBox(width: 8),
                        _buildPaymentOption(
                          title: 'Naqd pul',
                          id: 'cash',
                          selected: selectedPayment == 'cash',
                          onTap: () => setSheetState(() => selectedPayment = 'cash'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Notes
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7FAF8),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2EBE8)),
                      ),
                      child: TextField(
                        controller: notesCtrl,
                        style: GoogleFonts.dmSans(fontSize: 12, color: const Color(0xFF173C43)),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: context.tr('checkout_notes'),
                          hintStyle: GoogleFonts.dmSans(fontSize: 11, color: Colors.grey),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Total Row
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4FAF8),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFD6EDE6)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            context.tr('cart_total'),
                            style: GoogleFonts.dmSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF4C6A6E),
                            ),
                          ),
                          Text(
                            '${_formatPrice(total)} so\'m',
                            style: GoogleFonts.manrope(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0E9B83),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Confirm Order Button
                    GestureDetector(
                      onTap: isSubmitting
                          ? null
                          : () async {
                              setSheetState(() => isSubmitting = true);

                              final itemsPayload = CartService.instance.items.value.map((item) {
                                return {
                                  'name': item.name,
                                  'dose': item.dose,
                                  'qty': item.quantity,
                                  'price': item.rawPrice,
                                };
                              }).toList();

                              final noteString = 'Manzil: ${addressCtrl.text.trim()} | Tel: ${phoneCtrl.text.trim()} | To\'lov: $selectedPayment | Vaqt: $selectedTime | Izoh: ${notesCtrl.text.trim()}';

                              final sheetNav = Navigator.of(ctx);
                              await ApiService.instance.createOrder(
                                pharmacyName: 'KUAFmedFarm Store',
                                totalAmount: total.toDouble(),
                                items: itemsPayload,
                                notes: noteString,
                              );

                              sheetNav.pop();
                              CartService.instance.clear();

                              if (mounted) {
                                _showSuccessDialog(this.context);
                              }
                            },
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0E9B83), Color(0xFF097B67)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0E9B83).withValues(alpha: 0.35),
                              blurRadius: 16,
                              offset: const Offset(0, 7),
                            ),
                          ],
                        ),
                        child: Center(
                          child: isSubmitting
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.check_circle_rounded, color: Colors.white, size: 19),
                                    const SizedBox(width: 8),
                                    Text(
                                      context.tr('checkout_confirm_btn'),
                                      style: GoogleFonts.manrope(
                                        fontSize: 14,
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
              ),
            ),
          ),
        );
      },
    ),
  );
  }

  Widget _buildPaymentOption({
    required String title,
    required String id,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFE6F7F2) : const Color(0xFFF7FAF8),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? const Color(0xFF0E9B83) : const Color(0xFFE2EBE8),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Center(
            child: Text(
              title,
              style: GoogleFonts.dmSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: selected ? const Color(0xFF0E9B83) : const Color(0xFF173C43),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: const BoxDecoration(
                color: Color(0xFFDFF5ED),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Color(0xFF0E9B83),
                size: 38,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              context.tr('checkout_success_title'),
              style: GoogleFonts.manrope(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF173C43),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F6F4),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Buyurtma raqami: #UF-8492',
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0E9B83),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              context.tr('checkout_success_desc'),
              style: GoogleFonts.dmSans(
                fontSize: 12,
                color: const Color(0xFF55777C),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF173F48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                onPressed: () {
                  Navigator.pop(ctx); // Close dialog
                  Navigator.pop(context); // Back from Cart screen to Shop
                },
                child: Text(
                  context.tr('checkout_back_home'),
                  style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatPrice(int price) {
    final str = price.toString();
    final buffer = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      buffer.write(str[i]);
      count++;
      if (count % 3 == 0 && i != 0) {
        buffer.write(' ');
      }
    }
    return buffer.toString().split('').reversed.join('');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ValueListenableBuilder<List<CartItem>>(
          valueListenable: CartService.instance.items,
          builder: (context, items, _) {
            final subtotal = CartService.instance.subtotal;
            final discount = (subtotal * _promoDiscountPercent).round();
            final deliveryFee = subtotal > 150000 || items.isEmpty ? 0 : 15000;
            final total = items.isEmpty ? 0 : (subtotal - discount + deliveryFee);

            return Column(
              children: [
                // Top App Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7FAF8),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE5EDE9)),
                          ),
                          child: const Center(
                            child: Icon(
                              CupertinoIcons.chevron_left,
                              color: Color(0xFF173C43),
                              size: 19,
                            ),
                          ),
                        ),
                      ),
                      Column(
                        children: [
                          Text(
                            context.tr('cart_title'),
                            style: GoogleFonts.manrope(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF173C43),
                            ),
                          ),
                          Text(
                            '${items.length} ${context.tr('cart_items_count')}',
                            style: GoogleFonts.dmSans(
                              fontSize: 11,
                              color: const Color(0xFF758B8E),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      if (items.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            showCupertinoDialog(
                              context: context,
                              builder: (ctx) => CupertinoAlertDialog(
                                title: const Text('Savatchani tozalash'),
                                content: const Text('Barcha mahsulotlarni o\'chirmoqchimisiz?'),
                                actions: [
                                  CupertinoDialogAction(
                                    child: const Text('Yo\'q'),
                                    onPressed: () => Navigator.pop(ctx),
                                  ),
                                  CupertinoDialogAction(
                                    isDestructiveAction: true,
                                    child: const Text('Ha, tozalash'),
                                    onPressed: () {
                                      Navigator.pop(ctx);
                                      CartService.instance.clear();
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF1F1),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFFFDEDE)),
                            ),
                            child: const Center(
                              child: Icon(
                                CupertinoIcons.trash,
                                color: Color(0xFFFF5252),
                                size: 18,
                              ),
                            ),
                          ),
                        )
                      else
                        const SizedBox(width: 42),
                    ],
                  ),
                ),

                Expanded(
                  child: items.isEmpty
                      ? _buildEmptyCart()
                      : ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
                          children: [
                            // Items list
                            ...items.map((item) => _buildCartItemCard(item)),

                            const SizedBox(height: 18),

                            // Promo code card
                            _buildPromoCodeSection(),

                            const SizedBox(height: 20),

                            // Order Summary
                            _buildSummaryCard(subtotal, discount, deliveryFee, total),

                            const SizedBox(height: 24),
                          ],
                        ),
                ),

                // Bottom Checkout bar
                if (items.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.fromLTRB(22, 14, 22, 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: const Border(top: BorderSide(color: Color(0xFFE5EDE9), width: 1)),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF20564B).withValues(alpha: 0.08),
                          blurRadius: 20,
                          offset: const Offset(0, -6),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              context.tr('cart_total'),
                              style: GoogleFonts.dmSans(
                                fontSize: 11,
                                color: const Color(0xFF758B8E),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${_formatPrice(total)} so\'m',
                              style: GoogleFonts.manrope(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF0E9B83),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _openCheckout(context, subtotal, discount, deliveryFee, total),
                            child: Container(
                              height: 50,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF0E9B83), Color(0xFF097B67)],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF0E9B83).withValues(alpha: 0.35),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    context.tr('cart_checkout'),
                                    style: GoogleFonts.manrope(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.arrow_forward_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: const Color(0xFFEDF8F5),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Icon(
                CupertinoIcons.cart,
                size: 44,
                color: Color(0xFF0E9B83),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              context.tr('cart_empty_title'),
              style: GoogleFonts.manrope(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF173C43),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.tr('cart_empty_sub'),
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: const Color(0xFF758B8E),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0E9B83),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Katalogga qaytish',
                style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartItemCard(CartItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5EDE9)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF22584D).withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          // 3D Medicine Box thumbnail
          Container(
            width: 58,
            height: 68,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: item.pastelBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'UMED',
                  style: GoogleFonts.dmSans(
                    fontSize: 7,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF158D7C),
                  ),
                ),
                Text(
                  item.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF173C43),
                    height: 1.1,
                  ),
                ),
                Container(
                  height: 5,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF11A587), Color(0xFF2879DE)],
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),

          // Title & Price
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: GoogleFonts.manrope(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF173C43),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  item.dose,
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    color: const Color(0xFF758B8E),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${_formatPrice(item.rawPrice * item.quantity)} so\'m',
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0E9B83),
                  ),
                ),
              ],
            ),
          ),

          // Quantity controls
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFF4FAF8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2EBE8)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () => CartService.instance.updateQuantity(item.id, -1),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(CupertinoIcons.minus, size: 13, color: Color(0xFF173C43)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 9),
                  child: Text(
                    '${item.quantity}',
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF173C43),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => CartService.instance.updateQuantity(item.id, 1),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0E9B83),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(CupertinoIcons.plus, size: 13, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromoCodeSection() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAF8),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2EBE8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(CupertinoIcons.tag_fill, size: 15, color: Color(0xFF0E9B83)),
              const SizedBox(width: 7),
              Text(
                context.tr('cart_promo_code'),
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF173C43),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 42,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFD6E4E0)),
                  ),
                  child: TextField(
                    controller: _promoController,
                    style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w700),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'UMED20 yoki HEALTH10',
                      hintStyle: GoogleFonts.dmSans(fontSize: 11, color: Colors.grey.shade400),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _applyPromo,
                child: Container(
                  height: 42,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF173C43),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      context.tr('cart_apply'),
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_promoMessage.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              _promoMessage,
              style: GoogleFonts.dmSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _isPromoApplied ? const Color(0xFF0E9B83) : Colors.redAccent,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryCard(int subtotal, int discount, int deliveryFee, int total) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAF8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2EBE8)),
      ),
      child: Column(
        children: [
          _buildSummaryRow(context.tr('cart_subtotal'), '${_formatPrice(subtotal)} so\'m'),
          const SizedBox(height: 10),
          _buildSummaryRow(
            context.tr('cart_delivery'),
            deliveryFee == 0 ? context.tr('cart_delivery_free') : '${_formatPrice(deliveryFee)} so\'m',
            isGreen: deliveryFee == 0,
          ),
          if (discount > 0) ...[
            const SizedBox(height: 10),
            _buildSummaryRow(
              context.tr('cart_discount'),
              '-${_formatPrice(discount)} so\'m',
              isGreen: true,
            ),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: Color(0xFFD6E4E0), height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.tr('cart_total'),
                style: GoogleFonts.manrope(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF173C43),
                ),
              ),
              Text(
                '${_formatPrice(total)} so\'m',
                style: GoogleFonts.manrope(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0E9B83),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String title, String value, {bool isGreen = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.dmSans(
            fontSize: 12,
            color: const Color(0xFF758B8E),
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.dmSans(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isGreen ? const Color(0xFF0E9B83) : const Color(0xFF173C43),
          ),
        ),
      ],
    );
  }
}
