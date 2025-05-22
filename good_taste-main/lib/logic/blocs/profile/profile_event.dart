part of 'profile_bloc.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object> get props => [];
}

class ProfileLoaded extends ProfileEvent {}

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
class ProfileAllergiesUpdated extends ProfileEvent {
  final List<String> allergies;
  const ProfileAllergiesUpdated(this.allergies);

  @override
  List<Object> get props => [allergies];
}

// Add the missing PhoneNumberSubmitted event
class PhoneNumberSubmitted extends ProfileEvent {
  const PhoneNumberSubmitted(this.phoneNumber);

  final String phoneNumber;

  @override
  List<Object> get props => [phoneNumber];
}