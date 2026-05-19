import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
  String? _activeCategory;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Discover Recipes',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Search field
                  TextField(
                    controller: _searchController,
                    onChanged: (q) => context
                        .read<SearchBloc>()
                        .add(SearchQueryChanged(q)),
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Search meals, ingredients…',
                      prefixIcon: const Icon(Icons.search_rounded,
                          color: AppTheme.textHint),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded,
                                  color: AppTheme.textHint),
                              onPressed: () {
                                _searchController.clear();
                                context
                                    .read<SearchBloc>()
                                    .add(const ClearFiltersEvent());
                              },
                            )
                          : null,
                    ),
                  ),
                ],
              ).animate().fadeIn(duration: 350.ms),
            ),
            // ── Category chips ─────────────────────────────────────────────
            BlocBuilder<SearchBloc, SearchState>(
              buildWhen: (prev, curr) =>
                  curr is SearchInitial || curr is SearchSuccess,
              builder: (context, state) {
                final cats = state is SearchInitial
                    ? state.categories
                    : state is SearchSuccess
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
                              context.read<SearchBloc>().add(const ClearFiltersEvent());
                            } else {
                              _activeCategory = cat.name;
                              context.read<SearchBloc>().add(CategoryFilterSelected(cat.name));
                            }
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isActive ? AppTheme.primary : AppTheme.cardDark,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isActive ? AppTheme.primary : AppTheme.borderDark,
                            ),
                          ),
                          child: Text(
                            cat.name,
                            style: TextStyle(
                              color: isActive ? Colors.white : AppTheme.textSecondary,
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
            // ── Results ───────────────────────────────────────────────────
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
                    return _EmptyView(query: state.query);
                  }
                  if (state is SearchSuccess) {
                    return GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
                  // Initial state — show prompt
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('🔍', style: TextStyle(fontSize: 56)),
                        const SizedBox(height: 16),
                        const Text(
                          'Search for any meal or\nselect a category above',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppTheme.textSecondary,
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
            const Icon(Icons.wifi_off_rounded, size: 48, color: AppTheme.textHint),
            const SizedBox(height: 12),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.textSecondary)),
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
  const _EmptyView({required this.query});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🍽️', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          Text(
            'No results for "$query"',
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Try a different ingredient or category',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}
