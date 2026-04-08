import 'dart:math' as math;
import 'package:flutter/material.dart';

class AdaptiveAnimatedBackground extends StatefulWidget {
  final Widget child;

  const AdaptiveAnimatedBackground({super.key, required this.child});

  @override
  State<AdaptiveAnimatedBackground> createState() => _AdaptiveAnimatedBackgroundState();
}

class _AdaptiveAnimatedBackgroundState extends State<AdaptiveAnimatedBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF161618) : const Color(0xFFF9F9FB);

    return Container(
      color: backgroundColor,
      child: Stack(
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return CustomPaint(
                  painter: _WavePainter(
                    animationValue: _controller.value,
                    isDark: isDark,
                  ),
                );
              },
            ),
          ),
          widget.child,
        ],
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  final double animationValue;
  final bool isDark;

  _WavePainter({required this.animationValue, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint1 = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        colors: isDark
            ? [const Color(0xFF1E88E5).withOpacity(0.15), const Color(0xFF8E24AA).withOpacity(0.15)]
            : [const Color(0xFFE3F2FD).withOpacity(0.6), const Color(0xFFE8F5E9).withOpacity(0.6)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final paint2 = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        colors: isDark
            ? [const Color(0xFF8E24AA).withOpacity(0.1), const Color(0xFF3949AB).withOpacity(0.1)]
            : [const Color(0xFFF3E5F5).withOpacity(0.5), const Color(0xFFE3F2FD).withOpacity(0.5)],
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    _drawWave(canvas, size, paint1, 0.75, 1.2, animationValue * 2 * math.pi);
    _drawWave(canvas, size, paint2, 0.82, 1.8, (animationValue + 0.3) * 2 * math.pi);
  }

  void _drawWave(
      Canvas canvas, Size size, Paint paint, double heightRatio, double frequency, double phaseOffset) {
    final path = Path();
    final baseHeight = size.height * heightRatio;
    final amplitude = size.height * 0.04;

    path.moveTo(0, size.height);
    path.lineTo(0, baseHeight + math.sin(phaseOffset) * amplitude);

    for (double i = 0; i <= size.width; i += 10) {
      final xProgress = i / size.width;
      final y = baseHeight + math.sin(xProgress * frequency * math.pi * 2 + phaseOffset) * amplitude;
      path.lineTo(i, y);
    }

    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue || oldDelegate.isDark != isDark;
  }
}
