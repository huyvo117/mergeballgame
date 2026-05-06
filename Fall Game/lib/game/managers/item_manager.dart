import 'dart:math';
import 'package:flame/components.dart';
import '../config/game_config.dart';
import '../config/item_types.dart';
import '../config/level_config.dart';
import '../components/falling_item.dart';
import '../components/hazard_item.dart';
import '../cat_catcher_game.dart';

/// Manages spawning of items and hazards based on level configuration.
/// Supports Pattern Spawning during Fever Mode (V-shape, block, wave formations).
class ItemManager extends Component with HasGameReference<CatCatcherGame> {
  late LevelConfig _levelConfig;
  final _random = Random();

  double _spawnTimer = 0;
  double _elapsedTime = 0;
  bool _isActive = false;
  double? _speedOverride; // For Bullet Time skill

  // Pattern spawning state
  bool _isFeverSpawning = false;
  double _patternTimer = 0;
  int _patternIndex = 0;
  List<List<double>>? _currentPattern;

  // Weighted random selection
  late List<ItemType> _weightedItems;
  late List<HazardType> _weightedHazards;

  /// Initialize with a level config. [speedOverride] allows skills to modify fall speed.
  void configure(LevelConfig config, {double? speedOverride}) {
    _levelConfig = config;
    _spawnTimer = 0;
    _elapsedTime = 0;
    _isActive = true;
    _speedOverride = speedOverride;
    _buildWeightedLists();
  }

  /// Stop spawning
  void stop() {
    _isActive = false;
    _isFeverSpawning = false;
  }

  /// Reset the manager
  void reset() {
    _spawnTimer = 0;
    _elapsedTime = 0;
    _isActive = false;
    _isFeverSpawning = false;
    _patternIndex = 0;
    _currentPattern = null;
  }

  /// Start pattern spawning for Fever Mode
  void startFeverSpawning() {
    _isFeverSpawning = true;
    _patternIndex = 0;
    _patternTimer = 0;
    _currentPattern = _generatePattern();
  }

  /// Stop pattern spawning
  void stopFeverSpawning() {
    _isFeverSpawning = false;
    _patternIndex = 0;
    _currentPattern = null;
  }

  void _buildWeightedLists() {
    // Build weighted item list
    _weightedItems = [];
    for (final type in ItemType.values) {
      for (int i = 0; i < type.dropWeight; i++) {
        _weightedItems.add(type);
      }
    }

    // Build weighted hazard list
    _weightedHazards = [];
    for (final type in HazardType.values) {
      for (int i = 0; i < type.dropWeight; i++) {
        _weightedHazards.add(type);
      }
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (!_isActive) return;

    _elapsedTime += dt;

    // During fever: use pattern spawning
    if (_isFeverSpawning && _currentPattern != null) {
      _patternTimer += dt;
      // Spawn a row of the pattern every 0.25s
      if (_patternTimer >= 0.25 && _patternIndex < _currentPattern!.length) {
        _patternTimer -= 0.25;
        _spawnPatternRow(_currentPattern![_patternIndex]);
        _patternIndex++;
        if (_patternIndex >= _currentPattern!.length) {
          // Pattern complete — generate next one
          _currentPattern = _generatePattern();
          _patternIndex = 0;
        }
      }
      return; // Don't do regular spawning during fever patterns
    }

    // Regular spawning
    _spawnTimer += dt;
    final spawnInterval = 1.0 / _levelConfig.itemDropRate;

    if (_spawnTimer >= spawnInterval) {
      _spawnTimer -= spawnInterval;
      _spawnItem();
    }
  }

  void _spawnItem() {
    final gameSize = game.size;
    final margin = 30.0;

    // Random X position within screen bounds
    final x = margin + _random.nextDouble() * (gameSize.x - margin * 2);

    // Calculate current fall speed (increases over time)
    final baseItemSpeed = _speedOverride ?? _levelConfig.itemSpeed;
    final speedMultiplier = baseItemSpeed +
        (_elapsedTime * GameConfig.itemSpeedIncrement);
    final currentSpeed = (GameConfig.itemBaseSpeed * speedMultiplier)
        .clamp(GameConfig.itemBaseSpeed, GameConfig.itemMaxSpeed);

    // Decide if this should be a hazard
    final isHazard = _random.nextDouble() < _levelConfig.hazardFrequency;

    if (isHazard) {
      final hazardType = _weightedHazards[_random.nextInt(_weightedHazards.length)];
      game.world.add(HazardItem(
        hazardType: hazardType,
        fallSpeed: currentSpeed,
        startPosition: Vector2(x, -GameConfig.hazardSize),
      ));
    } else {
      final itemType = _weightedItems[_random.nextInt(_weightedItems.length)];
      game.world.add(FallingItem(
        itemType: itemType,
        fallSpeed: currentSpeed,
        startPosition: Vector2(x, -GameConfig.itemSize),
      ));
    }
  }

  /// Spawn a row of items at specific X positions (for pattern spawning)
  void _spawnPatternRow(List<double> xPositions) {
    final gameSize = game.size;
    final currentSpeed = GameConfig.itemBaseSpeed * 1.8; // Faster during fever

    // During fever, spawn high-value items (energy items, sushi, gold fish)
    final feverItems = [
      ItemType.rainbowJelly,
      ItemType.sushi,
      ItemType.goldFish,
      ItemType.squeezyJelly,
      ItemType.headphones,
    ];

    for (final xRatio in xPositions) {
      final x = (gameSize.x * xRatio).clamp(25.0, gameSize.x - 25.0);
      final itemType = feverItems[_random.nextInt(feverItems.length)];
      game.world.add(FallingItem(
        itemType: itemType,
        fallSpeed: currentSpeed,
        startPosition: Vector2(x, -GameConfig.itemSize),
      ));
    }
  }

  /// Generate a formation pattern for Fever Mode
  List<List<double>> _generatePattern() {
    final patterns = [
      _vShapePattern(),
      _blockPattern(),
      _wavePattern(),
      _diamondPattern(),
    ];
    return patterns[_random.nextInt(patterns.length)];
  }

  /// V-shape formation
  List<List<double>> _vShapePattern() {
    return [
      [0.2, 0.8],          // Row 1: wide
      [0.3, 0.7],          // Row 2: closer
      [0.4, 0.6],          // Row 3: closer
      [0.5],               // Row 4: center point
      [0.4, 0.6],          // Row 5: expand
      [0.3, 0.7],          // Row 6: expand
      [0.2, 0.8],          // Row 7: wide
    ];
  }

  /// Block/grid formation (3x3)
  List<List<double>> _blockPattern() {
    return [
      [0.25, 0.5, 0.75],   // Row 1
      [0.25, 0.5, 0.75],   // Row 2
      [0.25, 0.5, 0.75],   // Row 3
    ];
  }

  /// Wave/sine formation
  List<List<double>> _wavePattern() {
    return [
      [0.3],
      [0.5],
      [0.7],
      [0.5],
      [0.3],
      [0.5],
      [0.7],
      [0.5],
    ];
  }

  /// Diamond shape formation
  List<List<double>> _diamondPattern() {
    return [
      [0.5],               // Top
      [0.35, 0.65],        // 2nd row
      [0.2, 0.5, 0.8],     // Middle (widest)
      [0.35, 0.65],        // 4th row
      [0.5],               // Bottom
    ];
  }

  /// Get elapsed time for HUD display
  double get elapsedTime => _elapsedTime;
}
