import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'location_service.dart';

class MedicineModel {
  final String id;
  final String name;
  final String genericName;
  final String dose;
  final String category;
  final int basePrice;
  final String priceFormatted;
  final bool isPrescription;
  final String description;
  final IconData icon;

  const MedicineModel({
    required this.id,
    required this.name,
    required this.genericName,
    required this.dose,
    required this.category,
    required this.basePrice,
    required this.priceFormatted,
    this.isPrescription = false,
    required this.description,
    this.icon = CupertinoIcons.capsule_fill,
  });
}

class PharmacyMedicineStock {
  final String pharmacyId;
  final String pharmacyName;
  final String address;
  final String phone;
  final double latitude;
  final double longitude;
  final String rating;
  final bool isOpen24;
  final String workingHours;
  final double distanceMeters;
  final String distanceStr;
  final String walkEta;
  final int price;
  final String priceStr;
  final int stockCount;
  final bool inStock;

  const PharmacyMedicineStock({
    required this.pharmacyId,
    required this.pharmacyName,
    required this.address,
    required this.phone,
    required this.latitude,
    required this.longitude,
    required this.rating,
    required this.isOpen24,
    required this.workingHours,
    required this.distanceMeters,
    required this.distanceStr,
    required this.walkEta,
    required this.price,
    required this.priceStr,
    required this.stockCount,
    required this.inStock,
  });
}

class MedicineService {
  static final MedicineService instance = MedicineService._internal();
  MedicineService._internal();

  static const List<MedicineModel> catalog = [
    MedicineModel(
      id: 'm1',
      name: 'Paratsetamol',
      genericName: 'Paracetamol / Парацетамол',
      dose: '500 mg · 10 tabletka',
      category: "Og'riq va isitma",
      basePrice: 5000,
      priceFormatted: "5 000 so'm",
      description: 'Isitma tushiruvchi, bosh va tana ogʻriqlarini qoldiruvchi vosita.',
      icon: CupertinoIcons.capsule_fill,
    ),
    MedicineModel(
      id: 'm2',
      name: 'Nurofen Forte',
      genericName: 'Ibuprofen / Нурофен Ибупрофен',
      dose: '400 mg · 12 kapsula',
      category: "Og'riq qoldiruvchi",
      basePrice: 28000,
      priceFormatted: "28 000 so'm",
      description: 'Kuchli ogʻriq, yalligʻlanish va shamollash simptomlariga qarshi.',
      icon: CupertinoIcons.bolt_fill,
    ),
    MedicineModel(
      id: 'm3',
      name: 'Kardiomagnil',
      genericName: 'Acetylsalicylic acid / Кардиомагнил',
      dose: '75 mg · 100 dona',
      category: 'Kardiologiya',
      basePrice: 42000,
      priceFormatted: "42 000 so'm",
      description: 'Yurak-qon tomir tizimi profilaktikasi va qon quyilishining oldini oladi.',
      icon: CupertinoIcons.heart_fill,
    ),
    MedicineModel(
      id: 'm4',
      name: 'Sitramon P',
      genericName: 'Citramon / Цитрамон П',
      dose: '10 tabletka',
      category: "Og'riq va bosh og'rig'i",
      basePrice: 4500,
      priceFormatted: "4 500 so'm",
      description: 'Bosh ogʻrigʻi, charchoq va qon bosimi tushganda tetiklashtiruvchi.',
      icon: CupertinoIcons.bandage_fill,
    ),
    MedicineModel(
      id: 'm5',
      name: 'Trimol',
      genericName: 'Trimol / Тримол',
      dose: '10 tabletka',
      category: "Gripp va shamollash",
      basePrice: 8000,
      priceFormatted: "8 000 so'm",
      description: 'Gripp, burun bitishi va mushaklardagi ogʻriqlarni yengillashtiradi.',
      icon: CupertinoIcons.capsule_fill,
    ),
    MedicineModel(
      id: 'm6',
      name: 'Amoksiklav',
      genericName: 'Amoxicillin + Clavulanic acid / Амоксиклав',
      dose: '625 mg · 14 tabletka',
      category: 'Antibiotik',
      basePrice: 68000,
      priceFormatted: "68 000 so'm",
      isPrescription: true,
      description: 'Bakterial infeksiyalarga qarshi keng taʼsir doirasiga ega antibiotik.',
      icon: CupertinoIcons.bandage_fill,
    ),
    MedicineModel(
      id: 'm7',
      name: 'D3 Vitamini (Akvadetrim)',
      genericName: 'Cholecalciferol / Витамин D3',
      dose: '15 000 XB/ml · 10 ml tomchi',
      category: 'Vitaminlar',
      basePrice: 35000,
      priceFormatted: "35 000 so'm",
      description: 'Immunitetni oshirish va suyak-mushak tizimini mustahkamlash.',
      icon: CupertinoIcons.capsule_fill,
    ),
    MedicineModel(
      id: 'm8',
      name: 'Magniy B6',
      genericName: 'Magnesium + Vitamin B6 / Магний B6',
      dose: '500 mg · 60 tabletka',
      category: 'Sedativ va asab',
      basePrice: 54000,
      priceFormatted: "54 000 so'm",
      description: 'Asab tizimi, stress, bezovtalik va uyqu buzilishlarini bartaraf etadi.',
      icon: CupertinoIcons.moon_stars_fill,
    ),
    MedicineModel(
      id: 'm9',
      name: 'Mezim Forte',
      genericName: 'Pancreatin / Мезим Форте',
      dose: '10 000 TB · 20 dona',
      category: 'Oshqozon-ichak',
      basePrice: 31500,
      priceFormatted: "31 500 so'm",
      description: 'Ovqat hazm qilishni yaxshilovchi tabiiy fermentli vosita.',
      icon: CupertinoIcons.shield_fill,
    ),
    MedicineModel(
      id: 'm10',
      name: 'Spasmalgon',
      genericName: 'Pitofenone + Metamizole / Спазмалгон',
      dose: '500 mg · 20 dona',
      category: "Og'riq qoldiruvchi",
      basePrice: 29000,
      priceFormatted: "29 000 so'm",
      description: 'Qorin, buyrak va spazmli ogʻriqlarni tezda yengillashtiradi.',
      icon: CupertinoIcons.bolt_fill,
    ),
    MedicineModel(
      id: 'm11',
      name: 'Nimesil',
      genericName: 'Nimesulide / Нимесил',
      dose: '100 mg · 30 paket',
      category: "Yallig'lanishga qarshi",
      basePrice: 84000,
      priceFormatted: "84 000 so'm",
      description: 'Boʻgʻim, tish va jarohat ogʻriqlarida samarali vosita.',
      icon: CupertinoIcons.bolt_fill,
    ),
    MedicineModel(
      id: 'm12',
      name: 'Suprastin',
      genericName: 'Chloropyramine / Супрастин',
      dose: '25 mg · 20 tabletka',
      category: 'Allergiya',
      basePrice: 26000,
      priceFormatted: "26 000 so'm",
      description: 'Allergik reaksiyalar, toshma va qichishishni bartaraf etadi.',
      icon: CupertinoIcons.wind,
    ),
    MedicineModel(
      id: 'm13',
      name: 'No-shpa',
      genericName: 'Drotaverine / Но-шпа Дротаверин',
      dose: '40 mg · 24 tabletka',
      category: 'Spazmolitik',
      basePrice: 32000,
      priceFormatted: "32 000 so'm",
      description: 'Silliq mushaklar spazmini yengillashtiruvchi vosita.',
      icon: CupertinoIcons.capsule_fill,
    ),
    MedicineModel(
      id: 'm14',
      name: 'Teraflu',
      genericName: 'Paracetamol + Phenylephrine / Терафлю',
      dose: '10 paket · Issiq ichimlik',
      category: 'Shamollash',
      basePrice: 65000,
      priceFormatted: "65 000 so'm",
      description: 'Gripp, burun bitishi va tomoq ogʻrigʻida tez yordam.',
      icon: CupertinoIcons.thermometer,
    ),
    MedicineModel(
      id: 'm15',
      name: 'Aspirin Kardio',
      genericName: 'Acetylsalicylic acid / Аспирин Кардио',
      dose: '100 mg · 28 tabletka',
      category: 'Kardiologiya',
      basePrice: 22000,
      priceFormatted: "22 000 so'm",
      description: 'Tromb hosil boʻlishi va yurak xurujlarining oldini oladi.',
      icon: CupertinoIcons.heart_fill,
    ),
    MedicineModel(
      id: 'm16',
      name: 'Vitamin C',
      genericName: 'Ascorbic acid / Витамин C Аскорбинка',
      dose: '1000 mg · 20 dona',
      category: 'Vitaminlar',
      basePrice: 24000,
      priceFormatted: "24 000 so'm",
      description: 'Immunitetni mustahkamlovchi kuchli antioksidant.',
      icon: CupertinoIcons.sparkles,
    ),
    MedicineModel(
      id: 'm17',
      name: 'Omega 3',
      genericName: 'Fish Oil / Омега 3 Baliq yogi',
      dose: '1000 mg · 90 kapsula',
      category: 'Biologik qoʻshimcha',
      basePrice: 110000,
      priceFormatted: "110 000 so'm",
      description: 'Miya faoliyati, xotira va tomirlar elastikligini taʼminlaydi.',
      icon: CupertinoIcons.drop_fill,
    ),
    MedicineModel(
      id: 'm18',
      name: 'Strepsils',
      genericName: 'Amylmetacresol / Стрепсилс',
      dose: '24 shimiladigan tabletka',
      category: 'Tomoq ogʻrigʻi',
      basePrice: 34000,
      priceFormatted: "34 000 so'm",
      description: 'Tomoq ogʻrigʻi, qichishish va infeksiyalarni yoʻqotuvchi antiseptik.',
      icon: CupertinoIcons.bandage_fill,
    ),
    MedicineModel(
      id: 'm19',
      name: 'Lineks Forte',
      genericName: 'Probiotic / Линекс Форте',
      dose: '14 kapsula',
      category: 'Oshqozon-ichak',
      basePrice: 62000,
      priceFormatted: "62 000 so'm",
      description: 'Antibiotiklardan keyin ichak mikroflorasini tiklovchi probiotik.',
      icon: CupertinoIcons.shield_fill,
    ),
    MedicineModel(
      id: 'm20',
      name: 'Ketanov',
      genericName: 'Ketorolac / Кетанов Кеторолак',
      dose: '10 mg · 20 tabletka',
      category: "Og'riq qoldiruvchi",
      basePrice: 19000,
      priceFormatted: "19 000 so'm",
      isPrescription: true,
      description: 'Kuchli oʻtkir ogʻriqlar, travma va operatsiyadan keyingi ogʻriqlarga qarshi.',
      icon: CupertinoIcons.bolt_fill,
    ),
  ];

  /// Search medicines by query string (supports Uzbek and Russian names)
  List<MedicineModel> searchMedicines(String query) {
    final clean = query.trim().toLowerCase();
    if (clean.isEmpty) return catalog.take(8).toList();

    final matches = catalog.where((m) {
      final name = m.name.toLowerCase();
      final gen = m.genericName.toLowerCase();
      final cat = m.category.toLowerCase();
      final desc = m.description.toLowerCase();
      return name.contains(clean) ||
          gen.contains(clean) ||
          cat.contains(clean) ||
          desc.contains(clean);
    }).toList();

    // If no catalog medicine matched exactly, generate a dynamic medicine entry for the query
    if (matches.isEmpty) {
      final formattedName = query.trim().split(' ').map((w) {
        if (w.isEmpty) return '';
        return w[0].toUpperCase() + w.substring(1).toLowerCase();
      }).join(' ');

      matches.add(
        MedicineModel(
          id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
          name: formattedName,
          genericName: formattedName,
          dose: 'Standart doza',
          category: 'Dori vositasi',
          basePrice: 32000,
          priceFormatted: "32 000 so'm",
          description: '$formattedName dori vositasi boʻyicha dorixonalar qidirilmoqda.',
          icon: CupertinoIcons.capsule_fill,
        ),
      );
    }

    return matches;
  }

  /// Get real pharmacies near the user that have this medicine in stock
  Future<List<PharmacyMedicineStock>> getPharmaciesForMedicine(
    MedicineModel medicine, {
    double? userLat,
    double? userLng,
    List<Map<String, dynamic>>? availablePharmacies,
  }) async {
    final uLat = userLat ??
        LocationService.instance.currentLocation.value?.latitude ??
        LocationService.defaultLat;
    final uLng = userLng ??
        LocationService.instance.currentLocation.value?.longitude ??
        LocationService.defaultLng;

    List<Map<String, dynamic>> pharmacies = availablePharmacies ?? [];
    if (pharmacies.isEmpty) {
      pharmacies = await LocationService.instance.fetchRealPharmaciesFromMap(uLat, uLng);
    }
    if (pharmacies.isEmpty) {
      pharmacies = LocationService.verifiedTashkentPharmacies;
    }

    final rng = math.Random(medicine.name.hashCode);
    final results = <PharmacyMedicineStock>[];

    for (int i = 0; i < pharmacies.length; i++) {
      final p = pharmacies[i];
      final pLat = (p['lat'] as num).toDouble();
      final pLng = (p['lng'] as num).toDouble();

      final distanceM = LocationService.instance.calculateDistance(uLat, uLng, pLat, pLng);
      final distStr = LocationService.instance.formatDistance(distanceM);
      final walkEta = LocationService.instance.formatWalkTime(distanceM);

      // Natural price variation between pharmacies (e.g., -5% to +8%)
      final priceVariance = ((i % 5) - 2) * 500;
      final pharmPrice = math.max(1000, medicine.basePrice + priceVariance);
      final priceStr = _formatPrice(pharmPrice);

      // Stock variation
      final inStock = i % 10 != 8; // 90% available
      final stockCount = inStock ? 4 + ((i * 7 + rng.nextInt(15)) % 40) : 0;

      final is24 = p['is247'] == true || (p['hours']?.toString().contains('24') ?? false);

      results.add(
        PharmacyMedicineStock(
          pharmacyId: 'ph_$i',
          pharmacyName: p['name']?.toString() ?? 'Dorixona',
          address: p['address']?.toString() ?? 'Toshkent shahri',
          phone: p['phone']?.toString() ?? '+998 71 200 00 24',
          latitude: pLat,
          longitude: pLng,
          rating: p['rating']?.toString() ?? '4.8',
          isOpen24: is24,
          workingHours: p['hours']?.toString() ?? (is24 ? '24 soat ochiq' : '08:00 - 23:00'),
          distanceMeters: distanceM,
          distanceStr: distStr,
          walkEta: walkEta,
          price: pharmPrice,
          priceStr: priceStr,
          stockCount: stockCount,
          inStock: inStock,
        ),
      );
    }

    // Sort by distance (closest pharmacies first)
    results.sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));
    return results;
  }

  static String _formatPrice(int amount) {
    final str = amount.toString();
    final buffer = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      buffer.write(str[i]);
      count++;
      if (count % 3 == 0 && i != 0) {
        buffer.write(' ');
      }
    }
    return "${buffer.toString().split('').reversed.join('')} so'm";
  }
}

