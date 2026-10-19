// Opt-in live test against the real OpenRouter API. Skipped unless the
// environment provides a key. It runs in free-only mode (the default), so
// it uses free models only and costs nothing, but it counts against the
// account's daily free requests. Never commit a key.
//
//   OPENROUTER_API_KEY=sk-or-... flutter test test/live/openrouter_live_test.dart
@Tags(['live'])
library;

import 'dart:io';

import 'package:ai_wortbox/core/language/language.dart';
import 'package:ai_wortbox/core/text/script_detector.dart';
import 'package:ai_wortbox/core/time/clock.dart';
import 'package:ai_wortbox/features/enrichment/data/openrouter_client.dart';
import 'package:ai_wortbox/features/enrichment/data/openrouter_enrichment_service.dart';
import 'package:ai_wortbox/features/enrichment/domain/enrichment.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../helpers/ai_fakes.dart';

void main() {
  final key = Platform.environment['OPENROUTER_API_KEY'];
  final skip = key == null || key.isEmpty
      ? 'Set OPENROUTER_API_KEY to run live OpenRouter tests.'
      : null;

  late http.Client httpClient;
  setUp(() => httpClient = http.Client());
  tearDown(() => httpClient.close());

  test('the key is accepted by GET /key', () async {
    final info = await OpenRouterClient(httpClient).keyInfo(key!);
    expect(info, isA<OpenRouterKeyInfo>());
  }, skip: skip);

  test(
    'enriches a scanned word with a validated structured result',
    () async {
      final service = OpenRouterEnrichmentService(
        client: OpenRouterClient(httpClient),
        settings: InMemoryAiSettingsStore(
          apiKey: key,
          model: Platform.environment['OPENROUTER_MODEL'],
        ),
        clock: const SystemClock(),
      );
      final proposal = await service.enrich(
        const EnrichmentRequest(
          original: 'ging',
          sourceContext: 'Am Morgen ging sie mit großer Mühe in die Stadt.',
          sourceLanguage: Language.german,
          definitionLanguage: Language.persian,
        ),
      );
      expect(proposal.meanings, isNotEmpty);
      expect(
        proposal.meanings.every((m) => ScriptDetector.isMostlyRtl(m.text)),
        isTrue,
      );
      // Printed for manual inspection of quality; contains no secrets.
      // ignore: avoid_print
      print(
        'model=${proposal.model} cost=${proposal.costUsd} '
        'meanings=${proposal.meanings.map((m) => m.text).toList()} '
        'lemma=${proposal.lemma} pos=${proposal.partOfSpeech}',
      );
    },
    skip: skip,
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
