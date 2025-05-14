// lib/blocs/home/home_event.dart
abstract class HomeEvent {}

class LoadHomeDashboard extends HomeEvent {}

class CompleteAssistanceRequest extends HomeEvent {
  final String requestId;
  
  CompleteAssistanceRequest({required this.requestId});
}

class ToggleShowAllAssistanceRequests extends HomeEvent {}