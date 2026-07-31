import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'animal_player.dart';
import 'difficulty_unlocks.dart';
import 'game/game_logic.dart';
import 'game/game_widget.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    required this.selectedPlayer,
    required this.aiPlayer,
    required this.aiDifficulty,
    required this.selectedIndex,
    required this.aiIndex,
  });

  final AnimalPlayer selectedPlayer;
  final AnimalPlayer aiPlayer;
  final AIDifficulty aiDifficulty;
  final int selectedIndex;
  final int aiIndex;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  @override
  void initState() {
    super.initState();
    _setLandscapeMode();
  }

  Future<void> _setLandscapeMode() async {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('동물 축구'),
      ),
      body: GameWidget(
        leftPlayer: widget.selectedPlayer,
        rightPlayer: widget.aiPlayer,
        aiDifficulty: widget.aiDifficulty,
        onRetreat: (prev) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => GameScreen(
                selectedPlayer: widget.selectedPlayer,
                aiPlayer: widget.aiPlayer,
                aiDifficulty: prev,
                selectedIndex: widget.selectedIndex,
                aiIndex: widget.aiIndex,
              ),
            ),
          );
        },
        onAdvance: (next) async {
          await DifficultyUnlocks.unlockThrough(next);
          if (!context.mounted) {
            return;
          }
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => GameScreen(
                selectedPlayer: widget.selectedPlayer,
                aiPlayer: widget.aiPlayer,
                aiDifficulty: next,
                selectedIndex: widget.selectedIndex,
                aiIndex: widget.aiIndex,
              ),
            ),
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('다음 난이도로 진행: ${_difficultyLabel(next)}')),
          );
        },
      ),
    );
  }
}

String _difficultyLabel(AIDifficulty difficulty) => difficulty.label;
