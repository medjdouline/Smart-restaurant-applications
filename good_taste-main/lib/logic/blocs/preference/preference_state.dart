import 'package:equatable/equatable.dart';

enum PreferenceStatus { initial, loading, success, failure }

class PreferenceState extends Equatable {
  final List<String> selectedPreferences;
  final List<String> savedPreferences;
  final PreferenceStatus status;
  final String? errorMessage;

  const PreferenceState({
    this.selectedPreferences = const [],
    this.savedPreferences = const [],
    this.status = PreferenceStatus.initial,
    this.errorMessage,
  });

  PreferenceState copyWith({
    List<String>? selectedPreferences,
    List<String>? savedPreferences,
    PreferenceStatus? status,
    String? errorMessage,
  }) {
    return PreferenceState(
      selectedPreferences: selectedPreferences ?? this.selectedPreferences,
      savedPreferences: savedPreferences ?? this.savedPreferences,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [selectedPreferences, savedPreferences, status, errorMessage];
}