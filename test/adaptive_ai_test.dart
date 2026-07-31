import 'package:flutter_test/flutter_test.dart';
import 'package:soccer_game/game/adaptive_ai.dart';

void main() {
  group('PlayerBehaviorAnalyzer', () {
    test('classifies repeated attacking jumps as jump style', () {
      final analyzer = PlayerBehaviorAnalyzer();

      for (var i = 0; i < 50; i++) {
        analyzer.record(
          dt: 0.1,
          normalizedPosition: 0.5,
          horizontalVelocity: 40,
          movingForward: i.isEven,
          jumped: i % 6 == 0,
          nearBall: true,
        );
      }

      expect(analyzer.analysis.style, PlayerPlayStyle.jump);
      expect(analyzer.analysis.jumpAttackRatio, 1);
      expect(
        analyzer.analysis.strategy.shotStrategy,
        AiShotStrategy.lowCounter,
      );
    });

    test('classifies sustained forward play as rush style', () {
      final analyzer = PlayerBehaviorAnalyzer();

      for (var i = 0; i < 50; i++) {
        analyzer.record(
          dt: 0.1,
          normalizedPosition: 0.51,
          horizontalVelocity: 220,
          movingForward: true,
          jumped: false,
          nearBall: false,
        );
      }

      expect(analyzer.analysis.style, PlayerPlayStyle.rush);
      expect(analyzer.analysis.attackDirection, AttackDirection.right);
      expect(analyzer.analysis.strategy.counterAttackChance, 0.68);
    });

    test('classifies deep passive play as defensive style', () {
      final analyzer = PlayerBehaviorAnalyzer();

      for (var i = 0; i < 50; i++) {
        analyzer.record(
          dt: 0.1,
          normalizedPosition: 0.31,
          horizontalVelocity: 0,
          movingForward: false,
          jumped: false,
          nearBall: false,
        );
      }

      expect(analyzer.analysis.style, PlayerPlayStyle.defensive);
      expect(analyzer.analysis.strategy.shotStrategy, AiShotStrategy.lob);
    });

    test('discards observations outside the 20 second window', () {
      final analyzer = PlayerBehaviorAnalyzer();

      for (var i = 0; i < 250; i++) {
        analyzer.record(
          dt: 0.1,
          normalizedPosition: i < 40 ? 0.55 : 0.32,
          horizontalVelocity: i < 40 ? 220 : 0,
          movingForward: i < 40,
          jumped: false,
          nearBall: false,
        );
      }

      expect(analyzer.analysis.observedSeconds, closeTo(20, 0.11));
      expect(analyzer.analysis.style, PlayerPlayStyle.defensive);
    });
  });
}
