// lib/blocs/home/home_state.dart
import '../../data/models/order.dart';
import '../../data/models/table.dart';
import '../../data/models/assistance_request.dart';

enum HomeStatus {
  initial,
  loading,
  loaded,
  error,
  assistanceCompleted,
}

class HomeState {
  final HomeStatus status;
  final List<Order> recentOrders; // Commandes en préparation et prêtes
  final List<RestaurantTable> activeTables;
  final List<AssistanceRequest> assistanceRequests;
  final String? errorMessage;
  final bool showAllNewOrders;
  final bool showAllTables;
  final bool showAllAssistanceRequests;
  final int readyOrdersCount; // Pour l'affichage dans les cartes de résumé
  final int assistanceRequestsCount; // Pour l'affichage dans les cartes de résumé

  HomeState({
    this.status = HomeStatus.initial,
    this.recentOrders = const [],
    this.activeTables = const [],
    this.assistanceRequests = const [],
    this.errorMessage,
    this.showAllNewOrders = false,
    this.showAllTables = false,
    this.showAllAssistanceRequests = false,
    this.readyOrdersCount = 0,
    this.assistanceRequestsCount = 0,
  });

  HomeState copyWith({
    HomeStatus? status,
    List<Order>? recentOrders,
    List<RestaurantTable>? activeTables,
    List<AssistanceRequest>? assistanceRequests,
    String? errorMessage,
    bool? showAllNewOrders,
    bool? showAllTables,
    bool? showAllAssistanceRequests,
    int? readyOrdersCount,
    int? assistanceRequestsCount,
  }) {
    return HomeState(
      status: status ?? this.status,
      recentOrders: recentOrders ?? this.recentOrders,
      activeTables: activeTables ?? this.activeTables,
      assistanceRequests: assistanceRequests ?? this.assistanceRequests,
      errorMessage: errorMessage ?? this.errorMessage,
      showAllNewOrders: showAllNewOrders ?? this.showAllNewOrders,
      showAllTables: showAllTables ?? this.showAllTables,
      showAllAssistanceRequests: showAllAssistanceRequests ?? this.showAllAssistanceRequests,
      readyOrdersCount: readyOrdersCount ?? this.readyOrdersCount,
      assistanceRequestsCount: assistanceRequestsCount ?? this.assistanceRequestsCount,
    );
  }

  // Méthodes pour obtenir le nombre d'éléments à afficher en fonction de l'état
  List<Order> getVisibleNewOrders() {
    if (showAllNewOrders || recentOrders.length <= 2) {
      return recentOrders;
    }
    return recentOrders.sublist(0, 2);
  }

  List<RestaurantTable> getVisibleTables() {
    if (showAllTables || activeTables.length <= 2) {
      return activeTables;
    }
    return activeTables.sublist(0, 2);
  }

  List<AssistanceRequest> getVisibleAssistanceRequests() {
    if (showAllAssistanceRequests || assistanceRequests.length <= 2) {
      return assistanceRequests;
    }
    return assistanceRequests.sublist(0, 2);
  }

  bool shouldShowNewOrdersViewMore() {
    return !showAllNewOrders && recentOrders.length > 2;
  }

  bool shouldShowTablesViewMore() {
    return !showAllTables && activeTables.length > 2;
  }

  bool shouldShowAssistanceRequestsViewMore() {
    return !showAllAssistanceRequests && assistanceRequests.length > 2;
  }
}