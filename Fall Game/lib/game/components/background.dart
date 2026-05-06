import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../config/game_config.dart';

/// Animated gradient background with floating particles
class GameBackground extends PositionComponent {
  bool isFeverMode = false;
  double _feverTransition = 0; // 0 = normal, 1 = full fever
  final List<_FloatingDot> _dots = [];
  final _random = Random();

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    final gameSize = findGame()?.size ?? Vector2(GameConfig.designWidth, GameConfig.designHeight);
    size = gameSize.clone();
    position = Vector2.zero();
    anchor = Anchor.topLeft;
    priority = -1000; // Behind everything

    // Generate floating dots
    for (int i = 0; i < 30; i++) {
      _dots.add(_FloatingDot(
        x: _random.nextDouble() * size.x,
        y: _random.nextDouble() * size.y,
        radius: 1.0 + _random.nextDouble() * 3.0,
        speed: 10 + _random.nextDouble() * 25,
        alpha: 0.1 + _random.nextDouble() * 0.3,
        phase: _random.nextDouble() * pi * 2,
      ));
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Smooth fever transition
    if (isFeverMode && _feverTransition < 1.0) {
      _feverTransition = (_feverTransition + dt * 2).clamp(0.0, 1.0);
    } else if (!isFeverMode && _feverTransition > 0) {
      _feverTransition = (_feverTransition - dt * 1.5).clamp(0.0, 1.0);
    }

    // Animate dots
    for (final dot in _dots) {
      dot.y += dot.speed * dt;
      dot.phase += dt;
      dot.x += sin(dot.phase) * 0.5;

      // Wrap around
      if (dot.y > size.y + dot.radius) {
        dot.y = -dot.radius;
        dot.x = _random.nextDouble() * size.x;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // === Normal gradient (purple -> deep blue) ===
    final normalGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: const [
        GameConfig.bgMidPurple,
        GameConfig.bgDarkPurple,
        GameConfig.bgDeepBlue,
      ],
      stops: const [0.0, 0.5, 1.0],
    );

    // === Fever gradient (neon animated) ===
    final feverGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        GameConfig.feverNeonPink.withValues(alpha: 0.3),
        GameConfig.bgDarkPurple,
        GameConfig.feverNeonCyan.withValues(alpha: 0.2),
      ],
      stops: const [0.0, 0.5, 1.0],
    );

    final rect = Rect.fromLTWH(0, 0, size.x, size.y);

    // Draw normal gradient
    canvas.drawRect(
      rect,
      Paint()..shader = normalGradient.createShader(rect),
    );

    // Overlay fever gradient with transition
    if (_feverTransition > 0) {
      canvas.drawRect(
        rect,
        Paint()
          ..shader = feverGradient.createShader(rect)
          ..color = Colors.white.withValues(alpha: _feverTransition * 0.6),
      );
    }

    // === Floating dots ===
    for (final dot in _dots) {
      Color dotColor;
      if (_feverTransition > 0.5) {
        // Fever mode: rainbow dots
        final colors = [
          GameConfig.feverNeonPink,
          GameConfig.feverNeonCyan,
          GameConfig.feverNeonYellow,
        ];
        dotColor = colors[(_dots.indexOf(dot)) % colors.length];
      } else {
        dotColor = Colors.white;
      }

      canvas.drawCircle(
        Offset(dot.x, dot.y),
        dot.radius,
        Paint()..color = dotColor.withValues(alpha: dot.alpha * (0.7 + sin(dot.phase * 2) * 0.3)),
      );
    }

    // === Subtle vignette overlay ===
    final vignettePaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 1.2,
        colors: [
          Colors.transparent,
          Colors.black.withValues(alpha: 0.4),
        ],
      ).createShader(rect);
    canvas.drawRect(rect, vignettePaint);
  }
}

class _FloatingDot {
  double x, y, radius, speed, alpha, phase;

  _FloatingDot({
    required this.x,
    required this.y,
    required this.radius,
    required this.speed,
    required this.alpha,
    required this.phase,
  });
}
