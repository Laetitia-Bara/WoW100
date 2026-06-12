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
        const Positioned.fill(child: ColoredBox(color: AppTheme.background)),
        Positioned.fill(
          child: Image.asset(
            'assets/images/icones/wallpaper_app.jpg',
            fit: BoxFit.cover,
            alignment: Alignment.center,
            filterQuality: FilterQuality.medium,
          ),
        ),
        const Positioned.fill(child: _WallpaperVeil()),
        Positioned.fill(child: child),
      ],
    );
  }
}

class _WallpaperVeil extends StatelessWidget {
  const _WallpaperVeil();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(child: CustomPaint(painter: _WallpaperVeilPainter()));
  }
}

class _WallpaperVeilPainter extends CustomPainter {
  const _WallpaperVeilPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset.zero,
          Offset(0, size.height),
          const [Color(0xB309030B), Color(0x66150713), Color(0xCC050307)],
          const [0, 0.48, 1],
        ),
    );

    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.radial(
          rect.center,
          rect.longestSide * 0.68,
          [Colors.transparent, const Color(0xFF050307).withAlpha(132)],
          const [0.46, 1],
        ),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
