// lib/data/models/table.dart
import 'package:equatable/equatable.dart';

class TableModel extends Equatable {
  final String id;
  final String number;
  final int capacity; // Nombre maximum de personnes
  final String type; // "Standard", "Rectangulaire", "Large", etc.

  const TableModel({
    required this.id,
    required this.number,
    required this.capacity,
    required this.type,
  });

  @override
  List<Object?> get props => [id, number, capacity, type];
}