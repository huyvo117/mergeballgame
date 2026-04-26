import 'dart:math' as math;
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart' hide Draggable;
import '../config/game_config.dart';
import '../merge_ball_game.dart';

/// A ball entity in the merge ball game.
/// Each ball has a level (1-11) and can merge with same-level balls.
/// Physics properties (density, damping) vary per level for realistic weight.
class Ball extends BodyComponent<MergeBallGame> with ContactCallbacks {
  final int level;
  final double radius;
  final Vector2 initialPosition;
  final bool startAsStatic;

  bool hasDropped = false;
  bool isMerging = false;
  double aboveDeadlineTimer = 0.0;

  // Merge animation
  double _spawnAnimTimer = 0.0;
  static const double _spawnAnimDuration = 0.3;
  bool _isNewlySpawned;

  // Visual properties (initialized in onLoad)
  bool _visualsReady = false;
  late BallData _ballData;
  late Paint _gradientPaint;
  late Paint _highlightPaint;
  late Paint _shadowPaint;
  late Paint _glowPaint;
  late Paint _innerRingPaint;
  late Paint _borderPaint;
  late Paint _innerGradientPaint;
  late TextPainter _emojiPainter;

  Ball({
    required this.level,
    required this.initialPosition,
    this.startAsStatic = false,
    bool fromMerge = false,
  })  : radius = BallConfig.getLevel(level).radius,
        _isNewlySpawned = fromMerge;

  @override
  Future<void> onLoad() async {
    // Must initialize _ballData BEFORE super.onLoad() because
    // super.onLoad() calls createBody() which needs _ballData
    _ballData = BallConfig.getLevel(level);
    await super.onLoad();
    _setupPaints();
    _setupEmoji();
    _visualsReady = true;
  }

  void _setupPaints() {
    // Main gradient - rich 3-stop radial gradient
    _gradientPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.35, -0.35),
        radius: 1.1,
        colors: [
          _brighten(_ballData.color, 0.25),
          _ballData.color,
          _ballData.gradientColor,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: radius));

    // Inner subtle gradient for depth
    _innerGradientPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.1, 0.2),
        radius: 0.8,
        colors: [
          _ballData.gradientColor.withAlpha(60),
          _ballData.gradientColor.withAlpha(0),
        ],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: radius * 0.9));

    // Specular highlight - top-left gloss
    _highlightPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.45, -0.45),
        radius: 0.55,
        colors: [
          Colors.white.withAlpha(140),
          Colors.white.withAlpha(40),
          Colors.white.withAlpha(0),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: radius));

    // Drop shadow
    _shadowPaint = Paint()
      ..color = Colors.black.withAlpha(60)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.3);

    // Outer glow
    _glowPaint = Paint()
      ..color = _ballData.glowColor
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.5);

    // Inner ring accent
    _innerRingPaint = Paint()
      ..color = _ballData.innerRingColor.withAlpha(50)
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.08;

    // Border
    _borderPaint = Paint()
      ..color = _ballData.gradientColor.withAlpha(120)
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.04;
  }

  void _setupEmoji() {
    _emojiPainter = TextPainter(
      text: TextSpan(
        text: _ballData.emoji,
        style: TextStyle(
          fontSize: radius * 50, // Will be scaled down
          height: 1.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    _emojiPainter.layout();
  }

  /// Brighten a color by a factor (0.0 to 1.0)
  Color _brighten(Color color, double factor) {
    final ri = (color.r * 255).round();
    final gi = (color.g * 255).round();
    final bi = (color.b * 255).round();
    final ai = (color.a * 255).round();
    final r = (ri + (255 - ri) * factor).round().clamp(0, 255);
    final g = (gi + (255 - gi) * factor).round().clamp(0, 255);
    final b = (bi + (255 - bi) * factor).round().clamp(0, 255);
    return Color.fromARGB(ai, r, g, b);
  }

  @override
  Body createBody() {
    final bodyDef = BodyDef(
      type: startAsStatic ? BodyType.static : BodyType.dynamic,
      position: initialPosition,
      userData: this,
      fixedRotation: false,
      bullet: level >= 8, // High-level balls use CCD to prevent tunneling
      linearDamping: _ballData.linearDamping,
      angularDamping: 0.5,
    );

    final body = world.createBody(bodyDef);

    final shape = CircleShape()..radius = radius;
    final fixtureDef = FixtureDef(
      shape,
      restitution: GameConfig.ballRestitution,
      friction: GameConfig.ballFriction,
      density: _ballData.density, // Per-level density for weight differences!
    );

    body.createFixture(fixtureDef);
    return body;
  }

  /// Drop the ball (make it dynamic and affected by gravity)
  void drop() {
    if (hasDropped) return;
    hasDropped = true;
    body.setType(BodyType.dynamic);
    body.setAwake(true);
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Spawn animation timer
    if (_isNewlySpawned) {
      _spawnAnimTimer += dt;
      if (_spawnAnimTimer >= _spawnAnimDuration) {
        _isNewlySpawned = false;
      }
    }

    // Check if ball is above deadline for game over detection
    if (hasDropped && !isMerging) {
      if (body.position.y < GameConfig.deadlineY) {
        aboveDeadlineTimer += dt;
      } else {
        aboveDeadlineTimer = 0.0;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    // Guard: don't render until visuals are ready
    if (!_visualsReady) return;

    // Spawn scale animation
    if (_isNewlySpawned) {
      final t = (_spawnAnimTimer / _spawnAnimDuration).clamp(0.0, 1.0);
      // Elastic ease-out
      double scale = t < 1.0
          ? 1.0 - math.pow(2.0, -10.0 * t) * math.sin((t * 10.0 - 0.75) * (2.0 * math.pi / 3.0))
          : 1.0;
      scale = scale.clamp(0.1, 1.3);
      canvas.save();
      canvas.scale(scale, scale);
    }

    // Outer glow (subtle ambient light)
    canvas.drawCircle(Offset.zero, radius * 1.15, _glowPaint);

    // Drop shadow (offset slightly down-right)
    canvas.drawCircle(
      Offset(radius * 0.06, radius * 0.08),
      radius,
      _shadowPaint,
    );

    // Main body with rich gradient
    canvas.drawCircle(Offset.zero, radius, _gradientPaint);

    // Inner depth gradient
    canvas.drawCircle(Offset.zero, radius * 0.9, _innerGradientPaint);

    // Inner ring accent (decorative)
    canvas.drawCircle(
      Offset(-radius * 0.05, -radius * 0.05),
      radius * 0.7,
      _innerRingPaint,
    );

    // Specular highlight
    canvas.drawCircle(Offset.zero, radius, _highlightPaint);

    // Outer border
    canvas.drawCircle(Offset.zero, radius, _borderPaint);

    // Emoji in center
    canvas.save();
    final emojiTargetSize = radius * 1.1;
    final emojiScale = emojiTargetSize / _emojiPainter.width;
    canvas.scale(emojiScale);
    _emojiPainter.paint(
      canvas,
      Offset(
        -_emojiPainter.width / 2,
        -_emojiPainter.height / 2,
      ),
    );
    canvas.restore();

    if (_isNewlySpawned) {
      canvas.restore();
    }
  }

  @override
  void beginContact(Object other, Contact contact) {
    if (other is Ball && !isMerging && !other.isMerging) {
      if (level == other.level && level < GameConfig.maxLevel) {
        game.scheduleMerge(this, other);
      }
    }
  }
}
