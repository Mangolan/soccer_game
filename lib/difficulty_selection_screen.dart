import 'package:flutter/material.dart';
import 'game/game_logic.dart';
import 'game_screen.dart';
import 'marble_face.dart';
 

class DifficultySelectionScreen extends StatelessWidget {
  final MarbleStyle selectedMarble;
  final MarbleExpression? selectedExpression;
  final EyeStyle? selectedEyeStyle;
  final bool selectedHumanize;
  final bool selectedFlipMouth;
  final int selectedIndex;

  const DifficultySelectionScreen({
    super.key,
    required this.selectedMarble,
    this.selectedExpression,
    this.selectedEyeStyle,
    this.selectedHumanize = false,
    this.selectedFlipMouth = false,
    required this.selectedIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI 난이도 선택'),
        backgroundColor: const Color(0xFF0A1931),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFF0A1931),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('컴퓨터(AI) 난이도를 선택하세요', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 30),
            _difficultyButton(context, '매우 쉬움', () => _start(context, AIDifficulty.veryEasy)),
            const SizedBox(height: 20),
            _difficultyButton(context, '쉬움', () => _start(context, AIDifficulty.easy)),
            const SizedBox(height: 20),
            _difficultyButton(context, '중간', () => _start(context, AIDifficulty.medium)),
            const SizedBox(height: 20),
            _difficultyButton(context, '어려움', () => _start(context, AIDifficulty.hard)),
            const SizedBox(height: 20),
            _difficultyButton(context, '매우 어려움', () => _start(context, AIDifficulty.veryHard)),
          ],
        ),
      ),
    );
  }

  Widget _difficultyButton(BuildContext context, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: () => _showAdvanceHintDialog(context, onTap),
      child: Container(
        width: 220,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00D9E1).withOpacity(0.4),
              blurRadius: 15,
              spreadRadius: 2,
            ),
            BoxShadow(
              color: const Color(0xFF0A1931).withOpacity(0.6),
              blurRadius: 20,
              spreadRadius: -5,
              offset: const Offset(0, 5),
            ),
          ],
          border: Border.all(
            color: const Color(0xFF00D9E1).withOpacity(0.5),
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ),
    );
  }

  void _start(BuildContext context, AIDifficulty d) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => GameScreen(
          selected: selectedMarble,
          selectedExpression: selectedExpression,
          selectedEyeStyle: selectedEyeStyle,
          selectedHumanize: selectedHumanize,
          selectedFlipMouth: selectedFlipMouth,
          selectedIndex: selectedIndex,
          aiDifficulty: d,
        ),
      ),
    );
  }
}

void _showAdvanceHintDialog(BuildContext context, VoidCallback onStart) {
  const Color glowColor = Color(0xFF00D9E1);

  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF0A1931).withOpacity(0.95),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: glowColor.withOpacity(0.7), width: 1.5),
      ),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.emoji_events, color: Colors.amber.shade300, size: 28),
          const SizedBox(width: 10),
          const Text('단계 승급 안내', style: TextStyle(color: Colors.white)),
        ],
      ),
      content: const Text(
        '게임 전 안내:\n15점을 먼저 득점하면\n다음 단계로 올라갑니다\n(매우 어려움은 승급 없음)',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white70, height: 1.5),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('닫기', style: TextStyle(color: Colors.white70)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: glowColor,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          onPressed: () {
            Navigator.of(ctx).pop();
            onStart();
          },
          child: const Text('시작하기', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    ),
  );
}
