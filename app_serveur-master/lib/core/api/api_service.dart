// lib/core/api/api_service.dart
import 'package:flutter/foundation.dart';
import 'api_client.dart';

class ApiService {
  static late ApiClient _apiClient;

  // Initialize the API client with the base URL
  static void initialize({String? baseUrl}) {
    final url = baseUrl ?? _getDefaultBaseUrl();
    _apiClient = ApiClient(baseUrl: url);
  }

  // Get the API client instance
  static ApiClient get client => _apiClient;

  // Get default base URL based on build mode
  static String _getDefaultBaseUrl() {
    if (kReleaseMode) {
      // Production URL
      return 'https://your-production-api.com/api';
    } else if (kProfileMode) {
      // Profile mode URL
      return 'https://your-staging-api.com/api';
    } else {
      // Debug mode URL - Updated to match the Django server
      return 'http://localhost:8000/api/server';
      // For Android emulator:
      // return 'http://10.0.2.2:8000/api/server'; 
    }
  }
}