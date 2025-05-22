part of 'profile_bloc.dart';

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
    
  });

  final Username username;
  final Email email;
  final PhoneNumber phoneNumber;
  final String? gender;
  final DateTime? dateOfBirth;
  final String? profileImage; 
  final String? tempProfileImage;  // 
  final FormzSubmissionStatus status;
  final bool isValid;
  final String? errorMessage;
  final List<String> allergies; 

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
      
    );
  }

 
  String? get displayProfileImage => tempProfileImage ?? profileImage;

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
    
  ];
}