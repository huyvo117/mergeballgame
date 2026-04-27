import 'dart:math';
import 'package:flame/components.dart';
import '../config/game_config.dart';
import '../config/item_types.dart';
import '../config/level_config.dart';
import '../components/falling_item.dart';
import '../components/hazard_item.dart';
import '../cat_catcher_game.dart';

/// Manages spawning of items and hazards based on level configuration
class ItemManager extends Component with HasGameReference<CatCatcherGame> {
  late LevelConfig _levelConfig;
  final _random = Random();

  double _spawnTimer = 0;
  double _elapsedTime = 0;
  bool _isActive = false;

  // Weighted random selection
  late List<ItemType> _weightedItems;
  late List<HazardType> _weightedHazards;

  /// Initialize with a level config
  void configure(LevelConfig config) {
    _levelConfig = config;
    _spawnTimer = 0;
    _elapsedTime = 0;
    _isActive = true;
    _buildWeightedLists();
  }

  /// Stop spawning
  void stop() {
    _isActive = false;
  }

  /// Reset the manager
  void reset() {
    _spawnTimer = 0;
    _elapsedTime = 0;
    _isActive = false;
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
    _spawnTimer += dt;

    // Calculate current spawn interval based on drop rate
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
    final speedMultiplier = _levelConfig.itemSpeed +
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

  /// Get elapsed time for HUD display
  double get elapsedTime => _elapsedTime;
}
