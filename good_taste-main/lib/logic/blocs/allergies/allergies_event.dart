import 'package:equatable/equatable.dart';

abstract class AllergiesEvent extends Equatable {
  const AllergiesEvent();

  @override
  List<Object?> get props => [];
}

class AllergyToggled extends AllergiesEvent {
  final String allergy;

  const AllergyToggled(this.allergy);

  @override
  List<Object> get props => [allergy];
}

class AllergiesSubmitted extends AllergiesEvent {
  const AllergiesSubmitted();
}

class AllergiesLoaded extends AllergiesEvent {
  const AllergiesLoaded();
}