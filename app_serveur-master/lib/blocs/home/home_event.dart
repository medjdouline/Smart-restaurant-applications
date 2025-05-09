abstract class HomeEvent {}

class LoadHomeDashboard extends HomeEvent {}

class ToggleShowAllTables extends HomeEvent {}

class ToggleShowAllAssistanceRequests extends HomeEvent {}

class ToggleShowAllNewOrders extends HomeEvent {}

class CompleteAssistanceRequest extends HomeEvent {
  final String requestId;
  CompleteAssistanceRequest({required this.requestId});
}