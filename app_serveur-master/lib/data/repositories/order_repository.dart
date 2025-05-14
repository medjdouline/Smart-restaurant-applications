// lib/data/repositories/order_repository.dart
import 'dart:async';
import '../models/order.dart';
import '../models/assistance_request.dart';

// Make the class abstract
abstract class OrderRepository {
  // Pour la démo, nous utiliserons des données simulées
  Future<List<Order>> getNewOrders();
  Future<List<Order>> getReadyOrders();
  Future<List<Order>> getServedOrders();
  Future<List<Order>> getCancelledOrders();
  Future<List<Order>> getPreparingOrders();
  Future<List<Order>> getAllOrders(); // Add this method to match implementation
  Future<void> serveOrder(String orderId);
  Future<void> completeOrder(String orderId);
  Future<void> cancelOrder(String orderId);
  Future<void> requestCancelOrder(String orderId, String currentStatus);
  Future<void> directCancelOrder(String orderId);
  Future<List<AssistanceRequest>> getAssistanceRequests();
  Future<void> completeAssistanceRequest(String requestId);
}