// lib/data/repositories/order_repository_impl.dart
import 'dart:async';

import 'package:app_serveur/core/api/api_client.dart';
import '../models/order.dart';
import '../models/assistance_request.dart';
import 'order_repository.dart';

extension StringExtension on String {
  String capitalize() {
    if (this.isEmpty) return this;
    return "${this[0].toUpperCase()}${this.substring(1)}";
  }
}

class OrderRepositoryImpl implements OrderRepository {
  final ApiClient _apiClient;

  OrderRepositoryImpl({
    required ApiClient apiClient,
  }) : _apiClient = apiClient;

@override
Future<List<Order>> getNewOrders() async {
  try {
    print('[DEBUG] Fetching new orders (pending and preparing)...');
    // First get pending orders
    final pendingData = await _apiClient.get('/orders/pending/');
    // Then get preparing orders
    final preparingData = await _apiClient.get('/orders/preparing/');
    
    List<Order> allOrders = [];
    
    if (pendingData is List) {
      allOrders.addAll(_mapOrdersFromJson(pendingData));
    } else if (pendingData is Map && pendingData.containsKey('data')) {
      final items = pendingData['data'];
      if (items is List) {
        allOrders.addAll(_mapOrdersFromJson(items));
      }
    }
    
    if (preparingData is List) {
      allOrders.addAll(_mapOrdersFromJson(preparingData));
    } else if (preparingData is Map && preparingData.containsKey('data')) {
      final items = preparingData['data'];
      if (items is List) {
        allOrders.addAll(_mapOrdersFromJson(items));
      }
    }
    
    print('[DEBUG] Total new orders: ${allOrders.length}');
    return allOrders;
  } catch (e) {
    print('[ERROR] Failed to fetch new orders: $e');
    rethrow;
  }
}

  // Helper method to map JSON to Order objects
  List<Order> _mapOrdersFromJson(List items) {
    List<Order> orders = [];
    for (var item in items) {
      try {
        if (item is Map<String, dynamic>) {
          // Map the backend response fields to your Order model fields
          final orderMap = _transformResponseToOrderMap(item);
          orders.add(Order.fromJson(orderMap));
        }
      } catch (e) {
        print('Error parsing order item: $e');
      }
    }
    return orders;
  }

  // Transform the backend response to match Order model's expected format
  Map<String, dynamic> _transformResponseToOrderMap(Map<String, dynamic> responseItem) {
    // Debug logging
    print('Processing order item: $responseItem');
    
    // Extract items from the response with better safety checks
    List<Map<String, dynamic>> orderItems = [];
    
    try {
      // Handle both direct items array and items in nested structure
      var itemsList;
      
      if (responseItem.containsKey('items') && responseItem['items'] is List) {
        itemsList = responseItem['items'];
      } else if (responseItem.containsKey('plats') && responseItem['plats'] is List) {
        itemsList = responseItem['plats'];
      } else {
        // If we have a commande_plat relationship, try to extract items
        itemsList = [];
      }
      
      if (itemsList != null) {
        for (var item in itemsList) {
          if (item is Map<String, dynamic>) {
            orderItems.add({
              'id': item['idP'] ?? item['id'] ?? '',
              'productId': item['idP'] ?? item['id'] ?? '',
              'name': item['nom'] ?? item['name'] ?? '',
              'quantity': item['quantite'] ?? item['quantité'] ?? item['quantity'] ?? 1,
              'price': _extractPrice(item),
              'options': <String>[],  // Assuming no options in the response
            });
          }
        }
      }
    } catch (e) {
      print('Error extracting order items: $e');
    }

    // Extract ID safely
    String orderId = '';
    if (responseItem.containsKey('id')) {
      orderId = responseItem['id'].toString();
    } else if (responseItem.containsKey('idCmd')) {
      orderId = responseItem['idCmd'].toString();
    }
    
    // Extract customer info if available
    String customerName = '';
    String customerId = '';
    try {
      if (responseItem.containsKey('client') && 
          responseItem['client'] is Map<String, dynamic>) {
        customerName = responseItem['client']['username'] ?? '';
      }
      customerId = responseItem['idC']?.toString() ?? responseItem['client_id']?.toString() ?? '';
    } catch (e) {
      print('Error extracting customer info: $e');
    }
    
    // Extract customer count from the table information if available
    int customerCount = 0;
    try {
      if (responseItem.containsKey('table') && 
          responseItem['table'] is Map<String, dynamic> &&
          responseItem['table'].containsKey('nbrPersonne')) {
        customerCount = (responseItem['table']['nbrPersonne'] as num?)?.toInt() ?? 0;
      }
    } catch (e) {
      print('Error extracting customer count: $e');
    }

    // Safe extraction of table ID
    String tableId = '';
    try {
      if (responseItem.containsKey('table') && responseItem['table'] is Map) {
        tableId = (responseItem['table']['id'] ?? '').toString();
      } else if (responseItem.containsKey('idTable')) {
        tableId = responseItem['idTable'].toString();
      }
    } catch (e) {
      print('Error extracting table ID: $e');
    }

    // Get the status - FIXED: More comprehensive status mapping
    String orderStatus = _mapStatusFromResponse(responseItem['etat'] ?? responseItem['status'] ?? '');
    print('Original status: ${responseItem['etat'] ?? responseItem['status']}, Mapped status: $orderStatus');

    // Create a standardized order map that matches the Order.fromJson expectation
    return {
      'id': orderId,
      'tableId': tableId,
      'userId': customerId,
      'customerName': customerName,
      'status': orderStatus,
      'statusDisplay': _getStatusDisplayName(orderStatus),
      'items': orderItems,
      'createdAt': responseItem['dateCreation'] ?? responseItem['created_at'] ?? DateTime.now().toIso8601String(),
      'updatedAt': responseItem['updated_at'] ?? responseItem['dateCreation'] ?? DateTime.now().toIso8601String(),
      'customerCount': customerCount,
      'notes': responseItem['notes'] ?? '',
      'totalPrice': _calculateTotalPrice(orderItems),
    };
  }

  double _extractPrice(Map<String, dynamic> item) {
    try {
      var price = item['prix'] ?? item['price'] ?? 0.0;
      if (price is int) {
        return price.toDouble();
      } else if (price is double) {
        return price;
      } else if (price is String) {
        return double.tryParse(price) ?? 0.0;
      }
      return 0.0;
    } catch (e) {
      print('Error extracting price: $e');
      return 0.0;
    }
  }

  double _calculateTotalPrice(List<Map<String, dynamic>> items) {
    double total = 0.0;
    for (var item in items) {
      total += (item['price'] ?? 0.0) * (item['quantity'] ?? 1);
    }
    return total;
  }

  String _getStatusDisplayName(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'En attente';
      case 'preparing':
        return 'En préparation';
      case 'ready':
        return 'Prêt';
      case 'served':
        return 'Servi';
      case 'cancelled':
        return 'Annulé';
      case 'completed':
        return 'Terminé';
      default:
        return status.capitalize();
    }
  }

  // FIXED: Improved status mapping to handle all variations
String _mapStatusFromResponse(dynamic status) {
  if (status == null) return 'pending';
  
  String statusStr = status.toString().toLowerCase().trim();
  
  // Map all possible backend status values to frontend statuses
  if (statusStr.contains('attente') || 
      statusStr == 'pending' || 
      statusStr == 'en_attente' ||
      statusStr == 'en attente') {
    return 'pending';
  }
  if (statusStr.contains('preparation') || 
      statusStr == 'preparing' || 
      statusStr == 'en_preparation' ||
      statusStr == 'en preparation') {
    return 'preparing';
  }
  if (statusStr.contains('pret') || 
      statusStr.contains('prete') || 
      statusStr == 'ready') {
    return 'ready';
  }
  if (statusStr.contains('servi') || 
      statusStr.contains('servie') || 
      statusStr == 'served') {
    return 'served';
  }
  if (statusStr.contains('annul') || 
      statusStr == 'cancelled' || 
      statusStr == 'annulee') {
    return 'cancelled';
  }
  
  return 'pending'; // Default to pending for unrecognized status
}

 // Update the _mapStatusToBackend method
String _mapStatusToBackend(String frontendStatus) {
  switch (frontendStatus.toLowerCase()) {
    case 'pending': return 'en_attente';
    case 'preparing': return 'en_preparation';
    case 'ready': return 'pret';
    case 'served': return 'servi';
    case 'cancelled': return 'annulee';
    default: return frontendStatus;
  }
}

  @override
  Future<List<Order>> getAllOrders() async {
    try {
      final dynamic data = await _apiClient.get('/orders/');
      print('All orders data received: $data'); // Debug log
      
      if (data is List) {
        return _mapOrdersFromJson(data);
      } else if (data is Map<String, dynamic> && data.containsKey('data')) {
        final items = data['data'];
        if (items is List) {
          return _mapOrdersFromJson(items);
        }
      }
      return [];
    } catch (e) {
      print('Error fetching all orders: $e'); // Debug log
      throw Exception('Failed to fetch all orders: ${e.toString()}');
    }
  }

  @override
  Future<List<Order>> getReadyOrders() async {
    try {
      final dynamic data = await _apiClient.get('/orders/ready/');
      print('Ready orders data: $data'); // Debug log
      
      if (data is List) {
        return _mapOrdersFromJson(data);
      } else if (data is Map<String, dynamic> && data.containsKey('data')) {
        final items = data['data'];
        if (items is List) {
          return _mapOrdersFromJson(items);
        }
      }
      return [];
    } catch (e) {
      print('Error fetching ready orders: $e'); // Debug log
      throw Exception('Failed to fetch ready orders: ${e.toString()}');
    }
  }
// In lib/data/repositories/order_repository_impl.dart
// Updated getOrderDetails method in order_repository_impl.dart

@override
Future<Order> getOrderDetails(String orderId) async {
  try {
    print('[DEBUG] Fetching order details for ID: $orderId');
    final dynamic data = await _apiClient.get('/orders/$orderId/');
    print('[DEBUG] Received data: $data');
    
    if (data is Map<String, dynamic>) {
      // The new API returns detailed information, so we can use it directly
      // Transform the response to ensure compatibility with Order.fromJson
      final orderMap = {
        'id': data['id'],
        'dateCreation': data['dateCreation'],
        'etat': data['etat'],
        'table': data['table'],
        'client': data['client'],
        'server': data['server'],
        'montant': data['montant'],
        'calculated_total': data['calculated_total'],
        'confirmation': data['confirmation'],
        'items': data['items'], // This now contains the detailed dish information
        'items_count': data['items_count'],
        'total_quantity': data['total_quantity'],
        'notes': data['notes'] ?? '',
      };
      
      print('[DEBUG] Transformed order map: $orderMap');
      return Order.fromJson(orderMap);
    }
    
    throw Exception('Invalid order details format');
  } catch (e) {
    print('[ERROR] Failed to fetch order details: $e');
    throw Exception('Failed to fetch order details: ${e.toString()}');
  }
}
  @override
  Future<List<Order>> getServedOrders() async {
    try {
      final dynamic data = await _apiClient.get('/orders/served/');
      print('Served orders data: $data'); // Debug log
      
      if (data is List) {
        return _mapOrdersFromJson(data);
      } else if (data is Map<String, dynamic> && data.containsKey('data')) {
        final items = data['data'];
        if (items is List) {
          return _mapOrdersFromJson(items);
        }
      }
      return [];
    } catch (e) {
      print('Error fetching served orders: $e'); // Debug log
      throw Exception('Failed to fetch served orders: ${e.toString()}');
    }
  }

  @override
  Future<List<Order>> getCancelledOrders() async {
    try {
      final dynamic data = await _apiClient.get('/orders/cancelled/');
      print('Cancelled orders data: $data'); // Debug log
      
      if (data is List) {
        return _mapOrdersFromJson(data);
      } else if (data is Map<String, dynamic> && data.containsKey('data')) {
        final items = data['data'];
        if (items is List) {
          return _mapOrdersFromJson(items);
        }
      }
      return [];
    } catch (e) {
      print('Error fetching cancelled orders: $e'); // Debug log
      throw Exception('Failed to fetch cancelled orders: ${e.toString()}');
    }
  }

  @override
  Future<List<Order>> getPreparingOrders() async {
    try {
      final dynamic data = await _apiClient.get('/orders/preparing/');
      print('Preparing orders data: $data'); // Debug log
      
      if (data is List) {
        return _mapOrdersFromJson(data);
      } else if (data is Map<String, dynamic> && data.containsKey('data')) {
        final items = data['data'];
        if (items is List) {
          return _mapOrdersFromJson(items);
        }
      }
      return [];
    } catch (e) {
      print('Error fetching preparing orders: $e'); // Debug log
      throw Exception('Failed to fetch preparing orders: ${e.toString()}');
    }
  }

  // FIXED: Proper implementation of serveOrder
  @override
  Future<void> serveOrder(String orderId) async {
    try {
      print('Serving order $orderId...');
      
      // Using PUT to update order status to 'servi'
      final response = await _apiClient.put(
        '/orders/$orderId/status/', 
        data: {'status': 'servi'} // Use backend format directly
      );
      
      print('Serve order response: $response');
    } catch (e) {
      print('Error serving order: $e');
      throw Exception('Failed to serve order: ${e.toString()}');
    }
  }

  @override
  Future<void> completeOrder(String orderId) async {
    try {
      print('Attempting to complete order: $orderId');
      final response = await _apiClient.put(
        '/orders/$orderId/status/', 
        data: {'status': _mapStatusToBackend('completed')}
      );
      print('Complete order response: $response');
    } catch (e) {
      print('Error completing order: $e');
      throw Exception('Failed to complete order: ${e.toString()}');
    }
  }

  @override
  Future<void> cancelOrder(String orderId) async {
    try {
      await _apiClient.put(
        '/orders/$orderId/status/',
        data: {'status': _mapStatusToBackend('cancelled')}
      );
    } catch (e) {
      throw Exception('Failed to cancel order: ${e.toString()}');
    }
  }

// Dans order_repository_impl.dart, modifiez ces deux méthodes:

@override
Future<void> requestCancelOrder(String orderId, String currentStatus) async {
  try {
    if (currentStatus == 'pending' || currentStatus == 'new') {
      await directCancelOrder(orderId);
    } else {
      final response = await _apiClient.post(
        '/orders/$orderId/request-cancel/',
        data: {'motif': 'Demande d\'annulation par serveur'},
      ).timeout(const Duration(seconds: 10));

      print('Cancellation request created successfully: $response');
    }
  } on TimeoutException {
    throw Exception('La demande a pris trop de temps. Veuillez réessayer.');
  } on ApiException catch (e) {
    throw Exception('Erreur de serveur: ${e.message}');
  } catch (e) {
    throw Exception('Impossible de créer la demande d\'annulation: ${e.toString()}');
  }
}

@override
Future<void> directCancelOrder(String orderId) async {
  try {
    final response = await _apiClient.post(
      '/orders/$orderId/cancel/',
    ).timeout(const Duration(seconds: 10));

    print('Order cancelled successfully: $response');
  } on TimeoutException {
    throw Exception('La demande a pris trop de temps. Veuillez réessayer.');
  } on ApiException catch (e) {
    throw Exception('Erreur de serveur: ${e.message}');
  } catch (e) {
    throw Exception('Impossible d\'annuler la commande: ${e.toString()}');
  }
}

  

  @override
  Future<List<AssistanceRequest>> getAssistanceRequests() async {
    try {
      final dynamic data = await _apiClient.get('/assistance/');
      
      if (data is List) {
        return List<AssistanceRequest>.from(
          data.map((item) => AssistanceRequest.fromJson(item as Map<String, dynamic>))
        );
      } else if (data is Map<String, dynamic> && data.containsKey('data')) {
        final items = data['data'];
        if (items is List) {
          return List<AssistanceRequest>.from(
            items.map((item) => AssistanceRequest.fromJson(item as Map<String, dynamic>))
          );
        }
      }
      return [];
    } catch (e) {
      throw Exception('Failed to fetch assistance requests: ${e.toString()}');
    }
  }

  @override
  Future<void> completeAssistanceRequest(String requestId) async {
    try {
      await _apiClient.post('/assistance/$requestId/complete/');
    } catch (e) {
      throw Exception('Failed to complete assistance request: ${e.toString()}');
    }
  }
}