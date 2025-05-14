// lib/logic/blocs/favorites/favorites_event.dart
part of 'favorites_bloc.dart';

abstract class FavoritesEvent extends Equatable {
  const FavoritesEvent();

  @override
  List<Object?> get props => [];
}

class LoadFavorites extends FavoritesEvent {}

class AddToFavorites extends FavoritesEvent {
  final String dishId;

  const AddToFavorites(this.dishId);

  @override
  List<Object?> get props => [dishId];
}

class RemoveFromFavorites extends FavoritesEvent {
  final String dishId;

  const RemoveFromFavorites(this.dishId);

  @override
  List<Object?> get props => [dishId];
}

class ToggleFavorite extends FavoritesEvent {
  final String dishId;

  const ToggleFavorite(this.dishId);

  @override
  List<Object?> get props => [dishId];
}