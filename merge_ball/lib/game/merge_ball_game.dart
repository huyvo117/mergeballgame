import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart' hide Draggable, Route;
import 'components/ball.dart';
import 'components/walls.dart';
import 'components/deadline.dart';
import 'components/drop_guide.dart';
import 'components/background_fx.dart';
import 'config/game_config.dart';

/// The state of the game
enum GameState { playing, gameOver }

/// Represents a pending merge operation
class _MergePair {
  final Ball a;
  final Ball b;
  _MergePair(this.a, this.b);
}

/// Main game class using Forge2DGame
class MergeBallGame extends Forge2DGame {
  
  // Game state
  GameState gameState = GameState.playing;
  int score = 0;
  int highScore = 0;

  // Current ball being positioned
  Ball? currentBall;
  int nextBallLevel = 1;
  
  // Drop cooldown
  double _dropCooldownTimer = 0;
  bool _canSpawn = true;
  
  // Merge queue
  final List<_MergePair> _pendingMerges = [];
  
  // Components
  late DropGuide _dropGuide;
  
  // Random number generator
  final _random = Random();

  // All active balls
  final List<Ball> activeBalls = [];

  MergeBallGame()
      : super(
          gravity: Vector2(0, GameConfig.gravity),
          zoom: GameConfig.cameraZoom,
        );

  @override
  Color backgroundColor() => const Color(0xFF0D0E1A);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Add background effects (behind everything)
    await world.add(BackgroundFx());

    // Add walls
    await world.add(Walls());

    // Add deadline visual
    await world.add(Deadline());

    // Add drop guide
    _dropGuide = DropGuide();
    await world.add(_dropGuide);

    // Add input handler component to the world
    await world.add(_InputHandler());

    // Spawn first ball
    _spawnNextBall();
  }

  /// Spawn a new ball at the top, ready for the player to position
  void _spawnNextBall() {
    if (gameState == GameState.gameOver) return;

    final level = nextBallLevel;
    nextBallLevel = _random.nextInt(GameConfig.maxSpawnLevel) + 1;

    final ball = Ball(
      level: level,
      initialPosition: Vector2(0, GameConfig.spawnY),
      startAsStatic: true,
    );

    currentBall = ball;
    world.add(ball);
    
    _dropGuide.visible = true;
    _dropGuide.updatePosition(0);
  }

  /// Schedule a merge between two balls (called from contact callback)
  void scheduleMerge(Ball a, Ball b) {
    for (final pair in _pendingMerges) {
      if ((pair.a == a && pair.b == b) || (pair.a == b && pair.b == a)) return;
    }
    _pendingMerges.add(_MergePair(a, b));
  }

  /// Process all pending merges with physics impulse
  void _processMerges() {
    final merges = List<_MergePair>.from(_pendingMerges);
    _pendingMerges.clear();

    for (final pair in merges) {
      if (pair.a.isMerging || pair.b.isMerging) continue;
      if (!pair.a.isMounted || !pair.b.isMounted) continue;

      pair.a.isMerging = true;
      pair.b.isMerging = true;

      // Calculate midpoint
      final midpoint = (pair.a.body.position + pair.b.body.position) / 2;
      final newLevel = pair.a.level + 1;

      // Score
      score += newLevel * 10;

      // Remove old balls
      activeBalls.remove(pair.a);
      activeBalls.remove(pair.b);
      pair.a.removeFromParent();
      pair.b.removeFromParent();

      // Spawn new ball if not max level
      if (newLevel <= GameConfig.maxLevel) {
        final newBall = Ball(
          level: newLevel,
          initialPosition: midpoint,
          startAsStatic: false,
          fromMerge: true,
        );
        newBall.hasDropped = true;
        world.add(newBall);
        activeBalls.add(newBall);

        // Apply explosion impulse to nearby balls!
        _applyMergeImpulse(midpoint, newLevel);
      }
    }
  }

  /// Apply outward impulse to nearby balls when a merge happens.
  /// Simulates the "pop" effect of two balls combining into a larger one.
  /// Impulse strength scales with the new ball's level (heavier = bigger pop).
  void _applyMergeImpulse(Vector2 mergePoint, int newLevel) {
    final impulseStrength = GameConfig.mergeImpulseBase * (newLevel / 5.0);
    final effectRadius = GameConfig.mergeImpulseRadius + (newLevel * 0.15);

    for (final ball in activeBalls) {
      if (ball.isMerging || !ball.isMounted || !ball.hasDropped) continue;

      final diff = ball.body.position - mergePoint;
      final distance = diff.length;

      if (distance < effectRadius && distance > 0.01) {
        // Inverse-distance falloff: closer balls get pushed more
        final falloff = 1.0 - (distance / effectRadius);
        final force = falloff * falloff * impulseStrength;

        // Direction: push away from merge point
        final direction = diff.normalized();
        final impulse = direction * force;

        // Apply as impulse (instant force) for satisfying pop effect
        ball.body.applyLinearImpulse(impulse);
      }
    }
  }

  /// Check game over condition
  void _checkGameOver(double dt) {
    if (gameState == GameState.gameOver) return;

    for (final ball in activeBalls) {
      if (ball.hasDropped && !ball.isMerging && ball.isMounted) {
        if (ball.aboveDeadlineTimer >= GameConfig.gameOverDuration) {
          _triggerGameOver();
          return;
        }
      }
    }
  }

  void _triggerGameOver() {
    gameState = GameState.gameOver;
    _dropGuide.visible = false;
    
    if (score > highScore) {
      highScore = score;
    }
    
    overlays.add('gameOver');
  }

  /// Reset the game
  void resetGame() {
    for (final ball in List.from(activeBalls)) {
      ball.removeFromParent();
    }
    activeBalls.clear();
    
    if (currentBall != null && currentBall!.isMounted) {
      currentBall!.removeFromParent();
    }
    currentBall = null;

    score = 0;
    gameState = GameState.playing;
    _canSpawn = true;
    _dropCooldownTimer = 0;
    _pendingMerges.clear();

    overlays.remove('gameOver');

    nextBallLevel = _random.nextInt(GameConfig.maxSpawnLevel) + 1;
    _spawnNextBall();
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (gameState == GameState.gameOver) return;

    _processMerges();
    _checkGameOver(dt);

    if (!_canSpawn) {
      _dropCooldownTimer += dt;
      if (_dropCooldownTimer >= GameConfig.dropCooldown) {
        _canSpawn = true;
        _dropCooldownTimer = 0;
        _spawnNextBall();
      }
    }
  }

  // --- Input Handling ---

  void handleDragUpdate(Vector2 worldPosition) {
    if (gameState == GameState.gameOver) return;
    if (currentBall == null || currentBall!.hasDropped) return;

    final halfWidth = GameConfig.containerWidth / 2;
    final radius = currentBall!.radius;
    final clampedX = worldPosition.x.clamp(-halfWidth + radius, halfWidth - radius);

    currentBall!.body.setTransform(
      Vector2(clampedX.toDouble(), GameConfig.spawnY),
      0,
    );

    _dropGuide.updatePosition(clampedX.toDouble());
  }

  void handleTap(Vector2 worldPosition) {
    if (gameState == GameState.gameOver) return;
    if (currentBall == null || currentBall!.hasDropped) return;

    final halfWidth = GameConfig.containerWidth / 2;
    final radius = currentBall!.radius;
    final clampedX = worldPosition.x.clamp(-halfWidth + radius, halfWidth - radius);

    currentBall!.body.setTransform(
      Vector2(clampedX.toDouble(), GameConfig.spawnY),
      0,
    );

    _dropCurrentBall();
  }

  void handleDragEnd() {
    _dropCurrentBall();
  }

  void _dropCurrentBall() {
    if (gameState == GameState.gameOver) return;
    if (currentBall == null || currentBall!.hasDropped) return;

    currentBall!.drop();
    activeBalls.add(currentBall!);
    currentBall = null;
    _canSpawn = false;
    _dropCooldownTimer = 0;
    _dropGuide.visible = false;
  }
}

/// Full-screen input handler component
class _InputHandler extends PositionComponent
    with DragCallbacks, TapCallbacks, HasGameReference<MergeBallGame> {
  
  _InputHandler() : super(
    size: Vector2(GameConfig.worldWidth * 2, GameConfig.worldHeight * 2),
    position: Vector2(-GameConfig.worldWidth, -GameConfig.worldHeight),
    priority: -100,
  );

  Vector2 _screenToWorld(Vector2 canvasPosition) {
    final camera = game.camera;
    return camera.globalToLocal(canvasPosition);
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);
    final worldPos = _screenToWorld(event.canvasEndPosition);
    game.handleDragUpdate(worldPos);
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    game.handleDragEnd();
  }

  @override
  void onTapUp(TapUpEvent event) {
    super.onTapUp(event);
    final worldPos = _screenToWorld(event.canvasPosition);
    game.handleTap(worldPos);
  }

  @override
  bool containsLocalPoint(Vector2 point) => true;
}
