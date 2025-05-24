part of 'profile_bloc.dart';

// NEW: Enum for allergies loading status
enum AllergiesLoadingStatus { initial, loading, success, failure }
enum RestrictionsLoadingStatus { initial, loading, success, failure } // NEW

class ProfileState extends Equatable {
  const ProfileState({
    this.username = const Username.pure(),
    this.email = const Email.pure(),
    this.phoneNumber = const PhoneNumber.pure(),
    this.gender,
    this.dateOfBirth,
    this.profileImage,
    this.tempProfileImage, 
    this.status = FormzSubmissionStatus.initial,
    this.isValid = false,
    this.errorMessage,
    this.allergies = const [],
    this.selectedAllergies = const [], // NEW: For managing allergy selections
    this.allergiesStatus = AllergiesLoadingStatus.initial, // NEW: Separate status for allergies
    this.allergiesErrorMessage, // NEW: Separate error message for allergies
    this.restrictions = const [],
    this.selectedRestrictions = const [],
    this.restrictionsStatus = RestrictionsLoadingStatus.initial,
    this.restrictionsErrorMessage,
  });

  final Username username;
  final Email email;
  final PhoneNumber phoneNumber;
  final String? gender;
  final DateTime? dateOfBirth;
  final String? profileImage; 
  final String? tempProfileImage;
  final FormzSubmissionStatus status;
  final bool isValid;
  final String? errorMessage;
  final List<String> allergies;
  final List<String> selectedAllergies; // NEW
  final AllergiesLoadingStatus allergiesStatus; // NEW
  final String? allergiesErrorMessage; // NEW
  final List<String> restrictions;
  final List<String> selectedRestrictions;
  final RestrictionsLoadingStatus restrictionsStatus;
  final String? restrictionsErrorMessage;

  ProfileState copyWith({
    Username? username,
    Email? email,
    PhoneNumber? phoneNumber,
    String? gender,
    DateTime? dateOfBirth,
    String? profileImage,
    String? tempProfileImage,
    FormzSubmissionStatus? status,
    bool? isValid,
    String? errorMessage,
    List<String>? allergies,
    List<String>? selectedAllergies, // NEW
    AllergiesLoadingStatus? allergiesStatus, // NEW
    String? allergiesErrorMessage, // NEW
    List<String>? restrictions,
    List<String>? selectedRestrictions,
    RestrictionsLoadingStatus? restrictionsStatus,
    String? restrictionsErrorMessage,
  }) {
    return ProfileState(
      username: username ?? this.username,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      profileImage: profileImage ?? this.profileImage,
      tempProfileImage: tempProfileImage ?? this.tempProfileImage,
      status: status ?? this.status,
      isValid: isValid ?? this.isValid,
      errorMessage: errorMessage,
      allergies: allergies ?? this.allergies,
      selectedAllergies: selectedAllergies ?? this.selectedAllergies,
      allergiesStatus: allergiesStatus ?? this.allergiesStatus,
      allergiesErrorMessage: allergiesErrorMessage,
      restrictions: restrictions ?? this.restrictions,
      selectedRestrictions: selectedRestrictions ?? this.selectedRestrictions,
      restrictionsStatus: restrictionsStatus ?? this.restrictionsStatus,
      restrictionsErrorMessage: restrictionsErrorMessage,
    );
  }

  String? get displayProfileImage => tempProfileImage ?? profileImage;

  // NEW: Check if allergies have been modified
  bool get hasAllergiesChanged => 
      selectedAllergies.length != allergies.length ||
      !selectedAllergies.every((allergy) => allergies.contains(allergy));

  bool get hasRestrictionsChanged => 
    selectedRestrictions.length != restrictions.length ||
    !selectedRestrictions.every((restriction) => restrictions.contains(restriction));

  @override
  List<Object?> get props => [
    username, 
    email, 
    phoneNumber, 
    gender, 
    dateOfBirth, 
    profileImage,
    tempProfileImage,
    status, 
    isValid,
    errorMessage,
    allergies,
    selectedAllergies,
    allergiesStatus,
    allergiesErrorMessage,
    restrictions,
    selectedRestrictions,
    restrictionsStatus,
    restrictionsErrorMessage,
  ];
}