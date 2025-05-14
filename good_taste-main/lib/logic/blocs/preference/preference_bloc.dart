import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:good_taste/logic/blocs/preference/preference_event.dart';
import 'package:good_taste/logic/blocs/preference/preference_state.dart';
import 'package:good_taste/data/repositories/preferences_repository.dart';
import 'package:good_taste/data/repositories/auth_repository.dart';
import 'package:good_taste/data/models/preferences_model.dart';
import 'package:logging/logging.dart';

class PreferenceBloc extends Bloc<PreferenceEvent, PreferenceState> {
  final PreferencesRepository _preferencesRepository;
  final AuthRepository _authRepository;
  final Logger _logger = Logger('PreferenceBloc');
  
  PreferenceBloc({
    PreferencesRepository? preferencesRepository,
    AuthRepository? authRepository,
  }) : _preferencesRepository = preferencesRepository ?? PreferencesRepository(),
       _authRepository = authRepository ?? AuthRepository(),
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

  Future<void> _onPreferenceSubmitted(
    PreferenceSubmitted event,
    Emitter<PreferenceState> emit,
  ) async {
    emit(state.copyWith(status: PreferenceStatus.loading));

    try {
     
      final user = _authRepository.getCurrentUser();
      final String userId = user.id;
      
      _logger.info('Sauvegarde des préférences pour utilisateur $userId: ${state.selectedPreferences}');
      
      
      await _preferencesRepository.savePreferences(state.selectedPreferences, userId: userId);
    
      final updatedPreferencesModel = PreferencesModel(preferences: state.selectedPreferences);
      await _authRepository.updateUserProfile(
        name: user.name,
        email: user.email,
        preferences: updatedPreferencesModel
      );
      
      _logger.info('Préférences sauvegardées avec succès');
      
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