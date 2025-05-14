import 'package:good_taste/data/models/user.dart';
import 'package:good_taste/data/models/allergies_model.dart';
import 'package:good_taste/data/models/regime_model.dart';
import 'package:good_taste/data/models/preferences_model.dart';
import 'package:logging/logging.dart';
import 'dart:async';

class AuthRepository {
  final Logger _logger = Logger('AuthRepository');
  
  final _userController = StreamController<User>.broadcast();

  User _currentUser = User(
    id: 'fake-id', 
    email: 'fake@email.com', 
    name: 'Marie Dupont',
    profileImage: 'assets/images/profile_avatar.png',
    phoneNumber: '0612345678',
    gender: 'Femme', 
    dateOfBirth: DateTime(1990, 1, 1),
    allergies: const AllergiesModel(), 
    regimes: const RegimeModel(), 
    preferences: const PreferencesModel(), 
  );
  
  AuthRepository() {
    _userController.add(_currentUser);
  }

  Stream<User> get user => _userController.stream;
  
  User getCurrentUser() {
    return _currentUser;
  }
  
  Future<void> signUp({
    required String email,
    required String password,
    required String username,
    required String phoneNumber,
    String? gender,
    DateTime? dateOfBirth,
    String? profileImage,
    AllergiesModel? allergies,
    RegimeModel? regimes,
    PreferencesModel? preferences,
  }) async {
    
    _currentUser = User(
      id: 'user-${DateTime.now().millisecondsSinceEpoch}',
      email: email,
      name: username,
      profileImage: profileImage ?? 'assets/images/profile_avatar.png',
      phoneNumber: phoneNumber,
      gender: gender,
      dateOfBirth: dateOfBirth,
      allergies: allergies ?? const AllergiesModel(),
      regimes: regimes ?? const RegimeModel(),
      preferences: preferences ?? const PreferencesModel(),
    );
    
    _userController.add(_currentUser);

    _logger.info("Utilisateur simulé inscrit avec email: $email, username: $username, téléphone: $phoneNumber, genre: $gender, dateOfBirth: $dateOfBirth, profileImage: $profileImage, allergies: ${allergies?.allergies}, régimes: ${regimes?.regimes}, préférences: ${preferences?.preferences}");
    return Future.delayed(Duration(seconds: 1));
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
  
  void dispose() {
    _userController.close();
  }
}