// lib/data/repositories/profile_repository.dart
import 'package:logger/logger.dart';
import '../../core/api/api_client.dart';
import '../../core/services/firebase_auth_service.dart';


class ProfileException implements Exception {
  final String message;
  
  ProfileException(this.message);
  
  @override
  String toString() => 'ProfileException: $message';
}

class ProfileRepository {
  final ApiClient _apiClient;
  final FirebaseAuthService _firebaseAuthService;
  final Logger _logger = Logger();
  
  ProfileRepository({
    required ApiClient apiClient,
    required FirebaseAuthService firebaseAuthService,
  })  : _apiClient = apiClient,
        _firebaseAuthService = firebaseAuthService;
  
  Future<Map<String, dynamic>> getProfileStats() async {
    try {
      final token = await _firebaseAuthService.getAuthToken();
      
      if (token == null) {
        throw ProfileException('No authentication token found');
      }
      
      _logger.d('Fetching profile stats with token');
      
      // This is the endpoint from your server
      final response = await _apiClient.get(
        '/server/profile/',
        token: token,
      );
      
      _logger.d('Profile stats response: $response');
      
      return response;
    } catch (e) {
      _logger.e('Failed to get profile stats: $e');
      if (e is ApiException) {
        throw ProfileException(e.message);
      }
      throw ProfileException('Failed to load profile data: $e');
    }
  }
}