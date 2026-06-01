import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../features/virtual_fridge/data/datasources/fridge_local_datasource.dart';
import '../../../../features/virtual_fridge/domain/entities/fridge_item_entity.dart';
import '../../../../features/search/domain/entities/meal_entity.dart';
import '../../../../features/search/domain/usecases/meal_usecases.dart';

// ─── Events ───────────────────────────────────────────────────────────────────

abstract class FridgeEvent extends Equatable {
  const FridgeEvent();
  @override
  List<Object?> get props => [];
}

class LoadFridgeEvent extends FridgeEvent {
  const LoadFridgeEvent();
}

class AddFridgeItemEvent extends FridgeEvent {
  final FridgeItemEntity item;
  const AddFridgeItemEvent(this.item);
  @override
  List<Object?> get props => [item];
}

class RemoveFridgeItemEvent extends FridgeEvent {
  final String id;
  const RemoveFridgeItemEvent(this.id);
  @override
  List<Object?> get props => [id];
}

class UpdateFridgeItemEvent extends FridgeEvent {
  final FridgeItemEntity item;
  const UpdateFridgeItemEvent(this.item);
  @override
  List<Object?> get props => [item];
}

class SearchRecipesFromFridgeEvent extends FridgeEvent {
  const SearchRecipesFromFridgeEvent();
}

// ─── States ───────────────────────────────────────────────────────────────────

abstract class FridgeState extends Equatable {
  const FridgeState();
  @override
  List<Object?> get props => [];
}

class FridgeInitial extends FridgeState {}

class FridgeLoading extends FridgeState {}

class FridgeLoaded extends FridgeState {
  final List<FridgeItemEntity> items;
  final List<MealEntity>? suggestedMeals;
  final List<MealEntity>? perfectMatches;

  const FridgeLoaded({
    required this.items,
    this.suggestedMeals,
    this.perfectMatches,
  });

  @override
  List<Object?> get props => [items, suggestedMeals, perfectMatches];
}

class FridgeError extends FridgeState {
  final String message;
  const FridgeError(this.message);
  @override
  List<Object?> get props => [message];
}

// ─── BLoC ─────────────────────────────────────────────────────────────────────

class FridgeBloc extends Bloc<FridgeEvent, FridgeState> {
  final FridgeLocalDataSource dataSource;
  final SearchMealsByIngredient searchMealsByIngredient;

  FridgeBloc({
    required this.dataSource,
    required this.searchMealsByIngredient,
  }) : super(FridgeInitial()) {
    on<LoadFridgeEvent>(_onLoad);
    on<AddFridgeItemEvent>(_onAdd);
    on<RemoveFridgeItemEvent>(_onRemove);
    on<UpdateFridgeItemEvent>(_onUpdate);
    on<SearchRecipesFromFridgeEvent>(_onSearchRecipes);
  }

  void _onLoad(LoadFridgeEvent event, Emitter<FridgeState> emit) {
    try {
      final items = dataSource.getAll();
      emit(FridgeLoaded(items: items));
    } catch (e) {
      emit(const FridgeError('Failed to load fridge items.'));
    }
  }

  Future<void> _onAdd(
      AddFridgeItemEvent event, Emitter<FridgeState> emit) async {
    await dataSource.add(event.item);
    final items = dataSource.getAll();
    emit(FridgeLoaded(items: items));
  }

  Future<void> _onRemove(
      RemoveFridgeItemEvent event, Emitter<FridgeState> emit) async {
    await dataSource.delete(event.id);
    final items = dataSource.getAll();
    emit(FridgeLoaded(items: items));
  }

  Future<void> _onUpdate(
      UpdateFridgeItemEvent event, Emitter<FridgeState> emit) async {
    await dataSource.update(event.item);
    final items = dataSource.getAll();
    emit(FridgeLoaded(items: items));
  }

  Future<void> _onSearchRecipes(
    SearchRecipesFromFridgeEvent event,
    Emitter<FridgeState> emit,
  ) async {
    final currentItems = dataSource.getAll();
    if (currentItems.isEmpty) return;

    emit(FridgeLoading());
    try {
      final ingredientNames =
          currentItems.map((e) => e.name.toLowerCase()).toList();

      // Perform parallel searches for each ingredient
      final futures =
          ingredientNames.map((ing) => searchMealsByIngredient(ing));
      final results = await Future.wait(futures);

      // Calculate perfect matches (intersection) and possible options (union)
      final Map<String, int> mealCounts = {};
      final Map<String, MealEntity> mealMap = {};

      for (int i = 0; i < results.length; i++) {
        final list = results[i];
        for (final meal in list) {
          mealMap[meal.id] = meal;
          mealCounts[meal.id] = (mealCounts[meal.id] ?? 0) + 1;
        }
      }

      final int requiredCount = ingredientNames.length;
      final List<MealEntity> perfect = [];
      final List<MealEntity> possible = [];

      for (final id in mealCounts.keys) {
        final meal = mealMap[id]!;
        if (mealCounts[id] == requiredCount) {
          perfect.add(meal);
        } else {
          possible.add(meal);
        }
      }

      emit(FridgeLoaded(
        items: currentItems,
        suggestedMeals: possible,
        perfectMatches: perfect,
      ));
    } catch (e) {
      emit(FridgeLoaded(
          items: currentItems,
          suggestedMeals: const [],
          perfectMatches: const []));
    }
  }
}
