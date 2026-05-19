import '../../domain/entities/meal_entity.dart';

class MealModel extends MealEntity {
  const MealModel({
    required super.id,
    required super.name,
    super.category,
    super.area,
    super.instructions,
    super.thumbnailUrl,
    super.youtubeUrl,
    super.tags,
    super.ingredients,
    super.measurements,
  });

  factory MealModel.fromJson(Map<String, dynamic> json) {
    // Extract up to 20 ingredient/measure pairs
    final ingredients = <String>[];
    final measurements = <String>[];

    for (int i = 1; i <= 20; i++) {
      final ingredient = json['strIngredient$i'];
      final measure = json['strMeasure$i'];
      if (ingredient != null && ingredient.toString().trim().isNotEmpty) {
        ingredients.add(ingredient.toString().trim());
        measurements.add(measure?.toString().trim() ?? '');
      }
    }

    return MealModel(
      id: json['idMeal']?.toString() ?? '',
      name: json['strMeal']?.toString() ?? '',
      category: json['strCategory']?.toString(),
      area: json['strArea']?.toString(),
      instructions: json['strInstructions']?.toString(),
      thumbnailUrl: json['strMealThumb']?.toString(),
      youtubeUrl: json['strYoutube']?.toString(),
      tags: json['strTags']?.toString(),
      ingredients: ingredients,
      measurements: measurements,
    );
  }

  /// Lightweight model from filter endpoints (only has id, name, thumbnail)
  factory MealModel.fromFilterJson(Map<String, dynamic> json) {
    return MealModel(
      id: json['idMeal']?.toString() ?? '',
      name: json['strMeal']?.toString() ?? '',
      thumbnailUrl: json['strMealThumb']?.toString(),
    );
  }
}
