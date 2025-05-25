import 'package:flutter/material.dart';
import 'cart_service.dart';

class OrderHistoryItem {
  final String id;
  final DateTime date;
  final List<CartItem> items;
  final double total;
  final bool reductionAppliquee;
  final double montantReduction;
  final int pointsUtilises;
  final String? firebaseOrderId;
  final String? djangoOrderId;

  OrderHistoryItem({
    required this.id,
    required this.items,
    required this.total,
    required this.reductionAppliquee,
    required this.montantReduction,
    required this.pointsUtilises,
    this.firebaseOrderId,
    this.djangoOrderId,
  }) : date = DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'items': items.map((item) => item.toMap()).toList(),
      'total': total,
      'reductionAppliquee': reductionAppliquee,
      'montantReduction': montantReduction,
      'pointsUtilises': pointsUtilises,
      'firebaseOrderId': firebaseOrderId,
      'djangoOrderId': djangoOrderId,
    };
  }

  factory OrderHistoryItem.fromMap(Map<String, dynamic> map) {
    return OrderHistoryItem(
      id: map['id'],
      items: (map['items'] as List).map((item) => CartItem.fromMap(item)).toList(),
      total: map['total'],
      reductionAppliquee: map['reductionAppliquee'] ?? false,
      montantReduction: map['montantReduction'] ?? 0,
      pointsUtilises: map['pointsUtilises'] ?? 0,
      firebaseOrderId: map['firebaseOrderId'],
      djangoOrderId: map['djangoOrderId'],
    );
  }
}

class OrderHistoryService extends ChangeNotifier {
  List<OrderHistoryItem> _orders = [];

  List<OrderHistoryItem> get orders => [..._orders];

  void addOrder({
    required List<CartItem> items,
    required double total,
    bool reductionAppliquee = false,
    double montantReduction = 0,
    int pointsUtilises = 0,
    String? firebaseOrderId,
    String? djangoOrderId,
  }) {
    _orders.insert(0, OrderHistoryItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      items: List.from(items),
      total: total,
      reductionAppliquee: reductionAppliquee,
      montantReduction: montantReduction,
      pointsUtilises: pointsUtilises,
      firebaseOrderId: firebaseOrderId,
      djangoOrderId: djangoOrderId,
    ));
    notifyListeners();
  }

  void clearHistory() {
    _orders.clear();
    notifyListeners();
  }

  Map<String, dynamic> toMap() {
    return {
      'orders': _orders.map((order) => order.toMap()).toList(),
    };
  }

  void fromMap(Map<String, dynamic> map) {
    _orders = (map['orders'] as List)
        .map((order) => OrderHistoryItem.fromMap(order))
        .toList();
    notifyListeners();
  }
}