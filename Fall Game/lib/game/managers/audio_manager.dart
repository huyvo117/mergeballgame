// Audio Manager — Placeholder hooks for flame_audio
//
// To use with real audio files:
// 1. Add your .mp3/.ogg files to assets/audio/
// 2. Uncomment the flame_audio import and calls below
// 3. Register assets in pubspec.yaml under flutter > assets
//
// Recommended audio files:
// - bgm_normal.mp3     — Lo-fi hip-hop or chill 8-bit music
// - bgm_fever.mp3      — High-energy remix / bass-boosted version
// - sfx_catch.mp3      — Short pop/bling sound
// - sfx_combo.mp3      — Rising pitch chime
// - sfx_hazard.mp3     — Error/buzz sound
// - sfx_level_complete.mp3 — Victory fanfare
// - sfx_game_over.mp3  — Sad trombone / wah wah
// - sfx_star.mp3       — Star fill chime

// import 'package:flame_audio/flame_audio.dart';

class AudioManager {
  static bool _isMuted = false;
  // ignore: unused_field is expected — will be used when flame_audio is enabled
  static bool _isMusicPlaying = false;

  /// Toggle mute
  static void toggleMute() {
    _isMuted = !_isMuted;
    if (_isMuted) {
      stopBGM();
    }
  }

  /// Whether audio is muted
  static bool get isMuted => _isMuted;

  // ============================
  // Background Music
  // ============================

  /// Play normal background music (lo-fi / chill)
  static void playBGM() {
    if (_isMuted) return;
    // FlameAudio.bgm.play('bgm_normal.mp3', volume: 0.5);
    _isMusicPlaying = true;
    print('🎵 [AudioManager] playBGM() — Normal BGM started');
  }

  /// Switch to Fever mode music (high energy remix)
  static void playFeverBGM() {
    if (_isMuted) return;
    // FlameAudio.bgm.stop();
    // FlameAudio.bgm.play('bgm_fever.mp3', volume: 0.7);
    print('🔥 [AudioManager] playFeverBGM() — FEVER BGM started');
  }

  /// Switch back to normal BGM
  static void resumeNormalBGM() {
    if (_isMuted) return;
    // FlameAudio.bgm.stop();
    // FlameAudio.bgm.play('bgm_normal.mp3', volume: 0.5);
    print('🎵 [AudioManager] resumeNormalBGM() — Back to normal');
  }

  /// Stop all background music
  static void stopBGM() {
    // FlameAudio.bgm.stop();
    _isMusicPlaying = false;
    print('⏹️ [AudioManager] stopBGM() — Music stopped');
  }

  // ============================
  // Sound Effects
  // ============================

  /// Play catch sound effect (pop/bling)
  static void playCatchSFX() {
    if (_isMuted) return;
    // FlameAudio.play('sfx_catch.mp3', volume: 0.6);
    print('✨ [AudioManager] playCatchSFX()');
  }

  /// Play combo sound (rising pitch based on combo count)
  static void playComboSFX(int comboCount) {
    if (_isMuted) return;
    // Pitch could increase with combo:
    // final pitch = 0.8 + (comboCount * 0.1).clamp(0, 1.0);
    // FlameAudio.play('sfx_combo.mp3', volume: 0.7);
    print('🎯 [AudioManager] playComboSFX(combo: $comboCount)');
  }

  /// Play hazard hit sound (error buzz)
  static void playHazardSFX() {
    if (_isMuted) return;
    // FlameAudio.play('sfx_hazard.mp3', volume: 0.8);
    print('💥 [AudioManager] playHazardSFX()');
  }

  /// Play level complete fanfare
  static void playLevelCompleteSFX() {
    if (_isMuted) return;
    // FlameAudio.play('sfx_level_complete.mp3', volume: 0.8);
    print('🏆 [AudioManager] playLevelCompleteSFX()');
  }

  /// Play game over sound
  static void playGameOverSFX() {
    if (_isMuted) return;
    // FlameAudio.play('sfx_game_over.mp3', volume: 0.7);
    print('😿 [AudioManager] playGameOverSFX()');
  }

  /// Play star fill chime
  static void playStarSFX() {
    if (_isMuted) return;
    // FlameAudio.play('sfx_star.mp3', volume: 0.6);
    print('⭐ [AudioManager] playStarSFX()');
  }

  /// Play button click
  static void playClickSFX() {
    if (_isMuted) return;
    // FlameAudio.play('sfx_click.mp3', volume: 0.4);
    print('🔘 [AudioManager] playClickSFX()');
  }

  // ============================
  // Haptic Feedback
  // ============================

  /// Trigger light haptic on catch
  static void triggerCatchHaptic() {
    // HapticFeedback.lightImpact();
    // or use vibration package: Vibration.vibrate(duration: 30);
  }

  /// Trigger medium haptic on hazard hit
  static void triggerHazardHaptic() {
    // HapticFeedback.mediumImpact();
    // or: Vibration.vibrate(duration: 80);
  }

  /// Trigger heavy haptic on fever activation
  static void triggerFeverHaptic() {
    // HapticFeedback.heavyImpact();
    // or: Vibration.vibrate(duration: 150);
  }
}
