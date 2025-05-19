import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:formz/formz.dart';
import 'package:good_taste/data/models/email.dart'; 
import 'package:good_taste/data/models/password.dart';
import 'package:good_taste/data/repositories/auth_repository.dart';

part 'login_event.dart';
part 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  LoginBloc({
    required AuthRepository authRepository,
  })  : _authRepository = authRepository,
        super(const LoginState()) {
    on<LoginEmailChanged>(_onEmailChanged); // Modifié pour email
    on<LoginPasswordChanged>(_onPasswordChanged);
    on<LoginSubmitted>(_onSubmitted);
  }

  final AuthRepository _authRepository;

 void _onEmailChanged( // Modifié pour email
  LoginEmailChanged event,
  Emitter<LoginState> emit,
 ) {
  final email = Email.dirty(event.email); // Modifié pour email
  emit(state.copyWith(email: email)); // Modifié pour email
 }

 void _onPasswordChanged(
  LoginPasswordChanged event,
  Emitter<LoginState> emit,
 ) {
  final password = Password.dirty(event.password);
  emit(state.copyWith(password: password));
 }

void _onSubmitted(
  LoginSubmitted event,
  Emitter<LoginState> emit,
) async {
  
  emit(state.copyWith(isSubmitted: true));
  
  if (Formz.validate([state.email, state.password])) {
    emit(state.copyWith(status: FormzSubmissionStatus.inProgress));
    try {
      await _authRepository.logIn(
        email: state.email.value, 
        password: state.password.value,
      );
      
      emit(state.copyWith(status: FormzSubmissionStatus.success));
    } catch (_) {
      emit(state.copyWith(status: FormzSubmissionStatus.failure));
    }
  }
}
}