import 'dart:ui';

/// Global game configuration constants
class GameConfig {
  // === Screen & World ===
  static const double designWidth = 400;
  static const double designHeight = 800;

  // === Player (Cat) ===
  static const double catWidth = 80;
  static const double catHeight = 60;
  static const double catY = 700; // Y position of cat (near bottom)
  static const double catSpeed = 600; // Pixels per second movement speed

  // === Items ===
  static const double itemSize = 40;
  static const double itemBaseSpeed = 150; // Initial fall speed (pixels/sec)
  static const double itemSpeedIncrement = 0.05; // Speed increase per second elapsed
  static const double itemMaxSpeed = 500;

  // === Hazards ===
  static const double hazardSize = 44;
  static const int hazardPenalty = 50;

  // === Combo & Fever ===
  static const int feverComboThreshold = 5; // Catches needed for Fever
  static const double feverDuration = 5.0; // Base fever duration in seconds
  static const double feverExtension = 1.5; // Extra seconds per catch during fever
  static const double feverMaxDuration = 12.0;
  static const int feverMultiplier = 2;

  // === Scoring ===
  static const int baseCatchScore = 10;
  static const int comboBonusPerLevel = 5; // Extra points per combo level

  // === Stack Match-3 ===
  static const int maxStackSize = 7;        // Max items on plate
  static const int match3Multiplier = 5;    // 3-match score multiplier
  static const int match4Multiplier = 7;    // 4-match score multiplier
  static const int match5Multiplier = 10;   // 5+ match score multiplier
  static const int chainBonusPerLevel = 2;  // Extra multiplier per chain level

  // === Drop cooldown ===
  static const double minSpawnInterval = 0.3;

  // === Colors — Vibrant Candy / Neon Pastel ===
  static const Color primaryPink = Color(0xFFFF6B9D);
  static const Color primaryPurple = Color(0xFFC084FC);
  static const Color primaryMint = Color(0xFF34D399);
  static const Color primaryYellow = Color(0xFFFBBF24);
  static const Color primaryCyan = Color(0xFF22D3EE);

  static const Color bgDarkPurple = Color(0xFF1A0533);
  static const Color bgMidPurple = Color(0xFF2D1B69);
  static const Color bgDeepBlue = Color(0xFF0F172A);

  static const Color feverNeonPink = Color(0xFFFF2D95);
  static const Color feverNeonCyan = Color(0xFF00F5FF);
  static const Color feverNeonYellow = Color(0xFFFFFF00);

  static const Color textWhite = Color(0xFFF8FAFC);
  static const Color textGold = Color(0xFFFFD700);
  static const Color textDanger = Color(0xFFFF4444);

  // === Star thresholds (as percentage of target score) ===
  static const double oneStar = 1.0;   // Reach target = 1 star
  static const double twoStar = 1.5;   // 150% of target = 2 stars
  static const double threeStar = 2.0; // 200% of target = 3 stars
}
