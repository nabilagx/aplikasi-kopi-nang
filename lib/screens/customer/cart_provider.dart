import 'package:flutter/material.dart';

class CartProvider with ChangeNotifier {
  final List<Map<String, dynamic>> _items = [];

  List<Map<String, dynamic>> get items => _items;

  void addItem(Map<String, dynamic> product) {
    final index = _items.indexWhere((item) => item['id'] == product['id']);
    if (index >= 0) {
      _items[index]['qty'] += 1;
    } else {
      _items.add({...product, 'qty': 1});
    }
    notifyListeners();
  }

  void removeItem(int productId) {
    _items.removeWhere((item) => item['id'] == productId);
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }

  void increaseQty(int index) {
    if (index >= 0 && index < _items.length) {
      _items[index]['qty'] += 1;
      notifyListeners();
    }
  }

  void decreaseQty(int index) {
    if (index >= 0 && index < _items.length) {
      if (_items[index]['qty'] > 1) {
        _items[index]['qty'] -= 1;
      } else {
        _items.removeAt(index);
      }
      notifyListeners();
    }
  }

  num get totalHarga {
    return _items.fold(0, (total, item) => total + (item['harga'] * item['qty']));
  }
}
