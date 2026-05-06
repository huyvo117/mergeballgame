import '../config/game_config.dart';
import '../config/item_types.dart';

/// Manages the combo counter, Energy Bar, Fever Mode, and per-item catch tracking
class ComboManager {
  int _comboCount = 0;
  bool _isFever = false;
  double _feverTimer = 0;
  int _totalCatches = 0;
  int _maxCombo = 0;

  // Energy Bar (0.0 – 1.0)
  double _energy = 0;

  // Per-item catch counts (for detailed result screen)
  final Map<ItemType, int> _itemCatchCounts = {};

  // Callbacks
  void Function(int combo)? onComboChanged;
  void Function(bool isFever)? onFeverChanged;
  void Function()? onFeverActivated; // One-shot callback for popup

  /// Current combo count
  int get comboCount => _comboCount;

  /// Whether Fever mode is active
  bool get isFever => _isFever;

  /// Remaining fever time
  double get feverTimer => _feverTimer;

  /// Energy progress (0.0 – 1.0) — fills by catching Energy Items
  double get energy => _energy;

  /// Fever progress for HUD bar (combo-based fallback OR energy-based)
  double get feverProgress => _energy;

  /// Total catches in this session
  int get totalCatches => _totalCatches;

  /// Maximum combo achieved
  int get maxCombo => _maxCombo;

  /// Per-item catch counts for result screen
  Map<ItemType, int> get itemCatchCounts => Map.unmodifiable(_itemCatchCounts);

  /// Register a successful catch
  void onCatch({ItemType? itemType}) {
    _comboCount++;
    _totalCatches++;

    if (_comboCount > _maxCombo) {
      _maxCombo = _comboCount;
    }

    // Track per-item counts
    if (itemType != null) {
      _itemCatchCounts[itemType] = (_itemCatchCounts[itemType] ?? 0) + 1;
    }

    // Energy items fill the energy bar
    if (itemType != null && itemType.isEnergyItem) {
      _energy = (_energy + itemType.energyPercent / 100.0).clamp(0.0, 1.0);
    }

    onComboChanged?.call(_comboCount);

    // Check fever activation via Energy Bar (100%)
    if (!_isFever && _energy >= 1.0) {
      _activateFever();
    }

    // Extend fever if already active
    if (_isFever) {
      _feverTimer = (_feverTimer + GameConfig.feverExtension)
          .clamp(0, GameConfig.feverMaxDuration);
    }
  }

  /// Register a miss or hazard hit — breaks combo
  void onMiss() {
    _comboCount = 0;
    onComboChanged?.call(0);

    if (_isFever) {
      _deactivateFever();
    }
  }

  /// Calculate score for an item catch
  int calculateScore(int basePoints) {
    int score = basePoints;

    // Combo bonus
    score += _comboCount * GameConfig.comboBonusPerLevel;

    // Fever multiplier
    if (_isFever) {
      score *= GameConfig.feverMultiplier;
    }

    return score;
  }

  /// Update fever timer
  void update(double dt) {
    if (_isFever) {
      _feverTimer -= dt;
      if (_feverTimer <= 0) {
        _deactivateFever();
      }
    }
  }

  void _activateFever() {
    _isFever = true;
    _feverTimer = GameConfig.feverDuration;
    _energy = 0; // Reset energy bar after triggering fever
    onFeverChanged?.call(true);
    onFeverActivated?.call(); // Trigger popup
  }

  void _deactivateFever() {
    _isFever = false;
    _feverTimer = 0;
    onFeverChanged?.call(false);
  }

  /// Reset all combo state
  void reset() {
    _comboCount = 0;
    _isFever = false;
    _feverTimer = 0;
    _totalCatches = 0;
    _maxCombo = 0;
    _energy = 0;
    _itemCatchCounts.clear();
  }
}
