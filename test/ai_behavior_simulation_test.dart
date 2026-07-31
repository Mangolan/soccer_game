import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soccer_game/game/adaptive_ai.dart';
import 'package:soccer_game/game/game_logic.dart';

GameState _game(int seed) => GameState(
  size: const Size(800, 450),
  leftPlayer: PlayerState(pos: Offset.zero, color: Colors.blue),
  rightPlayer: PlayerState(pos: Offset.zero, color: Colors.red),
  ball: BallState(pos: Offset.zero),
  aiDifficulty: AIDifficulty.level8,
  randomSeed: seed,
)..kickoff();

void _simulateRush(GameState game) {
  for (var i = 0; i < 100; i++) {
    game.leftPlayer.pos = Offset(
      game.worldWidth * 0.55,
      game.groundY - GameConfig.playerRadius,
    );
    game.leftPlayer.grounded = true;
    game.update(0.05, leftRight: true);
  }
}

void _simulateDefense(GameState game) {
  for (var i = 0; i < 100; i++) {
    game.leftPlayer
      ..pos = Offset(
        game.worldWidth * 0.28,
        game.groundY - GameConfig.playerRadius,
      )
      ..vel = Offset.zero
      ..grounded = true;
    game.update(0.05);
  }
}

void _simulateAttackingJumps(GameState game) {
  for (var i = 0; i < 100; i++) {
    game.leftPlayer
      ..pos = Offset(
        game.worldWidth * 0.48,
        game.groundY - GameConfig.playerRadius,
      )
      ..vel = Offset.zero
      ..grounded = true;
    game.ball
      ..pos = game.leftPlayer.pos + const Offset(34, 0)
      ..vel = Offset.zero;
    game.update(0.05, leftJump: i % 6 == 0);
  }
}

void main() {
  group('adaptive AI behavior simulation', () {
    test(
      'repeated rush input changes the live AI to spacing and direct shots',
      () {
        final game = _game(11);

        _simulateRush(game);

        expect(game.playerAnalysis.style, PlayerPlayStyle.rush);
        expect(game.aiDecision.strategy.defenseDistanceScale, 1.28);
        expect(game.aiDecision.strategy.counterAttackChance, 0.68);
        expect(game.aiDecision.strategy.shotStrategy, AiShotStrategy.direct);
      },
    );

    test('repeated attacking jumps select early jumps and low counters', () {
      final game = _game(12);

      _simulateAttackingJumps(game);

      expect(game.playerAnalysis.style, PlayerPlayStyle.jump);
      expect(game.playerAnalysis.jumpAttackRatio, 1);
      expect(game.aiDecision.strategy.jumpLeadSeconds, 0.16);
      expect(game.aiDecision.strategy.shotStrategy, AiShotStrategy.lowCounter);
    });

    test('passive positioning makes the AI press and choose lob shots', () {
      final game = _game(13);

      _simulateDefense(game);

      expect(game.playerAnalysis.style, PlayerPlayStyle.defensive);
      expect(game.aiDecision.strategy.defenseDistanceScale, 0.72);
      expect(game.aiDecision.strategy.counterAttackChance, 0.38);
      expect(game.aiDecision.strategy.shotStrategy, AiShotStrategy.lob);
    });

    test('three repeated behaviors produce three distinct AI policies', () {
      final rush = _game(21);
      final jump = _game(22);
      final defense = _game(23);
      _simulateRush(rush);
      _simulateAttackingJumps(jump);
      _simulateDefense(defense);

      final shots = {
        rush.aiDecision.strategy.shotStrategy,
        jump.aiDecision.strategy.shotStrategy,
        defense.aiDecision.strategy.shotStrategy,
      };
      final distances = {
        rush.aiDecision.strategy.defenseDistanceScale,
        jump.aiDecision.strategy.defenseDistanceScale,
        defense.aiDecision.strategy.defenseDistanceScale,
      };

      expect(shots, hasLength(3));
      expect(distances, hasLength(3));
    });
  });
}
