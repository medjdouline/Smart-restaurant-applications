// lib/config/api_config.dart
class ApiConfig {
  // URL de base pour l'API - À configurer selon votre environnement
  // Make sure the URL is correct and has a trailing slash
  static const String baseUrl = 'http://127.0.0.1:8000/api';
  
  // Timeouts
  static const int connectionTimeout = 30000; // 30 secondes
  static const int receiveTimeout = 30000; // 30 secondes
  
  // Nombre de tentatives de reconnexion
  static const int maxRetries = 3;
  
  // Development mode flag - will use mock data when true
  static const bool useMockData = true; // Set to false in production
}