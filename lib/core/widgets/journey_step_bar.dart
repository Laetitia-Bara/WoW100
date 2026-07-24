import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class JourneyStepBar extends StatelessWidget implements PreferredSizeWidget {
  const JourneyStepBar({
    super.key,
    required this.currentStep,
    required this.onStep1,
    required this.onStep2,
    required this.onStep3,
  });

  final int currentStep;
  final VoidCallback onStep1;
  final VoidCallback onStep2;
  final VoidCallback onStep3;

  @override
  Size get preferredSize => const Size.fromHeight(70);

  @override
  Widget build(BuildContext context) {
    final steps = [
      _JourneyStep(
        number: 1,
        label: 'Sélectionne les items à farmer',
        onPressed: onStep1,
      ),
      _JourneyStep(
        number: 2,
        label: 'Organise ta whishlist',
        onPressed: onStep2,
      ),
      _JourneyStep(number: 3, label: 'Prends la route', onPressed: onStep3),
    ];

    return Material(
      color: AppTheme.background.withValues(alpha: 0.94),
      child: SafeArea(
        top: false,
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 780) {
                return ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: steps.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final step = steps[index];

                    return SizedBox(
                      width: 248,
                      child: _JourneyStepButton(
                        step: step,
                        selected: currentStep == step.number,
                      ),
                    );
                  },
                );
              }

              return Row(
                children: [
                  for (var index = 0; index < steps.length; index++) ...[
                    Expanded(
                      child: _JourneyStepButton(
                        step: steps[index],
                        selected: currentStep == steps[index].number,
                      ),
                    ),
                    if (index < steps.length - 1) const SizedBox(width: 12),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _JourneyStep {
  const _JourneyStep({
    required this.number,
    required this.label,
    required this.onPressed,
  });

  final int number;
  final String label;
  final VoidCallback onPressed;
}

class _JourneyStepButton extends StatelessWidget {
  const _JourneyStepButton({required this.step, required this.selected});

  final _JourneyStep step;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = selected
        ? AppTheme.gold
        : Colors.white.withValues(alpha: 0.06);
    final foregroundColor = selected ? AppTheme.background : AppTheme.text;
    final borderColor = selected
        ? Colors.white.withValues(alpha: 0.62)
        : AppTheme.gold.withValues(alpha: 0.36);

    return FilledButton(
      onPressed: step.onPressed,
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 50),
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        textStyle: const TextStyle(fontWeight: FontWeight.w900),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: BorderSide(color: borderColor, width: selected ? 1.4 : 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepNumberBadge(number: step.number, selected: selected),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              step.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _StepNumberBadge extends StatelessWidget {
  const _StepNumberBadge({required this.number, required this.selected});

  final int number;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = selected
        ? AppTheme.background.withValues(alpha: 0.18)
        : AppTheme.gold.withValues(alpha: 0.14);
    final borderColor = selected
        ? AppTheme.background.withValues(alpha: 0.44)
        : AppTheme.gold.withValues(alpha: 0.62);
    final foregroundColor = selected ? AppTheme.background : AppTheme.gold;

    return Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor,
        border: Border.all(color: borderColor, width: 1.4),
      ),
      child: Text(
        '$number',
        style: TextStyle(
          color: foregroundColor,
          fontSize: 16,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
