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
      
      if (response is List) {
        return response
            .map((json) => AssistanceRequest.fromJson(json))
            .toList();
      } else {
        _logger.e('Unexpected response format for assistance requests');
        return [];
      }
    } catch (e) {
      _logger.e('Error fetching assistance requests: $e');
      throw Exception('Failed to load assistance requests: $e');
    }
  }
  
  // Mark an assistance request as completed
  Future<void> completeAssistanceRequest(String requestId) async {
    try {
      await ApiService.client.put('/assistance/$requestId/complete/');
      _logger.i('Assistance request $requestId marked as completed');
    } catch (e) {
      _logger.e('Error completing assistance request: $e');
      throw Exception('Failed to complete assistance request: $e');
    }
  }
}