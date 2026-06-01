import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_theme.dart';

class MealCardSkeleton extends StatelessWidget {
  const MealCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppTheme.cardDark,
      highlightColor: AppTheme.borderDark,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 140,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                      height: 14,
                      width: double.infinity,
                      color: Colors.white,
                      margin: const EdgeInsets.only(bottom: 8)),
                  Container(height: 11, width: 80, color: Colors.white),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CategoryChipSkeleton extends StatelessWidget {
  const CategoryChipSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppTheme.cardDark,
      highlightColor: AppTheme.borderDark,
      child: Container(
        width: 80,
        height: 36,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}

class GridSkeletonLoader extends StatelessWidget {
  final int count;
  const GridSkeletonLoader({super.key, this.count = 6});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.78,
      ),
      itemCount: count,
      itemBuilder: (_, __) => const MealCardSkeleton(),
    );
  }
}

class HorizontalSkeletonLoader extends StatelessWidget {
  final int count;
  const HorizontalSkeletonLoader({super.key, this.count = 4});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: count,
        itemBuilder: (_, __) => const CategoryChipSkeleton(),
      ),
    );
  }
}
