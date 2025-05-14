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
}

class Order extends Equatable {
  final String id;
  final String orderNumber;
  final DateTime dateTime;
  final String tableNumber;
  final List<OrderItem> items;

  const Order({
    required this.id,
    required this.orderNumber,
    required this.dateTime,
    required this.tableNumber,
    required this.items,
  });

  int get itemCount => items.length;
  
  double get totalAmount {
    return items.fold(0, (sum, item) => sum + (item.price * item.quantity));
  }

  @override
  List<Object> get props => [id, orderNumber, dateTime, tableNumber, items];
}