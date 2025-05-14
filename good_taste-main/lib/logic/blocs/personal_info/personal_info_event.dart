import 'dart:io';
 import 'package:equatable/equatable.dart';
 
 abstract class PersonalInfoEvent extends Equatable {
   const PersonalInfoEvent();
 
   @override
   List<Object?> get props => [];
 }
 
 class DateOfBirthChanged extends PersonalInfoEvent {
   final DateTime dateOfBirth;
 
   const DateOfBirthChanged(this.dateOfBirth);
 
   @override
   List<Object> get props => [dateOfBirth];
 }
 
 class GenderChanged extends PersonalInfoEvent {
   final String gender;
 
   const GenderChanged(this.gender);
 
   @override
   List<Object> get props => [gender];
 }
 
 class ProfileImageChanged extends PersonalInfoEvent {
   final File profileImage;
 
   const ProfileImageChanged(this.profileImage);
 
   @override
   List<Object> get props => [profileImage];
 }
 
 class PersonalInfoSubmitted extends PersonalInfoEvent {
   const PersonalInfoSubmitted();
 }