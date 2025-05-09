import 'dart:async';
import 'package:logger/logger.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../core/api/api_client.dart';
import '../../core/services/firebase_auth_service.dart';
import '../models/user.dart';

class AuthException implements Exception {
  final String message;
  
  AuthException(this.message);
  
  @override
  String toString() => 'AuthException: $message';
}

class AuthRepositoryImpl {
  final ApiClient _apiClient;
  final FirebaseAuthService _firebaseAuthService;
  final Logger _logger = Logger();
  
  String get _baseApiUrl => dotenv.env['API_BASE_URL'] ?? 'http://127.0.0.1:8000/api/';
  
  AuthRepositoryImpl({
    required ApiClient apiClient,
    required FirebaseAuthService firebaseAuthService,
  })  : _apiClient = apiClient,
        _firebaseAuthService = firebaseAuthService;
  // Add this method to your AuthRepositoryImpl class:

Future<bool> changePassword({
  required String currentPassword,
  required String newPassword,
}) async {
  try {
    // Get the current user's email or username
    final currentUser = await getCurrentUser();
    if (currentUser == null) {
      throw AuthException('User not authenticated');
    }
    
    _logger.d('Updating password for user: ${currentUser.email}');
    
    // Use PUT request to the correct endpoint based on Django URLs
    final response = await _apiClient.put(
      '/server/profile/update-password/',
      data: {
        'current_password': currentPassword,
        'new_password': newPassword,
      },
    );
    
    _logger.d('Password update response: $response');

    // Also update the password in Firebase if you're using it
    await _firebaseAuthService.updatePassword(newPassword);
    
    return true;
  } catch (e) {
    if (e is ApiException) {
      throw AuthException(e.message);
    }
    throw AuthException('Failed to change password: $e');
  }
}
  Future<User> login({
  String? email,
  String? username,
  required String password,
}) async {
  try {
    _logger.d('Attempting login with ${email != null ? 'email' : 'username'}');
    
    if (email == null && username == null) {
      throw AuthException('Email or username is required');
    }
    
    final Map<String, dynamic> requestData = {
      'password': password,
    };
    
    if (email != null) {
      requestData['email'] = email;
    }
    
    if (username != null) {
      requestData['username'] = username;
    }
    
    _logger.d('Login request data: $requestData');
    
    dynamic response;
    ApiException? lastError;
    
    // FIXED: Explicitly use the correct URL with /auth/ in the path
    String loginUrl = "http://127.0.0.1:8000/api/auth/staff/login/";
    _logger.d('Using login URL: $loginUrl');
    
    try {
      response = await _apiClient.postUrl(loginUrl, data: requestData);
    } catch (e) {
      if (e is ApiException) {
        lastError = e;
        _logger.w('First login attempt failed: ${e.message}');
        
        // If you still want a fallback, keep it structured the same way
        try {
          _logger.d('Trying alternative login endpoint');
          response = await _apiClient.postUrl(
            "http://127.0.0.1:8000/api/auth/staff/login/",
            data: requestData,
          );
        } catch (e2) {
          if (e2 is ApiException) {
            _logger.w('Alternative login endpoint also failed: ${e2.message}');
            lastError = e2;
          } else {
            _logger.e('Unknown error during login: $e2');
            throw AuthException('Login failed: $e2');
          }
        }
      } else {
        _logger.e('Unknown error during login: $e');
        throw AuthException('Login failed: $e');
      }
    }
    
    if (response == null) {
      throw AuthException('Login failed: ${lastError?.message ?? "Unknown error"}');
    }
    
    _logger.d('Login API response received: $response');
    
    final User user = User.fromJson(response);
    _logger.d('User parsed: $user');
    
    if (user.token == null || user.token!.isEmpty) {
      throw AuthException('Invalid login response: No authentication token received');
    }
    
    await _firebaseAuthService.storeAuthData(
      token: user.token ?? '',
      uid: user.uid ?? (throw AuthException('User UID is null')),
      role: user.role,
      employeeId: user.employeeId ?? '',
      roleId: user.roleId != null ? int.tryParse(user.roleId!) : null,
    );
    
    _logger.i('User logged in successfully: ${user.fullName}');
    return user;
  } catch (e) {
    _logger.e('Login failed: $e');
    if (e is AuthException) {
      rethrow;
    }
    throw AuthException('Login failed: $e');
  }
}
  
  Future<void> logout() async {
    try {
      _logger.d('Logging out user');
      await _firebaseAuthService.clearAuthData();
      _logger.i('User logged out successfully');
    } catch (e) {
      _logger.e('Logout failed: $e');
      throw AuthException('Logout failed: $e');
    }
  }
  
  Future<bool> isAuthenticated() async {
    try {
      bool authenticated = await _firebaseAuthService.isAuthenticated();
      _logger.d('User authentication status: $authenticated');
      return authenticated;
    } catch (e) {
      _logger.e('Error checking authentication status: $e');
      return false;
    }
  }
 
  Future<User?> getCurrentUser() async {
    try {
      final uid = await _firebaseAuthService.getUid();
      final role = await _firebaseAuthService.getRole();
      final token = await _firebaseAuthService.getAuthToken();
      final employeeId = await _firebaseAuthService.getEmployeeId();
      final roleId = await _firebaseAuthService.getRoleId();
      
      _logger.d('Getting current user - UID: $uid, Role: $role');
      
      if (uid == null || role == null) {
        _logger.d('No authenticated user found');
        return null;
      }
      
      return User(
        id: uid,
        email: '',
        firstName: '',
        lastName: '',
        role: role,
        employeeId: employeeId,
        roleId: roleId?.toString(),
        token: token,
        uid: uid,
      );
    } catch (e) {
      _logger.e('Failed to get current user: $e');
      return null;
    }
  }
  
  Future<String?> getAuthToken() {
    return _firebaseAuthService.getAuthToken();
  }
}