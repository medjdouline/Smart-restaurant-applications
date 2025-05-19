import 'package:http/http.dart' as http;
import 'dart:convert';

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

  ApiClient({
    required this.baseUrl,
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  Future<ApiResponse> post(
    String endpoint,
    Map<String, dynamic> body, {
    Map<String, String>? headers,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final defaultHeaders = {
        'Content-Type': 'application/json',
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

  void dispose() {
    _httpClient.close();
  }
}