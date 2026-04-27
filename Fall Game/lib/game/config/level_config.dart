/// Configuration for a single game level
class LevelConfig {
  final int levelId;
  final int stageId;
  final String stageName;
  final String levelName;
  final String objective; // Description of what player must achieve
  final int targetScore;
  final double timeLimit; // Seconds
  final double itemDropRate; // Items per second
  final double hazardFrequency; // 0.0 - 1.0, chance of hazard vs good item
  final double itemSpeed; // Base fall speed multiplier
  final List<int> starThresholds; // [1-star, 2-star, 3-star] scores
  final int? targetGoldFish; // Special objective: catch N gold fish
  final bool unlocked;

  const LevelConfig({
    required this.levelId,
    required this.stageId,
    required this.stageName,
    required this.levelName,
    required this.objective,
    required this.targetScore,
    required this.timeLimit,
    required this.itemDropRate,
    required this.hazardFrequency,
    required this.itemSpeed,
    required this.starThresholds,
    this.targetGoldFish,
    this.unlocked = false,
  });

  /// Calculate star rating based on score
  int calculateStars(int score) {
    if (score >= starThresholds[2]) return 3;
    if (score >= starThresholds[1]) return 2;
    if (score >= starThresholds[0]) return 1;
    return 0;
  }
}

/// All level definitions organized by stages
class LevelDatabase {
  static const List<LevelConfig> levels = [
    // ==========================================
    // STAGE 1: Kitten's Kitchen (Tutorial)
    // ==========================================
    LevelConfig(
      levelId: 1,
      stageId: 1,
      stageName: "Kitten's Kitchen",
      levelName: 'First Catch',
      objective: 'Catch items to score 100 points!',
      targetScore: 100,
      timeLimit: 30,
      itemDropRate: 1.0,
      hazardFrequency: 0.0, // No hazards in tutorial
      itemSpeed: 1.0,
      starThresholds: [100, 150, 250],
      unlocked: true,
    ),
    LevelConfig(
      levelId: 2,
      stageId: 1,
      stageName: "Kitten's Kitchen",
      levelName: 'Getting Hungry',
      objective: 'Score 200 points in 30 seconds!',
      targetScore: 200,
      timeLimit: 30,
      itemDropRate: 1.3,
      hazardFrequency: 0.0,
      itemSpeed: 1.1,
      starThresholds: [200, 350, 500],
      unlocked: true,
    ),
    LevelConfig(
      levelId: 3,
      stageId: 1,
      stageName: "Kitten's Kitchen",
      levelName: 'Watch Out!',
      objective: 'Score 250 points — beware of cucumbers!',
      targetScore: 250,
      timeLimit: 35,
      itemDropRate: 1.5,
      hazardFrequency: 0.1, // First hazards appear
      itemSpeed: 1.1,
      starThresholds: [250, 400, 600],
    ),
    LevelConfig(
      levelId: 4,
      stageId: 1,
      stageName: "Kitten's Kitchen",
      levelName: 'Combo Cat',
      objective: 'Score 400 points — use combos!',
      targetScore: 400,
      timeLimit: 40,
      itemDropRate: 1.8,
      hazardFrequency: 0.12,
      itemSpeed: 1.2,
      starThresholds: [400, 600, 900],
    ),
    LevelConfig(
      levelId: 5,
      stageId: 1,
      stageName: "Kitten's Kitchen",
      levelName: 'Kitchen Boss',
      objective: 'Score 600 points before time runs out!',
      targetScore: 600,
      timeLimit: 45,
      itemDropRate: 2.0,
      hazardFrequency: 0.15,
      itemSpeed: 1.3,
      starThresholds: [600, 900, 1300],
    ),

    // ==========================================
    // STAGE 2: Neon Alley (Normal)
    // ==========================================
    LevelConfig(
      levelId: 6,
      stageId: 2,
      stageName: 'Neon Alley',
      levelName: 'Street Vibes',
      objective: 'Score 500 points in the neon night!',
      targetScore: 500,
      timeLimit: 35,
      itemDropRate: 2.0,
      hazardFrequency: 0.18,
      itemSpeed: 1.4,
      starThresholds: [500, 800, 1200],
    ),
    LevelConfig(
      levelId: 7,
      stageId: 2,
      stageName: 'Neon Alley',
      levelName: 'Gold Rush',
      objective: 'Catch 3 Gold Fish!',
      targetScore: 400,
      timeLimit: 40,
      itemDropRate: 2.2,
      hazardFrequency: 0.15,
      itemSpeed: 1.4,
      starThresholds: [400, 700, 1100],
      targetGoldFish: 3,
    ),
    LevelConfig(
      levelId: 8,
      stageId: 2,
      stageName: 'Neon Alley',
      levelName: 'Cyber Patrol',
      objective: 'Score 700 points — dodge the Cyber Police!',
      targetScore: 700,
      timeLimit: 40,
      itemDropRate: 2.5,
      hazardFrequency: 0.22,
      itemSpeed: 1.5,
      starThresholds: [700, 1100, 1600],
    ),
    LevelConfig(
      levelId: 9,
      stageId: 2,
      stageName: 'Neon Alley',
      levelName: 'Fever Night',
      objective: 'Score 1000 points — activate Fever Mode!',
      targetScore: 1000,
      timeLimit: 45,
      itemDropRate: 2.8,
      hazardFrequency: 0.20,
      itemSpeed: 1.5,
      starThresholds: [1000, 1500, 2200],
    ),
    LevelConfig(
      levelId: 10,
      stageId: 2,
      stageName: 'Neon Alley',
      levelName: 'Alley Showdown',
      objective: 'Score 1200 points in the chaos!',
      targetScore: 1200,
      timeLimit: 50,
      itemDropRate: 3.0,
      hazardFrequency: 0.25,
      itemSpeed: 1.6,
      starThresholds: [1200, 1800, 2500],
    ),

    // ==========================================
    // STAGE 3: Meme Dimension (Hard)
    // ==========================================
    LevelConfig(
      levelId: 11,
      stageId: 3,
      stageName: 'Meme Dimension',
      levelName: 'Meme Portal',
      objective: 'Score 1000 points in 30 seconds!',
      targetScore: 1000,
      timeLimit: 30,
      itemDropRate: 3.5,
      hazardFrequency: 0.25,
      itemSpeed: 1.8,
      starThresholds: [1000, 1600, 2400],
    ),
    LevelConfig(
      levelId: 12,
      stageId: 3,
      stageName: 'Meme Dimension',
      levelName: 'Cucumber Storm',
      objective: 'Survive the cucumber rain — Score 1500!',
      targetScore: 1500,
      timeLimit: 40,
      itemDropRate: 3.5,
      hazardFrequency: 0.35,
      itemSpeed: 1.9,
      starThresholds: [1500, 2200, 3000],
    ),
    LevelConfig(
      levelId: 13,
      stageId: 3,
      stageName: 'Meme Dimension',
      levelName: 'Golden Feast',
      objective: 'Catch 5 Gold Fish before time runs out!',
      targetScore: 1200,
      timeLimit: 45,
      itemDropRate: 3.8,
      hazardFrequency: 0.28,
      itemSpeed: 2.0,
      starThresholds: [1200, 2000, 3000],
      targetGoldFish: 5,
    ),
    LevelConfig(
      levelId: 14,
      stageId: 3,
      stageName: 'Meme Dimension',
      levelName: 'Speed Demon',
      objective: 'Score 2000 points — items fall FAST!',
      targetScore: 2000,
      timeLimit: 40,
      itemDropRate: 4.0,
      hazardFrequency: 0.30,
      itemSpeed: 2.2,
      starThresholds: [2000, 3000, 4500],
    ),
    LevelConfig(
      levelId: 15,
      stageId: 3,
      stageName: 'Meme Dimension',
      levelName: 'Final Meme Boss',
      objective: 'Score 3000 in the ultimate challenge!',
      targetScore: 3000,
      timeLimit: 50,
      itemDropRate: 4.5,
      hazardFrequency: 0.35,
      itemSpeed: 2.5,
      starThresholds: [3000, 4500, 6500],
    ),
  ];

  /// Get level by ID (1-indexed)
  static LevelConfig getLevel(int levelId) {
    return levels.firstWhere((l) => l.levelId == levelId);
  }

  /// Get all levels for a stage
  static List<LevelConfig> getStage(int stageId) {
    return levels.where((l) => l.stageId == stageId).toList();
  }

  /// Get unique stage names
  static List<String> get stageNames {
    return levels.map((l) => l.stageName).toSet().toList();
  }

  /// Total number of levels
  static int get totalLevels => levels.length;

  /// Total number of stages
  static int get totalStages => 3;
}
