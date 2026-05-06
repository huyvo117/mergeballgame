// HUD Overlay for Meme Cat Catcher
import 'package:flutter/material.dart';
import '../../game/cat_catcher_game.dart';
import '../../game/config/game_config.dart';

/// In-game HUD overlay showing score, time, combo, energy bar, skill popup, and fever popup
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
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _skillPopupController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..repeat(reverse: true);

    // Skill popup slide-in at level start
    _skillPopupController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // Auto-show skill popup then hide after 3s
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _skillPopupController.forward();
    });
    Future.delayed(const Duration(milliseconds: 3300), () {
      if (mounted) _skillPopupController.reverse();
    });

    // Rebuild every frame to update timer/score
    _pulseController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _skillPopupController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    final combo = game.comboManager;
    final isFever = combo.isFever;
    final timeRemaining = game.remainingTime;
    final isLowTime = timeRemaining <= 10;

    return Stack(
      children: [
        // Main HUD
        SafeArea(
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

                // Combo + Energy bar
                if (game.gameState == GameState.playing) _buildEnergyBar(combo),

                // Stack indicator (only in Stack Match-3 mode)
                if (game.gameState == GameState.playing && game.currentLevel.useStack)
                  _buildStackIndicator(),

                // Fever indicator
                if (isFever) _buildFeverIndicator(),

                // Slow debuff indicator
                if (game.player.isSlowed) _buildSlowIndicator(),
              ],
            ),
          ),
        ),

        // === Skill Popup (slide in from right at level start) ===
        if (game.selectedSkin.skill != null)
          _buildSkillPopup(),

        // === Massive Fever Popup (center screen) ===
        if (game.showFeverPopup)
          _buildFeverMassivePopup(),
      ],
    );
  }

  Widget _buildEnergyBar(dynamic comboManager) {
    final combo = comboManager.comboCount as int;
    final energy = comboManager.energy as double;
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

        // Energy Bar (replaces old fever progress bar)
        if (!isFever)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '⚡ Energy',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${(energy * 100).toInt()}%',
                      style: TextStyle(
                        color: energy >= 0.8
                            ? GameConfig.feverNeonYellow
                            : Colors.white.withValues(alpha: 0.5),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Container(
                  height: 10,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: energy,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        gradient: LinearGradient(
                          colors: energy >= 0.8
                              ? [GameConfig.feverNeonPink, GameConfig.feverNeonYellow]
                              : [const Color(0xFF4ADE80), const Color(0xFF22D3EE)],
                        ),
                        boxShadow: energy >= 0.8
                            ? [BoxShadow(
                                color: GameConfig.feverNeonPink.withValues(alpha: 0.5),
                                blurRadius: 6,
                              )]
                            : null,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildStackIndicator() {
    final game = widget.game;
    final stack = game.itemStack;
    final maxSlots = GameConfig.maxStackSize;
    final fillRatio = stack.length / maxSlots;

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: fillRatio >= 0.85
              ? const Color(0x33FF4444)
              : Colors.white.withValues(alpha: 0.06),
          border: Border.all(
            color: fillRatio >= 0.85
                ? const Color(0x88FF4444)
                : Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          children: [
            // Label
            Text(
              '🍽️',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(width: 4),
            Text(
              '${stack.length}/$maxSlots',
              style: TextStyle(
                color: fillRatio >= 0.85
                    ? GameConfig.textDanger
                    : Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 6),
            // Stack slots
            Expanded(
              child: Row(
                children: List.generate(maxSlots, (i) {
                  final hasItem = i < stack.length;
                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      height: 22,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: hasItem
                            ? (i >= maxSlots - 1
                                ? const Color(0x66FF4444)
                                : i >= maxSlots - 2
                                    ? const Color(0x44FFAA00)
                                    : Colors.white.withValues(alpha: 0.15))
                            : Colors.white.withValues(alpha: 0.05),
                        border: Border.all(
                          color: hasItem
                              ? Colors.white.withValues(alpha: 0.2)
                              : Colors.white.withValues(alpha: 0.08),
                          width: 0.5,
                        ),
                      ),
                      child: Center(
                        child: hasItem
                            ? Text(
                                stack[i].emoji,
                                style: const TextStyle(fontSize: 12),
                              )
                            : null,
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(width: 6),
            // Match-3 label
            Text(
              'MATCH 3!',
              style: TextStyle(
                color: GameConfig.primaryPink.withValues(alpha: 0.6),
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
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

  Widget _buildSlowIndicator() {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: const Color(0xFF9333EA).withValues(alpha: 0.3),
          border: Border.all(color: const Color(0xFF9333EA).withValues(alpha: 0.5)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🐌', style: TextStyle(fontSize: 14)),
            SizedBox(width: 4),
            Text(
              'SLOWED',
              style: TextStyle(
                color: Color(0xFFD8B4FE),
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Skill popup that slides in from right at level start
  Widget _buildSkillPopup() {
    final skin = widget.game.selectedSkin;
    return Positioned(
      top: 110,
      right: 0,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1.2, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _skillPopupController,
          curve: Curves.easeOutCubic,
        )),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              bottomLeft: Radius.circular(16),
            ),
            gradient: LinearGradient(
              colors: [
                skin.tierColor.withValues(alpha: 0.3),
                skin.tierColor.withValues(alpha: 0.1),
              ],
            ),
            border: Border.all(color: skin.tierColor.withValues(alpha: 0.5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(skin.emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    skin.name,
                    style: TextStyle(
                      color: skin.tierColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    skin.skillDesc,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Massive centered popup when Fever Mode activates
  Widget _buildFeverMassivePopup() {
    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 500),
        curve: Curves.elasticOut,
        builder: (_, v, child) => Transform.scale(
          scale: v,
          child: child,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              colors: [
                GameConfig.feverNeonPink,
                GameConfig.feverNeonCyan,
                GameConfig.feverNeonYellow,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: GameConfig.feverNeonPink.withValues(alpha: 0.6),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '🌈 MUNCHIE MADNESS! 🌈',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  shadows: [
                    Shadow(color: Colors.black54, blurRadius: 8),
                  ],
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Rainbow Jelly Hour!',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
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
