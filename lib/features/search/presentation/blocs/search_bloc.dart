import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../features/search/domain/entities/meal_entity.dart';
import '../../../../features/search/domain/entities/category_entity.dart';
import '../../../../features/search/domain/usecases/meal_usecases.dart';

// ─── Events ───────────────────────────────────────────────────────────────────

abstract class SearchEvent extends Equatable {
  const SearchEvent();
  @override
  List<Object?> get props => [];
}

class LoadCategoriesEvent extends SearchEvent {
  const LoadCategoriesEvent();
}

class SearchQueryChanged extends SearchEvent {
  final String query;
  const SearchQueryChanged(this.query);
  @override
  List<Object?> get props => [query];
}

class IngredientSearched extends SearchEvent {
  final String ingredient;
  const IngredientSearched(this.ingredient);
  @override
  List<Object?> get props => [ingredient];
}

class CategoryFilterSelected extends SearchEvent {
  final String? category;
  const CategoryFilterSelected(this.category);
  @override
  List<Object?> get props => [category];
}

class AreaFilterSelected extends SearchEvent {
  final String? area;
  const AreaFilterSelected(this.area);
  @override
  List<Object?> get props => [area];
}

class ClearFiltersEvent extends SearchEvent {
  const ClearFiltersEvent();
}

// ─── States ───────────────────────────────────────────────────────────────────

abstract class SearchState extends Equatable {
  const SearchState();
  @override
  List<Object?> get props => [];
}

class SearchInitial extends SearchState {
  final List<CategoryEntity> categories;
  const SearchInitial({this.categories = const []});
  @override
  List<Object?> get props => [categories];
}

class SearchLoading extends SearchState {
  const SearchLoading();
}

class SearchSuccess extends SearchState {
  final List<MealEntity> meals;
  final List<CategoryEntity> categories;
  final String? activeCategory;
  final String? activeArea;
  final String query;

  const SearchSuccess({
    required this.meals,
    this.categories = const [],
    this.activeCategory,
    this.activeArea,
    this.query = '',
  });

  @override
  List<Object?> get props => [meals, activeCategory, activeArea, query];
}

class SearchEmpty extends SearchState {
  final String query;
  const SearchEmpty({required this.query});
  @override
  List<Object?> get props => [query];
}

class SearchError extends SearchState {
  final String message;
  const SearchError(this.message);
  @override
  List<Object?> get props => [message];
}

// ─── BLoC ─────────────────────────────────────────────────────────────────────

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final SearchMealsByName searchMealsByName;
  final SearchMealsByIngredient searchMealsByIngredient;
  final FilterMealsByCategory filterMealsByCategory;
  final FilterMealsByArea filterMealsByArea;
  final GetAllCategories getAllCategories;

  List<CategoryEntity> _categories = [];

  SearchBloc({
    required this.searchMealsByName,
    required this.searchMealsByIngredient,
    required this.filterMealsByCategory,
    required this.filterMealsByArea,
    required this.getAllCategories,
  }) : super(const SearchInitial()) {
    on<LoadCategoriesEvent>(_onLoadCategories);
    on<SearchQueryChanged>(_onSearchQueryChanged);
    on<IngredientSearched>(_onIngredientSearched);
    on<CategoryFilterSelected>(_onCategoryFilter);
    on<AreaFilterSelected>(_onAreaFilter);
    on<ClearFiltersEvent>(_onClearFilters);
  }

  Future<void> _onLoadCategories(
    LoadCategoriesEvent event,
    Emitter<SearchState> emit,
  ) async {
    try {
      _categories = (await getAllCategories()).cast<CategoryEntity>();
      emit(SearchInitial(categories: _categories));
    } catch (_) {
      emit(SearchInitial(categories: const []));
    }
  }

  Future<void> _onSearchQueryChanged(
    SearchQueryChanged event,
    Emitter<SearchState> emit,
  ) async {
    if (event.query.trim().isEmpty) {
      emit(SearchInitial(categories: _categories));
      return;
    }
    emit(const SearchLoading());
    try {
      final meals = await searchMealsByName(event.query.trim());
      if (meals.isEmpty) {
        emit(SearchEmpty(query: event.query));
      } else {
        emit(SearchSuccess(
          meals: meals,
          categories: _categories,
          query: event.query,
        ));
      }
    } catch (e) {
      emit(SearchError(e.toString()));
    }
  }

  Future<void> _onIngredientSearched(
    IngredientSearched event,
    Emitter<SearchState> emit,
  ) async {
    emit(const SearchLoading());
    try {
      final meals = await searchMealsByIngredient(event.ingredient);
      if (meals.isEmpty) {
        emit(SearchEmpty(query: event.ingredient));
      } else {
        emit(SearchSuccess(meals: meals, categories: _categories, query: event.ingredient));
      }
    } catch (e) {
      emit(SearchError(e.toString()));
    }
  }

  Future<void> _onCategoryFilter(
    CategoryFilterSelected event,
    Emitter<SearchState> emit,
  ) async {
    if (event.category == null) {
      emit(SearchInitial(categories: _categories));
      return;
    }
    emit(const SearchLoading());
    try {
      final meals = await filterMealsByCategory(event.category!);
      emit(SearchSuccess(
        meals: meals,
        categories: _categories,
        activeCategory: event.category,
      ));
    } catch (e) {
      emit(SearchError(e.toString()));
    }
  }

  Future<void> _onAreaFilter(
    AreaFilterSelected event,
    Emitter<SearchState> emit,
  ) async {
    if (event.area == null) {
      emit(SearchInitial(categories: _categories));
      return;
    }
    emit(const SearchLoading());
    try {
      final meals = await filterMealsByArea(event.area!);
      emit(SearchSuccess(
        meals: meals,
        categories: _categories,
        activeArea: event.area,
      ));
    } catch (e) {
      emit(SearchError(e.toString()));
    }
  }

  void _onClearFilters(ClearFiltersEvent event, Emitter<SearchState> emit) {
    emit(SearchInitial(categories: _categories));
  }
}
