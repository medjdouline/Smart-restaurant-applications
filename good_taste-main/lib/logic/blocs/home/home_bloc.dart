// lib/logic/blocs/home/home_bloc.dart
import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:good_taste/data/models/dish_model.dart';
import 'package:good_taste/data/repositories/dish_repository.dart';
import 'package:good_taste/data/services/dish_api_service.dart';
import 'package:good_taste/di/di.dart';
part 'home_event.dart';
part 'home_state.dart';


class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final DishRepository dishRepository;
  final DishApiService _dishApiService;

  HomeBloc({
    required this.dishRepository,
  }) : _dishApiService = DependencyInjection.getDishApiService(),
       super(HomeInitial()) {
    on<LoadRecommendations>(_onLoadRecommendations);
  }

   Future<void> _onLoadRecommendations(
    LoadRecommendations event,
    Emitter<HomeState> emit,
  ) async {
    debugPrint("HomeBloc: Loading recommendations...");
    emit(HomeLoading());
    
    try {
      // First try to get recommendations from API
      final dishes = await _dishApiService.getRecommendedDishes();
      
      debugPrint("HomeBloc: Loaded ${dishes.length} dishes from API");
      
      if (dishes.isEmpty) {
        debugPrint("HomeBloc: No dishes from API, falling back to local");
        // Fallback to local recommendations if API returns empty
        final localDishes = dishRepository.getRecommendedDishes();
        emit(HomeLoaded(recommendedDishes: localDishes));
      } else {
        emit(HomeLoaded(recommendedDishes: dishes));
      }
    } catch (e) {
      debugPrint("HomeBloc: Error loading dishes from API: $e");
      // Fallback to local recommendations on error
      final localDishes = dishRepository.getRecommendedDishes();
      emit(HomeLoaded(recommendedDishes: localDishes));
    }
  }

  @override
  Future<void> close() {
    debugPrint("HomeBloc: Closing bloc");
    return super.close();
  }
}
