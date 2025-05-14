import 'package:equatable/equatable.dart';

abstract class RegimeEvent extends Equatable {
  const RegimeEvent();

  @override
  List<Object?> get props => [];
}

class RegimeToggled extends RegimeEvent {
  final String regime;

  const RegimeToggled(this.regime);

  @override
  List<Object> get props => [regime];
}

class RegimeSubmitted extends RegimeEvent {
  const RegimeSubmitted();
}

class RegimesLoaded extends RegimeEvent {
  const RegimesLoaded();
}