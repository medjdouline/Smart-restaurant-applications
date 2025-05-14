import 'dart:io';

class PersonalInfo {
  final DateTime? dateOfBirth;
  final String? gender;
  final File? profileImage;

  const PersonalInfo({
    this.dateOfBirth,
    this.gender,
    this.profileImage,
  });

  PersonalInfo copyWith({
    DateTime? dateOfBirth,
    String? gender,
    File? profileImage,
  }) {
    return PersonalInfo(
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      profileImage: profileImage ?? this.profileImage,
    );
  }
}
