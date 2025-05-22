// lib/data/api/order_api_service.dart
import 'package:good_taste/data/api/api_client.dart';

class OrderApiService {
  final ApiClient _apiClient;

  OrderApiService({
    required ApiClient apiClient,
  }) : _apiClient = apiClient;

  Future<ApiResponse> getOrdersHistory() async {
    return await _apiClient.get('client-mobile/orders/');
  }

  Future<ApiResponse> deleteOrderFromHistory(String orderId) async {
    return await _apiClient.delete('client-mobile/orders/$orderId/delete/');
  }
}