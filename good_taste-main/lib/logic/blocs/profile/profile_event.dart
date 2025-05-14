part of 'profile_bloc.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object> get props => [];
}

class ProfileLoaded extends ProfileEvent {}

class ProfileUsernameChanged extends ProfileEvent {
  const ProfileUsernameChanged(this.username);

  final String username;

  @override
  List<Object> get props => [username];
}

class ProfileEmailChanged extends ProfileEvent {
  const ProfileEmailChanged(this.email);

  final String email;

  @override
  List<Object> get props => [email];
}

class ProfilePhoneNumberChanged extends ProfileEvent {
  const ProfilePhoneNumberChanged(this.phoneNumber);

  final String phoneNumber;

  @override
  List<Object> get props => [phoneNumber];
}

class ProfileImageChanged extends ProfileEvent {
  const ProfileImageChanged(this.profileImage);

  final File profileImage;

  @override
  List<Object> get props => [profileImage];
}

class ProfileSubmitted extends ProfileEvent {}