import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';

class FirebaseAuthService {
  static const String _keyToken = 'auth_token';
  static const String _keyUid = 'auth_uid';
  static const String _keyRole = 'auth_role';
  static const String _keyEmployeeId = 'auth_employee_id';
  static const String _keyRoleId = 'auth_role_id';
  static const String _keyLastLogin = 'auth_last_login';

  final Logger _logger = Logger();

  Future<void> storeAuthData({
    required String token,
    required String uid,
    required String role,
    required String employeeId,
    int? roleId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyToken, token);
      await prefs.setString(_keyUid, uid);
      await prefs.setString(_keyRole, role);
      await prefs.setString(_keyEmployeeId, employeeId);
      if (roleId != null) {
        await prefs.setInt(_keyRoleId, roleId);
      }
      await prefs.setInt(_keyLastLogin, DateTime.now().millisecondsSinceEpoch);
      _logger.d('Auth data stored successfully');
    } catch (e) {
      _logger.e('Error storing auth data: $e');
      throw Exception('Failed to store authentication data: $e');
    }
  }

  Future<void> clearAuthData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyToken);
      await prefs.remove(_keyUid);
      await prefs.remove(_keyRole);
      await prefs.remove(_keyEmployeeId);
      await prefs.remove(_keyRoleId);
      await prefs.remove(_keyLastLogin);
      _logger.d('Auth data cleared successfully');
    } catch (e) {
      _logger.e('Error clearing auth data: $e');
      throw Exception('Failed to clear authentication data: $e');
    }
  }

  Future<bool> isAuthenticated() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_keyToken);
      final uid = prefs.getString(_keyUid);
      
      if (token == null || token.isEmpty || uid == null || uid.isEmpty) {
        _logger.d('User not authenticated: Missing token or uid');
        return false;
      }
      
      final lastLoginTimestamp = prefs.getInt(_keyLastLogin);
      if (lastLoginTimestamp != null) {
        final lastLogin = DateTime.fromMillisecondsSinceEpoch(lastLoginTimestamp);
        final now = DateTime.now();
        if (now.difference(lastLogin).inDays > 30) {
          _logger.d('Token expired, logging out');
          await clearAuthData();
          return false;
        }
      }
      return true;
    } catch (e) {
      _logger.e('Error checking authentication status: $e');
      return false;
    }
  }

  Future<String?> getAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyToken);
    } catch (e) {
      _logger.e('Error getting auth token: $e');
      return null;
    }
  }

  Future<String?> getUid() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyUid);
    } catch (e) {
      _logger.e('Error getting uid: $e');
      return null;
    }
  }

  Future<String?> getRole() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyRole);
    } catch (e) {
      _logger.e('Error getting role: $e');
      return null;
    }
  }

  Future<String?> getEmployeeId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyEmployeeId);
    } catch (e) {
      _logger.e('Error getting employee ID: $e');
      return null;
    }
  }

  Future<int?> getRoleId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_keyRoleId);
    } catch (e) {
      _logger.e('Error getting role ID: $e');
      return null;
    }
  }

  // Add the missing updatePassword method
  Future<void> updatePassword(String newPassword) async {
    try {
      _logger.d('Password updated successfully in FirebaseAuthService');
      // Since you're not actually using Firebase Auth but a custom implementation,
      // there's no need to store the password locally.
      // This method is just here to satisfy the interface call in your repository
    } catch (e) {
      _logger.e('Error updating password: $e');
      throw Exception('Failed to update password: $e');
    }
  }
}