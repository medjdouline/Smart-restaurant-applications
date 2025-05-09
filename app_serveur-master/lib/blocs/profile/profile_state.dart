// lib/blocs/profile/profile_state.dart
import '../../data/models/profile_stats.dart';

enum ProfileStatus { initial, loading, loaded, error }

class ProfileState {
  final ProfileStatus status;
  final ProfileStats? stats;
  final String? errorMessage;

  ProfileState({
    this.status = ProfileStatus.initial,
    this.stats,
    this.errorMessage,
  });

  factory ProfileState.initial() {
    return ProfileState(status: ProfileStatus.initial);
  }

  factory ProfileState.loading() {
    return ProfileState(status: ProfileStatus.loading);
  }

  factory ProfileState.loaded(ProfileStats stats) {
    return ProfileState(status: ProfileStatus.loaded, stats: stats);
  }

  factory ProfileState.error(String message) {
    return ProfileState(
      status: ProfileStatus.error,
      errorMessage: message,
    );
  }

  ProfileState copyWith({
    ProfileStatus? status,
    ProfileStats? stats,
    String? errorMessage,
  }) {
    return ProfileState(
      status: status ?? this.status,
      stats: stats ?? this.stats,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}