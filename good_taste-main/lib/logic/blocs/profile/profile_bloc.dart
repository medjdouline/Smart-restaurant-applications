// profile_bloc.dart
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:formz/formz.dart';
import 'package:good_taste/data/models/username.dart';
import 'package:good_taste/data/models/email.dart';
import 'package:good_taste/data/models/phone_number.dart';
import 'package:good_taste/data/repositories/auth_repository.dart';
import 'package:good_taste/data/repositories/profile_repository.dart';
import 'package:logging/logging.dart';
import 'dart:io';

part 'profile_event.dart';
part 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final Logger _logger = Logger('ProfileBloc');
  final AuthRepository _authRepository;
  final ProfileRepository _profileRepository;
  
  ProfileBloc({
    required AuthRepository authRepository,
    required ProfileRepository profileRepository,
  })  : _authRepository = authRepository,
        _profileRepository = profileRepository,
        super(ProfileState()) {
    on<ProfileLoaded>(_onProfileLoaded);
    on<ProfilePhoneNumberChanged>(_onPhoneNumberChanged);
    on<ProfileImageChanged>(_onProfileImageChanged);
    on<ProfileSubmitted>(_onSubmitted);
    on<PhoneNumberSubmitted>(_onPhoneNumberSubmitted);
    on<ProfileAllergiesUpdated>(_onAllergiesUpdated);
  }
void _onAllergiesUpdated(
  ProfileAllergiesUpdated event,
  Emitter<ProfileState> emit,
) {
  emit(state.copyWith(
    allergies: event.allergies,
  ));
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
      // FIX: Utiliser phone_number au lieu de phoneNumber
      final phoneNumber = PhoneNumber.dirty(profileData['phone_number'] ?? '');

emit(state.copyWith(
  username: username,
  email: email,
  phoneNumber: phoneNumber,
  gender: profileData['gender'],
  dateOfBirth: profileData['birthdate'] != null 
      ? DateTime.parse(profileData['birthdate']) 
      : null,
  profileImage: profileData['profile_image'],
  allergies: List<String>.from(profileData['allergies'] ?? []), // Add this line
  isValid: Formz.validate([phoneNumber]),
  status: FormzSubmissionStatus.initial,
  errorMessage: null,
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

emit(state.copyWith(
  username: username,
  email: email,
  phoneNumber: phoneNumber,
  gender: user.gender,
  dateOfBirth: user.dateOfBirth,
  profileImage: user.profileImage,
  allergies: user.allergies.allergies, // Add this line
  isValid: Formz.validate([phoneNumber]),
  status: FormzSubmissionStatus.initial,
  errorMessage: null,
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
      // FIX: Utiliser phone_number partout
      final response = await _profileRepository.updateProfile({
        'phone_number': event.phoneNumber, // Consistant avec le backend
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
      // FIX: Utiliser phone_number partout
      final response = await _profileRepository.updateProfile({
        'phone_number': state.phoneNumber.value, // Changé de phoneNumber à phone_number
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