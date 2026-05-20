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

class LoadIngredientSuggestions extends SearchEvent {
  const LoadIngredientSuggestions();
}

class SearchQueryChanged extends SearchEvent {
  final String query;
  const SearchQueryChanged(this.query);
  @override
  List<Object?> get props => [query];
}

/// Tapped a suggestion chip in the dropdown — adds it to the active filter set.
class IngredientChipAdded extends SearchEvent {
  final String ingredient;
  const IngredientChipAdded(this.ingredient);
  @override
  List<Object?> get props => [ingredient];
}

/// Removed a chip from the active filter set.
class IngredientChipRemoved extends SearchEvent {
  final String ingredient;
  const IngredientChipRemoved(this.ingredient);
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

class DismissSuggestions extends SearchEvent {
  const DismissSuggestions();
}

// ─── States ───────────────────────────────────────────────────────────────────

abstract class SearchState extends Equatable {
  const SearchState();
  @override
  List<Object?> get props => [];
}

class SearchInitial extends SearchState {
  final List<CategoryEntity> categories;
  final List<String> suggestions;
  final List<String> selectedIngredients;
  const SearchInitial({
    this.categories = const [],
    this.suggestions = const [],
    this.selectedIngredients = const [],
  });
  @override
  List<Object?> get props => [categories, suggestions, selectedIngredients];
}

class SearchLoading extends SearchState {
  final List<String> selectedIngredients;
  const SearchLoading({this.selectedIngredients = const []});
  @override
  List<Object?> get props => [selectedIngredients];
}

class SearchSuccess extends SearchState {
  final List<MealEntity> meals;
  final List<CategoryEntity> categories;
  final String? activeCategory;
  final String? activeArea;
  final String query;
  final List<String> selectedIngredients;

  const SearchSuccess({
    required this.meals,
    this.categories = const [],
    this.activeCategory,
    this.activeArea,
    this.query = '',
    this.selectedIngredients = const [],
  });

  @override
  List<Object?> get props =>
      [meals, activeCategory, activeArea, query, selectedIngredients];
}

class SearchEmpty extends SearchState {
  final String query;
  final List<String> selectedIngredients;
  const SearchEmpty({
    required this.query,
    this.selectedIngredients = const [],
  });
  @override
  List<Object?> get props => [query, selectedIngredients];
}

class SearchError extends SearchState {
  final String message;
  final List<String> selectedIngredients;
  const SearchError(this.message, {this.selectedIngredients = const []});
  @override
  List<Object?> get props => [message, selectedIngredients];
}

/// Emitted while the user is typing — carries filtered autocomplete hits.
class IngredientSuggestionsUpdated extends SearchState {
  final List<String> suggestions;
  final List<CategoryEntity> categories;
  final List<String> selectedIngredients;
  const IngredientSuggestionsUpdated({
    required this.suggestions,
    this.categories = const [],
    this.selectedIngredients = const [],
  });
  @override
  List<Object?> get props => [suggestions, categories, selectedIngredients];
}

// ─── BLoC ─────────────────────────────────────────────────────────────────────

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final SearchMealsByName searchMealsByName;
  final SearchMealsByIngredient searchMealsByIngredient;
  final FilterMealsByCategory filterMealsByCategory;
  final FilterMealsByArea filterMealsByArea;
  final GetAllCategories getAllCategories;
  final GetAllIngredients getAllIngredients;
  final FilterMealsByIngredients filterMealsByIngredients;

  List<CategoryEntity> _categories = [];
  List<String> _allIngredients = [];
  List<String> _selectedIngredients = [];

  SearchBloc({
    required this.searchMealsByName,
    required this.searchMealsByIngredient,
    required this.filterMealsByCategory,
    required this.filterMealsByArea,
    required this.getAllCategories,
    required this.getAllIngredients,
    required this.filterMealsByIngredients,
  }) : super(const SearchInitial()) {
    on<LoadCategoriesEvent>(_onLoadCategories);
    on<LoadIngredientSuggestions>(_onLoadIngredientSuggestions);
    on<SearchQueryChanged>(_onSearchQueryChanged);
    on<IngredientChipAdded>(_onIngredientChipAdded);
    on<IngredientChipRemoved>(_onIngredientChipRemoved);
    on<CategoryFilterSelected>(_onCategoryFilter);
    on<AreaFilterSelected>(_onAreaFilter);
    on<ClearFiltersEvent>(_onClearFilters);
    on<DismissSuggestions>(_onDismissSuggestions);
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  /// Re-runs the ingredient intersection search with the current chip set.
  Future<void> _searchBySelectedIngredients(Emitter<SearchState> emit) async {
    emit(SearchLoading(selectedIngredients: _selectedIngredients));
    try {
      final meals = await filterMealsByIngredients(_selectedIngredients);
      if (meals.isEmpty) {
        emit(SearchEmpty(
          query: _selectedIngredients.join(' + '),
          selectedIngredients: _selectedIngredients,
        ));
      } else {
        emit(SearchSuccess(
          meals: meals,
          categories: _categories,
          selectedIngredients: _selectedIngredients,
          query: _selectedIngredients.join(' + '),
        ));
      }
    } catch (e) {
      emit(SearchError(e.toString(),
          selectedIngredients: _selectedIngredients));
    }
  }

  // ── Handlers ───────────────────────────────────────────────────────────────

  Future<void> _onLoadCategories(
    LoadCategoriesEvent event,
    Emitter<SearchState> emit,
  ) async {
    try {
      _categories = (await getAllCategories()).cast<CategoryEntity>();
      emit(SearchInitial(categories: _categories));
    } catch (_) {
      emit(const SearchInitial(categories: []));
    }
  }

  Future<void> _onLoadIngredientSuggestions(
    LoadIngredientSuggestions event,
    Emitter<SearchState> emit,
  ) async {
    try {
      _allIngredients = await getAllIngredients();
    } catch (_) {
      _allIngredients = [];
    }
  }

  Future<void> _onSearchQueryChanged(
    SearchQueryChanged event,
    Emitter<SearchState> emit,
  ) async {
    final q = event.query.trim();

    if (q.isEmpty) {
      // Keep chips visible but stop showing suggestions
      if (_selectedIngredients.isNotEmpty) {
        // Stay in whatever result state we are — just dismiss the dropdown
        emit(IngredientSuggestionsUpdated(
          suggestions: const [],
          categories: _categories,
          selectedIngredients: _selectedIngredients,
        ));
      } else {
        emit(SearchInitial(categories: _categories));
      }
      return;
    }

    // Filter ingredient list (exclude already-selected ones)
    if (_allIngredients.isNotEmpty) {
      final lower = q.toLowerCase();
      final hits = _allIngredients
          .where((ing) =>
              !_selectedIngredients.contains(ing) &&
              ing.toLowerCase().contains(lower))
          .take(6)
          .toList();

      if (hits.isNotEmpty) {
        emit(IngredientSuggestionsUpdated(
          suggestions: hits,
          categories: _categories,
          selectedIngredients: _selectedIngredients,
        ));
        return;
      }
    }

    // No ingredient match → fall through to meal-name search
    emit(SearchLoading(selectedIngredients: _selectedIngredients));
    try {
      final meals = await searchMealsByName(q);
      if (meals.isEmpty) {
        emit(SearchEmpty(
          query: event.query,
          selectedIngredients: _selectedIngredients,
        ));
      } else {
        emit(SearchSuccess(
          meals: meals,
          categories: _categories,
          query: event.query,
          selectedIngredients: _selectedIngredients,
        ));
      }
    } catch (e) {
      emit(SearchError(e.toString(),
          selectedIngredients: _selectedIngredients));
    }
  }

  Future<void> _onIngredientChipAdded(
    IngredientChipAdded event,
    Emitter<SearchState> emit,
  ) async {
    if (_selectedIngredients.contains(event.ingredient)) return;
    _selectedIngredients = [..._selectedIngredients, event.ingredient];
    await _searchBySelectedIngredients(emit);
  }

  Future<void> _onIngredientChipRemoved(
    IngredientChipRemoved event,
    Emitter<SearchState> emit,
  ) async {
    _selectedIngredients =
        _selectedIngredients.where((i) => i != event.ingredient).toList();
    if (_selectedIngredients.isEmpty) {
      emit(SearchInitial(categories: _categories));
    } else {
      await _searchBySelectedIngredients(emit);
    }
  }

  Future<void> _onCategoryFilter(
    CategoryFilterSelected event,
    Emitter<SearchState> emit,
  ) async {
    _selectedIngredients = [];
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
    _selectedIngredients = [];
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
    _selectedIngredients = [];
    emit(SearchInitial(categories: _categories));
  }

  void _onDismissSuggestions(
      DismissSuggestions event, Emitter<SearchState> emit) {
    if (_selectedIngredients.isNotEmpty) {
      // Re-emit current results without the dropdown
      emit(IngredientSuggestionsUpdated(
        suggestions: const [],
        categories: _categories,
        selectedIngredients: _selectedIngredients,
      ));
    } else {
      emit(SearchInitial(categories: _categories));
    }
  }
}
