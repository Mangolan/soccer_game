import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';
import 'dart:math' as math;
import 'game_logic.dart';
import '../marble_face.dart';

enum WeatherType { dayClear, dayRain, cloudy, cloudyRain }

class GameWidget extends StatefulWidget {
  final MarbleStyle leftStyle;
  final MarbleStyle rightStyle;
  final MarbleExpression?
  leftExpression; // not used for dynamic mood, kept for compat
  final MarbleExpression? rightExpression;
  final MarbleExpression? initialLeftExpression; // sets starting mood
  final MarbleExpression? initialRightExpression; // sets AI starting mood
  final EyeStyle? leftEyeStyle;
  final bool leftHumanize;
  final bool leftFlipMouth;
  final EyeStyle? rightEyeStyle;
  final bool rightHumanize;
  final bool rightFlipMouth;
  final AIDifficulty aiDifficulty;
  final void Function(AIDifficulty nextDifficulty)? onAdvance;

  const GameWidget({
    super.key,
    required this.leftStyle,
    required this.rightStyle,
    this.leftExpression,
    this.rightExpression,
    this.initialLeftExpression,
    this.initialRightExpression,
    this.leftEyeStyle,
    this.leftHumanize = false,
    this.leftFlipMouth = false,
    this.rightEyeStyle,
    this.rightHumanize = false,
    this.rightFlipMouth = false,
    required this.aiDifficulty,
    this.onAdvance,
  });

  @override
  State<GameWidget> createState() => _GameWidgetState();
}

class _GameWidgetState extends State<GameWidget>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  late GameState _game;
  double _cameraX = 0.0;
  double _time = 0.0;
  bool _advanced = false;
  late WeatherType _weather;

  // Input
  bool _left = false;
  bool _right = false;
  bool _jump = false;

  WeatherType _randomWeather() {
    // Always use clear day weather per request
    return WeatherType.dayClear;
  }

  @override
  void initState() {
    super.initState();
    _weather = _randomWeather();
    _game = GameState(
      size: const Size(360, 640),
      leftPlayer: PlayerState(pos: const Offset(100, 400), color: Colors.blue),
      rightPlayer: PlayerState(pos: const Offset(260, 400), color: Colors.red),
      ball: BallState(pos: const Offset(180, 300)),
      aiDifficulty: widget.aiDifficulty,
    );
    // Initialize left face mood to selection, if provided
    if (widget.initialLeftExpression != null) {
      _game.mood.left = widget.initialLeftExpression!;
    }
    if (widget.initialRightExpression != null) {
      _game.mood.right = widget.initialRightExpression!;
    }
    _ticker = createTicker((elapsed) {
      var dt = (_lastStamp == null)
          ? 0.016
          : (elapsed - _lastStamp!).inMicroseconds / 1e6;
      // Clamp dt to reduce stutter on occasional long frames
      if (dt > 0.05) dt = 0.05;
      _lastStamp = elapsed;
      _game.update(dt, leftLeft: _left, leftRight: _right, leftJump: _jump);
      _time += dt;
      // Stage clear check: player reaches >=15 and is leading, except very hard
      if (!_advanced && widget.aiDifficulty != AIDifficulty.veryHard) {
        if (_game.score.left >= 15 && _game.score.left > _game.score.right) {
          _advanced = true;
          _ticker.stop();
          final next = _nextDifficulty(widget.aiDifficulty);
          if (next != null && widget.onAdvance != null && mounted) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              widget.onAdvance!(next);
            });
          }
        }
      }
      // Camera follows the ball primarily
      final desired = _game.ball.pos.dx - (_game.size.width * 0.5);
      final maxCam = (_game.worldWidth - _game.size.width).clamp(
        0,
        double.infinity,
      );
      final target = desired.clamp(0, maxCam);
      _cameraX = _cameraX + (target - _cameraX) * 0.12; // smooth
      if (mounted) setState(() {});
    });
  }

  Duration? _lastStamp;

  void start() {
    _game.kickoff();
    _lastStamp = null;
    _ticker.start();
  }

  void stop() {
    _ticker.stop();
  }

  AIDifficulty? _nextDifficulty(AIDifficulty d) {
    switch (d) {
      case AIDifficulty.veryEasy:
        return AIDifficulty.easy;
      case AIDifficulty.easy:
        return AIDifficulty.medium;
      case AIDifficulty.medium:
        return AIDifficulty.hard;
      case AIDifficulty.hard:
        return AIDifficulty.veryHard;
      case AIDifficulty.veryHard:
        return null;
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final size = Size(c.maxWidth, c.maxHeight);
        if (size.width > 0 && size.height > 0) {
          _game.resize(size);
        }
        return Focus(
          autofocus: true,
          onKeyEvent: (node, evt) {
            final pressed = evt is KeyDownEvent || evt is KeyRepeatEvent;
            if (evt.logicalKey == LogicalKeyboardKey.arrowLeft ||
                evt.logicalKey == LogicalKeyboardKey.keyA) {
              _left = pressed;
              return KeyEventResult.handled;
            }
            if (evt.logicalKey == LogicalKeyboardKey.arrowRight ||
                evt.logicalKey == LogicalKeyboardKey.keyD) {
              _right = pressed;
              return KeyEventResult.handled;
            }
            if (evt.logicalKey == LogicalKeyboardKey.space ||
                evt.logicalKey == LogicalKeyboardKey.arrowUp) {
              _jump = pressed;
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
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
                              BoxShadow(color: Colors.black26, blurRadius: 12),
                            ],
                          ),
                          child: const Text(
                            'GOAL! ??',
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
              // Left player face
              _faceAt(
                _game.leftPlayer.pos,
                widget.leftStyle,
                widget.leftExpression ?? _game.mood.left,
                eyeStyle: widget.leftEyeStyle,
                humanize: widget.leftHumanize,
                flipMouth: widget.leftFlipMouth,
              ),
              // Right player face
              _faceAt(
                _game.rightPlayer.pos,
                widget.rightStyle,
                widget.rightExpression ?? _game.mood.right,
                eyeStyle: widget.rightEyeStyle,
                humanize: widget.rightHumanize,
                flipMouth: widget.rightFlipMouth,
              ),
              // HUD
              Positioned(
                top: 8,
                left: 12,
                right: 12,
                child: _ScoreBar(
                  scoreLeft: _game.score.left,
                  scoreRight: _game.score.right,
                  onKickoff: start,
                  running: _game.running,
                ),
              ),
              // Mobile controls
              Positioned(
                left: 12,
                bottom: 12,
                child: _holdButton(
                  icon: Icons.arrow_left,
                  onChanged: (v) => setState(() => _left = v),
                ),
              ),
              Positioned(
                left: 72,
                bottom: 12,
                child: _holdButton(
                  icon: Icons.arrow_right,
                  onChanged: (v) => setState(() => _right = v),
                ),
              ),
              Positioned(
                right: 12,
                bottom: 12,
                child: _holdButton(
                  icon: Icons.arrow_upward,
                  onChanged: (v) => setState(() => _jump = v),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _faceAt(
    Offset center,
    MarbleStyle style,
    MarbleExpression expr, {
    EyeStyle? eyeStyle,
    bool humanize = false,
    bool flipMouth = false,
  }) {
    const r = GameConfig.playerRadius;
    return Positioned(
      left: center.dx - r - _cameraX,
      top: center.dy - r,
      width: r * 2,
      height: r * 2,
      child: CustomPaint(
        painter: MarbleFacePainter(
          style: style,
          expression: expr,
          eyeStyle: eyeStyle,
          humanize: humanize,
          flipMouth: flipMouth,
        ),
      ),
    );
  }

  Widget _holdButton({
    required IconData icon,
    required ValueChanged<bool> onChanged,
  }) {
    return Listener(
      onPointerDown: (_) => onChanged(true),
      onPointerUp: (_) => onChanged(false),
      onPointerCancel: (_) => onChanged(false),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }
}

class _ScoreBar extends StatelessWidget {
  final int scoreLeft;
  final int scoreRight;
  final VoidCallback onKickoff;
  final bool running;
  const _ScoreBar({
    required this.scoreLeft,
    required this.scoreRight,
    required this.onKickoff,
    required this.running,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _pill('${scoreLeft}', Colors.blue),
        const Spacer(),
        ElevatedButton.icon(
          onPressed: onKickoff,
          icon: const Icon(Icons.play_arrow_rounded),
          label: Text(running ? 'Re-Kickoff' : 'Kickoff'),
        ),
        const Spacer(),
        _pill('${scoreRight}', Colors.red),
      ],
    );
  }

  Widget _pill(String text, Color c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: c.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.withOpacity(0.6)),
      ),
      child: Text(
        text,
        style: TextStyle(fontWeight: FontWeight.bold, color: c),
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

  // Cache for static field background to reduce per-frame draw cost.
  static final _FieldBackgroundCache _bgCache = _FieldBackgroundCache();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(-cameraX, 0);

    // Draw cached static background (sky, field, lines, boxes, circle).
    final pic = _bgCache.ensure(
      worldWidth: g.worldWidth,
      size: size,
      weather: weather,
      groundY: g.groundY,
    );
    canvas.drawPicture(pic);

    // Goals (beautiful posts + vivid nets with wobble)
    _drawGoal(canvas, g.leftGoal, wobbleTime: g.netWobbleLeftTime, flip: false);
    _drawGoal(
      canvas,
      g.rightGoal,
      wobbleTime: g.netWobbleRightTime,
      flip: true,
    ); // Ball (no gloss)
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

    // Rain overlay in screen space
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
    // Slightly lower density to reduce per-frame draw calls
    const spacingX = 22.0;
    const spacingY = 26.0;
    const speed = 240.0; // px/s downward
    const dx = -6.0; // slant
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
    // Vivid deep sky-blue net with slight sag using quadratic curves
    final spacing = 10.0;
    final netTopColor = const Color(0xFF29B6F6).withOpacity(0.95);
    final netBottomColor = const Color(0xFF1976D2).withOpacity(0.95);
    // Vertical strings with sag and wobble
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
    // Horizontal threads
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
    // Posts and crossbar with glossy white and cyan outline
    final postW = 6.0;
    final outer = RRect.fromRectAndRadius(goal, const Radius.circular(3));
    // Outline frame
    canvas.drawRRect(
      outer,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = postW,
    );
    // Cyan edge glow
    canvas.drawRRect(
      outer.inflate(3),
      Paint()
        ..color = const Color(0xFF00BCD4).withOpacity(0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    // Soft shadow behind goal frame
    canvas.drawRRect(
      outer.shift(const Offset(2, 2)),
      Paint()..color = Colors.black.withOpacity(0.08),
    );
    _drawNet(canvas, goal, flip: flip, wobbleTime: wobbleTime);
  }

  @override
  bool shouldRepaint(covariant _FieldPainter oldDelegate) => true;
}

// Helper to build and cache the static field background as a Picture.
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

    // Sky background gradient (by weather)
    final sky = _skyColors(weather);
    final bg = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.transparent, Colors.transparent],
      ).createShader(Offset.zero & size);
    // Rebuild with actual colors to avoid reallocation in loops
    final shader = LinearGradient(
      colors: sky,
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ).createShader(Offset.zero & size);
    bg.shader = shader;
    c.drawRect(Rect.fromLTWH(0, 0, worldWidth, size.height), bg);

    // Ground and grass stripes (by weather)
    final field = Rect.fromLTWH(
      0,
      groundY,
      worldWidth,
      size.height - groundY,
    );
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

    // Center line and circle removed per request

    // Penalty boxes and goal areas at both ends
    final goalDepth = size.width * GameConfig.goalDepthFrac;
    final penW = goalDepth * 2.2;
    final penH = (size.height - groundY) * 0.9;
    final smallW = goalDepth * 1.2;
    final smallH = (size.height - groundY) * 0.55;
    final boxPaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    // Left penalty
    c.drawRect(Rect.fromLTWH(0, groundY - penH, penW, penH), boxPaint);
    c.drawRect(
      Rect.fromLTWH(0, groundY - smallH, smallW, smallH),
      boxPaint,
    );
    // Right penalty at world end
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
