// Enhanced api_client.dart with better error handling and logging
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;
  
  ApiException(this.message, {this.statusCode, this.data});
  
  @override
  String toString() {
    if (data != null) {
      return 'ApiException: $message (Status Code: $statusCode, Data: $data)';
    }
    return 'ApiException: $message (Status Code: $statusCode)';
  }
}

class NetworkException extends ApiException {
  NetworkException(String message) : super('Network error: $message');
}

class ApiClient {
  final String baseUrl;
  final http.Client _httpClient;
  final Logger _logger = Logger();
  final Duration _timeout = const Duration(seconds: 30);
  
  ApiClient({
    required this.baseUrl,
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client() {
    _logger.d('API Client initialized with base URL: $baseUrl');
  }

  String get loginUrl => '$baseUrl/auth/login/';

  // Headers with authentication token
  Future<Map<String, String>> _getHeaders({String? token}) async {
    final prefs = await SharedPreferences.getInstance();
    final authToken = token ?? prefs.getString('auth_token') ?? '';

    _logger.d('Using auth token: ${authToken.isNotEmpty ? 'Yes (present)' : 'No (empty)'}');
    
    return {
      'Content-Type': 'application/json',
      if (authToken.isNotEmpty) 'Authorization': 'Bearer $authToken',
    };
  }

  // Modified to return dynamic instead of Map<String, dynamic>
  Future<dynamic> get(
    String endpoint, {
    Map<String, String>? headers,
    String? token,
  }) async {
    final Uri uri = Uri.parse(endpoint.startsWith('http') ? endpoint : '$baseUrl$endpoint');
    _logger.d('GET Request: $uri');
    
    try {
      final Map<String, String> requestHeaders = {
        ...await _getHeaders(token: token),
        ...?headers,
      };
      
      _logger.d('Request headers: $requestHeaders');
      
      final response = await _httpClient.get(uri, headers: requestHeaders)
          .timeout(_timeout, onTimeout: () {
        throw NetworkException('Request timed out');
      });
      
      _logger.d('GET Response status: ${response.statusCode}');
      
      if (response.body.isNotEmpty && response.body.length < 500) {
        _logger.d('GET Response body: ${response.body}');
      } else {
        _logger.d('GET Response body length: ${response.body.length} bytes');
      }
      
      return _handleResponse(response);
    } on SocketException catch (e) {
      _logger.e('Socket Exception: $e');
      throw NetworkException('Cannot connect to server. Please check your internet connection.');
    } on HttpException catch (e) {
      _logger.e('HTTP Exception: $e');
      throw NetworkException('Cannot communicate with server. Please try again later.');
    } on FormatException catch (e) {
      _logger.e('Format Exception: $e');
      throw ApiException('Invalid response format: $e');
    } catch (e) {
      _logger.e('GET Request Failed: $e');
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException('Network error: $e');
    }
  }
  
  Future<dynamic> postUrl(String url, {Map<String, dynamic>? data, Map<String, String>? headers}) async {
    final uri = Uri.parse(url);
    _logger.d('Making POST request to: $uri');
    
    try {
      if (data != null) {
        _logger.d('Request data: $data');
      }
      
      final Map<String, String> requestHeaders = {
        'Content-Type': 'application/json',
        ...?headers,
      };
      
      final response = await http.post(
        uri,
        headers: requestHeaders,
        body: data != null ? jsonEncode(data) : null,
      ).timeout(_timeout, onTimeout: () {
        throw NetworkException('Request timed out');
      });
      
      _logger.d('Response status: ${response.statusCode}');
      _logger.d('Response body: ${response.body}');
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (response.body.isEmpty) {
          return {};
        }
        try {
          return jsonDecode(response.body);
        } catch (e) {
          _logger.e('JSON Decode Error: $e');
          throw ApiException('Failed to parse response');
        }
      } else {
        String errorMessage = 'Request failed with status: ${response.statusCode}';
        dynamic errorData;
        
        try {
          if (response.body.isNotEmpty) {
            errorData = jsonDecode(response.body);
            if (errorData is Map) {
              if (errorData.containsKey('error')) {
                errorMessage = errorData['error'];
              } else if (errorData.containsKey('message')) {
                errorMessage = errorData['message'];
              } else if (errorData.containsKey('detail')) {
                errorMessage = errorData['detail'];
              }
            }
          }
        } catch (e) {
          _logger.e('Error parsing error response: $e');
        }
        
        throw ApiException(errorMessage, statusCode: response.statusCode, data: errorData);
      }
    } on SocketException catch (e) {
      _logger.e('Socket Exception: $e');      
      throw NetworkException('Cannot connect to server. Please check your internet connection.');
    } on HttpException catch (e) {
      _logger.e('HTTP Exception: $e');
      throw NetworkException('Cannot communicate with server. Please try again later.');
    } on FormatException catch (e) {
      _logger.e('Format Exception: $e');
      throw ApiException('Invalid response format: $e');
    } catch (e) {
      _logger.e('POST request failed: $e');
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException('Network error: $e');
    }
  }

  // Modified to return dynamic instead of Map<String, dynamic>
  Future<dynamic> post(
    String endpoint, {
    Map<String, dynamic>? data,
    Map<String, String>? headers,
    String? token,
  }) async {
    final Uri uri = Uri.parse(endpoint.startsWith('http') ? endpoint : '$baseUrl$endpoint');
    _logger.d('POST Request: $uri');
    
    try {
      final Map<String, String> requestHeaders = {
        ...await _getHeaders(token: token),
        ...?headers,
      };
      
      if (data != null) {
        _logger.d('POST Request data: $data');
      }
      
      final response = await _httpClient.post(
        uri,
        headers: requestHeaders,
        body: data != null ? jsonEncode(data) : null,
      ).timeout(_timeout, onTimeout: () {
        throw NetworkException('Request timed out');
      });
      
      _logger.d('POST Response status: ${response.statusCode}');
      
      if (response.body.isNotEmpty && response.body.length < 500) {
        _logger.d('POST Response body: ${response.body}');
      } else {
        _logger.d('POST Response body length: ${response.body.length} bytes');
      }
      
      return _handleResponse(response);
    } on SocketException catch (e) {
      _logger.e('Socket Exception: $e');
      throw NetworkException('Cannot connect to server. Please check your internet connection.');
    } on HttpException catch (e) {
      _logger.e('HTTP Exception: $e');
      throw NetworkException('Cannot communicate with server. Please try again later.');
    } on FormatException catch (e) {
      _logger.e('Format Exception: $e');
      throw ApiException('Invalid response format: $e');
    } catch (e) {
      _logger.e('POST Request Failed: $e');
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException('Network error: $e');
    }
  }

  // PUT request implementation
  Future<dynamic> put(
    String endpoint, {
    Map<String, dynamic>? data,
    Map<String, String>? headers,
    String? token,
  }) async {
    final Uri uri = Uri.parse(endpoint.startsWith('http') ? endpoint : '$baseUrl$endpoint');
    _logger.d('PUT Request: $uri');
    
    try {
      final Map<String, String> requestHeaders = {
        ...await _getHeaders(token: token),
        ...?headers,
      };
      
      if (data != null) {
        _logger.d('PUT Request data: $data');
      }
      
      final response = await _httpClient.put(
        uri,
        headers: requestHeaders,
        body: data != null ? jsonEncode(data) : null,
      ).timeout(_timeout, onTimeout: () {
        throw NetworkException('Request timed out');
      });
      
      _logger.d('PUT Response status: ${response.statusCode}');
      
      if (response.body.isNotEmpty && response.body.length < 500) {
        _logger.d('PUT Response body: ${response.body}');
      } else {
        _logger.d('PUT Response body length: ${response.body.length} bytes');
      }
      
      return _handleResponse(response);
    } on SocketException catch (e) {
      _logger.e('Socket Exception: $e');
      throw NetworkException('Cannot connect to server. Please check your internet connection.');
    } on HttpException catch (e) {
      _logger.e('HTTP Exception: $e');
      throw NetworkException('Cannot communicate with server. Please try again later.');
    } on FormatException catch (e) {
      _logger.e('Format Exception: $e');
      throw ApiException('Invalid response format: $e');
    } catch (e) {
      _logger.e('PUT Request Failed: $e');
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException('Network error: $e');
    }
  }

  // DELETE request implementation
  Future<dynamic> delete(
    String endpoint, {
    Map<String, dynamic>? data,
    Map<String, String>? headers,
    String? token,
  }) async {
    final Uri uri = Uri.parse(endpoint.startsWith('http') ? endpoint : '$baseUrl$endpoint');
    _logger.d('DELETE Request: $uri');
    
    try {
      final Map<String, String> requestHeaders = {
        ...await _getHeaders(token: token),
        ...?headers,
      };
      
      if (data != null) {
        _logger.d('DELETE Request data: $data');
      }
      
      final response = await _httpClient.delete(
        uri,
        headers: requestHeaders,
        body: data != null ? jsonEncode(data) : null,
      ).timeout(_timeout, onTimeout: () {
        throw NetworkException('Request timed out');
      });
      
      _logger.d('DELETE Response status: ${response.statusCode}');
      
      if (response.body.isNotEmpty && response.body.length < 500) {
        _logger.d('DELETE Response body: ${response.body}');
      } else {
        _logger.d('DELETE Response body length: ${response.body.length} bytes');
      }
      
      return _handleResponse(response);
    } on SocketException catch (e) {
      _logger.e('Socket Exception: $e');
      throw NetworkException('Cannot connect to server. Please check your internet connection.');
    } on HttpException catch (e) {
      _logger.e('HTTP Exception: $e');
      throw NetworkException('Cannot communicate with server. Please try again later.');
    } on FormatException catch (e) {
      _logger.e('Format Exception: $e');
      throw ApiException('Invalid response format: $e');
    } catch (e) {
      _logger.e('DELETE Request Failed: $e');
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException('Network error: $e');
    }
  }

  // Helper function to handle API responses
  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return {};
      }
      
      try {
        return jsonDecode(response.body);
      } catch (e) {
        _logger.e('JSON Decode Error: $e');
        throw ApiException('Failed to parse response');
      }
    } else {
      String errorMessage = 'Request failed with status: ${response.statusCode}';
      dynamic errorData;
      
      try {
        if (response.body.isNotEmpty) {
          errorData = jsonDecode(response.body);
          if (errorData is Map) {
            if (errorData.containsKey('error')) {
              errorMessage = errorData['error'];
            } else if (errorData.containsKey('message')) {
              errorMessage = errorData['message'];
            } else if (errorData.containsKey('detail')) {
              errorMessage = errorData['detail'];
            }
          }
        }
      } catch (e) {
        _logger.e('Error parsing error response: $e');
      }
      
      throw ApiException(errorMessage, statusCode: response.statusCode, data: errorData);
    }
  }

  // Login method
  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      _logger.d('Attempting login for user: $username');
      
      final response = await postUrl(
        loginUrl,
        data: {
          'username': username,
          'password': password,
        },
      );
      
      if (response is Map<String, dynamic>) {
        // Save token
        if (response.containsKey('token') || response.containsKey('access')) {
          final token = response['token'] ?? response['access'];
          _logger.d('Login successful, saving token');
          
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('auth_token', token);
        } else {
          _logger.w('Login response missing token field');
        }
        
        return response;
      } else {
        throw ApiException('Unexpected login response format');
      }
    } catch (e) {
      _logger.e('Login failed: $e');
      rethrow;
    }
  }

  // Logout method
  Future<void> logout() async {
    try {
      _logger.d('Logging out user');
      
      // Clear token from storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      
      // Optional: Make logout API call if backend requires it
      // await post('/auth/logout/');
      
      _logger.d('Logout successful');
    } catch (e) {
      _logger.e('Logout error: $e');
      throw ApiException('Error during logout: ${e.toString()}');
    }
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    return token != null && token.isNotEmpty;
  }

  // Get current auth token
  Future<String?> getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }
}