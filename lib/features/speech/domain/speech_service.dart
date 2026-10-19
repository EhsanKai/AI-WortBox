import '../../../core/language/language.dart';

/// Reads text aloud with the device's own text-to-speech engine. No network
/// service is used; whether a voice exists depends on the device.
abstract interface class SpeechService {
  /// Speaks [text] in [language], interrupting anything still playing.
  ///
  /// Throws `SpeechException` when no voice for [language] is installed or
  /// the engine fails.
  Future<void> speak(String text, Language language);

  Future<void> stop();
}

/// Platform locale used for a language's voice.
String speechLocaleOf(Language language) => switch (language.code) {
  'de' => 'de-DE',
  'fa' => 'fa-IR',
  final code => code,
};
