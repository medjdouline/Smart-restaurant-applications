import 'package:equatable/equatable.dart';

abstract class PreferenceEvent extends Equatable {
  const PreferenceEvent();

  @override
  List<Object?> get props => [];
}

class PreferenceToggled extends PreferenceEvent {
  final String preference;

  const PreferenceToggled(this.preference);

  @override
  List<Object> get props => [preference];
}

class PreferenceSubmitted extends PreferenceEvent {
  const PreferenceSubmitted();
}

class PreferencesLoaded extends PreferenceEvent {
  const PreferencesLoaded();
}