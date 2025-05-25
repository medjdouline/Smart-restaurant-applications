import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart';

class ApiService {
  // Use your local Django server URL from .env
  static const String baseUrl = 'http://127.0.0.1:8000/api';
  
  // For debugging - you can switch this easily
  static const bool isDebug = true;
  
  static String get debugInfo => isDebug ? '[API Debug] ' : '';
  
  // Get headers with Firebase auth token
  Future<Map<String, String>> _getHeaders() async {
    final user = FirebaseAuth.instance.currentUser;
    String? token;
    
    if (user != null) {
      try {
        token = await user.getIdToken(true); // Force refresh
        if (isDebug) {
          print('${debugInfo}Firebase user: ${user.email}');
          print('${debugInfo}Token obtained: ${token?.substring(0, 20)}...');
        }
      } catch (e) {
        print('${debugInfo}Error getting token: $e');
      }
    } else {
      print('${debugInfo}No Firebase user authenticated');
    }
    
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }
  
  // Generic request method with better error handling
  Future<http.Response> _makeRequest(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final headers = await _getHeaders();
      final url = Uri.parse('$baseUrl$endpoint');
      
      if (isDebug) {
        print('${debugInfo}$method request to: $url');
        print('${debugInfo}Headers: ${headers.keys.toList()}');
        if (body != null) print('${debugInfo}Body: $body');
      }
      
      http.Response response;
      
      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(url, headers: headers);
          break;
        case 'POST':
          response = await http.post(
            url,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
        case 'PUT':
          response = await http.put(
            url,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
        case 'DELETE':
          response = await http.delete(url, headers: headers);
          break;
        default:
          throw Exception('Unsupported HTTP method: $method');
      }
      
      if (isDebug) {
        print('${debugInfo}Response status: ${response.statusCode}');
        print('${debugInfo}Response body: ${response.body.length > 200 ? response.body.substring(0, 200) + "..." : response.body}');
      }
      
      return response;
      
    } catch (e) {
      print('${debugInfo}Request failed: $e');
      rethrow;
    }
  }
  
  // GET request
  Future<http.Response> get(String endpoint) async {
    return await _makeRequest('GET', endpoint);
  }
  
  // POST request
  Future<http.Response> post(String endpoint, Map<String, dynamic> data) async {
    return await _makeRequest('POST', endpoint, body: data);
  }
  
  // PUT request
  Future<http.Response> put(String endpoint, Map<String, dynamic> data) async {
    return await _makeRequest('PUT', endpoint, body: data);
  }
  
  // DELETE request
  Future<http.Response> delete(String endpoint) async {
    return await _makeRequest('DELETE', endpoint);
  }
  
  // Helper method to handle response with better error details
  Map<String, dynamic> handleResponse(http.Response response) {
    if (isDebug) {
      print('${debugInfo}Handling response: ${response.statusCode}');
    }
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        return jsonDecode(response.body);
      } catch (e) {
        // Handle non-JSON responses
        return {'message': response.body, 'success': true};
      }
    } else {
      // Enhanced error handling
      String errorMessage = 'API Error: ${response.statusCode}';
      
      try {
        final errorBody = jsonDecode(response.body);
        if (errorBody is Map && errorBody.containsKey('detail')) {
          errorMessage = errorBody['detail'];
        } else if (errorBody is Map && errorBody.containsKey('message')) {
          errorMessage = errorBody['message'];
        } else {
          errorMessage += ' - ${response.body}';
        }
      } catch (e) {
        errorMessage += ' - ${response.body}';
      }
      
      print('${debugInfo}API Error: $errorMessage');
      throw ApiException(response.statusCode, errorMessage);
    }
  }
  
  // Test connection method
  Future<bool> testConnection() async {
    try {
      final response = await get('/health/'); // You might want to add this endpoint
      return response.statusCode == 200;
    } catch (e) {
      print('${debugInfo}Connection test failed: $e');
      return false;
    }
  }
}
// Logout method
Future<bool> logout() async {
  try {
    final response = await post('/auth/logout/' as Uri, body: {});
    return response.statusCode == 200;
  } catch (e) {
    return false;
  }
}


// Custom exception class for better error handling
class ApiException implements Exception {
  final int statusCode;
  final String message;
  
  ApiException(this.statusCode, this.message);
  
  @override
  String toString() => 'ApiException($statusCode): $message';
}