// lib/logic/blocs/register/register_state.dart
part of 'register_bloc.dart';

class RegisterState extends Equatable {
  const RegisterState({
    this.username = const Username.pure(),
    this.email = const Email.pure(),
    this.password = const Password.pure(),
    this.confirmedPassword = const ConfirmedPassword.pure(),
    this.phoneNumber = const PhoneNumber.pure(), 
    this.status = FormzSubmissionStatus.initial,
    this.isValid = false,
    this.isSubmitted = false,
    this.uid,
    this.errorMessage,
  });

  final Username username;
  final Email email;
  final Password password;
  final ConfirmedPassword confirmedPassword;
  final PhoneNumber phoneNumber;
  final FormzSubmissionStatus status;
  final bool isValid;
  final bool isSubmitted;
  final String? uid;
  final String? errorMessage;

  RegisterState copyWith({
    Username? username,
    Email? email,
    Password? password,
    ConfirmedPassword? confirmedPassword,
    PhoneNumber? phoneNumber, 
    FormzSubmissionStatus? status,
    bool? isValid,
    bool? isSubmitted,
    String? uid,
    String? errorMessage,
  }) {
    return RegisterState(
      username: username ?? this.username,
      email: email ?? this.email,
      password: password ?? this.password,
      confirmedPassword: confirmedPassword ?? this.confirmedPassword,
      phoneNumber: phoneNumber ?? this.phoneNumber, 
      status: status ?? this.status,
      isValid: isValid ?? this.isValid,
      isSubmitted: isSubmitted ?? this.isSubmitted,
      uid: uid ?? this.uid,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    username, 
    email, 
    password, 
    confirmedPassword,
    phoneNumber, 
    status, 
    isValid, 
    isSubmitted,
    uid,
    errorMessage,
  ];
}