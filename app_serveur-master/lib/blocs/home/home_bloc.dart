// lib/blocs/home/home_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';
import '../../data/models/assistance_request.dart';
import '../../data/repositories/home_repository.dart';
import 'home_event.dart';
import 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final HomeRepository homeRepository;
  final _logger = Logger();
  
  HomeBloc({required this.homeRepository}) : super(HomeState.initial()) {
    on<LoadHomeDashboard>(_onLoadHomeDashboard);
    on<CompleteAssistanceRequest>(_onCompleteAssistanceRequest);
    on<ToggleShowAllAssistanceRequests>(_onToggleShowAllAssistanceRequests);
  }

  Future<void> _onLoadHomeDashboard(
    LoadHomeDashboard event,
    Emitter<HomeState> emit,
  ) async {
    try {
      emit(state.copyWith(status: HomeStatus.loading));
      
      // Fetch assistance requests
      final assistanceRequests = await homeRepository.getAssistanceRequests();
      _logger.i('Loaded ${assistanceRequests.length} assistance requests');
      
      // Log retrieved requests to help debug
      for (var request in assistanceRequests) {
        _logger.d('Assistance request: ${request.id}, status: ${request.status}, tableId: ${request.tableId}');
      }

      emit(state.copyWith(
        status: HomeStatus.loaded,
        assistanceRequests: assistanceRequests,
        assistanceRequestsCount: assistanceRequests.where((req) => 
            req.status != 'traitee' && 
            req.status != 'completed').length,
      ));
    } catch (e) {
      _logger.e('Error loading home dashboard: $e');
      emit(state.copyWith(
        status: HomeStatus.error,
        errorMessage: 'Failed to load dashboard data: $e',
      ));
    }
  }

  Future<void> _onCompleteAssistanceRequest(
    CompleteAssistanceRequest event,
    Emitter<HomeState> emit,
  ) async {
    try {
      _logger.i('Completing assistance request: ${event.requestId}');
      
      // Make API call to mark as completed
      await homeRepository.completeAssistanceRequest(event.requestId);
      
      // Update local state - find the request and update its status
      final updatedRequests = state.assistanceRequests.map((request) {
        if (request.id == event.requestId) {
          _logger.i('Marking request ${event.requestId} as completed');
          return request.copyWith(status: 'traitee');
        }
        return request;
      }).toList();

      // Count active requests (not completed/treated)
      final activeCount = updatedRequests.where((req) => 
          req.status != 'traitee' && 
          req.status != 'completed').length;
      
      emit(state.copyWith(
        assistanceRequests: updatedRequests,
        assistanceRequestsCount: activeCount,
      ));
      
      // Fetch updated data from server to ensure consistency
      add(LoadHomeDashboard());
    } catch (e) {
      _logger.e('Error completing assistance request: $e');
      emit(state.copyWith(
        errorMessage: 'Failed to complete assistance request: $e',
      ));
    }
  }

  void _onToggleShowAllAssistanceRequests(
    ToggleShowAllAssistanceRequests event,
    Emitter<HomeState> emit,
  ) {
    emit(state.copyWith(
      showAllAssistanceRequests: !state.showAllAssistanceRequests,
    ));
  }
}
