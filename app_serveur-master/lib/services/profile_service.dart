// lib/services/profile_service.dart
import 'package:logger/logger.dart';
import '../core/api/api_client.dart';
import '../core/services/firebase_auth_service.dart';

class ProfileService {
  final ApiClient _apiClient;
  final FirebaseAuthService _firebaseAuthService;
  final Logger _logger = Logger();
  
  ProfileService({
    required ApiClient apiClient,
    required FirebaseAuthService firebaseAuthService,
  })  : _apiClient = apiClient,
        _firebaseAuthService = firebaseAuthService;
  
  Future<bool> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final token = await _firebaseAuthService.getAuthToken();
      
      if (token == null) {
        throw Exception('No authentication token found');
      }
      
      _logger.d('Attempting to update password');
      
      // Make the API call to update password
      final response = await _apiClient.put(
        '/server/profile/update-password/',
        data: {
          'current_password': currentPassword,
          'new_password': newPassword,
        },
        token: token,
      );
      
      _logger.d('Password update response: $response');
      
      // Also update locally in Firebase Auth service
      await _firebaseAuthService.updatePassword(newPassword);
      
      return true;
    } catch (e) {
      _logger.e('Failed to update password: $e');
      rethrow;
    }
  }
}