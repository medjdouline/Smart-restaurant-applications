// profile_repository.dart
import 'package:good_taste/data/api/profile_api_service.dart';
import 'package:logging/logging.dart';
import 'package:good_taste/data/api/api_client.dart';

class ProfileRepository {
  final Logger _logger = Logger('ProfileRepository');
  final ProfileApiService _profileApiService;

  ProfileRepository({
    required ProfileApiService profileApiService,
  }) : _profileApiService = profileApiService;

  Future<ApiResponse> getProfile() async {
    try {
      return await _profileApiService.getProfile();
    } catch (e) {
      _logger.severe("Failed to get profile: $e");
      return ApiResponse(
        success: false,
        error: 'Failed to load profile',
      );
    }
  }

  Future<ApiResponse> updateProfile(Map<String, dynamic> data) async {
    try {
      // FIX: Simplifier la logique - utiliser phone_number partout
      final updateData = <String, dynamic>{};
      
      // Gérer phone_number (accepter les deux formats pour compatibilité)
      if (data.containsKey('phone_number')) {
        updateData['phone_number'] = data['phone_number'];
      } else if (data.containsKey('phoneNumber')) {
        updateData['phone_number'] = data['phoneNumber']; // Convertir en snake_case
      }
      
      // Gérer profile_image
      if (data.containsKey('profile_image')) {
        updateData['profile_image'] = data['profile_image'];
      } else if (data.containsKey('profileImage')) {
        updateData['profile_image'] = data['profileImage']; // Convertir en snake_case
      }

      if (updateData.isEmpty) {
        return ApiResponse(
          success: false,
          error: 'No valid fields to update',
        );
      }

      _logger.info("Updating profile with data: $updateData");
      return await _profileApiService.updateProfile(updateData);
    } catch (e) {
      _logger.severe("Failed to update profile: $e");
      return ApiResponse(
        success: false,
        error: 'Failed to update profile',
      );
    }
  }
 Future<ApiResponse> getAllergies() async {
    try {
      return await _profileApiService.getAllergies();
    } catch (e) {
      _logger.severe("Failed to get allergies: $e");
      return ApiResponse(
        success: false,
        error: 'Failed to load allergies',
      );
    }
  }

  Future<ApiResponse> updateAllergies(List<String> allergies) async {
    try {
      _logger.info("Updating allergies: $allergies");
      return await _profileApiService.updateAllergies(allergies);
    } catch (e) {
      _logger.severe("Failed to update allergies: $e");
      return ApiResponse(
        success: false,
        error: 'Failed to update allergies',
      );
    }
  }
}
