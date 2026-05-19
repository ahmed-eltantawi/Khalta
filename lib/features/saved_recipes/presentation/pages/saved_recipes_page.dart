import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../features/search/domain/entities/meal_entity.dart';
import 'saved_recipes_cubit.dart';

class SavedRecipesPage extends StatelessWidget {
  const SavedRecipesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: SafeArea(
        child: BlocBuilder<SavedRecipesCubit, List<MealEntity>>(
          builder: (context, meals) {
            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Saved Recipes ❤️',
                            style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 24,
                                fontWeight: FontWeight.w700)),
                        Text('${meals.length} saved',
                            style: const TextStyle(
                                color: AppTheme.textSecondary, fontSize: 14)),
                      ],
                    ).animate().fadeIn(duration: 350.ms),
                  ),
                ),
                if (meals.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(48),
                      child: Column(
                        children: const [
                          Text('❤️', style: TextStyle(fontSize: 64)),
                          SizedBox(height: 16),
                          Text('No saved recipes yet',
                              style: TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600)),
                          SizedBox(height: 8),
                          Text(
                            'Tap the heart icon on any recipe\nto save it here.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppTheme.textSecondary, height: 1.5),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (meals.isNotEmpty)
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => _SavedMealRow(meal: meals[i], index: i),
                      childCount: meals.length,
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SavedMealRow extends StatelessWidget {
  final MealEntity meal;
  final int index;

  const _SavedMealRow({required this.meal, required this.index});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(meal.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppTheme.error.withValues(alpha: 0.8),
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      onDismissed: (_) =>
          context.read<SavedRecipesCubit>().toggleSave(meal),
      child: GestureDetector(
        onTap: () => context.push('/recipe/${meal.id}', extra: meal),
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          decoration: BoxDecoration(
            color: AppTheme.cardDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderDark, width: 0.5),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(15)),
                child: meal.thumbnailUrl != null
                    ? Image.network(
                        meal.thumbnailUrl!,
                        width: 90,
                        height: 90,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                            width: 90,
                            height: 90,
                            color: AppTheme.surfaceDark,
                            child: const Icon(Icons.restaurant,
                                color: AppTheme.textHint)),
                      )
                    : Container(
                        width: 90,
                        height: 90,
                        color: AppTheme.surfaceDark,
                        child: const Icon(Icons.restaurant, color: AppTheme.textHint),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        meal.name,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      if (meal.category != null)
                        Text(meal.category!,
                            style: const TextStyle(
                                color: AppTheme.primary, fontSize: 12)),
                      if (meal.area != null)
                        Text(meal.area!,
                            style: const TextStyle(
                                color: AppTheme.textHint, fontSize: 11)),
                    ],
                  ),
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: AppTheme.textHint, size: 20),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: index * 50))
        .fadeIn(duration: 300.ms)
        .slideX(begin: -0.05);
  }
}
