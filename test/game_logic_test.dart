import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soccer_game/game/game_logic.dart';

GameState _createGame({int seed = 7}) {
  return GameState(
    size: const Size(800, 450),
    leftPlayer: PlayerState(pos: Offset.zero, color: Colors.blue),
    rightPlayer: PlayerState(pos: Offset.zero, color: Colors.red),
    ball: BallState(pos: Offset.zero),
    aiDifficulty: AIDifficulty.level5,
    randomSeed: seed,
  );
}

void main() {
  group('GameState', () {
    test('kickoff initializes a running match and resets adaptive history', () {
      final game = _createGame()..kickoff();

      game.update(0.1, leftRight: true);
      expect(game.running, isTrue);
      expect(game.playerAnalysis.observedSeconds, greaterThan(0));

      game.kickoff();
      expect(game.playerAnalysis.observedSeconds, 0);
      expect(game.leftPlayer.grounded, isTrue);
      expect(game.rightPlayer.grounded, isTrue);
    });

    test('left movement and edge-triggered jump update player physics', () {
      final game = _createGame()..kickoff();
      final startX = game.leftPlayer.pos.dx;

      game.update(1 / 60, leftRight: true, leftJump: true);
      final firstJumpVelocity = game.leftPlayer.vel.dy;
      game.update(1 / 60, leftRight: true, leftJump: true);

      expect(game.leftPlayer.pos.dx, greaterThan(startX));
      expect(firstJumpVelocity, lessThan(0));
      expect(game.leftPlayer.grounded, isFalse);
      expect(game.playerAnalysis.jumpCount, 1);
    });

    test('ball entering the right goal increments the human score', () {
      final game = _createGame()..kickoff();
      game.ball
        ..pos = game.rightGoal.center
        ..vel = Offset.zero;

      game.update(1 / 120);

      expect(game.score.left, 1);
      expect(game.celebrating, isTrue);
      expect(game.lastScorerLeft, isTrue);
    });

    test('AI decision diagnostics expose the active strategy', () {
      final game = _createGame()..kickoff();

      expect(game.aiDecision.strategy.defenseDistanceScale, 1);
      expect(game.aiDecision.counterAttackActive, isFalse);
      expect(game.aiDecision.targetX, isNonZero);
    });
  });
}
