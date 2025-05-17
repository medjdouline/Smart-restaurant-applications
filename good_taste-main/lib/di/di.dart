// lib/di/di.dart
import 'package:http/http.dart' as http;
import 'package:good_taste/data/api/api_client.dart';
import 'package:good_taste/data/api/auth_api_service.dart';
import 'package:good_taste/data/repositories/auth_repository.dart';
import 'package:good_taste/data/repositories/allergies_repository.dart';
import 'package:good_taste/data/repositories/regime_repository.dart';

/// Class to handle dependency injection for the app
class DependencyInjection {
  // Private constructor to prevent instantiation
  DependencyInjection._();

  // Singleton instance
  static final DependencyInjection _instance = DependencyInjection._();
  
  // Factory constructor to return the singleton instance
  factory DependencyInjection() => _instance;

  // Lazy initialized dependencies
  static ApiClient? _apiClient;
  static AuthApiService? _authApiService;
  static AuthRepository? _authRepository;
  static AllergiesRepository? _allergiesRepository;

  // API base URL - update this to match your backend URL
  static const String apiBaseUrl = 'http://127.0.0.1:8000/api/';

  // Get the API client
  static ApiClient getApiClient() {
    _apiClient ??= ApiClient(
      baseUrl: apiBaseUrl,
      httpClient: http.Client(),
    );
    return _apiClient!;
  }

  // Get the Auth API service
  static AuthApiService getAuthApiService() {
    _authApiService ??= AuthApiService(
      apiClient: getApiClient(),
    );
    return _authApiService!;
  }

  // Get the Allergies repository
  static AllergiesRepository getAllergiesRepository() {
    _allergiesRepository ??= AllergiesRepository();
    return _allergiesRepository!;
  }

  // Get the Regime repository
  static RegimeRepository? _regimeRepository;
  static RegimeRepository getRegimeRepository() {
    _regimeRepository ??= RegimeRepository();
    return _regimeRepository!;
  }

  // Get the Auth repository
  static AuthRepository getAuthRepository() {
    _authRepository ??= AuthRepository(
      authApiService: getAuthApiService(),
      allergiesRepository: getAllergiesRepository(), // Added this required parameter
    );
    return _authRepository!;
  }

  // Close resources when app is terminated
  static void dispose() {
    _apiClient?.dispose();
    _authRepository = null;
    _allergiesRepository = null;
    // Add other disposable resources here
  }
}