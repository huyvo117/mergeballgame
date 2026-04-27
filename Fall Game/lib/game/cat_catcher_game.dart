import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart' hide Route;

import 'components/cat_player.dart';
import 'components/falling_item.dart';
import 'components/hazard_item.dart';
import 'components/particle_fx.dart';
import 'components/background.dart';
import 'managers/item_manager.dart';
import 'managers/combo_manager.dart';
import 'managers/audio_manager.dart';
import 'config/game_config.dart';
import 'config/level_config.dart';
import 'config/item_types.dart';

/// Game states
enum GameState { ready, playing, paused, levelComplete, gameOver }

/// Main game class for Meme Cat Catcher
class CatCatcherGame extends FlameGame
    with HasCollisionDetection, DragCallbacks, TapCallbacks {
  // --- Game state ---
  GameState gameState = GameState.ready;
  int score = 0;
  int goldFishCaught = 0;
  double remainingTime = 0;

  // --- Current level ---
  late LevelConfig currentLevel;
  int currentLevelId = 1;

  // --- Player ---
  late CatPlayer player;
  CatSkin selectedSkin = CatSkin.maxwell;

  // --- Managers ---
  late ItemManager itemManager;
  final ComboManager comboManager = ComboManager();
  late GameBackground background;

  // --- Level progress (stars per level) ---
  final Map<int, int> levelStars = {};
  // Unlocked levels
  final Set<int> unlockedLevels = {1, 2}; // First 2 levels unlocked by default

  // --- Screen shake ---
  double _shakeTimer = 0;
  double _shakeIntensity = 0;

  // --- Fever particle timer ---
  double _feverParticleTimer = 0;

  // --- Pending level to start after onLoad ---
  int? _pendingLevelId;
  bool _isLoaded = false;

  CatCatcherGame();

  @override
  Color backgroundColor() => const Color(0xFF0D0E1A);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Add background
    background = GameBackground();
    world.add(background);

    // Create player
    player = CatPlayer(skin: selectedSkin);
    player.position = Vector2(size.x / 2, GameConfig.catY);
    world.add(player);

    // Create item manager (added as component for auto-update)
    itemManager = ItemManager();
    add(itemManager);

    // Setup combo callbacks
    comboManager.onFeverChanged = _onFeverChanged;
    comboManager.onComboChanged = _onComboChanged;

    _isLoaded = true;

    // If a level was queued before onLoad, start it now
    if (_pendingLevelId != null) {
      startLevel(_pendingLevelId!);
      _pendingLevelId = null;
    } else {
      // Show initial overlays
      overlays.add('hud');
    }
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    // Update player Y position on resize
    if (isMounted) {
      player.position.y = size.y - 100;
    }
  }

  // ============================
  // Game Flow
  // ============================

  /// Start a specific level
  void startLevel(int levelId) {
    // If game hasn't loaded yet, queue the level
    if (!_isLoaded) {
      _pendingLevelId = levelId;
      return;
    }

    currentLevelId = levelId;
    currentLevel = LevelDatabase.getLevel(levelId);
    score = 0;
    goldFishCaught = 0;
    remainingTime = currentLevel.timeLimit;

    // Reset managers
    comboManager.reset();
    itemManager.configure(currentLevel);

    // Reset player
    player.position = Vector2(size.x / 2, size.y - 100);
    player.setSkin(selectedSkin);

    // Clear existing items
    world.children.whereType<FallingItem>().forEach((item) => item.removeFromParent());
    world.children.whereType<HazardItem>().forEach((item) => item.removeFromParent());

    // Remove old overlays and show HUD
    overlays.remove('levelComplete');
    overlays.remove('gameOver');
    overlays.remove('pause');

    if (!overlays.isActive('hud')) {
      overlays.add('hud');
    }

    gameState = GameState.playing;
    background.isFeverMode = false;

    AudioManager.playBGM();
  }

  /// Pause the game
  void pauseGame() {
    if (gameState != GameState.playing) return;
    gameState = GameState.paused;
    itemManager.stop();
    overlays.add('pause');
  }

  /// Resume from pause
  void resumeGame() {
    if (gameState != GameState.paused) return;
    gameState = GameState.playing;
    itemManager.configure(currentLevel);
    overlays.remove('pause');
  }

  /// Restart current level
  void restartLevel() {
    startLevel(currentLevelId);
  }

  /// Go to next level
  void nextLevel() {
    if (currentLevelId < LevelDatabase.totalLevels) {
      startLevel(currentLevelId + 1);
    }
  }

  /// Return to menu
  void goToMenu() {
    gameState = GameState.ready;
    itemManager.stop();
    AudioManager.stopBGM();

    // Clear items
    world.children.whereType<FallingItem>().forEach((item) => item.removeFromParent());
    world.children.whereType<HazardItem>().forEach((item) => item.removeFromParent());

    overlays.remove('hud');
    overlays.remove('levelComplete');
    overlays.remove('gameOver');
    overlays.remove('pause');
  }

  // ============================
  // Game Update Loop
  // ============================

  @override
  void update(double dt) {
    if (gameState != GameState.playing) {
      super.update(dt);
      return;
    }

    super.update(dt);

    // Update combo/fever
    comboManager.update(dt);

    // Update timer
    remainingTime -= dt;
    if (remainingTime <= 0) {
      remainingTime = 0;
      _onLevelEnd();
      return;
    }

    // Screen shake
    if (_shakeTimer > 0) {
      _shakeTimer -= dt;
      camera.viewfinder.position = Vector2(
        (_shakeIntensity * (0.5 - (dt * 100 % 1))),
        (_shakeIntensity * (0.5 - (dt * 77 % 1))),
      );
      if (_shakeTimer <= 0) {
        camera.viewfinder.position = Vector2.zero();
      }
    }

    // Fever particles
    if (comboManager.isFever) {
      _feverParticleTimer += dt;
      if (_feverParticleTimer >= 0.5) {
        _feverParticleTimer = 0;
        world.add(ParticleFx.feverRainbow(
          position: Vector2(size.x / 2, 0),
          gameSize: size,
        ));
      }
    }

    // Check collisions with player
    _processCollisions();
  }

  void _processCollisions() {
    // Process falling items
    final items = world.children.whereType<FallingItem>().toList();
    for (final item in items) {
      if (item.isCaught) continue;

      if (_isColliding(player, item)) {
        _onCatchItem(item);
      } else if (item.isMissed) {
        _onMissItem();
      }
    }

    // Process hazards
    final hazards = world.children.whereType<HazardItem>().toList();
    for (final hazard in hazards) {
      if (hazard.isHit) continue;

      if (_isColliding(player, hazard)) {
        _onHitHazard(hazard);
      }
    }
  }

  bool _isColliding(CatPlayer cat, PositionComponent item) {
    // Simple AABB collision between cat tray area and item
    final catLeft = cat.position.x - cat.size.x * 0.45;
    final catRight = cat.position.x + cat.size.x * 0.45;
    final catTop = cat.position.y - cat.size.y * 0.5;
    final catBottom = catTop + cat.size.y * 0.4; // Only top part (tray)

    final itemLeft = item.position.x - item.size.x / 2;
    final itemRight = item.position.x + item.size.x / 2;
    final itemTop = item.position.y - item.size.y / 2;
    final itemBottom = item.position.y + item.size.y / 2;

    return catLeft < itemRight &&
        catRight > itemLeft &&
        catTop < itemBottom &&
        catBottom > itemTop;
  }

  // ============================
  // Collision Handlers
  // ============================

  void _onCatchItem(FallingItem item) {
    // Calculate score
    final points = comboManager.calculateScore(item.itemType.points);
    score += points;

    // Track gold fish
    if (item.itemType == ItemType.goldFish) {
      goldFishCaught++;
    }

    // Update combo
    comboManager.onCatch();

    // Visual feedback
    item.triggerCatchAnimation();
    player.onCatchItem();

    // Particles
    world.add(ParticleFx.catchSparkle(
      position: item.position.clone(),
      color: item.itemType.color,
    ));
    world.add(ParticleFx.scorePopup(
      position: item.position.clone() + Vector2(0, -20),
      score: points,
      isFever: comboManager.isFever,
    ));

    if (comboManager.comboCount > 1) {
      world.add(ParticleFx.comboPopup(
        position: player.position.clone() + Vector2(0, -50),
        comboCount: comboManager.comboCount,
      ));
    }

    // Audio
    AudioManager.playCatchSFX();
    AudioManager.triggerCatchHaptic();

    if (comboManager.comboCount > 1) {
      AudioManager.playComboSFX(comboManager.comboCount);
    }
  }

  void _onMissItem() {
    comboManager.onMiss();
  }

  void _onHitHazard(HazardItem hazard) {
    // Penalty
    score = (score - hazard.hazardType.penalty).clamp(0, 999999);

    // Break combo
    comboManager.onMiss();

    // Visual feedback
    hazard.triggerHitAnimation();
    player.onHitHazard();

    // Screen shake
    _shakeTimer = 0.3;
    _shakeIntensity = 5;

    // Particles
    world.add(ParticleFx.hazardExplosion(
      position: hazard.position.clone(),
    ));

    // Audio
    AudioManager.playHazardSFX();
    AudioManager.triggerHazardHaptic();
  }

  // ============================
  // Fever Mode Callbacks
  // ============================

  void _onFeverChanged(bool isFever) {
    background.isFeverMode = isFever;
    if (isFever) {
      AudioManager.playFeverBGM();
      AudioManager.triggerFeverHaptic();
      _shakeTimer = 0.5;
      _shakeIntensity = 3;
    } else {
      AudioManager.resumeNormalBGM();
    }
  }

  void _onComboChanged(int combo) {
    // Combo changed — UI will read this from comboManager
  }

  // ============================
  // Level End
  // ============================

  void _onLevelEnd() {
    gameState = GameState.levelComplete;
    itemManager.stop();

    // Calculate stars
    final stars = currentLevel.calculateStars(score);

    // Check special objectives
    bool objectiveMet = true;
    if (currentLevel.targetGoldFish != null) {
      objectiveMet = goldFishCaught >= currentLevel.targetGoldFish!;
    }
    if (score < currentLevel.targetScore) {
      objectiveMet = false;
    }

    // Save best stars
    final prevStars = levelStars[currentLevelId] ?? 0;
    if (stars > prevStars && objectiveMet) {
      levelStars[currentLevelId] = stars;
    }

    // Unlock next level if objective met
    if (objectiveMet && currentLevelId < LevelDatabase.totalLevels) {
      unlockedLevels.add(currentLevelId + 1);
    }

    if (objectiveMet) {
      AudioManager.playLevelCompleteSFX();
      overlays.add('levelComplete');
    } else {
      AudioManager.playGameOverSFX();
      overlays.add('gameOver');
    }
  }

  // ============================
  // Input Handling
  // ============================

  @override
  void onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);
    if (gameState != GameState.playing) return;
    player.moveTo(event.localEndPosition.x);
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    player.stopDrag();
  }

  @override
  void onTapUp(TapUpEvent event) {
    if (gameState != GameState.playing) return;
    player.moveTo(event.localPosition.x);
  }
}
