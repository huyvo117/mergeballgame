import 'dart:math';
import 'package:flutter/material.dart';
import '../../game/config/game_config.dart';
import '../../game/config/item_types.dart';
import '../../game/managers/audio_manager.dart';
import '../../game/managers/player_data.dart';

/// Main Menu Screen with animated Meme Cat and neon pastel design
class MenuScreen extends StatefulWidget {
  final VoidCallback onPlay;
  final VoidCallback onLevelSelect;
  final VoidCallback onShop;
  final CatSkin currentSkin;

  const MenuScreen({
    super.key,
    required this.onPlay,
    required this.onLevelSelect,
    required this.onShop,
    required this.currentSkin,
  });

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> with TickerProviderStateMixin {
  late AnimationController _catBounceController;
  late AnimationController _titleController;
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();

    _catBounceController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);

    _titleController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();

    _glowController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _catBounceController.dispose();
    _titleController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            GameConfig.bgMidPurple,
            GameConfig.bgDarkPurple,
            GameConfig.bgDeepBlue,
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Diamond counter at top
            _buildDiamondHeader(),

            const Spacer(flex: 1),

            // === Animated Title ===
            _buildTitle(),

            const SizedBox(height: 20),

            // === Bouncing Cat ===
            _buildBouncingCat(),

            const SizedBox(height: 10),

            // Cat name
            Text(
              widget.currentSkin.name,
              style: TextStyle(
                color: widget.currentSkin.color,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              ),
            ),

            const Spacer(flex: 1),

            // === Buttons ===
            _buildMenuButtons(),

            const Spacer(flex: 1),

            // Footer
            Text(
              '🐱 Meme Cat Catcher v1.0',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.3),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return AnimatedBuilder(
      animation: _titleController,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: const [
                GameConfig.primaryPink,
                GameConfig.primaryPurple,
                GameConfig.primaryCyan,
                GameConfig.primaryYellow,
                GameConfig.primaryPink,
              ],
              stops: [
                0,
                0.25 + _titleController.value * 0.1,
                0.5,
                0.75 - _titleController.value * 0.1,
                1,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(bounds);
          },
          child: const Column(
            children: [
              Text(
                'MEME CAT',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4,
                  height: 1,
                ),
              ),
              Text(
                'CATCHER',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w300,
                  letterSpacing: 12,
                  height: 1.2,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBouncingCat() {
    return AnimatedBuilder(
      animation: _catBounceController,
      builder: (context, child) {
        final bounce = sin(_catBounceController.value * pi) * 15;
        final rotate = sin(_catBounceController.value * pi * 2) * 0.05;

        return Transform.translate(
          offset: Offset(0, -bounce),
          child: Transform.rotate(
            angle: rotate,
            child: AnimatedBuilder(
              animation: _glowController,
              builder: (context, child) {
                return Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        widget.currentSkin.color.withValues(alpha: 0.3),
                        widget.currentSkin.color.withValues(alpha: 0.0),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: widget.currentSkin.color.withValues(
                          alpha: 0.2 + _glowController.value * 0.2,
                        ),
                        blurRadius: 30 + _glowController.value * 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      widget.currentSkin.emoji,
                      style: const TextStyle(fontSize: 72),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildDiamondHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF6366F1).withValues(alpha: 0.3),
                  const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                ],
              ),
              border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('💎', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Text(
                  '${PlayerData.instance.diamonds}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          // PLAY Button
          _MenuButton(
            text: '▶  PLAY',
            gradient: const [GameConfig.primaryPink, GameConfig.primaryPurple],
            onTap: () {
              AudioManager.playClickSFX();
              widget.onPlay();
            },
          ),
          const SizedBox(height: 12),

          // LEVELS Button
          _MenuButton(
            text: '🗺️  LEVELS',
            gradient: const [GameConfig.primaryCyan, GameConfig.primaryMint],
            onTap: () {
              AudioManager.playClickSFX();
              widget.onLevelSelect();
            },
          ),
          const SizedBox(height: 12),

          // SHOP Button
          _MenuButton(
            text: '🛍️  SHOP',
            gradient: const [GameConfig.primaryYellow, Color(0xFFFF8C00)],
            onTap: () {
              AudioManager.playClickSFX();
              widget.onShop();
            },
          ),
        ],
      ),
    );
  }
}

/// Reusable gradient button for menu
class _MenuButton extends StatefulWidget {
  final String text;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _MenuButton({
    required this.text,
    required this.gradient,
    required this.onTap,
  });

  @override
  State<_MenuButton> createState() => _MenuButtonState();
}

class _MenuButtonState extends State<_MenuButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: double.infinity,
        height: 52,
        transform: Matrix4.diagonal3Values(_isPressed ? 0.95 : 1.0, _isPressed ? 0.95 : 1.0, 1.0),
        transformAlignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: widget.gradient,
          ),
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: widget.gradient[0].withValues(alpha: _isPressed ? 0.2 : 0.4),
              blurRadius: _isPressed ? 8 : 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Text(
            widget.text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
          ),
        ),
      ),
    );
  }
}
