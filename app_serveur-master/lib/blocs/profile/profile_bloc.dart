// lib/blocs/profile/profile_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/profile_stats.dart';
import '../../data/repositories/profile_repository.dart';
import 'profile_event.dart';
import 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final ProfileRepository _profileRepository;
  
  ProfileBloc({required ProfileRepository profileRepository})
      : _profileRepository = profileRepository,
        super(ProfileState.initial()) {
    on<LoadProfileStats>(_onLoadProfileStats);
    on<ResetProfileState>(_onResetProfileState);
  }
  
  Future<void> _onLoadProfileStats(
    LoadProfileStats event,
    Emitter<ProfileState> emit,
  ) async {
    try {
      emit(state.copyWith(status: ProfileStatus.loading));
      
      final profileData = await _profileRepository.getProfileStats();
      final profileStats = ProfileStats.fromJson(profileData);
      
      emit(state.copyWith(
        status: ProfileStatus.loaded,
        stats: profileStats,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ProfileStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }
  
  void _onResetProfileState(
    ResetProfileState event,
    Emitter<ProfileState> emit,
  ) {
    emit(ProfileState.initial());
  }
}