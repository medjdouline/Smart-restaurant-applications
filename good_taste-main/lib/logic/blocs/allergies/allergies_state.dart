import 'package:equatable/equatable.dart';

enum AllergiesStatus { initial, loading, success, failure }

class AllergiesState extends Equatable {
  final List<String> selectedAllergies;
  final List<String> savedAllergies;  
  final AllergiesStatus status;
  final String? errorMessage;

  const AllergiesState({
    this.selectedAllergies = const [],
    this.savedAllergies = const [], 
    this.status = AllergiesStatus.initial,
    this.errorMessage,
  });

  AllergiesState copyWith({
    List<String>? selectedAllergies,
    List<String>? savedAllergies,  
    AllergiesStatus? status,
    String? errorMessage,
  }) {
    return AllergiesState(
      selectedAllergies: selectedAllergies ?? this.selectedAllergies,
      savedAllergies: savedAllergies ?? this.savedAllergies,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [selectedAllergies, savedAllergies, status, errorMessage];
}