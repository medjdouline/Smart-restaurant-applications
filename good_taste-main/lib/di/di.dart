// lib/di/di.dart (updated)
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:good_taste/data/api/api_client.dart';
import 'package:good_taste/data/api/auth_api_service.dart';
import 'package:good_taste/data/repositories/auth_repository.dart';
import 'package:good_taste/data/repositories/allergies_repository.dart';
import 'package:good_taste/data/repositories/regime_repository.dart';
import 'package:good_taste/data/services/firebase_auth_service.dart';
import 'package:flutter/foundation.dart';

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
  static FirebaseAuthService? _firebaseAuthService;

  // API base URL - different URLs for emulator vs real device
static String get apiBaseUrl {
  const String deviceUrl = 'http://192.168.100.13:8000/api/';  // Replace with your actual IP
  const String emulatorUrl = 'http://10.0.2.2:8000/api/';
  const String webUrl = 'http://localhost:8000/api/';
  
  // More reliable way to determine if running on emulator
  if (Platform.isAndroid) {
    try {
      // For debugging - print the base URL being used
      debugPrint("Using API URL: $deviceUrl");
      return deviceUrl;  // Always use device URL for physical testing
    } catch (e) {
      debugPrint("Error determining platform: $e");
      return deviceUrl;
    }
  } else if (kIsWeb) {
    return webUrl;
  } else {
    return deviceUrl;
  }
}

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

  // Get the Firebase Auth Service
  static FirebaseAuthService getFirebaseAuthService() {
    _firebaseAuthService ??= FirebaseAuthService();
    return _firebaseAuthService!;
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
      allergiesRepository: getAllergiesRepository(),
      firebaseAuthService: getFirebaseAuthService(),
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