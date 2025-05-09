import 'package:equatable/equatable.dart';
import '../../data/models/user.dart';
import 'auth_status.dart';

class AuthState extends Equatable {
  final AuthStatus status;
  final User? user;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
  });

  // Factory constructors to create different states
  factory AuthState.initial() => const AuthState(status: AuthStatus.initial);
  
  factory AuthState.loading() => const AuthState(status: AuthStatus.loading);
  
  factory AuthState.authenticated(User user) => AuthState(
    status: AuthStatus.authenticated,
    user: user,
  );
  
  factory AuthState.unauthenticated() => const AuthState(status: AuthStatus.unauthenticated);
  
  factory AuthState.error(String message) => AuthState(
    status: AuthStatus.error,
    errorMessage: message,
  );

  // Create a copy of current state with some fields updated
  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
  
  @override
  List<Object?> get props => [status, user, errorMessage];
}