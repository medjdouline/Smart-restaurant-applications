// lib/blocs/tables/tables_event.dart
import 'package:equatable/equatable.dart';

abstract class TablesEvent extends Equatable {
  const TablesEvent();

  @override
  List<Object> get props => [];
}

class LoadTables extends TablesEvent {}

class LoadTableOrders extends TablesEvent {
  final String tableId;

  const LoadTableOrders({required this.tableId});

  @override
  List<Object> get props => [tableId];
}

class ToggleTableStatus extends TablesEvent {
  final String tableId;

  const ToggleTableStatus({required this.tableId});

  @override
  List<Object> get props => [tableId];
}

// Nouvel événement pour convertir une table réservée en occupée
class StartReservation extends TablesEvent {
  final String tableId;

  const StartReservation({required this.tableId});

  @override
  List<Object> get props => [tableId];
}