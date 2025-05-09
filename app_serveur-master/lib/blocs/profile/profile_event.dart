// lib/blocs/profile/profile_event.dart
import 'package:equatable/equatable.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();
  
  @override
  List<Object?> get props => [];
}

class LoadProfileStats extends ProfileEvent {}

class ResetProfileState extends ProfileEvent {}