import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../config/app_config.dart';
import '../design/app_colors.dart';
import '../design/tokens.dart';
import '../error/app_exception.dart';

/// Centered empty state: icon in a tinted box, title, message, action.
class EmptyStateView extends StatelessWidget {
  const EmptyStateView({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
    this.tone = StatusTone.warning,
    this.scrollable = true,
  });

  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  /// Tint of the icon box; the warm yellow by default, red for errors.
  final StatusTone tone;

  /// False when placed inside another scrollable (e.g. a list section).
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors.tone(tone);
    final content = Padding(
      padding: const EdgeInsets.all(AppSpace.xxl),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: colors.background,
                borderRadius: AppRadius.xlAll,
              ),
              child: Icon(
                icon,
                size: AppIconSize.xl - AppSpace.sm,
                color: colors.foreground,
              ),
            ),
            const SizedBox(height: AppSpace.lg + AppSpace.xs),
            Text(
              title,
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              const SizedBox(height: AppSpace.sm),
              Text(
                message!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: AppSpace.xl),
              action!,
            ],
          ],
        ),
      ),
    );
    return Center(
      child: scrollable ? SingleChildScrollView(child: content) : content,
    );
  }
}

/// Error state with a localized message and optional retry.
class ErrorStateView extends StatelessWidget {
  const ErrorStateView({super.key, required this.error, this.onRetry});

  final Object error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Semantics(
      liveRegion: true,
      child: EmptyStateView(
        icon: Icons.cloud_off_outlined,
        tone: StatusTone.danger,
        title: errorMessage(l10n, error),
        action: onRetry == null
            ? null
            : OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(l10n.actionRetry),
              ),
      ),
    );
  }
}

/// Full-area loading state with an optional message.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox.square(
              dimension: 36,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            if (message != null) ...[
              const SizedBox(height: AppSpace.lg),
              Semantics(
                liveRegion: true,
                child: Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Small spinner shown inside a button while its action runs.
class ButtonProgress extends StatelessWidget {
  const ButtonProgress({super.key});

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: 20,
    child: CircularProgressIndicator(
      strokeWidth: 2,
      color: DefaultTextStyle.of(context).style.color,
    ),
  );
}

/// Maps an error to a user-facing message. Technical details are never shown.
String errorMessage(AppLocalizations l10n, Object error) => switch (error) {
  StorageException() => l10n.errorStorage,
  NotFoundException() => l10n.errorEntryNotFound,
  VocabularyValidationException(:final errors)
      when errors.contains(VocabularyValidationError.deckNotFound) =>
    l10n.errorDeckNotFound,
  CsvFormatException(:final error, :final line) => switch (error) {
    CsvFormatError.empty => l10n.csvFormatEmpty,
    CsvFormatError.tooLarge => l10n.csvFormatTooLarge(
      AppConfig.maxCsvBytes ~/ (1024 * 1024),
    ),
    CsvFormatError.tooManyRows => l10n.csvFormatTooManyRows(
      AppConfig.maxCsvRows,
    ),
    CsvFormatError.unsupportedEncoding => l10n.csvFormatEncoding,
    CsvFormatError.unterminatedQuote => l10n.csvFormatUnterminatedQuote(
      line ?? 1,
    ),
    CsvFormatError.noDataRows => l10n.csvFormatNoDataRows,
  },
  ScanException(:final error) => switch (error) {
    ScanError.cameraPermissionDenied => l10n.scanErrorCameraPermission,
    ScanError.photoPermissionDenied => l10n.scanErrorPhotoPermission,
    ScanError.cameraUnavailable => l10n.scanErrorCameraUnavailable,
    ScanError.unsupportedFormat => l10n.scanErrorUnsupportedFormat,
    ScanError.imageTooLarge => l10n.scanErrorTooLarge,
    ScanError.unreadableImage => l10n.scanErrorUnreadable,
    ScanError.ocrUnavailable => l10n.scanErrorOcrUnavailable,
    ScanError.ocrFailed => l10n.scanErrorOcrFailed,
  },
  _ => l10n.errorGeneric,
};
