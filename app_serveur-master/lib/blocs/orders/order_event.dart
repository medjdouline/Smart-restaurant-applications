// lib/blocs/orders/order_event.dart
abstract class OrderEvent {}

class LoadOrders extends OrderEvent {}

class ServeOrder extends OrderEvent {
  final String orderId;
  ServeOrder({required this.orderId});
}

class CompleteOrder extends OrderEvent {
  final String orderId;
  CompleteOrder({required this.orderId});
}

class CancelOrder extends OrderEvent {
  final String orderId;
  final String currentStatus;
  CancelOrder({required this.orderId, required this.currentStatus});
}

class RequestCancelOrder extends OrderEvent {
  final String orderId;
  final String currentStatus;
  RequestCancelOrder({required this.orderId, required this.currentStatus});
}

class ConfirmOrderServed extends OrderEvent {
  final String orderId;
  ConfirmOrderServed({required this.orderId});
}

class FilterOrders extends OrderEvent {
  final String filter;
  FilterOrders({required this.filter});
}