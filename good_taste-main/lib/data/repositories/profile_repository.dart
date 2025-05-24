// profile_repository.dart
import 'package:good_taste/data/api/profile_api_service.dart';
import 'package:good_taste/data/api/api_client.dart';
import 'package:logging/logging.dart';

class ProfileRepository {
  final Logger _logger = Logger('ProfileRepository');
  final ProfileApiService _profileApiService;

  ProfileRepository({
    required ProfileApiService profileApiService,
  }) : _profileApiService = profileApiService;

  Future<ApiResponse> getProfile() async {
    try {
      final response = await _profileApiService.getProfile();
      _logger.info('Profile retrieved: ${response.success}');
      return response;
    } catch (e) {
      _logger.severe('Error getting profile: $e');
      rethrow;
    }
  }

  Future<ApiResponse> updateProfile(Map<String, dynamic> data) async {
    try {
      final response = await _profileApiService.updateProfile(data);
      _logger.info('Profile updated: ${response.success}');
      return response;
    } catch (e) {
      _logger.severe('Error updating profile: $e');
      rethrow;
    }
  }

  Future<ApiResponse> getAllergies() async {
    try {
      final response = await _profileApiService.getAllergies();
      _logger.info('Allergies retrieved: ${response.success}');
      return response;
    } catch (e) {
      _logger.severe('Error getting allergies: $e');
      rethrow;
    }
  }

  Future<ApiResponse> updateAllergies(List<String> allergies) async {
    try {
      final response = await _profileApiService.updateAllergies(allergies);
      _logger.info('Allergies updated via API: ${response.success}');
      return response;
    } catch (e) {
      _logger.severe('Error updating allergies via API: $e');
      rethrow;
    }
  }

  // NEW: Get user's dietary restrictions from API
Future<ApiResponse> getRestrictions() async {
  try {
    final response = await _profileApiService.getRestrictions();
    _logger.info('Restrictions retrieved: ${response.success}');
    return response;
  } catch (e) {
    _logger.severe('Error getting restrictions: $e');
    rethrow;
  }
}

Future<ApiResponse> updateRestrictions(List<String> restrictions) async {
  try {
    final response = await _profileApiService.updateRestrictions(restrictions);
    _logger.info('Restrictions updated via API: ${response.success}');
    return response;
  } catch (e) {
    _logger.severe('Error updating restrictions via API: $e');
    rethrow;
  }
}
}