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
class ProfileFidelityPointsLoaded extends ProfileEvent {}
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

class PhoneNumberSubmitted extends ProfileEvent {
  const PhoneNumberSubmitted(this.phoneNumber);

  final String phoneNumber;

  @override
  List<Object> get props => [phoneNumber];
}

// NEW: Allergies-specific events
class ProfileAllergiesLoaded extends ProfileEvent {}

class ProfileAllergyToggled extends ProfileEvent {
  final String allergy;
  const ProfileAllergyToggled(this.allergy);

  @override
  List<Object> get props => [allergy];
}

class ProfileAllergiesSubmitted extends ProfileEvent {}

// NEW: Regimes-specific events
class ProfileRestrictionsLoaded extends ProfileEvent {}

class ProfileRestrictionToggled extends ProfileEvent {
  final String restriction;
  const ProfileRestrictionToggled(this.restriction);

  @override
  List<Object> get props => [restriction];
}

class ProfileRestrictionsSubmitted extends ProfileEvent {}