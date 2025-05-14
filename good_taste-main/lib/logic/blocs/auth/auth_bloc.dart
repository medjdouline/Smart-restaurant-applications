import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:good_taste/data/repositories/auth_repository.dart';
import 'package:good_taste/data/models/user.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(const AuthState.unknown()) {
    on<AuthStatusChanged>(_onAuthStatusChanged);
    on<AuthLogoutRequested>(_onAuthLogoutRequested);
    
    _authStatusSubscription = _authRepository.user.listen(
      (user) => add(AuthStatusChanged(user)),
    );
  }

  final AuthRepository _authRepository;
  late StreamSubscription<User> _authStatusSubscription;

  @override
  Future<void> close() {
    _authStatusSubscription.cancel();
    return super.close();
  }

  void _onAuthStatusChanged(
    AuthStatusChanged event,
    Emitter<AuthState> emit,
  ) async {
    if (event.user != User.empty) {
      emit(AuthState.authenticated(event.user));
    } else {
      emit(const AuthState.unauthenticated());
    }
  }

void _onAuthLogoutRequested(
  AuthLogoutRequested event,
  Emitter<AuthState> emit,
) async {
  await _authRepository.logOut();
  emit(const AuthState.unauthenticated());
}
}