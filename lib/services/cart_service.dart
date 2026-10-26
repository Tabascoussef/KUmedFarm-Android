import 'package:flutter/material.dart';

class CartItem {
  final int id;
  final String name;
  final String dose;
  final String price;
  final int rawPrice;
  final Color pastelBg;
  int quantity;

  CartItem({
    required this.id,
    required this.name,
    required this.dose,
    required this.price,
    required this.rawPrice,
    required this.pastelBg,
    this.quantity = 1,
  });

  CartItem copyWith({int? quantity}) {
    return CartItem(
      id: id,
      name: name,
      dose: dose,
      price: price,
      rawPrice: rawPrice,
      pastelBg: pastelBg,
      quantity: quantity ?? this.quantity,
    );
  }
}

class CartService {
  static final CartService instance = CartService._internal();
  CartService._internal();

  final ValueNotifier<List<CartItem>> items = ValueNotifier<List<CartItem>>([]);

  int get totalCount => items.value.fold(0, (sum, i) => sum + i.quantity);

  int get subtotal => items.value.fold(0, (sum, i) => sum + (i.rawPrice * i.quantity));

  void addItem({
    required int id,
    required String name,
    required String dose,
    required String price,
    required int rawPrice,
    required Color pastelBg,
    int quantity = 1,
  }) {
    final list = List<CartItem>.from(items.value);
    final index = list.indexWhere((element) => element.id == id);
    if (index >= 0) {
      list[index].quantity += quantity;
    } else {
      list.add(
        CartItem(
          id: id,
          name: name,
          dose: dose,
          price: price,
          rawPrice: rawPrice,
          pastelBg: pastelBg,
          quantity: quantity,
        ),
      );
    }
    items.value = list;
  }

  void updateQuantity(int id, int delta) {
    final list = List<CartItem>.from(items.value);
    final index = list.indexWhere((element) => element.id == id);
    if (index >= 0) {
      final newQty = list[index].quantity + delta;
      if (newQty <= 0) {
        list.removeAt(index);
      } else {
        list[index].quantity = newQty;
      }
      items.value = list;
    }
  }

  void removeItem(int id) {
    final list = List<CartItem>.from(items.value);
    list.removeWhere((element) => element.id == id);
    items.value = list;
  }

  void clear() {
    items.value = [];
  }
}
