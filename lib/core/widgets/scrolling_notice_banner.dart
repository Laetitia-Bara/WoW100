import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class ScrollingNoticeBanner extends StatefulWidget {
  const ScrollingNoticeBanner({
    super.key,
    required this.message,
    this.icon = Icons.construction_rounded,
  });

  final String message;
  final IconData icon;

  @override
  State<ScrollingNoticeBanner> createState() => _ScrollingNoticeBannerState();
}

class _ScrollingNoticeBannerState extends State<ScrollingNoticeBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 11),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppTheme.gold.withValues(alpha: 0.22),
          border: Border.all(color: AppTheme.gold.withValues(alpha: 0.7)),
        ),
        child: SizedBox(
          height: 44,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;

              return ClipRect(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    return Transform.translate(
                      offset: Offset(-_controller.value * width, 0),
                      child: SizedBox(
                        width: width * 2,
                        child: Row(
                          children: [
                            SizedBox(
                              width: width,
                              child: _ScrollingNoticeBannerContent(
                                message: widget.message,
                                icon: widget.icon,
                              ),
                            ),
                            SizedBox(
                              width: width,
                              child: _ScrollingNoticeBannerContent(
                                message: widget.message,
                                icon: widget.icon,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ScrollingNoticeBannerContent extends StatelessWidget {
  const _ScrollingNoticeBannerContent({
    required this.message,
    required this.icon,
  });

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: AppTheme.gold, size: 20),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            message,
            maxLines: 1,
            overflow: TextOverflow.fade,
            softWrap: false,
            style: const TextStyle(
              color: AppTheme.gold,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}
