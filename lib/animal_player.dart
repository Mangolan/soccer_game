import 'package:flutter/material.dart';

enum AnimalKind {
  bunny,
  bear,
  duck,
  cat,
  puppy,
  seal,
  hamster,
  fox,
  panda,
}

class AnimalPlayer {
  const AnimalPlayer({
    required this.name,
    required this.kind,
    required this.bodyColor,
    required this.accentColor,
    required this.uniformColor,
    required this.trimColor,
  });

  final String name;
  final AnimalKind kind;
  final Color bodyColor;
  final Color accentColor;
  final Color uniformColor;
  final Color trimColor;
}

const List<AnimalPlayer> kAnimalPlayers = [
  AnimalPlayer(
    name: '토끼 인형',
    kind: AnimalKind.bunny,
    bodyColor: Color(0xFFFFC4D8),
    accentColor: Color(0xFFFFF2F7),
    uniformColor: Color(0xFFFF6F91),
    trimColor: Color(0xFFFFFFFF),
  ),
  AnimalPlayer(
    name: '곰 인형',
    kind: AnimalKind.bear,
    bodyColor: Color(0xFFC7833D),
    accentColor: Color(0xFFFFD39A),
    uniformColor: Color(0xFF3F7DFF),
    trimColor: Color(0xFFFFF4DD),
  ),
  AnimalPlayer(
    name: '오리 인형',
    kind: AnimalKind.duck,
    bodyColor: Color(0xFFFFE66D),
    accentColor: Color(0xFFFFF3A8),
    uniformColor: Color(0xFFFFA94D),
    trimColor: Color(0xFFFFFFFF),
  ),
  AnimalPlayer(
    name: '고양이 인형',
    kind: AnimalKind.cat,
    bodyColor: Color(0xFF86C8FF),
    accentColor: Color(0xFFFFFBF3),
    uniformColor: Color(0xFF845EF7),
    trimColor: Color(0xFFFFFFFF),
  ),
  AnimalPlayer(
    name: '강아지 인형',
    kind: AnimalKind.puppy,
    bodyColor: Color(0xFFFFD29B),
    accentColor: Color(0xFFFFF3D7),
    uniformColor: Color(0xFF2F9E44),
    trimColor: Color(0xFFFFFFFF),
  ),
  AnimalPlayer(
    name: '물범 인형',
    kind: AnimalKind.seal,
    bodyColor: Color(0xFFDDE7F2),
    accentColor: Color(0xFFFFFFFF),
    uniformColor: Color(0xFF4C6EF5),
    trimColor: Color(0xFFE7F5FF),
  ),
  AnimalPlayer(
    name: '햄스터 인형',
    kind: AnimalKind.hamster,
    bodyColor: Color(0xFFE9B575),
    accentColor: Color(0xFFFFE1B8),
    uniformColor: Color(0xFFE8590C),
    trimColor: Color(0xFFFFF4E6),
  ),
  AnimalPlayer(
    name: '여우 인형',
    kind: AnimalKind.fox,
    bodyColor: Color(0xFFFF9F43),
    accentColor: Color(0xFFFFE8CC),
    uniformColor: Color(0xFFD6336C),
    trimColor: Color(0xFFFFFFFF),
  ),
  AnimalPlayer(
    name: '판다 인형',
    kind: AnimalKind.panda,
    bodyColor: Color(0xFFFFFFFF),
    accentColor: Color(0xFF212529),
    uniformColor: Color(0xFF1098AD),
    trimColor: Color(0xFFFFFFFF),
  ),
];

class AnimalPlush extends StatelessWidget {
  const AnimalPlush({
    super.key,
    required this.player,
    required this.size,
    this.soccerUniform = false,
  });

  final AnimalPlayer player;
  final double size;
  final bool soccerUniform;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size * 1.18),
      painter: AnimalPlushPainter(
        player: player,
        soccerUniform: soccerUniform,
      ),
    );
  }
}

class AnimalPlushPainter extends CustomPainter {
  const AnimalPlushPainter({
    required this.player,
    this.soccerUniform = false,
  });

  final AnimalPlayer player;
  final bool soccerUniform;

  Paint _fill(Color color) => Paint()
    ..color = color
    ..isAntiAlias = true;

  Paint _stroke(Color color, double width) => Paint()
    ..color = color
    ..isAntiAlias = true
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  void _eye(Canvas canvas, double x, double y, double r) {
    canvas.drawCircle(Offset(x, y), r, _fill(const Color(0xFF241513)));
    canvas.drawCircle(
      Offset(x - r * .25, y - r * .25),
      r * .25,
      _fill(Colors.white),
    );
  }

  void _nose(Canvas canvas, double x, double y, double w, double h) {
    canvas.drawOval(
      Rect.fromCenter(center: Offset(x, y), width: w, height: h),
      _fill(const Color(0xFF3E2723)),
    );
  }

  void _smile(Canvas canvas, double cx, double cy, double size) {
    final path = Path()
      ..moveTo(cx, cy)
      ..quadraticBezierTo(
        cx - size * .35,
        cy + size * .34,
        cx - size * .68,
        cy + size * .12,
      )
      ..moveTo(cx, cy)
      ..quadraticBezierTo(
        cx + size * .35,
        cy + size * .34,
        cx + size * .68,
        cy + size * .12,
      );
    canvas.drawPath(path, _stroke(const Color(0xFF3E2723), size * .10));
  }

  void _blush(Canvas canvas, double x, double y, double width) {
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(x, y),
        width: width,
        height: width * .58,
      ),
      _fill(const Color(0x55FF7A98)),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    _drawShadow(canvas, size);
    switch (player.kind) {
      case AnimalKind.bunny:
        _drawRabbit(canvas, size);
        break;
      case AnimalKind.bear:
        _drawBear(canvas, size);
        break;
      case AnimalKind.duck:
        _drawDuck(canvas, size);
        break;
      case AnimalKind.cat:
        _drawCat(canvas, size);
        break;
      case AnimalKind.puppy:
        _drawPuppy(canvas, size);
        break;
      case AnimalKind.seal:
        _drawSeal(canvas, size);
        break;
      case AnimalKind.hamster:
        _drawHamster(canvas, size);
        break;
      case AnimalKind.fox:
        _drawFox(canvas, size);
        break;
      case AnimalKind.panda:
        _drawPanda(canvas, size);
        break;
    }
    if (soccerUniform) {
      _drawUniform(canvas, size);
    }
  }

  void _drawShadow(Canvas canvas, Size size) {
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * .5, size.height * .98),
        width: size.width * .48,
        height: size.height * .08,
      ),
      _fill(const Color(0x22000000)),
    );
  }

  void _drawUniform(Canvas canvas, Size size) {
    final jersey = player.uniformColor;
    final shorts = jersey.withOpacity(.98);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * .27,
          size.height * .61,
          size.width * .46,
          size.height * .22,
        ),
        Radius.circular(size.width * .08),
      ),
      _fill(jersey.withOpacity(.92)),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * .22,
          size.height * .76,
          size.width * .56,
          size.height * .16,
        ),
        Radius.circular(size.width * .10),
      ),
      _fill(shorts.withOpacity(.95)),
    );
    canvas.drawLine(
      Offset(size.width * .31, size.height * .68),
      Offset(size.width * .15, size.height * .60),
      _stroke(jersey, size.width * .08),
    );
    canvas.drawLine(
      Offset(size.width * .69, size.height * .68),
      Offset(size.width * .85, size.height * .60),
      _stroke(jersey, size.width * .08),
    );
    final tp = TextPainter(
      text: TextSpan(
        text: _uniformNumber(player.kind),
        style: TextStyle(
          color: Colors.white,
          fontSize: size.width * .17,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset(size.width * .5 - tp.width / 2, size.height * .64),
    );
  }

  String _uniformNumber(AnimalKind kind) {
    switch (kind) {
      case AnimalKind.bunny:
        return '10';
      case AnimalKind.bear:
        return '07';
      case AnimalKind.duck:
        return '11';
      case AnimalKind.cat:
        return '03';
      case AnimalKind.puppy:
        return '09';
      case AnimalKind.seal:
        return '01';
      case AnimalKind.hamster:
        return '08';
      case AnimalKind.fox:
        return '17';
      case AnimalKind.panda:
        return '05';
    }
  }

  void _drawRabbit(Canvas canvas, Size size) {
    final main = _fill(player.bodyColor);
    final inner = _fill(player.accentColor);
    final shadow = _fill(player.bodyColor.withOpacity(.82));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * .20, 0, size.width * .17, size.height * .46),
        Radius.circular(size.width * .09),
      ),
      main,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * .62,
          0,
          size.width * .17,
          size.height * .46,
        ),
        Radius.circular(size.width * .09),
      ),
      main,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * .25,
          size.height * .07,
          size.width * .07,
          size.height * .30,
        ),
        Radius.circular(size.width * .04),
      ),
      inner,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * .67,
          size.height * .07,
          size.width * .07,
          size.height * .30,
        ),
        Radius.circular(size.width * .04),
      ),
      inner,
    );
    canvas.drawOval(
      Rect.fromLTWH(size.width * .15, size.height * .28, size.width * .70, size.height * .50),
      main,
    );
    canvas.drawOval(
      Rect.fromLTWH(size.width * .28, size.height * .62, size.width * .44, size.height * .28),
      main,
    );
    canvas.drawOval(
      Rect.fromLTWH(size.width * .38, size.height * .48, size.width * .24, size.height * .18),
      inner,
    );
    canvas.drawCircle(Offset(size.width * .25, size.height * .76), size.width * .07, shadow);
    canvas.drawCircle(Offset(size.width * .75, size.height * .76), size.width * .07, shadow);
    _eye(canvas, size.width * .39, size.height * .47, size.width * .045);
    _eye(canvas, size.width * .61, size.height * .47, size.width * .045);
    _nose(canvas, size.width * .50, size.height * .56, size.width * .075, size.height * .045);
    _smile(canvas, size.width * .50, size.height * .59, size.width * .14);
    _blush(canvas, size.width * .30, size.height * .58, size.width * .12);
    _blush(canvas, size.width * .70, size.height * .58, size.width * .12);
  }

  void _drawBear(Canvas canvas, Size size) {
    final main = _fill(player.bodyColor);
    final light = _fill(player.accentColor);
    canvas.drawCircle(Offset(size.width * .26, size.height * .26), size.width * .145, main);
    canvas.drawCircle(Offset(size.width * .74, size.height * .26), size.width * .145, main);
    canvas.drawCircle(
      Offset(size.width * .26, size.height * .26),
      size.width * .085,
      _fill(player.bodyColor.withOpacity(.84)),
    );
    canvas.drawCircle(
      Offset(size.width * .74, size.height * .26),
      size.width * .085,
      _fill(player.bodyColor.withOpacity(.84)),
    );
    canvas.drawOval(
      Rect.fromLTWH(size.width * .13, size.height * .18, size.width * .74, size.height * .56),
      main,
    );
    canvas.drawOval(
      Rect.fromLTWH(size.width * .24, size.height * .57, size.width * .52, size.height * .30),
      main,
    );
    canvas.drawOval(
      Rect.fromLTWH(size.width * .33, size.height * .46, size.width * .34, size.height * .23),
      light,
    );
    canvas.drawOval(
      Rect.fromLTWH(size.width * .36, size.height * .62, size.width * .28, size.height * .18),
      light,
    );
    canvas.drawCircle(Offset(size.width * .25, size.height * .78), size.width * .075, main);
    canvas.drawCircle(Offset(size.width * .75, size.height * .78), size.width * .075, main);
    _eye(canvas, size.width * .38, size.height * .41, size.width * .043);
    _eye(canvas, size.width * .62, size.height * .41, size.width * .043);
    _nose(canvas, size.width * .50, size.height * .53, size.width * .095, size.height * .065);
    _smile(canvas, size.width * .50, size.height * .58, size.width * .14);
    _blush(canvas, size.width * .30, size.height * .53, size.width * .11);
    _blush(canvas, size.width * .70, size.height * .53, size.width * .11);
  }

  void _drawDuck(Canvas canvas, Size size) {
    final yellow = _fill(player.bodyColor);
    final light = _fill(player.accentColor);
    final orange = _fill(const Color(0xFFFF9B45));
    canvas.drawOval(
      Rect.fromLTWH(size.width * .15, size.height * .45, size.width * .76, size.height * .35),
      yellow,
    );
    canvas.drawOval(
      Rect.fromLTWH(size.width * .21, size.height * .18, size.width * .48, size.height * .45),
      yellow,
    );
    canvas.drawCircle(Offset(size.width * .48, size.height * .18), size.width * .035, yellow);
    canvas.drawCircle(Offset(size.width * .44, size.height * .13), size.width * .026, yellow);
    canvas.drawOval(
      Rect.fromLTWH(size.width * .17, size.height * .56, size.width * .28, size.height * .17),
      light,
    );
    canvas.drawOval(
      Rect.fromLTWH(size.width * .56, size.height * .39, size.width * .32, size.height * .13),
      orange,
    );
    canvas.drawOval(
      Rect.fromLTWH(size.width * .22, size.height * .78, size.width * .22, size.height * .075),
      orange,
    );
    canvas.drawOval(
      Rect.fromLTWH(size.width * .58, size.height * .78, size.width * .24, size.height * .075),
      orange,
    );
    _eye(canvas, size.width * .39, size.height * .34, size.width * .04);
    _blush(canvas, size.width * .30, size.height * .43, size.width * .10);
  }

  void _drawCat(Canvas canvas, Size size) {
    final main = _fill(player.bodyColor);
    final inner = _fill(player.accentColor);
    final ear = _fill(const Color(0xFFFFD6E2));
    final leftEar = Path()
      ..moveTo(size.width * .22, size.height * .28)
      ..lineTo(size.width * .34, size.height * .04)
      ..lineTo(size.width * .46, size.height * .29)
      ..close();
    final rightEar = Path()
      ..moveTo(size.width * .54, size.height * .29)
      ..lineTo(size.width * .66, size.height * .04)
      ..lineTo(size.width * .78, size.height * .28)
      ..close();
    canvas.drawPath(leftEar, main);
    canvas.drawPath(rightEar, main);
    canvas.drawOval(
      Rect.fromLTWH(size.width * .14, size.height * .23, size.width * .72, size.height * .54),
      main,
    );
    canvas.drawOval(
      Rect.fromLTWH(size.width * .26, size.height * .61, size.width * .48, size.height * .28),
      main,
    );
    canvas.drawOval(
      Rect.fromLTWH(size.width * .34, size.height * .48, size.width * .32, size.height * .20),
      inner,
    );
    final leftInner = Path()
      ..moveTo(size.width * .29, size.height * .25)
      ..lineTo(size.width * .34, size.height * .12)
      ..lineTo(size.width * .40, size.height * .25)
      ..close();
    final rightInner = Path()
      ..moveTo(size.width * .60, size.height * .25)
      ..lineTo(size.width * .66, size.height * .12)
      ..lineTo(size.width * .71, size.height * .25)
      ..close();
    canvas.drawPath(leftInner, ear);
    canvas.drawPath(rightInner, ear);
    _eye(canvas, size.width * .38, size.height * .42, size.width * .04);
    _eye(canvas, size.width * .62, size.height * .42, size.width * .04);
    _nose(canvas, size.width * .50, size.height * .51, size.width * .06, size.height * .045);
    _smile(canvas, size.width * .50, size.height * .55, size.width * .12);
  }

  void _drawPuppy(Canvas canvas, Size size) {
    final main = _fill(player.bodyColor);
    final light = _fill(player.accentColor);
    final brown = _fill(const Color(0xFF9A6A52));
    canvas.drawOval(
      Rect.fromLTWH(size.width * .18, size.height * .23, size.width * .64, size.height * .50),
      main,
    );
    canvas.drawOval(
      Rect.fromLTWH(size.width * .28, size.height * .60, size.width * .44, size.height * .30),
      main,
    );
    canvas.drawOval(
      Rect.fromLTWH(size.width * .10, size.height * .25, size.width * .22, size.height * .35),
      brown,
    );
    canvas.drawOval(
      Rect.fromLTWH(size.width * .68, size.height * .25, size.width * .22, size.height * .35),
      brown,
    );
    canvas.drawOval(
      Rect.fromLTWH(size.width * .37, size.height * .47, size.width * .26, size.height * .17),
      light,
    );
    canvas.drawOval(
      Rect.fromLTWH(size.width * .42, size.height * .23, size.width * .16, size.height * .18),
      light,
    );
    _eye(canvas, size.width * .39, size.height * .41, size.width * .04);
    _eye(canvas, size.width * .61, size.height * .41, size.width * .04);
    _nose(canvas, size.width * .50, size.height * .51, size.width * .075, size.height * .05);
    _smile(canvas, size.width * .50, size.height * .56, size.width * .13);
    _blush(canvas, size.width * .30, size.height * .53, size.width * .11);
    _blush(canvas, size.width * .70, size.height * .53, size.width * .11);
  }

  void _drawSeal(Canvas canvas, Size size) {
    final gray = _fill(player.bodyColor);
    final light = _fill(player.accentColor);
    canvas.drawOval(
      Rect.fromLTWH(size.width * .08, size.height * .36, size.width * .84, size.height * .38),
      gray,
    );
    canvas.drawCircle(Offset(size.width * .52, size.height * .34), size.width * .28, gray);
    canvas.drawOval(
      Rect.fromLTWH(size.width * .34, size.height * .42, size.width * .36, size.height * .20),
      light,
    );
    _eye(canvas, size.width * .42, size.height * .31, size.width * .035);
    _eye(canvas, size.width * .62, size.height * .31, size.width * .035);
    _nose(canvas, size.width * .52, size.height * .40, size.width * .07, size.height * .05);
    _smile(canvas, size.width * .52, size.height * .44, size.width * .12);
    _blush(canvas, size.width * .31, size.height * .42, size.width * .11);
    _blush(canvas, size.width * .73, size.height * .42, size.width * .11);
  }

  void _drawHamster(Canvas canvas, Size size) {
    final main = _fill(player.bodyColor);
    final light = _fill(player.accentColor);
    canvas.drawCircle(Offset(size.width * .28, size.height * .30), size.width * .13, main);
    canvas.drawCircle(Offset(size.width * .72, size.height * .30), size.width * .13, main);
    canvas.drawCircle(
      Offset(size.width * .28, size.height * .30),
      size.width * .075,
      _fill(const Color(0xFFFFB8C7)),
    );
    canvas.drawCircle(
      Offset(size.width * .72, size.height * .30),
      size.width * .075,
      _fill(const Color(0xFFFFB8C7)),
    );
    canvas.drawOval(
      Rect.fromLTWH(size.width * .12, size.height * .20, size.width * .76, size.height * .62),
      main,
    );
    canvas.drawOval(
      Rect.fromLTWH(size.width * .23, size.height * .50, size.width * .54, size.height * .33),
      light,
    );
    canvas.drawOval(
      Rect.fromLTWH(size.width * .36, size.height * .47, size.width * .28, size.height * .18),
      light,
    );
    _eye(canvas, size.width * .38, size.height * .41, size.width * .04);
    _eye(canvas, size.width * .62, size.height * .41, size.width * .04);
    _nose(canvas, size.width * .50, size.height * .52, size.width * .06, size.height * .045);
    _smile(canvas, size.width * .50, size.height * .56, size.width * .11);
  }

  void _drawFox(Canvas canvas, Size size) {
    final main = _fill(player.bodyColor);
    final light = _fill(player.accentColor);
    final leftEar = Path()
      ..moveTo(size.width * .20, size.height * .30)
      ..lineTo(size.width * .33, size.height * .03)
      ..lineTo(size.width * .45, size.height * .28)
      ..close();
    final rightEar = Path()
      ..moveTo(size.width * .55, size.height * .28)
      ..lineTo(size.width * .67, size.height * .03)
      ..lineTo(size.width * .80, size.height * .30)
      ..close();
    canvas.drawPath(leftEar, main);
    canvas.drawPath(rightEar, main);
    canvas.drawOval(
      Rect.fromLTWH(size.width * .14, size.height * .22, size.width * .72, size.height * .54),
      main,
    );
    canvas.drawOval(
      Rect.fromLTWH(size.width * .26, size.height * .61, size.width * .48, size.height * .28),
      main,
    );
    final muzzle = Path()
      ..moveTo(size.width * .28, size.height * .44)
      ..quadraticBezierTo(size.width * .50, size.height * .72, size.width * .72, size.height * .44)
      ..quadraticBezierTo(size.width * .50, size.height * .57, size.width * .28, size.height * .44)
      ..close();
    canvas.drawPath(muzzle, light);
    _eye(canvas, size.width * .38, size.height * .40, size.width * .04);
    _eye(canvas, size.width * .62, size.height * .40, size.width * .04);
    _nose(canvas, size.width * .50, size.height * .50, size.width * .07, size.height * .05);
    _smile(canvas, size.width * .50, size.height * .55, size.width * .13);
  }

  void _drawPanda(Canvas canvas, Size size) {
    final white = _fill(player.bodyColor);
    final black = _fill(player.accentColor);
    canvas.drawCircle(Offset(size.width * .28, size.height * .24), size.width * .12, black);
    canvas.drawCircle(Offset(size.width * .72, size.height * .24), size.width * .12, black);
    canvas.drawOval(
      Rect.fromLTWH(size.width * .14, size.height * .18, size.width * .72, size.height * .58),
      white,
    );
    canvas.drawOval(
      Rect.fromLTWH(size.width * .26, size.height * .60, size.width * .48, size.height * .30),
      white,
    );
    canvas.drawOval(
      Rect.fromLTWH(size.width * .26, size.height * .34, size.width * .20, size.height * .16),
      black,
    );
    canvas.drawOval(
      Rect.fromLTWH(size.width * .54, size.height * .34, size.width * .20, size.height * .16),
      black,
    );
    canvas.drawCircle(Offset(size.width * .26, size.height * .78), size.width * .08, black);
    canvas.drawCircle(Offset(size.width * .74, size.height * .78), size.width * .08, black);
    _eye(canvas, size.width * .37, size.height * .42, size.width * .04);
    _eye(canvas, size.width * .63, size.height * .42, size.width * .04);
    _nose(canvas, size.width * .50, size.height * .52, size.width * .08, size.height * .05);
    _smile(canvas, size.width * .50, size.height * .57, size.width * .13);
    _blush(canvas, size.width * .29, size.height * .53, size.width * .10);
    _blush(canvas, size.width * .71, size.height * .53, size.width * .10);
  }

  @override
  bool shouldRepaint(covariant AnimalPlushPainter oldDelegate) {
    return oldDelegate.player != player ||
        oldDelegate.soccerUniform != soccerUniform;
  }
}
