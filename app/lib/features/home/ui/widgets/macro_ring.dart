import 'package:flutter/material.dart';

class MacroRing extends StatelessWidget {
  const MacroRing({
    super.key,
    required this.label,
    required this.current,
    required this.target,
    this.subtitle,
  });

  final String label;
  final double current;
  final double target;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final clampedTarget = target <= 0 ? 1.0 : target;
    final theme = Theme.of(context);
    final ratio = current / clampedTarget;
    final baseProgress = ratio.clamp(0.0, 1.0);
    final overflowProgress = ratio > 1.0 ? (ratio - 1.0).clamp(0.0, 1.0) : 0.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 96,
          height: 96,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 96,
                height: 96,
                child: CircularProgressIndicator(
                  value: baseProgress,
                  strokeWidth: 10,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                ),
              ),
              if (overflowProgress > 0)
                SizedBox(
                  width: 96,
                  height: 96,
                  child: CircularProgressIndicator(
                    value: overflowProgress,
                    strokeWidth: 10,
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.error),
                  ),
                ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    current.toStringAsFixed(0),
                    style: theme.textTheme.titleMedium,
                  ),
                  Text(
                    '/ ${clampedTarget.toStringAsFixed(0)}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: theme.textTheme.bodyMedium),
        if (subtitle != null) Text(subtitle!, style: theme.textTheme.bodySmall),
      ],
    );
  }
}
