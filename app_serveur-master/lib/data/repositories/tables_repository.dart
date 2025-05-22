// lib/data/repositories/tables_repository.dart
import 'dart:math';
import '../models/table.dart';
import '../models/order.dart';

class TablesRepository {
  final List<RestaurantTable> _tables = [
    RestaurantTable(
      id: 'T01',
      
      capacity: 4,
      isOccupied: true,
      orderCount: 2,
      customerCount: 3,
    ),
    RestaurantTable(
      id: 'T02',
      
      capacity: 4,
      isOccupied: false,
      orderCount: 0,
      customerCount: 0,
    ),
    RestaurantTable(
      id: 'T07',
      
      capacity: 6,
      isOccupied: true,
      orderCount: 3,
      customerCount: 5,
    ),
    RestaurantTable(
      id: 'T10',
      
      capacity: 8,
      isOccupied: false,
      orderCount: 0,
      customerCount: 0,
    ),
  RestaurantTable(
  id: 'T03',
  capacity: 2,
  isOccupied: false,
  isReserved: true,
  orderCount: 0,
  customerCount: 0,
  reservationStart: DateTime.now().add(const Duration(minutes: 30)),
  reservationEnd: DateTime.now().add(const Duration(hours: 2)),
  clientName: 'Sophie Martin',
  reservationPersonCount: 2,
  reservationStatus: 'En attente',
),
RestaurantTable(
  id: 'T04',
  capacity: 4,
  isOccupied: false,
  isReserved: true,
  orderCount: 0,
  customerCount: 0,
  reservationStart: DateTime.now().subtract(const Duration(minutes: 15)),
  reservationEnd: DateTime.now().add(const Duration(hours: 1, minutes: 45)),
  clientName: 'Thomas Dubois',
  reservationPersonCount: 4,
  reservationStatus: 'En attente',
),
    
  ];

  // Mock orders by table - harmonisé avec les commandes dans OrderRepository
  final Map<String, List<Order>> _tableOrders = {
    'T01': [
      Order(
        id: 'order1',
        tableId: 'T01',
        
        customerCount: 3,
        status: 'ready',
        userId: 'John D.',
        createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
        items: [
          OrderItem(id: 'item1', name: 'Burger', quantity: 2, price: 12.5, productId: ''),
          OrderItem(id: 'item2', name: 'Frites', quantity: 1, price: 4.0, productId: ''),
        ],
      ),
      Order(
        id: 'order2',
        tableId: 'T01',
       
        customerCount: 3,
        status: 'preparing',
        userId: 'John D.',
        createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
        items: [
          OrderItem(id: 'item3', name: 'Boisson', quantity: 3, price: 3.5, productId: ''),
        ],
      ),
    ],
    'T02': [
      Order(
        id: 'order3',
        tableId: 'T02',
        
        customerCount: 5,
        status: 'new',
        userId: 'Emma S.',
        createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
        items: [
          OrderItem(id: 'item4', name: 'Pizza', quantity: 2, price: 15.0, productId: ''),
          OrderItem(id: 'item5', name: 'Salade', quantity: 1, price: 8.0, productId: ''),
        ],
      ),
      Order(
        id: 'order4',
        tableId: 'T02',
        
        customerCount: 5,
        status: 'ready',
        userId: 'Emma S.',
        createdAt: DateTime.now().subtract(const Duration(minutes: 20)),
        items: [
          OrderItem(id: 'item6', name: 'Dessert', quantity: 5, price: 6.0, productId: ''),
        ],
      ),
      Order(
        id: 'order5',
        tableId: 'T02',
        
        customerCount: 5,
        status: 'served',
        userId: 'Emma S.',
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        items: [
          OrderItem(id: 'item7', name: 'Apéritif', quantity: 5, price: 5.0, productId: ''),
        ],
      ),
    ],
    'T07': [
      Order(
        id: 'order6',
        tableId: 'T07',
        
        customerCount: 6,
        status: 'preparing',
        userId: 'Mike T.',
        createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
        items: [
          OrderItem(id: 'item8', name: 'Steak', quantity: 6, price: 22.0, productId: ''),
          OrderItem(id: 'item9', name: 'Vin', quantity: 2, price: 28.0, productId: ''),
        ],
      ),
    ],
    'T10': [
      Order(
        id: 'order7',
        tableId: 'T10',
        
        customerCount: 4,
        status: 'ready',
        userId: 'Lisa R.',
        createdAt: DateTime.now().subtract(const Duration(minutes: 25)),
        items: [
          OrderItem(id: 'item10', name: 'Pâtes', quantity: 4, price: 14.0, productId: ''),
        ],
      ),
      Order(
        id: 'order8',
        tableId: 'T10',
        
        customerCount: 4,
        status: 'new',
        userId: 'Lisa R.',
        createdAt: DateTime.now().subtract(const Duration(minutes: 3)),
        items: [
          OrderItem(id: 'item11', name: 'Café', quantity: 4, price: 2.5, productId: ''),
        ],
      ),
    ],
    
  };

  // Get all tables
  Future<List<RestaurantTable>> getAllTables() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));
    return _tables;
  }

  // Get available tables (not occupied)
  Future<List<RestaurantTable>> getAvailableTables() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    return _tables.where((table) => !table.isOccupied).toList();
  }

  // Get occupied tables
  Future<List<RestaurantTable>> getOccupiedTables() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    return _tables.where((table) => table.isOccupied).toList();
  }

  // Get orders for a specific table
  Future<List<Order>> getTableOrders(String tableId) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    return _tableOrders[tableId] ?? [];
  }

  // Update table status
  Future<RestaurantTable> updateTableStatus(String tableId, bool isOccupied, {int? customerCount}) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 600));
    
    final index = _tables.indexWhere((table) => table.id == tableId);
    if (index == -1) {
      throw Exception('Table not found');
    }
    
    // Create a new table with updated status
    final updatedTable = RestaurantTable(
      id: _tables[index].id,
      
      capacity: _tables[index].capacity,
      isOccupied: isOccupied,
      orderCount: isOccupied ? _tables[index].orderCount : 0,
      customerCount: customerCount ?? (isOccupied ? max(1, Random().nextInt(_tables[index].capacity + 1)) : 0),
    );
    
    // Update the list
    _tables[index] = updatedTable;
    
    return updatedTable;
  }
  
  // Add new order to a table
  Future<Order> addOrderToTable(String tableId, Order order) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 700));
    
    final tableIndex = _tables.indexWhere((table) => table.id == tableId);
    if (tableIndex == -1) {
      throw Exception('Table not found');
    }
    
    // Add the order to the table's orders
    if (_tableOrders.containsKey(tableId)) {
      _tableOrders[tableId]!.add(order);
    } else {
      _tableOrders[tableId] = [order];
    }
    
    // Update the table's order count
    final updatedTable = RestaurantTable(
      id: _tables[tableIndex].id,
      
      capacity: _tables[tableIndex].capacity,
      isOccupied: true,
      orderCount: _tables[tableIndex].orderCount + 1,
      customerCount: _tables[tableIndex].customerCount,
    );
    
    _tables[tableIndex] = updatedTable;
    
    return order;
  }

  // Start a reservation (convert from reserved to occupied)
Future<RestaurantTable> startReservation(String tableId) async {
  // Simulate network delay
  await Future.delayed(const Duration(milliseconds: 600));
  
  final index = _tables.indexWhere((table) => table.id == tableId);
  if (index == -1) {
    throw Exception('Table not found');
  }
  
  // Verify that the table is reserved
  if (!_tables[index].isReserved) {
    throw Exception('Table is not reserved');
  }
  
  // Create a new table with updated status
  final updatedTable = RestaurantTable(
    id: _tables[index].id,
    capacity: _tables[index].capacity,
    isOccupied: true,
    isReserved: true,
    orderCount: 0,
    customerCount: _tables[index].reservationPersonCount ?? 1,
    reservationStart: _tables[index].reservationStart,
    reservationEnd: _tables[index].reservationEnd,
    clientName: _tables[index].clientName,
    reservationPersonCount: _tables[index].reservationPersonCount,
    reservationStatus: 'Confirmée', // Mettre à jour le statut à "Confirmée"
  );
  
  // Update the list
  _tables[index] = updatedTable;
  
  return updatedTable;
}
}