// lib/data/services/firebase_auth_service.dart
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:logging/logging.dart';

class FirebaseAuthService {
  final firebase_auth.FirebaseAuth _firebaseAuth;
  final Logger _logger = Logger('FirebaseAuthService');

  FirebaseAuthService({
    firebase_auth.FirebaseAuth? firebaseAuth,
  }) : _firebaseAuth = firebaseAuth ?? firebase_auth.FirebaseAuth.instance;

  /// Exchanges a custom token for a Firebase ID token
  /// This is necessary because the backend generates a custom token
  /// that needs to be exchanged for an ID token for authenticated requests
  Future<String?> exchangeCustomTokenForIdToken(String customToken) async {
   _logger.info('Attempting to exchange custom token: ${customToken.substring(0, 10)}...');
    try {
      
      // Sign in with the custom token
      final userCredential = await _firebaseAuth.signInWithCustomToken(customToken);
      
      // Get the user's ID token
      final idToken = await userCredential.user?.getIdToken();
      
       if (idToken == null) {
    _logger.warning('Failed to get ID token after sign in with custom token');
    return null;
  }
      
       _logger.info('Successfully obtained ID token: ${idToken.substring(0, 10)}...');
  return idToken;
} catch (e) {
  _logger.severe('Error exchanging custom token for ID token: $e');
  // Don't throw here, just return null and log
  return null;
}
  }

  /// Signs out the current user
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
      _logger.info('User signed out from Firebase');
    } catch (e) {
      _logger.severe('Error signing out from Firebase: $e');
      throw Exception('Failed to sign out from Firebase: $e');
    }
  }

  /// Checks if a user is currently signed in with Firebase
  bool isSignedIn() {
    return _firebaseAuth.currentUser != null;
  }
}