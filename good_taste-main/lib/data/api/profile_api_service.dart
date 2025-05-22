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
    return await _apiClient.get('client-mobile/allergies/');
  }

  Future<ApiResponse> updateAllergies(List<String> allergies) async {
    return await _apiClient.put(
      'client-mobile/allergies/update/',
      {'allergies': allergies},
    );
  }
}
