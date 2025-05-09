// lib/data/repositories/order_repository_impl.dart
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
      print('[DEBUG] Fetching pending orders...');
      final dynamic data = await _apiClient.get('/orders/pending/');
      print('[DEBUG] Pending orders raw data: $data');
      
      if (data is List) {
        print('[DEBUG] Received ${data.length} pending orders');
        return _mapOrdersFromJson(data);
      } else if (data is Map && data.containsKey('data')) {
        print('[DEBUG] Received pending orders in data field');
        final items = data['data'];
        if (items is List) {
          return _mapOrdersFromJson(items);
        }
      }
      return [];
    } catch (e) {
      print('[ERROR] Failed to fetch pending orders: $e');
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
    
    // More comprehensive status mapping
    if (statusStr.contains('attente') || statusStr == 'pending') return 'pending';
    if (statusStr.contains('preparation') || statusStr == 'preparing') return 'preparing';
    if (statusStr.contains('pret') || statusStr.contains('prete') || statusStr == 'ready') return 'ready';
    if (statusStr.contains('servi') || statusStr.contains('servie') || statusStr.contains('service') || statusStr == 'served') return 'served';
    if (statusStr.contains('termin') || statusStr == 'completed') return 'completed';
    if (statusStr.contains('annul') || statusStr == 'cancelled') return 'cancelled';
    
    return 'pending'; // Default to pending for unrecognized status
  }

  // FIXED: Ensuring consistent status values sent to backend
  String _mapStatusToBackend(String frontendStatus) {
    switch (frontendStatus.toLowerCase()) {
      case 'pending': return 'en_attente';
      case 'preparing': return 'en_preparation';
      case 'ready': return 'pret';
      case 'served': return 'servi';
      case 'completed': return 'termine';
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