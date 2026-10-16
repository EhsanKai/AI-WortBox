import 'package:flutter/material.dart';

import '../design/app_colors.dart';
import '../design/tokens.dart';

/// A large tappable choice: icon in a yellow box, title, description.
class ActionTile extends StatelessWidget {
  const ActionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.description,
  });

  final IconData icon;
  final String title;
  final String? description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.lg),
          child: Row(
            children: [
              Container(
                width: AppTouch.minTarget,
                height: AppTouch.minTarget,
                decoration: BoxDecoration(
                  color: colors.box,
                  borderRadius: AppRadius.mdAll,
                ),
                child: Icon(icon, color: colors.onBox),
              ),
              const SizedBox(width: AppSpace.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleMedium),
                    if (description != null)
                      Text(
                        description!,
                        style: theme.textTheme.bodyMedium!.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpace.sm),
              const DirectionalChevron(),
            ],
          ),
        ),
      ),
    );
  }
}

/// A "forward" chevron that points the right way in RTL and LTR layouts.
class DirectionalChevron extends StatelessWidget {
  const DirectionalChevron({super.key});

  @override
  Widget build(BuildContext context) => Icon(
    Directionality.of(context) == TextDirection.rtl
        ? Icons.chevron_left
        : Icons.chevron_right,
    color: Theme.of(context).colorScheme.onSurfaceVariant,
  );
}
