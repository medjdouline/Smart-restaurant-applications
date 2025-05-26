import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
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
  final String? etat;
  final bool? confirmation;
  static const String _baseUrl = 'http://127.0.0.1:8000/api';

  OrderHistoryItem({
    required this.id,
    required this.items,
    required this.total,
    required this.reductionAppliquee,
    required this.montantReduction,
    required this.pointsUtilises,
    this.firebaseOrderId,
    this.djangoOrderId,
    this.etat,
    this.confirmation,
  }) : date = DateTime.now();

  // Constructor for API data
  OrderHistoryItem.fromApi({
    required this.id,
    required DateTime date,
    required this.total,
    this.etat,
    this.confirmation,
    this.items = const [],
    this.reductionAppliquee = false,
    this.montantReduction = 0,
    this.pointsUtilises = 0,
    this.firebaseOrderId,
    this.djangoOrderId,
  }) : date = date;

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
      'etat': etat,
      'confirmation': confirmation,
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
      etat: map['etat'],
      confirmation: map['confirmation'],
    );
  }

  factory OrderHistoryItem.fromApiResponse(Map<String, dynamic> json) {
    return OrderHistoryItem.fromApi(
      id: json['id'],
      date: DateTime.parse(json['date']),
      total: json['montant'].toDouble(),
      etat: json['etat'],
      confirmation: json['confirmation'],
    );
  }
}

class OrderHistoryService extends ChangeNotifier {
  List<OrderHistoryItem> _orders = [];
  bool _isLoading = false;
  String? _error;

  List<OrderHistoryItem> get orders => [..._orders];
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchOrdersFromApi(String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('http://127.0.0.1:8000/api/table/orders'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        // Check if response is JSON
        if (response.headers['content-type']?.contains('application/json') == true) {
          final List<dynamic> data = json.decode(response.body);
          _orders = data.map((json) => OrderHistoryItem.fromApiResponse(json)).toList();
          _error = null;
        } else {
          _error = 'API returned HTML instead of JSON. Check your endpoint URL.';
        }
      } else if (response.statusCode == 401) {
        _error = 'Authentication failed. Please login again.';
      } else if (response.statusCode == 404) {
        _error = 'API endpoint not found. Check your URL.';
      } else {
        _error = 'Server error (${response.statusCode}): ${response.reasonPhrase}';
      }
    } catch (e) {
      if (e.toString().contains('FormatException')) {
        _error = 'Invalid response format. Server returned HTML instead of JSON.';
      } else {
        _error = 'Network error: ${e.toString()}';
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

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