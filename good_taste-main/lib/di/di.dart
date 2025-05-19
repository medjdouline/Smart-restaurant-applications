import 'package:http/http.dart' as http;
import 'package:good_taste/data/api/api_client.dart';
import 'package:good_taste/data/api/auth_api_service.dart';
import 'package:good_taste/data/repositories/auth_repository.dart';
import 'package:good_taste/data/repositories/regime_repository.dart';
import 'package:good_taste/data/repositories/preferences_repository.dart';

class DependencyInjection {
  DependencyInjection._();
  static final DependencyInjection _instance = DependencyInjection._();
  factory DependencyInjection() => _instance;

  static ApiClient? _apiClient;
  static AuthApiService? _authApiService;
  static AuthRepository? _authRepository;
  static RegimeRepository? _regimeRepository;
  static PreferencesRepository? _preferencesRepository;

  static const String apiBaseUrl = 'http://127.0.0.1:8000/api/';

  static ApiClient getApiClient() {
    _apiClient ??= ApiClient(
      baseUrl: apiBaseUrl,
      httpClient: http.Client(),
    );
    return _apiClient!;
  }

  static AuthApiService getAuthApiService() {
    _authApiService ??= AuthApiService(
      apiClient: getApiClient(),
    );
    return _authApiService!;
  }
  static PreferencesRepository getPreferencesRepository() {
  _preferencesRepository ??= PreferencesRepository();
  return _preferencesRepository!;
}
  static RegimeRepository getRegimeRepository() {
  _regimeRepository ??= RegimeRepository();
  return _regimeRepository!;
}

  static AuthRepository getAuthRepository() {
    _authRepository ??= AuthRepository(
      authApiService: getAuthApiService(),
    );
    return _authRepository!;
  }

  static void dispose() {
    _apiClient?.dispose();
     _regimeRepository = null; // Add this line
      _preferencesRepository = null; // Add this line
  }
}