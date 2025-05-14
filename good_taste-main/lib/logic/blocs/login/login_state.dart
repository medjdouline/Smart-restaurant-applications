part of 'login_bloc.dart';

class LoginState extends Equatable {
  const LoginState({
    this.status = FormzSubmissionStatus.initial,
    this.email = const Email.pure(), 
    this.password = const Password.pure(),
    this.isSubmitted = false,
  });

  final FormzSubmissionStatus status;
  final Email email;
  final Password password;
  final bool isSubmitted;

  LoginState copyWith({
    FormzSubmissionStatus? status,
    Email? email,
    Password? password,
    bool? isSubmitted,
  }) {
    return LoginState(
      status: status ?? this.status,
      email: email ?? this.email, 
      password: password ?? this.password,
      isSubmitted: isSubmitted ?? this.isSubmitted,
    );
  }

  @override
  List<Object> get props => [status, email, password, isSubmitted];
}