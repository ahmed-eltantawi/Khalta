import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../../features/health_profile/domain/entities/health_profile_entity.dart';
import 'health_profile_cubit.dart';

class HealthProfilePage extends StatelessWidget {
  const HealthProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      body: SafeArea(
        child: BlocBuilder<HealthProfileCubit, HealthProfileEntity>(
          builder: (context, profile) {
            return CustomScrollView(
              slivers: [
                // ── Header ─────────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Health Profile 🥗',
                            style: TextStyle(
                                color: AppTheme.textP(context),
                                fontSize: 24,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text('Personalize your recipe recommendations',
                            style: TextStyle(
                                color: AppTheme.textS(context), fontSize: 14)),
                      ],
                    ).animate().fadeIn(duration: 350.ms),
                  ),
                ),
                // ── Dietary Preferences ───────────────────────────────────
                SliverToBoxAdapter(
                  child: _Section(
                    title: 'Dietary Preferences',
                    icon: Icons.eco_rounded,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: HealthProfileEntity.availableDiets.map((diet) {
                        final isActive = profile.dietaryPreferences.contains(diet);
                        return _SelectableChip(
                          label: diet,
                          isSelected: isActive,
                          onTap: () => context.read<HealthProfileCubit>().toggleDiet(diet),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                // ── Health Conditions ─────────────────────────────────────
                SliverToBoxAdapter(
                  child: _Section(
                    title: 'Health Goals',
                    icon: Icons.monitor_heart_rounded,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: HealthProfileEntity.availableConditions.map((c) {
                        final isActive = profile.healthConditions.contains(c);
                        return _SelectableChip(
                          label: c,
                          isSelected: isActive,
                          color: AppTheme.secondary,
                          onTap: () =>
                              context.read<HealthProfileCubit>().toggleCondition(c),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                // ── Daily Calorie Target ───────────────────────────────────
                SliverToBoxAdapter(
                  child: _Section(
                    title: 'Daily Calorie Target',
                    icon: Icons.local_fire_department_rounded,
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Target',
                                style: TextStyle(color: AppTheme.textS(context), fontSize: 14)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${profile.dailyCalorieTarget} kcal',
                                style: const TextStyle(
                                    color: AppTheme.primary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: AppTheme.primary,
                            inactiveTrackColor: AppTheme.border(context),
                            thumbColor: AppTheme.primary,
                            overlayColor: AppTheme.primary.withValues(alpha: 0.2),
                          ),
                          child: Slider(
                            value: profile.dailyCalorieTarget.toDouble(),
                            min: 1000,
                            max: 4000,
                            divisions: 60,
                            onChanged: (v) => context
                                .read<HealthProfileCubit>()
                                .setCalorieTarget(v.round()),
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('1000', style: TextStyle(color: AppTheme.textH(context), fontSize: 11)),
                            Text('4000', style: TextStyle(color: AppTheme.textH(context), fontSize: 11)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                // ── Active restrictions summary ────────────────────────────
                if (profile.dietaryPreferences.isNotEmpty)
                  SliverToBoxAdapter(
                    child: _Section(
                      title: 'Active Restrictions',
                      icon: Icons.block_rounded,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: profile.dietaryPreferences.map((diet) {
                          final excluded =
                              HealthProfileEntity.dietExclusions[diet] ?? [];
                          if (excluded.isEmpty) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.remove_circle_rounded,
                                    size: 14, color: AppTheme.error),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    '$diet — excludes: ${excluded.take(4).join(', ')}…',
                                    style: TextStyle(
                                        color: AppTheme.textS(context), fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                // ── Theme Toggle ─────────────────────────────────────────
                SliverToBoxAdapter(
                  child: _Section(
                    title: 'Appearance',
                    icon: Icons.palette_rounded,
                    child: BlocBuilder<ThemeCubit, ThemeMode>(
                      builder: (context, themeMode) {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Dark Mode',
                              style: TextStyle(color: AppTheme.textP(context), fontSize: 14)),
                            Switch.adaptive(
                              value: themeMode == ThemeMode.dark,
                              activeTrackColor: AppTheme.primary,
                              onChanged: (_) => context.read<ThemeCubit>().toggleTheme(),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 40)),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _Section({required this.title, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.card(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border(context), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.primary, size: 18),
              const SizedBox(width: 8),
              Text(title,
                  style: TextStyle(
                      color: AppTheme.textP(context),
                      fontSize: 15,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05);
  }
}

class _SelectableChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color color;

  const _SelectableChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.color = AppTheme.primary,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : AppTheme.surface(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : AppTheme.border(context),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              const Icon(Icons.check_rounded, size: 14, color: Colors.white),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppTheme.textS(context),
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
