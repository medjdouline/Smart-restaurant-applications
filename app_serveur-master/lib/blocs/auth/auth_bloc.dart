import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';
import '../../core/api/api_client.dart';
import '../../data/repositories/auth_repository_impl.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepositoryImpl _authRepository;
  final Logger _logger = Logger();

  AuthBloc({required AuthRepositoryImpl authRepository})
      : _authRepository = authRepository,
        super(AuthState.initial()) {
    on<AppStarted>(_onAppStarted);
    on<LoginSubmitted>(_onLoginSubmitted);
    on<LogoutRequested>(_onLogoutRequested);
    on<CheckAuthStatus>(_onCheckAuthStatus);
    on<ChangePasswordRequested>(_onChangePassword);
     on<LoginRequested>(_onLoginRequested);

  }
  Future<void> _onLoginRequested(LoginRequested event, Emitter<AuthState> emit) async {
    _logger.d('Login requested with email: ${event.email}');
    emit(AuthState.loading());
    try {
      final user = await _authRepository.login(
        email: event.email,
        password: event.password,
      );
      emit(AuthState.authenticated(user));
    } catch (e) {
      // Same error handling as _onLoginSubmitted
      String errorMessage = 'Login failed';
      if (e is AuthException) errorMessage = e.message;
      emit(AuthState.error(errorMessage));
      emit(AuthState.unauthenticated());
    }
  }
  Future<void> _onAppStarted(AppStarted event, Emitter<AuthState> emit) async {
    _logger.d('App started: Checking authentication status');
    emit(AuthState.loading());
    try {
      final isAuthenticated = await _authRepository.isAuthenticated();
      if (isAuthenticated) {
        final user = await _authRepository.getCurrentUser();
        if (user != null) {
          _logger.i('User is authenticated: ${user.uid}');
          emit(AuthState.authenticated(user));
        } else {
          _logger.w('User is authenticated but profile data is missing');
          emit(AuthState.unauthenticated());
        }
      } else {
        _logger.d('User is not authenticated');
        emit(AuthState.unauthenticated());
      }
    } catch (e) {
      _logger.e('Error checking authentication status: $e');
      emit(AuthState.error('Authentication check failed: $e'));
      emit(AuthState.unauthenticated());
    }
  }

  Future<void> _onLoginSubmitted(LoginSubmitted event, Emitter<AuthState> emit) async {
    _logger.d('Login submitted with ${event.email != null ? 'email' : 'username'}');
    emit(AuthState.loading());
    try {
      final user = await _authRepository.login(
        email: event.email,
        username: event.username,
        password: event.password,
      );
      _logger.i('Login successful: ${user.fullName}');
      emit(AuthState.authenticated(user));
    } catch (e) {
      _logger.e('Login error: $e');
      String errorMessage = 'Login failed';
      
      if (e is AuthException) {
        errorMessage = e.message;
      } else if (e is ApiException) {
        if (e is NetworkException) {
          errorMessage = 'Network error: Please check your internet connection';
        } else {
          errorMessage = e.message;
        }
      }
      
      emit(AuthState.error(errorMessage));
      emit(AuthState.unauthenticated());
    }
  }

  Future<void> _onLogoutRequested(LogoutRequested event, Emitter<AuthState> emit) async {
    _logger.d('Logout requested');
    try {
      await _authRepository.logout();
      _logger.i('Logout successful');
      emit(AuthState.unauthenticated());
    } catch (e) {
      _logger.e('Logout error: $e');
      emit(AuthState.error('Logout failed: $e'));
    }
  }

  Future<void> _onCheckAuthStatus(CheckAuthStatus event, Emitter<AuthState> emit) async {
    _logger.d('Checking authentication status');
    try {
      final isAuthenticated = await _authRepository.isAuthenticated();
      if (isAuthenticated) {
        final user = await _authRepository.getCurrentUser();
        if (user != null) {
          _logger.i('User is authenticated: ${user.uid}');
          emit(AuthState.authenticated(user));
        } else {
          _logger.w('User is authenticated but profile data is missing');
          emit(AuthState.unauthenticated());
        }
      } else {
        _logger.d('User is not authenticated');
        emit(AuthState.unauthenticated());
      }
    } catch (e) {
      _logger.e('Error checking authentication status: $e');
      emit(AuthState.error('Authentication check failed: $e'));
      emit(AuthState.unauthenticated());
    }
  }
  
  Future<void> _onChangePassword(ChangePasswordRequested event, Emitter<AuthState> emit) async {
    _logger.d('Change password requested');
    
    // Keep the current user in the new state
    final currentUser = state.user;
    
    // Set loading state
    emit(AuthState.loading());
    
    try {
      // Implement the actual password change logic
      // This is a placeholder. You'll need to implement this in your repository
      await _authRepository.changePassword(
        currentPassword: event.currentPassword,
        newPassword: event.newPassword,
      );
      
      _logger.i('Password changed successfully');
      
      // Return to authenticated state with the same user
      if (currentUser != null) {
        emit(AuthState.authenticated(currentUser));
      } else {
        // If somehow we don't have user info, we should re-authenticate
        emit(AuthState.unauthenticated());
      }
    } catch (e) {
      _logger.e('Password change error: $e');
      String errorMessage = 'Password change failed';
      
      if (e is AuthException) {
        errorMessage = e.message;
      } else if (e is ApiException) {
        if (e is NetworkException) {
          errorMessage = 'Network error: Please check your internet connection';
        } else {
          errorMessage = e.message;
        }
      }
      
      emit(AuthState.error(errorMessage));
      
      // Restore authenticated state with current user if available
      if (currentUser != null) {
        emit(AuthState.authenticated(currentUser));
      }
    }
  }
}