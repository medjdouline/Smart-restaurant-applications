// lib/data/api/api_client.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiResponse {
  final bool success;
  final dynamic data;
  final String? error;
  ApiResponse({
    required this.success,
    this.data,
    this.error,
  });
}

class ApiClient {
  final String baseUrl;
  final http.Client _httpClient;
  String? _authToken;

  ApiClient({
    required this.baseUrl,
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  // Base URL for the API - replace with your actual URL
  static const String defaultBaseUrl = 'http://127.0.0.1:8000/api/';

  void setAuthToken(String token) {
    _authToken = token;
  }

  Future<ApiResponse> post(
    String endpoint,
    Map<String, dynamic> body, {
    Map<String, String>? headers,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final defaultHeaders = {
        'Content-Type': 'application/json',
        if (_authToken != null) 'Authorization': 'Bearer $_authToken',
      };

      final response = await _httpClient.post(
        uri,
        headers: {...defaultHeaders, ...?headers},
        body: jsonEncode(body),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResponse(
          success: true,
          data: responseData,
        );
      } else {
        String errorMessage = responseData['error'] ?? 'Unknown error occurred';
        return ApiResponse(
          success: false,
          error: errorMessage,
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        error: e.toString(),
      );
    }
  }

  Future<ApiResponse> get(
    String endpoint, {
    Map<String, String>? headers,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final defaultHeaders = {
        'Content-Type': 'application/json',
        if (_authToken != null) 'Authorization': 'Bearer $_authToken',
      };

      final response = await _httpClient.get(
        uri,
        headers: {...defaultHeaders, ...?headers},
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResponse(
          success: true,
          data: responseData,
        );
      } else {
        String errorMessage = responseData['error'] ?? 'Unknown error occurred';
        return ApiResponse(
          success: false,
          error: errorMessage,
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        error: e.toString(),
      );
    }
  }

  Future<ApiResponse> put(
    String endpoint,
    Map<String, dynamic> body, {
    Map<String, String>? headers,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final defaultHeaders = {
        'Content-Type': 'application/json',
        if (_authToken != null) 'Authorization': 'Bearer $_authToken',
      };

      final response = await _httpClient.put(
        uri,
        headers: {...defaultHeaders, ...?headers},
        body: jsonEncode(body),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResponse(
          success: true,
          data: responseData,
        );
      } else {
        String errorMessage = responseData['error'] ?? 'Unknown error occurred';
        return ApiResponse(
          success: false,
          error: errorMessage,
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        error: e.toString(),
      );
    }
  }

  // Add more methods for other HTTP verbs as needed

  void dispose() {
    _httpClient.close();
  }
}