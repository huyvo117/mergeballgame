import 'package:shared_preferences/shared_preferences.dart';

/// Singleton manager for all persistent player data.
/// Handles diamonds, unlocked characters, equipped skin, level stars, and unlocked levels.
class PlayerData {
  // --- Singleton ---
  static final PlayerData _instance = PlayerData._();
  static PlayerData get instance => _instance;
  PlayerData._();

  // --- State ---
  int _diamonds = 0;
  final Set<String> _unlockedCharacters = {'maxwell'}; // Default cat free
  String _equippedCharacter = 'maxwell';
  final Map<int, int> _levelStars = {};
  final Set<int> _unlockedLevels = {1, 2};

  bool _isLoaded = false;

  // --- Getters ---
  int get diamonds => _diamonds;
  Set<String> get unlockedCharacters => Set.unmodifiable(_unlockedCharacters);
  String get equippedCharacter => _equippedCharacter;
  Map<int, int> get levelStars => Map.unmodifiable(_levelStars);
  Set<int> get unlockedLevels => Set.unmodifiable(_unlockedLevels);
  bool get isLoaded => _isLoaded;

  // --- Diamond Rewards ---
  /// Calculate diamonds earned based on star count
  static int diamondRewardForStars(int stars) {
    switch (stars) {
      case 1:
        return 10;
      case 2:
        return 20;
      case 3:
        return 35;
      default:
        return 3; // Consolation reward (score > 0 but 0 stars)
    }
  }

  // --- Mutations ---

  /// Add diamonds
  void addDiamonds(int amount) {
    _diamonds += amount;
    save();
  }

  /// Attempt to purchase a character. Returns true if successful.
  bool purchaseCharacter(String charId, int price) {
    if (_diamonds < price) return false;
    if (_unlockedCharacters.contains(charId)) return false;

    _diamonds -= price;
    _unlockedCharacters.add(charId);
    _equippedCharacter = charId; // Auto-equip on purchase
    save();
    return true;
  }

  /// Check if a character is unlocked
  bool isCharacterUnlocked(String charId) {
    return _unlockedCharacters.contains(charId);
  }

  /// Equip a character (must be unlocked)
  void equipCharacter(String charId) {
    if (_unlockedCharacters.contains(charId)) {
      _equippedCharacter = charId;
      save();
    }
  }

  /// Update level progress (stars and unlock next)
  void updateLevelProgress(int levelId, int stars, int totalLevels) {
    // Save best stars
    final prevStars = _levelStars[levelId] ?? 0;
    if (stars > prevStars) {
      _levelStars[levelId] = stars;
    }

    // Unlock next level
    if (levelId < totalLevels) {
      _unlockedLevels.add(levelId + 1);
    }

    save();
  }

  /// Get best stars for a level
  int getStarsForLevel(int levelId) => _levelStars[levelId] ?? 0;

  // --- Persistence ---

  /// Load all data from SharedPreferences
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    _diamonds = prefs.getInt('diamonds') ?? 0;
    _equippedCharacter = prefs.getString('equipped_character') ?? 'maxwell';

    // Unlocked characters
    final unlockedList = prefs.getStringList('unlocked_characters') ?? ['maxwell'];
    _unlockedCharacters.clear();
    _unlockedCharacters.addAll(unlockedList);

    // Level stars
    _levelStars.clear();
    final starKeys = prefs.getStringList('star_keys') ?? [];
    for (final key in starKeys) {
      final levelId = int.tryParse(key);
      if (levelId != null) {
        _levelStars[levelId] = prefs.getInt('stars_$key') ?? 0;
      }
    }

    // Unlocked levels
    final unlockedLevelsList = prefs.getStringList('unlocked_levels') ?? ['1', '2'];
    _unlockedLevels.clear();
    for (final l in unlockedLevelsList) {
      final id = int.tryParse(l);
      if (id != null) _unlockedLevels.add(id);
    }

    _isLoaded = true;
  }

  /// Save all data to SharedPreferences
  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setInt('diamonds', _diamonds);
    await prefs.setString('equipped_character', _equippedCharacter);
    await prefs.setStringList(
      'unlocked_characters',
      _unlockedCharacters.toList(),
    );

    // Level stars
    final starKeys = _levelStars.keys.map((k) => k.toString()).toList();
    await prefs.setStringList('star_keys', starKeys);
    for (final entry in _levelStars.entries) {
      await prefs.setInt('stars_${entry.key}', entry.value);
    }

    // Unlocked levels
    await prefs.setStringList(
      'unlocked_levels',
      _unlockedLevels.map((l) => l.toString()).toList(),
    );
  }
}
