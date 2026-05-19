import '../entities/meal_entity.dart';
import '../repositories/meal_repository.dart';

class SearchMealsByName {
  final MealRepository repository;
  SearchMealsByName(this.repository);

  Future<List<MealEntity>> call(String name) =>
      repository.searchMealsByName(name);
}

class SearchMealsByIngredient {
  final MealRepository repository;
  SearchMealsByIngredient(this.repository);

  Future<List<MealEntity>> call(String ingredient) =>
      repository.searchMealsByIngredient(ingredient);
}

class GetMealById {
  final MealRepository repository;
  GetMealById(this.repository);

  Future<MealEntity?> call(String id) => repository.getMealById(id);
}

class GetRandomMeal {
  final MealRepository repository;
  GetRandomMeal(this.repository);

  Future<MealEntity?> call() => repository.getRandomMeal();
}

class GetRandomMeals {
  final MealRepository repository;
  GetRandomMeals(this.repository);

  Future<List<MealEntity>> call(int count) => repository.getRandomMeals(count);
}

class GetAllCategories {
  final MealRepository repository;
  GetAllCategories(this.repository);

  Future<List<dynamic>> call() => repository.getAllCategories();
}

class FilterMealsByCategory {
  final MealRepository repository;
  FilterMealsByCategory(this.repository);

  Future<List<MealEntity>> call(String category) =>
      repository.filterMealsByCategory(category);
}

class FilterMealsByArea {
  final MealRepository repository;
  FilterMealsByArea(this.repository);

  Future<List<MealEntity>> call(String area) =>
      repository.filterMealsByArea(area);
}

class FilterMealsByIngredients {
  final MealRepository repository;
  FilterMealsByIngredients(this.repository);

  Future<List<MealEntity>> call(List<String> ingredients) =>
      repository.filterMealsByIngredients(ingredients);
}
