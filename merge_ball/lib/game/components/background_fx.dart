import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart' hide Draggable;
import '../config/game_config.dart';

/// Animated background with floating particles and gradient grid.
/// Renders behind all game elements.
class BackgroundFx extends PositionComponent {
  final List<_Particle> _particles = [];
  final math.Random _random = math.Random();
  double _time = 0;

  static const int _particleCount = 40;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    priority = -1000; // Render behind everything

    // Generate particles
    final halfW = GameConfig.containerWidth / 2 + 2;
    final topY = GameConfig.containerTopY - 3;
    final botY = GameConfig.containerBottomY + 2;

    for (int i = 0; i < _particleCount; i++) {
      _particles.add(_Particle(
        x: _random.nextDouble() * halfW * 2 - halfW,
        y: _random.nextDouble() * (botY - topY) + topY,
        size: _random.nextDouble() * 0.06 + 0.02,
        speed: _random.nextDouble() * 0.3 + 0.1,
        phase: _random.nextDouble() * math.pi * 2,
        alpha: _random.nextDouble() * 0.3 + 0.05,
      ));
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
  }

  @override
  void render(Canvas canvas) {
    final halfW = GameConfig.containerWidth / 2;
    final topY = GameConfig.containerTopY;
    final botY = GameConfig.containerBottomY;

    // Dark gradient background for container area
    final bgRect = Rect.fromLTRB(-halfW - 0.3, topY, halfW + 0.3, botY + 0.3);
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF12131F),
          Color(0xFF0A0B14),
          Color(0xFF0E0F1A),
        ],
      ).createShader(bgRect);
    canvas.drawRect(bgRect, bgPaint);

    // Subtle grid lines
    final gridPaint = Paint()
      ..color = const Color(0x08FFFFFF)
      ..strokeWidth = 0.02;

    // Vertical grid lines
    for (double x = -halfW; x <= halfW; x += 1.0) {
      canvas.drawLine(
        Offset(x, topY),
        Offset(x, botY),
        gridPaint,
      );
    }

    // Horizontal grid lines
    for (double y = topY; y <= botY; y += 1.0) {
      canvas.drawLine(
        Offset(-halfW, y),
        Offset(halfW, y),
        gridPaint,
      );
    }

    // Floating particles
    for (final p in _particles) {
      final floatY = math.sin(_time * p.speed + p.phase) * 0.5;
      final floatX = math.cos(_time * p.speed * 0.7 + p.phase) * 0.3;
      final alpha = (p.alpha * (0.5 + 0.5 * math.sin(_time * 0.8 + p.phase))).clamp(0.0, 1.0);

      canvas.drawCircle(
        Offset(p.x + floatX, p.y + floatY),
        p.size,
        Paint()..color = Color.fromRGBO(140, 160, 255, alpha),
      );
    }

    // Subtle vignette corners (radial darkening)
    final vignetteRect = Rect.fromLTRB(-halfW - 1, topY - 2, halfW + 1, botY + 1);
    final vignettePaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 1.0,
        colors: [
          Colors.transparent,
          const Color(0x30000000),
        ],
      ).createShader(vignetteRect);
    canvas.drawRect(vignetteRect, vignettePaint);
  }
}

class _Particle {
  final double x, y, size, speed, phase, alpha;
  const _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.phase,
    required this.alpha,
  });
}
