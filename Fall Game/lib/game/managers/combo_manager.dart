import '../config/game_config.dart';

/// Manages the combo counter and Fever Mode
class ComboManager {
  int _comboCount = 0;
  bool _isFever = false;
  double _feverTimer = 0;
  int _totalCatches = 0;
  int _maxCombo = 0;

  // Callbacks
  void Function(int combo)? onComboChanged;
  void Function(bool isFever)? onFeverChanged;

  /// Current combo count
  int get comboCount => _comboCount;

  /// Whether Fever mode is active
  bool get isFever => _isFever;

  /// Remaining fever time
  double get feverTimer => _feverTimer;

  /// Fever progress (0.0 - 1.0) towards activation
  double get feverProgress =>
      _comboCount < GameConfig.feverComboThreshold
          ? _comboCount / GameConfig.feverComboThreshold
          : 1.0;

  /// Total catches in this session
  int get totalCatches => _totalCatches;

  /// Maximum combo achieved
  int get maxCombo => _maxCombo;

  /// Register a successful catch
  void onCatch() {
    _comboCount++;
    _totalCatches++;

    if (_comboCount > _maxCombo) {
      _maxCombo = _comboCount;
    }

    onComboChanged?.call(_comboCount);

    // Check fever activation
    if (!_isFever && _comboCount >= GameConfig.feverComboThreshold) {
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
    onFeverChanged?.call(true);
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
  }
}
