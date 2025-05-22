// lib/blocs/tables/tables_bloc.dart
import 'package:app_serveur/data/repositories/tables_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';
import '../../data/repositories/tables_api_repository.dart';
import 'tables_event.dart';
import 'tables_state.dart';



class TablesBloc extends Bloc<TablesEvent, TablesState> {
  final TablesRepository tablesRepository;
  final TablesApiRepository _tablesRepository = TablesApiRepository();
  final Logger _logger = Logger();

  TablesBloc({required this.tablesRepository}) : super(const TablesState()) {
    on<LoadTables>(_onLoadTables);
    on<LoadTableOrders>(_onLoadTableOrders);
    on<ToggleTableStatus>(_onToggleTableStatus);
    on<StartReservation>(_onStartReservation);
  }

  Future<void> _onLoadTables(LoadTables event, Emitter<TablesState> emit) async {
    try {
      emit(state.copyWith(status: TablesStatus.loading));
      
      _logger.d('Loading tables');
      final tables = await _tablesRepository.getAllTables();
      _logger.d('Loaded ${tables.length} tables');
      
      // Create an empty map for table orders
      final Map<String, List<dynamic>> tableOrders = {};
      
      emit(state.copyWith(
        status: TablesStatus.success,
        tables: tables,
        tableOrders: tableOrders,
      ));
    } catch (e) {
      _logger.e('Error loading tables: $e');
      emit(state.copyWith(
        status: TablesStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onLoadTableOrders(LoadTableOrders event, Emitter<TablesState> emit) async {
    try {
      // Don't change status to loading to avoid UI flicker
      _logger.d('Loading orders for table ${event.tableId}');
      
      final orders = await _tablesRepository.getTableOrders(event.tableId);
      _logger.d('Loaded ${orders.length} orders for table ${event.tableId}');
      
      // Update the table orders map
      final updatedOrders = Map<String, List<dynamic>>.from(state.tableOrders);
      updatedOrders[event.tableId] = orders;
      
      emit(state.copyWith(
        tableOrders: updatedOrders,
      ));
    } catch (e) {
      _logger.e('Error loading table orders: $e');
      // Don't change status to failure to avoid UI issues
    }
  }

  Future<void> _onToggleTableStatus(ToggleTableStatus event, Emitter<TablesState> emit) async {
    try {
      _logger.d('Toggling status for table ${event.tableId}');
      
      // Find the current table status
      final tableIndex = state.tables.indexWhere((table) => table.id == event.tableId);
      if (tableIndex == -1) {
        _logger.e('Table not found: ${event.tableId}');
        return;
      }
      
      final currentTable = state.tables[tableIndex];
      final newIsOccupied = !currentTable.isOccupied;
      
      // Optimistic update
      final List<dynamic> updatedTables = List.from(state.tables);
      updatedTables[tableIndex] = currentTable.copyWith(isOccupied: newIsOccupied);
      
      emit(state.copyWith(
        tables: updatedTables,
      ));
      
      // Call API
      final updatedTable = await _tablesRepository.updateTableStatus(event.tableId, newIsOccupied);
      _logger.d('Table status updated: ${updatedTable.id}, occupied: ${updatedTable.isOccupied}');
      
      // Update with actual server response
      final finalTables = List.from(state.tables);
      finalTables[tableIndex] = updatedTable;
      
      emit(state.copyWith(
        tables: finalTables,
      ));
      
      // If the table is now occupied, load its orders
      if (updatedTable.isOccupied) {
        add(LoadTableOrders(tableId: event.tableId));
      }
    } catch (e) {
      _logger.e('Error toggling table status: $e');
      
      // Revert to original state on error
      add(LoadTables());
    }
  }
Future<void> _onStartReservation(StartReservation event, Emitter<TablesState> emit) async {
  try {
    _logger.d('Starting reservation for table ${event.tableId}');
    
    // Appelle le bon endpoint d'API
    final updatedTable = await _tablesRepository.startReservation(event.tableId);
    
    // Recharge les tables pour avoir les données fraîches
    add(LoadTables());
    
  } catch (e) {
    _logger.e('Error starting reservation: $e');
    emit(state.copyWith(
      status: TablesStatus.failure,
      errorMessage: 'Erreur lors de la confirmation de réservation',
    ));
  }
}
}