import 'dart:convert';

import 'package:ai_wortbox/core/error/app_exception.dart';
import 'package:ai_wortbox/features/enrichment/data/ai_settings_store.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// A syntactically plausible key. Not a real credential.
const testApiKey = 'sk-or-v1-0000000000000000000000000000test1234';

/// In-memory replacement for the OS secure storage.
class InMemoryAiSettingsStore implements AiSettingsStore {
  InMemoryAiSettingsStore({this.apiKey, this.model});

  String? apiKey;
  String? model;

  /// Simulates a Keychain/Keystore failure of every operation.
  bool failing = false;

  /// Simulates failures of writes (key and model) or deletes only.
  bool failWrites = false;
  bool failDeletes = false;

  int writes = 0;

  void _check([bool alsoFail = false]) {
    if (failing || alsoFail) {
      throw const StorageException('secureStorage', 'test');
    }
  }

  @override
  Future<String?> readApiKey() async {
    _check();
    return apiKey;
  }

  @override
  Future<void> writeApiKey(String apiKey) async {
    _check(failWrites);
    writes++;
    this.apiKey = apiKey;
  }

  @override
  Future<void> deleteApiKey() async {
    _check(failDeletes);
    apiKey = null;
  }

  @override
  Future<String?> readModel() async {
    _check();
    return model;
  }

  @override
  Future<void> writeModel(String modelId) async {
    _check(failWrites);
    model = modelId;
  }
}

/// A valid structured enrichment payload (the model's JSON content).
Map<String, Object?> enrichmentContent({
  List<Map<String, Object?>> meanings = const [
    {'text': 'رفتن', 'explanation': null},
  ],
  String? partOfSpeech = 'verb',
  String? grammarInfo = 'ging, ist gegangen',
  String? lemma = 'gehen',
  String? exampleSentence = 'Wir gehen morgen ins Kino.',
  String? exampleTranslation = 'ما فردا به سینما می‌رویم.',
  bool isAmbiguous = false,
}) => {
  'meanings': meanings,
  'partOfSpeech': partOfSpeech,
  'grammarInfo': grammarInfo,
  'lemma': lemma,
  'exampleSentence': exampleSentence,
  'exampleTranslation': exampleTranslation,
  'isAmbiguous': isAmbiguous,
};

/// An OpenRouter chat-completions response wrapping [content].
http.Response completionResponse(
  Object content, {
  String model = 'anthropic/claude-haiku-5.5',
  double? cost,
  String finishReason = 'stop',
}) => http.Response.bytes(
  utf8.encode(
    jsonEncode({
      'id': 'gen-test',
      'model': model,
      'object': 'chat.completion',
      'choices': [
        {
          'index': 0,
          'finish_reason': finishReason,
          'message': {
            'role': 'assistant',
            'content': content is String ? content : jsonEncode(content),
          },
        },
      ],
      'usage': {
        'prompt_tokens': 300,
        'completion_tokens': 120,
        'total_tokens': 420,
        'cost': ?cost,
      },
    }),
  ),
  200,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

/// An OpenRouter error response in the documented shape.
http.Response errorResponse(
  int status, {
  String message = 'error',
  Map<String, String> headers = const {},
}) => http.Response(
  jsonEncode({
    'error': {'code': status, 'message': message},
  }),
  status,
  headers: {'content-type': 'application/json', ...headers},
);

http.Response keyInfoResponse({double usage = 0.0123, double? remaining}) =>
    http.Response(
      jsonEncode({
        'data': {
          'label': 'sk-or-v1-000...234',
          'limit': remaining == null ? null : 5.0,
          'limit_remaining': remaining,
          'usage': usage,
          'is_free_tier': false,
        },
      }),
      200,
      headers: {'content-type': 'application/json'},
    );

http.Response modelsResponse(List<String> ids) => http.Response(
  jsonEncode({
    'data': [
      for (final id in ids)
        {
          'id': id,
          'supported_parameters': ['response_format', 'structured_outputs'],
        },
    ],
  }),
  200,
  headers: {'content-type': 'application/json'},
);

/// A scripted fake of the OpenRouter API. Records every request.
class FakeOpenRouter {
  FakeOpenRouter({this.completions = const [], this.keyInfo, this.models});

  /// Responses (or errors to throw) for successive chat completions.
  List<Object> completions;
  Object? keyInfo;
  Object? models;
  final List<http.Request> requests = [];

  int get completionCalls =>
      requests.where((r) => r.url.path.endsWith('/chat/completions')).length;

  late final client = MockClient((request) async {
    requests.add(request);
    final path = request.url.path;
    Object? next;
    if (path.endsWith('/chat/completions')) {
      final index = completionCalls - 1;
      next = index < completions.length ? completions[index] : null;
    } else if (path.endsWith('/key')) {
      next = keyInfo;
    } else if (path.endsWith('/models')) {
      next = models;
    }
    if (next == null) {
      throw StateError('Unexpected request to ${request.url}');
    }
    if (next is http.Response) return next;
    if (next is Future<http.Response> Function()) return next();
    throw next;
  });
}

/// A client that fails the test if anything is sent (the default in widget
/// tests: AI must never call out unless a test sets it up).
final noNetworkClient = MockClient(
  (request) async => throw StateError('Unexpected request to ${request.url}'),
);
