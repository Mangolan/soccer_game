import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../animal_player.dart';
import 'adaptive_ai.dart';
import 'game_logic.dart';

enum WeatherType { dayClear, dayRain, cloudy, cloudyRain }

enum _TouchControl { left, right, jump }

class GameWidget extends StatefulWidget {
  final AnimalPlayer leftPlayer;
  final AnimalPlayer rightPlayer;
  final AIDifficulty aiDifficulty;
  final void Function(AIDifficulty nextDifficulty)? onAdvance;
  final void Function(AIDifficulty nextDifficulty)? onRetreat;

  const GameWidget({
    super.key,
    required this.leftPlayer,
    required this.rightPlayer,
    required this.aiDifficulty,
    this.onAdvance,
    this.onRetreat,
  });

  @override
  State<GameWidget> createState() => _GameWidgetState();
}

class _GameWidgetState extends State<GameWidget>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final Ticker _ticker;
  late GameState _game;
  double _cameraX = 0.0;
  double _time = 0.0;
  bool _advanced = false;
  bool _resultHandled = false;
  late WeatherType _weather;
  final Set<LogicalKeyboardKey> _pressedKeys = <LogicalKeyboardKey>{};
  bool _touchLeft = false;
  bool _touchRight = false;
  bool _touchJump = false;
  final Map<int, _TouchControl> _activeTouchPointers = <int, _TouchControl>{};

  bool _left = false;
  bool _right = false;
  bool _jump = false;

  WeatherType _randomWeather() {
    return WeatherType.dayClear;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _weather = _randomWeather();
    _game = GameState(
      size: const Size(360, 640),
      leftPlayer: PlayerState(pos: const Offset(100, 400), color: Colors.blue),
      rightPlayer: PlayerState(pos: const Offset(260, 400), color: Colors.red),
      ball: BallState(pos: const Offset(180, 300)),
      aiDifficulty: widget.aiDifficulty,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeShowOnboarding();
    });
    _ticker = createTicker((elapsed) {
      var dt = (_lastStamp == null)
          ? 0.016
          : (elapsed - _lastStamp!).inMicroseconds / 1e6;
      if (dt > 0.05) {
        dt = 0.05;
      }
      _lastStamp = elapsed;
      _game.update(dt, leftLeft: _left, leftRight: _right, leftJump: _jump);
      _time += dt;
      _handleMatchResult();
      final playersMidX =
          (_game.leftPlayer.pos.dx + _game.rightPlayer.pos.dx) * 0.5;
      final focusX =
          playersMidX * 0.62 +
          _game.ball.pos.dx * 0.38 +
          _game.ball.vel.dx * 0.04;
      final desired = focusX - (_game.size.width * 0.5);
      final maxCam = (_game.worldWidth - _game.size.width).clamp(
        0,
        double.infinity,
      );
      final target = desired.clamp(0, maxCam);
      _cameraX = _cameraX + (target - _cameraX) * 0.09;
      if (mounted) {
        setState(() {});
      }
    });
  }

  Duration? _lastStamp;

  void _handleMatchResult() {
    if (_resultHandled) {
      return;
    }

    if (_game.score.left >= 10 && _game.score.left > _game.score.right) {
      _resultHandled = true;
      _advanced = true;
      _ticker.stop();
      final next = _nextDifficulty(widget.aiDifficulty);
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && next != null && widget.onAdvance != null) {
            widget.onAdvance!(next);
          }
        });
      }
      return;
    }

    if (_game.score.right >= 10 && _game.score.right > _game.score.left) {
      _resultHandled = true;
      _ticker.stop();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showLoseDialog();
        }
      });
    }
  }

  Future<void> _maybeShowOnboarding() async {
    if (!mounted) {
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        final size = MediaQuery.of(ctx).size;
        final isLandscape = size.width > size.height;
        final bodyStyle = TextStyle(
          fontSize: isLandscape ? 14 : 15,
          height: 1.35,
        );
        return AlertDialog(
          insetPadding: EdgeInsets.symmetric(
            horizontal: isLandscape ? 80 : 24,
            vertical: isLandscape ? 24 : 32,
          ),
          title: const Text('\uAC8C\uC784 \uBC29\uBC95'),
          content: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isLandscape ? 420 : 320),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '\uC0C1\uB2E8 \uC2DC\uC791 \uBC84\uD2BC\uC744 \uB204\uB974\uBA74 \uACBD\uAE30\uAC00 \uC2DC\uC791\uB429\uB2C8\uB2E4.',
                  style: bodyStyle,
                ),
                const SizedBox(height: 8),
                Text(
                  '< > \uBC84\uD2BC\uC73C\uB85C \uC88C\uC6B0 \uC774\uB3D9',
                  style: bodyStyle,
                ),
                const SizedBox(height: 8),
                Text(
                  '\uC810\uD504 \uBC84\uD2BC\uC73C\uB85C \uC810\uD504',
                  style: bodyStyle,
                ),
                const SizedBox(height: 8),
                Text(
                  '\uBA3C\uC800 10\uC810\uC744 \uB0B4\uBA74 \uC2B9\uB9AC\uD569\uB2C8\uB2E4.',
                  style: bodyStyle,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('\uD655\uC778'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showLoseDialog() async {
    if (!mounted) {
      return;
    }
    final retreat = _previousDifficulty(widget.aiDifficulty);
    final size = MediaQuery.of(context).size;
    final compact = size.width < 760;
    final canRetreat = retreat != null && widget.onRetreat != null;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final dialogMaxHeight = size.height * (compact ? 0.78 : 0.82);
        final dialogMaxWidth = compact ? 360.0 : 430.0;
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(
            horizontal: compact ? 24 : 80,
            vertical: compact ? 24 : 40,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: dialogMaxWidth,
              maxHeight: dialogMaxHeight,
            ),
            child: SizedBox(
              height: dialogMaxHeight,
              child: Container(
                padding: EdgeInsets.all(compact ? 20 : 28),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFF8FBFF), Color(0xFFE7EEF9)],
                  ),
                  border: Border.all(
                    color: const Color(0xFFB7C8E6),
                    width: 1.4,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 24,
                      offset: Offset(0, 14),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: compact ? 54 : 62,
                              height: compact ? 54 : 62,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFE0E0),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: const Icon(
                                Icons.sentiment_dissatisfied_rounded,
                                color: Color(0xFFD84343),
                                size: 34,
                              ),
                            ),
                            SizedBox(height: compact ? 16 : 20),
                            Text(
                              '\uC84C\uC2B5\uB2C8\uB2E4. \uB2E4\uC2DC \uD560\uAE4C\uC694?',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: compact ? 24 : 28,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF1B2A41),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: compact ? 18 : 22),
                    if (canRetreat)
                      Row(
                        children: [
                          Expanded(
                            child: _dialogActionButton(
                              label: '\uB808\uBCA8 \uB2E4\uC6B4',
                              icon: Icons.keyboard_double_arrow_down_rounded,
                              background: const Color(0xFFE0ECFF),
                              foreground: const Color(0xFF2357A5),
                              onTap: () {
                                Navigator.of(ctx).pop();
                                widget.onRetreat!(retreat);
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _dialogActionButton(
                              label: '\uADF8\uB300\uB85C',
                              icon: Icons.refresh_rounded,
                              background: const Color(0xFF1F6FE5),
                              foreground: Colors.white,
                              onTap: () {
                                Navigator.of(ctx).pop();
                                _restartCurrentMatch();
                              },
                            ),
                          ),
                        ],
                      )
                    else
                      Center(
                        child: SizedBox(
                          width: compact ? 170 : 190,
                          child: _dialogActionButton(
                            label: '\uADF8\uB300\uB85C',
                            icon: Icons.refresh_rounded,
                            background: const Color(0xFF1F6FE5),
                            foreground: Colors.white,
                            onTap: () {
                              Navigator.of(ctx).pop();
                              _restartCurrentMatch();
                            },
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void start() {
    _resetInputs();
    _game.kickoff();
    _lastStamp = null;
    _resultHandled = false;
    _ticker.start();
  }

  void _handleKickoffAction() {
    if (_game.running) {
      _restartCurrentMatch();
      return;
    }
    start();
  }

  void stop() {
    _ticker.stop();
  }

  String _difficultyLabel(AIDifficulty d) {
    return d.label;
  }

  AIDifficulty? _nextDifficulty(AIDifficulty d) {
    return d.next;
  }

  AIDifficulty? _previousDifficulty(AIDifficulty d) {
    return d.previous;
  }

  void _restartCurrentMatch() {
    _resetInputs();
    _advanced = false;
    _resultHandled = false;
    _game.score.left = 0;
    _game.score.right = 0;
    _game.celebrating = false;
    _game.running = false;
    _game.lastScorerLeft = false;
    _game.celebrationTime = 0.0;
    _game.netWobbleLeftTime = 0.0;
    _game.netWobbleRightTime = 0.0;
    _game.resize(_game.size);
    start();
  }

  void _resetInputs() {
    _pressedKeys.clear();
    _activeTouchPointers.clear();
    _touchLeft = false;
    _touchRight = false;
    _touchJump = false;
    _left = false;
    _right = false;
    _jump = false;
  }

  bool _isLeftKey(LogicalKeyboardKey key) =>
      key == LogicalKeyboardKey.arrowLeft || key == LogicalKeyboardKey.keyA;

  bool _isRightKey(LogicalKeyboardKey key) =>
      key == LogicalKeyboardKey.arrowRight || key == LogicalKeyboardKey.keyD;

  bool _isJumpKey(LogicalKeyboardKey key) =>
      key == LogicalKeyboardKey.space || key == LogicalKeyboardKey.arrowUp;

  void _syncInputs() {
    final leftPressed = _touchLeft || _pressedKeys.any(_isLeftKey);
    final rightPressed = _touchRight || _pressedKeys.any(_isRightKey);
    _left = leftPressed;
    _right = rightPressed && !leftPressed;
    _jump = _touchJump || _pressedKeys.any(_isJumpKey);
  }

  void _pressTouchControl(PointerDownEvent event, _TouchControl control) {
    _activeTouchPointers[event.pointer] = control;
    _syncTouchPointers();
  }

  void _releaseTouchPointer(PointerEvent event) {
    if (_activeTouchPointers.remove(event.pointer) != null) {
      setState(_syncTouchPointers);
    }
  }

  void _syncTouchPointers() {
    final activeControls = _activeTouchPointers.values;
    _touchLeft = activeControls.contains(_TouchControl.left);
    _touchRight = activeControls.contains(_TouchControl.right);
    _touchJump = activeControls.contains(_TouchControl.jump);
    _syncInputs();
  }

  KeyEventResult _handleKeyEvent(KeyEvent evt) {
    final key = evt.logicalKey;
    if (!_isLeftKey(key) && !_isRightKey(key) && !_isJumpKey(key)) {
      return KeyEventResult.ignored;
    }

    if (evt is KeyDownEvent || evt is KeyRepeatEvent) {
      _pressedKeys.add(key);
    } else if (evt is KeyUpEvent) {
      _pressedKeys.remove(key);
    } else {
      return KeyEventResult.ignored;
    }
    setState(_syncInputs);
    return KeyEventResult.handled;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed && mounted) {
      setState(_resetInputs);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _resetInputs();
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final size = Size(c.maxWidth, c.maxHeight);
        final isLandscape = size.width > size.height;
        if (size.width > 0 && size.height > 0) {
          _game.resize(size);
        }
        return Listener(
          onPointerUp: _releaseTouchPointer,
          onPointerCancel: _releaseTouchPointer,
          child: Focus(
            autofocus: true,
            onFocusChange: (hasFocus) {
              if (!hasFocus) {
                setState(_resetInputs);
              }
            },
            onKeyEvent: (node, evt) => _handleKeyEvent(evt),
            child: Stack(
              fit: StackFit.expand,
              children: [
                RepaintBoundary(
                  child: CustomPaint(
                    painter: _FieldPainter(
                      _game,
                      weather: _weather,
                      cameraX: _cameraX,
                      time: _time,
                    ),
                  ),
                ),
                if (_game.celebrating)
                  Positioned.fill(
                    child: IgnorePointer(
                      ignoring: true,
                      child: Center(
                        child: AnimatedScale(
                          scale: 1.0 + 0.06 * (1.0 + math.sin(_time * 8)),
                          duration: const Duration(milliseconds: 120),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 12,
                                ),
                              ],
                            ),
                            child: const Text(
                              'GOAL!',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                _faceAt(_game.leftPlayer.pos, widget.leftPlayer, flip: false),
                _faceAt(_game.rightPlayer.pos, widget.rightPlayer, flip: true),
                Positioned(
                  top: isLandscape ? 10 : 16,
                  left: isLandscape ? 24 : 16,
                  right: isLandscape ? 24 : 16,
                  child: _ScoreBar(
                    scoreLeft: _game.score.left,
                    scoreRight: _game.score.right,
                    onKickoff: _handleKickoffAction,
                    running: _game.running,
                    isLandscape: isLandscape,
                    difficultyLabel: _difficultyLabel(widget.aiDifficulty),
                  ),
                ),
                if (_game.running)
                  Positioned(
                    top: isLandscape ? 76 : 82,
                    left: isLandscape ? null : 12,
                    right: 12,
                    child: IgnorePointer(
                      child: _AnalysisBadge(
                        analysis: _game.playerAnalysis,
                        compact: !isLandscape,
                      ),
                    ),
                  ),
                Positioned(
                  left: isLandscape ? 24 : 12,
                  bottom: isLandscape ? 24 : 88,
                  child: _holdButton(
                    icon: Icons.arrow_left,
                    control: _TouchControl.left,
                    size: isLandscape ? 62 : 48,
                  ),
                ),
                Positioned(
                  left: isLandscape ? 98 : 72,
                  bottom: isLandscape ? 24 : 88,
                  child: _holdButton(
                    icon: Icons.arrow_right,
                    control: _TouchControl.right,
                    size: isLandscape ? 62 : 48,
                  ),
                ),
                Positioned(
                  right: isLandscape ? 92 : 68,
                  bottom: isLandscape ? 24 : 88,
                  child: _holdButton(
                    icon: Icons.arrow_upward,
                    control: _TouchControl.jump,
                    size: isLandscape ? 62 : 48,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _faceAt(Offset center, AnimalPlayer player, {required bool flip}) {
    const r = GameConfig.playerRadius;
    final width = r * 2.25;
    final height = r * 2.65;
    return Positioned(
      left: center.dx - width / 2 - _cameraX,
      top: center.dy + r - height + 6,
      width: width,
      height: height,
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()..scale(flip ? -1.0 : 1.0, 1.0),
        child: AnimalPlush(player: player, size: width, soccerUniform: true),
      ),
    );
  }

  Widget _holdButton({
    required IconData icon,
    required _TouchControl control,
    required double size,
  }) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (event) {
        setState(() => _pressTouchControl(event, control));
      },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.white, size: size * 0.58),
      ),
    );
  }

  Widget _dialogActionButton({
    required String label,
    required IconData icon,
    required Color background,
    required Color foreground,
    required VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(18),
            boxShadow: onTap == null
                ? null
                : [
                    BoxShadow(
                      color: foreground.withOpacity(0.16),
                      blurRadius: 12,
                      offset: const Offset(0, 7),
                    ),
                  ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: foreground, size: 22),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: foreground,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnalysisBadge extends StatelessWidget {
  final PlayerAnalysis analysis;
  final bool compact;

  const _AnalysisBadge({required this.analysis, required this.compact});

  @override
  Widget build(BuildContext context) {
    final confidence = analysis.confidencePercent;
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: compact ? 336 : 390),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xDD101A2A),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0x665CE1E6)),
          boxShadow: const [
            BoxShadow(color: Color(0x33000000), blurRadius: 10),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 10 : 12,
            vertical: compact ? 8 : 10,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.psychology_alt_rounded,
                    color: Color(0xFF72F1F5),
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      '${analysis.style.label} · 신뢰도 $confidence% · ${analysis.attackDirection.label} 공격',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: compact ? 11 : 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                analysis.evidenceText,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: const Color(0xFFD9F7F8),
                  fontSize: compact ? 10 : 11,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScoreBar extends StatelessWidget {
  final int scoreLeft;
  final int scoreRight;
  final VoidCallback onKickoff;
  final bool running;
  final bool isLandscape;
  final String difficultyLabel;

  const _ScoreBar({
    required this.scoreLeft,
    required this.scoreRight,
    required this.onKickoff,
    required this.running,
    required this.isLandscape,
    required this.difficultyLabel,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < (isLandscape ? 520 : 420);

        return Row(
          children: [
            Flexible(
              flex: compact ? 2 : 1,
              child: Align(
                alignment: Alignment.centerLeft,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: _pill('$scoreLeft', Colors.blue, compact: compact),
                ),
              ),
            ),
            SizedBox(width: compact ? 8 : 16),
            Flexible(
              flex: 3,
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: ElevatedButton.icon(
                    onPressed: onKickoff,
                    icon: Icon(
                      Icons.play_arrow_rounded,
                      size: compact ? 20 : (isLandscape ? 26 : 32),
                    ),
                    label: Text(
                      running
                          ? '\uC7AC\uC2DC\uC791\uD558\uAE30($difficultyLabel)'
                          : '\uC2DC\uC791\uD558\uAE30($difficultyLabel)',
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: compact ? 14 : (isLandscape ? 22 : 28),
                        vertical: compact ? 10 : (isLandscape ? 14 : 18),
                      ),
                      textStyle: TextStyle(
                        fontSize: compact ? 16 : (isLandscape ? 20 : 24),
                        fontWeight: FontWeight.w800,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: compact ? 8 : 16),
            Flexible(
              flex: compact ? 2 : 1,
              child: Align(
                alignment: Alignment.centerRight,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: _pill('$scoreRight', Colors.red, compact: compact),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _pill(String text, Color c, {required bool compact}) {
    return Container(
      constraints: BoxConstraints(
        minWidth: compact ? 54 : (isLandscape ? 76 : 88),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : (isLandscape ? 18 : 24),
        vertical: compact ? 8 : (isLandscape ? 10 : 14),
      ),
      decoration: BoxDecoration(
        color: c.withOpacity(0.18),
        borderRadius: BorderRadius.circular(compact ? 18 : 24),
        border: Border.all(color: c.withOpacity(0.8), width: compact ? 1.5 : 2),
        boxShadow: [
          BoxShadow(
            color: c.withOpacity(0.24),
            blurRadius: compact ? 10 : 16,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: compact ? 22 : (isLandscape ? 28 : 34),
          color: c,
        ),
      ),
    );
  }
}

class _FieldPainter extends CustomPainter {
  final GameState g;
  final WeatherType weather;
  final double cameraX;
  final double time;

  _FieldPainter(
    this.g, {
    required this.weather,
    required this.cameraX,
    required this.time,
  });

  static final _FieldBackgroundCache _bgCache = _FieldBackgroundCache();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(-cameraX, 0);

    final pic = _bgCache.ensure(
      worldWidth: g.worldWidth,
      size: size,
      weather: weather,
      groundY: g.groundY,
    );
    canvas.drawPicture(pic);

    _drawGoal(canvas, g.leftGoal, wobbleTime: g.netWobbleLeftTime, flip: false);
    _drawGoal(
      canvas,
      g.rightGoal,
      wobbleTime: g.netWobbleRightTime,
      flip: true,
    );
    final ballShadow = Paint()..color = Colors.black.withOpacity(0.2);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(g.ball.pos.dx, g.groundY + 6),
        width: 24,
        height: 8,
      ),
      ballShadow,
    );
    final ball = Paint()..color = const Color(0xFFFAFAFA);
    canvas.drawCircle(g.ball.pos, GameConfig.ballRadius, ball);
    final seam = Paint()
      ..color = Colors.black38
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(g.ball.pos, GameConfig.ballRadius * 0.7, seam);
    canvas.restore();

    if (weather == WeatherType.dayRain || weather == WeatherType.cloudyRain) {
      _drawRainOverlay(canvas, size);
    }
  }

  List<Color> _skyColors() {
    switch (weather) {
      case WeatherType.dayClear:
        return const [Color(0xFF90CAF9), Color(0xFFE3F2FD)];
      case WeatherType.dayRain:
        return const [Color(0xFF9EC5DB), Color(0xFFE6EEF5)];
      case WeatherType.cloudy:
        return const [Color(0xFFB0BEC5), Color(0xFFECEFF1)];
      case WeatherType.cloudyRain:
        return const [Color(0xFF9EACB4), Color(0xFFDDE3E6)];
    }
  }

  (Color, Color) _grassColors() {
    switch (weather) {
      case WeatherType.dayClear:
      case WeatherType.dayRain:
        return (
          const Color(0xFF2e7d32).withOpacity(0.92),
          const Color(0xFF388e3c).withOpacity(0.92),
        );
      case WeatherType.cloudy:
      case WeatherType.cloudyRain:
        return (
          const Color(0xFF2e7d32).withOpacity(0.82),
          const Color(0xFF336E30).withOpacity(0.82),
        );
    }
  }

  void _drawRainOverlay(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.18)
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;
    const spacingX = 22.0;
    const spacingY = 26.0;
    const speed = 240.0;
    const dx = -6.0;
    const dy = 12.0;
    final shift = (time * speed) % spacingY;
    for (double x = 0; x <= size.width + spacingX; x += spacingX) {
      for (double y = -spacingY; y <= size.height + spacingY; y += spacingY) {
        final y0 = y + shift;
        final p1 = Offset(x, y0);
        final p2 = p1.translate(dx, dy);
        canvas.drawLine(p1, p2, paint);
      }
    }
  }

  void _drawNet(
    Canvas canvas,
    Rect goal, {
    bool flip = false,
    double wobbleTime = 0.0,
  }) {
    final spacing = 10.0;
    final netTopColor = const Color(0xFF29B6F6).withOpacity(0.95);
    final netBottomColor = const Color(0xFF1976D2).withOpacity(0.95);
    for (double x = goal.left; x <= goal.right; x += spacing) {
      final wobbleAmp = (wobbleTime > 0)
          ? (6.0 * (wobbleTime.clamp(0, 1.0)))
          : 0.0;
      final phase = (x - goal.left) * 0.2;
      final wobble = wobbleAmp * math.sin(time * 12.0 + phase);
      final control = Offset(
        x + (flip ? -spacing : spacing) * 0.6,
        goal.top + goal.height * 0.55 + wobble,
      );
      final path = Path()
        ..moveTo(x, goal.top)
        ..quadraticBezierTo(control.dx, control.dy, x, goal.bottom);
      final t = (x - goal.left) / goal.width;
      final color = Color.lerp(netTopColor, netBottomColor, t) ?? netTopColor;
      canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4,
      );
    }
    for (double y = goal.top + spacing; y < goal.bottom; y += spacing) {
      final p1 = Offset(goal.left, y);
      final p2 = Offset(goal.right, y);
      canvas.drawLine(
        p1,
        p2,
        Paint()
          ..color = netBottomColor
          ..strokeWidth = 1.2,
      );
    }
  }

  void _drawGoal(
    Canvas canvas,
    Rect goal, {
    double wobbleTime = 0.0,
    bool flip = false,
  }) {
    final postW = 6.0;
    final outer = RRect.fromRectAndRadius(goal, const Radius.circular(3));
    canvas.drawRRect(
      outer,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = postW,
    );
    canvas.drawRRect(
      outer.inflate(3),
      Paint()
        ..color = const Color(0xFF00BCD4).withOpacity(0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    canvas.drawRRect(
      outer.shift(const Offset(2, 2)),
      Paint()..color = Colors.black.withOpacity(0.08),
    );
    _drawNet(canvas, goal, flip: flip, wobbleTime: wobbleTime);
  }

  @override
  bool shouldRepaint(covariant _FieldPainter oldDelegate) => true;
}

class _FieldBackgroundCache {
  ui.Picture? _picture;
  double? _cachedWorldWidth;
  Size? _cachedSize;
  WeatherType? _cachedWeather;
  double? _cachedGroundY;

  ui.Picture ensure({
    required double worldWidth,
    required Size size,
    required WeatherType weather,
    required double groundY,
  }) {
    if (_picture != null &&
        _cachedWorldWidth == worldWidth &&
        _cachedSize == size &&
        _cachedWeather == weather &&
        _cachedGroundY == groundY) {
      return _picture!;
    }
    final rec = ui.PictureRecorder();
    final c = Canvas(rec);

    final sky = _skyColors(weather);
    final bg = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.transparent, Colors.transparent],
      ).createShader(Offset.zero & size);
    final shader = LinearGradient(
      colors: sky,
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ).createShader(Offset.zero & size);
    bg.shader = shader;
    c.drawRect(Rect.fromLTWH(0, 0, worldWidth, size.height), bg);

    final field = Rect.fromLTWH(0, groundY, worldWidth, size.height - groundY);
    final grass = _grassColors(weather);
    final stripeA = grass.$1;
    final stripeB = grass.$2;
    const stripeCount = 8;
    final stripeH = field.height / stripeCount;
    for (var i = 0; i < stripeCount; i++) {
      final r = Rect.fromLTWH(
        field.left,
        field.top + i * stripeH,
        field.width,
        stripeH,
      );
      c.drawRect(r, Paint()..color = (i % 2 == 0) ? stripeA : stripeB);
    }

    final goalDepth = size.width * GameConfig.goalDepthFrac;
    final penW = goalDepth * 2.2;
    final penH = (size.height - groundY) * 0.9;
    final smallW = goalDepth * 1.2;
    final smallH = (size.height - groundY) * 0.55;
    final boxPaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    c.drawRect(Rect.fromLTWH(0, groundY - penH, penW, penH), boxPaint);
    c.drawRect(Rect.fromLTWH(0, groundY - smallH, smallW, smallH), boxPaint);
    c.drawRect(
      Rect.fromLTWH(worldWidth - penW, groundY - penH, penW, penH),
      boxPaint,
    );
    c.drawRect(
      Rect.fromLTWH(worldWidth - smallW, groundY - smallH, smallW, smallH),
      boxPaint,
    );

    final picture = rec.endRecording();
    _picture = picture;
    _cachedWorldWidth = worldWidth;
    _cachedSize = size;
    _cachedWeather = weather;
    _cachedGroundY = groundY;
    return picture;
  }

  static List<Color> _skyColors(WeatherType weather) {
    switch (weather) {
      case WeatherType.dayClear:
        return const [Color(0xFF90CAF9), Color(0xFFE3F2FD)];
      case WeatherType.dayRain:
        return const [Color(0xFF9EC5DB), Color(0xFFE6EEF5)];
      case WeatherType.cloudy:
        return const [Color(0xFFB0BEC5), Color(0xFFECEFF1)];
      case WeatherType.cloudyRain:
        return const [Color(0xFF9EACB4), Color(0xFFDDE3E6)];
    }
  }

  static (Color, Color) _grassColors(WeatherType weather) {
    switch (weather) {
      case WeatherType.dayClear:
      case WeatherType.dayRain:
        return (
          const Color(0xFF2e7d32).withOpacity(0.92),
          const Color(0xFF388e3c).withOpacity(0.92),
        );
      case WeatherType.cloudy:
      case WeatherType.cloudyRain:
        return (
          const Color(0xFF2e7d32).withOpacity(0.82),
          const Color(0xFF336E30).withOpacity(0.82),
        );
    }
  }
}
