// lib/data/api/auth_api_service.dart
import 'package:good_taste/data/api/api_client.dart';

class AuthApiService {
  final ApiClient _apiClient;

  AuthApiService({
    required ApiClient apiClient,
  }) : _apiClient = apiClient;

  /// Performs step 1 of the signup process
  /// 
  /// Takes email, password, password confirmation, username, and phone number
  /// Returns the Firebase UID on success
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

  /// Performs step 2 of the signup process - Personal Information
  ///
  /// Takes uid, full name, date of birth, and gender
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

  /// Performs step 3 of the signup process - Allergies
  ///
  /// Takes uid and list of allergies
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

  /// Performs step 4 of the signup process - Dietary Regimes
  ///
  /// Takes uid and list of dietary regimes
Future<ApiResponse> signUpStep4({
  required String uid,
  required List<String> restrictions,
}) async {
  return await _apiClient.post(
    'auth/client/signup/step4/',
    {
      'uid': uid,
      'restrictions': restrictions, // Nom exact attendu par le backend
    },
  );
}

  /// Performs step 5 of the signup process - Food Preferences
  ///
  /// Takes uid and list of food preferences
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

  /// Performs login with email and password
Future<ApiResponse> login({
  required String identifier,
  required String password,
}) async {
  return await _apiClient.post(
    'auth/client/login/',
    {
      'identifier': identifier,
      'password': password,
    },
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