import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/language/language.dart';
import '../../../core/widgets/state_views.dart';
import '../../../l10n/app_localizations.dart';

/// Plays [text] with the device's text-to-speech voice for [language].
/// Problems (no voice installed, engine failure) are shown as a message;
/// they never interrupt what the user is doing.
class SpeakButton extends ConsumerWidget {
  const SpeakButton({
    super.key,
    required this.text,
    this.language = Language.german,
    this.tooltip,
  });

  final String text;
  final Language language;
  final String? tooltip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return IconButton(
      tooltip: tooltip ?? l10n.speakWord,
      icon: const Icon(Icons.volume_up_outlined),
      onPressed: () async {
        final messenger = ScaffoldMessenger.of(context);
        try {
          await ref.read(speechServiceProvider).speak(text, language);
        } on AppException catch (e) {
          messenger
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(errorMessage(l10n, e))));
        }
      },
    );
  }
}
