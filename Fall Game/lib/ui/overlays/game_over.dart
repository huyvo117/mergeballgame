import 'package:flutter/material.dart';
import '../../game/cat_catcher_game.dart';
import '../../game/config/game_config.dart';
import '../../game/managers/audio_manager.dart';

/// Game Over overlay — shown when player fails objectives
class GameOverOverlay extends StatefulWidget {
  final CatCatcherGame game;
  const GameOverOverlay({super.key, required this.game});

  @override
  State<GameOverOverlay> createState() => _GameOverOverlayState();
}

class _GameOverOverlayState extends State<GameOverOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _shakeCtrl;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game = widget.game;

    return AnimatedBuilder(
      animation: _shakeCtrl,
      builder: (context, _) {
        return Opacity(
          opacity: _shakeCtrl.value,
          child: Container(
            color: Colors.black.withValues(alpha: 0.7),
            child: Center(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 40),
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      GameConfig.textDanger.withValues(alpha: 0.2),
                      GameConfig.bgDarkPurple.withValues(alpha: 0.95),
                    ],
                  ),
                  border: Border.all(
                    color: GameConfig.textDanger.withValues(alpha: 0.4),
                    width: 2,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('😿', style: TextStyle(fontSize: 56)),
                    const SizedBox(height: 8),
                    const Text(
                      'GAME OVER',
                      style: TextStyle(
                        color: GameConfig.textDanger,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Score: ${game.score}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Target: ${game.currentLevel.targetScore}',
                      style: TextStyle(
                        color: GameConfig.textDanger.withValues(alpha: 0.7),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Retry
                    GestureDetector(
                      onTap: () {
                        AudioManager.playClickSFX();
                        game.restartLevel();
                      },
                      child: Container(
                        width: double.infinity,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [GameConfig.primaryPink, GameConfig.primaryPurple],
                          ),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Center(
                          child: Text(
                            '🔄  TRY AGAIN',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Menu
                    GestureDetector(
                      onTap: () {
                        AudioManager.playClickSFX();
                        game.goToMenu();
                      },
                      child: Container(
                        width: double.infinity,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: const Center(
                          child: Text(
                            '🏠  MENU',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
