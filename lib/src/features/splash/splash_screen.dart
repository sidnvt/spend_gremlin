import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_colors.dart';
import '../../core/app_typography.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  Timer? _timer;
  late final AnimationController _scaleController;
  late final AnimationController _glowController;
  late final AnimationController _textController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _textFadeAnimation;
  late final Animation<double> _textSlideAnimation;

  @override
  void initState() {
    super.initState();

    // Circle scale-in with elastic bounce
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );

    // Glow pulse on the border
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Text fade-in + slide-up
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _textFadeAnimation = CurvedAnimation(
      parent: _textController,
      curve: Curves.easeOut,
    );
    _textSlideAnimation = Tween<double>(begin: 20.0, end: 0.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOut),
    );

    // Start animations in sequence
    _scaleController.forward();

    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      _textController.forward();
    });

    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      _glowController.repeat(reverse: true);
    });

    _timer = Timer(const Duration(milliseconds: 2000), () {
      if (!mounted) return;
      context.go('/dashboard');
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scaleController.dispose();
    _glowController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Responsive circle size — ~35% of screen width, clamped
    final circleSize = (screenWidth * 0.35).clamp(120.0, 200.0);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated circle with image
              ScaleTransition(
                scale: _scaleAnimation,
                child: AnimatedBuilder(
                  animation: _glowController,
                  builder: (context, child) {
                    final glowOpacity =
                        0.3 + (_glowController.value * 0.7);
                    final glowSpread =
                        2.0 + (_glowController.value * 8.0);
                    return Container(
                      width: circleSize,
                      height: circleSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.green,
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.green
                                .withValues(alpha: glowOpacity * 0.4),
                            blurRadius: glowSpread * 2,
                            spreadRadius: glowSpread * 0.5,
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: child,
                    );
                  },
                  child: Image.asset(
                    'assets/images/raccoon.jpg',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              SizedBox(height: circleSize * 0.12),
              // Animated text
              AnimatedBuilder(
                animation: _textController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _textFadeAnimation.value,
                    child: Transform.translate(
                      offset: Offset(0, _textSlideAnimation.value),
                      child: child,
                    ),
                  );
                },
                child: Text(
                  'Spend Gremlin',
                  style: AppTypography.serifAmount(
                    size: (circleSize * 0.18).clamp(20.0, 30.0),
                    color: AppColors.green,
                    weight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // v2 tag
              AnimatedBuilder(
                animation: _textController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _textFadeAnimation.value,
                    child: child,
                  );
                },
                child: Text(
                  'v2',
                  style: AppTypography.monoLabel(
                    size: 11,
                    color: AppColors.muted,
                    weight: FontWeight.w400,
                    letterSpacing: 2.0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
