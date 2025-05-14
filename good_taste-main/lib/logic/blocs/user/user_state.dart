part of 'user_bloc.dart';

abstract class UserState extends Equatable {
  const UserState();
  
  @override
  List<Object?> get props => [];
}

class UserInitial extends UserState {}

class UserLoaded extends UserState {
  final User user;
  
  const UserLoaded(this.user);
  
  @override
  List<Object> get props => [user];
}

class UserInvalid extends UserState {
  final User user;
  final String errorMessage;
  
  const UserInvalid(this.user, this.errorMessage);
  
  @override
  List<Object> get props => [user, errorMessage];
}

class UserLoadFailure extends UserState {
  final String error;
  
  const UserLoadFailure(this.error);
  
  @override
  List<Object> get props => [error];
}

class UserUpdateInProgress extends UserState {}

class UserUpdateFailure extends UserState {
  final String error;
  
  const UserUpdateFailure(this.error);
  
  @override
  List<Object> get props => [error];
}