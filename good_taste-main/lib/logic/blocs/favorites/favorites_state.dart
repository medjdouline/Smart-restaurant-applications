// lib/logic/blocs/favorites/favorites_state.dart
part of 'favorites_bloc.dart';

abstract class FavoritesState extends Equatable {
  const FavoritesState();

  @override
  List<Object> get props => [];
}

class FavoritesInitial extends FavoritesState {}

class FavoritesLoading extends FavoritesState {}

class FavoritesLoaded extends FavoritesState {
  final List<Dish> favoriteDishes;
  final List<String> favoriteIds;

  const FavoritesLoaded({
    required this.favoriteDishes,
    required this.favoriteIds,
  });

  @override
  List<Object> get props => [favoriteDishes, favoriteIds];
}

class FavoritesError extends FavoritesState {
  final String message;

  const FavoritesError({required this.message});

  @override
  List<Object> get props => [message];
}