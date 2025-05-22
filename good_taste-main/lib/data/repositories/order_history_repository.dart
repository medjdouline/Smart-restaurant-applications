// lib/data/repositories/order_history_repository.dart
import 'dart:async';
import 'package:good_taste/data/models/order.dart';
import 'package:good_taste/data/models/user.dart';
import 'package:good_taste/data/api/order_api_service.dart';
import 'package:logger/logger.dart';

class OrderHistoryRepository {
  final OrderApiService _orderApiService;
  final Logger _logger = Logger();

  OrderHistoryRepository({
    required OrderApiService orderApiService,
  }) : _orderApiService = orderApiService;

  Future<List<Order>> getOrderHistory(User user) async {
    try {
      _logger.d('Fetching order history from API...');
      
      final response = await _orderApiService.getOrdersHistory();
      
      if (response.success && response.data != null) {
        final List<dynamic> ordersData = response.data as List<dynamic>;
        
        final orders = ordersData.map((orderJson) {
          return Order.fromJson(orderJson as Map<String, dynamic>);
        }).toList();
        
        _logger.d('Successfully fetched ${orders.length} orders');
        return orders;
      } else {
        _logger.e('Failed to fetch order history: ${response.error}');
        throw Exception(response.error ?? 'Failed to fetch order history');
      }
    } catch (e) {
      _logger.e('Error fetching order history: $e');
      throw Exception('Failed to fetch order history: $e');
    }
  }

  Future<bool> deleteOrder(String orderId) async {
    try {
      _logger.d('Deleting order with ID: $orderId');
      
      final response = await _orderApiService.deleteOrderFromHistory(orderId);
      
      if (response.success) {
        _logger.d('Successfully deleted order: $orderId');
        return true;
      } else {
        _logger.e('Failed to delete order: ${response.error}');
        return false;
      }
    } catch (e) {
      _logger.e('Error deleting order: $e');
      return false;
    }
  }

  // Keep the mock orders for fallback or testing
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
      montant: 42.50,
      etat: 'completed',
      confirmation: true,
    ),
    Order(
      id: '2',
      orderNumber: '#4',
      dateTime: DateTime(2025, 3, 22, 19, 30),
      tableNumber: '5',
      items: [
        OrderItem(name: 'Soupe de Poisson', quantity: 2, price: 10.0),
        OrderItem(name: 'Salade de Chèvre Chaud', quantity: 2, price: 9.0),
      ],
      montant: 38.0,
      etat: 'completed',
      confirmation: true,
    ),
    Order(
      id: '3',
      orderNumber: '#3',
      dateTime: DateTime(2025, 3, 20, 12, 45),
      tableNumber: '3',
      items: [
        OrderItem(name: 'Soupe de Poisson', quantity: 1, price: 10.0),
        OrderItem(name: 'Salade de Chèvre Chaud', quantity: 1, price: 9.0),
        OrderItem(name: 'Boeuf Bourguignon', quantity: 1, price: 17.50),
        OrderItem(name: 'Smoothie Tropical', quantity: 1, price: 6.0),
      ],
      montant: 42.50,
      etat: 'completed',
      confirmation: true,
    ),
  ];

  // Method to use mock data for testing
  Future<List<Order>> getMockOrderHistory() {
    return Future.delayed(
      const Duration(milliseconds: 800),
      () => _mockOrders,
    );
  }
}