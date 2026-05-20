import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../features/search/domain/entities/meal_entity.dart';
import '../../../../features/search/domain/usecases/meal_usecases.dart';
import '../../../../features/saved_recipes/presentation/pages/saved_recipes_cubit.dart';
import '../../../../features/virtual_fridge/data/datasources/fridge_local_datasource.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RecipeDetailPage extends StatefulWidget {
  final String mealId;
  final MealEntity? initialMeal;

  const RecipeDetailPage({super.key, required this.mealId, this.initialMeal});

  @override
  State<RecipeDetailPage> createState() => _RecipeDetailPageState();
}

class _RecipeDetailPageState extends State<RecipeDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  MealEntity? _meal;
  bool _loading = true;
  List<String> _fridgeIngredientNames = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadFridgeItems();
    if (widget.initialMeal?.instructions != null) {
      _meal = widget.initialMeal;
      _loading = false;
    } else {
      _loadMeal();
    }
  }

  Future<void> _loadFridgeItems() async {
    try {
      final items = sl<FridgeLocalDataSource>().getAll();
      setState(() {
        _fridgeIngredientNames = items.map((e) => e.name.toLowerCase()).toList();
      });
    } catch (_) {}
  }

  Future<void> _loadMeal() async {
    try {
      final meal = await sl<GetMealById>()(widget.mealId);
      setState(() {
        _meal = meal ?? widget.initialMeal;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _meal = widget.initialMeal;
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final meal = _meal;
    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary))
          : meal == null
              ? _buildError()
              : _buildContent(meal),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: AppTheme.error, size: 48),
          const SizedBox(height: 12),
          Text('Could not load recipe', style: TextStyle(color: AppTheme.textS(context))),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Go Back')),
        ],
      ),
    );
  }

  Widget _buildContent(MealEntity meal) {
    return CustomScrollView(
      slivers: [
        // ── Hero image ────────────────────────────────────────────────────
        SliverAppBar(
          expandedHeight: 280,
          pinned: true,
          backgroundColor: AppTheme.bg(context),
          leading: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            BlocBuilder<SavedRecipesCubit, List<MealEntity>>(
              builder: (context, saved) {
                final isSaved = context.read<SavedRecipesCubit>().isSaved(meal.id);
                return IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isSaved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      color: isSaved ? AppTheme.error : Colors.white,
                    ),
                  ),
                  onPressed: () => context.read<SavedRecipesCubit>().toggleSave(meal),
                );
              },
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                if (meal.thumbnailUrl != null)
                  CachedNetworkImage(
                    imageUrl: meal.thumbnailUrl!,
                    fit: BoxFit.cover,
                  ),
                const DecoratedBox(
                  decoration: BoxDecoration(gradient: AppTheme.heroGradient),
                ),
              ],
            ),
          ),
        ),
        // ── Title & meta ──────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meal.name,
                  style: TextStyle(
                    color: AppTheme.textP(context),
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.1),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    if (meal.category != null) _buildTag(meal.category!, Icons.category_rounded, AppTheme.primary),
                    if (meal.area != null) _buildTag(meal.area!, Icons.location_on_rounded, AppTheme.secondary),
                    if (meal.ingredients.isNotEmpty)
                      _buildTag('${meal.ingredients.length} ingredients', Icons.kitchen_rounded, AppTheme.warning),
                  ],
                ).animate().fadeIn(duration: 400.ms, delay: 100.ms),
                if (meal.youtubeUrl != null && meal.youtubeUrl!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final uri = Uri.tryParse(meal.youtubeUrl!);
                      if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
                    },
                    icon: const Icon(Icons.play_circle_rounded, color: Color(0xFFFF0000)),
                    label: const Text('Watch Tutorial'),
                  ),
                ],
                const SizedBox(height: 20),
                // Tab bar
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.card(context),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicatorPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    indicator: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    labelColor: Colors.white,
                    labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                    unselectedLabelColor: AppTheme.textS(context),
                    dividerColor: Colors.transparent,
                    tabs: const [
                      Tab(text: 'Ingredients'),
                      Tab(text: 'Instructions'),
                      Tab(text: 'Nutrition'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        // ── Tab content ───────────────────────────────────────────────────
        SliverFillRemaining(
          child: TabBarView(
            controller: _tabController,
            children: [
              _IngredientsTab(meal: meal, fridgeIngredients: _fridgeIngredientNames),
              _InstructionsTab(meal: meal),
              _NutritionTab(meal: meal),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTag(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ─── Ingredients Tab ─────────────────────────────────────────────────────────

class _IngredientsTab extends StatelessWidget {
  final MealEntity meal;
  final List<String> fridgeIngredients;
  const _IngredientsTab({required this.meal, required this.fridgeIngredients});

  @override
  Widget build(BuildContext context) {
    final pairs = meal.ingredientMeasurements;
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: pairs.length,
      itemBuilder: (_, i) {
        final ing = pairs[i];
        final ingNameLower = ing.key.toLowerCase();
        
        // Simple matching logic
        final isMissing = !fridgeIngredients.any((f) => 
            ingNameLower.contains(f) || f.contains(ingNameLower));

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.card(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border(context), width: 0.5),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isMissing 
                      ? AppTheme.textHint.withValues(alpha: 0.1) 
                      : AppTheme.success.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isMissing ? Icons.cancel_outlined : Icons.check_circle_outline_rounded,
                  color: isMissing ? AppTheme.textHint : AppTheme.success, 
                  size: 18
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ing.key,
                      style: TextStyle(
                        color: AppTheme.textP(context),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        decoration: isMissing ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    if (isMissing)
                      Text(
                        'Missing',
                        style: TextStyle(color: AppTheme.error, fontSize: 10),
                      ),
                  ],
                ),
              ),
              Text(
                ing.value,
                style: TextStyle(color: AppTheme.textS(context), fontSize: 13),
              ),
            ],
          ),
        )
            .animate(delay: Duration(milliseconds: i * 40))
            .fadeIn(duration: 300.ms)
            .slideX(begin: -0.05);
      },
    );
  }
}

// ─── Instructions Tab ─────────────────────────────────────────────────────────

class _InstructionsTab extends StatelessWidget {
  final MealEntity meal;
  const _InstructionsTab({required this.meal});

  @override
  Widget build(BuildContext context) {
    if (meal.instructions == null || meal.instructions!.trim().isEmpty) {
      return Center(
        child: Text('No instructions available', style: TextStyle(color: AppTheme.textS(context))),
      );
    }
    final steps = meal.instructions!
        .split('\n')
        .where((s) => s.trim().isNotEmpty)
        .toList();

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: steps.length,
      itemBuilder: (_, i) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 28,
              height: 28,
              margin: const EdgeInsets.only(right: 12, top: 2),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${i + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  steps[i].trim(),
                  style: TextStyle(
                    color: AppTheme.textS(context),
                    fontSize: 14,
                    height: 1.6,
                  ),
                ),
              ),
            ),
          ],
        )
            .animate(delay: Duration(milliseconds: i * 50))
            .fadeIn(duration: 300.ms);
      },
    );
  }
}

// ─── Nutrition Tab ────────────────────────────────────────────────────────────

class _NutritionTab extends StatelessWidget {
  final MealEntity meal;
  const _NutritionTab({required this.meal});

  int get _estCalories => (meal.ingredients.length * 45).clamp(150, 900);
  int get _estProtein => (meal.ingredients.length * 4).clamp(5, 60);
  int get _estCarbs => (meal.ingredients.length * 12).clamp(10, 120);
  int get _estFat => (meal.ingredients.length * 3).clamp(3, 40);

  @override
  Widget build(BuildContext context) {
    final items = [
      _NutritionItem('Calories', '$_estCalories kcal', Icons.local_fire_department_rounded, AppTheme.primary, _estCalories / 900),
      _NutritionItem('Protein', '${_estProtein}g', Icons.fitness_center_rounded, AppTheme.secondary, _estProtein / 60),
      _NutritionItem('Carbs', '${_estCarbs}g', Icons.grain_rounded, AppTheme.warning, _estCarbs / 120),
      _NutritionItem('Fat', '${_estFat}g', Icons.opacity_rounded, const Color(0xFF9B59B6), _estFat / 40),
    ];

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.warning.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, color: AppTheme.warning, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Estimated values based on ingredients count.',
                    style: TextStyle(color: AppTheme.textS(context), fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ...items.asMap().entries.map((e) => _buildNutritionRow(context, e.value, e.key)),
        ],
      ),
    );
  }

  Widget _buildNutritionRow(BuildContext context, _NutritionItem item, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.card(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border(context), width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(item.icon, color: item.color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(item.label,
                        style: TextStyle(color: AppTheme.textP(context), fontSize: 14, fontWeight: FontWeight.w500)),
                    Text(item.value,
                        style: TextStyle(color: item.color, fontSize: 14, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: item.percent.clamp(0.0, 1.0),
                    backgroundColor: AppTheme.border(context),
                    valueColor: AlwaysStoppedAnimation<Color>(item.color),
                    minHeight: 5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate(delay: Duration(milliseconds: index * 80))
        .fadeIn(duration: 350.ms)
        .slideY(begin: 0.1);
  }
}

class _NutritionItem {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final double percent;
  const _NutritionItem(this.label, this.value, this.icon, this.color, this.percent);
}
