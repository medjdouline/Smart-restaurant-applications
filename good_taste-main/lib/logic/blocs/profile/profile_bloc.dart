import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:formz/formz.dart';
import 'package:good_taste/data/models/username.dart';
import 'package:good_taste/data/models/email.dart';
import 'package:good_taste/data/models/phone_number.dart';
import 'package:good_taste/data/repositories/auth_repository.dart';
import 'package:logging/logging.dart';
import 'dart:io';

part 'profile_event.dart';
part 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final Logger _logger = Logger('ProfileBloc');
  
  ProfileBloc({required AuthRepository authRepository})
    : _authRepository = authRepository,
      super(ProfileState()) {
    on<ProfileLoaded>(_onProfileLoaded);
    on<ProfileUsernameChanged>(_onUsernameChanged);
    on<ProfileEmailChanged>(_onEmailChanged);
    on<ProfilePhoneNumberChanged>(_onPhoneNumberChanged);
    on<ProfileImageChanged>(_onProfileImageChanged);
    on<ProfileSubmitted>(_onSubmitted);
    
  }

  final AuthRepository _authRepository;

  void _onProfileLoaded(
    ProfileLoaded event,
    Emitter<ProfileState> emit,
  ) {
    final user = _authRepository.getCurrentUser();

    _logger.info('Données utilisateur chargées du repository:');
    _logger.info('Nom: ${user.name}');
    _logger.info('Email: ${user.email}');
    _logger.info('Téléphone: ${user.phoneNumber}');
    
    
    if (user.isEmpty) {
      _logger.warning('Utilisateur vide reçu du repository');
      return;
    }
    
   
    final username = Username.dirty(user.name);
    final email = Email.dirty(user.email);
    final phoneNumber = user.phoneNumber != null 
        ? PhoneNumber.dirty(user.phoneNumber!) 
        : const PhoneNumber.pure();
    

    final newState = state.copyWith(
      username: username,
      email: email,
      phoneNumber: phoneNumber,
      gender: user.gender,
      dateOfBirth: user.dateOfBirth,
      profileImage: user.profileImage,
      tempProfileImage: null, 
      isValid: Formz.validate([username, email, phoneNumber]),
      status: FormzSubmissionStatus.initial,
      errorMessage: null,
    );
    
    emit(newState);
  }

  void _onUsernameChanged(
    ProfileUsernameChanged event,
    Emitter<ProfileState> emit,
  ) {
    final username = Username.dirty(event.username);
    emit(
      state.copyWith(
        username: username,
        isValid: Formz.validate([
          username,
          state.email,
          state.phoneNumber,
        ]),
      ),
    );
  }

  void _onEmailChanged(
    ProfileEmailChanged event,
    Emitter<ProfileState> emit,
  ) {
    final email = Email.dirty(event.email);
    emit(
      state.copyWith(
        email: email,
        isValid: Formz.validate([
          state.username,
          email,
          state.phoneNumber,
        ]),
      ),
    );
  }

  void _onPhoneNumberChanged(
    ProfilePhoneNumberChanged event,
    Emitter<ProfileState> emit,
  ) {
    final phoneNumber = PhoneNumber.dirty(event.phoneNumber);
    emit(
      state.copyWith(
        phoneNumber: phoneNumber,
        isValid: Formz.validate([
          state.username,
          state.email,
          phoneNumber,
        ]),
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

  void _onSubmitted(
    ProfileSubmitted event,
    Emitter<ProfileState> emit,
  ) async {
    if (state.isValid) {
      emit(state.copyWith(status: FormzSubmissionStatus.inProgress));
      try {
     
        final String? finalImagePath = state.tempProfileImage ?? state.profileImage;
        
        await _authRepository.updateUserProfile(
          name: state.username.value,
          email: state.email.value,
          phoneNumber: state.phoneNumber.value,
          gender: state.gender,
          dateOfBirth: state.dateOfBirth,
          profileImage: finalImagePath,
        );
        
        
        emit(state.copyWith(
          status: FormzSubmissionStatus.success,
          profileImage: finalImagePath,
          tempProfileImage: null,  
        ));
      } catch (e) {
        _logger.severe('Erreur lors de la mise à jour du profil: $e');
        emit(state.copyWith(
          status: FormzSubmissionStatus.failure,
          errorMessage: 'Une erreur est survenue lors de la mise à jour du profil.',
        ));
      }
    } else {
      emit(state.copyWith(
        status: FormzSubmissionStatus.failure,
        errorMessage: 'Veuillez remplir correctement tous les champs obligatoires.',
      ));
    }
  }
}