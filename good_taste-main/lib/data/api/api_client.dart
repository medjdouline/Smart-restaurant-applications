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
  String? _authToken;
  final String baseUrl;
  final http.Client _httpClient;

  void setAuthToken(String token) {
    _authToken = token.isEmpty ? null : token;
  }

  // AJOUT: Méthode pour nettoyer le token
  void clearAuthToken() {
    _authToken = null;
  }

  Map<String, String> get _authHeaders {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    
    if (_authToken != null && _authToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    
    return headers;
  }

  // AJOUT: Headers sans authentification pour les endpoints publics
  Map<String, String> get _publicHeaders {
    return <String, String>{
      'Content-Type': 'application/json',
    };
  }

  ApiClient({
    required this.baseUrl,
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  Future<ApiResponse> post(
    String endpoint,
    Map<String, dynamic> body, {
    Map<String, String>? headers,
    bool requiresAuth = true, // AJOUT: Paramètre pour indiquer si l'auth est requise
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      
      // Choisir les headers appropriés selon le besoin d'authentification
      final requestHeaders = requiresAuth ? _authHeaders : _publicHeaders;
      
      final response = await _httpClient.post(
        uri,
        headers: {...requestHeaders, ...?headers},
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
  bool requiresAuth = true, // AJOUT: Paramètre pour indiquer si l'auth est requise
}) async {
  try {
    final uri = Uri.parse('$baseUrl$endpoint');

    // Choisir les headers appropriés selon le besoin d'authentification
    final requestHeaders = requiresAuth ? _authHeaders : _publicHeaders;

    final response = await _httpClient.get(
      uri,
      headers: {...requestHeaders, ...?headers},
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

  Future<ApiResponse> delete(
  String endpoint, {
  Map<String, String>? headers,
  bool requiresAuth = true,
}) async {
  try {
    final uri = Uri.parse('$baseUrl$endpoint');

    final requestHeaders = requiresAuth ? _authHeaders : _publicHeaders;

    final response = await _httpClient.delete(
      uri,
      headers: {...requestHeaders, ...?headers},
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
  bool requiresAuth = true,
}) async {
  try {
    final uri = Uri.parse('$baseUrl$endpoint');
    
    final requestHeaders = requiresAuth ? _authHeaders : _publicHeaders;
    
    final response = await _httpClient.put(
      uri,
      headers: {...requestHeaders, ...?headers},
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