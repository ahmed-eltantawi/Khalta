import '../entities/meal_entity.dart';
import '../entities/category_entity.dart';

abstract class MealRepository {
  Future<List<MealEntity>> searchMealsByName(String name);
  Future<List<MealEntity>> searchMealsByIngredient(String ingredient);
  Future<MealEntity?> getMealById(String id);
  Future<MealEntity?> getRandomMeal();
  Future<List<MealEntity>> getRandomMeals(int count);
  Future<List<CategoryEntity>> getAllCategories();
  Future<List<MealEntity>> filterMealsByCategory(String category);
  Future<List<MealEntity>> filterMealsByArea(String area);
  Future<List<MealEntity>> filterMealsByIngredients(List<String> ingredients);
}
