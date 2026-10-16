import 'package:flutter/material.dart';

import '../design/app_colors.dart';
import '../design/tokens.dart';

/// One line of an [OutcomeView] summary.
class OutcomeLine {
  const OutcomeLine(this.icon, this.text, {this.tone = StatusTone.neutral});

  final IconData icon;
  final String text;
  final StatusTone tone;
}

/// The success screen after saving or importing: a summary and next steps.
class OutcomeView extends StatelessWidget {
  const OutcomeView({
    super.key,
    required this.title,
    required this.lines,
    required this.primary,
    this.secondary,
  });

  final String title;
  final List<OutcomeLine> lines;
  final Widget primary;
  final Widget? secondary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.xl,
        AppSpace.xxl,
        AppSpace.xl,
        AppSpace.xl,
      ),
      children: [
        Center(
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: colors.success.background,
              borderRadius: AppRadius.xlAll,
            ),
            child: Icon(
              Icons.check_rounded,
              size: AppIconSize.xl,
              color: colors.success.foreground,
            ),
          ),
        ),
        const SizedBox(height: AppSpace.lg),
        Semantics(
          header: true,
          liveRegion: true,
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall,
          ),
        ),
        const SizedBox(height: AppSpace.xl),
        Card(
          child: Column(
            children: [
              for (final (index, line) in lines.indexed) ...[
                if (index > 0) const Divider(indent: AppSpace.lg),
                ListTile(
                  leading: Icon(
                    line.icon,
                    color: line.tone == StatusTone.neutral
                        ? null
                        : colors.tone(line.tone).foreground,
                  ),
                  title: Text(line.text),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpace.xl),
        primary,
        if (secondary != null) ...[
          const SizedBox(height: AppSpace.sm),
          secondary!,
        ],
      ],
    );
  }
}
