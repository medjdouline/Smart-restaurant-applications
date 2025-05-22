import 'package:good_taste/data/models/user.dart';
import 'package:good_taste/data/models/allergies_model.dart';
import 'package:good_taste/data/models/regime_model.dart';
import 'package:good_taste/data/models/preferences_model.dart';
import 'package:good_taste/data/api/api_client.dart';
import 'package:logging/logging.dart';
import 'package:good_taste/data/api/auth_api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class AuthRepository {
  final Logger _logger = Logger('AuthRepository');
  final AuthApiService _authApiService;
  final SharedPreferences _prefs;
  final ApiClient _apiClient;
  final _userController = StreamController<User>.broadcast();
  User _currentUser = User.empty;
  String? _currentUid;
  
  AuthRepository({
    required AuthApiService authApiService,
    required SharedPreferences prefs,
    required ApiClient apiClient,
  }) : _authApiService = authApiService, 
       _prefs = prefs,
       _apiClient = apiClient {
    _userController.add(_currentUser);
    
    // MODIFICATION: Vérifier et nettoyer les tokens expirés au démarrage
    _initializeAuth();
  }

  // AJOUT: Méthode pour initialiser l'authentification
  void _initializeAuth() {
    final token = _prefs.getString('auth_token');
    if (token != null) {
      // Vérifier si le token est valide (simple vérification de format)
      if (_isTokenValid(token)) {
        _apiClient.setAuthToken(token);
      } else {
        // Token expiré ou invalide, le nettoyer
        _clearExpiredToken();
      }
    }
  }

  // AJOUT: Vérification basique du token (vous pouvez l'améliorer)
  bool _isTokenValid(String token) {
    // Simple vérification - vous pouvez ajouter une vérification plus sophistiquée
    // comme décoder le JWT et vérifier l'expiration
    return token.isNotEmpty && token.length > 20;
  }

  // AJOUT: Nettoyer le token expiré
  Future<void> _clearExpiredToken() async {
    await _prefs.remove('auth_token');
    _apiClient.clearAuthToken();
    _logger.info("Expired token cleared");
  }

  Stream<User> get user => _userController.stream;
  
  User getCurrentUser() {
    return _currentUser;
  }
  
  Future<String> signUp({
    required String email,
    required String password,
    required String username,
    required String phoneNumber,
  }) async {
    try {
      // AJOUT: Nettoyer tout token existant avant signup
      await _clearExpiredToken();
      
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
      
      await _prefs.setString('temp_uid', _currentUid!);
      
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
        loyaltyPoints: 0,
      );
      
      _userController.add(_currentUser);
      
      return _currentUid!;
    } catch (e) {
      _logger.severe("Signup failed: $e");
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
    int? loyaltyPoints,
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
      loyaltyPoints: loyaltyPoints ?? _currentUser.loyaltyPoints,
    );
    
    _logger.info("Mise à jour du profil utilisateur: ${_currentUser.name}, préférences: ${_currentUser.preferences.preferences}");
    _userController.add(_currentUser);
    return;
  }
  
  Future<void> logIn({
    required String email,
    required String password,
  }) async {
    try {
      // AJOUT: Nettoyer tout token existant avant login
      await _clearExpiredToken();
      
      final response = await _authApiService.clientLogin(
        identifier: email,
        password: password,
      );

      if (!response.success) {
        throw Exception(response.error ?? 'Login failed');
      }

      // Stockage du token
      await _prefs.setString('auth_token', response.data['id_token']);
      _apiClient.setAuthToken(response.data['id_token']);
      _logger.info("Token stored and ApiClient configured successfully");

      // Récupération des données utilisateur
      final uid = response.data['uid'];
      String username = email.split('@')[0];
      
      _currentUser = User(
        id: uid,
        email: email,
        name: username,
        profileImage: 'assets/images/profile_avatar.png',
        phoneNumber: '0610101010',
        gender: 'Homme',
        dateOfBirth: DateTime(1990, 1, 1),
        allergies: const AllergiesModel(),
        regimes: const RegimeModel(),
        preferences: const PreferencesModel(),
        idToken: response.data['id_token'],
        loyaltyPoints: 0,
      );

      _userController.add(_currentUser);
      _logger.info("User logged in with email: $email");

    } catch (e) {
      _logger.severe("Login failed: $e");
      if (e.toString().contains('Invalid credentials')) {
        throw Exception('Email ou mot de passe incorrect.');
      } else if (e.toString().contains('Complete signup first')) {
        throw Exception('Veuillez compléter votre inscription.');
      } else if (e.toString().contains('Firebase connection error')) {
        throw Exception('Erreur de connexion au serveur.');
      }
      throw Exception('Échec de la connexion: ${e.toString()}');
    }
  }
  
  Future<void> logOut() async {
    await _prefs.remove('auth_token');
    _apiClient.clearAuthToken(); // MODIFICATION: Utiliser clearAuthToken()
    _currentUser = User.empty;
    _userController.add(_currentUser);
    _logger.info("User logged out");
  }

  String? getAuthToken() {
    return _prefs.getString('auth_token');
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
      
      _currentUser = User(
        id: _currentUser.id,
        email: _currentUser.email,
        name: _currentUser.name,
        phoneNumber: _currentUser.phoneNumber,
        profileImage: _currentUser.profileImage,
        gender: gender,
        dateOfBirth: dateOfBirth,
        allergies: _currentUser.allergies,
        regimes: _currentUser.regimes,
        preferences: _currentUser.preferences,
        loyaltyPoints: _currentUser.loyaltyPoints,
        idToken: _currentUser.idToken,
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
      
      _currentUser = User(
        id: _currentUser.id,
        email: _currentUser.email,
        name: _currentUser.name,
        phoneNumber: _currentUser.phoneNumber,
        profileImage: _currentUser.profileImage,
        gender: _currentUser.gender,
        dateOfBirth: _currentUser.dateOfBirth,
        allergies: AllergiesModel(allergies: allergies),
        regimes: _currentUser.regimes,
        preferences: _currentUser.preferences,
        loyaltyPoints: _currentUser.loyaltyPoints,
        idToken: _currentUser.idToken,
      );
      
      _userController.add(_currentUser);
      
      return response;
    } catch (e) {
      _logger.severe("Allergies info update failed: $e");
      throw Exception('Échec de la mise à jour des allergies: ${e.toString()}');
    }
  }

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
      
      _currentUser = User(
        id: _currentUser.id,
        email: _currentUser.email,
        name: _currentUser.name,
        phoneNumber: _currentUser.phoneNumber,
        profileImage: _currentUser.profileImage,
        gender: _currentUser.gender,
        dateOfBirth: _currentUser.dateOfBirth,
        allergies: _currentUser.allergies,
        regimes: RegimeModel(regimes: restrictions),
        preferences: _currentUser.preferences,
        loyaltyPoints: _currentUser.loyaltyPoints,
        idToken: _currentUser.idToken,
      );
      
      _userController.add(_currentUser);
      
      return response;
    } catch (e) {
      _logger.severe("Regimes info update failed: $e");
      throw Exception('Échec de la mise à jour des régimes: ${e.toString()}');
    }
  }

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
      
      if (response.data['id_token'] != null) {
        await _prefs.setString('auth_token', response.data['id_token']);
        _apiClient.setAuthToken(response.data['id_token']);
        _logger.info("Token stored and ApiClient configured successfully");
        
        await _prefs.remove('temp_uid');
      }
      
      _currentUser = User(
        id: _currentUser.id,
        email: _currentUser.email,
        name: _currentUser.name,
        phoneNumber: _currentUser.phoneNumber,
        profileImage: _currentUser.profileImage,
        gender: _currentUser.gender,
        dateOfBirth: _currentUser.dateOfBirth,
        allergies: _currentUser.allergies,
        regimes: _currentUser.regimes,
        preferences: PreferencesModel(preferences: preferences),
        loyaltyPoints: _currentUser.loyaltyPoints,
        idToken: response.data['id_token'],
      );
      
      _userController.add(_currentUser);
      
      return response;
    } catch (e) {
      _logger.severe("Preferences update failed: $e");
      throw Exception('Échec de la mise à jour des préférences: ${e.toString()}');
    }
  }

  void clearTempUid() {
    _prefs.remove('temp_uid');
  }

  void dispose() {
    _userController.close();
  }
}