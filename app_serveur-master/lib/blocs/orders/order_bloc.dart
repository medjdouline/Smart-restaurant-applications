// lib/blocs/orders/order_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/order_repository.dart';
import '../../data/models/order.dart';
import 'order_event.dart';
import 'order_state.dart';

class OrderBloc extends Bloc<OrderEvent, OrderState> {
  final OrderRepository orderRepository;

  OrderBloc({required this.orderRepository}) : super(OrderState()) {
    on<LoadOrders>(_onLoadOrders);
    on<ServeOrder>(_onServeOrder);
    on<CompleteOrder>(_onCompleteOrder);
    on<FilterOrders>(_onFilterOrders);
    on<CancelOrder>(_onCancelOrder);
    on<RequestCancelOrder>(_onRequestCancelOrder);
    on<ConfirmOrderServed>(_onConfirmOrderServed);
  }


Future<void> _onLoadOrderDetails(
  LoadOrderDetails event,
  Emitter<OrderState> emit,
) async {
  emit(state.copyWith(status: OrderStatus.loading));
  
  try {
    final orderDetails = await orderRepository.getOrderDetails(event.orderId);
    emit(state.copyWith(
      status: OrderStatus.detailLoaded,
      currentOrderDetails: orderDetails,
    ));
  } catch (e) {
    emit(state.copyWith(
      status: OrderStatus.error,
      errorMessage: 'Failed to load order details: ${e.toString()}',
    ));
  }
}
Future<void> _onLoadOrders(
  LoadOrders event,
  Emitter<OrderState> emit,
) async {
  // Ne pas recharger si déjà en cours de chargement
  if (state.status == OrderStatus.loading) return;

  emit(state.copyWith(status: OrderStatus.loading));
  
  try {
    final newOrders = await orderRepository.getNewOrders();
    final readyOrders = await orderRepository.getReadyOrders();
    final servedOrders = await orderRepository.getServedOrders();
    final cancelledOrders = await orderRepository.getCancelledOrders();

    List<Order> filteredOrders;
    switch (state.currentFilter) {
      case 'Tous':
        filteredOrders = [...newOrders, ...readyOrders];
        break;
      case 'En attente':
        filteredOrders = newOrders.where((o) => o.status == 'pending').toList();
        break;
      case 'En préparation':
        filteredOrders = newOrders.where((o) => o.status == 'preparing').toList();
        break;
      case 'Prête':
        filteredOrders = readyOrders;
        break;
      case 'Servie':
        filteredOrders = servedOrders;
        break;
      case 'Annulées':
        filteredOrders = cancelledOrders;
        break;
      default:
        filteredOrders = [...newOrders, ...readyOrders];
    }

    emit(state.copyWith(
      status: OrderStatus.loaded,
      newOrders: newOrders,
      readyOrders: readyOrders,
      servedOrders: servedOrders,
      cancelledOrders: cancelledOrders,
      filteredOrders: filteredOrders,
      errorMessage: null,
    ));

  } catch (e) {
    emit(state.copyWith(
      status: OrderStatus.error,
      errorMessage: 'Erreur de chargement: ${e.toString()}',
    ));
  }
}

  Future<void> _onServeOrder(
    ServeOrder event,
    Emitter<OrderState> emit,
  ) async {
    try {
      // Appel API pour marquer la commande comme servie
      await orderRepository.serveOrder(event.orderId);
      
      // Rechercher la commande qui est servie
      Order? servedOrder;
      List<Order> updatedNewOrders = List.from(state.newOrders);
      List<Order> updatedReadyOrders = List.from(state.readyOrders);
      
      // Chercher dans les commandes en attente ou en préparation
      final newOrderIndex = updatedNewOrders.indexWhere((order) => order.id == event.orderId);
      if (newOrderIndex != -1) {
        servedOrder = updatedNewOrders[newOrderIndex].copyWith(status: 'served');
        updatedNewOrders.removeAt(newOrderIndex);
      } else {
        // Chercher dans les commandes prêtes
        final readyOrderIndex = updatedReadyOrders.indexWhere((order) => order.id == event.orderId);
        if (readyOrderIndex != -1) {
          servedOrder = updatedReadyOrders[readyOrderIndex].copyWith(status: 'served');
          updatedReadyOrders.removeAt(readyOrderIndex);
        }
      }
      
      if (servedOrder != null) {
        // Ajouter la commande à la liste des servies
        final updatedServedOrders = [...state.servedOrders, servedOrder];
        
        // Mettre à jour les commandes filtrées selon le filtre actuel
        List<Order> updatedFilteredOrders;
        switch (state.currentFilter) {
          case 'Servie':
            updatedFilteredOrders = updatedServedOrders;
            break;
          case 'Tous':
            updatedFilteredOrders = [...updatedNewOrders, ...updatedReadyOrders];
            break;
          case 'En attente':
            updatedFilteredOrders = updatedNewOrders.where((order) => order.status == 'new').toList();
            break;
          case 'En préparation':
            updatedFilteredOrders = updatedNewOrders.where((order) => order.status == 'preparing').toList();
            break;
          case 'Prête':
            updatedFilteredOrders = updatedReadyOrders;
            break;
          default:
            updatedFilteredOrders = [...updatedNewOrders, ...updatedReadyOrders];
        }
        
        emit(state.copyWith(
          newOrders: updatedNewOrders,
          readyOrders: updatedReadyOrders,
          servedOrders: updatedServedOrders,
          filteredOrders: updatedFilteredOrders,
          status: OrderStatus.served,
        ));
      } else {
        // Si on n'a pas trouvé la commande à servir, recharger toutes les données
        add(LoadOrders());
      }
    } catch (e) {
      emit(state.copyWith(
        status: OrderStatus.error,
        errorMessage: 'Impossible de servir la commande: ${e.toString()}',
      ));
    }
  }

  Future<void> _onCompleteOrder(
    CompleteOrder event,
    Emitter<OrderState> emit,
  ) async {
    try {
      await orderRepository.completeOrder(event.orderId);
      add(LoadOrders());
    } catch (e) {
      emit(state.copyWith(
        status: OrderStatus.error,
        errorMessage: 'Impossible de terminer la commande',
      ));
    }
  }
  

// Replace the existing _onRequestCancelOrder method with this one
Future<void> _onRequestCancelOrder(
  RequestCancelOrder event,
  Emitter<OrderState> emit,
) async {
  try {
    // État initial de chargement
    emit(state.copyWith(
      status: OrderStatus.loading,
      infoMessage: null,
      errorMessage: null,
    ));

    // Appel API
    await orderRepository.requestCancelOrder(
      event.orderId,
      event.currentStatus,
    );

    // Message de succès sans rechargement immédiat
    emit(state.copyWith(
      status: OrderStatus.cancelRequested,
      infoMessage: event.currentStatus == 'pending' || event.currentStatus == 'new'
          ? 'Commande annulée avec succès'
          : 'Demande d\'annulation envoyée',
    ));

  } catch (e) {
    emit(state.copyWith(
      status: OrderStatus.error,
      errorMessage: 'Erreur lors de l\'annulation: ${e.toString()}',
    ));
  }
}

  Future<void> _onCancelOrder(
    CancelOrder event,
    Emitter<OrderState> emit,
  ) async {
    try {
      await orderRepository.cancelOrder(event.orderId);
      
      // Rechercher la commande à annuler
      Order? cancelledOrder;
      List<Order> updatedNewOrders = List.from(state.newOrders);
      List<Order> updatedReadyOrders = List.from(state.readyOrders);
      
      // Chercher dans les commandes en attente ou en préparation
      final newOrderIndex = updatedNewOrders.indexWhere((order) => order.id == event.orderId);
      if (newOrderIndex != -1) {
        cancelledOrder = updatedNewOrders[newOrderIndex].copyWith(status: 'cancelled');
        updatedNewOrders.removeAt(newOrderIndex);
      } else {
        // Chercher dans les commandes prêtes
        final readyOrderIndex = updatedReadyOrders.indexWhere((order) => order.id == event.orderId);
        if (readyOrderIndex != -1) {
          cancelledOrder = updatedReadyOrders[readyOrderIndex].copyWith(status: 'cancelled');
          updatedReadyOrders.removeAt(readyOrderIndex);
        }
      }
      
      if (cancelledOrder != null) {
        // Ajouter la commande à la liste des annulées
        final updatedCancelledOrders = [...state.cancelledOrders, cancelledOrder];
        
        // Mettre à jour les commandes filtrées selon le filtre actuel
        List<Order> updatedFilteredOrders;
        switch (state.currentFilter) {
          case 'Annulées':
            updatedFilteredOrders = updatedCancelledOrders;
            break;
          case 'Tous':
            updatedFilteredOrders = [...updatedNewOrders, ...updatedReadyOrders];
            break;
          case 'En attente':
            updatedFilteredOrders = updatedNewOrders.where((order) => order.status == 'new').toList();
            break;
          case 'En préparation':
            updatedFilteredOrders = updatedNewOrders.where((order) => order.status == 'preparing').toList();
            break;
          case 'Prête':
            updatedFilteredOrders = updatedReadyOrders;
            break;
          default:
            updatedFilteredOrders = [...updatedNewOrders, ...updatedReadyOrders];
        }
        
        emit(state.copyWith(
          newOrders: updatedNewOrders,
          readyOrders: updatedReadyOrders,
          cancelledOrders: updatedCancelledOrders,
          filteredOrders: updatedFilteredOrders,
          status: OrderStatus.cancelled,
        ));
      } else {
        // Si on n'a pas trouvé la commande à annuler, recharger toutes les données
        add(LoadOrders());
      }
    } catch (e) {
      emit(state.copyWith(
        status: OrderStatus.error,
        errorMessage: 'Impossible d\'annuler la commande: ${e.toString()}',
      ));
    }
  }

  Future<void> _onConfirmOrderServed(
    ConfirmOrderServed event,
    Emitter<OrderState> emit,
  ) async {
    try {
      await orderRepository.serveOrder(event.orderId);
      
      // Rechercher la commande à marquer comme servie
      Order? servedOrder;
      List<Order> updatedNewOrders = List.from(state.newOrders);
      List<Order> updatedReadyOrders = List.from(state.readyOrders);
      
      // Chercher dans les commandes prêtes (puisque cette action est disponible pour les commandes prêtes)
      final readyOrderIndex = updatedReadyOrders.indexWhere((order) => order.id == event.orderId);
      if (readyOrderIndex != -1) {
        servedOrder = updatedReadyOrders[readyOrderIndex].copyWith(status: 'served');
        updatedReadyOrders.removeAt(readyOrderIndex);
      } else {
        // Chercher dans les commandes en attente ou en préparation (cas moins courant)
        final newOrderIndex = updatedNewOrders.indexWhere((order) => order.id == event.orderId);
        if (newOrderIndex != -1) {
          servedOrder = updatedNewOrders[newOrderIndex].copyWith(status: 'served');
          updatedNewOrders.removeAt(newOrderIndex);
        }
      }
      
      if (servedOrder != null) {
        // Ajouter la commande à la liste des servies
        final updatedServedOrders = [...state.servedOrders, servedOrder];
        
        // Mettre à jour les commandes filtrées selon le filtre actuel
        List<Order> updatedFilteredOrders;
        switch (state.currentFilter) {
          case 'Servie':
            updatedFilteredOrders = updatedServedOrders;
            break;
          case 'Tous':
            updatedFilteredOrders = [...updatedNewOrders, ...updatedReadyOrders];
            break;
          case 'En attente':
            updatedFilteredOrders = updatedNewOrders.where((order) => order.status == 'new').toList();
            break;
          case 'En préparation':
            updatedFilteredOrders = updatedNewOrders.where((order) => order.status == 'preparing').toList();
            break;
          case 'Prête':
            updatedFilteredOrders = updatedReadyOrders;
            break;
          default:
            updatedFilteredOrders = [...updatedNewOrders, ...updatedReadyOrders];
        }
        
        emit(state.copyWith(
          newOrders: updatedNewOrders,
          readyOrders: updatedReadyOrders,
          servedOrders: updatedServedOrders,
          filteredOrders: updatedFilteredOrders,
          status: OrderStatus.served,
        ));
      } else {
        // Si on n'a pas trouvé la commande, recharger toutes les données
        add(LoadOrders());
      }
    } catch (e) {
      emit(state.copyWith(
        status: OrderStatus.error,
        errorMessage: 'Impossible de marquer la commande comme servie: ${e.toString()}',
      ));
    }
  }

void _onFilterOrders(
  FilterOrders event,
  Emitter<OrderState> emit,
) {
  List<Order> filteredOrders = [];
  
  switch (event.filter) {
    case 'Tous':
      filteredOrders = [...state.newOrders, ...state.readyOrders];
      break;
    case 'En attente':
      filteredOrders = state.newOrders.where((order) => 
        order.status == 'pending').toList();
      break;
    case 'En préparation':
      filteredOrders = state.newOrders.where((order) => 
        order.status == 'preparing').toList();
      break;
    case 'Prête':
      filteredOrders = state.readyOrders;
      break;
    case 'Servie':
      filteredOrders = state.servedOrders;
      break;
    case 'Annulées':
      filteredOrders = state.cancelledOrders;
      break;
    default:
      filteredOrders = [...state.newOrders, ...state.readyOrders];
  }
  
  emit(state.copyWith(
    filteredOrders: filteredOrders,
    currentFilter: event.filter,
  ));
}
}