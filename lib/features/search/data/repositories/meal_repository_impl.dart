import '../../../../core/error/exceptions.dart';
import '../../domain/entities/meal_entity.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/repositories/meal_repository.dart';
import '../datasources/meal_remote_datasource.dart';

class MealRepositoryImpl implements MealRepository {
  final MealRemoteDataSource _remoteDataSource;

  MealRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<MealEntity>> searchMealsByName(String name) async {
    try {
      return await _remoteDataSource.searchMealsByName(name);
    } on ServerException {
      rethrow;
    }
  }

  @override
  Future<List<MealEntity>> searchMealsByIngredient(String ingredient) async {
    try {
      return await _remoteDataSource.searchMealsByIngredient(ingredient);
    } on ServerException {
      rethrow;
    }
  }

  @override
  Future<MealEntity?> getMealById(String id) async {
    try {
      return await _remoteDataSource.getMealById(id);
    } on ServerException {
      rethrow;
    }
  }

  @override
  Future<MealEntity?> getRandomMeal() async {
    try {
      return await _remoteDataSource.getRandomMeal();
    } on ServerException {
      rethrow;
    }
  }

  @override
  Future<List<MealEntity>> getRandomMeals(int count) async {
    final meals = <MealEntity>[];
    for (int i = 0; i < count; i++) {
      try {
        final meal = await _remoteDataSource.getRandomMeal();
        if (meal != null) meals.add(meal);
      } catch (_) {}
    }
    return meals;
  }

  @override
  Future<List<CategoryEntity>> getAllCategories() async {
    try {
      return await _remoteDataSource.getAllCategories();
    } on ServerException {
      rethrow;
    }
  }

  @override
  Future<List<MealEntity>> filterMealsByCategory(String category) async {
    try {
      return await _remoteDataSource.filterMealsByCategory(category);
    } on ServerException {
      rethrow;
    }
  }

  @override
  Future<List<MealEntity>> filterMealsByArea(String area) async {
    try {
      return await _remoteDataSource.filterMealsByArea(area);
    } on ServerException {
      rethrow;
    }
  }

  @override
  Future<List<MealEntity>> filterMealsByIngredients(
      List<String> ingredients) async {
    if (ingredients.isEmpty) return [];
    if (ingredients.length == 1) {
      try {
        return await _remoteDataSource.searchMealsByIngredient(ingredients.first);
      } on ServerException {
        rethrow;
      }
    }

    // Fetch a lightweight list (idMeal, strMeal, strMealThumb) for every
    // ingredient in parallel, then intersect by meal ID.
    try {
      final futures = ingredients
          .map((i) => _remoteDataSource.searchMealsByIngredient(i))
          .toList();
      final results = await Future.wait(futures);

      // Build ID set for the first ingredient
      var commonIds = results.first.map((m) => m.id).toSet();
      for (int i = 1; i < results.length; i++) {
        commonIds = commonIds.intersection(results[i].map((m) => m.id).toSet());
      }

      // Keep only meals whose ID appears in every set (preserving order)
      return results.first
          .where((m) => commonIds.contains(m.id))
          .toList();
    } on ServerException {
      rethrow;
    }
  }


  @override
  Future<List<String>> getAllIngredients() async {
    try {
      return await _remoteDataSource.getAllIngredients();
    } on ServerException {
      rethrow;
    }
  }
}
