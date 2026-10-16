import 'package:flutter/material.dart';

import '../design/app_colors.dart';
import '../design/tokens.dart';

/// An inline message block: errors, warnings, privacy notes, suggestions.
class InfoBanner extends StatelessWidget {
  const InfoBanner({
    super.key,
    required this.message,
    this.tone = StatusTone.neutral,
    this.icon,
    this.title,
    this.action,
  });

  final String message;
  final StatusTone tone;
  final IconData? icon;
  final String? title;
  final Widget? action;

  static IconData _defaultIcon(StatusTone tone) => switch (tone) {
    StatusTone.neutral => Icons.info_outline,
    StatusTone.success => Icons.check_circle_outline,
    StatusTone.warning => Icons.warning_amber_rounded,
    StatusTone.danger => Icons.error_outline,
    StatusTone.accent => Icons.lightbulb_outline,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors.tone(tone);
    return Semantics(
      container: true,
      liveRegion: tone == StatusTone.danger,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: AppRadius.mdAll,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon ?? _defaultIcon(tone),
                size: AppIconSize.md,
                color: colors.foreground,
              ),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (title != null)
                      Text(
                        title!,
                        style: theme.textTheme.titleSmall!.copyWith(
                          color: colors.foreground,
                        ),
                      ),
                    Text(
                      message,
                      style: theme.textTheme.bodyMedium!.copyWith(
                        color: colors.foreground,
                      ),
                    ),
                    if (action != null)
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: action,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
