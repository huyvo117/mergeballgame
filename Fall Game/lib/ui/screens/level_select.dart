import 'package:flutter/material.dart';
import '../../game/config/game_config.dart';
import '../../game/config/level_config.dart';
import '../../game/managers/audio_manager.dart';

/// Level selection screen with Candy Crush-style stage map
class LevelSelectScreen extends StatefulWidget {
  final Function(int levelId) onLevelSelected;
  final VoidCallback onBack;
  final Set<int> unlockedLevels;
  final Map<int, int> levelStars;

  const LevelSelectScreen({
    super.key,
    required this.onLevelSelected,
    required this.onBack,
    required this.unlockedLevels,
    required this.levelStars,
  });

  @override
  State<LevelSelectScreen> createState() => _LevelSelectScreenState();
}

class _LevelSelectScreenState extends State<LevelSelectScreen>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  int _currentStage = 0;
  late AnimationController _starAnimController;

  static const _stageColors = [
    [GameConfig.primaryPink, GameConfig.primaryPurple],   // Stage 1
    [GameConfig.primaryCyan, GameConfig.primaryMint],      // Stage 2
    [GameConfig.feverNeonPink, GameConfig.feverNeonCyan],  // Stage 3
  ];

  static const _stageIcons = ['🍳', '🌃', '🌀'];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentStage);
    _starAnimController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _starAnimController.dispose();
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
            // Header
            _buildHeader(),

            // Stage indicator
            _buildStageIndicator(),

            const SizedBox(height: 16),

            // Level grid
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: LevelDatabase.totalStages,
                onPageChanged: (page) {
                  setState(() => _currentStage = page);
                  _starAnimController.forward(from: 0);
                },
                itemBuilder: (context, stageIndex) {
                  return _buildStageGrid(stageIndex + 1);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () {
              AudioManager.playClickSFX();
              widget.onBack();
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.1),
                border: Border.all(color: Colors.white24),
              ),
              child: const Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
          const Spacer(),
          const Text(
            'SELECT LEVEL',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: 3,
            ),
          ),
          const Spacer(),
          const SizedBox(width: 44), // Balance
        ],
      ),
    );
  }

  Widget _buildStageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(LevelDatabase.totalStages, (index) {
        final isActive = index == _currentStage;
        final colors = _stageColors[index];
        return GestureDetector(
          onTap: () {
            _pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 6),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: isActive
                  ? LinearGradient(colors: colors)
                  : null,
              color: isActive ? null : Colors.white.withValues(alpha: 0.1),
              border: Border.all(
                color: isActive ? colors[0] : Colors.white24,
                width: isActive ? 2 : 1,
              ),
            ),
            child: Text(
              '${_stageIcons[index]} Stage ${index + 1}',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildStageGrid(int stageId) {
    final stageLevels = LevelDatabase.getStage(stageId);
    final stageName = stageLevels.first.stageName;
    final colors = _stageColors[stageId - 1];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SizedBox(height: 8),

          // Stage title
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: colors,
            ).createShader(bounds),
            child: Text(
              stageName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Level cards
          Expanded(
            child: ListView.builder(
              itemCount: stageLevels.length,
              itemBuilder: (context, index) {
                final level = stageLevels[index];
                return _buildLevelCard(level, colors);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelCard(LevelConfig level, List<Color> stageColors) {
    final isUnlocked = widget.unlockedLevels.contains(level.levelId);
    final stars = widget.levelStars[level.levelId] ?? 0;

    return GestureDetector(
      onTap: isUnlocked
          ? () {
              AudioManager.playClickSFX();
              widget.onLevelSelected(level.levelId);
            }
          : null,
      child: AnimatedBuilder(
        animation: _starAnimController,
        builder: (context, child) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: isUnlocked
                  ? LinearGradient(
                      colors: [
                        stageColors[0].withValues(alpha: 0.15),
                        stageColors[1].withValues(alpha: 0.08),
                      ],
                    )
                  : null,
              color: isUnlocked ? null : Colors.white.withValues(alpha: 0.05),
              border: Border.all(
                color: isUnlocked
                    ? stageColors[0].withValues(alpha: 0.3)
                    : Colors.white.withValues(alpha: 0.1),
              ),
            ),
            child: Row(
              children: [
                // Level number
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: isUnlocked
                        ? LinearGradient(colors: stageColors)
                        : null,
                    color: isUnlocked ? null : Colors.white.withValues(alpha: 0.1),
                  ),
                  child: Center(
                    child: isUnlocked
                        ? Text(
                            '${level.levelId}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          )
                        : const Icon(Icons.lock, color: Colors.white38, size: 18),
                  ),
                ),

                const SizedBox(width: 14),

                // Level info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        level.levelName,
                        style: TextStyle(
                          color: isUnlocked ? Colors.white : Colors.white38,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        level.objective,
                        style: TextStyle(
                          color: isUnlocked
                              ? Colors.white.withValues(alpha: 0.6)
                              : Colors.white24,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Time limit
                      Text(
                        '⏱️ ${level.timeLimit.toInt()}s  |  🎯 ${level.targetScore} pts',
                        style: TextStyle(
                          color: isUnlocked
                              ? stageColors[0].withValues(alpha: 0.7)
                              : Colors.white12,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                // Stars
                if (isUnlocked)
                  Row(
                    children: List.generate(3, (i) {
                      final isFilled = i < stars;
                      final delay = i * 0.2;
                      final animProgress =
                          ((_starAnimController.value - delay) / (1 - delay))
                              .clamp(0.0, 1.0);

                      return Padding(
                        padding: const EdgeInsets.only(left: 2),
                        child: Transform.scale(
                          scale: isFilled ? 0.8 + animProgress * 0.2 : 0.8,
                          child: Icon(
                            isFilled ? Icons.star : Icons.star_border,
                            color: isFilled
                                ? GameConfig.textGold
                                : Colors.white24,
                            size: 22,
                          ),
                        ),
                      );
                    }),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
