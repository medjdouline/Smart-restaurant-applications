import 'package:equatable/equatable.dart';
 import 'package:good_taste/data/models/personal_info_model.dart';
 
 enum PersonalInfoStatus { initial, valid, invalid, loading, success, failure }
 
 class PersonalInfoState extends Equatable {
   final PersonalInfo personalInfo;
   final PersonalInfoStatus status;
   final String? errorMessage;
 
   const PersonalInfoState({
     this.personalInfo = const PersonalInfo(),
     this.status = PersonalInfoStatus.initial,
     this.errorMessage,
   });
 
   PersonalInfoState copyWith({
     PersonalInfo? personalInfo,
     PersonalInfoStatus? status,
     String? errorMessage,
   }) {
     return PersonalInfoState(
       personalInfo: personalInfo ?? this.personalInfo,
       status: status ?? this.status,
       errorMessage: errorMessage ?? this.errorMessage,
     );
   }
 
   bool get isFormValid {
     final dateOfBirth = personalInfo.dateOfBirth;
     final gender = personalInfo.gender;
     
     if (dateOfBirth == null) return false;
     if (gender == null || gender.isEmpty) return false;
     
     
     final today = DateTime.now();
     final difference = today.difference(dateOfBirth).inDays;
     final age = difference / 365;
     
     return age >= 13;
   }
 
   @override
   List<Object?> get props => [personalInfo, status, errorMessage];
 }