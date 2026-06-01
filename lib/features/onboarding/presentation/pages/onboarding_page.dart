import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/theme/app_theme.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _controller = PageController();
  int _currentPage = 0;

  static const _pages = [
    _OnboardSlide(
      emoji: '📸',
      title: 'Scan Your Ingredients',
      subtitle:
          'Point your camera at any ingredient and let AI identify it instantly.',
      gradient: [Color(0xFFFF6B35), Color(0xFFFF8C42)],
    ),
    _OnboardSlide(
      emoji: '🍽️',
      title: 'Discover Recipes',
      subtitle:
          'Get personalized meal suggestions powered by TheMealDB — explore thousands of dishes.',
      gradient: [Color(0xFF2EC4B6), Color(0xFF26A69A)],
    ),
    _OnboardSlide(
      emoji: '🧊',
      title: 'Manage Your Fridge',
      subtitle:
          'Track what\'s in your fridge and get recipes tailored to your available ingredients.',
      gradient: [Color(0xFF9B59B6), Color(0xFF8E44AD)],
    ),
  ];

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  void _finish() {
    final box = Hive.box('app_prefs');
    box.put('onboarding_done', true);
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      body: Stack(
        children: [
          // Page view
          PageView.builder(
            controller: _controller,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemCount: _pages.length,
            itemBuilder: (context, index) => _OnboardSlideWidget(
                slide: _pages[index], isActive: index == _currentPage),
          ),
          // Skip button
          Positioned(
            top: 60,
            right: 24,
            child: TextButton(
              onPressed: _finish,
              child: Text('Skip',
                  style: TextStyle(color: AppTheme.textS(context))),
            ),
          ),
          // Bottom controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
              child: Column(
                children: [
                  // Page indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == i ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == i
                              ? AppTheme.primary
                              : AppTheme.border(context),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // CTA Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _nextPage,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        _currentPage == _pages.length - 1
                            ? "Let's Cook! 🍳"
                            : 'Next',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardSlide {
  final String emoji;
  final String title;
  final String subtitle;
  final List<Color> gradient;
  const _OnboardSlide({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.gradient,
  });
}

class _OnboardSlideWidget extends StatelessWidget {
  final _OnboardSlide slide;
  final bool isActive;
  const _OnboardSlideWidget({required this.slide, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 80),
        // Animated emoji circle
        Container(
          width: 180,
          height: 180,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: slide.gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: slide.gradient.first.withValues(alpha: 0.4),
                blurRadius: 40,
                spreadRadius: 10,
              ),
            ],
          ),
          child: Center(
            child: Text(slide.emoji, style: const TextStyle(fontSize: 72)),
          ),
        ).animate(target: isActive ? 1 : 0).scale(
            begin: const Offset(0.8, 0.8),
            end: const Offset(1, 1),
            duration: 500.ms,
            curve: Curves.elasticOut),
        const SizedBox(height: 48),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              Text(
                slide.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.textP(context),
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                ),
              )
                  .animate(target: isActive ? 1 : 0)
                  .fadeIn(duration: 400.ms, delay: 200.ms)
                  .slideY(begin: 0.2, end: 0, duration: 400.ms, delay: 200.ms),
              const SizedBox(height: 16),
              Text(
                slide.subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.textS(context),
                  fontSize: 15,
                  height: 1.6,
                ),
              )
                  .animate(target: isActive ? 1 : 0)
                  .fadeIn(duration: 400.ms, delay: 300.ms),
            ],
          ),
        ),
      ],
    );
  }
}
