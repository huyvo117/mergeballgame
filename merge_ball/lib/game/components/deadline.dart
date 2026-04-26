import 'package:flame/components.dart';
import 'package:flutter/material.dart' hide Draggable;
import '../config/game_config.dart';

/// Visual deadline indicator. When balls stay above this line
/// for too long, it's game over.
class Deadline extends PositionComponent {
  late Paint _linePaint;
  late Paint _glowPaint;
  double _animTimer = 0;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _linePaint = Paint()
      ..color = const Color(0xAAFF4444)
      ..strokeWidth = 0.06
      ..style = PaintingStyle.stroke;

    _glowPaint = Paint()
      ..color = const Color(0x33FF4444)
      ..strokeWidth = 0.15
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _animTimer += dt;
  }

  @override
  void render(Canvas canvas) {
    final halfWidth = GameConfig.containerWidth / 2;
    final y = GameConfig.deadlineY;

    // Pulsing opacity
    final opacity = 0.4 + 0.3 * (1 + _sin(_animTimer * 2)) / 2;
    _linePaint.color = Color.fromRGBO(255, 68, 68, opacity);

    // Glow effect
    canvas.drawLine(
      Offset(-halfWidth, y),
      Offset(halfWidth, y),
      _glowPaint,
    );

    // Dashed line
    const dashWidth = 0.4;
    const dashSpace = 0.3;
    double x = -halfWidth;
    while (x < halfWidth) {
      final endX = (x + dashWidth).clamp(-halfWidth, halfWidth);
      canvas.drawLine(
        Offset(x, y),
        Offset(endX, y),
        _linePaint,
      );
      x += dashWidth + dashSpace;
    }

    // "DANGER" label
    final textPainter = TextPainter(
      text: TextSpan(
        text: '⚠ DANGER',
        style: TextStyle(
          color: Color.fromRGBO(255, 68, 68, opacity),
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    final textScale = 1.0 / GameConfig.cameraZoom;
    canvas.save();
    canvas.translate(-halfWidth + 0.3, y - 0.35);
    canvas.scale(textScale);
    textPainter.paint(canvas, Offset.zero);
    canvas.restore();
  }

  /// Simple sine approximation
  double _sin(double x) {
    x = x % (2 * 3.14159);
    // Taylor series approximation
    double result = x;
    double term = x;
    for (int i = 1; i <= 5; i++) {
      term *= -x * x / ((2 * i) * (2 * i + 1));
      result += term;
    }
    return result;
  }
}
