// Audio Manager — Web Audio API with Combo Pitch Scaling
//
// Uses dart:js_interop to access Web Audio API for real-time synthesized sounds.
// Each SFX uses OscillatorNode with precise frequency control for pitch scaling.

// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:js_interop';
import 'package:web/web.dart' as web;

/// Centralized Audio Manager with Web Audio API
/// Features:
/// - Combo Pitch Scaling (catch SFX rises in pitch with combo)
/// - Dynamic BGM (normal → fever mode transition)
/// - Match-3 explosion chime
/// - All SFX are synthesized (no asset files needed)
class AudioManager {
  static bool _isMuted = false;
  static web.AudioContext? _ctx;
  static web.OscillatorNode? _bgmOsc;
  static web.GainNode? _bgmGain;
  static bool _isFeverBGM = false;

  /// Initialize AudioContext (call once)
  static void _ensureContext() {
    _ctx ??= web.AudioContext();
  }

  /// Toggle mute
  static void toggleMute() {
    _isMuted = !_isMuted;
    if (_isMuted) {
      stopBGM();
    } else {
      playBGM();
    }
  }

  /// Whether audio is muted
  static bool get isMuted => _isMuted;

  // ============================
  // Background Music (Synthesized)
  // ============================

  /// Play normal background music (gentle arpeggio pattern)
  static void playBGM() {
    if (_isMuted) return;
    _ensureContext();
    _stopBGMInternal();

    final ctx = _ctx!;
    _bgmGain = ctx.createGain();
    _bgmGain!.gain.value = 0.08;
    _bgmGain!.connect(ctx.destination);

    _isFeverBGM = false;
    _playBGMPattern();
    print('🎵 [AudioManager] playBGM() — Normal BGM started');
  }

  /// Recursive BGM pattern — plays a looping arpeggio
  static void _playBGMPattern() {
    if (_isMuted || _bgmGain == null) return;
    final ctx = _ctx!;
    final now = ctx.currentTime;

    // Musical notes (pentatonic scale in Hz)
    final notes = _isFeverBGM
        ? [523.25, 659.25, 783.99, 880.0, 1046.5, 880.0, 783.99, 659.25] // C5 high energy
        : [261.63, 329.63, 392.0, 440.0, 523.25, 440.0, 392.0, 329.63]; // C4 chill

    final noteDuration = _isFeverBGM ? 0.12 : 0.2;

    for (int i = 0; i < notes.length; i++) {
      final osc = ctx.createOscillator();
      final gain = ctx.createGain();

      osc.type = _isFeverBGM ? 'sawtooth' : 'sine';
      osc.frequency.value = notes[i];

      gain.gain.setValueAtTime(0.0, now + i * noteDuration);
      gain.gain.linearRampToValueAtTime(
          _isFeverBGM ? 0.06 : 0.04, now + i * noteDuration + 0.02);
      gain.gain.linearRampToValueAtTime(
          0.0, now + (i + 1) * noteDuration);

      osc.connect(gain);
      gain.connect(_bgmGain!);

      osc.start(now + i * noteDuration);
      osc.stop(now + (i + 1) * noteDuration);
    }

    // Schedule next loop
    final loopDuration = (notes.length * noteDuration * 1000).toInt();
    Future.delayed(Duration(milliseconds: loopDuration), () {
      if (!_isMuted && _bgmGain != null) {
        _playBGMPattern();
      }
    });
  }

  /// Switch to Fever mode music (high energy, faster, higher pitch)
  static void playFeverBGM() {
    if (_isMuted) return;
    _isFeverBGM = true;
    print('🔥 [AudioManager] playFeverBGM() — FEVER BGM started');
  }

  /// Switch back to normal BGM
  static void resumeNormalBGM() {
    if (_isMuted) return;
    _isFeverBGM = false;
    print('🎵 [AudioManager] resumeNormalBGM() — Back to normal');
  }

  /// Stop all background music
  static void stopBGM() {
    _stopBGMInternal();
    print('⏹️ [AudioManager] stopBGM() — Music stopped');
  }

  static void _stopBGMInternal() {
    try {
      _bgmOsc?.stop(0);
    } catch (_) {}
    _bgmOsc = null;
    try {
      _bgmGain?.disconnect();
    } catch (_) {}
    _bgmGain = null;
  }

  // ============================
  // Sound Effects with Pitch Scaling
  // ============================

  /// Play catch SFX with COMBO PITCH SCALING
  /// As combo increases, pitch rises creating a musical ascending scale
  static void playCatchSFX([int comboCount = 0]) {
    if (_isMuted) return;
    _ensureContext();
    final ctx = _ctx!;

    // Base frequency: C5 (523 Hz)
    // Each combo step raises by a musical semitone (ratio 1.0595)
    // Creates: C, C#, D, D#, E, F, F#, G, G#, A, A#, B, C6...
    final semitoneRatio = 1.0595;
    final baseFreq = 523.25;
    final comboStep = comboCount.clamp(0, 24); // Max 2 octaves
    final freq = baseFreq * _pow(semitoneRatio, comboStep);

    final now = ctx.currentTime;

    // Main tone (sine — clean pop)
    final osc1 = ctx.createOscillator();
    final gain1 = ctx.createGain();
    osc1.type = 'sine';
    osc1.frequency.value = freq;
    gain1.gain.setValueAtTime(0.25, now);
    gain1.gain.exponentialRampToValueAtTime(0.001, now + 0.15);
    osc1.connect(gain1);
    gain1.connect(ctx.destination);
    osc1.start(now);
    osc1.stop(now + 0.15);

    // Harmonic overtone (triangle — sparkle)
    final osc2 = ctx.createOscillator();
    final gain2 = ctx.createGain();
    osc2.type = 'triangle';
    osc2.frequency.value = freq * 2; // Octave up
    gain2.gain.setValueAtTime(0.1, now);
    gain2.gain.exponentialRampToValueAtTime(0.001, now + 0.1);
    osc2.connect(gain2);
    gain2.connect(ctx.destination);
    osc2.start(now);
    osc2.stop(now + 0.1);
  }

  /// Play combo milestone SFX (x5, x10, x15...)
  static void playComboSFX(int comboCount) {
    if (_isMuted) return;
    _ensureContext();
    final ctx = _ctx!;
    final now = ctx.currentTime;

    // Rising arpeggio chord
    final baseFreq = 440.0 + comboCount * 20;
    for (int i = 0; i < 3; i++) {
      final osc = ctx.createOscillator();
      final gain = ctx.createGain();
      osc.type = 'sine';
      osc.frequency.value = baseFreq * (1 + i * 0.25);
      gain.gain.setValueAtTime(0.0, now + i * 0.05);
      gain.gain.linearRampToValueAtTime(0.15, now + i * 0.05 + 0.02);
      gain.gain.exponentialRampToValueAtTime(0.001, now + 0.3);
      osc.connect(gain);
      gain.connect(ctx.destination);
      osc.start(now + i * 0.05);
      osc.stop(now + 0.3);
    }
  }

  /// Play Match-3 explosion SFX — satisfying multi-note chime
  static void playMatchSFX(int matchCount) {
    if (_isMuted) return;
    _ensureContext();
    final ctx = _ctx!;
    final now = ctx.currentTime;

    // Chord burst (C major: C-E-G)
    final freqs = [523.25, 659.25, 783.99];
    if (matchCount >= 4) freqs.add(1046.5); // Add octave for 4+
    if (matchCount >= 5) freqs.add(1318.5); // Add E6 for 5+

    for (int i = 0; i < freqs.length; i++) {
      final osc = ctx.createOscillator();
      final gain = ctx.createGain();
      osc.type = 'sine';
      osc.frequency.value = freqs[i];
      gain.gain.setValueAtTime(0.2, now + i * 0.03);
      gain.gain.exponentialRampToValueAtTime(0.001, now + 0.4);
      osc.connect(gain);
      gain.connect(ctx.destination);
      osc.start(now + i * 0.03);
      osc.stop(now + 0.4);
    }

    // Impact sub-bass for satisfaction
    final sub = ctx.createOscillator();
    final subGain = ctx.createGain();
    sub.type = 'sine';
    sub.frequency.value = 80;
    subGain.gain.setValueAtTime(0.3, now);
    subGain.gain.exponentialRampToValueAtTime(0.001, now + 0.2);
    sub.connect(subGain);
    subGain.connect(ctx.destination);
    sub.start(now);
    sub.stop(now + 0.2);

    print('💥 [AudioManager] playMatchSFX(count: $matchCount)');
  }

  /// Play hazard hit sound (error buzz)
  static void playHazardSFX() {
    if (_isMuted) return;
    _ensureContext();
    final ctx = _ctx!;
    final now = ctx.currentTime;

    // Buzzer — low frequency sawtooth
    final osc = ctx.createOscillator();
    final gain = ctx.createGain();
    osc.type = 'sawtooth';
    osc.frequency.setValueAtTime(150, now);
    osc.frequency.linearRampToValueAtTime(80, now + 0.2);
    gain.gain.setValueAtTime(0.2, now);
    gain.gain.exponentialRampToValueAtTime(0.001, now + 0.25);
    osc.connect(gain);
    gain.connect(ctx.destination);
    osc.start(now);
    osc.stop(now + 0.25);
  }

  /// Play level complete fanfare
  static void playLevelCompleteSFX() {
    if (_isMuted) return;
    _ensureContext();
    final ctx = _ctx!;
    final now = ctx.currentTime;

    // Victory fanfare: C-E-G-C ascending
    final notes = [523.25, 659.25, 783.99, 1046.5];
    for (int i = 0; i < notes.length; i++) {
      final osc = ctx.createOscillator();
      final gain = ctx.createGain();
      osc.type = 'sine';
      osc.frequency.value = notes[i];
      gain.gain.setValueAtTime(0.0, now + i * 0.15);
      gain.gain.linearRampToValueAtTime(0.2, now + i * 0.15 + 0.03);
      gain.gain.exponentialRampToValueAtTime(0.001, now + i * 0.15 + 0.4);
      osc.connect(gain);
      gain.connect(ctx.destination);
      osc.start(now + i * 0.15);
      osc.stop(now + i * 0.15 + 0.4);
    }
    print('🏆 [AudioManager] playLevelCompleteSFX()');
  }

  /// Play game over sound (descending sad tone)
  static void playGameOverSFX() {
    if (_isMuted) return;
    _ensureContext();
    final ctx = _ctx!;
    final now = ctx.currentTime;

    // Sad descending: G-E-C
    final notes = [392.0, 329.63, 261.63];
    for (int i = 0; i < notes.length; i++) {
      final osc = ctx.createOscillator();
      final gain = ctx.createGain();
      osc.type = 'sine';
      osc.frequency.value = notes[i];
      gain.gain.setValueAtTime(0.0, now + i * 0.25);
      gain.gain.linearRampToValueAtTime(0.15, now + i * 0.25 + 0.05);
      gain.gain.exponentialRampToValueAtTime(0.001, now + i * 0.25 + 0.5);
      osc.connect(gain);
      gain.connect(ctx.destination);
      osc.start(now + i * 0.25);
      osc.stop(now + i * 0.25 + 0.5);
    }
    print('😿 [AudioManager] playGameOverSFX()');
  }

  /// Play star fill chime
  static void playStarSFX() {
    if (_isMuted) return;
    _ensureContext();
    final ctx = _ctx!;
    final now = ctx.currentTime;

    // Sparkly high chime
    final osc = ctx.createOscillator();
    final gain = ctx.createGain();
    osc.type = 'sine';
    osc.frequency.value = 1200;
    gain.gain.setValueAtTime(0.2, now);
    gain.gain.exponentialRampToValueAtTime(0.001, now + 0.3);
    osc.connect(gain);
    gain.connect(ctx.destination);
    osc.start(now);
    osc.stop(now + 0.3);

    // Shimmer overtone
    final osc2 = ctx.createOscillator();
    final gain2 = ctx.createGain();
    osc2.type = 'triangle';
    osc2.frequency.value = 1800;
    gain2.gain.setValueAtTime(0.08, now + 0.05);
    gain2.gain.exponentialRampToValueAtTime(0.001, now + 0.25);
    osc2.connect(gain2);
    gain2.connect(ctx.destination);
    osc2.start(now + 0.05);
    osc2.stop(now + 0.25);

    print('⭐ [AudioManager] playStarSFX()');
  }

  /// Play button click (soft pop)
  static void playClickSFX() {
    if (_isMuted) return;
    _ensureContext();
    final ctx = _ctx!;
    final now = ctx.currentTime;

    final osc = ctx.createOscillator();
    final gain = ctx.createGain();
    osc.type = 'sine';
    osc.frequency.value = 800;
    gain.gain.setValueAtTime(0.12, now);
    gain.gain.exponentialRampToValueAtTime(0.001, now + 0.08);
    osc.connect(gain);
    gain.connect(ctx.destination);
    osc.start(now);
    osc.stop(now + 0.08);
  }

  // ============================
  // Haptic Feedback
  // ============================

  static void triggerCatchHaptic() {
    // Web doesn't support haptic — no-op
  }

  static void triggerHazardHaptic() {
    // Web doesn't support haptic — no-op
  }

  static void triggerFeverHaptic() {
    // Web doesn't support haptic — no-op
  }

  // ============================
  // Utility
  // ============================

  /// Power function for pitch calculation
  static double _pow(double base, int exponent) {
    double result = 1.0;
    for (int i = 0; i < exponent; i++) {
      result *= base;
    }
    return result;
  }
}
