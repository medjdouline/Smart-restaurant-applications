import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:good_taste/logic/blocs/preference/preference_event.dart';
import 'package:good_taste/logic/blocs/preference/preference_state.dart';
import 'package:good_taste/data/repositories/preferences_repository.dart';
import 'package:good_taste/data/repositories/auth_repository.dart';
import 'package:good_taste/data/models/preferences_model.dart';
import 'package:good_taste/data/api/auth_api_service.dart';
import 'package:good_taste/data/api/api_client.dart';
import 'package:logging/logging.dart';

class PreferenceBloc extends Bloc<PreferenceEvent, PreferenceState> {
  final PreferencesRepository _preferencesRepository;
  final AuthRepository _authRepository;
  final Logger _logger = Logger('PreferenceBloc');
  
  PreferenceBloc({
    PreferencesRepository? preferencesRepository,
    AuthRepository? authRepository,
    AuthApiService? authApiService,
  }) : _preferencesRepository = preferencesRepository ?? PreferencesRepository(),
       _authRepository = authRepository ?? AuthRepository(
         authApiService: authApiService ?? AuthApiService(
           apiClient: ApiClient(baseUrl: 'https://api.your-domain.com/'), // Replace with your actual base URL
         ),
       ),
       super(const PreferenceState()) {
    on<PreferenceToggled>(_onPreferenceToggled);
    on<PreferenceSubmitted>(_onPreferenceSubmitted);
    on<PreferencesLoaded>(_onPreferencesLoaded);
    
    add(const PreferencesLoaded());
  }

  void _onPreferenceToggled(
    PreferenceToggled event,
    Emitter<PreferenceState> emit,
  ) {
    final currentPreferences = List<String>.from(state.selectedPreferences);
    
    if (currentPreferences.contains(event.preference)) {
      currentPreferences.remove(event.preference);
    } else {
      currentPreferences.add(event.preference);
    }
    
    emit(state.copyWith(
      selectedPreferences: currentPreferences,
    ));
  }

// In preference_bloc.dart - modify the _onPreferenceSubmitted method
Future<void> _onPreferenceSubmitted(
  PreferenceSubmitted event,
  Emitter<PreferenceState> emit,
) async {
  emit(state.copyWith(status: PreferenceStatus.loading));

  try {
    final user = _authRepository.getCurrentUser();
    final String userId = user.id;
    
    // Save to API
    await _authRepository.completePreferencesInfo(
      uid: userId,
      preferences: state.selectedPreferences,
    );
    
    // Save to local storage
    await _preferencesRepository.savePreferences(
      state.selectedPreferences, 
      userId: userId
    );
    
    emit(state.copyWith(
      status: PreferenceStatus.success,
      savedPreferences: List.from(state.selectedPreferences),
    ));
  } catch (e) {
    _logger.severe('Erreur lors de la sauvegarde des préférences: $e');
    emit(state.copyWith(
      status: PreferenceStatus.failure,
      errorMessage: 'Une erreur est survenue. Veuillez réessayer.',
    ));
  }
}
  
  Future<void> _onPreferencesLoaded(
    PreferencesLoaded event,
    Emitter<PreferenceState> emit,
  ) async {
    emit(state.copyWith(status: PreferenceStatus.loading));
    
    try {
      final user = _authRepository.getCurrentUser();
      final String userId = user.id;
      
      final preferences = await _preferencesRepository.getPreferences(userId: userId);
      _logger.info('Préférences chargées pour utilisateur $userId: $preferences');
      
      emit(state.copyWith(
        selectedPreferences: preferences,
        savedPreferences: preferences,
        status: PreferenceStatus.initial,
      ));
    } catch (e) {
      _logger.severe('Erreur lors du chargement des préférences: $e');
      emit(state.copyWith(
        status: PreferenceStatus.failure,
        errorMessage: 'Erreur lors du chargement des préférences: $e',
      ));
    }
  }
}