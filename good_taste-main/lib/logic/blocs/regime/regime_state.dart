import 'package:equatable/equatable.dart';

enum RegimeStatus { initial, loading, success, failure }

class RegimeState extends Equatable {
  final List<String> selectedRegimes;
  final List<String> savedRegimes;  
  final RegimeStatus status;
  final String? errorMessage;

  const RegimeState({
    this.selectedRegimes = const [],
    this.savedRegimes = const [], 
    this.status = RegimeStatus.initial,
    this.errorMessage,
  });

  RegimeState copyWith({
    List<String>? selectedRegimes,
    List<String>? savedRegimes,  
    RegimeStatus? status,
    String? errorMessage,
  }) {
    return RegimeState(
      selectedRegimes: selectedRegimes ?? this.selectedRegimes,
      savedRegimes: savedRegimes ?? this.savedRegimes,  
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [selectedRegimes, savedRegimes, status, errorMessage];
}