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
import 'managers/player_data.dart';
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
  int diamondsEarned = 0; // Diamonds earned this level

  // --- Stack Match-3 ---
  final List<ItemType> itemStack = []; // Items on the plate (max 7)
  int matchChainLevel = 0; // Current chain combo level
  int totalMatches = 0; // Total match-3s this level

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

  // --- Fever popup state ---
  bool showFeverPopup = false;
  double _feverPopupTimer = 0;

  // --- Pending level to start after onLoad ---
  int? _pendingLevelId;
  bool _isLoaded = false;

  CatCatcherGame();

  @override
  Color backgroundColor() => const Color(0xFF0D0E1A);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // CRITICAL: Set camera anchor to topLeft so world (0,0) maps to screen top-left.
    // Flame v1.19+ defaults to center, which causes the world to render offset.
    camera.viewfinder.anchor = Anchor.topLeft;

    // Add background
    background = GameBackground();
    world.add(background);

    // Create player
    player = CatPlayer(skin: selectedSkin);
    player.position = Vector2(size.x / 2, size.y - 100);
    world.add(player);

    // Create item manager (added as component for auto-update)
    itemManager = ItemManager();
    add(itemManager);

    // Setup combo callbacks
    comboManager.onFeverChanged = _onFeverChanged;
    comboManager.onComboChanged = _onComboChanged;
    comboManager.onFeverActivated = _onFeverPopup;

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
    // Update player Y position and background on resize
    if (isMounted) {
      player.position.y = size.y - 100;
      background.size = size.clone();
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
    diamondsEarned = 0;
    remainingTime = currentLevel.timeLimit;

    // Reset stack
    itemStack.clear();
    matchChainLevel = 0;
    totalMatches = 0;

    // Reset managers
    comboManager.reset();

    // Bullet Time skill: reduce item fall speed by 25%
    if (selectedSkin.hasSkill(CharSkill.bulletTime)) {
      // Create a modified level config with reduced speed
      itemManager.configure(currentLevel, speedOverride: currentLevel.itemSpeed * 0.75);
    } else {
      itemManager.configure(currentLevel);
    }

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

    // Fever popup auto-hide
    if (showFeverPopup) {
      _feverPopupTimer -= dt;
      if (_feverPopupTimer <= 0) {
        showFeverPopup = false;
      }
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
    // Track per-item stats
    comboManager.onCatch(itemType: item.itemType);

    // Track gold fish
    if (item.itemType == ItemType.goldFish) {
      goldFishCaught++;
    }

    // Visual feedback
    item.triggerCatchAnimation();
    player.onCatchItem();

    // Catch sparkle at item position
    world.add(ParticleFx.catchSparkle(
      position: item.position.clone(),
      color: item.itemType.color,
    ));

    // Audio — pitch scales with combo
    AudioManager.playCatchSFX(comboManager.comboCount);
    AudioManager.triggerCatchHaptic();

    // === MODE BRANCHING ===
    if (currentLevel.useStack) {
      _onCatchItem_StackMode(item);
    } else {
      _onCatchItem_ClassicMode(item);
    }
  }

  /// CLASSIC MODE: Catch = immediate score (Stage 1-2)
  void _onCatchItem_ClassicMode(FallingItem item) {
    // Calculate base points — Jelly Rain skill: +50% base points
    int basePoints = item.itemType.points;
    if (selectedSkin.hasSkill(CharSkill.jellyRain)) {
      basePoints = (basePoints * 1.5).round();
    }
    final points = comboManager.calculateScore(basePoints);
    score += points;

    // Score popup
    world.add(ParticleFx.scorePopup(
      position: item.position.clone() + Vector2(0, -20),
      score: points,
      isFever: comboManager.isFever,
    ));

    // Combo popup
    if (comboManager.comboCount > 1) {
      world.add(ParticleFx.comboPopup(
        position: player.position.clone() + Vector2(0, -50),
        comboCount: comboManager.comboCount,
      ));
      AudioManager.playComboSFX(comboManager.comboCount);
    }
  }

  /// STACK MATCH-3 MODE: Catch = add to stack, match = score (Stage 3)
  void _onCatchItem_StackMode(FallingItem item) {
    itemStack.add(item.itemType);
    player.updateStack(itemStack);

    // Check for stack overflow FIRST
    if (itemStack.length > GameConfig.maxStackSize) {
      _onStackOverflow();
      return;
    }

    // Then check for matches
    matchChainLevel = 0;
    _checkStackMatches();
  }

  /// Match-3 detection: find 3+ adjacent same items in the stack
  void _checkStackMatches() {
    if (itemStack.length < 3) return;

    // Scan for groups of 3+ adjacent same items
    int matchStart = -1;
    int matchLen = 0;

    for (int i = 0; i < itemStack.length; i++) {
      if (i == 0 || itemStack[i] != itemStack[i - 1]) {
        // Check if previous group was a match
        if (matchLen >= 3) break;
        matchStart = i;
        matchLen = 1;
      } else {
        matchLen++;
      }
    }
    // Check last group too
    if (matchLen < 3) {
      // Also check from matchStart forward
      matchStart = -1;
      matchLen = 0;
      for (int i = 0; i < itemStack.length; i++) {
        if (matchStart == -1) {
          matchStart = i;
          matchLen = 1;
        } else if (itemStack[i] == itemStack[matchStart]) {
          matchLen++;
        } else {
          if (matchLen >= 3) break;
          matchStart = i;
          matchLen = 1;
        }
      }
    }

    if (matchLen >= 3 && matchStart >= 0) {
      _explodeMatch(matchStart, matchLen);
    }
  }

  /// Explode matched items from the stack
  void _explodeMatch(int startIdx, int count) {
    // Get matched item type for scoring
    final matchedType = itemStack[startIdx];
    matchChainLevel++;
    totalMatches++;

    // Calculate score multiplier based on match length
    int multiplier;
    if (count >= 5) {
      multiplier = GameConfig.match5Multiplier;
    } else if (count == 4) {
      multiplier = GameConfig.match4Multiplier;
    } else {
      multiplier = GameConfig.match3Multiplier;
    }

    // Chain bonus
    multiplier += (matchChainLevel - 1) * GameConfig.chainBonusPerLevel;

    // Calculate points
    int basePoints = matchedType.points * count;
    if (selectedSkin.hasSkill(CharSkill.jellyRain)) {
      basePoints = (basePoints * 1.5).round();
    }
    final points = basePoints * multiplier;
    score += points;

    // Energy from energy items being matched
    if (matchedType.isEnergyItem) {
      for (int i = 0; i < count; i++) {
        comboManager.onCatch(itemType: matchedType);
      }
    }

    // Remove matched items from stack
    itemStack.removeRange(startIdx, startIdx + count);
    player.updateStack(itemStack);

    // Visual: match explosion particles at player position
    for (int i = 0; i < count; i++) {
      final offsetY = -(startIdx + i) * 18.0 - 30;
      world.add(ParticleFx.catchSparkle(
        position: player.position.clone() + Vector2(0, offsetY),
        color: matchedType.color,
      ));
    }

    // Score popup
    world.add(ParticleFx.scorePopup(
      position: player.position.clone() + Vector2(0, -80),
      score: points,
      isFever: comboManager.isFever,
    ));

    // Combo popup for chain
    if (matchChainLevel > 1) {
      world.add(ParticleFx.comboPopup(
        position: player.position.clone() + Vector2(0, -120),
        comboCount: matchChainLevel,
      ));
    }

    // Audio — Match-3 explosion chord
    AudioManager.playMatchSFX(count);
    AudioManager.triggerCatchHaptic();

    // Screen shake for big matches
    if (count >= 4) {
      _shakeTimer = 0.2;
      _shakeIntensity = 3;
    }

    // Check for chain matches after removal
    Future.delayed(const Duration(milliseconds: 200), () {
      if (gameState == GameState.playing) {
        _checkStackMatches();
      }
    });
  }

  /// Stack overflow — Game Over!
  void _onStackOverflow() {
    gameState = GameState.gameOver;
    itemManager.stop();

    // Screen shake
    _shakeTimer = 0.5;
    _shakeIntensity = 8;

    // Particles explosion from stack
    for (int i = 0; i < itemStack.length; i++) {
      world.add(ParticleFx.hazardExplosion(
        position: player.position.clone() + Vector2(0, -i * 18.0 - 30),
      ));
    }

    // Diamond consolation
    if (score > 0) {
      diamondsEarned = 3;
      PlayerData.instance.addDiamonds(diamondsEarned);
    }

    AudioManager.playGameOverSFX();
    AudioManager.triggerHazardHaptic();
    overlays.add('gameOver');
  }

  void _onMissItem() {
    comboManager.onMiss();
  }

  void _onHitHazard(HazardItem hazard) {
    // Stack mode: remove top item from stack
    if (currentLevel.useStack && itemStack.isNotEmpty) {
      itemStack.removeLast();
      player.updateStack(itemStack);
    }
    // Apply score penalty
    score = (score - hazard.hazardType.penalty).clamp(0, 999999);

    // Break combo
    comboManager.onMiss();

    // Visual feedback
    hazard.triggerHitAnimation();
    player.onHitHazard();

    // Slow debuff from Toxic Fish Jar
    if (hazard.hazardType.appliesSlow) {
      player.applySlow(hazard.hazardType.slowDuration);
    }

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
      // Start pattern spawning during fever
      itemManager.startFeverSpawning();
    } else {
      AudioManager.resumeNormalBGM();
      // Return to regular spawning
      itemManager.stopFeverSpawning();
    }
  }

  void _onComboChanged(int combo) {
    // Combo changed — UI will read this from comboManager
  }

  /// Triggered when Fever is activated — show massive popup
  void _onFeverPopup() {
    showFeverPopup = true;
    _feverPopupTimer = 2.5; // Show for 2.5 seconds
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

    // === Diamond rewards ===
    if (objectiveMet && stars > 0) {
      diamondsEarned = PlayerData.diamondRewardForStars(stars);
    } else if (score > 0) {
      diamondsEarned = 3; // Consolation
    } else {
      diamondsEarned = 0;
    }
    if (diamondsEarned > 0) {
      PlayerData.instance.addDiamonds(diamondsEarned);
    }

    // Sync progress to PlayerData
    if (objectiveMet) {
      PlayerData.instance.updateLevelProgress(
        currentLevelId, stars, LevelDatabase.totalLevels,
      );
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
