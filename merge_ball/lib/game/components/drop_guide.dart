import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/material.dart' hide Draggable;
import '../config/game_config.dart';

/// Visual guide line showing where the ball will drop.
/// A dotted vertical line from the current ball to the bottom.
class DropGuide extends PositionComponent {
  double guideX = 0;
  bool visible = false;

  late Paint _linePaint;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _linePaint = Paint()
      ..color = const Color(0x44FFFFFF)
      ..strokeWidth = 0.04
      ..style = PaintingStyle.stroke;
  }

  void updatePosition(double x) {
    guideX = x;
  }

  @override
  void render(Canvas canvas) {
    if (!visible) return;

    final topY = GameConfig.spawnY;
    final bottomY = GameConfig.containerBottomY;

    // Dotted vertical line
    const dashHeight = 0.3;
    const dashSpace = 0.2;
    double y = topY;
    while (y < bottomY) {
      final endY = (y + dashHeight).clamp(topY, bottomY);
      canvas.drawLine(
        Offset(guideX, y),
        Offset(guideX, endY),
        _linePaint,
      );
      y += dashHeight + dashSpace;
    }
  }
}
