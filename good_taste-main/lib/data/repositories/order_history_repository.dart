// lib/data/repositories/order_history_repository.dart
import 'dart:async';
import 'package:good_taste/data/models/order.dart';
import 'package:good_taste/data/models/user.dart';

class OrderHistoryRepository {
 
  final List<Order> _mockOrders = [
    Order(
      id: '1',
      orderNumber: '#5',
      dateTime: DateTime(2025, 3, 25, 18, 12),
      tableNumber: '10',
      items: [
        OrderItem(name: 'Soupe de Poisson', quantity: 1, price: 10.0),
        OrderItem(name: 'Salade de Chèvre Chaud', quantity: 1, price: 9.0),
        OrderItem(name: 'Boeuf Bourguignon', quantity: 1, price: 17.50),
        OrderItem(name: 'Smoothie Tropical', quantity: 1, price: 6.0),
      ],
    ),
    Order(
      id: '2',
      orderNumber: '#5',
      dateTime: DateTime(2025, 3, 22, 19, 30),
      tableNumber: '5',
      items: [
        OrderItem(name: 'Soupe de Poisson', quantity: 2, price: 10.0),
        OrderItem(name: 'Salade de Chèvre Chaud', quantity: 2, price: 9.0),
      ],
    ),
    Order(
      id: '3',
      orderNumber: '#5',
      dateTime: DateTime(2025, 3, 20, 12, 45),
      tableNumber: '3',
      items: [
        OrderItem(name: 'Soupe de Poisson', quantity: 1, price: 10.0),
        OrderItem(name: 'Salade de Chèvre Chaud', quantity: 1, price: 9.0),
        OrderItem(name: 'Boeuf Bourguignon', quantity: 1, price: 17.50),
        OrderItem(name: 'Smoothie Tropical', quantity: 1, price: 6.0),
      ],
    ),
   
  ];

  Future<List<Order>> getOrderHistory(User user) {
  
    return Future.delayed(
      const Duration(milliseconds: 800),
      () => _mockOrders,
    );
  }

  Future<bool> deleteOrder(String orderId) {
   
    return Future.delayed(
      const Duration(milliseconds: 500),
      () {
        final index = _mockOrders.indexWhere((order) => order.id == orderId);
        if (index != -1) {
          _mockOrders.removeAt(index);
          return true;
        }
        return false;
      },
    );
  }
}