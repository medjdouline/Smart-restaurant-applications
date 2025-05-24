// profile_bloc.dart
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:formz/formz.dart';
import 'package:good_taste/data/models/username.dart';
import 'package:good_taste/data/models/email.dart';
import 'package:good_taste/data/models/phone_number.dart';
import 'package:good_taste/di/di.dart';
import 'package:good_taste/data/repositories/auth_repository.dart';
import 'package:good_taste/data/repositories/profile_repository.dart';
import 'package:good_taste/data/repositories/allergies_repository.dart';
import 'package:logging/logging.dart';
import 'package:good_taste/data/models/allergies_model.dart';
import 'dart:io';
import 'package:good_taste/data/repositories/regime_repository.dart'; 
import 'package:good_taste/data/models/regime_model.dart'; 

part 'profile_event.dart';
part 'profile_state.dart';


class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final Logger _logger = Logger('ProfileBloc');
  final AuthRepository _authRepository;
  final ProfileRepository _profileRepository;
  final AllergiesRepository _allergiesRepository;
  final RegimeRepository _regimeRepository; // NEW
  
  ProfileBloc({
    required AuthRepository authRepository,
    required ProfileRepository profileRepository,
    required AllergiesRepository allergiesRepository,
    required RegimeRepository regimeRepository, // NEW
  })  : _authRepository = authRepository,
        _profileRepository = profileRepository,
        _allergiesRepository = allergiesRepository,
        _regimeRepository = regimeRepository, // NEW
        super(ProfileState()) {
    on<ProfileLoaded>(_onProfileLoaded);
    on<ProfilePhoneNumberChanged>(_onPhoneNumberChanged);
    on<ProfileImageChanged>(_onProfileImageChanged);
    on<ProfileSubmitted>(_onSubmitted);
    on<PhoneNumberSubmitted>(_onPhoneNumberSubmitted);
    on<ProfileAllergiesUpdated>(_onAllergiesUpdated);
    on<ProfileAllergiesLoaded>(_onAllergiesLoaded);
    on<ProfileAllergiesSubmitted>(_onAllergiesSubmitted);
    on<ProfileAllergyToggled>(_onAllergyToggled);
    on<ProfileRestrictionsLoaded>(_onRestrictionsLoaded);
    on<ProfileRestrictionToggled>(_onRestrictionToggled);
    on<ProfileRestrictionsSubmitted>(_onRestrictionsSubmitted);
  }

  void _onAllergiesUpdated(
    ProfileAllergiesUpdated event,
    Emitter<ProfileState> emit,
  ) {
    emit(state.copyWith(
      allergies: event.allergies,
    ));
  }

  // NEW: Load allergies specifically
  void _onAllergiesLoaded(
    ProfileAllergiesLoaded event,
    Emitter<ProfileState> emit,
  ) async {
    emit(state.copyWith(allergiesStatus: AllergiesLoadingStatus.loading));
    
    try {
      // Try to get from API first
      final response = await _profileRepository.getAllergies();
      
      if (response.success) {
        final allergies = List<String>.from(response.data['allergies'] ?? []);
        _logger.info('Allergies loaded from API: $allergies');
        
        // Save to local storage for backup
        final user = _authRepository.getCurrentUser();
        await _allergiesRepository.saveAllergies(allergies, userId: user.id);
        
        emit(state.copyWith(
          allergies: allergies,
          selectedAllergies: List.from(allergies),
          allergiesStatus: AllergiesLoadingStatus.success,
          allergiesErrorMessage: null,
        ));
      } else {
        // Fall back to local storage
        final user = _authRepository.getCurrentUser();
        final localAllergies = await _allergiesRepository.getAllergies(userId: user.id);
        
        emit(state.copyWith(
          allergies: localAllergies,
          selectedAllergies: List.from(localAllergies),
          allergiesStatus: AllergiesLoadingStatus.success,
          allergiesErrorMessage: null,
        ));
      }
    } catch (e) {
      _logger.severe('Error loading allergies: $e');
      
      // Try local storage as final fallback
      try {
        final user = _authRepository.getCurrentUser();
        final localAllergies = await _allergiesRepository.getAllergies(userId: user.id);
        
        emit(state.copyWith(
          allergies: localAllergies,
          selectedAllergies: List.from(localAllergies),
          allergiesStatus: AllergiesLoadingStatus.success,
          allergiesErrorMessage: 'Données locales chargées',
        ));
      } catch (localError) {
        emit(state.copyWith(
          allergiesStatus: AllergiesLoadingStatus.failure,
          allergiesErrorMessage: 'Erreur lors du chargement des allergies',
        ));
      }
    }
  }
  void _onRestrictionsLoaded(
  ProfileRestrictionsLoaded event,
  Emitter<ProfileState> emit,
) async {
  emit(state.copyWith(restrictionsStatus: RestrictionsLoadingStatus.loading));
  
  try {
    // Try to get from API first
    final response = await _profileRepository.getRestrictions();
    
    if (response.success) {
      final restrictions = List<String>.from(response.data['restrictions'] ?? []);
      _logger.info('Restrictions loaded from API: $restrictions');
      
      // Save to local storage for backup
      final user = _authRepository.getCurrentUser();
      await DependencyInjection.getRegimeRepository().saveRegimes(restrictions, userId: user.id);
      
      emit(state.copyWith(
        restrictions: restrictions,
        selectedRestrictions: List.from(restrictions),
        restrictionsStatus: RestrictionsLoadingStatus.success,
        restrictionsErrorMessage: null,
      ));
    } else {
      // Fall back to local storage
      final user = _authRepository.getCurrentUser();
      final localRestrictions = await DependencyInjection.getRegimeRepository().getRegimes(userId: user.id);
      
      emit(state.copyWith(
        restrictions: localRestrictions,
        selectedRestrictions: List.from(localRestrictions),
        restrictionsStatus: RestrictionsLoadingStatus.success,
        restrictionsErrorMessage: null,
      ));
    }
  } catch (e) {
    _logger.severe('Error loading restrictions: $e');
    
    // Try local storage as final fallback
    try {
      final user = _authRepository.getCurrentUser();
      final localRestrictions = await DependencyInjection.getRegimeRepository().getRegimes(userId: user.id);
      
      emit(state.copyWith(
        restrictions: localRestrictions,
        selectedRestrictions: List.from(localRestrictions),
        restrictionsStatus: RestrictionsLoadingStatus.success,
        restrictionsErrorMessage: 'Données locales chargées',
      ));
    } catch (localError) {
      emit(state.copyWith(
        restrictionsStatus: RestrictionsLoadingStatus.failure,
        restrictionsErrorMessage: 'Erreur lors du chargement des régimes',
      ));
    }
  }
}

void _onRestrictionToggled(
  ProfileRestrictionToggled event,
  Emitter<ProfileState> emit,
) {
  final updatedRestrictions = List<String>.from(state.selectedRestrictions);
  
  if (updatedRestrictions.contains(event.restriction)) {
    updatedRestrictions.remove(event.restriction);
  } else {
    updatedRestrictions.add(event.restriction);
  }
  
  emit(state.copyWith(selectedRestrictions: updatedRestrictions));
}

void _onRestrictionsSubmitted(
  ProfileRestrictionsSubmitted event,
  Emitter<ProfileState> emit,
) async {
  emit(state.copyWith(restrictionsStatus: RestrictionsLoadingStatus.loading));
  
  try {
    final user = _authRepository.getCurrentUser();
    
    // Update via API (NOT signup step 4!)
    final response = await _profileRepository.updateRestrictions(state.selectedRestrictions);
    
    if (!response.success) {
      throw Exception(response.error ?? 'Failed to update restrictions');
    }
    
    // Update local storage
    await DependencyInjection.getRegimeRepository().saveRegimes(state.selectedRestrictions, userId: user.id);
    
    // Update auth repository user
    await _authRepository.updateUserProfile(
      regimes: RegimeModel(regimes: state.selectedRestrictions),
    );
    
    _logger.info('Restrictions updated successfully: ${state.selectedRestrictions}');
    
    emit(state.copyWith(
      restrictions: List.from(state.selectedRestrictions),
      restrictionsStatus: RestrictionsLoadingStatus.success,
      restrictionsErrorMessage: null,
    ));
  } catch (e) {
    _logger.severe('Error updating restrictions: $e');
    emit(state.copyWith(
      restrictionsStatus: RestrictionsLoadingStatus.failure,
      restrictionsErrorMessage: 'Erreur lors de la mise à jour des régimes',
    ));
  }
}

  // NEW: Toggle allergy selection
  void _onAllergyToggled(
    ProfileAllergyToggled event,
    Emitter<ProfileState> emit,
  ) {
    final updatedAllergies = List<String>.from(state.selectedAllergies);
    
    if (updatedAllergies.contains(event.allergy)) {
      updatedAllergies.remove(event.allergy);
    } else {
      updatedAllergies.add(event.allergy);
    }
    
    emit(state.copyWith(selectedAllergies: updatedAllergies));
  }

  // NEW: Submit allergies changes
  void _onAllergiesSubmitted(
    ProfileAllergiesSubmitted event,
    Emitter<ProfileState> emit,
  ) async {
    emit(state.copyWith(allergiesStatus: AllergiesLoadingStatus.loading));
    
    try {
      final user = _authRepository.getCurrentUser();
      
      // Update via API
      final response = await _profileRepository.updateAllergies(state.selectedAllergies);
      
      if (!response.success) {
        throw Exception(response.error ?? 'Failed to update allergies');
      }
      
      // Update local storage
      await _allergiesRepository.saveAllergies(state.selectedAllergies, userId: user.id);
      
      // Update auth repository user
      await _authRepository.updateUserProfile(
        allergies: AllergiesModel(allergies: state.selectedAllergies),
      );
      
      _logger.info('Allergies updated successfully: ${state.selectedAllergies}');
      
      emit(state.copyWith(
        allergies: List.from(state.selectedAllergies),
        allergiesStatus: AllergiesLoadingStatus.success,
        allergiesErrorMessage: null,
      ));
    } catch (e) {
      _logger.severe('Error updating allergies: $e');
      emit(state.copyWith(
        allergiesStatus: AllergiesLoadingStatus.failure,
        allergiesErrorMessage: 'Erreur lors de la mise à jour des allergies',
      ));
    }
  }

  void _onProfileLoaded(
    ProfileLoaded event,
    Emitter<ProfileState> emit,
  ) async {
    try {
      // Récupérer les données depuis l'API
      final response = await _profileRepository.getProfile();
      
      if (!response.success) {
        _logger.warning('Failed to load profile from API: ${response.error}');
        // Fallback sur les données locales
        _loadLocalProfile(emit);
        return;
      }

      final profileData = response.data;
      _logger.info('Profile data loaded from API: $profileData');

      final username = Username.dirty(profileData['username'] ?? '');
      final email = Email.dirty(profileData['email'] ?? '');
      final phoneNumber = PhoneNumber.dirty(profileData['phone_number'] ?? '');
      final allergies = List<String>.from(profileData['allergies'] ?? []);
      final restrictions = List<String>.from(profileData['restrictions'] ?? []);

      emit(state.copyWith(
        username: username,
        email: email,
        phoneNumber: phoneNumber,
        gender: profileData['gender'],
        dateOfBirth: profileData['birthdate'] != null 
            ? DateTime.parse(profileData['birthdate']) 
            : null,
        profileImage: profileData['profile_image'],
        allergies: allergies,
        selectedAllergies: List.from(allergies), // Initialize selected allergies
        isValid: Formz.validate([phoneNumber]),
        status: FormzSubmissionStatus.initial,
        errorMessage: null,
        allergiesStatus: AllergiesLoadingStatus.success,
        restrictions: restrictions,
        selectedRestrictions: List.from(restrictions),
        restrictionsStatus: RestrictionsLoadingStatus.success,
      ));
    } catch (e) {
      _logger.severe('Error loading profile: $e');
      _loadLocalProfile(emit);
    }
  }

  void _loadLocalProfile(Emitter<ProfileState> emit) {
    final user = _authRepository.getCurrentUser();
    _logger.info('Loading local profile data');

    final username = Username.dirty(user.name);
    final email = Email.dirty(user.email);
    final phoneNumber = user.phoneNumber != null 
        ? PhoneNumber.dirty(user.phoneNumber!) 
        : const PhoneNumber.pure();
    final allergies = user.allergies.allergies;
    final restrictions = user.regimes.regimes;
    emit(state.copyWith(
      username: username,
      email: email,
      phoneNumber: phoneNumber,
      gender: user.gender,
      dateOfBirth: user.dateOfBirth,
      profileImage: user.profileImage,
      allergies: allergies,
      selectedAllergies: List.from(allergies), // Initialize selected allergies
      isValid: Formz.validate([phoneNumber]),
      status: FormzSubmissionStatus.initial,
      errorMessage: null,
      allergiesStatus: AllergiesLoadingStatus.success,
      restrictions: restrictions,
      selectedRestrictions: List.from(restrictions),
      restrictionsStatus: RestrictionsLoadingStatus.success,
    ));
  }

  void _onPhoneNumberChanged(
    ProfilePhoneNumberChanged event,
    Emitter<ProfileState> emit,
  ) {
    final phoneNumber = PhoneNumber.dirty(event.phoneNumber);
    emit(
      state.copyWith(
        phoneNumber: phoneNumber,
        isValid: Formz.validate([phoneNumber]),
      ),
    );
  }

  void _onProfileImageChanged(
    ProfileImageChanged event,
    Emitter<ProfileState> emit,
  ) async {
    _logger.info('Changement d\'image de profil temporaire');
    
    final fileSize = await event.profileImage.length();
    if (fileSize > 5 * 1024 * 1024) {
      emit(state.copyWith(
        status: FormzSubmissionStatus.failure,
        errorMessage: 'L\'image est trop volumineuse. Maximum 5 Mo.',
      ));
      return;
    }
    
    final imagePath = event.profileImage.path;
    _logger.info('Nouvelle image de profil temporaire: $imagePath');
    
    emit(state.copyWith(
      tempProfileImage: imagePath,
      errorMessage: null,
    ));
  }

  void _onPhoneNumberSubmitted(
    PhoneNumberSubmitted event,
    Emitter<ProfileState> emit,
  ) async {
    final phoneNumber = PhoneNumber.dirty(event.phoneNumber);
    
    if (!phoneNumber.isValid) {
      emit(state.copyWith(
        status: FormzSubmissionStatus.failure,
        errorMessage: 'Veuillez entrer un numéro de téléphone valide.',
      ));
      return;
    }

    emit(state.copyWith(status: FormzSubmissionStatus.inProgress));

    try {
      final response = await _profileRepository.updateProfile({
        'phone_number': event.phoneNumber,
        if (state.tempProfileImage != null) 'profile_image': state.tempProfileImage,
      });

      if (!response.success) {
        throw Exception(response.error ?? 'Failed to update profile');
      }

      await _authRepository.updateUserProfile(
        phoneNumber: event.phoneNumber,
        profileImage: state.tempProfileImage ?? state.profileImage,
      );

      emit(state.copyWith(
        status: FormzSubmissionStatus.success,
        phoneNumber: phoneNumber,
        profileImage: state.tempProfileImage ?? state.profileImage,
        tempProfileImage: null,
      ));
    } catch (e) {
      _logger.severe('Error updating phone number: $e');
      emit(state.copyWith(
        status: FormzSubmissionStatus.failure,
        errorMessage: 'Échec de la mise à jour: ${e.toString()}',
      ));
    }
  }

  void _onSubmitted(
    ProfileSubmitted event,
    Emitter<ProfileState> emit,
  ) async {
    if (!state.phoneNumber.isValid) {
      emit(state.copyWith(
        status: FormzSubmissionStatus.failure,
        errorMessage: 'Veuillez entrer un numéro de téléphone valide.',
      ));
      return;
    }

    emit(state.copyWith(status: FormzSubmissionStatus.inProgress));

    try {
      final response = await _profileRepository.updateProfile({
        'phone_number': state.phoneNumber.value,
        if (state.tempProfileImage != null) 'profile_image': state.tempProfileImage,
      });

      if (!response.success) {
        throw Exception(response.error ?? 'Failed to update profile');
      }

      await _authRepository.updateUserProfile(
        phoneNumber: state.phoneNumber.value,
        profileImage: state.tempProfileImage ?? state.profileImage,
      );

      emit(state.copyWith(
        status: FormzSubmissionStatus.success,
        profileImage: state.tempProfileImage ?? state.profileImage,
        tempProfileImage: null,
      ));
    } catch (e) {
      _logger.severe('Error updating profile: $e');
      emit(state.copyWith(
        status: FormzSubmissionStatus.failure,
        errorMessage: 'Échec de la mise à jour: ${e.toString()}',
      ));
    }
  }
}