import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';
import '../config/game_config.dart';

/// Manages all particle effects in the game
class ParticleFx {
  static final _random = Random();

  /// Spawn sparkle particles when catching an item
  static ParticleSystemComponent catchSparkle({
    required Vector2 position,
    required Color color,
  }) {
    return ParticleSystemComponent(
      position: position,
      particle: Particle.generate(
        count: 12,
        lifespan: 0.6,
        generator: (i) {
          final angle = (i / 12) * 2 * pi + _random.nextDouble() * 0.5;
          final speed = 80 + _random.nextDouble() * 120;
          final velocity = Vector2(cos(angle), sin(angle)) * speed;
          final size = 3.0 + _random.nextDouble() * 4;

          return AcceleratedParticle(
            speed: velocity,
            acceleration: Vector2(0, 200), // gravity
            child: ComputedParticle(
              renderer: (canvas, particle) {
                final alpha = (1.0 - particle.progress).clamp(0.0, 1.0);
                final paint = Paint()
                  ..color = color.withValues(alpha: alpha)
                  ..style = PaintingStyle.fill;

                // Star shape sparkle
                final currentSize = size * (1.0 - particle.progress * 0.5);
                canvas.drawCircle(Offset.zero, currentSize, paint);

                // White center
                canvas.drawCircle(
                  Offset.zero,
                  currentSize * 0.4,
                  Paint()..color = Colors.white.withValues(alpha: alpha * 0.8),
                );
              },
            ),
          );
        },
      ),
    );
  }

  /// Spawn combo number popup
  static ParticleSystemComponent comboPopup({
    required Vector2 position,
    required int comboCount,
  }) {
    return ParticleSystemComponent(
      position: position,
      particle: Particle.generate(
        count: 1,
        lifespan: 0.8,
        generator: (i) {
          return AcceleratedParticle(
            speed: Vector2(0, -80),
            acceleration: Vector2(0, 40),
            child: ComputedParticle(
              renderer: (canvas, particle) {
                final alpha = (1.0 - particle.progress).clamp(0.0, 1.0);
                final scale = 1.0 + particle.progress * 0.5;

                canvas.save();
                canvas.scale(scale, scale);

                final textPainter = TextPainter(
                  text: TextSpan(
                    text: 'x$comboCount!',
                    style: TextStyle(
                      color: GameConfig.textGold.withValues(alpha: alpha),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: alpha * 0.5),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                  textDirection: TextDirection.ltr,
                );
                textPainter.layout();
                textPainter.paint(
                  canvas,
                  Offset(-textPainter.width / 2, -textPainter.height / 2),
                );

                canvas.restore();
              },
            ),
          );
        },
      ),
    );
  }

  /// Spawn score popup (+XX)
  static ParticleSystemComponent scorePopup({
    required Vector2 position,
    required int score,
    bool isFever = false,
  }) {
    return ParticleSystemComponent(
      position: position,
      particle: Particle.generate(
        count: 1,
        lifespan: 0.7,
        generator: (i) {
          return AcceleratedParticle(
            speed: Vector2(_random.nextDouble() * 40 - 20, -100),
            acceleration: Vector2(0, 50),
            child: ComputedParticle(
              renderer: (canvas, particle) {
                final alpha = (1.0 - particle.progress).clamp(0.0, 1.0);

                final color = isFever
                    ? Color.lerp(
                        GameConfig.feverNeonPink,
                        GameConfig.feverNeonCyan,
                        particle.progress,
                      )!
                    : GameConfig.primaryMint;

                final textPainter = TextPainter(
                  text: TextSpan(
                    text: '+$score',
                    style: TextStyle(
                      color: color.withValues(alpha: alpha),
                      fontSize: isFever ? 22 : 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  textDirection: TextDirection.ltr,
                );
                textPainter.layout();
                textPainter.paint(
                  canvas,
                  Offset(-textPainter.width / 2, -textPainter.height / 2),
                );
              },
            ),
          );
        },
      ),
    );
  }

  /// Continuous fever particles (rainbow sparkles)
  static ParticleSystemComponent feverRainbow({
    required Vector2 position,
    required Vector2 gameSize,
  }) {
    return ParticleSystemComponent(
      position: Vector2(gameSize.x / 2, 0),
      particle: Particle.generate(
        count: 20,
        lifespan: 1.5,
        generator: (i) {
          final x = _random.nextDouble() * gameSize.x - gameSize.x / 2;
          final colors = [
            GameConfig.feverNeonPink,
            GameConfig.feverNeonCyan,
            GameConfig.feverNeonYellow,
            GameConfig.primaryPurple,
            GameConfig.primaryMint,
          ];
          final color = colors[_random.nextInt(colors.length)];

          return AcceleratedParticle(
            position: Vector2(x, -20),
            speed: Vector2(
              _random.nextDouble() * 60 - 30,
              100 + _random.nextDouble() * 150,
            ),
            acceleration: Vector2(0, 50),
            child: ComputedParticle(
              renderer: (canvas, particle) {
                final alpha = (1.0 - particle.progress).clamp(0.0, 1.0);
                final size = 2.0 + _random.nextDouble() * 3;
                canvas.drawCircle(
                  Offset.zero,
                  size * (1.0 - particle.progress * 0.3),
                  Paint()..color = color.withValues(alpha: alpha * 0.7),
                );
              },
            ),
          );
        },
      ),
    );
  }

  /// Hazard hit explosion (red particles)
  static ParticleSystemComponent hazardExplosion({
    required Vector2 position,
  }) {
    return ParticleSystemComponent(
      position: position,
      particle: Particle.generate(
        count: 15,
        lifespan: 0.5,
        generator: (i) {
          final angle = _random.nextDouble() * 2 * pi;
          final speed = 100 + _random.nextDouble() * 150;

          return AcceleratedParticle(
            speed: Vector2(cos(angle), sin(angle)) * speed,
            acceleration: Vector2(0, 300),
            child: ComputedParticle(
              renderer: (canvas, particle) {
                final alpha = (1.0 - particle.progress).clamp(0.0, 1.0);
                canvas.drawCircle(
                  Offset.zero,
                  3 + _random.nextDouble() * 2,
                  Paint()..color = GameConfig.textDanger.withValues(alpha: alpha),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
