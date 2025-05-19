import 'package:good_taste/data/models/user.dart';
import 'package:good_taste/data/models/allergies_model.dart';
import 'package:good_taste/data/models/regime_model.dart';
import 'package:good_taste/data/models/preferences_model.dart';
import 'package:good_taste/data/api/api_client.dart';
import 'package:logging/logging.dart';
import 'package:good_taste/data/api/auth_api_service.dart';
import 'dart:async';

class AuthRepository {
  final Logger _logger = Logger('AuthRepository');
  final AuthApiService _authApiService;
  
  final _userController = StreamController<User>.broadcast();
  User _currentUser = User.empty;
  String? _currentUid;
  
  AuthRepository({required AuthApiService authApiService}) 
    : _authApiService = authApiService {
    _userController.add(_currentUser);
  }

  Stream<User> get user => _userController.stream;
  
  User getCurrentUser() {
    return _currentUser;
  }
  
// In auth_repository.dart - update the signUp method
Future<String> signUp({
  required String email,
  required String password,
  required String username,
  required String phoneNumber,
}) async {
  try {
    final response = await _authApiService.signUpStep1(
      email: email,
      password: password,
      passwordConfirmation: password,
      username: username,
      phoneNumber: phoneNumber,
    );
    
    if (!response.success) {
      throw Exception(response.error ?? 'Signup failed');
    }
    
    _currentUid = response.data['uid'];
    _logger.info("User created with UID: $_currentUid");
    
    // Create a partial user object with the data we have so far
    _currentUser = User(
      id: _currentUid!,
      email: email,
      name: username,
      profileImage: 'assets/images/profile_avatar.png',
      phoneNumber: phoneNumber,
      gender: null,
      dateOfBirth: null,
      allergies: const AllergiesModel(),
      regimes: const RegimeModel(),
      preferences: const PreferencesModel(),
    );
    
    _userController.add(_currentUser);
    
    return _currentUid!;
  } catch (e) {
    _logger.severe("Signup failed: $e");
    // Parse the error to provide a more user-friendly message
    if (e.toString().contains('Email already registered')) {
      throw Exception('Cette adresse email est déjà utilisée.');
    } else if (e.toString().contains('Passwords do not match')) {
      throw Exception('Les mots de passe ne correspondent pas.');
    } else if (e.toString().contains('All fields are required')) {
      throw Exception('Tous les champs sont obligatoires.');
    }
    throw Exception('Échec de l\'inscription: ${e.toString()}');
  }
}
  // Rest of the methods remain unchanged
  Future<void> updateUserProfile({
    String? name,
    String? email,
    String? phoneNumber,
    String? gender,
    DateTime? dateOfBirth,
    String? profileImage,
    AllergiesModel? allergies,
    RegimeModel? regimes,
    PreferencesModel? preferences,
  }) async {
    await Future.delayed(Duration(seconds: 1));
    
    _currentUser = User(
      id: _currentUser.id,
      email: email ?? _currentUser.email,
      name: name ?? _currentUser.name,
      phoneNumber: phoneNumber ?? _currentUser.phoneNumber,
      profileImage: profileImage ?? _currentUser.profileImage,
      gender: gender ?? _currentUser.gender,
      dateOfBirth: dateOfBirth ?? _currentUser.dateOfBirth,
      allergies: allergies ?? _currentUser.allergies,
      regimes: regimes ?? _currentUser.regimes,
      preferences: preferences ?? _currentUser.preferences,
    );
    
    _logger.info("Mise à jour du profil utilisateur: ${_currentUser.name}, préférences: ${_currentUser.preferences.preferences}");
    _userController.add(_currentUser);
    return;
  }
  
  Future<void> logIn({
    required String email,
    required String password,
  }) async {
    
    if (email == "admin@example.com") {
      _currentUser = User(
        id: 'admin-id',
        email: email,
        name: 'Admin',
        profileImage: 'assets/images/admin_avatar.png',
        phoneNumber: '0600000000',
        gender: 'Homme',
        dateOfBirth: DateTime(1985, 5, 15),
        allergies: const AllergiesModel(),
        regimes: const RegimeModel(),
        preferences: const PreferencesModel(),
      );
    } else {
    
      String username = email.split('@')[0];
      
      _currentUser = User(
        id: 'user-${DateTime.now().millisecondsSinceEpoch}',
        email: email,
        name: username, 
        profileImage: 'assets/images/profile_avatar.png',
        phoneNumber: '0610101010',
        gender: 'Homme',
        dateOfBirth: DateTime(1990, 1, 1),
        allergies: const AllergiesModel(),
        regimes: const RegimeModel(),
        preferences: const PreferencesModel(),
      );
    }
    _userController.add(_currentUser);
    _logger.info("Utilisateur simulé connecté avec email: $email");
    return Future.delayed(Duration(seconds: 1)); 
  }
  
  Future<void> logOut() async {
    _currentUser = User.empty;
    _userController.add(_currentUser);
    _logger.info("Utilisateur simulé déconnecté");
    return Future.delayed(Duration(seconds: 1)); 
  }
  
  bool isValidAge(DateTime dateOfBirth) {
    final today = DateTime.now();
    final difference = today.difference(dateOfBirth).inDays;
    final age = difference / 365;
    return age >= 13;
  }
  

  Future<ApiResponse> completePersonalInfo({
  required String uid,
  required DateTime dateOfBirth,
  required String gender,
}) async {
  try {
    final response = await _authApiService.signUpStep2(
      uid: uid,
      dateOfBirth: dateOfBirth,
      gender: gender,
    );
    
    if (!response.success) {
      throw Exception(response.error ?? 'Personal info update failed');
    }
    
    // Update local user data
    _currentUser = _currentUser.copyWith(
      dateOfBirth: dateOfBirth,
      gender: gender,
    );
    
    _userController.add(_currentUser);
    
    return response;
  } catch (e) {
    _logger.severe("Personal info update failed: $e");
    throw Exception('Échec de la mise à jour des informations personnelles: ${e.toString()}');
  }
}
Future<ApiResponse> completeAllergiesInfo({
  required String uid,
  required List<String> allergies,
}) async {
  try {
    final response = await _authApiService.signUpStep3(
      uid: uid,
      allergies: allergies,
    );
    
    if (!response.success) {
      throw Exception(response.error ?? 'Allergies info update failed');
    }
    
    // Update local user data
    _currentUser = _currentUser.copyWith(
      allergies: AllergiesModel(allergies: allergies),
    );
    
    _userController.add(_currentUser);
    
    return response;
  } catch (e) {
    _logger.severe("Allergies info update failed: $e");
    throw Exception('Échec de la mise à jour des allergies: ${e.toString()}');
  }
}
// In auth_repository.dart - add this method
Future<ApiResponse> completeRegimesInfo({
  required String uid,
  required List<String> restrictions,
}) async {
  try {
    final response = await _authApiService.signUpStep4(
      uid: uid,
      restrictions: restrictions,
    );
    
    if (!response.success) {
      throw Exception(response.error ?? 'Regimes info update failed');
    }
    
    // Update local user data
    _currentUser = _currentUser.copyWith(
      regimes: RegimeModel(regimes: restrictions),
    );
    
    _userController.add(_currentUser);
    
    return response;
  } catch (e) {
    _logger.severe("Regimes info update failed: $e");
    throw Exception('Échec de la mise à jour des régimes: ${e.toString()}');
  }
}
// In auth_repository.dart - add this method
Future<ApiResponse> completePreferencesInfo({
  required String uid,
  required List<String> preferences,
}) async {
  try {
    final response = await _authApiService.signUpStep5(
      uid: uid,
      preferences: preferences,
    );
    
    if (!response.success) {
      throw Exception(response.error ?? 'Preferences update failed');
    }
    
    // Update local user data
    _currentUser = _currentUser.copyWith(
      preferences: PreferencesModel(preferences: preferences),
    );
    
    _userController.add(_currentUser);
    
    return response;
  } catch (e) {
    _logger.severe("Preferences update failed: $e");
    throw Exception('Échec de la mise à jour des préférences: ${e.toString()}');
  }
}
  void dispose() {
    _userController.close();
  }
}