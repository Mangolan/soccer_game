import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'animal_player.dart';
import 'difficulty_unlocks.dart';
import 'game/game_logic.dart';
import 'game_screen.dart';

class DifficultySelectionScreen extends StatefulWidget {
  const DifficultySelectionScreen({
    super.key,
    required this.selectedPlayer,
    required this.selectedIndex,
    required this.aiPlayer,
    required this.aiIndex,
  });

  final AnimalPlayer selectedPlayer;
  final int selectedIndex;
  final AnimalPlayer aiPlayer;
  final int aiIndex;

  @override
  State<DifficultySelectionScreen> createState() =>
      _DifficultySelectionScreenState();
}

class _DifficultySelectionScreenState extends State<DifficultySelectionScreen> {
  static const String _lastDifficultyKey = 'last_selected_difficulty';

  int _maxUnlockedLevel = 1;
  bool _loadingUnlocks = true;

  @override
  void initState() {
    super.initState();
    _loadUnlocks();
  }

  Future<void> _loadUnlocks() async {
    final maxUnlockedLevel = await DifficultyUnlocks.loadMaxUnlockedLevel();
    if (!context.mounted) {
      return;
    }
    setState(() {
      _maxUnlockedLevel = maxUnlockedLevel;
      _loadingUnlocks = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final levels = AIDifficulty.values;
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI 레벨 선택'),
        backgroundColor: const Color(0xFF0A1931),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFF0A1931),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 10, 24, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(width: double.infinity),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _playerPreview('내 선수', widget.selectedPlayer),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 22),
                    child: Text(
                      'VS',
                      style: TextStyle(
                        color: Color(0xFFFFD43B),
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  _playerPreview('랜덤 AI', widget.aiPlayer),
                ],
              ),
              const SizedBox(height: 26),
              Text(
                _loadingUnlocks ? '레벨 정보를 불러오는 중...' : '대결할 AI 레벨을 선택하세요',
                style: const TextStyle(fontSize: 18, color: Colors.white),
              ),
              const SizedBox(height: 36),
              Wrap(
                spacing: 14,
                runSpacing: 14,
                alignment: WrapAlignment.center,
                children: levels
                    .map(
                      (difficulty) => _difficultyButton(
                        context,
                        difficulty.label,
                        difficulty,
                        locked:
                            _loadingUnlocks ||
                            difficulty.level > _maxUnlockedLevel,
                      ),
                    )
                    .toList(growable: false),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _playerPreview(String label, AnimalPlayer player) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        AnimalPlush(player: player, size: 88, soccerUniform: true),
        const SizedBox(height: 8),
        Text(
          player.name.replaceAll(' 인형', ''),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _difficultyButton(
    BuildContext context,
    String label,
    AIDifficulty difficulty, {
    required bool locked,
  }) {
    return GestureDetector(
      onTap: () => locked
          ? _showLockedMessage(context, difficulty)
          : _start(context, difficulty),
      child: Container(
        width: 150,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: locked
              ? Colors.black.withOpacity(0.18)
              : Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: (locked ? Colors.grey : const Color(0xFF00D9E1))
                  .withOpacity(0.35),
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ],
          border: Border.all(
            color: (locked ? Colors.white38 : const Color(0xFF00D9E1))
                .withOpacity(0.65),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (locked) ...[
              const Icon(Icons.lock_rounded, color: Colors.white70, size: 18),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: locked ? Colors.white70 : Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _start(BuildContext context, AIDifficulty difficulty) async {
    if (difficulty.level > _maxUnlockedLevel) {
      _showLockedMessage(context, difficulty);
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastDifficultyKey, difficulty.name);
    if (!context.mounted) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GameScreen(
          selectedPlayer: widget.selectedPlayer,
          selectedIndex: widget.selectedIndex,
          aiPlayer: widget.aiPlayer,
          aiIndex: widget.aiIndex,
          aiDifficulty: difficulty,
        ),
      ),
    );
    if (!mounted) {
      return;
    }
    await _loadUnlocks();
  }

  void _showLockedMessage(BuildContext context, AIDifficulty difficulty) {
    final previousLevel = difficulty.level - 1;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Level $previousLevel을 이겨야 ${difficulty.label}이 열립니다.'),
      ),
    );
  }
}
