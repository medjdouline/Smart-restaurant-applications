// notification_api_service.dart
import 'package:good_taste/data/api/api_client.dart';

class NotificationApiService {
  final ApiClient _apiClient;

  NotificationApiService({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<ApiResponse> getNotifications() async {
    return await _apiClient.get(
      'client-mobile/notifications/',
      requiresAuth: true,
    );
  }

  Future<ApiResponse> markAsRead(String notificationId) async {
    return await _apiClient.put(
      'client-mobile/notifications/$notificationId/mark_as_read/',
      {},
      requiresAuth: true,
    );
  }
}