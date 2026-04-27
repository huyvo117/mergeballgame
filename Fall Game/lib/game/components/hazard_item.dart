import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../config/game_config.dart';
import '../config/item_types.dart';

/// A falling hazard item that the player should avoid
/// Visual: Has a red warning border and pulsing danger effect
class HazardItem extends PositionComponent with CollisionCallbacks {
  final HazardType hazardType;
  double fallSpeed;
  bool isHit = false;
  bool _isRemoving = false;

  // Visual animation
  double _pulseTimer = 0;
  double _rotateAngle = 0;
  double _hitAnimTimer = 0;
  final double _initialRotation;

  HazardItem({
    required this.hazardType,
    required this.fallSpeed,
    required Vector2 startPosition,
  })  : _initialRotation = (Random().nextDouble() - 0.5) * 0.5,
        super(
          position: startPosition,
          size: Vector2.all(GameConfig.hazardSize),
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(CircleHitbox());
  }

  /// Trigger the hit animation (flash and fly away)
  void triggerHitAnimation() {
    if (isHit) return;
    isHit = true;
    _hitAnimTimer = 0.4;
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (isHit) {
      _hitAnimTimer -= dt;
      // Fly upward and fade
      position.y -= 200 * dt;
      if (_hitAnimTimer <= 0 && !_isRemoving) {
        _isRemoving = true;
        removeFromParent();
      }
      return;
    }

    // Fall downward
    position.y += fallSpeed * dt;

    // Slight rotation wobble
    _rotateAngle = _initialRotation + sin(_pulseTimer * 4) * 0.15;

    // Danger pulse
    _pulseTimer += dt;

    // Remove if off-screen
    final gameHeight = findGame()?.size.y ?? GameConfig.designHeight;
    if (position.y > gameHeight + size.y) {
      if (!_isRemoving) {
        _isRemoving = true;
        removeFromParent();
      }
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final center = size / 2;
    final radius = size.x / 2;

    canvas.save();
    canvas.translate(center.x, center.y);
    canvas.rotate(_rotateAngle);
    canvas.translate(-center.x, -center.y);

    // Opacity for hit animation
    final opacity = isHit ? (_hitAnimTimer / 0.4).clamp(0.0, 1.0) : 1.0;

    // === Danger glow ===
    final dangerPulse = sin(_pulseTimer * 6) * 0.3 + 0.7;
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          hazardType.warningColor.withValues(alpha: 0.4 * dangerPulse * opacity),
          hazardType.warningColor.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(center.x, center.y),
        radius: radius * 1.5,
      ));
    canvas.drawCircle(Offset(center.x, center.y), radius * 1.5, glowPaint);

    // === Hazard background (dark with warning tint) ===
    final bgPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          hazardType.color.withValues(alpha: 0.8 * opacity),
          Color.lerp(hazardType.color, Colors.black, 0.5)!.withValues(alpha: 0.9 * opacity),
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(center.x, center.y),
        radius: radius,
      ));
    canvas.drawCircle(Offset(center.x, center.y), radius, bgPaint);

    // === Warning border (pulsing red) ===
    final borderPaint = Paint()
      ..color = hazardType.warningColor.withValues(alpha: dangerPulse * opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawCircle(Offset(center.x, center.y), radius - 1, borderPaint);

    // === ⚠ Warning triangle indicator ===
    final warningSize = radius * 0.4;
    final warningY = center.y - radius - warningSize * 0.5;
    final trianglePaint = Paint()
      ..color = hazardType.warningColor.withValues(alpha: dangerPulse * opacity);
    final triangle = Path()
      ..moveTo(center.x, warningY - warningSize)
      ..lineTo(center.x - warningSize * 0.7, warningY + warningSize * 0.3)
      ..lineTo(center.x + warningSize * 0.7, warningY + warningSize * 0.3)
      ..close();
    canvas.drawPath(triangle, trianglePaint);

    // === Emoji ===
    final textPainter = TextPainter(
      text: TextSpan(
        text: hazardType.emoji,
        style: TextStyle(fontSize: radius * 1.1),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        center.x - textPainter.width / 2,
        center.y - textPainter.height / 2,
      ),
    );

    canvas.restore();
  }
}
