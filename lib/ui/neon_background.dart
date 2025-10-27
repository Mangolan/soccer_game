import 'package:flutter/material.dart';

class NeonBackground extends StatelessWidget {
  final Widget child;

  const NeonBackground({super.key, required this.child});

  static const Color baseColor = Color(0xFF0A1931);
  static const Color glowColor = Color(0xFF00D9E1);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0A1931),
            Color(0xFF071427),
            Color(0xFF05101F),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Soft cyan glows in corners
          Positioned(
            top: -80,
            left: -60,
            child: _glow(180),
          ),
          Positioned(
            bottom: -100,
            right: -80,
            child: _glow(220),
          ),
          // Content
          child,
        ],
      ),
    );
  }

  Widget _glow(double size) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              glowColor,
              Colors.transparent,
            ],
            stops: [0.0, 1.0],
          ),
        ),
      ),
    );
  }
}

