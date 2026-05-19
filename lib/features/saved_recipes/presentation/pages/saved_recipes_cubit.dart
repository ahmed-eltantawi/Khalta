import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../features/saved_recipes/data/datasources/saved_recipes_datasource.dart';
import '../../../../features/search/domain/entities/meal_entity.dart';

class SavedRecipesCubit extends Cubit<List<MealEntity>> {
  final SavedRecipesDataSource _dataSource;

  SavedRecipesCubit(this._dataSource) : super(const []);

  void loadSaved() {
    emit(_dataSource.getAll());
  }

  Future<void> toggleSave(MealEntity meal) async {
    if (_dataSource.isSaved(meal.id)) {
      await _dataSource.remove(meal.id);
    } else {
      await _dataSource.save(meal);
    }
    emit(_dataSource.getAll());
  }

  bool isSaved(String id) => _dataSource.isSaved(id);
}
