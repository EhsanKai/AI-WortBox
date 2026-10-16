import 'package:flutter/material.dart';

import '../design/app_colors.dart';
import '../design/tokens.dart';

/// A small pill describing the state of an item (new, duplicate, error…).
///
/// The meaning is carried by the text; color and icon only reinforce it.
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    required this.tone,
    this.icon,
    this.textKey,
  });

  final String label;
  final StatusTone tone;
  final IconData? icon;

  /// Key for the label [Text], for tests that read the status.
  final Key? textKey;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors.tone(tone);
    final style = Theme.of(context).textTheme.labelMedium!
        .copyWith(color: colors.foreground);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.sm + AppSpace.xxs,
          vertical: AppSpace.xxs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: colors.foreground),
              const SizedBox(width: AppSpace.xs),
            ],
            Flexible(
              child: Text(label, key: textKey, style: style),
            ),
          ],
        ),
      ),
    );
  }
}
