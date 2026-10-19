import 'dart:typed_data';

import 'package:ai_wortbox/core/error/app_exception.dart';
import 'package:ai_wortbox/core/language/language.dart';
import 'package:ai_wortbox/features/export/domain/export_file_sink.dart';
import 'package:ai_wortbox/features/reminders/domain/reminder.dart';
import 'package:ai_wortbox/features/speech/domain/speech_service.dart';

/// Records what would have been spoken. Never touches a real TTS engine.
class FakeSpeechService implements SpeechService {
  final spoken = <(String, Language)>[];
  SpeechError? failWith;
  int stops = 0;

  @override
  Future<void> speak(String text, Language language) async {
    if (failWith case final error?) throw SpeechException(error);
    spoken.add((text, language));
  }

  @override
  Future<void> stop() async => stops++;
}

/// A notification scheduler that keeps "scheduled" reminders in a map keyed
/// by notification id, like the real plugin: scheduling again replaces.
class FakeReminderScheduler implements ReminderScheduler {
  bool grantPermission = true;
  bool failScheduling = false;
  bool failCancel = false;
  int permissionRequests = 0;

  /// id → (hour, minute, title)
  final scheduled = <int, (int, int, String)>{};
  int scheduleCalls = 0;

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    return grantPermission;
  }

  @override
  Future<void> scheduleDaily({
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    scheduleCalls++;
    if (failScheduling) {
      throw const ReminderException(ReminderError.schedulingFailed);
    }
    scheduled[1] = (hour, minute, title);
  }

  @override
  Future<void> cancel() async {
    if (failCancel) {
      throw const ReminderException(ReminderError.schedulingFailed);
    }
    scheduled.remove(1);
  }
}

/// Captures exported files instead of showing a save dialog.
class FakeExportSink implements ExportFileSink {
  final saved = <(String, Uint8List, String)>[];
  bool cancel = false;
  bool fail = false;

  @override
  Future<bool> save({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
  }) async {
    if (fail) throw const ExportException(ExportError.writeFailed);
    if (cancel) return false;
    saved.add((fileName, bytes, mimeType));
    return true;
  }
}
