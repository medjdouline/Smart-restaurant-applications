// lib/data/repositories/order_repository.dart
import 'dart:async';
import '../models/order.dart';
import '../models/assistance_request.dart';

class OrderRepository {
  // Pour la démo, nous utiliserons des données simulées
  Future<List<Order>> getNewOrders() async {
    // Simuler un délai réseau
    await Future.delayed(const Duration(milliseconds: 100));
    
    // Données simulées pour les nouvelles commandes
    return [
      Order(
        id: 'order8',
        tableId: 'T07',
        
        customerCount: 4,
        status: 'new',
        userId: 'Lisa R.',
        createdAt: DateTime.now().subtract(const Duration(minutes: 3)),
        items: [
          OrderItem(id: 'item11', name: 'Café', quantity: 4, price: 2.5, productId: ''),
        ],
      ),
      Order(
        id: 'order3',
        tableId: 'T03',
        
        customerCount: 5,
        status: 'new',
        userId: 'Emma S.',
        createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
        items: [
          OrderItem(id: 'item4', productId: 'prod4', name: 'Pizza', quantity: 2, price: 15.0),
          OrderItem(id: 'item5', productId: 'prod5', name: 'Salade', quantity: 1, price: 8.0),
        ],
      ),
    ];
  }

  Future<List<Order>> getReadyOrders() async {
    // Simuler un délai réseau
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Données simulées pour les commandes prêtes
    return [
      Order(
        id: 'order1',
        tableId: 'T01',
        
        customerCount: 2,
        status: 'ready',
        userId: 'John D.',
        createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
        items: [
          OrderItem(id: 'item1', productId: 'prod1', name: 'Burger', quantity: 2, price: 12.5),
          OrderItem(id: 'item2', productId: 'prod2', name: 'Frites', quantity: 1, price: 4.0),
        ],
      ),
      Order(
        id: 'order4',
        tableId: 'T03',
        
        customerCount: 1,
        status: 'ready',
        userId: 'Emma S.',
        createdAt: DateTime.now().subtract(const Duration(minutes: 20)),
        items: [
          OrderItem(id: 'item6', productId: 'prod6', name: 'Dessert', quantity: 5, price: 6.0),
        ],
      ),
      Order(
        id: 'order7',
        tableId: 'T07',
        
        customerCount: 1,
        status: 'ready',
        userId: 'Lisa R.',
        createdAt: DateTime.now().subtract(const Duration(minutes: 25)),
        items: [
          OrderItem(id: 'item10', name: 'Pâtes', quantity: 4, price: 14.0, productId: ''),
        ],
      ),
    ];
  }



  Future<void> serveOrder(String orderId) async {
    // Simuler un délai réseau
    await Future.delayed(const Duration(milliseconds: 300));
    return;
  }

  Future<void> completeOrder(String orderId) async {
    // Simuler un délai réseau
    await Future.delayed(const Duration(milliseconds: 300));
    return;
  }

  Future<List<AssistanceRequest>> getAssistanceRequests() async {
    // Simuler un délai réseau
    await Future.delayed(const Duration(milliseconds: 100));
    
    // Données simulées pour les demandes d'assistance
    return [
      AssistanceRequest(
        id: 'assist1',
        tableId: 'T01',
       
        userId: 'Mike T.',
        createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
        status: 'pending',
      ),
      AssistanceRequest(
        id: 'assist2',
        tableId: 'T10',
        
        userId: 'Emma S.',
        createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
        status: 'pending',
      ),
      AssistanceRequest(
        id: 'assist3',
        tableId: 'T03',
        
        userId: 'John D.',
        createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
        status: 'pending',
      ),
    ];
  }

  Future<void> completeAssistanceRequest(String requestId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return;
  }

  Future<void> cancelOrder(String orderId) async {
    // Simuler un délai réseau
    await Future.delayed(const Duration(milliseconds: 300));
    return;
  }

  Future<List<Order>> getServedOrders() async {
    // Simuler un délai réseau
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Données simulées pour les commandes servies
    return [
      Order(
        id: 'order5',
        tableId: 'T03',
        
        customerCount: 5,
        status: 'served',
        userId: 'Emma S.',
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        items: [
          OrderItem(id: 'item7', name: 'Apéritif', quantity: 5, price: 5.0, productId: ''),
        ],
      ),
    ];
  }

  Future<List<Order>> getCancelledOrders() async {
    // Simuler un délai réseau
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Pour la démo, retourner une liste vide ou quelques éléments
    return [
      Order(
        id: 'order9',
        tableId: 'T08',
        
        customerCount: 2,
        status: 'cancelled',
        userId: 'Kim J.',
        createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
        items: [
          OrderItem(id: 'item12', name: 'Sushi', quantity: 1, price: 18.0, productId: ''),
        ],
      ),
    ];
  }
  
  Future<List<Order>> getPreparingOrders() async {
    // Simuler un délai réseau
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Données simulées pour les commandes en préparation
    return [
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
      Order(
        id: 'order6',
        tableId: 'T05',
        
        customerCount: 6,
        status: 'preparing',
        userId: 'Mike T.',
        createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
        items: [
          OrderItem(id: 'item8', name: 'Steak', quantity: 6, price: 22.0, productId: ''),
          OrderItem(id: 'item9', name: 'Vin', quantity: 2, price: 28.0, productId: ''),
        ],
      ),
    ];
  }

  
}