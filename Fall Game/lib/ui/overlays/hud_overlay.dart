// HUD Overlay for Meme Cat Catcher
import 'package:flutter/material.dart';
import '../../game/cat_catcher_game.dart';
import '../../game/config/game_config.dart';

/// In-game HUD overlay showing score, time, combo, and fever gauge
class HudOverlay extends StatelessWidget {
  final CatCatcherGame game;

  const HudOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return _HudContent(game: game);
  }
}

class _HudContent extends StatefulWidget {
  final CatCatcherGame game;

  const _HudContent({required this.game});

  @override
  State<_HudContent> createState() => _HudContentState();
}

class _HudContentState extends State<_HudContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..repeat(reverse: true);

    // Rebuild every frame to update timer/score
    _pulseController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    final combo = game.comboManager;
    final isFever = combo.isFever;
    final timeRemaining = game.remainingTime;
    final isLowTime = timeRemaining <= 10;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            // Top bar: Score + Timer + Pause
            Row(
              children: [
                // Score
                Expanded(
                  child: _GlassCard(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('⭐', style: TextStyle(fontSize: 18)),
                        const SizedBox(width: 6),
                        Text(
                          '${game.score}',
                          style: TextStyle(
                            color: isFever
                                ? GameConfig.feverNeonYellow
                                : GameConfig.textWhite,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // Timer
                _GlassCard(
                  borderColor: isLowTime ? GameConfig.textDanger : null,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.timer,
                        color: isLowTime
                            ? GameConfig.textDanger
                            : Colors.white70,
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${timeRemaining.ceil()}s',
                        style: TextStyle(
                          color: isLowTime
                              ? GameConfig.textDanger
                              : GameConfig.textWhite,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Pause button
                GestureDetector(
                  onTap: () => game.pauseGame(),
                  child: _GlassCard(
                    child: const Icon(
                      Icons.pause,
                      color: Colors.white70,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Combo + Fever bar
            if (game.gameState == GameState.playing) _buildComboBar(combo),

            // Fever indicator
            if (isFever) _buildFeverIndicator(),
          ],
        ),
      ),
    );
  }

  Widget _buildComboBar(dynamic comboManager) {
    final combo = comboManager.comboCount as int;
    final progress = comboManager.feverProgress as double;
    final isFever = comboManager.isFever as bool;

    return Row(
      children: [
        // Combo counter
        if (combo > 0)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: isFever
                    ? [GameConfig.feverNeonPink, GameConfig.feverNeonCyan]
                    : [GameConfig.primaryPink, GameConfig.primaryPurple],
              ),
              boxShadow: [
                BoxShadow(
                  color: (isFever ? GameConfig.feverNeonPink : GameConfig.primaryPink)
                      .withValues(alpha: 0.4),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Text(
              isFever ? '🔥 FEVER x$combo' : '⚡ x$combo',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),

        const SizedBox(width: 8),

        // Fever progress bar
        if (!isFever && combo > 0)
          Expanded(
            child: Container(
              height: 8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: Colors.white.withValues(alpha: 0.1),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: progress,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    gradient: const LinearGradient(
                      colors: [
                        GameConfig.primaryPink,
                        GameConfig.primaryPurple,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFeverIndicator() {
    final timer = widget.game.comboManager.feverTimer;
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Text(
                '🔥 FEVER MODE 🔥',
                style: TextStyle(
                  color: Color.lerp(
                    GameConfig.feverNeonPink,
                    GameConfig.feverNeonYellow,
                    _pulseController.value,
                  ),
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              );
            },
          ),
          const Spacer(),
          Text(
            '${timer.toStringAsFixed(1)}s',
            style: TextStyle(
              color: GameConfig.feverNeonCyan.withValues(alpha: 0.8),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Glassmorphism card widget
class _GlassCard extends StatelessWidget {
  final Widget child;
  final Color? borderColor;

  const _GlassCard({required this.child, this.borderColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withValues(alpha: 0.08),
        border: Border.all(
          color: borderColor ?? Colors.white.withValues(alpha: 0.15),
        ),
      ),
      child: child,
    );
  }
}
