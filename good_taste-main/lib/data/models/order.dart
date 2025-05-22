// lib/data/models/order.dart
import 'package:equatable/equatable.dart';

class OrderItem {
  final String name;
  final int quantity;
  final double price;

  OrderItem({
    required this.name,
    required this.quantity,
    required this.price,
  });

  double get totalPrice => price * quantity;

  // Factory method to create OrderItem from JSON
  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      name: json['name'] ?? '',
      quantity: json['quantity'] ?? 0,
      price: (json['price'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'quantity': quantity,
      'price': price,
    };
  }
}

class Order extends Equatable {
  final String id;
  final String orderNumber;
  final DateTime dateTime;
  final String tableNumber;
  final List<OrderItem> items;
  final double montant;
  final String etat;
  final bool confirmation;

  const Order({
    required this.id,
    required this.orderNumber,
    required this.dateTime,
    required this.tableNumber,
    required this.items,
    required this.montant,
    required this.etat,
    required this.confirmation,
  });

  int get itemCount => items.length;
  
  double get totalAmount => montant;

  // Factory method to create Order from API response
  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] ?? '',
      orderNumber: '#${json['id'] ?? ''}', // Format order number
      dateTime: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
      tableNumber: json['table_number'] ?? '', // You might need to adjust this based on your API
      items: [], // Items might need to be fetched separately or included in the response
      montant: (json['montant'] ?? 0).toDouble(),
      etat: json['etat'] ?? '',
      confirmation: json['confirmation'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': dateTime.toIso8601String(),
      'montant': montant,
      'etat': etat,
      'confirmation': confirmation,
    };
  }

  @override
  List<Object> get props => [id, orderNumber, dateTime, tableNumber, items, montant, etat, confirmation];
}