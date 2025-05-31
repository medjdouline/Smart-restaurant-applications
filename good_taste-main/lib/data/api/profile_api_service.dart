// profile_api_service.dart
import 'package:good_taste/data/api/api_client.dart';

class ProfileApiService {
  final ApiClient _apiClient;

  ProfileApiService({
    required ApiClient apiClient,
  }) : _apiClient = apiClient;

  Future<ApiResponse> getProfile() async {
    return await _apiClient.get('client-mobile/profile/');
  }

  Future<ApiResponse> updateProfile(Map<String, dynamic> data) async {
    return await _apiClient.put(
      'client-mobile/profile/update/',
      data,
    );
  }

  Future<ApiResponse> getAllergies() async {
    return await _apiClient.get(
      'client-mobile/allergies/',
      requiresAuth: true,
    );
  }

  Future<ApiResponse> updateAllergies(List<String> allergies) async {
    return await _apiClient.put(
      'client-mobile/allergies/update/',
      {'allergies': allergies},
      requiresAuth: true,
    );
  }

  // NEW: Get user's dietary restrictions from API
  Future<ApiResponse> getRestrictions() async {
    return await _apiClient.get(
      'client-mobile/restrictions/',
      requiresAuth: true,
    );
  }

  // NEW: Update user's dietary restrictions via API
  Future<ApiResponse> updateRestrictions(List<String> restrictions) async {
    return await _apiClient.put(
      'client-mobile/restrictions/update/',
      {'restrictions': restrictions},
      requiresAuth: true,
    );
  }

  // NEW: Get user's fidelity points from API
  Future<ApiResponse> getFidelityPoints() async {
    return await _apiClient.get(
      'client-mobile/fidelity/points/',
      requiresAuth: true,
    );
  }
}