// lib/logic/blocs/home/home_bloc.dart
import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:good_taste/data/models/dish_model.dart';
import 'package:good_taste/data/repositories/dish_repository.dart';

part 'home_event.dart';
part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final DishRepository dishRepository;

  HomeBloc({
    required this.dishRepository,
  }) : super(HomeInitial()) {
    on<LoadRecommendations>(_onLoadRecommendations);
    
  }

  Future<void> _onLoadRecommendations(
    LoadRecommendations event,
    Emitter<HomeState> emit,
  ) async {
    debugPrint("HomeBloc: Loading recommendations...");
    emit(HomeLoading());
    
    try {
     
      await Future.delayed(const Duration(milliseconds: 100));
      
      final dishes = dishRepository.getRecommendedDishes();
      debugPrint("HomeBloc: Loaded ${dishes.length} dishes");
      
      if (dishes.isEmpty) {
        debugPrint("HomeBloc: No dishes found!");
      } else {
       
        debugPrint("HomeBloc: First dish: ${dishes.first.name}");
      }
      
      emit(HomeLoaded(recommendedDishes: dishes));
      debugPrint("HomeBloc: Emitted HomeLoaded state");
    } catch (e) {
      debugPrint("HomeBloc: Error loading dishes: $e");
      emit(HomeError(message: e.toString()));
    }
  }

  

  @override
  Future<void> close() {
    debugPrint("HomeBloc: Closing bloc");
    return super.close();
  }
}