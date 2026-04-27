// Level Complete Overlay
import 'package:flutter/material.dart';
import '../../game/cat_catcher_game.dart';
import '../../game/config/game_config.dart';
import '../../game/config/level_config.dart';
import '../../game/managers/audio_manager.dart';

/// Level complete overlay with animated star rating
class LevelCompleteOverlay extends StatefulWidget {
  final CatCatcherGame game;
  const LevelCompleteOverlay({super.key, required this.game});

  @override
  State<LevelCompleteOverlay> createState() => _LevelCompleteOverlayState();
}

class _LevelCompleteOverlayState extends State<LevelCompleteOverlay>
    with TickerProviderStateMixin {
  late AnimationController _enterCtrl;
  late AnimationController _confettiCtrl;
  int _starsShown = 0;

  @override
  void initState() {
    super.initState();
    final stars = widget.game.currentLevel.calculateStars(widget.game.score);

    _enterCtrl = AnimationController(
      duration: const Duration(milliseconds: 600), vsync: this,
    )..forward();

    _confettiCtrl = AnimationController(
      duration: const Duration(milliseconds: 3000), vsync: this,
    )..repeat();

    _enterCtrl.addStatusListener((s) {
      if (s == AnimationStatus.completed) _animateStars(stars);
    });
  }

  Future<void> _animateStars(int total) async {
    for (int i = 0; i < total; i++) {
      await Future.delayed(const Duration(milliseconds: 400));
      if (mounted) {
        setState(() => _starsShown = i + 1);
        AudioManager.playStarSFX();
      }
    }
  }

  @override
  void dispose() {
    _enterCtrl.dispose();
    _confettiCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    final isLast = game.currentLevelId >= LevelDatabase.totalLevels;

    return AnimatedBuilder(
      animation: _enterCtrl,
      builder: (context, _) {
        return Opacity(
          opacity: _enterCtrl.value,
          child: Container(
            color: Colors.black54,
            child: Center(child: _card(game, isLast)),
          ),
        );
      },
    );
  }

  Widget _card(CatCatcherGame game, bool isLast) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [
            GameConfig.primaryPurple.withValues(alpha: 0.3),
            GameConfig.bgDarkPurple.withValues(alpha: 0.95),
          ],
        ),
        border: Border.all(color: GameConfig.primaryPurple.withValues(alpha: 0.4), width: 2),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('🎉 CHALLENGE', style: TextStyle(color: GameConfig.textGold, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 3)),
        const Text('COMPLETE!', style: TextStyle(color: GameConfig.textGold, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 4)),
        const SizedBox(height: 20),
        // Stars
        Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(3, (i) {
          final filled = i < _starsShown;
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: filled ? 1.0 : 0),
            duration: const Duration(milliseconds: 400),
            curve: Curves.elasticOut,
            builder: (_, v, __) => Transform.scale(
              scale: filled ? v : 0.6,
              child: Icon(filled ? Icons.star : Icons.star_border,
                color: filled ? GameConfig.textGold : Colors.white24, size: 48),
            ),
          );
        })),
        const SizedBox(height: 16),
        _row('Score', '${game.score}'),
        _row('Max Combo', 'x${game.comboManager.maxCombo}'),
        _row('Items Caught', '${game.comboManager.totalCatches}'),
        const SizedBox(height: 20),
        if (!isLast) _btn('▶  NEXT LEVEL', [GameConfig.primaryMint, GameConfig.primaryCyan], () { AudioManager.playClickSFX(); game.nextLevel(); }),
        if (!isLast) const SizedBox(height: 10),
        _btn('🔄  RETRY', [GameConfig.primaryYellow, const Color(0xFFFF8C00)], () { AudioManager.playClickSFX(); game.restartLevel(); }),
        const SizedBox(height: 10),
        _btn('🏠  MENU', [Colors.white24, Colors.white12], () { AudioManager.playClickSFX(); game.goToMenu(); }),
      ]),
    );
  }

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(color: Colors.white60, fontSize: 14)),
      Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
    ]),
  );

  Widget _btn(String text, List<Color> colors, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: double.infinity, height: 46,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        borderRadius: BorderRadius.circular(23),
      ),
      child: Center(child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700))),
    ),
  );
}
