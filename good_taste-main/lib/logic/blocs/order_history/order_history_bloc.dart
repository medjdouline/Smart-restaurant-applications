// lib/logic/blocs/order_history/order_history_bloc.dart
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:logger/logger.dart';
import 'package:good_taste/data/models/order.dart';
import 'package:good_taste/data/repositories/order_history_repository.dart';
import 'package:good_taste/logic/blocs/auth/auth_bloc.dart';

part 'order_history_event.dart';
part 'order_history_state.dart';

class OrderHistoryBloc extends Bloc<OrderHistoryEvent, OrderHistoryState> {
  final OrderHistoryRepository repository;
  final AuthBloc authBloc;
  final Logger _logger = Logger();

  OrderHistoryBloc({
    required this.repository,
    required this.authBloc,
  }) : super(OrderHistoryInitial()) {
    on<LoadOrderHistory>(_onLoadOrderHistory);
    on<DeleteOrder>(_onDeleteOrder);
  }

  void _onLoadOrderHistory(
    LoadOrderHistory event,
    Emitter<OrderHistoryState> emit,
  ) async {
    emit(OrderHistoryLoading());
    try {
      final user = authBloc.state.user;
      final orders = await repository.getOrderHistory(user);
      emit(OrderHistoryLoaded(orders: orders));
    } catch (e) {
      _logger.e('Error loading order history: $e');
      emit(OrderHistoryError(message: e.toString()));
    }
  }

  void _onDeleteOrder(
    DeleteOrder event,
    Emitter<OrderHistoryState> emit,
  ) async {
    _logger.i('Attempting to delete order: ${event.orderId}');
    if (state is OrderHistoryLoaded) {
      final currentState = state as OrderHistoryLoaded;
      emit(OrderHistoryLoading());
      
      try {
        _logger.d('Calling repository to delete order...');
        final result = await repository.deleteOrder(event.orderId);
        _logger.i('Delete result: $result');
        
        if (result) {
          // Remove the order from the list
          final updatedOrders = currentState.orders
              .where((order) => order.id != event.orderId)
              .toList();
          
          _logger.d('Orders count before: ${currentState.orders.length}');
          _logger.d('Orders count after: ${updatedOrders.length}');
          
          emit(OrderHistoryLoaded(orders: updatedOrders));
        } else {
          emit(OrderHistoryError(message: "Failed to delete order"));
        }
      } catch (e) {
        _logger.e('Error deleting order: $e');
        emit(OrderHistoryError(message: e.toString()));
      }
    } else {
      _logger.w('Incorrect state for deletion: $state');
    }
  }
}