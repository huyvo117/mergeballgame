import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../config/game_config.dart';
import '../config/item_types.dart';

/// A falling good item that the player should catch
class FallingItem extends PositionComponent with CollisionCallbacks {
  final ItemType itemType;
  double fallSpeed;
  bool isCaught = false;
  bool _isRemoving = false;

  // Visual animation
  double _wobbleTimer = 0;
  double _glowPulse = 0;
  double _catchAnimTimer = 0;
  double _catchScale = 1.0;
  final double _wobbleOffset;

  FallingItem({
    required this.itemType,
    required this.fallSpeed,
    required Vector2 startPosition,
  })  : _wobbleOffset = Random().nextDouble() * 3.14 * 2,
        super(
          position: startPosition,
          size: Vector2.all(GameConfig.itemSize),
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(CircleHitbox());
  }

  /// Trigger the catch animation (bouncy before disappearing)
  void triggerCatchAnimation() {
    if (isCaught) return;
    isCaught = true;
    _catchAnimTimer = 0.25; // Duration of catch animation
    _catchScale = 1.4;
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (isCaught) {
      // Catch animation: scale up then shrink away
      _catchAnimTimer -= dt;
      if (_catchAnimTimer > 0.15) {
        _catchScale = 1.4;
      } else if (_catchAnimTimer > 0) {
        _catchScale = (_catchAnimTimer / 0.15) * 1.4;
      } else {
        if (!_isRemoving) {
          _isRemoving = true;
          removeFromParent();
        }
      }
      return;
    }

    // Fall downward
    position.y += fallSpeed * dt;

    // Gentle wobble side to side
    _wobbleTimer += dt;
    position.x += sin(_wobbleTimer * 3 + _wobbleOffset) * 0.5;

    // Glow pulse
    _glowPulse += dt * 4;

    // Remove if off-screen
    final gameHeight = findGame()?.size.y ?? GameConfig.designHeight;
    if (position.y > gameHeight + size.y) {
      if (!_isRemoving) {
        _isRemoving = true;
        removeFromParent();
      }
    }
  }

  /// Check if item has fallen past the screen
  bool get isMissed =>
      !isCaught && position.y > (findGame()?.size.y ?? GameConfig.designHeight);

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final center = size / 2;
    final radius = size.x / 2;

    canvas.save();

    // Apply catch scale animation
    if (isCaught) {
      canvas.translate(center.x, center.y);
      canvas.scale(_catchScale, _catchScale);
      canvas.translate(-center.x, -center.y);
    }

    // === Glow effect ===
    final glowRadius = radius * (1.2 + sin(_glowPulse) * 0.15);
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          itemType.glowColor,
          itemType.glowColor.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(center.x, center.y),
        radius: glowRadius,
      ));
    canvas.drawCircle(Offset(center.x, center.y), glowRadius, glowPaint);

    // === Item background circle ===
    final bgPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          itemType.color.withValues(alpha: 0.9),
          itemType.color.withValues(alpha: 0.5),
        ],
        stops: const [0.3, 1.0],
      ).createShader(Rect.fromCircle(
        center: Offset(center.x, center.y),
        radius: radius,
      ));
    canvas.drawCircle(Offset(center.x, center.y), radius, bgPaint);

    // === Border ===
    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(Offset(center.x, center.y), radius - 1, borderPaint);

    // === Emoji text ===
    final textPainter = TextPainter(
      text: TextSpan(
        text: itemType.emoji,
        style: TextStyle(fontSize: radius * 1.2),
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
