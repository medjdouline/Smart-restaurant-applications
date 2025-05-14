// lib/logic/blocs/favorites/favorites_bloc.dart
import 'dart:async';
import 'dart:convert';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:good_taste/data/models/dish_model.dart';
import 'package:good_taste/data/repositories/dish_repository.dart';

part 'favorites_event.dart';
part 'favorites_state.dart';

class FavoritesBloc extends Bloc<FavoritesEvent, FavoritesState> {
  final DishRepository dishRepository;
  final String userId;
  static const String _storageKey = 'user_favorites';

  FavoritesBloc({
    required this.dishRepository,
    required this.userId,
  }) : super(FavoritesInitial()) {
    on<LoadFavorites>(_onLoadFavorites);
    on<AddToFavorites>(_onAddToFavorites);
    on<RemoveFromFavorites>(_onRemoveFromFavorites);
    on<ToggleFavorite>(_onToggleFavorite);
  }

  Future<void> _onLoadFavorites(
    LoadFavorites event,
    Emitter<FavoritesState> emit,
  ) async {
    emit(FavoritesLoading());
    try {
      final favoriteIds = await _loadFavoriteIds();
      final allDishes = dishRepository.getAllDishes();
      
      final favoriteDishes = allDishes
          .where((dish) => favoriteIds.contains(dish.id))
          .toList();
      
      emit(FavoritesLoaded(
        favoriteDishes: favoriteDishes,
        favoriteIds: favoriteIds,
      ));
    } catch (e) {
      emit(FavoritesError(message: e.toString()));
    }
  }

  Future<void> _onAddToFavorites(
    AddToFavorites event,
    Emitter<FavoritesState> emit,
  ) async {
    if (state is FavoritesLoaded) {
      try {
        final currentState = state as FavoritesLoaded;
        final updatedIds = List<String>.from(currentState.favoriteIds)
          ..add(event.dishId);
        
        await _saveFavoriteIds(updatedIds);
        
        final allDishes = dishRepository.getAllDishes();
        final favoriteDishes = allDishes
            .where((dish) => updatedIds.contains(dish.id))
            .toList();
        
        emit(FavoritesLoaded(
          favoriteDishes: favoriteDishes,
          favoriteIds: updatedIds,
        ));
      } catch (e) {
        emit(FavoritesError(message: e.toString()));
      }
    }
  }

  Future<void> _onRemoveFromFavorites(
    RemoveFromFavorites event,
    Emitter<FavoritesState> emit,
  ) async {
    if (state is FavoritesLoaded) {
      try {
        final currentState = state as FavoritesLoaded;
        final updatedIds = List<String>.from(currentState.favoriteIds)
          ..remove(event.dishId);
        
        await _saveFavoriteIds(updatedIds);
        
        final allDishes = dishRepository.getAllDishes();
        final favoriteDishes = allDishes
            .where((dish) => updatedIds.contains(dish.id))
            .toList();
        
        emit(FavoritesLoaded(
          favoriteDishes: favoriteDishes,
          favoriteIds: updatedIds,
        ));
      } catch (e) {
        emit(FavoritesError(message: e.toString()));
      }
    }
  }

  Future<void> _onToggleFavorite(
    ToggleFavorite event,
    Emitter<FavoritesState> emit,
  ) async {
    if (state is FavoritesLoaded) {
      final currentState = state as FavoritesLoaded;
      final isCurrentlyFavorite = currentState.favoriteIds.contains(event.dishId);
      
      if (isCurrentlyFavorite) {
        add(RemoveFromFavorites(event.dishId));
      } else {
        add(AddToFavorites(event.dishId));
      }
    }
  }

 
  Future<List<String>> _loadFavoriteIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedFavorites = prefs.getString('$_storageKey:$userId');
      
      if (storedFavorites != null) {
        final List<dynamic> decoded = jsonDecode(storedFavorites);
        return decoded.map((e) => e.toString()).toList();
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement des favoris: $e');
    }
    return [];
  }

  Future<void> _saveFavoriteIds(List<String> favoriteIds) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(favoriteIds);
      await prefs.setString('$_storageKey:$userId', encoded);
    } catch (e) {
      debugPrint('Erreur lors de la sauvegarde des favoris: $e');
      throw Exception('Impossible de sauvegarder les favoris');
    }
  }
}