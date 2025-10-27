import 'package:flutter/material.dart';
import 'dart:math' as math;

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

enum EyeStyle {
  normal,
  glasses,
  sunglasses,
  closed,
  big,
  wink,
  angry,
  sad,
  funny,
}

class FaceAnchors {
  final Offset nose;
  final Offset mouth;
  final Offset leftEye;
  final Offset rightEye;

  const FaceAnchors({
    this.nose = const Offset(0, -0.05),
    this.mouth = const Offset(0, 0.13),
    this.leftEye = const Offset(-0.28, -0.22),
    this.rightEye = const Offset(0.28, -0.22),
  });
}

class MarbleStyle {
  final Color baseColor;
  final double opacity;
  final double gloss;
  final bool glass;

  const MarbleStyle({
    required this.baseColor,
    this.opacity = 1.0,
    this.gloss = 0.6,
    this.glass = false,
  });
}

class MarbleFacePainter extends CustomPainter {
  final MarbleStyle style;
  final MarbleExpression expression;
  final FaceAnchors anchors;
  final bool humanize;
  final bool flipMouth;
  final EyeStyle? eyeStyle;

  const MarbleFacePainter({
    required this.style,
    this.expression = MarbleExpression.neutral,
    this.anchors = const FaceAnchors(),
    this.humanize = false,
    this.flipMouth = false,
    this.eyeStyle,
  });

  void _withMouthFlip(Canvas canvas, Offset m, void Function() draw) {
    if (flipMouth) {
      canvas.save();
      canvas.translate(m.dx, m.dy);
      canvas.rotate(math.pi);
      canvas.translate(-m.dx, -m.dy);
      draw();
      canvas.restore();
    } else {
      draw();
    }
  }

  void _drawMouthForExpression(Canvas canvas, Offset mouth, double r) {
    switch (expression) {
      case MarbleExpression.happy:
        _mouthSmile(canvas, mouth, r, 0.5);
        break;
      case MarbleExpression.pouting:
        _mouthPout(canvas, mouth.translate(0, r * 0.04), r);
        break;
      case MarbleExpression.angry:
        _mouthFlat(canvas, mouth, r, down: true);
        break;
      case MarbleExpression.sad:
        _mouthSmile(canvas, mouth, r, 0.1);
        break;
      case MarbleExpression.mischievous:
        _mouthSmile(canvas, mouth, r, 0.45);
        break;
      case MarbleExpression.surprised:
        _mouthO(canvas, mouth, r);
        break;
      case MarbleExpression.funny:
        _mouthFunny(canvas, mouth, r);
        break;
      case MarbleExpression.sleeping:
        _mouthO(canvas, mouth.translate(0, r * 0.1), r * 0.08);
        break;
      default:
        _mouthSmile(canvas, mouth, r, 0.25);
    }
  }

  void _drawEyesByStyle(
      Canvas canvas, Offset leftEye, Offset rightEye, double r, EyeStyle s) {
    switch (s) {
      case EyeStyle.normal:
        _eyesNeutral(canvas, leftEye, rightEye, r);
        break;
      case EyeStyle.glasses:
        _eyesNeutral(canvas, leftEye, rightEye, r);
        _drawGlasses(canvas, leftEye, rightEye, r, dark: false);
        break;
      case EyeStyle.sunglasses:
        _drawSunglasses(canvas, leftEye, rightEye, r);
        break;
      case EyeStyle.closed:
        _eyesSleeping(canvas, leftEye, rightEye, r);
        break;
      case EyeStyle.big:
        _eyesSurprised(canvas, leftEye, rightEye, r);
        break;
      case EyeStyle.wink:
        _eyeWink(canvas, leftEye, rightEye, r);
        break;
      case EyeStyle.angry:
        _eyesAngry(canvas, leftEye, rightEye, r);
        break;
      case EyeStyle.sad:
        _eyesSad(canvas, leftEye, rightEye, r);
        break;
      case EyeStyle.funny:
        _eyesFunny(canvas, leftEye, rightEye, r);
        break;
    }
  }

  void _drawGlasses(Canvas canvas, Offset l, Offset rEye, double r,
      {bool dark = false}) {
    final frameColor = dark ? Colors.black : Colors.black87;
    final glassPaint = Paint()
      ..color = (dark ? Colors.black87 : Colors.white.withOpacity(0.1))
      ..style = PaintingStyle.fill;
    final ring = Paint()
      ..color = frameColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.05;
    final rad = r * 0.16;
    canvas.drawCircle(l, rad, glassPaint);
    canvas.drawCircle(rEye, rad, glassPaint);
    canvas.drawCircle(l, rad, ring);
    canvas.drawCircle(rEye, rad, ring);
    canvas.drawLine(l.translate(rad, 0), rEye.translate(-rad, 0),
        Paint()..color = frameColor..strokeWidth = r * 0.04);
  }

  void _drawSunglasses(Canvas canvas, Offset l, Offset rEye, double r) {
    _drawGlasses(canvas, l, rEye, r, dark: true);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2.0;
    _drawBody(canvas, c, r);
    _drawFace(canvas, c, r);
  }

  void _drawBody(Canvas canvas, Offset c, double r) {
    final Color tint = style.baseColor.withOpacity(style.opacity);
    final shader = RadialGradient(
      colors: [
        tint.withOpacity(style.glass ? 0.9 : 1.0),
        tint.withOpacity(style.glass ? 0.6 : 1.0),
        tint.withOpacity(style.glass ? 0.4 : 1.0),
      ],
      stops: const [0.0, 0.7, 1.0],
      center: const Alignment(-0.1, -0.1),
      radius: 0.95,
    ).createShader(Rect.fromCircle(center: c, radius: r));

    canvas.drawCircle(c, r, Paint()..shader = shader);

    canvas.drawCircle(
      c,
      r - r * 0.02,
      Paint()
        ..color = Colors.white.withOpacity(0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.04,
    );

    canvas.drawCircle(
      c.translate(-r * 0.25, -r * 0.25),
      r * 0.35,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withOpacity(0.85 * style.gloss),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: c, radius: r * 0.6)),
    );
  }

  void _drawFace(Canvas canvas, Offset c, double r) {
    Offset a(Offset n) => c + Offset(n.dx * r, n.dy * r);
    final mouth = a(anchors.mouth);
    final leftEye = a(anchors.leftEye);
    final rightEye = a(anchors.rightEye);

    if (eyeStyle != null) {
      _drawEyesByStyle(canvas, leftEye, rightEye, r, eyeStyle!);
      _drawMouthForExpression(canvas, mouth, r);
      return;
    }

    switch (expression) {
      case MarbleExpression.happy:
        _eyesCute(canvas, leftEye, rightEye, r);
        _mouthSmile(canvas, mouth, r, 0.5);
        break;
      case MarbleExpression.pouting:
        _eyesNeutral(canvas, leftEye, rightEye, r);
        _mouthPout(canvas, mouth.translate(0, r * 0.04), r);
        break;
      case MarbleExpression.angry:
        _eyesAngry(canvas, leftEye, rightEye, r);
        _mouthFlat(canvas, mouth, r, down: true);
        break;
      case MarbleExpression.sad:
        _eyesSad(canvas, leftEye, rightEye, r);
        _mouthSmile(canvas, mouth, r, 0.1);
        break;
      case MarbleExpression.mischievous:
        _eyeWink(canvas, leftEye, rightEye, r);
        _mouthSmirk(canvas, mouth, r);
        break;
      case MarbleExpression.in_love:
        _eyesHearts(canvas, leftEye, rightEye, r);
        _mouthSmile(canvas, mouth, r, 0.45);
        break;
      case MarbleExpression.surprised:
        _eyesSurprised(canvas, leftEye, rightEye, r);
        _mouthO(canvas, mouth, r);
        break;
      case MarbleExpression.funny:
        _eyesFunny(canvas, leftEye, rightEye, r);
        _mouthFunny(canvas, mouth, r);
        break;
      case MarbleExpression.sleeping:
        _eyesSleeping(canvas, leftEye, rightEye, r);
        _mouthO(canvas, mouth.translate(0, r * 0.1), r * 0.08);
        break;
      default:
        _eyesNeutral(canvas, leftEye, rightEye, r);
        _mouthSmile(canvas, mouth, r, 0.25);
    }

    if (humanize) {
      _eyebrows(canvas, leftEye, rightEye, r);
      _eyeHighlights(canvas, leftEye, rightEye, r);
      _blush(canvas, leftEye, rightEye, r);
    }
  }

  // 👁 Eyes
  void _eyesCute(Canvas canvas, Offset l, Offset rEye, double r) {
    final iris = Paint()..color = Colors.black87;
    final light = Paint()..color = Colors.white.withOpacity(0.9);
    for (final e in [l, rEye]) {
      canvas.drawCircle(e, r * 0.09, iris);
      canvas.drawCircle(e.translate(-r * 0.03, -r * 0.03), r * 0.025, light);
    }
  }

  void _eyesNeutral(Canvas canvas, Offset l, Offset rEye, double r) =>
      _eyesCute(canvas, l, rEye, r);

  void _eyesAngry(Canvas canvas, Offset l, Offset rEye, double r) {
    final lid = Paint()
      ..color = Colors.black87
      ..strokeWidth = r * 0.06
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(l.translate(-r * 0.12, -r * 0.06),
        l.translate(r * 0.05, -r * 0.16), lid);
    canvas.drawLine(rEye.translate(-r * 0.05, -r * 0.16),
        rEye.translate(r * 0.12, -r * 0.06), lid);
    _eyesCute(canvas, l.translate(0, r * 0.02), rEye.translate(0, r * 0.02), r * 0.9);
  }

  void _eyeWink(Canvas canvas, Offset l, Offset rEye, double r) {
    final open = Paint()..color = Colors.black87;
    canvas.drawCircle(l, r * 0.085, open);
    final wink = Paint()
      ..color = Colors.black87
      ..strokeWidth = r * 0.07
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(rEye.translate(-r * 0.12, 0), rEye.translate(r * 0.12, 0), wink);
  }

  void _eyesSurprised(Canvas canvas, Offset l, Offset rEye, double r) {
    final white = Paint()..color = Colors.white;
    final edge = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.035;
    for (final e in [l, rEye]) {
      canvas.drawCircle(e, r * 0.11, white);
      canvas.drawCircle(e, r * 0.11, edge);
      canvas.drawCircle(e, r * 0.06, Paint()..color = Colors.black87);
    }
  }

  void _eyesSad(Canvas canvas, Offset l, Offset rEye, double r) {
    final p = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.06
      ..strokeCap = StrokeCap.round;
    final w = r * 0.22;
    final h = r * 0.12;
    canvas.drawArc(Rect.fromCenter(center: l.translate(0, r * 0.02), width: w, height: h),
        _deg(20), _deg(140), false, p);
    canvas.drawArc(Rect.fromCenter(center: rEye.translate(0, r * 0.02), width: w, height: h),
        _deg(20), _deg(140), false, p);
  }

  void _eyesFunny(Canvas canvas, Offset l, Offset rEye, double r) {
    final p = Paint()
      ..color = Colors.black87
      ..strokeWidth = r * 0.06
      ..strokeCap = StrokeCap.round;
    for (final e in [l, rEye]) {
      canvas.drawLine(e.translate(-r * 0.1, -r * 0.1), e.translate(r * 0.1, r * 0.1), p);
      canvas.drawLine(e.translate(r * 0.1, -r * 0.1), e.translate(-r * 0.1, r * 0.1), p);
    }
  }

  void _eyesSleeping(Canvas canvas, Offset l, Offset rEye, double r) {
    final p = Paint()
      ..color = Colors.black.withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.05;
    for (final e in [l, rEye]) {
      canvas.drawLine(e.translate(r * 0.1, -r * 0.1), e.translate(-r * 0.1, -r * 0.1), p);
    }
  }

  // 👄 Mouth
  void _mouthSmile(Canvas canvas, Offset m, double r, double strength) {
    _withMouthFlip(canvas, m, () {
      final p = Paint()
        ..color = Colors.black87
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.06
        ..strokeCap = StrokeCap.round;
      final rect = Rect.fromCenter(
        center: m,
        width: r * (0.9 - 0.3 * strength),
        height: r * (0.6 + 0.3 * strength),
      );
      canvas.drawArc(rect, _deg(200), _deg(140), false, p);
    });
  }

  void _mouthFlat(Canvas canvas, Offset m, double r, {bool down = false}) {
    _withMouthFlip(canvas, m, () {
      final p = Paint()
        ..color = Colors.black87
        ..strokeWidth = r * 0.07
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      final dx = r * 0.35;
      final dy = r * (down ? 0.05 : 0);
      canvas.drawLine(m.translate(-dx, dy), m.translate(dx, dy), p);
    });
  }

  void _mouthSmirk(Canvas canvas, Offset m, double r) {
    _withMouthFlip(canvas, m, () {
      final p = Paint()
        ..color = Colors.black87
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.07
        ..strokeCap = StrokeCap.round;
      final rect = Rect.fromCenter(
        center: m.translate(r * 0.05, 0),
        width: r * 0.7,
        height: r * 0.55,
      );
      canvas.drawArc(rect, _deg(210), _deg(120), false, p);
    });
  }

  void _mouthO(Canvas canvas, Offset m, double r) {
    _withMouthFlip(canvas, m, () {
      canvas.drawCircle(
        m,
        r * 0.16,
        Paint()
          ..color = Colors.black87
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * 0.06,
      );
    });
  }

  void _mouthPout(Canvas canvas, Offset m, double r) {
    _withMouthFlip(canvas, m, () {
      final edge = Paint()
        ..color = Colors.black87
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.065
        ..strokeCap = StrokeCap.round;
      final rect = Rect.fromCenter(center: m, width: r * 0.35, height: r * 0.25);
      canvas.drawArc(rect, _deg(190), _deg(160), false, edge);
    });
  }

  void _mouthFunny(Canvas canvas, Offset m, double r) {
    _withMouthFlip(canvas, m, () {
      final p = Paint()
        ..color = Colors.black87
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.06
        ..strokeCap = StrokeCap.round;
      final rect = Rect.fromCenter(center: m, width: r * 0.8, height: r * 0.4);
      canvas.drawArc(rect, 0, math.pi, false, p);
    });
  }

  // ❤️ Hearts, eyebrows, blush, etc.
  void _eyesHearts(Canvas canvas, Offset l, Offset rEye, double r) {
    final paint = Paint()..color = const Color(0xFFE53935);
    _drawHeart(canvas, l, r * 0.09, paint);
    _drawHeart(canvas, rEye, r * 0.09, paint);
  }

  void _drawHeart(Canvas canvas, Offset c, double sz, Paint p) {
    final path = Path();
    final top = c.translate(0, -sz * 0.2);
    path.moveTo(top.dx, top.dy);
    path.cubicTo(
      c.dx - sz,
      c.dy - sz,
      c.dx - sz * 1.1,
      c.dy + sz * 0.4,
      c.dx,
      c.dy + sz,
    );
    path.cubicTo(
      c.dx + sz * 1.1,
      c.dy + sz * 0.4,
      c.dx + sz,
      c.dy - sz,
      top.dx,
      top.dy,
    );
    canvas.drawPath(path, p);
  }

  void _eyebrows(Canvas canvas, Offset l, Offset rEye, double r) {
    final p = Paint()
      ..color = Colors.black.withOpacity(0.85)
      ..strokeWidth = r * 0.06
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    Offset l1 = l.translate(-r * 0.12, -r * 0.2);
    Offset l2 = l.translate(r * 0.08, -r * 0.24);
    Offset r1 = rEye.translate(-r * 0.08, -r * 0.24);
    Offset r2 = rEye.translate(r * 0.12, -r * 0.2);
    if (expression == MarbleExpression.happy ||
        expression == MarbleExpression.mischievous) {
      l1 = l1.translate(0, r * 0.04);
      l2 = l2.translate(0, r * 0.02);
      r1 = r1.translate(0, r * 0.02);
      r2 = r2.translate(0, r * 0.04);
    }
    canvas.drawLine(l1, l2, p);
    canvas.drawLine(r1, r2, p);
  }

  void _eyeHighlights(Canvas canvas, Offset l, Offset rEye, double r) {
    final h = Paint()..color = Colors.white.withOpacity(0.9);
    final d = r * 0.03;
    canvas.drawCircle(l.translate(-d, -d), d, h);
    canvas.drawCircle(rEye.translate(-d, -d), d, h);
  }

  void _blush(Canvas canvas, Offset l, Offset rEye, double r) {
    if (expression == MarbleExpression.happy ||
        expression == MarbleExpression.mischievous) {
      final shaderL = RadialGradient(
        colors: [const Color(0xFFFF8A80).withOpacity(0.35), Colors.transparent],
        stops: const [0.0, 1.0],
      ).createShader(
        Rect.fromCircle(center: l.translate(0, r * 0.12), radius: r * 0.13),
      );
      canvas.drawCircle(
        l.translate(0, r * 0.12),
        r * 0.13,
        Paint()..shader = shaderL,
      );

      final shaderR = RadialGradient(
        colors: [const Color(0xFFFF8A80).withOpacity(0.35), Colors.transparent],
        stops: const [0.0, 1.0],
      ).createShader(
        Rect.fromCircle(center: rEye.translate(0, r * 0.12), radius: r * 0.13),
      );
      canvas.drawCircle(
        rEye.translate(0, r * 0.12),
        r * 0.13,
        Paint()..shader = shaderR,
      );
    }
  }

  double _deg(double d) => d * math.pi / 180;

  @override
  bool shouldRepaint(covariant MarbleFacePainter old) =>
      old.expression != expression ||
      old.style != style ||
      old.anchors != anchors ||
      old.flipMouth != flipMouth;
}
