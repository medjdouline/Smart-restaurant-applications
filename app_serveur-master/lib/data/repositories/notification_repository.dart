// lib/data/repositories/notification_repository.dart
import 'dart:async';
import '../models/notification.dart';
import 'package:app_serveur/core/api/api_client.dart';
import 'package:logger/logger.dart';

class NotificationRepository {
  final ApiClient _apiClient;
  final Logger _logger = Logger();
  
  NotificationRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  // Récupère les notifications depuis l'API
  Future<List<UserNotification>> getNotifications() async {
    try {
      _logger.d('Fetching notifications for server');
      
      // Appel à l'API REST avec le chemin correct
      final response = await _apiClient.getWithRetry('/api/server/notifications/', maxRetries: 2);
      
      if (response == null) {
        _logger.w('Null response from notifications API');
        return [];
      }
      
      if (response is List) {
        _logger.d('Successfully parsed notifications list with ${response.length} items');
        return response
            .map((notifJson) => UserNotification.fromJson(notifJson))
            .toList();
      } else if (response is Map) {
        // Certaines API renvoient une structure avec un champ contenant la liste
        if (response.containsKey('results') && response['results'] is List) {
          _logger.d('Successfully parsed notifications from results field');
          final List resultsList = response['results'];
          return resultsList
              .map((notifJson) => UserNotification.fromJson(notifJson))
              .toList();
        }
        _logger.w('Unexpected response format: $response');
        return [];
      } else {
        _logger.w('Unexpected response format: $response');
        return [];
      }
    } catch (e) {
      _logger.e('Error fetching notifications: $e');
      throw Exception('Impossible de récupérer les notifications: $e');
    }
  }

  // Marque une notification comme lue
  Future<UserNotification> markAsRead(String notificationId) async {
    try {
      _logger.d('Marking notification as read: $notificationId');
      
      // Appel à l'API pour récupérer les détails, ce qui la marque automatiquement comme lue
      final response = await _apiClient.get('/server/notifications/$notificationId/');
      
      if (response == null) {
        throw Exception('Réponse nulle de l\'API');
      }
      
      _logger.d('Mark as read response: $response');
      return UserNotification.fromJson(response);
    } catch (e) {
      _logger.e('Error marking notification as read: $e');
      throw Exception('Impossible de marquer la notification comme lue: $e');
    }
  }

  // Marque toutes les notifications comme lues
  Future<void> markAllAsRead() async {
    try {
      _logger.d('Marking all notifications as read');
      
      final response = await _apiClient.post('/server/notifications/mark-all-read/');
      
      _logger.d('All notifications marked as read: $response');
      return;
    } catch (e) {
      _logger.e('Error marking all notifications as read: $e');
      throw Exception('Impossible de marquer toutes les notifications comme lues: $e');
    }
  }
}