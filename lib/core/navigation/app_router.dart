import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/di/injection.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/home/presentation/cubits/home_cubit.dart';
import '../../features/search/presentation/pages/search_page.dart';
import '../../features/search/presentation/blocs/search_bloc.dart';
import '../../features/recipe_detail/presentation/pages/recipe_detail_page.dart';
import '../../features/virtual_fridge/presentation/pages/fridge_page.dart';
import '../../features/virtual_fridge/presentation/blocs/fridge_bloc.dart';
import '../../features/health_profile/presentation/pages/health_profile_page.dart';
import '../../features/health_profile/presentation/pages/health_profile_cubit.dart';
import '../../features/saved_recipes/presentation/pages/saved_recipes_page.dart';
import '../../features/saved_recipes/presentation/pages/saved_recipes_cubit.dart';
import '../../features/search/domain/entities/meal_entity.dart';

class AppRouter {
  static const String onboarding = '/onboarding';
  static const String home = '/';
  static const String search = '/search';
  static const String recipeDetail = '/recipe/:id';
  static const String fridge = '/fridge';
  static const String healthProfile = '/health-profile';
  static const String savedRecipes = '/saved';

  static final router = GoRouter(
    initialLocation: home,
    routes: [
      GoRoute(
        path: onboarding,
        builder: (_, __) => const OnboardingPage(),
      ),
      ShellRoute(
        builder: (context, state, child) => _ScaffoldWithNav(child: child),
        routes: [
          GoRoute(
            path: home,
            builder: (context, state) => BlocProvider(
              create: (_) => sl<HomeCubit>()..loadHome(),
              child: const HomePage(),
            ),
          ),
          GoRoute(
            path: search,
            builder: (context, state) => BlocProvider(
              create: (_) => sl<SearchBloc>()..add(const LoadCategoriesEvent()),
              child: const SearchPage(),
            ),
          ),
          GoRoute(
            path: fridge,
            builder: (context, state) => BlocProvider(
              create: (_) => sl<FridgeBloc>()..add(const LoadFridgeEvent()),
              child: const FridgePage(),
            ),
          ),
          GoRoute(
            path: savedRecipes,
            builder: (context, state) => BlocProvider(
              create: (_) => sl<SavedRecipesCubit>()..loadSaved(),
              child: const SavedRecipesPage(),
            ),
          ),
          GoRoute(
            path: healthProfile,
            builder: (context, state) => BlocProvider(
              create: (_) => sl<HealthProfileCubit>()..loadProfile(),
              child: const HealthProfilePage(),
            ),
          ),
        ],
      ),
      GoRoute(
        path: recipeDetail,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          final meal = state.extra as MealEntity?;
          return RecipeDetailPage(mealId: id, initialMeal: meal);
        },
      ),
    ],
  );
}

class _ScaffoldWithNav extends StatelessWidget {
  final Widget child;
  const _ScaffoldWithNav({required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    return Scaffold(
      body: child,
      bottomNavigationBar: _BottomNav(location: location),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final String location;
  const _BottomNav({required this.location});

  @override
  Widget build(BuildContext context) {
    final items = [
      const _NavItem(icon: Icons.home_rounded, label: 'Home', path: '/'),
      const _NavItem(icon: Icons.search_rounded, label: 'Search', path: '/search'),
      const _NavItem(icon: Icons.kitchen_rounded, label: 'Fridge', path: '/fridge'),
      const _NavItem(icon: Icons.favorite_rounded, label: 'Saved', path: '/saved'),
      const _NavItem(icon: Icons.person_rounded, label: 'Profile', path: '/health-profile'),
    ];

    int currentIndex = 0;
    for (int i = 0; i < items.length; i++) {
      if (location.startsWith(items[i].path) &&
          (items[i].path == '/' ? location == '/' : true)) {
        if (items[i].path == '/') {
          if (location == '/') currentIndex = i;
        } else {
          currentIndex = i;
        }
      }
    }

    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFF3A3A3C), width: 0.5)),
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) => context.go(items[index].path),
        items: items
            .map((item) => BottomNavigationBarItem(
                  icon: Icon(item.icon),
                  label: item.label,
                ))
            .toList(),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final String path;
  const _NavItem({required this.icon, required this.label, required this.path});
}
