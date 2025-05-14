// part of 'home_bloc.dart'
part of 'home_bloc.dart';

abstract class HomeState extends Equatable {
  const HomeState();
  
  @override
  List<Object> get props => [];
}

class HomeInitial extends HomeState {}

class HomeLoading extends HomeState {}

class HomeLoaded extends HomeState {
  final List<Dish> recommendedDishes;

  const HomeLoaded({required this.recommendedDishes});

  @override
  List<Object> get props => [recommendedDishes];
}

class HomeError extends HomeState {
  final String message;

  const HomeError({required this.message});

  @override
  List<Object> get props => [message];
}