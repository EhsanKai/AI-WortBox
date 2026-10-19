import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/language/language.dart';
import '../domain/speech_service.dart';

/// [SpeechService] backed by the system engine via `flutter_tts` (Android
/// TextToSpeech, iOS AVSpeechSynthesizer). Runs offline when the voice is
/// installed on the device; no network service is involved.
///
/// On iOS the shared audio session is put in the playback category before
/// the first utterance. Without it, iOS uses the default "solo ambient"
/// category, which the Ring/Silent switch mutes, so speech was silent on a
/// phone in silent mode while the engine still reported success. Other
/// apps' audio is ducked while a word is spoken and restored afterwards.
///
/// Requests are handled one at a time. A newer request replaces an older
/// one that has not started yet, and every utterance first stops the one
/// still playing, so repeated taps never overlap or queue up.
class FlutterTtsSpeechService implements SpeechService {
  FlutterTtsSpeechService([FlutterTts? tts, bool? configureIosAudioSession])
    : _tts = tts ?? FlutterTts(),
      _configureIosAudio =
          configureIosAudioSession ??
          (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS);

  /// The channel of the `flutter_tts` plugin (see [_prepareAudioSession]).
  static const _channel = MethodChannel('flutter_tts');

  final FlutterTts _tts;
  final bool _configureIosAudio;
  bool _audioSessionReady = false;
  String? _locale;
  Future<void> _previous = Future.value();
  int _latest = 0;

  @override
  Future<void> speak(String text, Language language) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    final request = ++_latest;
    final previous = _previous;
    final done = Completer<void>();
    _previous = done.future;
    try {
      await previous;
      // A newer tap arrived while waiting: only the newest one is spoken.
      if (request != _latest) return;
      await _speakNow(trimmed, speechLocaleOf(language));
    } finally {
      done.complete();
    }
  }

  Future<void> _speakNow(String text, String locale) async {
    try {
      await _prepareAudioSession();
      await _tts.stop();
      if (_locale != locale) {
        final available = await _tts.isLanguageAvailable(locale);
        if (available != true) {
          _log('No voice for $locale is installed');
          throw const SpeechException(SpeechError.voiceUnavailable);
        }
        // iOS answers 0 when it has no voice for the language.
        final set = await _tts.setLanguage(locale);
        if (set == 0) {
          _log('The engine refused language $locale');
          throw const SpeechException(SpeechError.voiceUnavailable);
        }
        _locale = locale;
      }
      final result = await _tts.speak(text);
      // Android and iOS report 1 when the utterance was accepted.
      if (result != null && result != 1) {
        _log('speak returned $result');
        throw const SpeechException(SpeechError.failed);
      }
    } on SpeechException {
      rethrow;
    } on PlatformException catch (e, stackTrace) {
      _log('Platform error ${e.code}: ${e.message}', e, stackTrace);
      throw const SpeechException(SpeechError.failed);
    } on MissingPluginException catch (e, stackTrace) {
      _log('Speech plugin missing', e, stackTrace);
      throw const SpeechException(SpeechError.failed);
    }
  }

  /// iOS only, once. A failure is logged and retried next time; speaking is
  /// still attempted (it works with the switch set to ring).
  ///
  /// Calls the plugin's own method on its channel: the Dart wrapper
  /// `FlutterTts.setIosAudioCategory` hides failures (it prints and returns
  /// null), so a failed setup could not be told apart from success.
  Future<void> _prepareAudioSession() async {
    if (!_configureIosAudio || _audioSessionReady) return;
    try {
      final result = await _channel.invokeMethod<Object?>(
        'setIosAudioCategory',
        const {
          iosAudioCategoryKey: iosAudioCategoryPlayback,
          iosAudioCategoryOptionsKey: [iosAudioCategoryOptionsDuckOthers],
          iosAudioModeKey: iosAudioModeDefault,
        },
      );
      _audioSessionReady = result == 1;
      if (!_audioSessionReady) _log('setIosAudioCategory returned $result');
    } on Object catch (e, stackTrace) {
      _log('Could not configure the audio session', e, stackTrace);
    }
  }

  @override
  Future<void> stop() async {
    _latest++;
    try {
      await _tts.stop();
    } on Object {
      // Nothing to stop or no engine: not an error for the user.
    }
  }

  void _log(String message, [Object? error, StackTrace? stackTrace]) =>
      developer.log(
        message,
        name: 'ai_wortbox.speech',
        error: error,
        stackTrace: stackTrace,
      );
}
