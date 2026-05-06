import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import 'package:flutter/material.dart';
import '../config/game_config.dart';
import '../config/item_types.dart';

/// The player-controlled Meme Cat character
/// Moves horizontally at the bottom of the screen to catch falling items.
///
/// To replace with a real sprite:
/// 1. Add your sprite image to assets/images/
/// 2. Replace the `_renderPlaceholder` method with a SpriteComponent
class CatPlayer extends PositionComponent with CollisionCallbacks {
  CatSkin skin;

  // Movement state
  double _targetX = 0;
  bool _isDragging = false;

  // Visual feedback
  double _bounceScale = 1.0;
  double _bounceTimer = 0;
  bool _isHurt = false;
  double _hurtTimer = 0;
  double _hurtFlashTimer = 0;

  // Slow debuff
  bool _isSlowed = false;
  double _slowTimer = 0;

  // Mouth/tray animation
  double _mouthOpen = 0.0;

  // Stack visual state
  List<ItemType> _stack = [];
  double _stackWobble = 0;

  CatPlayer({this.skin = CatSkin.maxwell})
      : super(
          size: Vector2(
            skin.hasSkill(CharSkill.giantPlate)
                ? GameConfig.catWidth * 1.4
                : GameConfig.catWidth,
            GameConfig.catHeight,
          ),
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Add collision hitbox (the "tray" area)
    add(RectangleHitbox(
      size: Vector2(size.x * 0.9, size.y * 0.4),
      position: Vector2(size.x * 0.05, 0),
      anchor: Anchor.topLeft,
    ));
  }

  /// Update target position from drag input
  void moveTo(double screenX) {
    _isDragging = true;
    _targetX = screenX.clamp(
      size.x / 2,
      (findGame()?.size.x ?? GameConfig.designWidth) - size.x / 2,
    );
  }

  /// Stop dragging — cat stays in place
  void stopDrag() {
    _isDragging = false;
  }

  /// Trigger catch animation (bouncy scale effect)
  void onCatchItem() {
    _bounceScale = 1.3;
    _bounceTimer = 0.15;
    _mouthOpen = 1.0;
  }

  /// Trigger hurt animation (flash red)
  void onHitHazard() {
    _isHurt = true;
    _hurtTimer = 0.5;
    _hurtFlashTimer = 0;
  }

  /// Apply slow debuff from Toxic Fish Jar
  void applySlow(double duration) {
    _isSlowed = true;
    _slowTimer = duration;
  }

  /// Whether the player is currently slowed
  bool get isSlowed => _isSlowed;

  /// Update the visual stack of items on the plate
  void updateStack(List<ItemType> stack) {
    _stack = List.from(stack);
    if (_stack.length >= 6) {
      _stackWobble = 1.0; // Trigger warning wobble
    }
  }

  /// Current stack for HUD
  List<ItemType> get stack => _stack;

  /// Change cat skin and apply skill-based size changes
  void setSkin(CatSkin newSkin) {
    skin = newSkin;
    // Giant Plate: +40% catch area width
    final newWidth = newSkin.hasSkill(CharSkill.giantPlate)
        ? GameConfig.catWidth * 1.4
        : GameConfig.catWidth;
    size = Vector2(newWidth, GameConfig.catHeight);
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Stack wobble warning
    if (_stackWobble > 0) {
      _stackWobble = (_stackWobble - dt * 2).clamp(0.0, 1.0);
    }

    // Slow debuff timer
    if (_isSlowed) {
      _slowTimer -= dt;
      if (_slowTimer <= 0) {
        _isSlowed = false;
        _slowTimer = 0;
      }
    }

    // Smooth movement towards target
    if (_isDragging || (position.x - _targetX).abs() > 1) {
      final diff = _targetX - position.x;
      // Swift Sprint: +30% movement speed
      double speedMul = skin.hasSkill(CharSkill.swiftSprint) ? 1.3 : 1.0;
      // Slow debuff: -50% movement speed
      if (_isSlowed) speedMul *= 0.5;
      position.x += diff * 12 * speedMul * dt;

      // Clamp to screen bounds
      final gameWidth = findGame()?.size.x ?? GameConfig.designWidth;
      position.x = position.x.clamp(size.x / 2, gameWidth - size.x / 2);
    }

    // Bounce animation (catch feedback)
    if (_bounceTimer > 0) {
      _bounceTimer -= dt;
      if (_bounceTimer <= 0) {
        _bounceScale = 1.0;
      } else {
        _bounceScale = 1.0 + 0.3 * sin(_bounceTimer * 20);
      }
    }

    // Mouth close animation
    if (_mouthOpen > 0) {
      _mouthOpen = (_mouthOpen - dt * 4).clamp(0.0, 1.0);
    }

    // Hurt animation
    if (_isHurt) {
      _hurtTimer -= dt;
      _hurtFlashTimer += dt;
      if (_hurtTimer <= 0) {
        _isHurt = false;
        _hurtTimer = 0;
        _hurtFlashTimer = 0;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    _renderPlaceholder(canvas);
  }

  /// Placeholder rendering — replace with sprite later
  /// Draws a cute cat face with a tray
  void _renderPlaceholder(Canvas canvas) {
    final w = size.x;
    final h = size.y;
    final centerX = w / 2;
    final centerY = h / 2;

    // Apply bounce scale
    canvas.save();
    canvas.translate(centerX, centerY);
    canvas.scale(_bounceScale, _bounceScale);
    canvas.translate(-centerX, -centerY);

    // Determine color (flash when hurt, purple when slowed)
    Color bodyColor = skin.color;
    if (_isHurt && ((_hurtFlashTimer * 10).toInt() % 2 == 0)) {
      bodyColor = const Color(0xFFFF4444);
    } else if (_isSlowed) {
      bodyColor = Color.lerp(skin.color, const Color(0xFF9333EA), 0.4)!;
    }

    // === Tray / Catching area ===
    final trayPaint = Paint()
      ..color = bodyColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    final trayRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(4, 0, w - 8, h * 0.35),
      const Radius.circular(8),
    );
    canvas.drawRRect(trayRect, trayPaint);

    // Tray border
    final trayBorderPaint = Paint()
      ..color = bodyColor.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(trayRect, trayBorderPaint);

    // === Cat Body (circle) ===
    final bodyPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          bodyColor,
          Color.lerp(bodyColor, Colors.black, 0.3)!,
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(centerX, h * 0.65),
        radius: w * 0.35,
      ));
    canvas.drawCircle(
      Offset(centerX, h * 0.65),
      w * 0.32,
      bodyPaint,
    );

    // === Cat Ears ===
    final earPaint = Paint()..color = bodyColor;
    // Left ear
    final leftEar = Path()
      ..moveTo(centerX - w * 0.22, h * 0.40)
      ..lineTo(centerX - w * 0.35, h * 0.20)
      ..lineTo(centerX - w * 0.08, h * 0.40)
      ..close();
    canvas.drawPath(leftEar, earPaint);
    // Right ear
    final rightEar = Path()
      ..moveTo(centerX + w * 0.22, h * 0.40)
      ..lineTo(centerX + w * 0.35, h * 0.20)
      ..lineTo(centerX + w * 0.08, h * 0.40)
      ..close();
    canvas.drawPath(rightEar, earPaint);

    // Inner ear (pink)
    final innerEarPaint = Paint()..color = GameConfig.primaryPink.withValues(alpha: 0.5);
    final leftInner = Path()
      ..moveTo(centerX - w * 0.19, h * 0.42)
      ..lineTo(centerX - w * 0.28, h * 0.26)
      ..lineTo(centerX - w * 0.11, h * 0.42)
      ..close();
    canvas.drawPath(leftInner, innerEarPaint);
    final rightInner = Path()
      ..moveTo(centerX + w * 0.19, h * 0.42)
      ..lineTo(centerX + w * 0.28, h * 0.26)
      ..lineTo(centerX + w * 0.11, h * 0.42)
      ..close();
    canvas.drawPath(rightInner, innerEarPaint);

    // === Eyes ===
    final eyePaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(centerX - 10, h * 0.58), 6, eyePaint);
    canvas.drawCircle(Offset(centerX + 10, h * 0.58), 6, eyePaint);

    // Pupils
    final pupilPaint = Paint()..color = Colors.black;
    canvas.drawCircle(Offset(centerX - 9, h * 0.59), 3.5, pupilPaint);
    canvas.drawCircle(Offset(centerX + 11, h * 0.59), 3.5, pupilPaint);

    // Eye shine
    final shinePaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(centerX - 8, h * 0.57), 1.5, shinePaint);
    canvas.drawCircle(Offset(centerX + 12, h * 0.57), 1.5, shinePaint);

    // === Mouth ===
    final mouthPaint = Paint()
      ..color = const Color(0xFFFF6B9D)
      ..style = PaintingStyle.fill;

    if (_mouthOpen > 0.1) {
      // Open mouth (catching!)
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(centerX, h * 0.72),
          width: 10 * _mouthOpen,
          height: 6 * _mouthOpen,
        ),
        mouthPaint,
      );
    } else {
      // Cute smile :3
      final smilePath = Path()
        ..moveTo(centerX - 6, h * 0.70)
        ..quadraticBezierTo(centerX, h * 0.76, centerX + 6, h * 0.70);
      canvas.drawPath(
        smilePath,
        Paint()
          ..color = const Color(0xFFFF6B9D)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..strokeCap = StrokeCap.round,
      );
    }

    // === Whiskers ===
    final whiskerPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    // Left whiskers
    canvas.drawLine(Offset(centerX - 14, h * 0.66), Offset(centerX - 30, h * 0.62), whiskerPaint);
    canvas.drawLine(Offset(centerX - 14, h * 0.68), Offset(centerX - 30, h * 0.68), whiskerPaint);
    // Right whiskers
    canvas.drawLine(Offset(centerX + 14, h * 0.66), Offset(centerX + 30, h * 0.62), whiskerPaint);
    canvas.drawLine(Offset(centerX + 14, h * 0.68), Offset(centerX + 30, h * 0.68), whiskerPaint);

    // === Glow effect under tray ===
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          bodyColor.withValues(alpha: 0.3),
          bodyColor.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(centerX, h * 0.15),
        radius: w * 0.5,
      ));
    canvas.drawCircle(Offset(centerX, h * 0.15), w * 0.5, glowPaint);

    canvas.restore();

    // === Render Stack Items above the tray ===
    _renderStack(canvas);
  }

  /// Draw stacked items as emoji text above the cat
  void _renderStack(Canvas canvas) {
    if (_stack.isEmpty) return;

    final w = size.x;
    final centerX = w / 2;
    final stackSlotH = 20.0;
    final maxSlots = GameConfig.maxStackSize;

    // Wobble offset for nearly-full stack
    final wobble = _stack.length >= 6
        ? sin(_stackWobble * 20) * 3
        : 0.0;

    for (int i = 0; i < _stack.length; i++) {
      final yPos = -8.0 - (i * stackSlotH); // Stack upward from tray

      // Background slot
      final slotColor = i >= maxSlots - 1
          ? const Color(0x44FF4444) // Red for last slot
          : i >= maxSlots - 2
              ? const Color(0x44FFAA00) // Orange warning
              : const Color(0x22FFFFFF);

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(centerX + wobble, yPos),
            width: 30,
            height: stackSlotH - 2,
          ),
          const Radius.circular(4),
        ),
        Paint()..color = slotColor,
      );

      // Item emoji as text
      final tp = TextPainter(
        text: TextSpan(
          text: _stack[i].emoji,
          style: const TextStyle(fontSize: 14),
        ),
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      tp.paint(
        canvas,
        Offset(centerX - tp.width / 2 + wobble, yPos - tp.height / 2),
      );
    }

    // Stack count indicator
    final countTp = TextPainter(
      text: TextSpan(
        text: '${_stack.length}/$maxSlots',
        style: TextStyle(
          fontSize: 10,
          color: _stack.length >= maxSlots - 1
              ? const Color(0xFFFF4444)
              : const Color(0x99FFFFFF),
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    countTp.layout();
    countTp.paint(
      canvas,
      Offset(centerX - countTp.width / 2, -8 - _stack.length * stackSlotH - 14),
    );
  }
}
