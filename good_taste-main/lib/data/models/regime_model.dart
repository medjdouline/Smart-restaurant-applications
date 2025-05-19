import 'package:equatable/equatable.dart';

class RegimeModel extends Equatable {
  final List<String> regimes;

  const RegimeModel({this.regimes = const []});

  bool isRegimeSelected(String regime) {
    return regimes.contains(regime);
  }

  RegimeModel copyWith({List<String>? regimes}) {
    return RegimeModel(
      regimes: regimes ?? this.regimes,
    );
  }

  @override
  List<Object?> get props => [regimes];
}