import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_loading_skeleton.dart';
import '../../../../features/search/domain/entities/category_entity.dart';
import '../../../../features/search/presentation/blocs/search_bloc.dart';
import '../../../../features/search/presentation/widgets/meal_card.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  String? _activeCategory;

  @override
  void initState() {
    super.initState();
    context.read<SearchBloc>().add(const LoadIngredientSuggestions());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSuggestionTap(String ingredient) {
    // Clear the text field so the user can type the next ingredient
    _searchController.clear();
    context.read<SearchBloc>().add(IngredientChipAdded(ingredient));
    // Keep focus so the user can type another ingredient immediately
    _focusNode.requestFocus();
  }

  void _removeChip(String ingredient) {
    context.read<SearchBloc>().add(IngredientChipRemoved(ingredient));
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _activeCategory = null);
    context.read<SearchBloc>().add(const ClearFiltersEvent());
  }

  /// Extract selected ingredients from any state type.
  List<String> _ingredientsFrom(SearchState state) {
    if (state is SearchInitial) return state.selectedIngredients;
    if (state is SearchLoading) return state.selectedIngredients;
    if (state is SearchSuccess) return state.selectedIngredients;
    if (state is SearchEmpty) return state.selectedIngredients;
    if (state is SearchError) return state.selectedIngredients;
    if (state is IngredientSuggestionsUpdated) return state.selectedIngredients;
    return const [];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Discover Recipes',
                    style: TextStyle(
                      color: AppTheme.textP(context),
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── Search field + autocomplete overlay ──────────────
                  BlocBuilder<SearchBloc, SearchState>(
                    buildWhen: (prev, curr) =>
                        curr is IngredientSuggestionsUpdated ||
                        prev is IngredientSuggestionsUpdated,
                    builder: (context, state) {
                      final suggestions = state is IngredientSuggestionsUpdated
                          ? state.suggestions
                          : <String>[];

                      return Column(
                        children: [
                          TextField(
                            controller: _searchController,
                            focusNode: _focusNode,
                            onChanged: (q) {
                              setState(() {});
                              context
                                  .read<SearchBloc>()
                                  .add(SearchQueryChanged(q));
                            },
                            onSubmitted: (q) {
                              if (q.trim().isNotEmpty) {
                                context
                                    .read<SearchBloc>()
                                    .add(SearchQueryChanged(q.trim()));
                              }
                            },
                            style: TextStyle(color: AppTheme.textP(context)),
                            decoration: InputDecoration(
                              hintText: 'Add ingredient to filter…',
                              prefixIcon: Icon(Icons.search_rounded,
                                  color: AppTheme.textH(context)),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: Icon(Icons.clear_rounded,
                                          color: AppTheme.textH(context)),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() {});
                                        context
                                            .read<SearchBloc>()
                                            .add(const DismissSuggestions());
                                      },
                                    )
                                  : null,
                            ),
                          ),

                          // ── Autocomplete dropdown ──────────────────
                          if (suggestions.isNotEmpty)
                            _SuggestionDropdown(
                              suggestions: suggestions,
                              isDark: isDark,
                              onTap: _onSuggestionTap,
                            ),
                        ],
                      );
                    },
                  ),
                ],
              ).animate().fadeIn(duration: 350.ms),
            ),

            // ── Active ingredient chips strip ────────────────────────────
            BlocBuilder<SearchBloc, SearchState>(
              buildWhen: (p, c) =>
                  _ingredientsFrom(p) != _ingredientsFrom(c) ||
                  c is SearchInitial,
              builder: (context, state) {
                final chips = _ingredientsFrom(state);
                if (chips.isEmpty) return const SizedBox.shrink();

                return Padding(
                  padding:
                      const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Label row
                      Row(
                        children: [
                          Text(
                            'Filtering by ingredients:',
                            style: TextStyle(
                              color: AppTheme.textS(context),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: _clearSearch,
                            child: Text(
                              'Clear all',
                              style: TextStyle(
                                color: AppTheme.primary.withValues(alpha: 0.85),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Chips row
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: chips.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final ingredient = entry.value;
                            return _IngredientChip(
                              ingredient: ingredient,
                              onRemove: () => _removeChip(ingredient),
                            )
                                .animate(
                                    delay: Duration(milliseconds: idx * 60))
                                .fadeIn(duration: 200.ms)
                                .slideX(begin: -0.15, end: 0, duration: 200.ms);
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            // ── Category chips ───────────────────────────────────────────
            BlocBuilder<SearchBloc, SearchState>(
              buildWhen: (prev, curr) =>
                  curr is SearchInitial ||
                  curr is SearchSuccess ||
                  curr is IngredientSuggestionsUpdated,
              builder: (context, state) {
                final cats = state is SearchInitial
                    ? state.categories
                    : state is SearchSuccess
                        ? state.categories
                        : state is IngredientSuggestionsUpdated
                            ? state.categories
                            : <CategoryEntity>[];
                if (cats.isEmpty) return const SizedBox.shrink();
                return SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: cats.length,
                    itemBuilder: (ctx, i) {
                      final cat = cats[i];
                      final isActive = _activeCategory == cat.name;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isActive) {
                              _activeCategory = null;
                              context
                                  .read<SearchBloc>()
                                  .add(const ClearFiltersEvent());
                            } else {
                              _activeCategory = cat.name;
                              _searchController.clear();
                              context
                                  .read<SearchBloc>()
                                  .add(CategoryFilterSelected(cat.name));
                            }
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isActive
                                ? AppTheme.primary
                                : AppTheme.card(context),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isActive
                                  ? AppTheme.primary
                                  : AppTheme.border(context),
                            ),
                          ),
                          child: Text(
                            cat.name,
                            style: TextStyle(
                              color: isActive
                                  ? Colors.white
                                  : AppTheme.textS(context),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: 12),

            // ── Results ─────────────────────────────────────────────────
            Expanded(
              child: BlocBuilder<SearchBloc, SearchState>(
                builder: (context, state) {
                  if (state is SearchInitial && state.categories.isEmpty) {
                    return const GridSkeletonLoader();
                  }
                  if (state is SearchLoading) {
                    return const GridSkeletonLoader();
                  }
                  if (state is SearchError) {
                    return _ErrorView(message: state.message);
                  }
                  if (state is SearchEmpty) {
                    return _EmptyView(
                      query: state.query,
                      isMultiIngredient: state.selectedIngredients.length > 1,
                    );
                  }
                  if (state is SearchSuccess) {
                    return GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.75,
                      ),
                      itemCount: state.meals.length,
                      itemBuilder: (_, i) =>
                          MealCard(meal: state.meals[i], index: i),
                    );
                  }
                  // Initial / suggestions state — show prompt
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('🔍', style: TextStyle(fontSize: 56)),
                        const SizedBox(height: 16),
                        Text(
                          'Search for any meal or\nselect a category above',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppTheme.textS(context),
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Ingredient chip pill ─────────────────────────────────────────────────────

class _IngredientChip extends StatelessWidget {
  final String ingredient;
  final VoidCallback onRemove;

  const _IngredientChip({
    required this.ingredient,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.only(left: 8, right: 6, top: 5, bottom: 5),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Ingredient thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.network(
              ApiConstants.ingredientImageUrl(ingredient),
              width: 22,
              height: 22,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.eco_rounded,
                size: 18,
                color: AppTheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            ingredient,
            style: const TextStyle(
              color: AppTheme.primary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close_rounded,
                size: 12,
                color: AppTheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Autocomplete Suggestion Dropdown ────────────────────────────────────────

class _SuggestionDropdown extends StatelessWidget {
  final List<String> suggestions;
  final bool isDark;
  final ValueChanged<String> onTap;

  const _SuggestionDropdown({
    required this.suggestions,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        color: AppTheme.card(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: suggestions.asMap().entries.map((entry) {
            final idx = entry.key;
            final ingredient = entry.value;
            final isLast = idx == suggestions.length - 1;

            return InkWell(
              onTap: () => onTap(ingredient),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    child: Row(
                      children: [
                        // Ingredient CDN thumbnail
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            ApiConstants.ingredientImageUrl(ingredient),
                            width: 36,
                            height: 36,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.eco_rounded,
                                  size: 20, color: AppTheme.primary),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            ingredient,
                            style: TextStyle(
                              color: AppTheme.textP(context),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        // "Add" icon hint
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            '+ Add',
                            style: TextStyle(
                              color: AppTheme.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isLast)
                    Divider(
                      height: 1,
                      thickness: 0.5,
                      color: AppTheme.border(context),
                      indent: 62,
                    ),
                ],
              ),
            )
                .animate(delay: Duration(milliseconds: idx * 40))
                .fadeIn(duration: 180.ms)
                .slideY(begin: -0.08, end: 0, duration: 180.ms);
          }).toList(),
        ),
      ),
    );
  }
}

// ─── Error / Empty views ──────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded,
                size: 48, color: AppTheme.textHint),
            const SizedBox(height: 12),
            Text(message,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textS(context))),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () =>
                  context.read<SearchBloc>().add(const LoadCategoriesEvent()),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final String query;
  final bool isMultiIngredient;
  const _EmptyView({required this.query, this.isMultiIngredient = false});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🍽️', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          Text(
            isMultiIngredient
                ? 'No meals contain all\nselected ingredients'
                : 'No results for "$query"',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.textP(context),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isMultiIngredient
                ? 'Try removing one or more ingredients'
                : 'Try a different ingredient or category',
            style: TextStyle(color: AppTheme.textS(context)),
          ),
        ],
      ),
    );
  }
}
