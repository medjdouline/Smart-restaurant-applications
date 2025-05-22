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
      requiresAuth: false,
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
      requiresAuth: false,
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
    requiresAuth: false,
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
    requiresAuth: false,
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
    requiresAuth: false,
  );
}

// Add this method to the AuthApiService class
Future<ApiResponse> clientLogin({
  required String identifier,
  required String password,
}) async {
  return await _apiClient.post(
    'auth/client/login/',
    {
      'identifier': identifier,
      'password': password,
    },
    requiresAuth: false,
  );
}
}