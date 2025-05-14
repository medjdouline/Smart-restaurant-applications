part of 'user_bloc.dart';

abstract class UserEvent extends Equatable {
  const UserEvent();

  @override
  List<Object?> get props => [];
}

class UserLoadRequested extends UserEvent {}

class UserProfileUpdated extends UserEvent {
  final String name;
  final String email;
  final String? phoneNumber;
  final String? gender;
  final DateTime? dateOfBirth;
  final String? profileImage;
  final AllergiesModel? allergies;
  final RegimeModel? regimes;

  const UserProfileUpdated({
    required this.name,
    required this.email,
    this.phoneNumber,
    this.gender,
    this.dateOfBirth,
    this.profileImage,
    this.allergies,
    this.regimes,
  });

  @override
  List<Object?> get props => [name, email, phoneNumber, gender, dateOfBirth, profileImage, allergies, regimes];
}

class UserDateOfBirthChanged extends UserEvent {
  final DateTime dateOfBirth;

  const UserDateOfBirthChanged(this.dateOfBirth);

  @override
  List<Object> get props => [dateOfBirth];
}

class UserGenderChanged extends UserEvent {
  final String gender;

  const UserGenderChanged(this.gender);

  @override
  List<Object> get props => [gender];
}

class UserProfileImageChanged extends UserEvent {
  final File profileImage;

  const UserProfileImageChanged(this.profileImage);

  @override
  List<Object> get props => [profileImage];
}

class UserAllergiesChanged extends UserEvent {
  final AllergiesModel allergies;

  const UserAllergiesChanged(this.allergies);

  @override
  List<Object> get props => [allergies];
}

class UserRegimesChanged extends UserEvent {
  final RegimeModel regimes;

  const UserRegimesChanged(this.regimes);

  @override
  List<Object> get props => [regimes];
}

class UserPersonalInfoSubmitted extends UserEvent {
  const UserPersonalInfoSubmitted();
}