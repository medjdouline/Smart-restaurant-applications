import 'package:http/http.dart' as http;
import 'package:good_taste/data/api/api_client.dart';
import 'package:good_taste/data/api/auth_api_service.dart';
import 'package:good_taste/data/repositories/auth_repository.dart';
import 'package:good_taste/data/repositories/regime_repository.dart';
import 'package:good_taste/data/repositories/preferences_repository.dart';
import 'package:good_taste/data/repositories/allergies_repository.dart'; // NEW: Import
import 'package:shared_preferences/shared_preferences.dart';
import 'package:good_taste/data/services/reservation_service.dart';
import 'package:good_taste/data/api/profile_api_service.dart';
import 'package:good_taste/data/repositories/profile_repository.dart';
import 'package:good_taste/data/api/notification_api_service.dart';
import 'package:good_taste/data/repositories/notification_repository.dart';

class DependencyInjection {
  static SharedPreferences? _prefs;
  DependencyInjection._();
  static final DependencyInjection _instance = DependencyInjection._();
  factory DependencyInjection() => _instance;

  static ApiClient? _apiClient;
  static AuthApiService? _authApiService;
  static AuthRepository? _authRepository;
  static RegimeRepository? _regimeRepository;
  static PreferencesRepository? _preferencesRepository;
  static AllergiesRepository? _allergiesRepository; // NEW
  static ProfileApiService? _profileApiService;
  static ProfileRepository? _profileRepository;
  static NotificationApiService? _notificationApiService;
  static NotificationRepository? _notificationRepository;
  

  static const String apiBaseUrl = 'http://127.0.0.1:8000/api/';

  static ApiClient getApiClient() {
    _apiClient ??= ApiClient(
      baseUrl: apiBaseUrl,
      httpClient: http.Client(),
    );
    return _apiClient!;
  }
  
  static NotificationApiService getNotificationApiService() {
    _notificationApiService ??= NotificationApiService(
      apiClient: getApiClient(),
    );
    return _notificationApiService!;
  }

  static NotificationRepository getNotificationRepository() {
    _notificationRepository ??= NotificationRepository();
    return _notificationRepository!;
  }
  
  static ProfileApiService getProfileApiService() {
    _profileApiService ??= ProfileApiService(
      apiClient: getApiClient(),
    );
    return _profileApiService!;
  }
 
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }
  
  static AuthApiService getAuthApiService() {
    _authApiService ??= AuthApiService(
      apiClient: getApiClient(),
    );
    return _authApiService!;
  }
  
  static ProfileRepository getProfileRepository() {
    _profileRepository ??= ProfileRepository(
      profileApiService: getProfileApiService(),
    );
    return _profileRepository!;
  }
  
  static SharedPreferences getSharedPreferences() {
    if (_prefs == null) throw Exception('SharedPreferences not initialized');
    return _prefs!;
  }
  
  static PreferencesRepository getPreferencesRepository() {
    _preferencesRepository ??= PreferencesRepository();
    return _preferencesRepository!;
  }
  
  static RegimeRepository getRegimeRepository() {
    _regimeRepository ??= RegimeRepository();
    return _regimeRepository!;
  }

  // NEW: Add AllergiesRepository getter
  static AllergiesRepository getAllergiesRepository() {
    _allergiesRepository ??= AllergiesRepository();
    return _allergiesRepository!;
  }

  static ReservationService getReservationService() {
    return ReservationService(
      apiClient: getApiClient(),
      authRepo: getAuthRepository(),
    );
  }

  static AuthRepository getAuthRepository() {
    _authRepository ??= AuthRepository(
      authApiService: getAuthApiService(),
      prefs: getSharedPreferences(),
      apiClient: getApiClient(),
    );
    return _authRepository!;
  }
  

  static void dispose() {
    _apiClient?.dispose();
    _regimeRepository = null;
    _preferencesRepository = null;
    _allergiesRepository = null; // NEW: Add disposal
    _notificationApiService = null;
    _notificationRepository = null;
  }
}