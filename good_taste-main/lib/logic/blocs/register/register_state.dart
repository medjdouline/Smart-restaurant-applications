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
    this.errorMessage,
    this.isSubmitted = false, 
  });

  final Username username;
  final Email email;
  final String? errorMessage;
  final Password password;
  final ConfirmedPassword confirmedPassword;
  final PhoneNumber phoneNumber;
  final FormzSubmissionStatus status;
  final bool isValid;
  final bool isSubmitted; 

  RegisterState copyWith({
    Username? username,
    Email? email,
    String? errorMessage,
    Password? password,
    ConfirmedPassword? confirmedPassword,
    PhoneNumber? phoneNumber, 
    FormzSubmissionStatus? status,
    bool? isValid,
    bool? isSubmitted,
  }) {
    return RegisterState(
      username: username ?? this.username,
      email: email ?? this.email,
      password: password ?? this.password,
      confirmedPassword: confirmedPassword ?? this.confirmedPassword,
      phoneNumber: phoneNumber ?? this.phoneNumber, 
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      isValid: isValid ?? this.isValid,
      isSubmitted: isSubmitted ?? this.isSubmitted,
    );
  }

  @override
  List<Object> get props => [
    username, 
    email, 
    password, 
    confirmedPassword,
    phoneNumber, 
    errorMessage ?? '',
    status, 
    isValid, 
    isSubmitted
  ];
}