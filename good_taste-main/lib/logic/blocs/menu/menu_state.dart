// part of 'menu_bloc.dart'
part of 'menu_bloc.dart';

abstract class MenuState extends Equatable {
  const MenuState();

  @override
  List<Object?> get props => [];
}

class MenuInitial extends MenuState {}

class MenuLoading extends MenuState {}

class CategoriesLoaded extends MenuState {
  final List<Category> categories;
  final Category? selectedCategory;
  final List<Dish> dishes; 

  const CategoriesLoaded({
    required this.categories,
    this.selectedCategory,
    required this.dishes,
  });

  @override
  List<Object?> get props => [
    categories,
    selectedCategory,
    dishes,
  ];
}

class SubcategoryDishesLoaded extends MenuState {
  final String subCategoryName;
  final List<Dish> dishes;

  const SubcategoryDishesLoaded({
    required this.subCategoryName,
    required this.dishes,
  });

  @override
  List<Object> get props => [subCategoryName, dishes];
}

class MenuError extends MenuState {
  final String message;

  const MenuError({required this.message});

  @override
  List<Object> get props => [message];
}