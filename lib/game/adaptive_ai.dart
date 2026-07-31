import 'dart:math' as math;

enum PlayerPlayStyle { rush, jump, defensive, mixed }

enum AttackDirection { left, right, neutral }

enum AiShotStrategy { lowCounter, direct, lob, balanced }

extension PlayerPlayStyleX on PlayerPlayStyle {
  String get label => switch (this) {
    PlayerPlayStyle.rush => '돌진형',
    PlayerPlayStyle.jump => '점프형',
    PlayerPlayStyle.defensive => '수비형',
    PlayerPlayStyle.mixed => '혼합형',
  };
}

extension AttackDirectionX on AttackDirection {
  String get label => switch (this) {
    AttackDirection.left => '왼쪽',
    AttackDirection.right => '오른쪽',
    AttackDirection.neutral => '중립',
  };
}

extension AiShotStrategyX on AiShotStrategy {
  String get label => switch (this) {
    AiShotStrategy.lowCounter => '낮은 역습',
    AiShotStrategy.direct => '빠른 직선 슈팅',
    AiShotStrategy.lob => '높은 롭슈팅',
    AiShotStrategy.balanced => '균형 슈팅',
  };
}

class AdaptiveAiStrategy {
  final double defenseDistanceScale;
  final double jumpLeadSeconds;
  final double jumpChanceScale;
  final double jumpCooldownScale;
  final double counterAttackChance;
  final AiShotStrategy shotStrategy;

  const AdaptiveAiStrategy({
    required this.defenseDistanceScale,
    required this.jumpLeadSeconds,
    required this.jumpChanceScale,
    required this.jumpCooldownScale,
    required this.counterAttackChance,
    required this.shotStrategy,
  });

  static const balanced = AdaptiveAiStrategy(
    defenseDistanceScale: 1,
    jumpLeadSeconds: 0,
    jumpChanceScale: 1,
    jumpCooldownScale: 1,
    counterAttackChance: 0.5,
    shotStrategy: AiShotStrategy.balanced,
  );
}

/// Read-only snapshot used by diagnostics, tests, and demo tooling.
class AiDecisionSnapshot {
  final double targetX;
  final bool counterAttackActive;
  final double jumpCooldownSeconds;
  final AdaptiveAiStrategy strategy;

  const AiDecisionSnapshot({
    required this.targetX,
    required this.counterAttackActive,
    required this.jumpCooldownSeconds,
    required this.strategy,
  });
}

class PlayerAnalysis {
  final double observedSeconds;
  final int jumpCount;
  final double jumpFrequencyPerMinute;
  final double jumpAttackRatio;
  final double forwardTendency;
  final double averagePosition;
  final AttackDirection attackDirection;
  final PlayerPlayStyle style;
  final double confidence;
  final AdaptiveAiStrategy strategy;

  const PlayerAnalysis({
    required this.observedSeconds,
    required this.jumpCount,
    required this.jumpFrequencyPerMinute,
    required this.jumpAttackRatio,
    required this.forwardTendency,
    required this.averagePosition,
    required this.attackDirection,
    required this.style,
    required this.confidence,
    required this.strategy,
  });

  static const empty = PlayerAnalysis(
    observedSeconds: 0,
    jumpCount: 0,
    jumpFrequencyPerMinute: 0,
    jumpAttackRatio: 0,
    forwardTendency: 0,
    averagePosition: 0.42,
    attackDirection: AttackDirection.neutral,
    style: PlayerPlayStyle.mixed,
    confidence: 0,
    strategy: AdaptiveAiStrategy.balanced,
  );

  int get jumpAttackPercent => (jumpAttackRatio * 100).round();
  int get forwardPercent => (forwardTendency * 100).round();
  int get confidencePercent => (confidence * 100).round();

  String get evidenceText {
    if (observedSeconds < 3) {
      return '상대 플레이 분석 중 ${observedSeconds.toStringAsFixed(1)}/3.0초';
    }
    return switch (style) {
      PlayerPlayStyle.jump =>
        '상대 분석: 점프 공격 $jumpAttackPercent% → ${strategy.shotStrategy.label} 전략 적용',
      PlayerPlayStyle.rush => '상대 분석: 전진 성향 $forwardPercent% → 거리 유지·역습 적용',
      PlayerPlayStyle.defensive =>
        '상대 분석: 평균 위치 ${(averagePosition * 100).round()}% → 전방 압박 적용',
      PlayerPlayStyle.mixed =>
        '상대 분석: 혼합 패턴 → ${strategy.shotStrategy.label} 적용',
    };
  }
}

class _BehaviorSample {
  final double time;
  final double duration;
  final double position;
  final double horizontalVelocity;
  final bool movingForward;
  final bool jumped;
  final bool attackingJump;

  const _BehaviorSample({
    required this.time,
    required this.duration,
    required this.position,
    required this.horizontalVelocity,
    required this.movingForward,
    required this.jumped,
    required this.attackingJump,
  });
}

/// Keeps a time-weighted, 20 second rolling window of human behaviour.
class PlayerBehaviorAnalyzer {
  final double windowSeconds;
  final List<_BehaviorSample> _samples = [];
  double _clock = 0;
  PlayerAnalysis _analysis = PlayerAnalysis.empty;

  PlayerBehaviorAnalyzer({this.windowSeconds = 20});

  PlayerAnalysis get analysis => _analysis;

  void reset() {
    _samples.clear();
    _clock = 0;
    _analysis = PlayerAnalysis.empty;
  }

  void record({
    required double dt,
    required double normalizedPosition,
    required double horizontalVelocity,
    required bool movingForward,
    required bool jumped,
    required bool nearBall,
  }) {
    if (dt <= 0) return;
    _clock += dt;
    _samples.add(
      _BehaviorSample(
        time: _clock,
        duration: dt,
        position: normalizedPosition.clamp(0, 1),
        horizontalVelocity: horizontalVelocity,
        movingForward: movingForward,
        jumped: jumped,
        attackingJump: jumped && nearBall,
      ),
    );
    final cutoff = _clock - windowSeconds;
    _samples.removeWhere((sample) => sample.time < cutoff);
    _analysis = _calculate();
  }

  PlayerAnalysis _calculate() {
    if (_samples.isEmpty) return PlayerAnalysis.empty;
    final duration = _samples.fold<double>(0, (sum, s) => sum + s.duration);
    final weightedPosition = _samples.fold<double>(
      0,
      (sum, s) => sum + s.position * s.duration,
    );
    final forwardTime = _samples.fold<double>(
      0,
      (sum, s) => sum + (s.movingForward ? s.duration : 0),
    );
    final signedMovement = _samples.fold<double>(
      0,
      (sum, s) => sum + s.horizontalVelocity * s.duration,
    );
    final jumpCount = _samples.where((s) => s.jumped).length;
    final attackingJumps = _samples.where((s) => s.attackingJump).length;
    final jumpRate = jumpCount * 60 / math.max(duration, 0.001);
    final jumpAttackRatio = jumpCount == 0 ? 0.0 : attackingJumps / jumpCount;
    final forward = forwardTime / math.max(duration, 0.001);
    final averagePosition = weightedPosition / math.max(duration, 0.001);
    final movementThreshold = duration * 18;
    final direction = signedMovement > movementThreshold
        ? AttackDirection.right
        : signedMovement < -movementThreshold
        ? AttackDirection.left
        : AttackDirection.neutral;

    final PlayerPlayStyle style;
    if (duration >= 3 && jumpRate >= 10 && jumpAttackRatio >= 0.5) {
      style = PlayerPlayStyle.jump;
    } else if (duration >= 3 && forward >= 0.58 && averagePosition >= 0.43) {
      style = PlayerPlayStyle.rush;
    } else if (duration >= 3 && forward <= 0.28 && averagePosition <= 0.43) {
      style = PlayerPlayStyle.defensive;
    } else {
      style = PlayerPlayStyle.mixed;
    }

    final strategy = switch (style) {
      PlayerPlayStyle.rush => const AdaptiveAiStrategy(
        defenseDistanceScale: 1.28,
        jumpLeadSeconds: 0.08,
        jumpChanceScale: 1.08,
        jumpCooldownScale: 0.92,
        counterAttackChance: 0.68,
        shotStrategy: AiShotStrategy.direct,
      ),
      PlayerPlayStyle.jump => const AdaptiveAiStrategy(
        defenseDistanceScale: 1.42,
        jumpLeadSeconds: 0.16,
        jumpChanceScale: 1.28,
        jumpCooldownScale: 0.82,
        counterAttackChance: 0.74,
        shotStrategy: AiShotStrategy.lowCounter,
      ),
      PlayerPlayStyle.defensive => const AdaptiveAiStrategy(
        defenseDistanceScale: 0.72,
        jumpLeadSeconds: -0.02,
        jumpChanceScale: 0.82,
        jumpCooldownScale: 1.12,
        counterAttackChance: 0.38,
        shotStrategy: AiShotStrategy.lob,
      ),
      PlayerPlayStyle.mixed => AdaptiveAiStrategy.balanced,
    };

    return PlayerAnalysis(
      observedSeconds: math.min(duration, windowSeconds),
      jumpCount: jumpCount,
      jumpFrequencyPerMinute: jumpRate,
      jumpAttackRatio: jumpAttackRatio,
      forwardTendency: forward,
      averagePosition: averagePosition,
      attackDirection: direction,
      style: style,
      confidence: (duration / windowSeconds).clamp(0, 1),
      strategy: strategy,
    );
  }
}
