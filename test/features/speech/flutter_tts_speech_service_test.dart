import 'package:ai_wortbox/core/error/app_exception.dart';
import 'package:ai_wortbox/core/language/language.dart';
import 'package:ai_wortbox/features/speech/data/flutter_tts_speech_service.dart';
import 'package:ai_wortbox/features/speech/domain/speech_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

// These tests replace the plugin's method channel. They check what the app
// asks the engine to do and how failures are reported; they cannot tell
// whether a device has a German voice or how it sounds.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('flutter_tts');
  late List<MethodCall> calls;
  late Object? Function(MethodCall) reply;

  setUp(() {
    calls = [];
    reply = (call) => switch (call.method) {
      'isLanguageAvailable' => true,
      'speak' || 'setLanguage' || 'stop' || 'setIosAudioCategory' => 1,
      _ => null,
    };
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return reply(call);
        });
  });
  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null),
  );

  Matcher failsWith(SpeechError error) =>
      throwsA(isA<SpeechException>().having((e) => e.error, 'error', error));

  test('German uses de-DE; the voice is checked once, then reused', () async {
    final service = FlutterTtsSpeechService();
    await service.speak(' das Haus ', Language.german);
    await service.speak('die Mühe', Language.german);
    final methods = calls.map((c) => c.method).toList();
    expect(methods.where((m) => m == 'isLanguageAvailable'), hasLength(1));
    expect(
      calls.firstWhere((c) => c.method == 'setLanguage').arguments,
      'de-DE',
    );
    // Each request interrupts what is playing first.
    expect(methods.where((m) => m == 'stop'), hasLength(2));
    final spoken = calls.where((c) => c.method == 'speak').map((c) {
      final args = c.arguments;
      return args is Map ? args['text'] : args;
    });
    expect(spoken, ['das Haus', 'die Mühe']);
  });

  test('blank text is not sent', () async {
    await FlutterTtsSpeechService().speak('  ', Language.german);
    expect(calls, isEmpty);
  });

  test(
    'no German voice installed → voiceUnavailable, nothing spoken',
    () async {
      reply = (call) => call.method == 'isLanguageAvailable' ? false : 1;
      await expectLater(
        FlutterTtsSpeechService().speak('Haus', Language.german),
        failsWith(SpeechError.voiceUnavailable),
      );
      expect(calls.where((c) => c.method == 'speak'), isEmpty);
    },
  );

  test('engine errors and a refused request → failed', () async {
    reply = (call) => call.method == 'speak'
        ? throw PlatformException(code: 'TTS_ERROR')
        : (call.method == 'isLanguageAvailable' ? true : 1);
    await expectLater(
      FlutterTtsSpeechService().speak('Haus', Language.german),
      failsWith(SpeechError.failed),
    );
    reply = (call) => call.method == 'speak'
        ? 0
        : (call.method == 'isLanguageAvailable' ? true : 1);
    await expectLater(
      FlutterTtsSpeechService().speak('Haus', Language.german),
      failsWith(SpeechError.failed),
    );
  });

  test('stop never throws', () async {
    reply = (_) => throw PlatformException(code: 'x');
    await FlutterTtsSpeechService().stop();
  });

  group('iOS audio session', () {
    test('playback category (not muted by the silent switch) is set once, '
        'before the first utterance', () async {
      final service = FlutterTtsSpeechService(null, true);
      await service.speak('Haus', Language.german);
      await service.speak('Baum', Language.german);
      final methods = calls.map((c) => c.method).toList();
      expect(methods.where((m) => m == 'setIosAudioCategory'), hasLength(1));
      expect(
        methods.indexOf('setIosAudioCategory'),
        lessThan(methods.indexOf('speak')),
      );
      final args =
          calls.firstWhere((c) => c.method == 'setIosAudioCategory').arguments
              as Map;
      expect(args['iosAudioCategoryKey'], 'iosAudioCategoryPlayback');
      expect(
        args['iosAudioCategoryOptionsKey'],
        contains('iosAudioCategoryOptionsDuckOthers'),
      );
      // Speech is never routed through a microphone-capable category.
      expect(args['iosAudioCategoryKey'], isNot(contains('Record')));
    });

    test('not touched on Android', () async {
      await FlutterTtsSpeechService(null, false).speak('Haus', Language.german);
      expect(
        calls.map((c) => c.method),
        isNot(contains('setIosAudioCategory')),
      );
    });

    test('a failing audio session does not prevent speaking and is retried '
        'next time', () async {
      reply = (call) => switch (call.method) {
        'setIosAudioCategory' => throw PlatformException(code: 'session'),
        'isLanguageAvailable' => true,
        _ => 1,
      };
      final service = FlutterTtsSpeechService(null, true);
      await service.speak('Haus', Language.german);
      await service.speak('Haus', Language.german);
      final methods = calls.map((c) => c.method);
      expect(methods.where((m) => m == 'speak'), hasLength(2));
      expect(methods.where((m) => m == 'setIosAudioCategory'), hasLength(2));
    });
  });

  test('rapid repeated taps: only the newest request is spoken, nothing '
      'overlaps', () async {
    final service = FlutterTtsSpeechService(null, false);
    await Future.wait([
      service.speak('eins', Language.german),
      service.speak('zwei', Language.german),
      service.speak('drei', Language.german),
    ]);
    final spoken = calls.where((c) => c.method == 'speak').map((c) {
      final args = c.arguments;
      return args is Map ? args['text'] : args;
    });
    expect(spoken, ['drei']);
  });

  test('tapping again after playback restarts: stop, then speak', () async {
    final service = FlutterTtsSpeechService(null, false);
    await service.speak('Haus', Language.german);
    calls.clear();
    await service.speak('Haus', Language.german);
    expect(calls.map((c) => c.method), ['stop', 'speak']);
  });

  test('stop cancels a request that has not started yet', () async {
    final service = FlutterTtsSpeechService(null, false);
    final pending = service.speak('Haus', Language.german);
    await service.stop();
    await pending;
    expect(calls.map((c) => c.method), isNot(contains('speak')));
  });

  test('the engine refusing the language → voiceUnavailable', () async {
    reply = (call) => switch (call.method) {
      'isLanguageAvailable' => true,
      'setLanguage' => 0,
      _ => 1,
    };
    await expectLater(
      FlutterTtsSpeechService(null, false).speak('Haus', Language.german),
      failsWith(SpeechError.voiceUnavailable),
    );
    expect(calls.where((c) => c.method == 'speak'), isEmpty);
  });

  test('after a failure the next tap tries again', () async {
    var fail = true;
    reply = (call) => switch (call.method) {
      'isLanguageAvailable' => true,
      'speak' when fail => throw PlatformException(code: 'busy'),
      _ => 1,
    };
    final service = FlutterTtsSpeechService(null, false);
    await expectLater(
      service.speak('Haus', Language.german),
      failsWith(SpeechError.failed),
    );
    fail = false;
    await service.speak('Haus', Language.german);
    expect(calls.where((c) => c.method == 'speak'), hasLength(2));
  });

  test('locales', () {
    expect(speechLocaleOf(Language.german), 'de-DE');
    expect(speechLocaleOf(Language.persian), 'fa-IR');
  });
}
