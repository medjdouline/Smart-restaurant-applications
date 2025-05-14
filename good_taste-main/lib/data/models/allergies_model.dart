import 'package:equatable/equatable.dart';

class AllergiesModel extends Equatable {
  final List<String> allergies;

  const AllergiesModel({this.allergies = const []});

  AllergiesModel copyWith({List<String>? allergies}) {
    return AllergiesModel(
      allergies: allergies ?? this.allergies,
    );
  }

  @override
  List<Object?> get props => [allergies];
}