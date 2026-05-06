import 'package:flutter/material.dart';
import '../../game/config/game_config.dart';
import '../../game/config/item_types.dart';
import '../../game/managers/audio_manager.dart';
import '../../game/managers/player_data.dart';

/// Full character shop screen with carousel, buy/equip flow
class ShopScreen extends StatefulWidget {
  final VoidCallback onBack;
  final Function(CatSkin) onSkinSelected;
  final CatSkin currentSkin;

  const ShopScreen({
    super.key,
    required this.onBack,
    required this.onSkinSelected,
    required this.currentSkin,
  });

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> with TickerProviderStateMixin {
  late PageController _pageController;
  int _currentPage = 0;
  late AnimationController _glowCtrl;
  late AnimationController _unlockCtrl;
  bool _showUnlockAnim = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Start on the currently equipped character page
    _currentPage = CatSkin.values.indexWhere(
      (s) => s.name == widget.currentSkin.name,
    );
    if (_currentPage < 0) _currentPage = 0;

    _pageController = PageController(
      initialPage: _currentPage,
      viewportFraction: 0.75,
    );

    _glowCtrl = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _unlockCtrl = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _glowCtrl.dispose();
    _unlockCtrl.dispose();
    super.dispose();
  }

  void _buyCharacter(CatSkin skin) {
    final playerData = PlayerData.instance;
    if (playerData.diamonds < skin.price) {
      setState(() => _errorMessage = 'Not enough Diamonds!');
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _errorMessage = null);
      });
      return;
    }

    final success = playerData.purchaseCharacter(skin.name, skin.price);
    if (success) {
      AudioManager.playLevelCompleteSFX();
      widget.onSkinSelected(skin);
      setState(() {
        _showUnlockAnim = true;
      });
      _unlockCtrl.forward(from: 0).then((_) {
        if (mounted) {
          setState(() => _showUnlockAnim = false);
        }
      });
    }
  }

  void _equipCharacter(CatSkin skin) {
    final playerData = PlayerData.instance;
    playerData.equipCharacter(skin.name);
    widget.onSkinSelected(skin);
    AudioManager.playClickSFX();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final playerData = PlayerData.instance;

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
            _buildHeader(playerData),
            const SizedBox(height: 16),

            // Title
            const Text(
              'CHARACTER SHOP',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Swipe to browse characters',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 12,
              ),
            ),

            const Spacer(flex: 1),

            // Character carousel
            SizedBox(
              height: 350,
              child: PageView.builder(
                controller: _pageController,
                itemCount: CatSkin.values.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (context, index) {
                  final skin = CatSkin.values[index];
                  final isActive = index == _currentPage;
                  return _buildCharacterCard(skin, isActive, playerData);
                },
              ),
            ),

            const SizedBox(height: 16),

            // Page dots
            _buildPageDots(),

            const SizedBox(height: 16),

            // Action button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: _buildActionButton(playerData),
            ),

            // Error message
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: GameConfig.textDanger.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: GameConfig.textDanger.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: GameConfig.textDanger,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),

            const Spacer(flex: 1),

            // Unlock animation overlay
            if (_showUnlockAnim) _buildUnlockOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(PlayerData data) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
              child: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
            ),
          ),
          const Spacer(),
          // Diamond counter
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
                const Text('💎', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 6),
                Text(
                  '${data.diamonds}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
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

  Widget _buildCharacterCard(CatSkin skin, bool isActive, PlayerData data) {
    final isUnlocked = data.isCharacterUnlocked(skin.name);
    final isEquipped = data.equippedCharacter == skin.name;

    return AnimatedBuilder(
      animation: _glowCtrl,
      builder: (context, _) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: EdgeInsets.symmetric(
            horizontal: 8,
            vertical: isActive ? 0 : 20,
          ),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isUnlocked
                  ? [
                      skin.color.withValues(alpha: 0.2),
                      skin.tierColor.withValues(alpha: 0.1),
                    ]
                  : [
                      Colors.white.withValues(alpha: 0.05),
                      Colors.white.withValues(alpha: 0.02),
                    ],
            ),
            border: Border.all(
              color: isEquipped
                  ? skin.tierColor
                  : isUnlocked
                      ? skin.color.withValues(alpha: 0.3)
                      : Colors.white.withValues(alpha: 0.1),
              width: isEquipped ? 2.5 : 1,
            ),
            boxShadow: isActive && isUnlocked
                ? [
                    BoxShadow(
                      color: skin.tierColor.withValues(
                        alpha: 0.15 + _glowCtrl.value * 0.15,
                      ),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Tier badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: skin.tierColor.withValues(alpha: 0.2),
                  border: Border.all(color: skin.tierColor.withValues(alpha: 0.5)),
                ),
                child: Text(
                  'TIER ${skin.tier}',
                  style: TextStyle(
                    color: skin.tierColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Character emoji (or silhouette)
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: isUnlocked
                      ? RadialGradient(
                          colors: [
                            skin.color.withValues(alpha: 0.3),
                            skin.color.withValues(alpha: 0.0),
                          ],
                        )
                      : null,
                  color: isUnlocked ? null : Colors.white.withValues(alpha: 0.05),
                ),
                child: Center(
                  child: isUnlocked
                      ? Text(skin.emoji, style: const TextStyle(fontSize: 52))
                      : Stack(
                          alignment: Alignment.center,
                          children: [
                            // Silhouette emoji (darkened)
                            Opacity(
                              opacity: 0.15,
                              child: Text(skin.emoji, style: const TextStyle(fontSize: 52)),
                            ),
                            // Lock icon
                            const Icon(Icons.lock, color: Colors.white38, size: 28),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 10),

              // Name
              Text(
                skin.name,
                style: TextStyle(
                  color: isUnlocked ? Colors.white : Colors.white38,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 4),

              // Description
              Text(
                skin.description,
                style: TextStyle(
                  color: isUnlocked
                      ? Colors.white.withValues(alpha: 0.5)
                      : Colors.white24,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              // Skill info
              if (skin.skill != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: skin.tierColor.withValues(alpha: isUnlocked ? 0.15 : 0.05),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '⚡ ${skin.skillName}',
                        style: TextStyle(
                          color: isUnlocked ? skin.tierColor : Colors.white24,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        skin.skillDesc,
                        style: TextStyle(
                          color: isUnlocked
                              ? Colors.white.withValues(alpha: 0.5)
                              : Colors.white12,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Text(
                  'No special skill',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3),
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                  ),
                ),

              // Price tag (if locked)
              if (!isUnlocked) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('💎', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 4),
                    Text(
                      '${skin.price}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],

              // Equipped badge
              if (isEquipped) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: LinearGradient(
                      colors: [GameConfig.primaryMint, GameConfig.primaryCyan],
                    ),
                  ),
                  child: const Text(
                    '✓ EQUIPPED',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildPageDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(CatSkin.values.length, (i) {
        final skin = CatSkin.values[i];
        final isActive = i == _currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: isActive ? skin.tierColor : Colors.white24,
          ),
        );
      }),
    );
  }

  Widget _buildActionButton(PlayerData data) {
    final skin = CatSkin.values[_currentPage];
    final isUnlocked = data.isCharacterUnlocked(skin.name);
    final isEquipped = data.equippedCharacter == skin.name;

    if (isEquipped) {
      // Already equipped
      return Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          color: Colors.white.withValues(alpha: 0.1),
          border: Border.all(color: Colors.white24),
        ),
        child: const Center(
          child: Text(
            '✓  EQUIPPED',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
          ),
        ),
      );
    } else if (isUnlocked) {
      // Unlocked but not equipped — EQUIP
      return _ShopButton(
        text: '🎯  EQUIP',
        gradient: const [GameConfig.primaryMint, GameConfig.primaryCyan],
        onTap: () => _equipCharacter(skin),
      );
    } else {
      // Locked — BUY
      final canAfford = data.diamonds >= skin.price;
      return _ShopButton(
        text: '💎  BUY FOR ${skin.price}',
        gradient: canAfford
            ? [const Color(0xFF8B5CF6), const Color(0xFF6366F1)]
            : [Colors.white12, Colors.white10],
        onTap: () => _buyCharacter(skin),
      );
    }
  }

  Widget _buildUnlockOverlay() {
    final skin = CatSkin.values[_currentPage];
    return AnimatedBuilder(
      animation: _unlockCtrl,
      builder: (context, _) {
        return Opacity(
          opacity: (1 - _unlockCtrl.value).clamp(0, 1),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Transform.scale(
                  scale: 1 + _unlockCtrl.value * 0.5,
                  child: Text(skin.emoji, style: const TextStyle(fontSize: 64)),
                ),
                const SizedBox(height: 8),
                Text(
                  '🎉 UNLOCKED!',
                  style: TextStyle(
                    color: skin.tierColor,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Reusable shop button
class _ShopButton extends StatefulWidget {
  final String text;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _ShopButton({
    required this.text,
    required this.gradient,
    required this.onTap,
  });

  @override
  State<_ShopButton> createState() => _ShopButtonState();
}

class _ShopButtonState extends State<_ShopButton> {
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
        transform: Matrix4.diagonal3Values(
          _isPressed ? 0.95 : 1.0,
          _isPressed ? 0.95 : 1.0,
          1.0,
        ),
        transformAlignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: widget.gradient),
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
