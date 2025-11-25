import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class DetectedAnimation extends StatefulWidget {
  const DetectedAnimation({super.key});

  @override
  State<DetectedAnimation> createState() => _DetectedAnimationState();
}

class _DetectedAnimationState extends State<DetectedAnimation>
    with TickerProviderStateMixin {

  late AnimationController _scale;
  late AnimationController _icon;

  @override
  void initState() {
    super.initState();

    _scale = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
      lowerBound: 0.2,
      upperBound: 1.2,
    )..forward();

    _icon = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    )..forward();
  }

  @override
  void dispose() {
    _scale.dispose();
    _icon.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: CurvedAnimation(parent: _scale, curve: Curves.elasticOut),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FadeTransition(
            opacity: CurvedAnimation(parent: _icon, curve: Curves.easeOutCubic),
            child: Icon(
              Icons.check_circle,
              size: 80,
              color: AppTheme.yellow,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            "Haltère connectée !",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
