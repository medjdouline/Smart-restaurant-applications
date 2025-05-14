// lib/blocs/home/home_state.dart
import '../../data/models/assistance_request.dart';

enum HomeStatus { initial, loading, loaded, error }

class HomeState {
  final HomeStatus status;
  final List<AssistanceRequest> assistanceRequests;
  final int assistanceRequestsCount;
  final bool showAllAssistanceRequests;
  final String? errorMessage;
  
  HomeState({
    required this.status,
    required this.assistanceRequests,
    required this.assistanceRequestsCount,
    required this.showAllAssistanceRequests,
    this.errorMessage,
  });
  
  factory HomeState.initial() {
    return HomeState(
      status: HomeStatus.initial,
      assistanceRequests: [],
      assistanceRequestsCount: 0,
      showAllAssistanceRequests: false,
      errorMessage: null,
    );
  }
  
  HomeState copyWith({
    HomeStatus? status,
    List<AssistanceRequest>? assistanceRequests,
    int? assistanceRequestsCount,
    bool? showAllAssistanceRequests,
    String? errorMessage,
  }) {
    return HomeState(
      status: status ?? this.status,
      assistanceRequests: assistanceRequests ?? this.assistanceRequests,
      assistanceRequestsCount: assistanceRequestsCount ?? this.assistanceRequestsCount,
      showAllAssistanceRequests: showAllAssistanceRequests ?? this.showAllAssistanceRequests,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
  
  // Get only the assistance requests that should be visible based on showAllAssistanceRequests
  List<AssistanceRequest> getVisibleAssistanceRequests() {
    if (showAllAssistanceRequests) {
      return assistanceRequests;
    }
    
    // Show only the first 3 requests
    const int maxRequestsToShow = 3;
    return assistanceRequests.length <= maxRequestsToShow 
        ? assistanceRequests 
        : assistanceRequests.sublist(0, maxRequestsToShow);
  }
  
  // Determine if the "View More" button should be shown
  bool shouldShowAssistanceRequestsViewMore() {
    return !showAllAssistanceRequests && assistanceRequests.length > 3;
  }
}