import 'package:equatable/equatable.dart';

class PreferencesModel extends Equatable {
  final List<String> preferences;

  const PreferencesModel({this.preferences = const []});

  PreferencesModel copyWith({List<String>? preferences}) {
    return PreferencesModel(
      preferences: preferences ?? this.preferences,
    );
  }

  @override
  List<Object?> get props => [preferences];
}