import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:good_taste/data/repositories/allergies_repository.dart';
import 'package:good_taste/data/repositories/auth_repository.dart';
import 'package:good_taste/data/models/allergies_model.dart';
import 'package:logging/logging.dart';
import 'package:good_taste/logic/blocs/allergies/allergies_event.dart';
import 'package:good_taste/logic/blocs/allergies/allergies_state.dart';

const List<String> allowedAllergies = [
  'Fraise', 'Fruit exotique', 'Gluten', 'Arachides', 'Noix', 'Lupin',
  'Champignons', 'Moutarde', 'Soja', 'Crustacés', 'Poisson', 'Lactose', 'Œufs'
];

class AllergiesBloc extends Bloc<AllergiesEvent, AllergiesState> {
  final Logger _logger = Logger('AllergiesBloc');
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
    // Validate if it's a custom allergy
    if (!allowedAllergies.contains(event.allergy) && 
        !state.selectedAllergies.contains(event.allergy)) {
      emit(state.copyWith(
        status: AllergiesStatus.failure,
        errorMessage: 'Allergie non valide: ${event.allergy}',
      ));
      return;
    }

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
      _logger.severe('Error toggling allergy: $e');
      emit(state.copyWith(
        status: AllergiesStatus.failure,
        errorMessage: 'Erreur lors de la mise à jour des allergies: $e',
      ));
    }
  }

// In allergies_bloc.dart - Need to update this method
Future<void> _onAllergiesSubmitted(
  AllergiesSubmitted event,
  Emitter<AllergiesState> emit,
) async {
  _logger.info("Starting allergies submission with: ${state.selectedAllergies}");
  emit(state.copyWith(status: AllergiesStatus.loading));

  try {
    // Only call the updateAllergies method, nothing else
    await _authRepository.updateAllergies(state.selectedAllergies);
    
    emit(state.copyWith(
      status: AllergiesStatus.success,
      savedAllergies: state.selectedAllergies, // Update saved allergies to match selected
    ));
    _logger.info("Successfully submitted allergies");
  } catch (e) {
    _logger.severe('Error submitting allergies: $e');
    emit(state.copyWith(
      status: AllergiesStatus.failure,
      errorMessage: e.toString(),
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
        status: AllergiesStatus.initial,
      ));
    } catch (e) {
      _logger.severe('Error loading allergies: $e');
      emit(state.copyWith(
        status: AllergiesStatus.failure,
        errorMessage: 'Erreur lors du chargement des allergies: $e',
      ));
    }
  }
}