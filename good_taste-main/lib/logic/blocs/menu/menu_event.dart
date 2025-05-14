part of 'menu_bloc.dart';

abstract class MenuEvent extends Equatable {
  const MenuEvent();

  @override
  List<Object?> get props => [];
}

class ResetSelection extends MenuEvent {}
class LoadCategories extends MenuEvent {}

class SelectCategory extends MenuEvent {
  final Category category;

  const SelectCategory(this.category);

  @override
  List<Object?> get props => [category];
}

class LoadSubcategoryDishes extends MenuEvent {
  final String subCategoryName;

  const LoadSubcategoryDishes(this.subCategoryName);

  @override
  List<Object?> get props => [subCategoryName];
}