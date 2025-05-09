// lib/presentation/blocs/profile/password_update_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/repositories/auth_repository_impl.dart';

// Events
abstract class PasswordUpdateEvent extends Equatable {
  const PasswordUpdateEvent();

  @override
  List<Object> get props => [];
}

class UpdatePassword extends PasswordUpdateEvent {
  final String currentPassword;
  final String newPassword;

  const UpdatePassword({
    required this.currentPassword,
    required this.newPassword,
  });

  @override
  List<Object> get props => [currentPassword, newPassword];
}

// States
enum PasswordUpdateStatus { initial, loading, success, failure }

class PasswordUpdateState extends Equatable {
  final PasswordUpdateStatus status;
  final String? errorMessage;

  const PasswordUpdateState({
    this.status = PasswordUpdateStatus.initial,
    this.errorMessage,
  });

  PasswordUpdateState copyWith({
    PasswordUpdateStatus? status,
    String? errorMessage,
  }) {
    return PasswordUpdateState(
      status: status ?? this.status,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, errorMessage];
}

// Bloc
class PasswordUpdateBloc extends Bloc<PasswordUpdateEvent, PasswordUpdateState> {
  final AuthRepositoryImpl _authRepository;

  PasswordUpdateBloc({required AuthRepositoryImpl authRepository})
      : _authRepository = authRepository,
        super(const PasswordUpdateState()) {
    on<UpdatePassword>(_onUpdatePassword);
  }

  Future<void> _onUpdatePassword(
    UpdatePassword event,
    Emitter<PasswordUpdateState> emit,
  ) async {
    emit(state.copyWith(status: PasswordUpdateStatus.loading));

    try {
      await _authRepository.changePassword(
        currentPassword: event.currentPassword,
        newPassword: event.newPassword,
      );
      emit(state.copyWith(status: PasswordUpdateStatus.success));
    } catch (e) {
      emit(state.copyWith(
        status: PasswordUpdateStatus.failure,
        errorMessage: e.toString().replaceAll('AuthException: ', ''),
      ));
    }
  }
}