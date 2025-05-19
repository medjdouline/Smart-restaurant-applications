import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:good_taste/data/models/personal_info_model.dart';
import 'package:good_taste/data/api/auth_api_service.dart';
import 'package:good_taste/data/repositories/auth_repository.dart';
import 'personal_info_event.dart';
import 'package:good_taste/data/api/api_client.dart';
import 'personal_info_state.dart';

class PersonalInfoBloc extends Bloc<PersonalInfoEvent, PersonalInfoState> {
  final AuthRepository authRepository;

  PersonalInfoBloc({required this.authRepository}) : super(const PersonalInfoState()) {
    on<DateOfBirthChanged>(_onDateOfBirthChanged);
    on<GenderChanged>(_onGenderChanged);
    on<ProfileImageChanged>(_onProfileImageChanged);
    on<PersonalInfoSubmitted>(_onPersonalInfoSubmitted);
  }

  void _onDateOfBirthChanged(
    DateOfBirthChanged event,
    Emitter<PersonalInfoState> emit,
  ) {
    final updatedInfo = state.personalInfo.copyWith(
      dateOfBirth: event.dateOfBirth,
    );
    
    
    final today = DateTime.now();
    final difference = today.difference(event.dateOfBirth).inDays;
    final age = difference / 365;
    
    if (age < 13) {
      emit(state.copyWith(
        personalInfo: updatedInfo,
        status: PersonalInfoStatus.invalid,
        errorMessage: 'Vous devez avoir au moins 13 ans pour utiliser cette application.',
      ));
      return;
    }
    
    emit(state.copyWith(
      personalInfo: updatedInfo,
      status: _validateForm(updatedInfo) ? PersonalInfoStatus.valid : PersonalInfoStatus.invalid,
      errorMessage: null,
    ));
  }

  bool _validateForm(PersonalInfo info) {
  if (info.dateOfBirth == null) return false;
  if (info.gender == null || info.gender!.isEmpty) return false;
  
  // Calculate age
  final today = DateTime.now();
  final difference = today.difference(info.dateOfBirth!).inDays;
  final age = difference / 365;
  
  return age >= 13;
}

  void _onGenderChanged(
    GenderChanged event,
    Emitter<PersonalInfoState> emit,
  ) {
    final updatedInfo = state.personalInfo.copyWith(
      gender: event.gender,
    );
    
    emit(state.copyWith(
      personalInfo: updatedInfo,
      status: _validateForm(updatedInfo) ? PersonalInfoStatus.valid : PersonalInfoStatus.invalid,
    ));
  }

  Future<void> _onProfileImageChanged(
    ProfileImageChanged event,
    Emitter<PersonalInfoState> emit,
  ) async {
   
    final fileSize = await event.profileImage.length();
    if (fileSize > 5 * 1024 * 1024) {
      emit(state.copyWith(
        status: PersonalInfoStatus.invalid,
        errorMessage: 'L\'image est trop volumineuse. Maximum 5 Mo.',
      ));
      return;
    }
    
    
    try {
      final imageBytes = await event.profileImage.readAsBytes();
      final image = await decodeImageFromList(imageBytes);
      
      
      if (image.width < 100 || image.height < 100) {
        emit(state.copyWith(
          status: PersonalInfoStatus.invalid,
          errorMessage: 'L\'image est trop petite. Minimum 100x100 pixels.',
        ));
        return;
      }
      
      if (image.width > 2000 || image.height > 2000) {
        emit(state.copyWith(
          status: PersonalInfoStatus.invalid,
          errorMessage: 'L\'image est trop grande. Maximum 2000x2000 pixels.',
        ));
        return;
      }
    } catch (e) {
      emit(state.copyWith(
        status: PersonalInfoStatus.invalid,
        errorMessage: 'Format d\'image non valide.',
      ));
      return;
    }
    
   
    final updatedInfo = state.personalInfo.copyWith(
      profileImage: event.profileImage,
    );
    
    emit(state.copyWith(
      personalInfo: updatedInfo,
      status: _validateForm(updatedInfo) ? PersonalInfoStatus.valid : PersonalInfoStatus.invalid,
      errorMessage: null,
    ));
  }

// In the _onPersonalInfoSubmitted method of PersonalInfoBloc
void _onPersonalInfoSubmitted(
  PersonalInfoSubmitted event,
  Emitter<PersonalInfoState> emit,
) async {
  if (!state.isFormValid) {
    emit(state.copyWith(
      status: PersonalInfoStatus.invalid,
      errorMessage: 'Veuillez compléter toutes les informations requises. Vous devez avoir au moins 13 ans.',
    ));
    return;
  }

  emit(state.copyWith(status: PersonalInfoStatus.loading));

  try {
    final currentUid = authRepository.getCurrentUser().id;
    
    final response = await authRepository.completePersonalInfo(
      uid: currentUid,
      dateOfBirth: state.personalInfo.dateOfBirth!,
      gender: state.personalInfo.gender!,
    );

    if (response.success) {
      emit(state.copyWith(status: PersonalInfoStatus.success));
    } else {
      emit(state.copyWith(
        status: PersonalInfoStatus.failure,
        errorMessage: response.error ?? 'Une erreur est survenue',
      ));
    }
  } catch (e) {
    emit(state.copyWith(
      status: PersonalInfoStatus.failure,
      errorMessage: 'Une erreur est survenue. Veuillez réessayer.',
    ));
  }
}
}