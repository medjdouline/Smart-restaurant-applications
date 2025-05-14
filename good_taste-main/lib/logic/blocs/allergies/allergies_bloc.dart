import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:good_taste/logic/blocs/allergies/allergies_event.dart';
import 'package:good_taste/logic/blocs/allergies/allergies_state.dart';
import 'package:good_taste/data/repositories/allergies_repository.dart';
import 'package:good_taste/data/repositories/auth_repository.dart';
import 'package:good_taste/data/models/allergies_model.dart';

class AllergiesBloc extends Bloc<AllergiesEvent, AllergiesState> {
  final AllergiesRepository _allergiesRepository;
  final AuthRepository _authRepository;
  
  AllergiesBloc({
    required AllergiesRepository allergiesRepository,
    required AuthRepository authRepository,
  }) : _allergiesRepository = allergiesRepository,
      _authRepository = authRepository,
      super(const AllergiesState()) {
    on<AllergyToggled>(_onAllergyToggled);
    on<AllergiesSubmitted>(_onAllergiesSubmitted);
    on<AllergiesLoaded>(_onAllergiesLoaded);
    
  
    add(const AllergiesLoaded());
  }

  Future<void> _onAllergyToggled(
    AllergyToggled event,
    Emitter<AllergiesState> emit,
  ) async {
    emit(state.copyWith(status: AllergiesStatus.loading));
    
    try {
     
      final List<String> updatedAllergies = List.from(state.selectedAllergies);
      
      if (updatedAllergies.contains(event.allergy)) {
        updatedAllergies.remove(event.allergy);
      } else {
        updatedAllergies.add(event.allergy);
      }
      
      emit(state.copyWith(
        selectedAllergies: updatedAllergies,
        status: AllergiesStatus.initial,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AllergiesStatus.failure,
        errorMessage: 'Erreur lors de la mise à jour des allergies: $e',
      ));
    }
  }

  Future<void> _onAllergiesSubmitted(
    AllergiesSubmitted event,
    Emitter<AllergiesState> emit,
  ) async {
    emit(state.copyWith(status: AllergiesStatus.loading));

    try {
     
      final user = _authRepository.getCurrentUser();
      final String userId = user.id;
      
      
      await _allergiesRepository.saveAllergies(state.selectedAllergies, userId: userId);
      
     
      final updatedAllergiesModel = AllergiesModel(allergies: state.selectedAllergies);
      await _authRepository.updateUserProfile(allergies: updatedAllergiesModel);
      
      emit(state.copyWith(
        status: AllergiesStatus.success,
        savedAllergies: List.from(state.selectedAllergies),
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AllergiesStatus.failure,
        errorMessage: 'Une erreur est survenue. Veuillez réessayer.',
      ));
    }
  }
  
  Future<void> _onAllergiesLoaded(
    AllergiesLoaded event,
    Emitter<AllergiesState> emit,
  ) async {
    emit(state.copyWith(status: AllergiesStatus.loading));
    
    try {
    
      final user = _authRepository.getCurrentUser();
      final String userId = user.id;
      
      
      final allergies = await _allergiesRepository.getAllergies(userId: userId);
      
      emit(state.copyWith(
        selectedAllergies: allergies,
        savedAllergies: allergies,
        status: AllergiesStatus.initial,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AllergiesStatus.failure,
        errorMessage: 'Erreur lors du chargement des allergies: $e',
      ));
    }
  }
}