import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:good_taste/logic/blocs/regime/regime_event.dart';
import 'package:good_taste/logic/blocs/regime/regime_state.dart';
import 'package:good_taste/data/repositories/regime_repository.dart';
import 'package:good_taste/data/repositories/auth_repository.dart';
import 'package:good_taste/data/models/regime_model.dart';

class RegimeBloc extends Bloc<RegimeEvent, RegimeState> {
  final RegimeRepository _regimeRepository;
  final AuthRepository _authRepository;
  
  RegimeBloc({
    required RegimeRepository regimeRepository, 
    required AuthRepository authRepository
  }) : _regimeRepository = regimeRepository,
       _authRepository = authRepository,
       super(const RegimeState()) {
    on<RegimeToggled>(_onRegimeToggled);
    on<RegimeSubmitted>(_onRegimeSubmitted);
    on<RegimesLoaded>(_onRegimesLoaded);
    
    // Charger les régimes au démarrage
    add(const RegimesLoaded());
  }

  Future<void> _onRegimeToggled(
    RegimeToggled event,
    Emitter<RegimeState> emit,
  ) async {
    emit(state.copyWith(status: RegimeStatus.loading));
    
    try {
     
      final List<String> updatedRegimes = List.from(state.selectedRegimes);
      
      if (updatedRegimes.contains(event.regime)) {
        updatedRegimes.remove(event.regime);
      } else {
        updatedRegimes.add(event.regime);
      }
      
      emit(state.copyWith(
        selectedRegimes: updatedRegimes,
        status: RegimeStatus.initial,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: RegimeStatus.failure,
        errorMessage: 'Erreur lors de la mise à jour des régimes: $e',
      ));
    }
  }

  Future<void> _onRegimeSubmitted(
    RegimeSubmitted event,
    Emitter<RegimeState> emit,
  ) async {
    emit(state.copyWith(status: RegimeStatus.loading));

    try {
     
      final user = _authRepository.getCurrentUser();
      final String userId = user.id;
      
     
      await _regimeRepository.saveRegimes(state.selectedRegimes, userId: userId);
      
     
      final updatedRegimeModel = RegimeModel(regimes: state.selectedRegimes);
      await _authRepository.updateUserProfile(regimes: updatedRegimeModel);
      
      emit(state.copyWith(
        status: RegimeStatus.success,
        savedRegimes: List.from(state.selectedRegimes), 
      ));
    } catch (e) {
      emit(state.copyWith(
        status: RegimeStatus.failure,
        errorMessage: 'Une erreur est survenue. Veuillez réessayer.',
      ));
    }
  }
  
  Future<void> _onRegimesLoaded(
    RegimesLoaded event,
    Emitter<RegimeState> emit,
  ) async {
    emit(state.copyWith(status: RegimeStatus.loading));
    
    try {
   
      final user = _authRepository.getCurrentUser();
      final String userId = user.id;
      
      
      final regimes = await _regimeRepository.getRegimes(userId: userId);
      
      emit(state.copyWith(
        selectedRegimes: regimes,
        savedRegimes: regimes,
        status: RegimeStatus.initial,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: RegimeStatus.failure,
        errorMessage: 'Erreur lors du chargement des régimes: $e',
      ));
    }
  }
}