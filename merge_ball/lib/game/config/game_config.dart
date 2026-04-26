import 'dart:ui';

/// Game configuration constants
/// Forge2D uses meters, not pixels. Camera zoom handles conversion.
class GameConfig {
  // World dimensions (in Forge2D meters)
  static const double worldWidth = 10.0;
  static const double worldHeight = 20.0;
  static const double wallThickness = 0.3;

  // Container dimensions
  static const double containerWidth = 9.0;
  static const double containerHeight = 14.0;
  static const double containerBottomY = 7.0;
  static const double containerTopY = -7.0;

  // Deadline (game over line) - near top of container
  static const double deadlineY = -5.5;

  // Spawn position
  static const double spawnY = -8.5;

  // Physics
  static const double gravity = 30.0;
  static const double ballRestitution = 0.15;
  static const double ballFriction = 0.6;
  static const double wallRestitution = 0.05;
  static const double wallFriction = 0.9;

  // Merge explosion impulse strength (scales with level)
  static const double mergeImpulseBase = 8.0;
  static const double mergeImpulseRadius = 4.0; // meters - area of effect

  // Gameplay
  static const int maxLevel = 11;
  static const int maxSpawnLevel = 5;
  static const double dropCooldown = 0.6;
  static const double gameOverDuration = 2.0;

  // Camera
  static const double cameraZoom = 40.0;
}

/// Ball data for each level (1-11)
class BallData {
  final int level;
  final double radius;
  final double density;
  final double linearDamping;
  final Color color;
  final Color gradientColor;
  final Color glowColor;
  final Color innerRingColor;
  final String emoji;
  final String name;

  const BallData({
    required this.level,
    required this.radius,
    required this.density,
    required this.linearDamping,
    required this.color,
    required this.gradientColor,
    required this.glowColor,
    required this.innerRingColor,
    required this.emoji,
    required this.name,
  });
}

/// All ball definitions with per-level physics
class BallConfig {
  static final List<BallData> levels = [
    // Level 1: Cherry - tiny, light
    const BallData(
      level: 1, radius: 0.32, density: 0.8, linearDamping: 0.3,
      color: Color(0xFFFF6B6B), gradientColor: Color(0xFFCC3344),
      glowColor: Color(0x44FF6B6B), innerRingColor: Color(0xFFFF9999),
      emoji: '🍒', name: 'Cherry',
    ),
    // Level 2: Strawberry - small, light
    const BallData(
      level: 2, radius: 0.50, density: 1.0, linearDamping: 0.3,
      color: Color(0xFFFF8FAB), gradientColor: Color(0xFFE05580),
      glowColor: Color(0x44FF8FAB), innerRingColor: Color(0xFFFFB8CC),
      emoji: '🍓', name: 'Strawberry',
    ),
    // Level 3: Grape - medium-small
    const BallData(
      level: 3, radius: 0.66, density: 1.3, linearDamping: 0.25,
      color: Color(0xFFC084FC), gradientColor: Color(0xFF7C3AED),
      glowColor: Color(0x44C084FC), innerRingColor: Color(0xFFDDB4FE),
      emoji: '🍇', name: 'Grape',
    ),
    // Level 4: Dekopon - medium
    const BallData(
      level: 4, radius: 0.80, density: 1.6, linearDamping: 0.2,
      color: Color(0xFFFBBF24), gradientColor: Color(0xFFD97706),
      glowColor: Color(0x44FBBF24), innerRingColor: Color(0xFFFDE68A),
      emoji: '🍊', name: 'Dekopon',
    ),
    // Level 5: Orange - medium
    const BallData(
      level: 5, radius: 0.93, density: 2.0, linearDamping: 0.2,
      color: Color(0xFFFB923C), gradientColor: Color(0xFFEA580C),
      glowColor: Color(0x44FB923C), innerRingColor: Color(0xFFFDBA74),
      emoji: '🍊', name: 'Orange',
    ),
    // Level 6: Apple - medium-large, heavier
    const BallData(
      level: 6, radius: 1.05, density: 2.5, linearDamping: 0.15,
      color: Color(0xFFEF4444), gradientColor: Color(0xFFB91C1C),
      glowColor: Color(0x44EF4444), innerRingColor: Color(0xFFFCA5A5),
      emoji: '🍎', name: 'Apple',
    ),
    // Level 7: Pear - large
    const BallData(
      level: 7, radius: 1.16, density: 3.0, linearDamping: 0.1,
      color: Color(0xFFA3E635), gradientColor: Color(0xFF65A30D),
      glowColor: Color(0x44A3E635), innerRingColor: Color(0xFFD9F99D),
      emoji: '🍐', name: 'Pear',
    ),
    // Level 8: Peach - large, heavy
    const BallData(
      level: 8, radius: 1.27, density: 3.6, linearDamping: 0.1,
      color: Color(0xFFFDA4AF), gradientColor: Color(0xFFE11D48),
      glowColor: Color(0x44FDA4AF), innerRingColor: Color(0xFFFECDD3),
      emoji: '🍑', name: 'Peach',
    ),
    // Level 9: Pineapple - very large, very heavy
    const BallData(
      level: 9, radius: 1.38, density: 4.2, linearDamping: 0.08,
      color: Color(0xFFFACC15), gradientColor: Color(0xFFCA8A04),
      glowColor: Color(0x44FACC15), innerRingColor: Color(0xFFFEF08A),
      emoji: '🍍', name: 'Pineapple',
    ),
    // Level 10: Melon - huge
    const BallData(
      level: 10, radius: 1.48, density: 5.0, linearDamping: 0.05,
      color: Color(0xFF4ADE80), gradientColor: Color(0xFF16A34A),
      glowColor: Color(0x444ADE80), innerRingColor: Color(0xFFBBF7D0),
      emoji: '🍈', name: 'Melon',
    ),
    // Level 11: Watermelon - biggest, heaviest
    const BallData(
      level: 11, radius: 1.58, density: 6.0, linearDamping: 0.05,
      color: Color(0xFF22C55E), gradientColor: Color(0xFF15803D),
      glowColor: Color(0x4422C55E), innerRingColor: Color(0xFF86EFAC),
      emoji: '🍉', name: 'Watermelon',
    ),
  ];

  static BallData getLevel(int level) {
    return levels[level - 1];
  }
}
