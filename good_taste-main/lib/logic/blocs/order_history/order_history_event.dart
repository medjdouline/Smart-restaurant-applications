// lib/logic/blocs/order_history/order_history_event.dart
part of 'order_history_bloc.dart';

abstract class OrderHistoryEvent extends Equatable {
  const OrderHistoryEvent();

  @override
  List<Object> get props => [];
}

class LoadOrderHistory extends OrderHistoryEvent {}

class DeleteOrder extends OrderHistoryEvent {
  final String orderId;

  const DeleteOrder(this.orderId);

  @override
  List<Object> get props => [orderId];
}