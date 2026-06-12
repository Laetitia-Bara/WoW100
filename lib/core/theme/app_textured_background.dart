import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'app_theme.dart';

class AppTexturedBackground extends StatelessWidget {
  const AppTexturedBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(
          child: RepaintBoundary(
            child: CustomPaint(painter: _LogoTexturePainter()),
          ),
        ),
        const Positioned.fill(child: _LogoBackgroundWatermark()),
        Positioned.fill(child: child),
      ],
    );
  }
}

class _LogoBackgroundWatermark extends StatelessWidget {
  const _LogoBackgroundWatermark();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Opacity(
        opacity: 0.16,
        child: ImageFiltered(
          imageFilter: ui.ImageFilter.blur(sigmaX: 1.2, sigmaY: 1.2),
          child: ColorFiltered(
            colorFilter: const ColorFilter.mode(
              Color(0xFF160817),
              BlendMode.multiply,
            ),
            child: Image.asset(
              'assets/images/icones/icone.png',
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),
          ),
        ),
      ),
    );
  }
}

class _LogoTexturePainter extends CustomPainter {
  const _LogoTexturePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    canvas.drawRect(rect, Paint()..color = AppTheme.background);

    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset.zero,
          Offset(size.width, size.height),
          const [Color(0xFF2B0820), Color(0xFF150713), Color(0xFF09060D)],
          const [0, 0.58, 1],
        ),
    );

    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.radial(
          Offset(size.width * 0.38, size.height * 0.12),
          size.longestSide * 0.76,
          [
            const Color(0xFF5B173D).withAlpha(72),
            const Color(0xFF2C0822).withAlpha(26),
            Colors.transparent,
          ],
          const [0, 0.54, 1],
        ),
    );

    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.radial(
          Offset(size.width * 0.86, size.height * 0.82),
          size.longestSide * 0.62,
          [
            const Color(0xFF7C1D28).withAlpha(44),
            const Color(0xFF2A0717).withAlpha(20),
            Colors.transparent,
          ],
          const [0, 0.5, 1],
        ),
    );

    _paintGrain(canvas, size);
    _paintFineVeins(canvas, size);
    _paintVignette(canvas, rect);
  }

  void _paintGrain(Canvas canvas, Size size) {
    final paint = Paint()..strokeCap = StrokeCap.round;
    const spacing = 17.0;

    for (var y = 0.0; y < size.height; y += spacing) {
      for (var x = 0.0; x < size.width; x += spacing) {
        final value = _noise(x * 0.021, y * 0.019);
        if (value < 0.36) {
          continue;
        }

        final warmFleck = value > 0.94;
        paint
          ..color = warmFleck
              ? AppTheme.gold.withAlpha(18)
              : const Color(0xFF8A2A61).withAlpha((value * 18).round())
          ..strokeWidth = warmFleck ? 1.1 : 0.75;

        canvas.drawPoints(ui.PointMode.points, [
          Offset(x + _noise(x, y) * spacing, y + _noise(y, x) * spacing),
        ], paint);
      }
    }
  }

  void _paintFineVeins(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7
      ..color = const Color(0xFFB03862).withAlpha(20);

    for (var index = 0; index < 30; index++) {
      final startX = _noise(index * 9.7, 2.3) * size.width;
      final startY = _noise(4.1, index * 13.9) * size.height;
      final length = 44 + _noise(index * 2.1, index * 5.3) * 120;
      final angle = -0.8 + _noise(index * 6.1, index * 3.7) * 1.6;
      final controlShift = 18 + _noise(index * 7.2, 1.8) * 34;

      final path = Path()..moveTo(startX, startY);
      path.cubicTo(
        startX + math.cos(angle) * controlShift,
        startY + math.sin(angle) * controlShift,
        startX + math.cos(angle + 0.28) * length * 0.65,
        startY + math.sin(angle + 0.28) * length * 0.65,
        startX + math.cos(angle) * length,
        startY + math.sin(angle) * length,
      );

      canvas.drawPath(path, paint);
    }
  }

  void _paintVignette(Canvas canvas, Rect rect) {
    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.radial(
          rect.center,
          rect.longestSide * 0.72,
          [Colors.transparent, const Color(0xFF050307).withAlpha(122)],
          const [0.46, 1],
        ),
    );
  }

  double _noise(double x, double y) {
    final value = math.sin(x * 12.9898 + y * 78.233) * 43758.5453;
    return value - value.floorToDouble();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
