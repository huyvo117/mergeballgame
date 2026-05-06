import 'dart:ui';

/// Types of good items that can be caught
enum ItemType {
  fish(
    emoji: '🐟',
    name: 'Fish',
    points: 10,
    color: Color(0xFF60A5FA),
    glowColor: Color(0x4460A5FA),
    dropWeight: 30,
  ),
  milk(
    emoji: '🥛',
    name: 'Milk',
    points: 10,
    color: Color(0xFFF8FAFC),
    glowColor: Color(0x44F8FAFC),
    dropWeight: 25,
  ),
  pizza(
    emoji: '🍕',
    name: 'Pizza',
    points: 15,
    color: Color(0xFFFBBF24),
    glowColor: Color(0x44FBBF24),
    dropWeight: 20,
  ),
  sushi(
    emoji: '🍣',
    name: 'Sushi',
    points: 20,
    color: Color(0xFFFF6B6B),
    glowColor: Color(0x44FF6B6B),
    dropWeight: 15,
  ),
  sunglasses(
    emoji: '🕶️',
    name: 'Sunglasses',
    points: 25,
    color: Color(0xFFA855F7),
    glowColor: Color(0x44A855F7),
    dropWeight: 5,
  ),
  headphones(
    emoji: '🎧',
    name: 'Headphones',
    points: 30,
    color: Color(0xFF22D3EE),
    glowColor: Color(0x4422D3EE),
    dropWeight: 5,
  ),
  goldFish(
    emoji: '🐠',
    name: 'Gold Fish',
    points: 50,
    color: Color(0xFFFFD700),
    glowColor: Color(0x44FFD700),
    dropWeight: 3,
  ),
  // --- Energy Items ---
  squeezyJelly(
    emoji: '🍏',
    name: 'Squeezy Jelly',
    points: 10,
    color: Color(0xFF4ADE80),
    glowColor: Color(0x444ADE80),
    dropWeight: 12,
    energyPercent: 15,
  ),
  rainbowJelly(
    emoji: '🍇',
    name: 'Rainbow Jelly',
    points: 50,
    color: Color(0xFFA855F7),
    glowColor: Color(0x44A855F7),
    dropWeight: 4,
    energyPercent: 50,
  );

  final String emoji;
  final String name;
  final int points;
  final Color color;
  final Color glowColor;
  final int dropWeight; // Higher = more frequent
  final int energyPercent; // Energy added to Energy Bar (0 = not energy item)

  const ItemType({
    required this.emoji,
    required this.name,
    required this.points,
    required this.color,
    required this.glowColor,
    required this.dropWeight,
    this.energyPercent = 0,
  });

  /// Whether this is an energy item
  bool get isEnergyItem => energyPercent > 0;
}

/// Types of hazardous items to avoid
enum HazardType {
  cucumber(
    emoji: '🥒',
    name: 'Cucumber',
    penalty: 50,
    color: Color(0xFF4ADE80),
    warningColor: Color(0xFFFF4444),
    dropWeight: 50,
  ),
  water(
    emoji: '💧',
    name: 'Water Splash',
    penalty: 30,
    color: Color(0xFF38BDF8),
    warningColor: Color(0xFFFF6B6B),
    dropWeight: 30,
  ),
  cyberPolice(
    emoji: '👮',
    name: 'Cyber Police',
    penalty: 100,
    color: Color(0xFF6366F1),
    warningColor: Color(0xFFEF4444),
    dropWeight: 20,
  ),
  toxicFishJar(
    emoji: '🏺',
    name: 'Toxic Fish Jar',
    penalty: 50,
    color: Color(0xFF9333EA),
    warningColor: Color(0xFFFF4444),
    dropWeight: 15,
    slowDuration: 3.0,
  );

  final String emoji;
  final String name;
  final int penalty;
  final Color color;
  final Color warningColor;
  final int dropWeight;
  final double slowDuration; // 0 = no slow, >0 = seconds of slow effect

  const HazardType({
    required this.emoji,
    required this.name,
    required this.penalty,
    required this.color,
    required this.warningColor,
    required this.dropWeight,
    this.slowDuration = 0,
  });

  /// Whether this hazard applies a slow debuff
  bool get appliesSlow => slowDuration > 0;
}

/// Character skill types
enum CharSkill {
  swiftSprint,  // +30% movement speed
  giantPlate,   // +40% catch area width
  jellyRain,    // +50% base points per item
  bulletTime,   // -25% item fall speed
}

/// Meme Cat character skins — 5-tier system
enum CatSkin {
  maxwell(
    emoji: '😼',
    name: 'Maxwell Cat',
    color: Color(0xFF8B7355),
    description: 'The spinning cat of legend',
    tier: 'D',
    price: 0,
    skill: null,
    skillName: '',
    skillDesc: 'Basic speed, no special ability',
  ),
  popCat(
    emoji: '😺',
    name: 'Pop Cat',
    color: Color(0xFFF5DEB3),
    description: 'Pop pop pop!',
    tier: 'C',
    price: 50,
    skill: CharSkill.swiftSprint,
    skillName: 'Swift Sprint',
    skillDesc: '+30% movement speed',
  ),
  elGato(
    emoji: '🐈',
    name: 'El Gato',
    color: Color(0xFF2D2D2D),
    description: 'The mysterious one',
    tier: 'B',
    price: 150,
    skill: CharSkill.giantPlate,
    skillName: 'Giant Plate',
    skillDesc: '+40% catch area width',
  ),
  bananaCat(
    emoji: '🍌',
    name: 'Banana Cat',
    color: Color(0xFFFFE135),
    description: 'Happy banana vibes',
    tier: 'A',
    price: 200,
    skill: CharSkill.jellyRain,
    skillName: 'Jelly Rain',
    skillDesc: '+50% base points per item',
  ),
  nyanCat(
    emoji: '🌈',
    name: 'Nyan Cat',
    color: Color(0xFFFF69B4),
    description: 'The legendary rainbow cat',
    tier: 'S',
    price: 350,
    skill: CharSkill.bulletTime,
    skillName: 'Bullet Time',
    skillDesc: '-25% item fall speed',
  );

  final String emoji;
  final String name;
  final Color color;
  final String description;
  final String tier;
  final int price;
  final CharSkill? skill;
  final String skillName;
  final String skillDesc;

  const CatSkin({
    required this.emoji,
    required this.name,
    required this.color,
    required this.description,
    required this.tier,
    required this.price,
    required this.skill,
    required this.skillName,
    required this.skillDesc,
  });

  /// Tier badge color
  Color get tierColor {
    switch (tier) {
      case 'D': return const Color(0xFF9CA3AF);
      case 'C': return const Color(0xFF4ADE80);
      case 'B': return const Color(0xFF60A5FA);
      case 'A': return const Color(0xFFC084FC);
      case 'S': return const Color(0xFFFFD700);
      default: return const Color(0xFF9CA3AF);
    }
  }

  /// Get CatSkin by name string (for persistence)
  static CatSkin fromName(String name) {
    return CatSkin.values.firstWhere(
      (s) => s.name == name,
      orElse: () => CatSkin.maxwell,
    );
  }

  /// Check if this skin has a specific skill
  bool hasSkill(CharSkill s) => skill == s;
}

