/// ---------------------------------------------------------------------------
/// ResUniq - app_animations.dart
/// ---------------------------------------------------------------------------
/// PURPOSE:
/// Reusable UI widgets shared by multiple screens. Keeping these widgets here avoids duplicating UI code.
///
/// BEGINNER GUIDE:
/// - UI screens/widgets should mainly display information and collect input.
/// - Providers hold/change state that the UI listens to.
/// - Services/repositories perform Firebase, API, PDF, or other data work.
/// - Models describe the data passed between these layers.
///
/// TIP:
/// Read this file together with the classes it imports. The imported classes
/// usually explain where data comes from and where actions are performed.
/// ---------------------------------------------------------------------------
library;

import 'package:flutter/material.dart';

/// Lightweight entrance animation used across the app.
class FadeSlideIn extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final Offset begin;

  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 520),
    this.begin = const Offset(0, 0.045),
  });

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

/// _FadeSlideInState is responsible for this part of the ResUniq application.
/// It is kept separate so other files can reuse it without duplicating logic.
class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    final curve = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _opacity = Tween<double>(begin: 0, end: 1).animate(curve);
    _slide = Tween<Offset>(begin: widget.begin, end: Offset.zero).animate(curve);

    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future<void>.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

/// A small, polished loading indicator that avoids a static spinner.
class AppLoadingIndicator extends StatefulWidget {
  final String? label;
  final Color color;
  final double size;

  const AppLoadingIndicator({
    super.key,
    this.label,
    this.color = const Color(0xFF0F285D),
    this.size = 34,
  });

  @override
  State<AppLoadingIndicator> createState() => _AppLoadingIndicatorState();
}

/// _AppLoadingIndicatorState is responsible for this part of the ResUniq application.
/// It is kept separate so other files can reuse it without duplicating logic.
class _AppLoadingIndicatorState extends State<AppLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return SizedBox(
              width: widget.size,
              height: widget.size,
              child: CircularProgressIndicator(
                value: null,
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(widget.color),
                strokeCap: StrokeCap.round,
              ),
            );
          },
        ),
        if (widget.label != null) ...[
          const SizedBox(height: 12),
          Text(
            widget.label!,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ],
    );
  }
}

/// Smoothly animates changes between selected/unselected states.
class AnimatedSelection extends StatelessWidget {
  final bool selected;
  final Widget child;

  const AnimatedSelection({
    super.key,
    required this.selected,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      transform: Matrix4.identity()..scaleByDouble(selected ? 1.015 : 1.0, selected ? 1.015 : 1.0, 1.0, 1.0),
      transformAlignment: Alignment.center,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        child: KeyedSubtree(
          key: ValueKey(selected),
          child: child,
        ),
      ),
    );
  }
}

/// Gentle pulsing effect for the splash/app branding.
class Pulse extends StatefulWidget {
  final Widget child;

  const Pulse({super.key, required this.child});

  @override
  State<Pulse> createState() => _PulseState();
}

/// _PulseState is responsible for this part of the ResUniq application.
/// It is kept separate so other files can reuse it without duplicating logic.
class _PulseState extends State<Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final scale = 0.97 + (_controller.value * 0.03);
        return Transform.scale(scale: scale, child: child);
      },
      child: widget.child,
    );
  }
}

/// Custom page transition used throughout the app.
class AppPageTransitionsBuilder extends PageTransitionsBuilder {
  const AppPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
    );
    final slide = Tween<Offset>(
      begin: const Offset(0.025, 0),
      end: Offset.zero,
    ).animate(curved);

    return FadeTransition(
      opacity: curved,
      child: SlideTransition(position: slide, child: child),
    );
  }
}
