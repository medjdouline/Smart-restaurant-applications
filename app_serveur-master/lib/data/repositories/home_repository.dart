// lib/data/repositories/home_repository.dart
import '../models/order.dart';
import '../models/assistance_request.dart';
import 'order_repository.dart';
import 'assistance_repository.dart';

class HomeRepository {
  final OrderRepository orderRepository;
  final AssistanceRepository assistanceRepository;
  
  HomeRepository({
    required this.orderRepository,
    required this.assistanceRepository,
  });
  
  Future<List<Order>> getPreparingOrders() async {
    final newOrders = await orderRepository.getNewOrders();
    return newOrders.where((order) => order.status == 'preparing').toList();
  }
  
  Future<List<Order>> getReadyOrders() async {
    return orderRepository.getReadyOrders();
  }
  
  // Now using the dedicated AssistanceRepository
  Future<List<AssistanceRequest>> getAssistanceRequests() async {
    return assistanceRepository.getAssistanceRequests();
  }
  
  // Now using the dedicated AssistanceRepository
  Future<void> completeAssistanceRequest(String requestId) async {
    return assistanceRepository.completeAssistanceRequest(requestId);
  }
}