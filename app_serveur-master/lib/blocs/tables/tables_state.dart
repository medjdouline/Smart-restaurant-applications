// lib/blocs/tables/tables_state.dart
import 'package:equatable/equatable.dart';


enum TablesStatus { initial, loading, success, failure }

class TablesState extends Equatable {
  final TablesStatus status;
  final List<dynamic> tables;
  final Map<String, List<dynamic>> tableOrders;
  final String? errorMessage;

  const TablesState({
    this.status = TablesStatus.initial,
    this.tables = const [],
    this.tableOrders = const {},
    this.errorMessage,
  });

  TablesState copyWith({
    TablesStatus? status,
    List<dynamic>? tables,
    Map<String, List<dynamic>>? tableOrders,
    String? errorMessage,
  }) {
    return TablesState(
      status: status ?? this.status,
      tables: tables ?? this.tables,
      tableOrders: tableOrders ?? this.tableOrders,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, tables, tableOrders, errorMessage];
}