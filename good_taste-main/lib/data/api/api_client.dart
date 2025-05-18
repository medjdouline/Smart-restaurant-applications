// lib/data/api/api_client.dart (updated)
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

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
  final Logger _logger = Logger('ApiClient');

  ApiClient({
    required this.baseUrl,
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

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

      _logger.info('POST Request to: $uri');
      _logger.info('Headers: ${jsonEncode({...defaultHeaders, ...?headers})}');
      _logger.info('Body: ${jsonEncode(body)}');

      final response = await _httpClient.post(
        uri,
        headers: {...defaultHeaders, ...?headers},
        body: jsonEncode(body),
      );

      _logger.info('Response status: ${response.statusCode}');
      _logger.info('Response body: ${response.body}');

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
      _logger.severe('Exception in POST request: $e');
      _logger.severe("Exception details in POST request:", e, StackTrace.current);
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

      _logger.info('GET Request to: $uri');
      _logger.info('Headers: ${jsonEncode({...defaultHeaders, ...?headers})}');

      final response = await _httpClient.get(
        uri,
        headers: {...defaultHeaders, ...?headers},
      );

      _logger.info('Response status: ${response.statusCode}');
      _logger.info('Response body: ${response.body}');

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
      _logger.severe('Exception in GET request: $e');
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

    _logger.info('PUT Request to: $uri');
    _logger.info('Headers: ${jsonEncode({...defaultHeaders, ...?headers})}');
    _logger.info('Body: ${jsonEncode(body)}');

    final response = await _httpClient.put(
      uri,
      headers: {...defaultHeaders, ...?headers},
      body: jsonEncode(body),
    );

    _logger.info('Response status: ${response.statusCode}');
    _logger.info('Response body: ${response.body}');

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
    _logger.severe('Exception in PUT request: $e');
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