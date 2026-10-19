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

/// Lets the user choose the tags of one entry, and create new ones.
Future<void> showEntryTagsSheet(
  BuildContext context, {
  required String entryId,
  required Set<String> selected,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => _EntryTagsSheet(entryId: entryId, initial: selected),
);

class _EntryTagsSheet extends ConsumerStatefulWidget {
  const _EntryTagsSheet({required this.entryId, required this.initial});

  final String entryId;
  final Set<String> initial;

  @override
  ConsumerState<_EntryTagsSheet> createState() => _EntryTagsSheetState();
}

class _EntryTagsSheetState extends ConsumerState<_EntryTagsSheet> {
  late final Set<String> _selected = {...widget.initial};
  final _name = TextEditingController();
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final l10n = AppLocalizations.of(context);
    try {
      final tag = await ref.read(tagRepositoryProvider).createTag(_name.text);
      _name.clear();
      setState(() {
        _selected.add(tag.id);
        _error = null;
      });
    } on AppException catch (e) {
      setState(() => _error = errorMessage(l10n, e));
    }
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _saving = true);
    try {
      await ref
          .read(tagRepositoryProvider)
          .setEntryTags(widget.entryId, _selected);
      if (mounted) Navigator.pop(context);
    } on AppException catch (e) {
      if (mounted) {
        setState(() {
          _error = errorMessage(l10n, e);
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tags = ref.watch(tagsProvider).value ?? const <Tag>[];
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.8,
          ),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(
              AppSpace.gutter,
              0,
              AppSpace.gutter,
              AppSpace.lg,
            ),
            children: [
              Text(
                l10n.tagsEditTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpace.md),
              if (tags.isEmpty) Text(l10n.tagsEmptyHint),
              for (final tag in tags)
                CheckboxListTile(
                  key: Key('entryTags.${tag.id}'),
                  contentPadding: EdgeInsets.zero,
                  value: _selected.contains(tag.id),
                  title: Text(bidiIsolate(tag.name)),
                  onChanged: (value) => setState(
                    () => value == true
                        ? _selected.add(tag.id)
                        : _selected.remove(tag.id),
                  ),
                ),
              const SizedBox(height: AppSpace.sm),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
                      key: const Key('entryTags.newName'),
                      controller: _name,
                      maxLength: TagNames.maxLength,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        labelText: l10n.tagNewLabel,
                        errorText: _error,
                      ),
                      onSubmitted: (_) => _create(),
                    ),
                  ),
                  const SizedBox(width: AppSpace.sm),
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpace.sm),
                    child: IconButton.filledTonal(
                      key: const Key('entryTags.create'),
                      tooltip: l10n.tagCreate,
                      onPressed: _create,
                      icon: const Icon(Icons.add),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.md),
              FilledButton(
                key: const Key('entryTags.save'),
                onPressed: _saving ? null : _save,
                child: Text(l10n.actionSave),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
