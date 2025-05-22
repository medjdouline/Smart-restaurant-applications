// lib/data/repositories/tables_api_repository.dart
import 'package:logger/logger.dart';
import '../../core/api/api_service.dart';
import '../models/table.dart';
import '../models/order.dart';

class TablesApiRepository {
  final _logger = Logger();

  // Get all tables from API
  Future<List<RestaurantTable>> getAllTables() async {
    try {
      final response = await ApiService.client.get('/tables/');
      _logger.d('Tables response: $response');
      
      if (response is List) {
        return response.map((tableData) => _parseTableFromFirebase(tableData)).toList();
      } else if (response is Map) {
        // If response is a Map, it might be wrapping the list
        if (response.containsKey('data') && response['data'] is List) {
          return (response['data'] as List)
              .map((tableData) => _parseTableFromFirebase(tableData))
              .toList();
        }
      }
      
      // Fall back to empty list if response format is unexpected
      _logger.w('Unexpected tables response format: $response');
      return [];
    } catch (e) {
      _logger.e('Error fetching tables: $e');
      rethrow;
    }
  }

  // Get orders for a specific table
  Future<List<Order>> getTableOrders(String tableId) async {
    try {
      final response = await ApiService.client.get('/tables/$tableId/orders/');
      _logger.d('Table orders response: $response');
      
      if (response is List) {
        return response.map((orderData) => _parseOrderFromFirebase(orderData, tableId)).toList();
      } else if (response is Map && response.containsKey('data') && response['data'] is List) {
        return (response['data'] as List)
            .map((orderData) => _parseOrderFromFirebase(orderData, tableId))
            .toList();
      }
      
      _logger.w('Unexpected table orders response format: $response');
      return [];
    } catch (e) {
      _logger.e('Error fetching table orders: $e');
      rethrow;
    }
  }

  // Update table status
  Future<RestaurantTable> updateTableStatus(String tableId, bool isOccupied) async {
    try {
      final status = isOccupied ? 'occupee' : 'libre';
      final response = await ApiService.client.put(
        '/tables/$tableId/status/',
        data: {'status': status},
      );
      
      _logger.d('Update table status response: $response');
      
      // Return updated table - ideally the API would return the updated table
      // For now, we'll fetch the table again to get the latest state
      final updatedTableData = await ApiService.client.get('/tables/');
      
      if (updatedTableData is List) {
        final tableList = updatedTableData.map((t) => _parseTableFromFirebase(t)).toList();
        final updatedTable = tableList.firstWhere(
          (t) => t.id == tableId,
          orElse: () => RestaurantTable(
            id: tableId,
            capacity: 0,
            isOccupied: isOccupied,
            orderCount: 0,
            customerCount: 0,
          ),
        );
        return updatedTable;
      } else if (updatedTableData is Map && updatedTableData.containsKey('message')) {
        // If the API just returns a success message, construct a table with the updated status
        _logger.d('API returned success message. Constructing updated table object.');
        
        // In a real app, we might want to get the table details again to ensure accuracy
        // but for now, we'll just update the status
        return RestaurantTable(
          id: tableId,
          capacity: 0, // We don't have this information from the API response
          isOccupied: isOccupied,
          orderCount: 0, // We don't have this information from the API response
          customerCount: 0, // We don't have this information from the API response
        );
      }
      
      _logger.w('Unexpected update table response format: $response');
      throw Exception('Failed to update table status: Unexpected response format');
    } catch (e) {
      _logger.e('Error updating table status: $e');
      rethrow;
    }
  }

  // Helper method to parse table data from Firebase format
// Mise à jour de la fonction _parseTableFromFirebase dans TablesApiRepository

// Voici un extrait modifié à intégrer dans tables_api_repository.dart
// Remplacer la méthode _parseTableFromFirebase existante par celle-ci

RestaurantTable _parseTableFromFirebase(Map<String, dynamic> data) {
  final String id = data['id'] ?? '';
  final String status = data['etatTable'] ?? 'libre';
  final bool isOccupied = status == 'occupee';
  final bool isReserved = status == 'reservee'; // Utilise le statut directement
  
  // Parse reservation data
  DateTime? reservationStart;
  DateTime? reservationEnd;
  String? clientName;
  int? reservationPersonCount;
  String? reservationStatus = 'En attente';

  if (data.containsKey('reservation') && data['reservation'] != null) {
    final reservationData = data['reservation'];
    reservationStart = reservationData['date_time'] != null 
        ? DateTime.tryParse(reservationData['date_time']) 
        : null;
    clientName = reservationData['client']?['username'] ?? 'Inconnu';
    reservationPersonCount = reservationData['party_size'];
    reservationStatus = reservationData['status'] == 'confirmee' 
        ? 'Confirmée' 
        : 'En attente';
  }

  return RestaurantTable(
    id: id,
    capacity: data['capacite'] ?? 4,
    isOccupied: isOccupied,
    isReserved: isReserved, // Ceci est maintenant correctement défini
    orderCount: (data['orders'] as List?)?.length ?? 0,
    customerCount: 0, // À calculer selon ta logique
    reservationStart: reservationStart,
    reservationEnd: reservationEnd,
    clientName: clientName,
    reservationPersonCount: reservationPersonCount,
    reservationStatus: reservationStatus,
  );
}
// Nouvelle méthode à ajouter au TablesApiRepository
Future<RestaurantTable> startReservation(String tableId) async {
  try {
    // Changement de PUT à POST pour correspondre à l'API Django
    final response = await ApiService.client.post(
      '/tables/$tableId/confirm-reservation/',
      data: {}, // Tu peux ajouter des données si nécessaire
    );
    
    _logger.d('Start reservation response: $response');
    
    // Recharge les tables pour obtenir la table mise à jour
    final tables = await getAllTables();
    return tables.firstWhere(
      (t) => t.id == tableId,
      orElse: () => throw Exception('Table not found after update'),
    );
  } catch (e) {
    _logger.e('Error starting reservation: $e');
    rethrow;
  }
}

  // Helper method to parse order data from Firebase format
  Order _parseOrderFromFirebase(Map<String, dynamic> data, String tableId) {
    final String id = data['id'] ?? '';
    final String status = _mapOrderStatus(data['etat'] ?? 'en attente');
    
    // Parse order items
    final List<OrderItem> items = [];
    if (data.containsKey('items') && data['items'] is List) {
      for (final item in data['items']) {
        items.add(OrderItem(
          id: item['idP'] ?? '',
          productId: item['idP'] ?? '',
          name: item['nom'] ?? 'Unknown Item',
          quantity: item['quantite'] ?? 1,
          price: (item['prix'] ?? 0).toDouble(),
        ));
      }
    }
    
    return Order(
      id: id,
      tableId: tableId,
      status: status,
      userId: data['idC'] ?? '',
      customerCount: data['nbPersonnes'] ?? 1,
      createdAt: data['dateCmd'] != null 
        ? DateTime.tryParse(data['dateCmd']) ?? DateTime.now() 
        : DateTime.now(),
      items: items,
    );
  }

  // Helper method to map Firebase order status to app order status
  String _mapOrderStatus(String firebaseStatus) {
    switch (firebaseStatus.toLowerCase()) {
      case 'en attente':
        return 'pending';
      case 'en préparation':
        return 'preparing';
      case 'prête':
        return 'ready';
      case 'servie':
        return 'served';
      case 'annulée':
        return 'cancelled';
      default:
        return 'pending';
    }
  }
}