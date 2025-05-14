// part of 'home_bloc.dart'
part of 'home_bloc.dart';

abstract class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object?> get props => [];
}

class LoadRecommendations extends HomeEvent {}


class ToggleFavorite extends HomeEvent {
  final String dishId;

  const ToggleFavorite(this.dishId);

  @override
  List<Object?> get props => [dishId];
}