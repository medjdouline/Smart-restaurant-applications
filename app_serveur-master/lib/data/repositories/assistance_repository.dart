// lib/data/repositories/assistance_repository.dart
import 'package:logger/logger.dart';
import '../models/assistance_request.dart';
import '../../core/api/api_service.dart';

class AssistanceRepository {
  final _logger = Logger();
  
  // Get all assistance requests
  Future<List<AssistanceRequest>> getAssistanceRequests() async {
    try {
      final response = await ApiService.client.get('/assistance/');
      _logger.i('Assistance response: $response');
      
      if (response is List) {
        return response
            .map((json) => AssistanceRequest.fromJson(json as Map<String, dynamic>))
            .toList();
      } else if (response is Map) {
        // Check if the response is a map with a data field
        if (response.containsKey('data') && response['data'] is List) {
          return (response['data'] as List)
              .map((json) => AssistanceRequest.fromJson(json as Map<String, dynamic>))
              .toList();
        }
      }
      
      _logger.e('Unexpected response format for assistance requests: $response');
      return [];
    } catch (e) {
      _logger.e('Error fetching assistance requests: $e');
      throw Exception('Failed to load assistance requests: $e');
    }
  }
  
  // Mark an assistance request as completed
  Future<void> completeAssistanceRequest(String requestId) async {
    try {
      final response = await ApiService.client.put('/assistance/$requestId/complete/');
      _logger.i('Assistance request $requestId marked as completed: $response');
    } catch (e) {
      _logger.e('Error completing assistance request: $e');
      throw Exception('Failed to complete assistance request: $e');
    }
  }
}