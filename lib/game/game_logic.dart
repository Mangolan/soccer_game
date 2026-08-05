import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'adaptive_ai.dart';

enum AIDifficulty {
  level1,
  level2,
  level3,
  level4,
  level5,
  level6,
  level7,
  level8,
  level9,
  level10,
}

extension AIDifficultyX on AIDifficulty {
  int get level => index + 1;

  String get label => 'Level $level';

  AIDifficulty? get next => index >= AIDifficulty.values.length - 1
      ? null
      : AIDifficulty.values[index + 1];

  AIDifficulty? get previous =>
      index <= 0 ? null : AIDifficulty.values[index - 1];
}

enum MarbleExpression {
  neutral,
  happy,
  pouting,
  angry,
  sad,
  mischievous,
  in_love,
  surprised,
  funny,
  sleeping,
}

class GameConfig {
  static const double gravity = 1800; // px/s^2
  static const double groundFrac = 0.85; // ground y = h * frac
  static const double playerRadius = 28;
  static const double ballRadius = 16;
  static const double playerSpeed = 350;
  static const double jumpVelocity = -780;
  static const double wallBounce = 0.7;
  static const double ballBounce = 0.82;
  static const double airDrag = 0.02;
  static const double headImpulse = 220; // keep touches low for dribbling
  static const double friction = 0.9; // ground horizontal damping
  static const double ballRestitutionCutoff = 4;
  static const double goalDepthFrac = 0.06; // as width fraction
  static const double goalHeightFrac =
      0.36; // as height fraction from ground up

  final AIDifficulty difficulty;
  final double aiPlayerSpeed;
  final double aiJumpVelocity;
  final double aiJumpCooldown;
  final double aiKp; // Proportional gain for smoother movement
  final double aiResponseAlpha;
  final double aiThinkInterval;
  final double aiPredictionTime;
  final double aiTrackingNoise;
  final double aiAttackBias;
  final double aiAttackOffset;
  final double aiMinPursuitFrac;
  final double aiMistakeChance;
  final double aiJumpChance;
  final double aiJumpWindow;

  GameConfig({required this.difficulty})
    : aiPlayerSpeed = _getAiPlayerSpeed(difficulty),
      aiJumpVelocity = _getAiJumpVelocity(difficulty),
      aiJumpCooldown = _getAiJumpCooldown(difficulty),
      aiKp = _getAiKp(difficulty),
      aiResponseAlpha = _getAiResponseAlpha(difficulty),
      aiThinkInterval = _getAiThinkInterval(difficulty),
      aiPredictionTime = _getAiPredictionTime(difficulty),
      aiTrackingNoise = _getAiTrackingNoise(difficulty),
      aiAttackBias = _getAiAttackBias(difficulty),
      aiAttackOffset = _getAiAttackOffset(difficulty),
      aiMinPursuitFrac = _getAiMinPursuitFrac(difficulty),
      aiMistakeChance = _getAiMistakeChance(difficulty),
      aiJumpChance = _getAiJumpChance(difficulty),
      aiJumpWindow = _getAiJumpWindow(difficulty);

  static double _tierScale(AIDifficulty difficulty, int unlockLevel) {
    if (difficulty.level < unlockLevel) {
      return 1.0;
    }
    return 1.15;
  }

  static double _getAiPlayerSpeed(AIDifficulty difficulty) {
    if (difficulty.level == 1) {
      return GameConfig.playerSpeed * 0.46;
    }
    return GameConfig.playerSpeed *
        (0.60 * _tierScale(difficulty, 3)).clamp(0.0, 1.08);
  }

  static double _getAiJumpVelocity(AIDifficulty difficulty) {
    if (difficulty.level == 1) {
      return GameConfig.jumpVelocity * 0.58;
    }
    return GameConfig.jumpVelocity *
        (0.72 * _tierScale(difficulty, 4)).clamp(0.0, 1.08);
  }

  static double _getAiJumpCooldown(AIDifficulty difficulty) {
    if (difficulty.level == 1) {
      return 1.70;
    }
    return (1.22 / _tierScale(difficulty, 5)).clamp(0.34, 1.22);
  }

  static double _getAiKp(AIDifficulty difficulty) {
    if (difficulty.level == 1) {
      return 0.62;
    }
    return (1.08 * _tierScale(difficulty, 10)).clamp(0.0, 2.70);
  }

  static double _getAiResponseAlpha(AIDifficulty difficulty) {
    if (difficulty.level == 1) {
      return 0.045;
    }
    return (0.084 * _tierScale(difficulty, 6)).clamp(0.0, 0.24);
  }

  static double _getAiThinkInterval(AIDifficulty difficulty) {
    if (difficulty.level == 1) {
      return 0.52;
    }
    return (0.32 / _tierScale(difficulty, 7)).clamp(0.07, 0.32);
  }

  static double _getAiPredictionTime(AIDifficulty difficulty) {
    if (difficulty.level == 1) {
      return 0.0;
    }
    return (0.045 * _tierScale(difficulty, 10)).clamp(0.0, 0.17);
  }

  static double _getAiTrackingNoise(AIDifficulty difficulty) {
    if (difficulty.level == 1) {
      return 170;
    }
    return (96 / _tierScale(difficulty, 10)).clamp(18.0, 96.0);
  }

  static double _getAiAttackBias(AIDifficulty difficulty) {
    if (difficulty.level == 1) {
      return 0.04;
    }
    return (0.12 * _tierScale(difficulty, 10)).clamp(0.0, 0.42);
  }

  static double _getAiAttackOffset(AIDifficulty difficulty) {
    if (difficulty.level == 1) {
      return 2;
    }
    return (18 * _tierScale(difficulty, 10)).clamp(0.0, 64.0);
  }

  static double _getAiMinPursuitFrac(AIDifficulty difficulty) {
    if (difficulty.level == 1) {
      return 0.62;
    }
    return (0.53 / _tierScale(difficulty, 10)).clamp(0.34, 0.53);
  }

  static double _getAiMistakeChance(AIDifficulty difficulty) {
    if (difficulty.level == 1) {
      return 0.42;
    }
    return (0.24 / _tierScale(difficulty, 8)).clamp(0.03, 0.24);
  }

  static double _getAiJumpChance(AIDifficulty difficulty) {
    if (difficulty.level == 1) {
      return 0.18;
    }
    return (0.42 * _tierScale(difficulty, 9)).clamp(0.0, 0.92);
  }

  static double _getAiJumpWindow(AIDifficulty difficulty) {
    if (difficulty.level == 1) {
      return 22;
    }
    return (36 * _tierScale(difficulty, 10)).clamp(0.0, 64.0);
  }
}

class PlayerState {
  Offset pos; // center
  Offset vel;
  bool grounded;
  final Color color;
  final MarbleExpression expression;
  PlayerState({
    required this.pos,
    this.vel = Offset.zero,
    this.grounded = true,
    required this.color,
    this.expression = MarbleExpression.neutral,
  });
}

class FaceMood {
  MarbleExpression left = MarbleExpression.mischievous;
  MarbleExpression right = MarbleExpression.mischievous;
  double leftTimer = 0;
  double rightTimer = 0;

  void setLeft(MarbleExpression e, double t) {
    left = e;
    leftTimer = t;
  }

  void setRight(MarbleExpression e, double t) {
    right = e;
    rightTimer = t;
  }

  void tick(double dt) {
    if (leftTimer > 0) {
      leftTimer -= dt;
      if (leftTimer <= 0) left = MarbleExpression.neutral;
    }
    if (rightTimer > 0) {
      rightTimer -= dt;
      if (rightTimer <= 0) right = MarbleExpression.neutral;
    }
  }
}

class BallState {
  Offset pos;
  Offset vel;
  BallState({required this.pos, this.vel = Offset.zero});
}

class GameScore {
  int left = 0;
  int right = 0;
}

class GameState {
  Size size = Size.zero;
  late double groundY;
  late Rect leftGoal;
  late Rect rightGoal;
  late double worldWidth;
  // Crossbar removed in this version (simple goal)

  final PlayerState leftPlayer;
  final PlayerState rightPlayer;
  final BallState ball;
  final GameScore score = GameScore();
  final FaceMood mood = FaceMood();
  final GameConfig config;

  bool running = false;
  bool celebrating = false;
  bool lastScorerLeft = false;
  double celebrationTime = 0.0;
  double _aiJumpCooldown = 0.0;
  double _aiThinkCooldown = 0.0;
  double _aiTargetX = 0.0;
  bool _leftJumpHeld = false;
  double _ballPinchJumpCooldown = 0.0;
  double _counterAttackTime = 0.0;
  double _counterDecisionCooldown = 0.0;
  double netWobbleLeftTime = 0.0;
  double netWobbleRightTime = 0.0;
  final math.Random _rng;
  final PlayerBehaviorAnalyzer behaviorAnalyzer = PlayerBehaviorAnalyzer();
  // No goal freeze / last scorer in simple goal mode

  GameState({
    required this.size,
    required this.leftPlayer,
    required this.rightPlayer,
    required this.ball,
    required AIDifficulty aiDifficulty,
    int? randomSeed,
  }) : config = GameConfig(difficulty: aiDifficulty),
       _rng = math.Random(randomSeed) {
    _configure(size);
    _placeIdleObjects();
    _aiTargetX = rightPlayer.pos.dx;
  }

  PlayerAnalysis get playerAnalysis => behaviorAnalyzer.analysis;

  AiDecisionSnapshot get aiDecision => AiDecisionSnapshot(
    targetX: _aiTargetX,
    counterAttackActive: _counterAttackTime > 0,
    jumpCooldownSeconds: math.max(0, _aiJumpCooldown),
    strategy: playerAnalysis.strategy,
  );

  void resize(Size newSize) {
    size = newSize;
    _configure(newSize);
    if (!running && !celebrating) {
      _placeIdleObjects();
    }
  }

  void _configure(Size s) {
    groundY = s.height * GameConfig.groundFrac;
    worldWidth = s.width * 2.6; // extend world so user can pan to see goals
    final goalDepth = s.width * GameConfig.goalDepthFrac;
    final goalHeight = s.height * GameConfig.goalHeightFrac;
    leftGoal = Rect.fromLTWH(0, groundY - goalHeight, goalDepth, goalHeight);
    rightGoal = Rect.fromLTWH(
      worldWidth - goalDepth,
      groundY - goalHeight,
      goalDepth,
      goalHeight,
    );
    // Crossbars not used in simple mode
  }

  void _placeIdleObjects() {
    _leftJumpHeld = false;
    leftPlayer.pos = Offset(
      worldWidth * 0.42,
      groundY - GameConfig.playerRadius,
    );
    leftPlayer.vel = Offset.zero;
    leftPlayer.grounded = true;

    rightPlayer.pos = Offset(
      worldWidth * 0.58,
      groundY - GameConfig.playerRadius,
    );
    rightPlayer.vel = Offset.zero;
    rightPlayer.grounded = true;

    ball.pos = Offset(worldWidth * 0.5, groundY - GameConfig.ballRadius);
    ball.vel = Offset.zero;
  }

  void kickoff() {
    running = true;
    _leftJumpHeld = false;
    // Reset positions
    leftPlayer.pos = Offset(
      worldWidth * 0.42,
      groundY - GameConfig.playerRadius,
    );
    leftPlayer.vel = Offset.zero;
    leftPlayer.grounded = true;
    rightPlayer.pos = Offset(
      worldWidth * 0.58,
      groundY - GameConfig.playerRadius,
    );
    rightPlayer.vel = Offset.zero;
    rightPlayer.grounded = true;
    ball.pos = Offset(
      worldWidth * 0.5,
      groundY - GameConfig.playerRadius - GameConfig.ballRadius - 16,
    );
    ball.vel = const Offset(0, -340);
    _aiJumpCooldown = 0.0;
    _aiThinkCooldown = 0.0;
    _aiTargetX = rightPlayer.pos.dx;
    _counterAttackTime = 0;
    _counterDecisionCooldown = 0;
    behaviorAnalyzer.reset();
  }

  void update(
    double dt, {
    bool leftLeft = false,
    bool leftRight = false,
    bool leftJump = false,
  }) {
    if (!running) return;
    mood.tick(dt);
    if (_aiJumpCooldown > 0) _aiJumpCooldown -= dt;
    if (_aiThinkCooldown > 0) _aiThinkCooldown -= dt;
    if (_ballPinchJumpCooldown > 0) _ballPinchJumpCooldown -= dt;
    if (_counterAttackTime > 0) _counterAttackTime -= dt;
    if (_counterDecisionCooldown > 0) _counterDecisionCooldown -= dt;
    final leftJumpPressedThisFrame = leftJump && !_leftJumpHeld;
    _leftJumpHeld = leftJump;
    // Net wobble decay timers
    if (netWobbleLeftTime > 0) {
      netWobbleLeftTime = (netWobbleLeftTime - dt).clamp(0, 10);
    }
    if (netWobbleRightTime > 0) {
      netWobbleRightTime = (netWobbleRightTime - dt).clamp(0, 10);
    }

    // Celebration state: pause gameplay briefly with small hop
    if (celebrating) {
      celebrationTime -= dt;
      // Gentle hop effect for scorer
      final hop = (math.sin((1.0 - celebrationTime) * 18.0) * 60)
          .clamp(0, 60)
          .toDouble();
      if (lastScorerLeft) {
        leftPlayer.pos = Offset(
          leftPlayer.pos.dx,
          (groundY - GameConfig.playerRadius) - hop,
        );
      } else {
        rightPlayer.pos = Offset(
          rightPlayer.pos.dx,
          (groundY - GameConfig.playerRadius) - hop,
        );
      }
      if (celebrationTime <= 0) {
        celebrating = false;
        // Kickoff to the side that conceded
        _centerKick(toRight: lastScorerLeft);
      }
      return; // skip normal update while celebrating
    }

    // Left player input (instant response)
    double axL = 0;
    if (leftLeft) {
      axL -= GameConfig.playerSpeed;
    } else if (leftRight) {
      axL += GameConfig.playerSpeed;
    }
    leftPlayer.vel = Offset(axL, leftPlayer.vel.dy);
    if (leftJumpPressedThisFrame && leftPlayer.grounded) {
      leftPlayer.vel = Offset(leftPlayer.vel.dx, GameConfig.jumpVelocity);
      leftPlayer.grounded = false;
    }

    final nearBallForAnalysis =
        (ball.pos - leftPlayer.pos).distance <=
        GameConfig.playerRadius + GameConfig.ballRadius + 32;
    behaviorAnalyzer.record(
      dt: dt,
      normalizedPosition: leftPlayer.pos.dx / worldWidth,
      horizontalVelocity: leftPlayer.vel.dx,
      movingForward: leftRight && !leftLeft,
      jumped: leftJumpPressedThisFrame,
      nearBall: nearBallForAnalysis,
    );

    _updateRightAi(dt);

    // Integrate players
    _integratePlayer(leftPlayer, dt);
    _integratePlayer(rightPlayer, dt);

    // Player vs Player body collision (simple elastic response)
    _handlePlayersCollision();

    // Ball physics
    _integrateBall(dt);
    // No crossbar collisions in simple mode

    // Collisions ball <-> players (heading)
    _handleBallPlayer(leftPlayer);
    _handleBallPlayer(rightPlayer, isLeft: false);
    _handleGroundPinchBallJump();
    _applyRightAiDribbleControl(dt);

    // Goals / scoring
    _checkGoals();
  }

  void _integratePlayer(PlayerState p, double dt) {
    // Gravity
    p.vel = Offset(p.vel.dx, p.vel.dy + GameConfig.gravity * dt);
    // Integrate
    p.pos += p.vel * dt;

    // Ground
    final yBottom = groundY - GameConfig.playerRadius;
    if (p.pos.dy >= yBottom) {
      p.pos = Offset(p.pos.dx, yBottom);
      p.vel = Offset(p.vel.dx * GameConfig.friction, 0);
      p.grounded = true;
    } else {
      p.grounded = false;
    }

    // Walls
    if (p.pos.dx < GameConfig.playerRadius) {
      p.pos = Offset(GameConfig.playerRadius, p.pos.dy);
    }
    if (p.pos.dx > worldWidth - GameConfig.playerRadius) {
      p.pos = Offset(worldWidth - GameConfig.playerRadius, p.pos.dy);
    }
  }

  void _updateRightAi(double dt) {
    final adaptive = playerAnalysis.strategy;
    final difficultyLevel = config.difficulty.level;
    final nearBall =
        (ball.pos.dx - rightPlayer.pos.dx).abs() <
        (GameConfig.playerRadius + GameConfig.ballRadius + 18);
    final hasBallControl =
        nearBall &&
        ball.pos.dx < rightPlayer.pos.dx + GameConfig.playerRadius * 0.65;
    if (_aiThinkCooldown <= 0 || nearBall) {
      _aiTargetX = _computeAiTargetX();
      _aiThinkCooldown = math.max(
        config.aiThinkInterval * (nearBall ? 0.45 : 1.0),
        0.02,
      );
    }

    final dx = _aiTargetX - rightPlayer.pos.dx;
    final deadZone = 4.0 + config.aiTrackingNoise * 0.02;
    final aiMoveCap =
        config.aiPlayerSpeed * (1.18 + config.aiAttackBias * 0.24);
    double desiredVx = 0.0;
    if (dx.abs() > deadZone) {
      desiredVx = (dx * config.aiKp).clamp(-aiMoveCap, aiMoveCap);
    }

    final ballIsLeftOfAi =
        ball.pos.dx < rightPlayer.pos.dx + GameConfig.playerRadius * 0.4;
    final ballIsRightOfAi =
        ball.pos.dx > rightPlayer.pos.dx + GameConfig.playerRadius * 0.9;
    final veryEasy = difficultyLevel == 1;
    final veryEasyOnly = difficultyLevel == 1;
    final mediumOrBelow = difficultyLevel <= 5;
    final hardOrAbove = difficultyLevel >= 7;
    final counterOpportunity =
        ball.vel.dx > 80 && ball.pos.dx > worldWidth * 0.48;
    if (counterOpportunity && _counterDecisionCooldown <= 0) {
      _counterAttackTime = _rng.nextDouble() < adaptive.counterAttackChance
          ? 1.35
          : 0;
      _counterDecisionCooldown = 1.8;
    }
    final rightSideLandingTarget =
        (ball.pos.dx +
                GameConfig.playerRadius * 2.05 +
                GameConfig.ballRadius * 1.45 +
                34 +
                config.aiAttackBias * 18)
            .clamp(
              GameConfig.playerRadius,
              worldWidth - GameConfig.playerRadius,
            );
    final needsRightSideLanding =
        nearBall &&
        ballIsRightOfAi &&
        rightPlayer.pos.dx <
            rightSideLandingTarget - GameConfig.playerRadius * 0.18;
    final rightTurnLine = worldWidth * 0.78;
    final forcingTurnLeft =
        ball.pos.dx > rightTurnLine &&
        ball.pos.dx >= rightPlayer.pos.dx - GameConfig.playerRadius * 0.2;
    final turnSetupTarget =
        (ball.pos.dx +
                GameConfig.playerRadius * 2.45 +
                GameConfig.ballRadius * 1.85 +
                68 +
                config.aiAttackBias * 28)
            .clamp(
              GameConfig.playerRadius,
              worldWidth - GameConfig.playerRadius,
            );
    if (hasBallControl && ballIsLeftOfAi) {
      final pushSpeed = -aiMoveCap * (0.9 + config.aiAttackBias * 0.16);
      desiredVx = math.min(desiredVx, pushSpeed);
    } else if (needsRightSideLanding && !veryEasyOnly) {
      _aiTargetX = math.max(_aiTargetX, rightSideLandingTarget);
      desiredVx = math.max(
        desiredVx,
        aiMoveCap * (1.26 + config.aiAttackBias * 0.18),
      );
      if (rightPlayer.grounded && _aiJumpCooldown <= 0) {
        rightPlayer.vel = Offset(
          aiMoveCap * (1.72 + config.aiAttackBias * 0.18),
          config.aiJumpVelocity * (veryEasy ? 0.94 : 1.0),
        );
        rightPlayer.grounded = false;
        _aiJumpCooldown = config.aiJumpCooldown * 0.74;
      }
    } else if (nearBall && ballIsRightOfAi) {
      desiredVx = math.max(
        desiredVx,
        aiMoveCap * (0.72 + config.aiAttackBias * 0.12),
      );
    }

    if (forcingTurnLeft && hardOrAbove) {
      _aiTargetX = turnSetupTarget;
      final setupDx = turnSetupTarget - rightPlayer.pos.dx;
      if (setupDx > 6) {
        desiredVx = math.max(
          desiredVx,
          aiMoveCap * (1.28 + config.aiAttackBias * 0.14),
        );
      } else {
        desiredVx = math.min(
          desiredVx,
          -aiMoveCap * (0.92 + config.aiAttackBias * 0.08),
        );
      }
      final readyToTurnLeft =
          rightPlayer.pos.dx >
          ball.pos.dx +
              GameConfig.playerRadius * 1.45 +
              GameConfig.ballRadius * 1.1;
      final canSetupJump =
          rightPlayer.grounded &&
          _aiJumpCooldown <= 0 &&
          rightPlayer.pos.dx < turnSetupTarget - GameConfig.playerRadius * 0.25;
      if (canSetupJump) {
        rightPlayer.vel = Offset(
          aiMoveCap * (1.85 + config.aiAttackBias * 0.22),
          config.aiJumpVelocity * (veryEasy ? 0.96 : 1.02),
        );
        rightPlayer.grounded = false;
        _aiJumpCooldown = config.aiJumpCooldown * 0.68;
      } else if (readyToTurnLeft &&
          rightPlayer.grounded &&
          _aiJumpCooldown <= 0) {
        rightPlayer.vel = Offset(
          -aiMoveCap * 1.02,
          config.aiJumpVelocity * (veryEasy ? 0.88 : 0.94),
        );
        rightPlayer.grounded = false;
        _aiJumpCooldown = config.aiJumpCooldown * 0.82;
      }
    }

    final recoverRightSide =
        !mediumOrBelow &&
        !nearBall &&
        ball.pos.dx > rightPlayer.pos.dx - GameConfig.playerRadius * 0.4;
    if (recoverRightSide) {
      desiredVx = math.max(
        desiredVx,
        aiMoveCap * (0.88 + config.aiAttackBias * 0.08),
      );
      if (veryEasy && rightPlayer.grounded && _aiJumpCooldown <= 0) {
        rightPlayer.vel = Offset(desiredVx, config.aiJumpVelocity * 0.88);
        rightPlayer.grounded = false;
        _aiJumpCooldown = config.aiJumpCooldown * 0.8;
      }
    }

    final finishZone = ball.pos.dx < size.width * 0.24;
    if (finishZone && hasBallControl) {
      desiredVx = math.min(
        desiredVx,
        -aiMoveCap * (1.0 + config.aiAttackBias * 0.12),
      );
    }

    final carryLeft =
        hasBallControl &&
        ball.pos.dx < rightPlayer.pos.dx + GameConfig.playerRadius * 0.55;
    if (carryLeft) {
      desiredVx = math.min(
        desiredVx,
        -aiMoveCap * (0.96 + config.aiAttackBias * 0.12),
      );
    }
    if (_counterAttackTime > 0 && ball.pos.dx <= rightPlayer.pos.dx + 24) {
      desiredVx = math.min(desiredVx, -aiMoveCap * 1.16);
    }

    final newVx =
        rightPlayer.vel.dx +
        (desiredVx - rightPlayer.vel.dx) *
            (config.aiResponseAlpha + 0.08).clamp(0.0, 0.55);
    rightPlayer.vel = Offset(newVx, rightPlayer.vel.dy);

    final predictedBallY =
        ball.pos.dy +
        ball.vel.dy *
            math.max(0, config.aiPredictionTime + adaptive.jumpLeadSeconds);
    final closeEnoughX =
        (ball.pos.dx - rightPlayer.pos.dx).abs() <
        (config.aiJumpWindow + 10 + config.aiAttackBias * 14) *
            adaptive.jumpChanceScale;
    final ballHighEnough = predictedBallY < groundY - 70;
    final urgentSave = ball.vel.dx > 160 && ball.pos.dx > worldWidth * 0.68;
    final groundedBall =
        ball.pos.dy > groundY - GameConfig.ballRadius - 4 &&
        ball.vel.dy.abs() < 40;
    final attackJump =
        ball.pos.dx < rightPlayer.pos.dx - 6 &&
        ball.pos.dx < size.width * 0.74 &&
        predictedBallY < groundY - 6;
    final pressureJump =
        !veryEasyOnly &&
        nearBall &&
        ball.pos.dx < rightPlayer.pos.dx + 10 &&
        ball.pos.dx < size.width * 0.7;
    final jumpRoll = _rng.nextDouble();

    if (rightPlayer.grounded &&
        _aiJumpCooldown <= 0 &&
        closeEnoughX &&
        (!groundedBall || attackJump) &&
        (ballHighEnough || urgentSave || attackJump || pressureJump) &&
        (jumpRoll <=
                (config.aiJumpChance * adaptive.jumpChanceScale).clamp(0, 1) ||
            urgentSave ||
            attackJump ||
            pressureJump)) {
      rightPlayer.vel = Offset(rightPlayer.vel.dx, config.aiJumpVelocity);
      rightPlayer.grounded = false;
      _aiJumpCooldown = config.aiJumpCooldown * adaptive.jumpCooldownScale;
    }
  }

  double _computeAiTargetX() {
    final difficultyLevel = config.difficulty.level;
    final mediumOrBelow = difficultyLevel <= 5;
    final predictedX = (ball.pos.dx + ball.vel.dx * config.aiPredictionTime)
        .clamp(GameConfig.ballRadius, worldWidth - GameConfig.ballRadius);
    final pursueFloor = size.width * config.aiMinPursuitFrac;
    final closeContest =
        (predictedX - rightPlayer.pos.dx).abs() <
        size.width * (mediumOrBelow ? 0.24 : 0.30);
    final committedChase =
        predictedX > pursueFloor ||
        closeContest ||
        ball.vel.dx < -25 ||
        difficultyLevel <= 3;
    final chaseX = committedChase ? predictedX : pursueFloor;

    var behindOffset =
        (36 + config.aiAttackOffset * (0.34 + config.aiAttackBias * 0.16)) *
        playerAnalysis.strategy.defenseDistanceScale;
    if (closeContest) {
      behindOffset *= 0.78;
    }
    if (chaseX < size.width * 0.42) {
      behindOffset *= 0.62;
    }
    if (ball.vel.dx < -60) {
      behindOffset += 10;
    }

    var target = chaseX + behindOffset;
    final baseNoise =
        (_rng.nextDouble() * 2 - 1) *
        config.aiTrackingNoise *
        (closeContest ? 0.35 : 0.7);
    final mistakeNoise = _rng.nextDouble() < config.aiMistakeChance
        ? (_rng.nextDouble() * 2 - 1) * (18 + config.aiTrackingNoise * 0.9)
        : 0.0;
    target += baseNoise + mistakeNoise;
    if (mediumOrBelow) {
      target += (_rng.nextDouble() * 2 - 1) * 16;
    }

    return target.clamp(
      GameConfig.playerRadius,
      worldWidth - GameConfig.playerRadius,
    );
  }

  void _applyRightAiDribbleControl(double dt) {
    final adaptive = playerAnalysis.strategy;
    final dx = ball.pos.dx - rightPlayer.pos.dx;
    final dy = ball.pos.dy - rightPlayer.pos.dy;
    final difficultyLevel = config.difficulty.level;
    final veryEasy = difficultyLevel == 1;
    final easyOnly = difficultyLevel == 1;
    final mediumOrBelow = difficultyLevel <= 5;
    final rightTurnLine = worldWidth * 0.78;
    final forcingTurnLeft =
        !mediumOrBelow &&
        ball.pos.dx > rightTurnLine &&
        ball.pos.dx >= rightPlayer.pos.dx - GameConfig.playerRadius * 0.2;
    final closeToBall =
        dx.abs() < (GameConfig.playerRadius + GameConfig.ballRadius + 24) &&
        dy.abs() < (GameConfig.playerRadius + GameConfig.ballRadius + 22);
    final ballControllable =
        ball.pos.dx < rightPlayer.pos.dx + GameConfig.playerRadius * 0.9;
    if (veryEasy && closeToBall && dx > 0 && _rng.nextDouble() > 0.70) {
      ball.vel = Offset(
        math.min(ball.vel.dx, -90.0),
        math.min(ball.vel.dy, -18.0),
      );
      return;
    }
    if (!closeToBall || !ballControllable) {
      return;
    }

    if (forcingTurnLeft) {
      final aiIsRightOfBall =
          rightPlayer.pos.dx >
          ball.pos.dx + GameConfig.playerRadius + GameConfig.ballRadius * 0.35;
      if (aiIsRightOfBall) {
        ball.vel = Offset(
          -math.max(260.0, 220.0 + config.aiAttackBias * 180.0),
          math.min(ball.vel.dy, -22.0),
        );
      } else {
        ball.vel = Offset(
          math.max(ball.vel.dx, 140.0 + config.aiAttackBias * 90.0),
          math.min(ball.vel.dy, -12.0),
        );
      }
      return;
    }

    var controlStrength = 0.08 + config.aiAttackBias * 0.14;
    if (mediumOrBelow) {
      controlStrength *= 0.62;
    }
    if (easyOnly) {
      controlStrength *= 0.45;
    }
    if (_rng.nextDouble() < config.aiMistakeChance * math.min(1.0, dt * 18)) {
      controlStrength *= 0.35;
    }
    final desiredBallX =
        rightPlayer.pos.dx -
        (GameConfig.playerRadius + GameConfig.ballRadius - 6);
    final newBallX =
        ball.pos.dx +
        (desiredBallX - ball.pos.dx) *
            (controlStrength + dt * (1.6 + config.aiAttackBias * 2.0));

    ball.pos = Offset(
      newBallX.clamp(GameConfig.ballRadius, worldWidth - GameConfig.ballRadius),
      ball.pos.dy,
    );

    var dribbleSpeed =
        -150 - config.aiAttackBias * 220 - rightPlayer.vel.dx.abs() * 0.16;
    if (easyOnly) {
      dribbleSpeed *= 0.50;
    }
    final dribbleLift = ball.vel.dy;
    ball.vel = Offset(math.min(ball.vel.dx, dribbleSpeed), dribbleLift);
    if (veryEasy) {
      ball.vel = Offset(math.min(ball.vel.dx, -95.0), dribbleLift);
    }

    final finishShot =
        difficultyLevel >= 4 &&
        ball.pos.dx < size.width * 0.22 &&
        dx < GameConfig.playerRadius * 0.35 &&
        dx > -(GameConfig.playerRadius + GameConfig.ballRadius + 18);
    if (finishShot) {
      final shot = switch (adaptive.shotStrategy) {
        AiShotStrategy.lowCounter => const Offset(1.12, 0.45),
        AiShotStrategy.direct => const Offset(1.18, 0.82),
        AiShotStrategy.lob => const Offset(0.88, 2.25),
        AiShotStrategy.balanced => const Offset(1, 1),
      };
      ball.vel = Offset(
        (-520 - config.aiAttackBias * 180) * shot.dx,
        (-18 - config.aiAttackBias * 18) * shot.dy,
      );
      if (rightPlayer.grounded && _aiJumpCooldown <= 0) {
        rightPlayer.vel = Offset(rightPlayer.vel.dx, config.aiJumpVelocity);
        rightPlayer.grounded = false;
        _aiJumpCooldown = config.aiJumpCooldown;
      }
    }
  }

  void _integrateBall(double dt) {
    // Air drag
    final drag = 1 - GameConfig.airDrag;
    ball.vel = Offset(
      ball.vel.dx * drag,
      (ball.vel.dy + GameConfig.gravity * dt) * drag,
    );
    ball.pos += ball.vel * dt;

    // Floor
    final yFloor = groundY - GameConfig.ballRadius;
    if (ball.pos.dy >= yFloor) {
      ball.pos = Offset(ball.pos.dx, yFloor);
      final impactVy = ball.vel.dy.abs();
      final bouncedVy = impactVy < 90 ? 0.0 : -impactVy * GameConfig.ballBounce;
      ball.vel = Offset(ball.vel.dx * 0.97, bouncedVy);
      // friction at ground
      ball.vel = Offset(ball.vel.dx * 0.95, ball.vel.dy);
      if (ball.vel.dy.abs() < GameConfig.ballRestitutionCutoff) {
        ball.vel = Offset(ball.vel.dx, 0);
      }
      if (ball.vel.dx.abs() < 4) {
        ball.vel = Offset(0, ball.vel.dy);
      }
    }
    // Ceiling
    if (ball.pos.dy < GameConfig.ballRadius) {
      ball.pos = Offset(ball.pos.dx, GameConfig.ballRadius);
      ball.vel = Offset(ball.vel.dx, ball.vel.dy.abs());
    }
    // Walls
    if (ball.pos.dx < GameConfig.ballRadius) {
      ball.pos = Offset(GameConfig.ballRadius, ball.pos.dy);
      ball.vel = Offset(ball.vel.dx.abs() * GameConfig.wallBounce, ball.vel.dy);
    }
    if (ball.pos.dx > worldWidth - GameConfig.ballRadius) {
      ball.pos = Offset(worldWidth - GameConfig.ballRadius, ball.pos.dy);
      ball.vel = Offset(
        -ball.vel.dx.abs() * GameConfig.wallBounce,
        ball.vel.dy,
      );
    }
  }

  void _handlePlayersCollision() {
    final r = GameConfig.playerRadius;
    final minDist = r * 2;
    Offset d = rightPlayer.pos - leftPlayer.pos;
    double dist2 = d.dx * d.dx + d.dy * d.dy;
    if (dist2 >= minDist * minDist) return;
    double dist = math.sqrt(dist2.clamp(1e-6, double.infinity));
    // Normal from left -> right
    final n = Offset(d.dx / dist, d.dy / dist);
    final overlap = (minDist - dist);
    // Bias separation toward the AI so the human player is not shoved around.
    leftPlayer.pos -= n * (overlap * 0.18);
    rightPlayer.pos += n * (overlap * 0.82);

    // Keep the body collision soft so contact does not throw the player backward.
    final rel = rightPlayer.vel - leftPlayer.vel;
    final vRel = rel.dx * n.dx + rel.dy * n.dy;
    if (vRel < 0) {
      const e = 0.08;
      final j = -(1 + e) * vRel / 2.0;
      leftPlayer.vel -= n * (j * 0.18);
      rightPlayer.vel += n * (j * 0.82);
      final t = Offset(-n.dy, n.dx);
      final vT = (rel.dx * t.dx + rel.dy * t.dy) * 0.08;
      leftPlayer.vel += t * (vT * 0.15);
      rightPlayer.vel -= t * (vT * 0.85);
      if (leftPlayer.grounded && leftPlayer.vel.dx.abs() < 70) {
        leftPlayer.vel = Offset(0, leftPlayer.vel.dy);
      }
    }
    leftPlayer.vel = Offset(
      leftPlayer.vel.dx.clamp(-GameConfig.playerSpeed, GameConfig.playerSpeed),
      leftPlayer.vel.dy,
    );

    // Keep within bounds and above ground
    final yBottom = groundY - r;
    leftPlayer.pos = Offset(
      leftPlayer.pos.dx.clamp(r, worldWidth - r),
      math.min(leftPlayer.pos.dy, yBottom),
    );
    rightPlayer.pos = Offset(
      rightPlayer.pos.dx.clamp(r, worldWidth - r),
      math.min(rightPlayer.pos.dy, yBottom),
    );
  }

  void _handleBallPlayer(PlayerState p, {bool isLeft = true}) {
    final rSum = GameConfig.playerRadius + GameConfig.ballRadius;
    final delta = ball.pos - p.pos;
    final dist2 = delta.dx * delta.dx + delta.dy * delta.dy;
    if (dist2 < rSum * rSum) {
      final dist = math.sqrt(dist2.clamp(1e-6, double.infinity));
      final n = Offset(delta.dx / dist, delta.dy / dist);
      // Separate
      final overlap = rSum - dist;
      ball.pos += n * overlap;
      // Reflect ball velocity along normal and add heading impulse upward
      final rel = ball.vel - p.vel;
      final proj = rel.dx * n.dx + rel.dy * n.dy;
      var v = rel - n * (1.2 * proj);
      final headContact =
          delta.dy < -(GameConfig.playerRadius * 0.3) && n.dy < -0.42;
      final impactSpeed = math.max(0.0, -proj);
      final sideWeight = n.dx.abs();
      final topWeight = (-n.dy).clamp(0.0, 1.0).toDouble();
      // Blend impact speed and contact angle so the pop feels more organic.
      final touchLift =
          (30.0 +
                  impactSpeed * 0.18 +
                  sideWeight * 20.0 +
                  topWeight * 34.0 +
                  (p.grounded ? 0.0 : 12.0))
              .clamp(48.0, headContact ? 124.0 : 102.0)
              .toDouble();
      v += Offset(n.dx * 52, -touchLift);
      v += Offset(p.vel.dx * 0.18, p.grounded ? 0 : p.vel.dy * 0.03);
      final nearGround = ball.pos.dy > groundY - GameConfig.ballRadius - 10;
      final glancingContact = n.dx.abs() > 0.72 && delta.dy.abs() < rSum * 0.72;
      final sideSwipeSpeed = (ball.vel.dx - p.vel.dx).abs();
      if (nearGround && glancingContact && sideSwipeSpeed > 45) {
        final shortHop = (44.0 + sideSwipeSpeed * 0.16 + impactSpeed * 0.12)
            .clamp(46.0, 96.0)
            .toDouble();
        v += Offset(0, -shortHop);
        v += Offset(n.dx * 26.0, 0);
      }
      final risingBall = ball.vel.dy < -70;
      final risingGraze =
          risingBall &&
          glancingContact &&
          delta.dy.abs() < rSum * 0.86 &&
          sideSwipeSpeed > 24;
      if (risingGraze) {
        final risingLift =
            (36.0 + ball.vel.dy.abs() * 0.14 + sideSwipeSpeed * 0.12)
                .clamp(42.0, 112.0)
                .toDouble();
        v += Offset(n.dx * 18.0, -risingLift);
      }
      if (!isLeft) {
        final adaptive = playerAnalysis.strategy;
        final contactShot = switch (adaptive.shotStrategy) {
          AiShotStrategy.lowCounter => const Offset(1.12, 0.55),
          AiShotStrategy.direct => const Offset(1.18, 0.9),
          AiShotStrategy.lob => const Offset(0.86, 1.7),
          AiShotStrategy.balanced => const Offset(1, 1),
        };
        final difficultyScale =
            config.difficulty.level / AIDifficulty.values.length;
        final shotBiasX =
            80 + difficultyScale * 110 + config.aiAttackBias * 180;
        final shotBiasY = headContact
            ? -6.0 * difficultyScale
            : (p.grounded ? 4.0 * difficultyScale : 0.0);
        v += Offset(-shotBiasX * contactShot.dx, shotBiasY);
        if (!headContact && contactShot.dy != 1) {
          v = Offset(v.dx, math.min(v.dy, -42 * contactShot.dy));
        }
        if (config.difficulty.level == 1 && !headContact) {
          v = Offset(math.min(v.dx, -70.0), math.min(v.dy, 18.0));
        }
        if (!headContact &&
            ball.pos.dy > groundY - GameConfig.ballRadius - 12) {
          ball.pos = Offset(ball.pos.dx, groundY - GameConfig.ballRadius);
          v = Offset(v.dx, math.max(v.dy, -24));
        }
      }
      if (headContact) {
        final headLift =
            (185.0 + impactSpeed * 0.52 + (p.grounded ? 56.0 : 34.0))
                .clamp(210.0, isLeft ? 310.0 : 285.0)
                .toDouble();
        v = Offset(v.dx, math.min(v.dy, -headLift));
        if (ball.vel.dy > -30) {
          v = Offset(v.dx, math.min(v.dy, -(headLift + 26.0)));
        }
        if (isLeft) {
          final rightUpHeader = p.vel.dx > 24.0 && p.vel.dy < -24.0;
          if (rightUpHeader) {
            final headerPushX = (195.0 + impactSpeed * 0.20 + p.vel.dx * 0.42)
                .clamp(210.0, 340.0)
                .toDouble();
            final headerLiftY = (headLift + (-p.vel.dy) * 0.16)
                .clamp(225.0, 330.0)
                .toDouble();
            v = Offset(
              math.max(v.dx, headerPushX),
              math.min(v.dy, -headerLiftY),
            );
          }
          final rightPush = (170.0 + impactSpeed * 0.24 + p.vel.dx.abs() * 0.35)
              .clamp(190.0, 320.0)
              .toDouble();
          v = Offset(math.max(v.dx, rightPush), v.dy);
        }
      }
      if (n.dx.abs() > 0.12 && v.dx * n.dx < 0) {
        v = Offset(n.dx * math.max(v.dx.abs(), 120), v.dy);
      }
      final minVertical = headContact
          ? (isLeft ? -310.0 : -285.0)
          : (isLeft ? -210.0 : -185.0);
      ball.vel = Offset(v.dx.clamp(-720, 720), v.dy.clamp(minVertical, 720));
      // Set temporary expressions
      if (isLeft) {
        mood.setLeft(MarbleExpression.mischievous, 0.6);
      } else {
        mood.setRight(MarbleExpression.mischievous, 0.6);
      }
    }
  }

  void _handleGroundPinchBallJump() {
    if (_ballPinchJumpCooldown > 0) return;

    final contactRadius = GameConfig.playerRadius + GameConfig.ballRadius + 4;
    final leftContact = (ball.pos - leftPlayer.pos).distance <= contactRadius;
    final rightContact = (ball.pos - rightPlayer.pos).distance <= contactRadius;
    final playersClose =
        (rightPlayer.pos - leftPlayer.pos).distance <=
        (GameConfig.playerRadius * 2 + GameConfig.ballRadius * 1.9);
    final ballBetweenPlayers =
        ball.pos.dx > math.min(leftPlayer.pos.dx, rightPlayer.pos.dx) &&
        ball.pos.dx < math.max(leftPlayer.pos.dx, rightPlayer.pos.dx);
    final verticalAligned =
        (ball.pos.dy - leftPlayer.pos.dy).abs() <
            GameConfig.playerRadius * 0.95 &&
        (ball.pos.dy - rightPlayer.pos.dy).abs() <
            GameConfig.playerRadius * 0.95;
    final trappedHorizontally =
        ball.vel.dx.abs() < 140 ||
        (leftPlayer.vel.dx - rightPlayer.vel.dx).abs() > 40;

    if (!leftContact ||
        !rightContact ||
        !playersClose ||
        !ballBetweenPlayers ||
        !verticalAligned ||
        !trappedHorizontally) {
      return;
    }

    final liftY = math.min(
      ball.pos.dy,
      math.min(leftPlayer.pos.dy, rightPlayer.pos.dy) -
          GameConfig.playerRadius -
          GameConfig.ballRadius * 0.45,
    );
    ball.pos = Offset(ball.pos.dx, liftY);
    ball.vel = Offset(ball.vel.dx * 0.28, math.min(ball.vel.dy, -300.0));
    _ballPinchJumpCooldown = 0.18;
  }

  void _checkGoals() {
    // Simple contains-based goal detection
    if (leftGoal.contains(ball.pos)) {
      score.right += 1;
      mood.setRight(MarbleExpression.happy, 1.2);
      mood.setLeft(MarbleExpression.angry, 1.0);
      netWobbleLeftTime = 0.8;
      celebrating = true;
      lastScorerLeft = false;
      celebrationTime = 1.0;
    }
    if (rightGoal.contains(ball.pos)) {
      score.left += 1;
      mood.setLeft(MarbleExpression.happy, 1.2);
      mood.setRight(MarbleExpression.angry, 1.0);
      netWobbleRightTime = 0.8;
      celebrating = true;
      lastScorerLeft = true;
      celebrationTime = 1.0;
    }
  }

  void _centerKick({required bool toRight}) {
    ball.pos = Offset(
      worldWidth * 0.5,
      groundY - GameConfig.playerRadius - GameConfig.ballRadius - 16,
    );
    ball.vel = Offset((toRight ? 150 : -150), -340);
    leftPlayer.pos = Offset(
      worldWidth * 0.2,
      groundY - GameConfig.playerRadius,
    );
    rightPlayer.pos = Offset(
      worldWidth * 0.8,
      groundY - GameConfig.playerRadius,
    );
    leftPlayer.vel = Offset.zero;
    rightPlayer.vel = Offset.zero;
    leftPlayer.grounded = true;
    rightPlayer.grounded = true;
    _aiJumpCooldown = 0.0;
    _aiThinkCooldown = 0.0;
    _aiTargetX = rightPlayer.pos.dx;
    _counterAttackTime = 0;
    _counterDecisionCooldown = 0;
  }

  // Crossbar collision helpers removed in simple mode
}
