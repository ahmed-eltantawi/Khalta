import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../features/search/domain/entities/meal_entity.dart';
import '../../../../features/search/domain/usecases/meal_usecases.dart';

// ─── State ────────────────────────────────────────────────────────────────────

abstract class HomeCubitState {}

class HomeInitial extends HomeCubitState {}
class HomeLoading extends HomeCubitState {}
class HomeLoaded extends HomeCubitState {
  final List<MealEntity> randomMeals;
  final List<dynamic> categories;
  HomeLoaded({required this.randomMeals, required this.categories});
}
class HomeError extends HomeCubitState {
  final String message;
  HomeError(this.message);
}

// ─── Cubit ────────────────────────────────────────────────────────────────────

class HomeCubit extends Cubit<HomeCubitState> {
  final GetRandomMeals getRandomMeals;
  final GetAllCategories getAllCategories;

  HomeCubit({required this.getRandomMeals, required this.getAllCategories})
      : super(HomeInitial());

  Future<void> loadHome() async {
    emit(HomeLoading());
    try {
      final randomMeals = await getRandomMeals(6);
      final categories = await getAllCategories();
      emit(HomeLoaded(
        randomMeals: randomMeals,
        categories: categories,
      ));
    } catch (e) {
      emit(HomeError('Failed to load home. Please check your connection.'));
    }
  }

  Future<void> refresh() => loadHome();
}
