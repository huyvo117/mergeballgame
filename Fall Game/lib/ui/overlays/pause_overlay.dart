import 'package:flutter/material.dart';
import '../../game/cat_catcher_game.dart';
import '../../game/config/game_config.dart';
import '../../game/managers/audio_manager.dart';

/// Pause menu overlay
class PauseOverlay extends StatelessWidget {
  final CatCatcherGame game;

  const PauseOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.6),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.12),
                Colors.white.withValues(alpha: 0.05),
              ],
            ),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '⏸️',
                style: TextStyle(fontSize: 48),
              ),
              const SizedBox(height: 8),
              const Text(
                'PAUSED',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 24),

              // Resume
              _PauseButton(
                text: '▶  RESUME',
                gradient: const [GameConfig.primaryMint, GameConfig.primaryCyan],
                onTap: () {
                  AudioManager.playClickSFX();
                  game.resumeGame();
                },
              ),
              const SizedBox(height: 12),

              // Restart
              _PauseButton(
                text: '🔄  RESTART',
                gradient: const [GameConfig.primaryYellow, Color(0xFFFF8C00)],
                onTap: () {
                  AudioManager.playClickSFX();
                  game.restartLevel();
                },
              ),
              const SizedBox(height: 12),

              // Menu
              _PauseButton(
                text: '🏠  MENU',
                gradient: [
                  Colors.white.withValues(alpha: 0.2),
                  Colors.white.withValues(alpha: 0.1),
                ],
                onTap: () {
                  AudioManager.playClickSFX();
                  game.goToMenu();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PauseButton extends StatelessWidget {
  final String text;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _PauseButton({
    required this.text,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 48,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: gradient),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: gradient[0].withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
        ),
      ),
    );
  }
}
