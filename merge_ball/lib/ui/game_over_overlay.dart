import 'package:flutter/material.dart';
import '../game/merge_ball_game.dart';

/// Game Over overlay with score, high score, and restart button
class GameOverOverlay extends StatefulWidget {
  final MergeBallGame game;

  const GameOverOverlay({super.key, required this.game});

  @override
  State<GameOverOverlay> createState() => _GameOverOverlayState();
}

class _GameOverOverlayState extends State<GameOverOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticOut,
      ),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        color: Colors.black.withAlpha(180),
        child: Center(
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              width: 300,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF2D1B4E),
                    Color(0xFF1A1B2E),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withAlpha(25),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6C3CE0).withAlpha(60),
                    blurRadius: 40,
                    spreadRadius: 5,
                  ),
                  BoxShadow(
                    color: Colors.black.withAlpha(120),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Game Over text
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [
                        Color(0xFFFF6B6B),
                        Color(0xFFFF8E53),
                      ],
                    ).createShader(bounds),
                    child: const Text(
                      'GAME OVER',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Score
                  Text(
                    'SCORE',
                    style: TextStyle(
                      color: Colors.white.withAlpha(150),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${widget.game.score}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // High score
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD700).withAlpha(30),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFFFD700).withAlpha(60),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          '👑',
                          style: TextStyle(fontSize: 18),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'BEST: ${widget.game.highScore}',
                          style: const TextStyle(
                            color: Color(0xFFFFD700),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Restart button
                  GestureDetector(
                    onTap: () {
                      widget.game.resetGame();
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF6C3CE0),
                            Color(0xFF8B5CF6),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFF6C3CE0).withAlpha(120),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          '🔄 PLAY AGAIN',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
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
      ),
    );
  }
}
