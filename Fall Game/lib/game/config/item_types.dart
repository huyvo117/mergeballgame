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
  );

  final String emoji;
  final String name;
  final int points;
  final Color color;
  final Color glowColor;
  final int dropWeight; // Higher = more frequent

  const ItemType({
    required this.emoji,
    required this.name,
    required this.points,
    required this.color,
    required this.glowColor,
    required this.dropWeight,
  });
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
  );

  final String emoji;
  final String name;
  final int penalty;
  final Color color;
  final Color warningColor;
  final int dropWeight;

  const HazardType({
    required this.emoji,
    required this.name,
    required this.penalty,
    required this.color,
    required this.warningColor,
    required this.dropWeight,
  });
}

/// Meme Cat character skins
enum CatSkin {
  maxwell(
    emoji: '😼',
    name: 'Maxwell Cat',
    color: Color(0xFF8B7355),
    description: 'The spinning cat of legend',
  ),
  popCat(
    emoji: '😺',
    name: 'Pop Cat',
    color: Color(0xFFF5DEB3),
    description: 'Pop pop pop!',
  ),
  elGato(
    emoji: '🐈',
    name: 'El Gato',
    color: Color(0xFF2D2D2D),
    description: 'The mysterious one',
  ),
  bananaCat(
    emoji: '🍌',
    name: 'Banana Cat',
    color: Color(0xFFFFE135),
    description: 'Happy banana vibes',
  );

  final String emoji;
  final String name;
  final Color color;
  final String description;

  const CatSkin({
    required this.emoji,
    required this.name,
    required this.color,
    required this.description,
  });
}
