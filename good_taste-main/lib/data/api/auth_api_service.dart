// auth_api_service.dart
import 'package:good_taste/data/api/api_client.dart';

class AuthApiService {
  final ApiClient _apiClient;

  AuthApiService({
    required ApiClient apiClient,
  }) : _apiClient = apiClient;

  Future<ApiResponse> signUpStep1({
    required String email,
    required String password,
    required String passwordConfirmation,
    required String username,
    required String phoneNumber,
  }) async {
    return await _apiClient.post(
      'auth/client/signup/step1/',
      {
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
        'username': username,
        'phone_number': phoneNumber,
      },
    );
  }

  Future<ApiResponse> signUpStep2({
    required String uid,
    required DateTime dateOfBirth,
    required String gender,
  }) async {
    return await _apiClient.post(
      'auth/client/signup/step2/',
      {
        'uid': uid,
        'birthdate': dateOfBirth.toIso8601String().split('T')[0], // Format as YYYY-MM-DD
        'gender': gender,
      },
    );
  }
  Future<ApiResponse> signUpStep3({
  required String uid,
  required List<String> allergies,
}) async {
  return await _apiClient.post(
    'auth/client/signup/step3/',
    {
      'uid': uid,
      'allergies': allergies,
    },
  );
}
Future<ApiResponse> signUpStep4({
  required String uid,
  required List<String> restrictions,
}) async {
  return await _apiClient.post(
    'auth/client/signup/step4/',
    {
      'uid': uid,
      'restrictions': restrictions,
    },
  );
}
Future<ApiResponse> signUpStep5({
  required String uid,
  required List<String> preferences,
}) async {
  return await _apiClient.post(
    'auth/client/signup/step5/',
    {
      'uid': uid,
      'preferences': preferences,
    },
  );
}
}