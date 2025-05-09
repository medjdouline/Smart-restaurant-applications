// lib/blocs/home/home_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/home_repository.dart';
import 'home_event.dart';
import 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final HomeRepository homeRepository;

  HomeBloc({required this.homeRepository}) : super(HomeState()) {
    on<LoadHomeDashboard>(_onLoadHomeDashboard);
    on<ToggleShowAllNewOrders>(_onToggleShowAllNewOrders);
    on<ToggleShowAllTables>(_onToggleShowAllTables);
    on<ToggleShowAllAssistanceRequests>(_onToggleShowAllAssistanceRequests);
    on<CompleteAssistanceRequest>(_onCompleteAssistanceRequest);
  }

  Future<void> _onLoadHomeDashboard(
    LoadHomeDashboard event,
    Emitter<HomeState> emit,
  ) async {
    emit(state.copyWith(status: HomeStatus.loading));
    try {
      // Récupérer les données pour le tableau de bord
      final preparingOrders = await homeRepository.getPreparingOrders();
      final readyOrders = await homeRepository.getReadyOrders();
      final assistanceRequests = await homeRepository.getAssistanceRequests();
      
      // Combiner les commandes en préparation et prêtes pour l'affichage sur le dashboard
      final recentOrders = [...preparingOrders, ...readyOrders];
      
      emit(state.copyWith(
        status: HomeStatus.loaded,
        recentOrders: recentOrders,
        assistanceRequests: assistanceRequests,
        readyOrdersCount: readyOrders.length,
        assistanceRequestsCount: assistanceRequests.length,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: HomeStatus.error,
        errorMessage: 'Impossible de charger les données du tableau de bord: ${e.toString()}',
      ));
    }
  }

  void _onToggleShowAllNewOrders(
    ToggleShowAllNewOrders event,
    Emitter<HomeState> emit,
  ) {
    emit(state.copyWith(
      showAllNewOrders: !state.showAllNewOrders,
    ));
  }

  void _onToggleShowAllTables(
    ToggleShowAllTables event,
    Emitter<HomeState> emit,
  ) {
    emit(state.copyWith(
      showAllTables: !state.showAllTables,
    ));
  }

  void _onToggleShowAllAssistanceRequests(
    ToggleShowAllAssistanceRequests event,
    Emitter<HomeState> emit,
  ) {
    emit(state.copyWith(
      showAllAssistanceRequests: !state.showAllAssistanceRequests,
    ));
  }

  Future<void> _onCompleteAssistanceRequest(
    CompleteAssistanceRequest event,
    Emitter<HomeState> emit,
  ) async {
    try {
      await homeRepository.completeAssistanceRequest(event.requestId);
      
      // Au lieu de supprimer la demande, mettre à jour son statut
      final updatedRequests = state.assistanceRequests.map((request) {
        // Si c'est la demande concernée, changer son statut
        if (request.id == event.requestId) {
          return request.copyWith(status: 'completed');
        }
        return request;
      }).toList();
      
      emit(state.copyWith(
        assistanceRequests: updatedRequests,
        status: HomeStatus.assistanceCompleted,
        assistanceRequestsCount: state.assistanceRequestsCount - 1,
      ));
      
      // Après un délai, retirer la demande terminée
      await Future.delayed(const Duration(seconds: 2));
      final filteredRequests = updatedRequests
          .where((request) => request.status != 'completed')
          .toList();
      
      emit(state.copyWith(
        assistanceRequests: filteredRequests,
      ));
      
    } catch (e) {
      emit(state.copyWith(
        status: HomeStatus.error,
        errorMessage: 'Impossible de compléter la demande d\'assistance',
      ));
    }
  }
}

