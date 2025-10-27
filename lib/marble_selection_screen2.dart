import 'package:flutter/material.dart';
import 'difficulty_selection_screen.dart';
import 'package:soccer_game/marble_face.dart';

class MarbleSelectionScreen extends StatelessWidget {
  const MarbleSelectionScreen({super.key});

  static const List<MarbleStyle> samples = [
    MarbleStyle(baseColor: Colors.blue),
    MarbleStyle(baseColor: Colors.red),
    MarbleStyle(baseColor: Colors.green),
    MarbleStyle(baseColor: Colors.orange),
    MarbleStyle(baseColor: Colors.purple),
    MarbleStyle(baseColor: Colors.cyan, glass: true, gloss: 0.8, opacity: 0.95),
    MarbleStyle(baseColor: Colors.amber, glass: true, gloss: 0.7),
    MarbleStyle(baseColor: Colors.teal, gloss: 0.4),
    MarbleStyle(baseColor: Colors.pink),
  ];
  static const List<MarbleExpression> sampleExpressions = [
    MarbleExpression.happy,
    MarbleExpression.mischievous,
    MarbleExpression.sad,
    MarbleExpression.neutral,
    MarbleExpression.happy,
    MarbleExpression.mischievous,
    MarbleExpression.sad,
    MarbleExpression.neutral,
    MarbleExpression.happy,
  ];
  static const List<EyeStyle> eyeStyles = [
    EyeStyle.normal,
    EyeStyle.glasses,
    EyeStyle.sunglasses,
    EyeStyle.closed,
    EyeStyle.big,
    EyeStyle.wink,
    EyeStyle.angry,
    EyeStyle.sad,
    EyeStyle.funny,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('구슬 선택'),
        centerTitle: true,
        backgroundColor: const Color(0xFF0A1931),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFF0A1931),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 60), // 👈 기존 40 → 60으로 수정 (전체 조금 더 아래로)
              const Text(
                '마음에 드는 구슬을 선택하세요',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                '다음 화면에서 AI 난이도를 고를 수 있어요',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 40), // 👈 그리드와의 간격도 살짝 넓힘
              Expanded(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 20, // 👈 간격 살짝 확대
                      mainAxisSpacing: 20,
                      childAspectRatio: 1,
                    ),
                    itemCount: samples.length,
                    itemBuilder: (context, index) {
                      final style = samples[index];
                      final expr = sampleExpressions[index % sampleExpressions.length];
                      final eyes = eyeStyles[index % eyeStyles.length];
                      return _MarbleTile(
                        style: style,
                        expression: expr,
                        eyeStyle: eyes,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => DifficultySelectionScreen(
                                selectedMarble: style,
                                selectedExpression: expr,
                                selectedEyeStyle: eyes,
                                selectedHumanize: true,
                                selectedFlipMouth: true,
                                selectedIndex: index,
                              ),
                            ),
                          );
                        },
                      );
                    },
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

class _MarbleTile extends StatelessWidget {
  final MarbleStyle style;
  final MarbleExpression expression;
  final EyeStyle eyeStyle;
  final VoidCallback onTap;

  const _MarbleTile({
    required this.style,
    required this.expression,
    required this.eyeStyle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const Color glowColor = Color(0xFF00D9E1);
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: glowColor.withOpacity(0.5),
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Center(
              child: CustomPaint(
                painter: MarbleFacePainter(
                  style: style,
                  expression: expression,
                  humanize: true,
                  flipMouth: true,
                  eyeStyle: eyeStyle,
                ),
                size: const Size.square(88),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
