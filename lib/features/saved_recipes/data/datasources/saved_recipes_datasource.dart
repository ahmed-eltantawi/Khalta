import 'package:hive_flutter/hive_flutter.dart';
import '../../../search/domain/entities/meal_entity.dart';

class SavedRecipesDataSource {
  static const String _boxName = 'saved_recipes';

  Box get _box => Hive.box(_boxName);

  static Future<void> init() async {
    await Hive.openBox(_boxName);
  }

  List<MealEntity> getAll() {
    return _box.values
        .map((e) => MealEntity.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> save(MealEntity meal) async {
    await _box.put(meal.id, meal.toMap());
  }

  Future<void> remove(String id) async {
    await _box.delete(id);
  }

  bool isSaved(String id) => _box.containsKey(id);

  Future<void> clear() async => _box.clear();
}
