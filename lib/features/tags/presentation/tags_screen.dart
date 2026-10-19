import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/design/tokens.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/text/bidi.dart';
import '../../../core/widgets/state_views.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/tag.dart';
import 'tag_providers.dart';

/// Create, rename and delete tags. Deleting a tag removes it from its words;
/// the words themselves are kept.
class TagsScreen extends ConsumerWidget {
  const TagsScreen({super.key});

  Future<void> _editName(
    BuildContext context,
    WidgetRef ref, {
    Tag? tag,
  }) async {
    final l10n = AppLocalizations.of(context);
    final repository = ref.read(tagRepositoryProvider);
    final controller = TextEditingController(text: tag?.name ?? '');
    String? error;
    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          Future<void> submit() async {
            try {
              if (tag == null) {
                await repository.createTag(controller.text);
              } else {
                await repository.renameTag(tag.id, controller.text);
              }
              if (context.mounted) Navigator.pop(context);
            } on AppException catch (e) {
              setState(() => error = errorMessage(l10n, e));
            }
          }

          return AlertDialog(
            scrollable: true,
            title: Text(tag == null ? l10n.tagCreate : l10n.tagRename),
            content: TextField(
              key: const Key('tags.nameField'),
              controller: controller,
              autofocus: true,
              maxLength: TagNames.maxLength,
              decoration: InputDecoration(
                labelText: l10n.tagNameLabel,
                errorText: error,
              ),
              onSubmitted: (_) => submit(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.actionCancel),
              ),
              FilledButton(
                key: const Key('tags.saveName'),
                onPressed: submit,
                child: Text(l10n.actionSave),
              ),
            ],
          );
        },
      ),
    );
    controller.dispose();
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, Tag tag) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        title: Text(l10n.tagDeleteTitle(bidiIsolate(tag.name))),
        content: Text(l10n.tagDeleteBody(tag.entryCount)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            key: const Key('tags.confirmDelete'),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.actionDelete),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(tagRepositoryProvider).deleteTag(tag.id);
    } on AppException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(errorMessage(l10n, e))));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final tags = ref.watch(tagsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.tagsTitle)),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('tags.create'),
        onPressed: () => _editName(context, ref),
        icon: const Icon(Icons.add),
        label: Text(l10n.tagCreate),
      ),
      body: switch (tags) {
        AsyncData(:final value) when value.isEmpty => EmptyStateView(
          icon: Icons.label_outline,
          title: l10n.tagsEmptyTitle,
          message: l10n.tagsEmptyHint,
        ),
        AsyncData(:final value) => ListView.separated(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.gutter,
            AppSpace.sm,
            AppSpace.gutter,
            AppSpace.fabClearance,
          ),
          itemCount: value.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpace.sm),
          itemBuilder: (context, index) {
            final tag = value[index];
            return Card(
              child: ListTile(
                key: Key('tags.${tag.id}'),
                leading: const Icon(Icons.label_outline),
                title: Text(bidiIsolate(tag.name)),
                subtitle: Text(l10n.tagWordCount(tag.entryCount)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      key: Key('tags.${tag.id}.rename'),
                      tooltip: l10n.tagRename,
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => _editName(context, ref, tag: tag),
                    ),
                    IconButton(
                      key: Key('tags.${tag.id}.delete'),
                      tooltip: l10n.actionDelete,
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _delete(context, ref, tag),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        AsyncError(:final error) => ErrorStateView(
          error: error,
          onRetry: () => ref.invalidate(tagsProvider),
        ),
        _ => const LoadingView(),
      },
    );
  }
}
