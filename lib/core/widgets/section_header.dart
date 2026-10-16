import 'package:flutter/material.dart';

import '../design/app_colors.dart';
import '../design/tokens.dart';

/// A section title with the yellow "box tab" marker.
class SectionHeader extends StatelessWidget {
  const SectionHeader(
    this.title, {
    super.key,
    this.trailing,
    this.padding = const EdgeInsets.only(bottom: AppSpace.sm),
  });

  final String title;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: padding,
      child: Semantics(
        header: true,
        child: Row(
          children: [
            Container(
              width: 4,
              height: 18,
              decoration: BoxDecoration(
                color: context.colors.box,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
            const SizedBox(width: AppSpace.sm),
            Expanded(child: Text(title, style: theme.textTheme.titleSmall)),
            ?trailing,
          ],
        ),
      ),
    );
  }
}
