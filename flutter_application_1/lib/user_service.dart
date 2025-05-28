import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';

class UserService with ChangeNotifier {
    int _fidelityPoints = 0;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _firebaseUser;
  bool _isGuest = false;
  String? _idToken;
  String? _refreshToken;
  String? _gender;
  DateTime? _birthdate;
  String? _tableId;
  
  
  String? _nomUtilisateur;
  String? _email; // ADD THIS LINE - new field to store email from API
  String? _phone;
  String? _photoUrl;
  List<NotificationModel> _notifications = [];
  int _unreadNotificationsCount = 0;

  final List<String> _diets = [];
  final List<String> _allergies = [];
  final List<String> _preferences = [];

  // Base URL for your Django API
  static const String _baseUrl = 'http://127.0.0.1:8000/api';

  UserService() {
    // Remove Firebase auth state listener since we're using Django auth
  }

  // Getters
  User? get firebaseUser => _firebaseUser;
  String? get nomUtilisateur {
  if (_isGuest && _nomUtilisateur != null) {
    return _nomUtilisateur;
  }
  return _nomUtilisateur ?? _firebaseUser?.displayName;
}
  String? get email => _email ?? _firebaseUser?.email; // UPDATED - now uses _email first
  String? get gender => _gender;
  DateTime? get birthdate => _birthdate;
  String? get phone => _phone;
  String? get tableId => _tableId;
  String? get idToken => _idToken;
  String? get photoUrl => _photoUrl ?? _firebaseUser?.photoURL;
  bool get isLoggedIn => _idToken != null || _isGuest;
  bool get isGuest => _isGuest;
  List<String> get diets => List.unmodifiable(_diets);
  List<String> get allergies => List.unmodifiable(_allergies);
  List<NotificationModel> get notifications => List.unmodifiable(_notifications);
  int get unreadNotificationsCount => _unreadNotificationsCount;
  int get fidelityPoints => _fidelityPoints;
  bool get hasDiscount => _fidelityPoints >= 10;


  List<String> get preferences => List.unmodifiable(_preferences);
  bool get isAuthenticated => _idToken != null && !_isGuest;
  void setTableId(String tableId) {
  _tableId = tableId;
  notifyListeners();
}

Future<void> loadFidelityPoints() async {
    if (_isGuest || _idToken == null) {
      _fidelityPoints = 0;
      return;
    }

    try {
      debugPrint('Loading fidelity points...');
      final response = await http.get(
        Uri.parse('$_baseUrl/table/fidelity/points/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_idToken',
        },
      );

      debugPrint('Fidelity points response: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _fidelityPoints = data['points'] ?? 0;
        debugPrint('Fidelity points loaded: $_fidelityPoints');
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading fidelity points: $e');
      _fidelityPoints = 0;
    }
  }
Future<bool> login(String identifier, String password) async {
  try {
    debugPrint('Tentative de connexion pour: $identifier');
    
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/client/login/'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'identifier': identifier,
        'password': password,
      }),
    );

    debugPrint('Réponse Django: ${response.statusCode}');
    debugPrint('Corps de la réponse: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      
      if (data['success'] == true) {
        _idToken = data['id_token'];
        _refreshToken = data['refresh_token'];
        
        debugPrint('Tokens reçus, chargement des données utilisateur...');
        
        // Load user data immediately after getting tokens
        await _loadUserDataFromBackend();
        
        debugPrint('Connexion réussie avec données chargées');
        return true;
      }
    }
    return false;
  } catch (e) {
    debugPrint('Erreur de connexion: $e');
    return false;
  }
}

  // Helper method to handle Firebase authentication after Django success
  Future<void> _signInWithCustomToken(String uid) async {
    try {
      // Since we have the ID token from Django, we'll create a simulated Firebase state
      // In a production app, you might want to use Firebase Custom Tokens
      // For now, we'll manually trigger the auth state
      
      // This is a simplified approach - in production, you'd want to:
      // 1. Have Django create a Firebase Custom Token
      // 2. Use signInWithCustomToken() here
      
      // For now, we'll just store the user info and simulate the auth state
      _firebaseUser = _auth.currentUser; // This might be null, which is OK for now
      
      debugPrint('Firebase auth state configuré pour UID: $uid');
    } catch (e) {
      debugPrint('Erreur lors de la configuration de l\'état Firebase: $e');
      throw e;
    }
  }
  void enterAsGuest() async {
    try {
      final success = await loginAsGuest();
      if (!success) {
        _isGuest = true;
        _nomUtilisateur = 'Invité';
        _fidelityPoints = 0; // Add this line
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error in enterAsGuest: $e');
      _isGuest = true;
      _nomUtilisateur = 'Invité';
      _fidelityPoints = 0; // Add this line
      notifyListeners();
    }
  }

  Future<bool> register(String email, String password, String username, String phone) async {
    try {
      debugPrint('Tentative d\'inscription pour $email');
      
      // 1. Création du compte Firebase
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email, 
        password: password
      );
      debugPrint('Compte Firebase créé: ${userCredential.user?.uid}');
      
      // 2. Mise à jour du nom d'affichage
      await userCredential.user?.updateDisplayName(username);
      debugPrint('Nom d\'utilisateur mis à jour');
      
      // 3. Enregistrement dans le backend Django
      final token = await userCredential.user?.getIdToken();
      debugPrint('Token Firebase obtenu');
      
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/client/signup/step1/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'firebase_uid': userCredential.user?.uid,
          'email': email,
          'username': username,
          'phoneNumber': phone,
        }),
      );

      debugPrint('Réponse Django: ${response.statusCode} ${response.body}');

      if (response.statusCode == 201) {
        // Chargement des données utilisateur après inscription réussie
        await _loadUserDataFromBackend();
        return true;
      } else {
        // Annulation si Django échoue
        await userCredential.user?.delete();
        throw Exception('Erreur Django: ${response.statusCode} - ${response.body}');
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('Erreur Firebase [${e.code}]: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Erreur d\'inscription: $e');
      rethrow;
    }
  }


Future<void> updatePhoneNumber(String phone) async {
  if (!isLoggedIn) return;

  try {
    debugPrint('Attempting to update phone to: $phone');
    final response = await http.put(
      Uri.parse('$_baseUrl/table/profile/update/'),
      headers: {
        'Content-Type': 'application/json', // Ensure this is present
        'Authorization': 'Bearer $_idToken',
      },  
      body: jsonEncode({
        'phoneNumber': phone,
      }),
    );

    debugPrint('Phone update response: ${response.statusCode}');
    debugPrint('Response headers: ${response.headers}'); // Add this
    debugPrint('Response body: ${response.body}');

    if (response.statusCode == 200) {
      _phone = phone;
      notifyListeners();
    } else {
      throw Exception('Failed to update phone: ${response.body}');
    }
  } catch (e) {
    debugPrint('Error updating phone: $e');
    rethrow; // Add this to propagate the error
  }
}

// Add this new method to save personal info during registration
Future<void> savePersonalInfo({
  required String gender,
  required DateTime birthdate,
}) async {
  try {
    _gender = gender;
    _birthdate = birthdate;
    
    if (isLoggedIn) {
      final response = await http.put(
        Uri.parse('$_baseUrl/table/profile/update/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_idToken',
        },
        body: jsonEncode({
          'gender': gender,
          'birthdate': birthdate.toIso8601String().split('T')[0], // YYYY-MM-DD format
        }),
      );

      debugPrint('Personal info save response: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception('Échec de la sauvegarde des informations personnelles: ${response.body}');
      }
    }
    
    notifyListeners();
  } catch (e) {
    debugPrint('Erreur de sauvegarde des informations personnelles: $e');
    rethrow;
  }
}

Future<void> updateAllergies(List<String> allergies) async {
  if (!isLoggedIn) return;

  try {
    debugPrint('Updating allergies: $allergies');
    final response = await http.put(
      Uri.parse('$_baseUrl/table/allergies/update/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_idToken',
      },
      body: jsonEncode({
        'allergies': allergies,
      }),
    );

    debugPrint('Update allergies response: ${response.statusCode}');
    debugPrint('Response body: ${response.body}');

    if (response.statusCode == 200) {
      _allergies
        ..clear()
        ..addAll(allergies.where((a) => a.trim().isNotEmpty));
      notifyListeners();
    } else {
      throw Exception('Failed to update allergies: ${response.body}');
    }
  } catch (e) {
    debugPrint('Error updating allergies: $e');
    rethrow;
  }
}

  Future<void> updatePreferences(List<String> preferences) async {
    _preferences
      ..clear()
      ..addAll(preferences.where((p) => p.trim().isNotEmpty));
    
    if (isLoggedIn) {
      try {
        await http.patch(
          Uri.parse('$_baseUrl/users/${_firebaseUser?.uid ?? 'current'}/preferences/'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_idToken',
          },
          body: jsonEncode({
            'preferences': _preferences,
          }),
        );
        notifyListeners();
      } catch (e) {
        debugPrint('Erreur de mise à jour des préférences: $e');
        rethrow;
      }
    }
  }

 Future<void> updateDiets(List<String> diets) async {
  if (!isLoggedIn) return;

  try {
    debugPrint('Updating dietary restrictions: $diets');
    final response = await http.put(
      Uri.parse('$_baseUrl/table/restrictions/update/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_idToken',
      },
      body: jsonEncode({
        'restrictions': diets,
      }),
    );

    debugPrint('Update restrictions response: ${response.statusCode}');
    debugPrint('Response body: ${response.body}');

    if (response.statusCode == 200) {
      _diets
        ..clear()
        ..addAll(diets.where((d) => d.trim().isNotEmpty));
      notifyListeners();
    } else {
      throw Exception('Failed to update dietary restrictions: ${response.body}');
    }
  } catch (e) {
    debugPrint('Error updating dietary restrictions: $e');
    rethrow;
  }
}

 Future<void> _loadUserDataFromBackend() async {
    if (_idToken == null) {
      debugPrint('No token available for loading user data');
      return;
    }
    
    try {
      debugPrint('Loading user data from backend...');
      final response = await http.get(
        Uri.parse('$_baseUrl/table/profile/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_idToken',
        },
      );

      debugPrint('Load user data response: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        _nomUtilisateur = data['username'];
        _email = data['email'];
        _phone = data['phone_number'];
        _photoUrl = data['photo_url'];
        _gender = data['gender'];
        
        if (data['birthdate'] != null && data['birthdate'].toString().isNotEmpty) {
          try {
            _birthdate = DateTime.parse(data['birthdate']);
          } catch (e) {
            debugPrint('Erreur parsing birthdate: $e');
          }
        }
        
        _diets.clear();
        _allergies.clear();
        _preferences.clear();
        
        _diets.addAll(List<String>.from(data['restrictions'] ?? []));
        _allergies.addAll(List<String>.from(data['allergies'] ?? []));
        _preferences.addAll(List<String>.from(data['preferences'] ?? []));
        
        debugPrint('User data loaded successfully');
        debugPrint('Username: $_nomUtilisateur');
        debugPrint('Email: $_email');
        debugPrint('Phone: $_phone');
        
        // Load fidelity points after loading user data
        await loadFidelityPoints();
        
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  // Update your _clearLocalData method:
  void _clearLocalData() {
    _nomUtilisateur = null;
    _email = null;
    _phone = null;
    _photoUrl = null;
    _gender = null;
    _birthdate = null;
    _fidelityPoints = 0; // Add this line
    _diets.clear();
    _allergies.clear();
    _tableId = null;
    _preferences.clear();
  }




  bool hasAllergy(String allergy) => _allergies.contains(allergy);
  bool hasDiet(String diet) => _diets.contains(diet);
  bool hasPreference(String preference) => _preferences.contains(preference);
  bool get hasAllergies => _allergies.isNotEmpty;
  bool get hasDiets => _diets.isNotEmpty;
  bool get hasPreferences => _preferences.isNotEmpty;


 Future<void> logout() async {
  try {
    if (_isGuest) {
      // For guest users, just clear local data
      debugPrint('Logging out guest user');
      
      // If guest was signed in with Firebase, sign out
      if (_firebaseUser != null) {
        await _auth.signOut();
        debugPrint('Firebase guest sign out successful');
      }
    } else {
      // Regular user logout with Django API call
      if (_idToken != null) {
        final response = await http.post(
          Uri.parse('$_baseUrl/auth/logout/'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_idToken',
          },
        );
        
        if (response.statusCode == 200) {
          debugPrint('Déconnexion Django réussie');
        } else {
          debugPrint('Erreur déconnexion Django: ${response.statusCode}');
        }
      }
      
      // Sign out from Firebase
      await _auth.signOut();
      debugPrint('Déconnexion Firebase réussie');
    }
  } catch (e) {
    debugPrint('Erreur lors de la déconnexion: $e');
  }
  
  // Clear all local data
  _isGuest = false;
  _idToken = null;
  _refreshToken = null;
  _firebaseUser = null;
  _clearLocalData();
  notifyListeners();
}// In user_service.dart
// Replace the registerStep1 method in your user_service.dart with this:

// Replace the registerStep1 method in your user_service.dart with this:

Future<bool> registerStep1(String email, String password, String username, String phone) async {
  try {
    debugPrint('Starting step 1 registration for $email');
    
    // Generate a temporary UID (we'll use a UUID or a timestamp-based ID)
    final tempUid = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    
    final requestData = {
      'email': email,
      'password': password,
      'password_confirmation': password,
      'username': username,
      'phone_number': phone,
      'firebase_uid': tempUid, // Add the temporary UID
    };

    debugPrint('Sending to Django: ${jsonEncode(requestData)}');

    final response = await http.post(
      Uri.parse('$_baseUrl/auth/client/signup/step1/'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(requestData),
    );

    debugPrint('Response status: ${response.statusCode}');
    debugPrint('Response body: ${response.body}');

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      _firebaseUID = responseData['uid']; // Store the UID created by Django
      return true;
    } else {
      // Try to parse error message
      try {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Registration failed');
      } catch (e) {
        throw Exception('Failed to register: ${response.body}');
      }
    }
  } catch (e) {
    debugPrint('Registration error: $e');
    rethrow;
  }
}
// Add this field to store the Firebase UID
String? _firebaseUID;

// Update the savePersonalInfoStep2 method:
Future<bool> savePersonalInfoStep2({
  required String gender,
  required DateTime birthdate,
}) async {
  try {
    if (_firebaseUID == null) {
      debugPrint('Firebase UID is null!');
      throw Exception('Registration process not properly initialized');
    }

    debugPrint('Sending Step 2 data with UID: $_firebaseUID');
    debugPrint('Gender: $gender');
    debugPrint('Birthdate: $birthdate');

    final formattedDate = "${birthdate.year}-${birthdate.month.toString().padLeft(2, '0')}-${birthdate.day.toString().padLeft(2, '0')}";

    final requestData = {
      'uid': _firebaseUID, // Changed from 'firebase_uid' to 'uid' to match your backend
      'gender': gender,
      'birthdate': formattedDate,
    };

    debugPrint('Request data: $requestData');

    final response = await http.post(
      Uri.parse('$_baseUrl/auth/client/signup/step2/'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(requestData),
    );

    debugPrint('Response status: ${response.statusCode}');
    debugPrint('Response body: ${response.body}');

    if (response.statusCode == 200) {
      _gender = gender;
      _birthdate = birthdate;
      return true;
    } else {
      final error = jsonDecode(response.body)['error'] ?? 'Unknown error';
      throw Exception(error);
    }
  } catch (e) {
    debugPrint('Error in savePersonalInfoStep2: $e');
    rethrow;
  }
}// Update saveAllergiesStep3:
Future<bool> saveAllergiesStep3(List<String> allergies) async {
  try {
    if (_firebaseUID == null) {
      throw Exception('UID manquant - le processus d\'inscription n\'a pas été correctement initialisé');
    }

    debugPrint('Envoi des allergies pour UID: $_firebaseUID');
    debugPrint('Allergies: $allergies');

    final response = await http.post(
      Uri.parse('$_baseUrl/auth/client/signup/step3/'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'uid': _firebaseUID, // Utilisez 'uid' au lieu de 'firebase_uid'
        'allergies': allergies,
      }),
    );

    debugPrint('Réponse étape 3: ${response.statusCode} - ${response.body}');

    if (response.statusCode == 200) {
      _allergies.clear();
      _allergies.addAll(allergies);
      return true;
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['error'] ?? 'Échec de l\'enregistrement des allergies');
    }
  } catch (e) {
    debugPrint('Erreur saveAllergiesStep3: $e');
    rethrow;
  }
}
// Update saveDietsStep4:
Future<bool> saveDietsStep4(List<String> diets) async {
  try {
    if (_firebaseUID == null) {
      throw Exception('UID manquant - inscription non initialisée');
    }

    debugPrint('Envoi des régimes pour UID: $_firebaseUID');
    debugPrint('Régimes: $diets');

    final response = await http.post(
      Uri.parse('$_baseUrl/auth/client/signup/step4/'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'uid': _firebaseUID, // Important: utiliser 'uid' comme clé
        'restrictions': diets, // Note: votre backend attend 'restrictions'
      }),
    );

    debugPrint('Réponse étape 4: ${response.statusCode} - ${response.body}');

    if (response.statusCode == 200) {
      _diets.clear();
      _diets.addAll(diets);
      return true;
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['error'] ?? 'Échec sauvegarde régimes');
    }
  } catch (e) {
    debugPrint('Erreur saveDietsStep4: $e');
    rethrow;
  }
}
Future<bool> loginAsGuest() async {
  try {
    debugPrint('Starting guest login...');
    
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/guest/login/'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    debugPrint('Guest login response: ${response.statusCode}');
    debugPrint('Response body: ${response.body}');

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      
      // Store guest information
      _nomUtilisateur = data['username'];
      _isGuest = true;
      
      // If you get custom_token, sign in with Firebase
      if (data['custom_token'] != null) {
        try {
          final userCredential = await _auth.signInWithCustomToken(data['custom_token']);
          _firebaseUser = userCredential.user;
          debugPrint('Firebase guest auth successful');
        } catch (e) {
          debugPrint('Firebase guest auth failed: $e');
          // Continue anyway - guest mode can work without Firebase
        }
      }
      
      debugPrint('Guest login successful with username: ${_nomUtilisateur}');
      notifyListeners();
      return true;
    } else {
      debugPrint('Guest login failed: ${response.body}');
      return false;
    }
  } catch (e) {
    debugPrint('Guest login error: $e');
    return false;
  }
}
// Add this method to your UserService class

Future<bool> createAssistanceRequest(String tableId) async {
  if (!isLoggedIn || isGuest) {
    debugPrint('Cannot create assistance request - user not logged in or is guest');
    return false;
  }

  try {
    debugPrint('Creating assistance request for table: $tableId');
    
    final response = await http.post(
      Uri.parse('http://127.0.0.1:8000/api/table/assistance/create/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_idToken',
      },
      body: jsonEncode({
        'table_id': tableId,
      }),
    );

    debugPrint('Assistance request response: ${response.statusCode}');
    debugPrint('Response body: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      debugPrint('Assistance request created with ID: ${data['id']}');
      return true;
    } else {
      debugPrint('Failed to create assistance request: ${response.statusCode} - ${response.body}');
      return false;
    }
  } catch (e) {
    debugPrint('Error creating assistance request: $e');
    return false;
  }
}
// Update completeRegistrationStep5:
Future<bool> completeRegistrationStep5(List<String> preferences) async {
  try {
    if (_firebaseUID == null) {
      throw Exception('UID manquant - inscription non initialisée');
    }

    debugPrint('Finalisation inscription pour UID: $_firebaseUID');
    debugPrint('Préférences: $preferences');

    final response = await http.post(
      Uri.parse('$_baseUrl/auth/client/signup/step5/'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'uid': _firebaseUID,
        'preferences': preferences,
      }),
    );

    debugPrint('Réponse étape 5: ${response.statusCode} - ${response.body}');

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      
      // Sauvegarde des tokens
      _idToken = data['id_token'];
      _refreshToken = data['refresh_token'];
      
      // Connexion Firebase si custom token présent
      if (data['custom_token'] != null) {
        await _auth.signInWithCustomToken(data['custom_token']);
      }
      
      // Chargement des données utilisateur
      await _loadUserDataFromBackend();
      
      // Réinitialisation du UID temporaire
      _firebaseUID = null;
      
      return true;
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['error'] ?? 'Échec finalisation inscription');
    }
  } catch (e) {
    debugPrint('Erreur completeRegistrationStep5: $e');
    rethrow;
  }
}// In user_service.dart
Future<bool> convertGuestToUser(String email, String password, String username, String phone) async {
  if (!_isGuest) {
    debugPrint('User is not a guest, cannot convert');
    return false;
  }

  try {
    debugPrint('Converting guest to registered user...');
    
    // First register normally
    final success = await registerStep1(email, password, username, phone);
    
    if (success) {
      // Clear guest status
      _isGuest = false;
      debugPrint('Guest conversion successful');
      return true;
    }
    
    return false;
  } catch (e) {
    debugPrint('Error converting guest to user: $e');
    return false;
  }
}

String _getFirebaseErrorMessage(FirebaseAuthException e) {
  switch (e.code) {
    case 'email-already-in-use':
      return 'This email is already in use';
    case 'invalid-email':
      return 'Invalid email address';
    case 'weak-password':
      return 'Password should be at least 6 characters';
    case 'operation-not-allowed':
      return 'Operation not allowed';
    default:
      return 'Authentication failed: ${e.message}';
  }
}
Future<List<NotificationModel>> loadNotifications() async {
  if (!isLoggedIn || isGuest) {
    debugPrint('Cannot load notifications - user not logged in or is guest');
    return [];
  }

  try {
    debugPrint('Loading notifications from backend...');
    
    final response = await http.get(
      Uri.parse('$_baseUrl/table/notifications/'),
      headers: {
        'Content-Type': 'application/json; charset=utf-8',  // Added charset
        'Accept': 'application/json; charset=utf-8',        // Added charset
        'Authorization': 'Bearer $_idToken',
      },
    );

    debugPrint('Notifications response: ${response.statusCode}');
    debugPrint('Response headers: ${response.headers}');

    if (response.statusCode == 200) {
      // FIXED: Properly decode UTF-8 bytes first, then parse JSON
      final String decodedBody = utf8.decode(response.bodyBytes);
      debugPrint('Decoded response body: $decodedBody');
      
      final List<dynamic> data = jsonDecode(decodedBody);
      
      _notifications = data.map((json) => NotificationModel.fromJson(json)).toList();
      
      // Debug: Print first notification to verify encoding
      if (_notifications.isNotEmpty) {
        debugPrint('First notification title: ${_notifications.first.title}');
        debugPrint('First notification message: ${_notifications.first.message}');
      }
      
      // Update unread count
      _unreadNotificationsCount = _notifications.where((n) => !n.read).length;
      
      debugPrint('Loaded ${_notifications.length} notifications, ${_unreadNotificationsCount} unread');
      
      notifyListeners();
      return _notifications;
    } else {
      debugPrint('Failed to load notifications: ${response.statusCode} - ${response.body}');
      throw Exception('Failed to load notifications: ${response.body}');
    }
  } catch (e) {
    debugPrint('Error loading notifications: $e');
    throw e;
  }
}
Future<bool> markNotificationAsRead(String notificationId) async {
  if (!isLoggedIn || isGuest) {
    debugPrint('Cannot mark notification as read - user not logged in or is guest');
    return false;
  }

  try {
    debugPrint('Marking notification $notificationId as read...');
    
    final response = await http.patch(
      Uri.parse('$_baseUrl/table//notifications/$notificationId/read/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_idToken',
      },
    );

    debugPrint('Mark as read response: ${response.statusCode}');

    if (response.statusCode == 200) {
      // Update local notification
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(read: true);
        _unreadNotificationsCount = _notifications.where((n) => !n.read).length;
        notifyListeners();
      }
      
      debugPrint('Notification marked as read successfully');
      return true;
    } else {
      debugPrint('Failed to mark notification as read: ${response.statusCode} - ${response.body}');
      return false;
    }
  } catch (e) {
    debugPrint('Error marking notification as read: $e');
    return false;
  }
}

/// Mark all notifications as read
Future<bool> markAllNotificationsAsRead() async {
  if (!isLoggedIn || isGuest) {
    debugPrint('Cannot mark all notifications as read - user not logged in or is guest');
    return false;
  }

  try {
    debugPrint('Marking all notifications as read...');
    
    final response = await http.patch(
      Uri.parse('$_baseUrl/table/notifications/mark-all-read/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_idToken',
      },
    );

    debugPrint('Mark all as read response: ${response.statusCode}');

    if (response.statusCode == 200) {
      // Update all local notifications
      _notifications = _notifications.map((n) => n.copyWith(read: true)).toList();
      _unreadNotificationsCount = 0;
      notifyListeners();
      
      debugPrint('All notifications marked as read successfully');
      return true;
    } else {
      debugPrint('Failed to mark all notifications as read: ${response.statusCode} - ${response.body}');
      return false;
    }
  } catch (e) {
    debugPrint('Error marking all notifications as read: $e');
    return false;
  }
}

/// Delete a notification
Future<bool> deleteNotification(String notificationId) async {
  if (!isLoggedIn || isGuest) {
    debugPrint('Cannot delete notification - user not logged in or is guest');
    return false;
  }

  try {
    debugPrint('Deleting notification $notificationId...');
    
    final response = await http.delete(
      Uri.parse('$_baseUrl/table/notifications/$notificationId/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_idToken',
      },
    );

    debugPrint('Delete notification response: ${response.statusCode}');

    if (response.statusCode == 200 || response.statusCode == 204) {
      // Remove from local list
      final removedNotification = _notifications.firstWhere((n) => n.id == notificationId);
      _notifications.removeWhere((n) => n.id == notificationId);
      
      // Update unread count if the deleted notification was unread
      if (!removedNotification.read) {
        _unreadNotificationsCount--;
      }
      
      notifyListeners();
      
      debugPrint('Notification deleted successfully');
      return true;
    } else {
      debugPrint('Failed to delete notification: ${response.statusCode} - ${response.body}');
      return false;
    }
  } catch (e) {
    debugPrint('Error deleting notification: $e');
    return false;
  }
}

/// Clear all notifications locally (for logout)
void _clearNotifications() {
  _notifications.clear();
  _unreadNotificationsCount = 0;
}


}
class NotificationModel {
  final String id;
  final String title;
  final String message;
  final String createdAt;
  final bool read;
  final String type;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.read,
    required this.type,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
      read: json['read'] ?? false,
      type: json['type']?.toString() ?? 'general',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'created_at': createdAt,
      'read': read,
      'type': type,
    };
  }

  NotificationModel copyWith({
    String? id,
    String? title,
    String? message,
    String? createdAt,
    bool? read,
    String? type,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      read: read ?? this.read,
      type: type ?? this.type,
    );
  }
}