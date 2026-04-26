import 'package:flutter/material.dart';
import '../game/merge_ball_game.dart';
import '../game/config/game_config.dart';

/// Score and next ball display overlay with glassmorphism
class ScoreOverlay extends StatelessWidget {
  final MergeBallGame game;

  const ScoreOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Score display
            _GlassCard(
              child: _ScoreDisplay(game: game),
            ),
            const Spacer(),
            // Next ball indicator
            _GlassCard(
              child: _NextBallDisplay(game: game),
            ),
          ],
        ),
      ),
    );
  }
}

/// Glass-morphism card wrapper
class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withAlpha(15),
            Colors.white.withAlpha(5),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withAlpha(20),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(100),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: const Color(0xFF6366F1).withAlpha(15),
            blurRadius: 30,
            spreadRadius: -5,
          ),
        ],
      ),
      child: child,
    );
  }
}

class _ScoreDisplay extends StatefulWidget {
  final MergeBallGame game;
  const _ScoreDisplay({required this.game});

  @override
  State<_ScoreDisplay> createState() => _ScoreDisplayState();
}

class _ScoreDisplayState extends State<_ScoreDisplay> {
  int _lastScore = -1;

  @override
  void initState() {
    super.initState();
    _poll();
  }

  void _poll() {
    if (!mounted) return;
    if (widget.game.score != _lastScore) {
      _lastScore = widget.game.score;
      setState(() {});
    }
    Future.delayed(const Duration(milliseconds: 80), _poll);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFF818CF8), Color(0xFFA78BFA)],
          ).createShader(bounds),
          child: const Text(
            'SCORE',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 3,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '${widget.game.score}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 30,
            fontWeight: FontWeight.w800,
            height: 1.1,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }
}

class _NextBallDisplay extends StatefulWidget {
  final MergeBallGame game;
  const _NextBallDisplay({required this.game});

  @override
  State<_NextBallDisplay> createState() => _NextBallDisplayState();
}

class _NextBallDisplayState extends State<_NextBallDisplay> {
  int _lastLevel = -1;

  @override
  void initState() {
    super.initState();
    _poll();
  }

  void _poll() {
    if (!mounted) return;
    if (widget.game.nextBallLevel != _lastLevel) {
      _lastLevel = widget.game.nextBallLevel;
      setState(() {});
    }
    Future.delayed(const Duration(milliseconds: 80), _poll);
  }

  @override
  Widget build(BuildContext context) {
    final ballData = BallConfig.getLevel(widget.game.nextBallLevel);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFF818CF8), Color(0xFFA78BFA)],
          ).createShader(bounds),
          child: const Text(
            'NEXT',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 3,
            ),
          ),
        ),
        const SizedBox(height: 6),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Container(
            key: ValueKey(widget.game.nextBallLevel),
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                center: const Alignment(-0.3, -0.3),
                radius: 1.0,
                colors: [
                  _brighten(ballData.color, 0.2),
                  ballData.color,
                  ballData.gradientColor,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
              boxShadow: [
                BoxShadow(
                  color: ballData.color.withAlpha(80),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ],
              border: Border.all(
                color: ballData.gradientColor.withAlpha(80),
                width: 1.5,
              ),
            ),
            child: Center(
              child: Text(
                ballData.emoji,
                style: const TextStyle(fontSize: 22),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color _brighten(Color color, double factor) {
    final ri = (color.r * 255).round();
    final gi = (color.g * 255).round();
    final bi = (color.b * 255).round();
    final ai = (color.a * 255).round();
    final r = (ri + (255 - ri) * factor).round().clamp(0, 255);
    final g = (gi + (255 - gi) * factor).round().clamp(0, 255);
    final b = (bi + (255 - bi) * factor).round().clamp(0, 255);
    return Color.fromARGB(ai, r, g, b);
  }
}
