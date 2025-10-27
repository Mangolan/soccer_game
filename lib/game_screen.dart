import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'game/game_logic.dart';
import 'game/game_widget.dart';
import 'marble_face.dart';
import 'marble_selection_screen2.dart';

class GameScreen extends StatelessWidget {
  final MarbleStyle selected;
  final AIDifficulty aiDifficulty;
  final MarbleExpression? selectedExpression;
  final EyeStyle? selectedEyeStyle;
  final bool selectedHumanize;
  final bool selectedFlipMouth;
  final int selectedIndex;

  const GameScreen({
    super.key,
    required this.selected,
    required this.aiDifficulty,
    this.selectedExpression,
    this.selectedEyeStyle,
    this.selectedHumanize = false,
    this.selectedFlipMouth = false,
    required this.selectedIndex,
  });

  @override
  Widget build(BuildContext context) {
    final aiIndex = _randomAiIndexExcluding(selectedIndex);
    final MarbleStyle aiStyle = MarbleSelectionScreen.samples[aiIndex];
    final MarbleExpression aiExpr = MarbleSelectionScreen
        .sampleExpressions[aiIndex % MarbleSelectionScreen.sampleExpressions.length];
    final EyeStyle aiEyes = MarbleSelectionScreen
        .eyeStyles[aiIndex % MarbleSelectionScreen.eyeStyles.length];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Soccer Game'),
      ),
      body: GameWidget(
        leftStyle: selected,
        rightStyle: aiStyle,
        initialRightExpression: aiExpr,
        initialLeftExpression: selectedExpression,
        leftEyeStyle: selectedEyeStyle,
        leftHumanize: selectedHumanize,
        leftFlipMouth: selectedFlipMouth,
        rightEyeStyle: aiEyes,
        rightHumanize: true,
        rightFlipMouth: true,
        aiDifficulty: aiDifficulty,
        onAdvance: (next) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => GameScreen(
                selected: selected,
                aiDifficulty: next,
                selectedExpression: selectedExpression,
                selectedEyeStyle: selectedEyeStyle,
                selectedHumanize: selectedHumanize,
                selectedFlipMouth: selectedFlipMouth,
                selectedIndex: selectedIndex,
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

int _randomAiIndexExcluding(int exclude) {
  final total = MarbleSelectionScreen.samples.length;
  final pool = List<int>.generate(total, (i) => i)..remove(exclude);
  return pool[math.Random().nextInt(pool.length)];
}

String _difficultyLabel(AIDifficulty d) {
  switch (d) {
    case AIDifficulty.veryEasy:
      return '매우 쉬움';
    case AIDifficulty.easy:
      return '쉬움';
    case AIDifficulty.medium:
      return '중간';
    case AIDifficulty.hard:
      return '어려움';
    case AIDifficulty.veryHard:
      return '매우 어려움';
  }
}
