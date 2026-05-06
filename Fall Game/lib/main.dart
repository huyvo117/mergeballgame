import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'game/cat_catcher_game.dart';
import 'game/config/item_types.dart';
import 'game/managers/player_data.dart';
import 'ui/screens/menu_screen.dart';
import 'ui/screens/level_select.dart';
import 'ui/screens/shop_screen.dart';
import 'ui/overlays/hud_overlay.dart';
import 'ui/overlays/pause_overlay.dart';
import 'ui/overlays/level_complete.dart';
import 'ui/overlays/game_over.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait mode
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // System UI style
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF1A0533),
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  // Load persistent player data before app starts
  await PlayerData.instance.load();

  runApp(const CatCatcherApp());
}

/// Root application widget
class CatCatcherApp extends StatelessWidget {
  const CatCatcherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Meme Cat Catcher',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        fontFamily: 'Roboto',
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFF6B9D),
          secondary: Color(0xFFC084FC),
          surface: Color(0xFF1A0533),
        ),
      ),
      home: const AppShell(),
    );
  }
}

/// App shell that manages navigation between menu, level select, shop, and game
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

enum AppScreen { menu, levelSelect, shop, game }

class _AppShellState extends State<AppShell> {
  AppScreen _currentScreen = AppScreen.menu;
  late CatCatcherGame _game;
  CatSkin _selectedSkin = CatSkin.maxwell;

  @override
  void initState() {
    super.initState();
    _game = CatCatcherGame();

    // Restore equipped character from saved data
    final equippedName = PlayerData.instance.equippedCharacter;
    _selectedSkin = CatSkin.values.firstWhere(
      (s) => s.name == equippedName,
      orElse: () => CatSkin.maxwell,
    );
  }

  void _goToMenu() {
    setState(() => _currentScreen = AppScreen.menu);
  }

  void _goToLevelSelect() {
    setState(() => _currentScreen = AppScreen.levelSelect);
  }

  void _goToShop() {
    setState(() => _currentScreen = AppScreen.shop);
  }

  void _startLevel(int levelId) {
    // Create a fresh game instance for each play session
    _game = CatCatcherGame();
    _game.selectedSkin = _selectedSkin;
    // Sync progress from PlayerData
    _game.unlockedLevels.addAll(PlayerData.instance.unlockedLevels);
    for (final entry in PlayerData.instance.levelStars.entries) {
      _game.levelStars[entry.key] = entry.value;
    }
    _game.startLevel(levelId);
    setState(() => _currentScreen = AppScreen.game);
  }

  void _playFirstLevel() {
    _startLevel(1);
  }

  void _onSkinSelected(CatSkin skin) {
    setState(() {
      _selectedSkin = skin;
      _game.selectedSkin = skin;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Dark outer background for wide screens
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500), // Mobile frame width
          child: ClipRect(
            child: Scaffold(
              backgroundColor: const Color(0xFF1A0533),
              body: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _buildCurrentScreen(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentScreen() {
    switch (_currentScreen) {
      case AppScreen.menu:
        return MenuScreen(
          key: const ValueKey('menu'),
          onPlay: _playFirstLevel,
          onLevelSelect: _goToLevelSelect,
          onShop: _goToShop,
          currentSkin: _selectedSkin,
        );

      case AppScreen.levelSelect:
        return LevelSelectScreen(
          key: const ValueKey('levels'),
          onLevelSelected: _startLevel,
          onBack: _goToMenu,
          unlockedLevels: PlayerData.instance.unlockedLevels,
          levelStars: PlayerData.instance.levelStars,
        );

      case AppScreen.shop:
        return ShopScreen(
          key: const ValueKey('shop'),
          onBack: _goToMenu,
          onSkinSelected: _onSkinSelected,
          currentSkin: _selectedSkin,
        );

      case AppScreen.game:
        return _buildGameScreen();
    }
  }

  Widget _buildGameScreen() {
    return GameWidget<CatCatcherGame>(
      key: const ValueKey('game'),
      game: _game,
      overlayBuilderMap: {
        'hud': (context, game) => HudOverlay(game: game),
        'pause': (context, game) => PauseOverlay(game: game),
        'levelComplete': (context, game) => LevelCompleteOverlay(game: game),
        'gameOver': (context, game) => GameOverOverlay(game: game),
      },
    );
  }
}
