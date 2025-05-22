import '../../data/models/order.dart';

enum OrderStatus {
  initial,
  loading,
  loaded,
  error,
  served,
  cancelRequested,
  cancelled,
  detailLoaded,
  
}

class OrderState {
  final OrderStatus status;
  final List<Order> newOrders;
  final List<Order> readyOrders;
  final List<Order> servedOrders;
  final List<Order> cancelledOrders;
  final List<Order> filteredOrders;
  final String currentFilter;
  final String? errorMessage;
  final String? infoMessage;
  final Order? currentOrderDetails;

  OrderState({
    this.status = OrderStatus.initial,
    this.newOrders = const [],
    this.readyOrders = const [],
    this.servedOrders = const [],
    this.cancelledOrders = const [],
    this.filteredOrders = const [],
    this.currentFilter = 'Tous',
    this.errorMessage,
    this.infoMessage,
    this.currentOrderDetails,
  });

  OrderState copyWith({
    OrderStatus? status,
    List<Order>? newOrders,
    List<Order>? readyOrders,
    List<Order>? servedOrders,
    List<Order>? cancelledOrders,
    List<Order>? filteredOrders,
    String? currentFilter,
    String? errorMessage,
    Order? currentOrderDetails,
    String? infoMessage,
  }) {
    return OrderState(
      status: status ?? this.status,
      newOrders: newOrders ?? this.newOrders,
      readyOrders: readyOrders ?? this.readyOrders,
      servedOrders: servedOrders ?? this.servedOrders,
      cancelledOrders: cancelledOrders ?? this.cancelledOrders,
      filteredOrders: filteredOrders ?? this.filteredOrders,
      currentFilter: currentFilter ?? this.currentFilter,
      errorMessage: errorMessage ?? this.errorMessage,
      infoMessage: infoMessage ?? this.infoMessage,
      currentOrderDetails: currentOrderDetails ?? this.currentOrderDetails,
    );
  }
}