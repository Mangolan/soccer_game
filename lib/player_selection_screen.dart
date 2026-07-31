import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'animal_player.dart';
import 'difficulty_selection_screen.dart';

class PlayerStats {
  const PlayerStats({
    required this.speed,
    required this.power,
    required this.jump,
    required this.defense,
  });

  final int speed;
  final int power;
  final int jump;
  final int defense;
}

const List<PlayerStats> _playerStats = <PlayerStats>[
  PlayerStats(speed: 92, power: 66, jump: 96, defense: 58),
  PlayerStats(speed: 62, power: 96, jump: 64, defense: 91),
  PlayerStats(speed: 78, power: 72, jump: 76, defense: 70),
  PlayerStats(speed: 90, power: 70, jump: 88, defense: 62),
  PlayerStats(speed: 84, power: 80, jump: 74, defense: 78),
  PlayerStats(speed: 68, power: 84, jump: 60, defense: 94),
  PlayerStats(speed: 96, power: 62, jump: 82, defense: 60),
  PlayerStats(speed: 88, power: 86, jump: 80, defense: 66),
  PlayerStats(speed: 70, power: 90, jump: 68, defense: 96),
];

class PlayerSelectionScreen extends StatefulWidget {
  const PlayerSelectionScreen({super.key});

  @override
  State<PlayerSelectionScreen> createState() => _PlayerSelectionScreenState();
}

class _PlayerSelectionScreenState extends State<PlayerSelectionScreen> {
  static const String _lastSelectedAnimalKey = 'last_selected_animal_index';
  final math.Random _random = math.Random();
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadLastSelection();
  }

  Future<void> _loadLastSelection() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getInt(_lastSelectedAnimalKey);
    if (!mounted ||
        saved == null ||
        saved < 0 ||
        saved >= kAnimalPlayers.length) {
      return;
    }
    setState(() => _selectedIndex = saved);
  }

  Future<void> _continue() async {
    final aiCandidates = List<int>.generate(
      kAnimalPlayers.length,
      (index) => index,
    )..remove(_selectedIndex);
    final aiIndex = aiCandidates[_random.nextInt(aiCandidates.length)];
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastSelectedAnimalKey, _selectedIndex);
    if (!mounted) {
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DifficultySelectionScreen(
          selectedPlayer: kAnimalPlayers[_selectedIndex],
          selectedIndex: _selectedIndex,
          aiPlayer: kAnimalPlayers[aiIndex],
          aiIndex: aiIndex,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1931),
      appBar: AppBar(
        title: const Text('선수 선택'),
        centerTitle: true,
        backgroundColor: const Color(0xFF0A1931),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(18, 8, 18, 16),
              child: Column(
                children: [
                  Text(
                    '내 선수를 고르세요',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    '모든 선수의 능력치를 비교해 보세요. 상대 AI는 무작위로 정해집니다.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                itemCount: kAnimalPlayers.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  // AnimalPlush is 1.18 times taller than its requested size.
                  // Leave enough room for it and the stat rows at larger text
                  // scales so the cards do not produce a bottom overflow.
                  mainAxisExtent: 320,
                ),
                itemBuilder: (context, index) => _PlayerCard(
                  player: kAnimalPlayers[index],
                  stats: _playerStats[index],
                  selected: index == _selectedIndex,
                  onTap: () => setState(() => _selectedIndex = index),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton.icon(
                  onPressed: _continue,
                  icon: const Icon(Icons.sports_soccer_rounded),
                  label: Text(
                    '${kAnimalPlayers[_selectedIndex].name.replaceAll(' 인형', '')} 선수로 시작',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayerCard extends StatelessWidget {
  const _PlayerCard({
    required this.player,
    required this.stats,
    required this.selected,
    required this.onTap,
  });

  final AnimalPlayer player;
  final PlayerStats stats;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFF173B65)
                : const Color(0xFF102746),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? const Color(0xFF00D9E1)
                  : Colors.white.withOpacity(0.12),
              width: selected ? 3 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: const Color(0xFF00D9E1).withOpacity(0.25),
                      blurRadius: 14,
                    ),
                  ]
                : null,
          ),
          child: Column(
            children: [
              AnimalPlush(
                player: player,
                size: 68,
                soccerUniform: true,
              ),
              const SizedBox(height: 3),
              Text(
                player.name.replaceAll(' 인형', ' 선수'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(
                height: 20,
                child: selected
                    ? const Text(
                        '선택됨',
                        style: TextStyle(
                          color: Color(0xFF00D9E1),
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      )
                    : null,
              ),
              const Divider(color: Colors.white24, height: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _StatBar(
                      label: '스피드',
                      value: stats.speed,
                      color: const Color(0xFF74C0FC),
                    ),
                    _StatBar(
                      label: '파워',
                      value: stats.power,
                      color: const Color(0xFFFF8787),
                    ),
                    _StatBar(
                      label: '점프',
                      value: stats.jump,
                      color: const Color(0xFFB197FC),
                    ),
                    _StatBar(
                      label: '수비',
                      value: stats.defense,
                      color: const Color(0xFF63E6BE),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatBar extends StatelessWidget {
  const _StatBar({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 44,
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '$value',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: value / 100,
              minHeight: 8,
              backgroundColor: Colors.white24,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
