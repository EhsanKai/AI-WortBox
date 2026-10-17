import 'package:flutter/foundation.dart';

@immutable
class AiModelOption {
  const AiModelOption(this.id, this.label);

  /// OpenRouter model id.
  final String id;

  /// Shown in the model selector (product names are not translated).
  final String label;
}

/// Curated models for enrichment.
///
/// Chosen (2026-10-16) from OpenRouter's public model list: each supports
/// structured outputs (`structured_outputs`), handles Persian, is inexpensive,
/// and had no announced expiry date. Availability can change; the key check
/// verifies the selected model against the live list. See
/// docs/decisions.md (D29).
abstract final class AiModelCatalog {
  static const models = [
    AiModelOption('anthropic/claude-haiku-5.5', 'Claude Haiku 5.5'),
    AiModelOption('google/gemini-3.5-flash-lite', 'Gemini 3.5 Flash Lite'),
    AiModelOption('openai/gpt-5-mini', 'GPT-5 mini'),
    AiModelOption('openai/gpt-4o-mini', 'GPT-4o mini'),
    AiModelOption(
      'mistralai/mistral-small-3.2-24b-instruct',
      'Mistral Small 3.2',
    ),
  ];

  static const defaultModel = 'anthropic/claude-haiku-5.5';

  static AiModelOption? byId(String id) =>
      models.where((m) => m.id == id).firstOrNull;

  /// [id] if it is in the catalog, otherwise the default.
  static String resolve(String? id) =>
      id != null && byId(id) != null ? id : defaultModel;
}
