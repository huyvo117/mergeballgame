import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'game/merge_ball_game.dart';
import 'ui/score_overlay.dart';
import 'ui/game_over_overlay.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait mode for better gameplay
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI style
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF1A1B2E),
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  runApp(const MergeBallApp());
}

class MergeBallApp extends StatelessWidget {
  const MergeBallApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Merge Ball',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        fontFamily: 'Roboto',
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF6C3CE0),
          secondary: Color(0xFF8B5CF6),
          surface: Color(0xFF1A1B2E),
        ),
      ),
      home: const GamePage(),
    );
  }
}

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  late MergeBallGame _game;

  @override
  void initState() {
    super.initState();
    _game = MergeBallGame();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1B2E),
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF1A1B2E),
                  Color(0xFF0F1019),
                  Color(0xFF1A1B2E),
                ],
              ),
            ),
          ),
          // Game
          GameWidget<MergeBallGame>(
            game: _game,
            overlayBuilderMap: {
              'score': (context, game) => ScoreOverlay(game: game),
              'gameOver': (context, game) => GameOverOverlay(game: game),
            },
            initialActiveOverlays: const ['score'],
          ),
        ],
      ),
    );
  }
}
