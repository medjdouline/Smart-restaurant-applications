// lib/logic/helpers/favorites_helper.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:good_taste/logic/blocs/favorites/favorites_bloc.dart';

class FavoritesHelper {

  static bool isDishFavorite(BuildContext context, String dishId) {
    final favoritesState = context.watch<FavoritesBloc>().state;
    if (favoritesState is FavoritesLoaded) {
      return favoritesState.favoriteIds.contains(dishId);
    }
    return false;
  }


  static void toggleFavorite(BuildContext context, String dishId, String dishName) {
    final favoritesState = context.read<FavoritesBloc>().state;
    if (favoritesState is FavoritesLoaded) {
      context.read<FavoritesBloc>().add(ToggleFavorite(dishId));
    }
  }
}