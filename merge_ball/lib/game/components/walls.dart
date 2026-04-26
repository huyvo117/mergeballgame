import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart' hide Draggable;
import '../config/game_config.dart';

/// Premium styled static walls for the game container.
/// U-shaped container with gradient fills and neon glow edges.
class Walls extends BodyComponent {
  @override
  Body createBody() {
    final bodyDef = BodyDef(
      type: BodyType.static,
      position: Vector2.zero(),
    );

    final body = world.createBody(bodyDef);

    final halfWidth = GameConfig.containerWidth / 2;
    final top = GameConfig.containerTopY;
    final bottom = GameConfig.containerBottomY;
    final thickness = GameConfig.wallThickness;

    // Left wall
    _createWall(body, 
      Vector2(-halfWidth - thickness, top),
      Vector2(-halfWidth, bottom),
    );

    // Right wall
    _createWall(body,
      Vector2(halfWidth, top),
      Vector2(halfWidth + thickness, bottom),
    );

    // Bottom wall
    _createWall(body,
      Vector2(-halfWidth - thickness, bottom),
      Vector2(halfWidth + thickness, bottom + thickness),
    );

    return body;
  }

  void _createWall(Body body, Vector2 topLeft, Vector2 bottomRight) {
    final center = (topLeft + bottomRight) / 2;
    final halfSize = (bottomRight - topLeft) / 2;

    final shape = PolygonShape()
      ..setAsBox(halfSize.x.abs(), halfSize.y.abs(), center, 0);

    final fixtureDef = FixtureDef(
      shape,
      friction: GameConfig.wallFriction,
      restitution: GameConfig.wallRestitution,
    );

    body.createFixture(fixtureDef);
  }

  @override
  void render(Canvas canvas) {
    final halfWidth = GameConfig.containerWidth / 2;
    final top = GameConfig.containerTopY;
    final bottom = GameConfig.containerBottomY;
    final thickness = GameConfig.wallThickness;

    // --- Left Wall ---
    _drawGradientWall(
      canvas,
      Rect.fromLTRB(-halfWidth - thickness, top, -halfWidth, bottom),
      isVertical: true,
      isLeft: true,
    );

    // --- Right Wall ---
    _drawGradientWall(
      canvas,
      Rect.fromLTRB(halfWidth, top, halfWidth + thickness, bottom),
      isVertical: true,
      isLeft: false,
    );

    // --- Bottom Wall ---
    _drawGradientWall(
      canvas,
      Rect.fromLTRB(-halfWidth - thickness, bottom, halfWidth + thickness, bottom + thickness),
      isVertical: false,
      isLeft: false,
    );

    // --- Glow edges (inner sides of walls) ---
    _drawGlowEdge(canvas, -halfWidth, top, -halfWidth, bottom); // Left inner
    _drawGlowEdge(canvas, halfWidth, top, halfWidth, bottom);   // Right inner
    _drawGlowEdge(canvas, -halfWidth, bottom, halfWidth, bottom); // Bottom inner

    // Corner accents
    _drawCornerGlow(canvas, -halfWidth, bottom); // Bottom-left
    _drawCornerGlow(canvas, halfWidth, bottom);  // Bottom-right
  }

  void _drawGradientWall(Canvas canvas, Rect rect, {
    required bool isVertical,
    required bool isLeft,
  }) {
    // Main fill with gradient
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: isVertical
            ? (isLeft ? Alignment.centerRight : Alignment.centerLeft)
            : Alignment.topCenter,
        end: isVertical
            ? (isLeft ? Alignment.centerLeft : Alignment.centerRight)
            : Alignment.bottomCenter,
        colors: const [
          Color(0xFF1E2038),
          Color(0xFF14152A),
        ],
      ).createShader(rect);

    canvas.drawRect(rect, fillPaint);

    // Subtle border
    canvas.drawRect(
      rect,
      Paint()
        ..color = const Color(0xFF2A2D4A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.03,
    );
  }

  void _drawGlowEdge(Canvas canvas, double x1, double y1, double x2, double y2) {
    // Bright inner edge glow
    canvas.drawLine(
      Offset(x1, y1),
      Offset(x2, y2),
      Paint()
        ..color = const Color(0x306366F1) // Indigo glow
        ..strokeWidth = 0.12
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );

    // Sharp edge line
    canvas.drawLine(
      Offset(x1, y1),
      Offset(x2, y2),
      Paint()
        ..color = const Color(0x60818CF8)
        ..strokeWidth = 0.03,
    );
  }

  void _drawCornerGlow(Canvas canvas, double x, double y) {
    canvas.drawCircle(
      Offset(x, y),
      0.3,
      Paint()
        ..color = const Color(0x206366F1)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
  }
}
