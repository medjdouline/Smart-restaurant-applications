import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:good_taste/data/models/user.dart';
import 'package:good_taste/data/models/allergies_model.dart';
import 'package:good_taste/data/models/regime_model.dart';
import 'package:good_taste/data/repositories/auth_repository.dart';
import 'package:good_taste/data/repositories/allergies_repository.dart';
import 'package:good_taste/data/repositories/regime_repository.dart';
import 'package:logging/logging.dart';
import 'dart:io';

part 'user_event.dart';
part 'user_state.dart';

class UserBloc extends Bloc<UserEvent, UserState> {
  final AuthRepository _authRepository;
  final AllergiesRepository _allergiesRepository;
  final RegimeRepository _regimeRepository;
  final Logger _logger = Logger('UserBloc');

  UserBloc({
    required AuthRepository authRepository,
    required AllergiesRepository allergiesRepository,
    required RegimeRepository regimeRepository,
  }) : _authRepository = authRepository,
       _allergiesRepository = allergiesRepository,
       _regimeRepository = regimeRepository,
       super(UserInitial()) {
    on<UserLoadRequested>(_onUserLoadRequested);
    on<UserProfileUpdated>(_onUserProfileUpdated);
    on<UserDateOfBirthChanged>(_onUserDateOfBirthChanged);
    on<UserGenderChanged>(_onUserGenderChanged);
    on<UserProfileImageChanged>(_onUserProfileImageChanged);
    on<UserAllergiesChanged>(_onUserAllergiesChanged);
    on<UserRegimesChanged>(_onUserRegimesChanged);
    on<UserPersonalInfoSubmitted>(_onUserPersonalInfoSubmitted);
  }

  void _onUserLoadRequested(
    UserLoadRequested event,
    Emitter<UserState> emit,
  ) async {
    try {
      _logger.info('UserLoadRequested: Loading user from repository');
      final user = _authRepository.getCurrentUser();
      
      if (user.id.isNotEmpty) {
      
        final allergies = await _allergiesRepository.getAllergies(userId: user.id);
        final allergiesModel = AllergiesModel(allergies: allergies);
        
    
        final regimes = await _regimeRepository.getRegimes(userId: user.id);
        final regimesModel = RegimeModel(regimes: regimes);
        
        
        final updatedUser = User(
          id: user.id,
          email: user.email,
          name: user.name,
          profileImage: user.profileImage,
          phoneNumber: user.phoneNumber,
          gender: user.gender,
          dateOfBirth: user.dateOfBirth,
          allergies: allergiesModel,
          regimes: regimesModel,
        );
        
        _logger.info('User loaded: ${updatedUser.name}, email: ${updatedUser.email}, allergies: ${updatedUser.allergies.allergies}, regimes: ${updatedUser.regimes.regimes}');
        emit(UserLoaded(updatedUser));
      } else {
        _logger.info('User loaded: ${user.name}, email: ${user.email}, gender: ${user.gender}');
        emit(UserLoaded(user));
      }
    } catch (e) {
      _logger.severe('Error loading user: $e');
      emit(UserLoadFailure(e.toString()));
    }
  }

  void _onUserProfileUpdated(
    UserProfileUpdated event,
    Emitter<UserState> emit,
  ) async {
    _logger.info('UserProfileUpdated: Updating user profile');
    emit(UserUpdateInProgress());
    try {
      await _authRepository.updateUserProfile(
        name: event.name,
        email: event.email,
        phoneNumber: event.phoneNumber,
        gender: event.gender,
        dateOfBirth: event.dateOfBirth,
        profileImage: event.profileImage,
        allergies: event.allergies,
        regimes: event.regimes,
      );
      
      final updatedUser = _authRepository.getCurrentUser();
      
      if (event.allergies != null) {
        await _allergiesRepository.saveAllergies(
          event.allergies!.allergies,
          userId: updatedUser.id,
        );
      }
      

      if (event.regimes != null) {
        await _regimeRepository.saveRegimes(
          event.regimes!.regimes,
          userId: updatedUser.id,
        );
      }
      
      _logger.info('Profile updated successfully: ${updatedUser.name}');
      emit(UserLoaded(updatedUser));
    } catch (e) {
      _logger.severe('Error updating profile: $e');
      emit(UserUpdateFailure(e.toString()));
    }
  }
  
  void _onUserDateOfBirthChanged(
    UserDateOfBirthChanged event,
    Emitter<UserState> emit,
  ) {
    final currentState = state;
    if (currentState is UserLoaded) {
      _logger.info('UserDateOfBirthChanged: ${event.dateOfBirth}');
      

      final isValid = _authRepository.isValidAge(event.dateOfBirth);
      
      if (!isValid) {
        _logger.warning('Invalid age: user is under 13 years old');
        emit(UserInvalid(
          currentState.user, 
          'Vous devez avoir au moins 13 ans pour utiliser cette application.'
        ));
        return;
      }
      
      final updatedUser = currentState.user.copyWith(dateOfBirth: event.dateOfBirth);
      emit(UserLoaded(updatedUser));
    }
  }
  
  void _onUserGenderChanged(
    UserGenderChanged event,
    Emitter<UserState> emit,
  ) {
    final currentState = state;
    if (currentState is UserLoaded) {
      _logger.info('UserGenderChanged: ${event.gender}');
      
      final updatedUser = currentState.user.copyWith(gender: event.gender);
      emit(UserLoaded(updatedUser));
    }
  }
  
  void _onUserProfileImageChanged(
    UserProfileImageChanged event,
    Emitter<UserState> emit,
  ) async {
    final currentState = state;
    if (currentState is UserLoaded) {
      try {
        _logger.info('UserProfileImageChanged: Processing new image');
        

        final fileSize = await event.profileImage.length();
        if (fileSize > 5 * 1024 * 1024) {
          _logger.warning('Invalid image: file size exceeds 5MB');
          emit(UserInvalid(
            currentState.user,
            'L\'image est trop volumineuse. Maximum 5 Mo.',
          ));
          return;
        }
        
        final updatedUser = currentState.user.copyWith(profileImage: event.profileImage.path);
        emit(UserLoaded(updatedUser));
      } catch (e) {
        _logger.severe('Error processing image: $e');
        emit(UserInvalid(
          currentState.user,
          'Format d\'image non valide.',
        ));
      }
    }
  }
  
  void _onUserAllergiesChanged(
    UserAllergiesChanged event,
    Emitter<UserState> emit,
  ) {
    final currentState = state;
    if (currentState is UserLoaded) {
      _logger.info('UserAllergiesChanged: ${event.allergies.allergies}');
      
      final updatedUser = currentState.user.copyWith(allergies: event.allergies);
      emit(UserLoaded(updatedUser));
    }
  }
  
  void _onUserRegimesChanged(
    UserRegimesChanged event,
    Emitter<UserState> emit,
  ) {
    final currentState = state;
    if (currentState is UserLoaded) {
      _logger.info('UserRegimesChanged: ${event.regimes.regimes}');
      
      final updatedUser = currentState.user.copyWith(regimes: event.regimes);
      emit(UserLoaded(updatedUser));
    }
  }
  
  void _onUserPersonalInfoSubmitted(
    UserPersonalInfoSubmitted event,
    Emitter<UserState> emit,
  ) async {
    final currentState = state;
    if (currentState is UserLoaded) {
      _logger.info('UserPersonalInfoSubmitted: Submitting personal info');
      
      final user = currentState.user;
      
      if (user.dateOfBirth == null || user.gender == null || user.gender!.isEmpty) {
        _logger.warning('Invalid submission: missing required fields');
        emit(UserInvalid(
          user,
          'Veuillez compléter toutes les informations requises.',
        ));
        return;
      }
      
     
      if (!_authRepository.isValidAge(user.dateOfBirth!)) {
        _logger.warning('Invalid submission: user is under 13 years old');
        emit(UserInvalid(
          user,
          'Vous devez avoir au moins 13 ans pour utiliser cette application.',
        ));
        return;
      }
      
      emit(UserUpdateInProgress());
      
      try {
     
        await _authRepository.updateUserProfile(
          name: user.name,
          email: user.email,
          phoneNumber: user.phoneNumber,
          gender: user.gender,
          dateOfBirth: user.dateOfBirth,
          profileImage: user.profileImage,
          allergies: user.allergies,
          regimes: user.regimes,
        );
        
        
        await _allergiesRepository.saveAllergies(
          user.allergies.allergies,
          userId: user.id,
        );
        
     
        await _regimeRepository.saveRegimes(
          user.regimes.regimes,
          userId: user.id, 
        );
  
  
        final updatedUser = _authRepository.getCurrentUser();
        _logger.info('Personal info submitted successfully');
        emit(UserLoaded(updatedUser));
      } catch (e) {
        _logger.severe('Error submitting personal info: $e');
        emit(UserUpdateFailure(e.toString()));
      }
    }
  }
}