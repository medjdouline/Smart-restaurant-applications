import 'package:good_taste/data/models/user.dart';
import 'package:good_taste/data/models/allergies_model.dart';
import 'package:good_taste/data/models/regime_model.dart';
import 'package:good_taste/data/models/preferences_model.dart';
import 'package:good_taste/data/api/auth_api_service.dart';
import 'package:good_taste/data/api/auth_api_service.dart';
import 'package:good_taste/data/repositories/allergies_repository.dart';
import 'package:logging/logging.dart';
import 'dart:async';

class AuthRepository {
  final Logger _logger = Logger('AuthRepository');
  final AuthApiService _authApiService;
  final AllergiesRepository _allergiesRepository;
  
  final _userController = StreamController<User>.broadcast();
  User _currentUser = User.empty;
  String? _currentUid;
  
  AuthRepository({
    required AuthApiService authApiService,
    required AllergiesRepository allergiesRepository,
  }) : _authApiService = authApiService,
       _allergiesRepository = allergiesRepository {
    _userController.add(_currentUser);
  }

  Stream<User> get user => _userController.stream;
  
  User getCurrentUser() {
    return _currentUser;
  }
  
  String? getCurrentUid() {
    return _currentUid;
  }
  
  bool isValidAge(DateTime dateOfBirth) {
    final today = DateTime.now();
    final difference = today.difference(dateOfBirth).inDays;
    final age = difference / 365;
    return age >= 13;
  }

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
      
      // Store the UID for later steps
      _currentUid = response.data['uid'];
      
      // Create a basic user with the information we have
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
      
      _logger.info("User signed up with email: $email, username: $username, phone: $phoneNumber");
      
      return _currentUid!;
    } catch (e) {
      _logger.severe("Signup failed: $e");
      throw Exception('Failed to sign up: $e');
    }
  }
  


// In auth_repository.dart
Future<void> updateUserProfile({
        RegimeModel? regimes,
  PreferencesModel? preferences,
  // Step 1 fields
  String? name,
  String? email,
  String? phoneNumber,
  
  // Step 2 fields
  String? gender,
  DateTime? dateOfBirth,
  String? profileImage,
 
  
  // Step 3 fields
  AllergiesModel? allergies,
}) async {
  try {
    // Handle Step 1 updates
    if (name != null || email != null || phoneNumber != null) {
      _currentUser = _currentUser.copyWith(
        name: name ?? _currentUser.name,
        email: email ?? _currentUser.email,
        phoneNumber: phoneNumber ?? _currentUser.phoneNumber,
      );
      _userController.add(_currentUser);
    }

    // Handle Step 2 updates
    if (gender != null && dateOfBirth != null && _currentUid != null) {
      final response = await _authApiService.signUpStep2(
        uid: _currentUid!,
        dateOfBirth: dateOfBirth,
        gender: gender,
      );

      if (!response.success) {
        throw Exception(response.error ?? 'Personal info update failed');
      }

      _currentUser = _currentUser.copyWith(
        gender: gender,
        dateOfBirth: dateOfBirth,
        profileImage: profileImage,
      );
      _userController.add(_currentUser);
    }

    // Handle Step 3 updates (only if step 2 is complete)
    if (allergies != null && _currentUid != null && _currentUser.gender != null) {
      final response = await _authApiService.signUpStep3(
        uid: _currentUid!,
        allergies: allergies.allergies,
      );

      if (!response.success) {
        throw Exception(response.error ?? 'Failed to save allergies');
      }

      _currentUser = _currentUser.copyWith(allergies: allergies);
      _userController.add(_currentUser);
    }
   if (regimes != null && _currentUid != null) {
      final response = await _authApiService.signUpStep4(
        uid: _currentUid!,
        restrictions: regimes.regimes, // Utilise .regimes comme défini dans votre modèle
      );

      if (!response.success) {
        throw Exception(response.error ?? 'Échec de l\'enregistrement des régimes');
      }

      _currentUser = _currentUser.copyWith(regimes: regimes);
      _userController.add(_currentUser);
    }
    // ▲▲▲ FIN DE L'AJOUT ▲▲▲
//step 5
if (preferences != null && _currentUid != null) {
      final response = await _authApiService.signUpStep5(
        uid: _currentUid!,
        preferences: preferences.preferences,
      );

      if (!response.success) {
        throw Exception(response.error ?? 'Échec de l\'enregistrement des préférences');
      }

      _currentUser = _currentUser.copyWith(preferences: preferences);
      _userController.add(_currentUser);
      
      // Si vous avez besoin du token de connexion retourné par le backend:
      final customToken = response.data['custom_token'];
      // ... faites ce que vous devez faire avec ce token
    }
    // ▲▲▲ FIN DE L'AJOUT ▲▲▲
    
  } catch (e) {
    _logger.severe("Échec de la mise à jour du profil: $e");
    throw Exception('Échec de la mise à jour du profil: $e');
  }
}

  Future<void> logOut() async {
    _currentUser = User.empty;
    _userController.add(_currentUser);
    _logger.info("Utilisateur simulé déconnecté");
    return Future.delayed(Duration(seconds: 1)); 
  }
  

Future<void> logIn({
  required String identifier,
  required String password,
}) async {
  try {
    final response = await _authApiService.login(
      identifier: identifier,
      password: password,
    );
    
    if (!response.success) {
      throw Exception(response.error ?? 'Login failed');
    }
    
    _currentUid = response.data['uid'];

        if (response.data['token'] != null) {
  await _authApiService.setAuthToken(response.data['token']); // Fixed
}
    
    // For email vs username handling
    String email = identifier.contains('@') ? identifier : '';
    String username = !identifier.contains('@') ? identifier : email.split('@')[0];
    
    _currentUser = User(
      id: _currentUid!,
      email: email,
      name: username,
      profileImage: 'assets/images/profile_avatar.png',
      phoneNumber: '',
      gender: null,
      dateOfBirth: null,
      allergies: const AllergiesModel(),
      regimes: const RegimeModel(),
      preferences: const PreferencesModel(),
    );
    
    _userController.add(_currentUser);
    
    _logger.info("User logged in with identifier: $identifier");
  } catch (e) {
    _logger.severe("Login failed: $e");
    throw Exception('Failed to login: $e');
  }
}
Future<List<String>> getAllergies() async {
  try {
    final response = await _authApiService.getAllergies(); // Will call /client-mobile/allergies/
    if (!response.success) throw Exception(response.error);
    return List<String>.from(response.data['allergies'] ?? []);
  } catch (e) {
    _logger.severe("Failed to get allergies: $e");
    // Fallback to local storage if needed
    final user = getCurrentUser();
    return _allergiesRepository.getAllergies(userId: user.id);
  }
}

Future<void> updateAllergies(List<String> allergies) async {
  try {
    _logger.info("Starting updateAllergies with: $allergies");
    
    // Rest of the code...
    
    _logger.info("Successfully updated allergies");
  } catch (e) {
    _logger.severe("Failed to update allergies: $e");
    throw Exception('Failed to update allergies: $e');
  }
}
}