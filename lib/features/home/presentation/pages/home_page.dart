import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_loading_skeleton.dart';
import '../../../../features/search/domain/entities/category_entity.dart';
import '../../../../features/search/domain/entities/meal_entity.dart';
import '../../../../features/search/presentation/widgets/meal_card.dart';
import '../../../../features/search/presentation/blocs/search_bloc.dart';
import '../../../../features/virtual_fridge/presentation/blocs/fridge_bloc.dart';
import '../cubits/home_cubit.dart';
import '../cubits/camera_cubit.dart';
import '../cubits/voice_cubit.dart';
import '../widgets/camera_scan_sheet.dart';
import '../widgets/voice_scan_sheet.dart';
import '../../../../core/di/injection.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      body: SafeArea(
        child: BlocBuilder<HomeCubit, HomeCubitState>(
          builder: (context, state) {
            return RefreshIndicator(
              color: AppTheme.primary,
              backgroundColor: AppTheme.card(context),
              onRefresh: () => context.read<HomeCubit>().refresh(),
              child: CustomScrollView(
                slivers: [
                  // ── App Bar ──────────────────────────────────────────────
                  SliverToBoxAdapter(
                    child: _buildHeader(context),
                  ),
                  // ── Hero scan section ────────────────────────────────────
                  SliverToBoxAdapter(
                    child: _buildHeroSection(context),
                  ),
                  // ── Categories ───────────────────────────────────────────
                  SliverToBoxAdapter(
                    child: _buildSectionTitle(context, "Browse Categories",
                        onSeeAll: () => context.go('/search')),
                  ),
                  SliverToBoxAdapter(
                    child: state is HomeLoaded
                        ? _buildCategories(
                            context, state.categories.cast<CategoryEntity>())
                        : const HorizontalSkeletonLoader(count: 5),
                  ),
                  // ── Today's suggestions ──────────────────────────────────
                  SliverToBoxAdapter(
                    child: _buildSectionTitle(context, "Today's Suggestions"),
                  ),
                  if (state is HomeLoading)
                    SliverToBoxAdapter(
                        child: SizedBox(
                      height: 220,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: 4,
                        itemBuilder: (_, __) => const Padding(
                          padding: EdgeInsets.only(right: 12),
                          child:
                              SizedBox(width: 160, child: MealCardSkeleton()),
                        ),
                      ),
                    )),
                  if (state is HomeLoaded)
                    SliverToBoxAdapter(
                      child: _buildSuggestions(state.randomMeals),
                    ),
                  if (state is HomeError)
                    SliverToBoxAdapter(
                      child: _buildError(context, state.message),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hello, Chef! 👋',
                style: TextStyle(color: AppTheme.textS(context), fontSize: 14),
              ),
              const SizedBox(height: 2),
              Text(
                'What to cook today?',
                style: TextStyle(
                  color: AppTheme.textP(context),
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: () => context.go('/health-profile'),
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                gradient: AppTheme.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_rounded,
                  color: Colors.white, size: 22),
            ),
          ),
        ],
      ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1),
    );
  }

  Widget _buildHeroSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "What's in\nyour kitchen?",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _openCamera(context),
                          icon: const Icon(Icons.camera_alt_rounded, size: 18),
                          label: const Text('Scan'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppTheme.primary,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _openVoice(context),
                          icon: const Icon(Icons.mic_rounded, size: 18),
                          label: const Text('Voice'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.2),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 500.ms, delay: 100.ms).slideY(begin: 0.1),
    );
  }

  void _openCamera(BuildContext context) async {
    // Create a FridgeBloc for the camera sheet so ingredients can be added
    final fridgeBloc = sl<FridgeBloc>()..add(const LoadFridgeEvent());

    final acceptedIngredients = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => sl<CameraCubit>()),
          BlocProvider.value(value: fridgeBloc),
        ],
        child: const CameraScanSheet(),
      ),
    );

    if (acceptedIngredients != null &&
        acceptedIngredients.isNotEmpty &&
        context.mounted) {
      // Navigate to fridge page to show newly added items
      context.go('/fridge');
    }
  }

  void _openVoice(BuildContext context) async {
    final ingredients = await showModalBottomSheet<List<String>>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider(
        create: (_) => sl<VoiceCubit>(),
        child: const VoiceScanSheet(),
      ),
    );
    if (ingredients != null && ingredients.isNotEmpty && context.mounted) {
      _searchIngredients(context, ingredients);
    }
  }

  void _searchIngredients(BuildContext context, List<String> ingredients) {
    final searchBloc = context.read<SearchBloc>();
    // Add each detected ingredient as a chip so multi-ingredient filtering works
    for (final ingredient in ingredients) {
      searchBloc.add(IngredientChipAdded(ingredient));
    }
    context.go('/search');
  }

  Widget _buildSectionTitle(BuildContext context, String title,
      {VoidCallback? onSeeAll}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: TextStyle(
                color: AppTheme.textP(context),
                fontSize: 17,
                fontWeight: FontWeight.w600,
              )),
          if (onSeeAll != null)
            TextButton(
              onPressed: onSeeAll,
              child: const Text('See all'),
            ),
        ],
      ),
    );
  }

  Widget _buildCategories(
      BuildContext context, List<CategoryEntity> categories) {
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, i) {
          final cat = categories[i];
          return GestureDetector(
            onTap: () {
              context.go('/search');
            },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.card(context),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.border(context)),
              ),
              child: Text(
                cat.name,
                style: TextStyle(
                  color: AppTheme.textS(context),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
                .animate(delay: Duration(milliseconds: i * 40))
                .fadeIn(duration: 300.ms)
                .slideX(begin: 0.1, end: 0),
          );
        },
      ),
    );
  }

  Widget _buildSuggestions(List<MealEntity> meals) {
    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: meals.length,
        itemBuilder: (context, i) =>
            MealCardHorizontal(meal: meals[i], index: i),
      ),
    );
  }

  Widget _buildError(BuildContext context, String message) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(Icons.wifi_off_rounded,
              color: AppTheme.textH(context), size: 48),
          const SizedBox(height: 12),
          Text(message,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textS(context))),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.read<HomeCubit>().refresh(),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
