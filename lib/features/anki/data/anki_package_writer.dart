import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:sqlite3/sqlite3.dart';

import '../../vocabulary/domain/vocabulary_entry.dart';
import '../domain/anki_html.dart';
import 'anki_sqlite.dart';

/// Writes vocabulary as an Anki package (`.apkg`).
///
/// Format: a ZIP with `collection.anki2` (SQLite, Anki collection schema
/// 11 — the "legacy" layout that current Anki, older Anki 2.1 versions and
/// AnkiDroid import) and an empty `media` map. Verified by importing the
/// output with the official Anki library (see `tool/anki/README.md`).
///
/// Content: one note per entry, using the note type [noteTypeName] with
/// the fields in [fields] and one card ("German → Persian"). Persian fields
/// are marked right-to-left. Tags become Anki tags (spaces replaced by
/// `_`, since Anki tags cannot contain spaces).
///
/// Not exported: review history, scheduling (cards are new in Anki),
/// difficult marks, statistics, settings and the API key.
///
/// Note GUIDs are derived from entry ids, so importing a later export of
/// the same words updates those notes in Anki instead of duplicating them.
abstract final class AnkiPackageWriter {
  static const noteTypeName = 'AI WortBox (German → Persian)';

  /// Field names. They match the CSV importer's recognized headers, so a
  /// package exported here is mapped automatically when imported back.
  static const fields = [
    'German',
    'Meaning',
    'Lemma',
    'Part of speech',
    'Grammar',
    'Example',
    'Example translation',
    'Notes',
    'Context',
  ];
  static const _rtlFields = {'Meaning', 'Example translation'};

  /// Fixed so that repeated exports reuse one note type in Anki.
  static const noteTypeId = 1760000000001;

  static Uint8List build({
    required String deckName,
    required List<VocabularyEntry> entries,
    required DateTime nowUtc,
    Map<String, List<String>> tagsByEntry = const {},
  }) {
    final (_, collection) = withMemoryDatabase(
      (db) => _write(db, deckName, entries, tagsByEntry, nowUtc),
    );
    final archive = Archive()
      ..add(ArchiveFile.bytes('collection.anki2', collection))
      ..add(ArchiveFile.bytes('media', utf8.encode('{}')));
    return Uint8List.fromList(ZipEncoder().encodeBytes(archive));
  }

  static void _write(
    Database db,
    String deckName,
    List<VocabularyEntry> entries,
    Map<String, List<String>> tagsByEntry,
    DateTime nowUtc,
  ) {
    final nowMs = nowUtc.millisecondsSinceEpoch;
    final nowSec = nowMs ~/ 1000;
    // Ids are millisecond timestamps in Anki; keep them unique and ordered.
    final deckId = nowMs;
    final dayStart = DateTime.utc(nowUtc.year, nowUtc.month, nowUtc.day);

    db.execute(_schema);
    db.execute(
      'INSERT INTO col VALUES (1, ?, ?, ?, 11, 0, 0, 0, ?, ?, ?, ?, ?)',
      [
        dayStart.millisecondsSinceEpoch ~/ 1000,
        nowMs,
        nowMs,
        jsonEncode(_conf(deckId)),
        jsonEncode({'$noteTypeId': _noteType(deckId, nowSec)}),
        jsonEncode({
          '1': _deck(1, 'Default', nowSec),
          '$deckId': _deck(deckId, deckName, nowSec),
        }),
        jsonEncode({'1': _deckConfig}),
        '{}',
      ],
    );

    final note = db.prepare(
      'INSERT INTO notes VALUES (?, ?, ?, ?, -1, ?, ?, ?, ?, 0, \'\')',
    );
    final card = db.prepare(
      'INSERT INTO cards VALUES '
      '(?, ?, ?, 0, ?, -1, 0, 0, ?, 0, 0, 0, 0, 0, 0, 0, 0, \'\')',
    );
    try {
      for (final (i, e) in entries.indexed) {
        final values = [
          e.original,
          e.meanings.map((m) => m.text).join('\n'),
          e.lemma ?? '',
          e.partOfSpeech ?? '',
          e.grammarInfo ?? '',
          e.exampleSentence ?? '',
          e.exampleTranslation ?? '',
          e.notes ?? '',
          e.sourceContext ?? '',
        ].map(AnkiHtml.fromText).toList();
        final tags = [
          for (final t in tagsByEntry[e.id] ?? const <String>[])
            t.trim().replaceAll(RegExp(r'\s+'), '_'),
        ].where((t) => t.isNotEmpty).toList();
        final sortField = AnkiHtml.toText(values.first);
        final noteId = nowMs + 1 + i;
        note.execute([
          noteId,
          'aiwortbox-${e.id}',
          noteTypeId,
          nowSec,
          tags.isEmpty ? '' : ' ${tags.join(' ')} ',
          values.join('\u001f'),
          sortField,
          checksum(sortField),
        ]);
        card.execute([
          nowMs + 1 + entries.length + i,
          noteId,
          deckId,
          nowSec,
          i + 1, // Position among new cards.
        ]);
      }
    } finally {
      note.close();
      card.close();
    }
  }

  /// Anki's duplicate checksum: the first 8 hex digits of the SHA-1 of the
  /// plain sort field, as an integer.
  static int checksum(String plainSortField) => int.parse(
    sha1.convert(utf8.encode(plainSortField)).toString().substring(0, 8),
    radix: 16,
  );

  static Map<String, Object?> _conf(int deckId) => {
    'activeDecks': [1],
    'curDeck': 1,
    'newSpread': 0,
    'collapseTime': 1200,
    'timeLim': 0,
    'estTimes': true,
    'dueCounts': true,
    'curModel': noteTypeId,
    'nextPos': 1,
    'sortType': 'noteFld',
    'sortBackwards': false,
    'addToCur': true,
    'schedVer': 2,
  };

  static const _css = '''
.card { font-family: sans-serif; font-size: 22px; line-height: 1.5;
  text-align: center; color: black; background-color: white; }
.de { font-size: 28px; }
.fa { direction: rtl; unicode-bidi: isolate; }
.small { font-size: 16px; color: #555; }
''';

  static Map<String, Object?> _noteType(int deckId, int nowSec) => {
    'id': noteTypeId,
    'name': noteTypeName,
    'type': 0,
    'mod': nowSec,
    'usn': -1,
    'sortf': 0,
    'did': deckId,
    'tmpls': [
      {
        'name': 'German → Persian',
        'ord': 0,
        'qfmt': '<div class="de" lang="de">{{German}}</div>',
        'afmt':
            '{{FrontSide}}\n\n<hr id=answer>\n\n'
            '<div class="fa" dir="rtl" lang="fa">{{Meaning}}</div>\n'
            '{{#Grammar}}<div class="small" lang="de">{{Grammar}}</div>'
            '{{/Grammar}}\n'
            '{{#Example}}<div class="small" lang="de">{{Example}}</div>'
            '{{/Example}}\n'
            '{{#Example translation}}<div class="small fa" dir="rtl" '
            'lang="fa">{{Example translation}}</div>{{/Example translation}}',
        'did': null,
        'bqfmt': '',
        'bafmt': '',
      },
    ],
    'flds': [
      for (final (ord, name) in fields.indexed)
        {
          'name': name,
          'ord': ord,
          'sticky': false,
          'rtl': _rtlFields.contains(name),
          'font': 'Arial',
          'size': 20,
          'media': <Object>[],
        },
    ],
    'css': _css,
    'latexPre':
        '\\documentclass[12pt]{article}\n\\special{papersize=3in,5in}\n'
        '\\usepackage[utf8]{inputenc}\n\\usepackage{amssymb,amsmath}\n'
        '\\pagestyle{empty}\n\\setlength{\\parindent}{0in}\n'
        '\\begin{document}\n',
    'latexPost': '\\end{document}',
    'latexsvg': false,
    'req': [
      [
        0,
        'any',
        [0],
      ],
    ],
    'tags': <Object>[],
    'vers': <Object>[],
  };

  static Map<String, Object?> _deck(int id, String name, int nowSec) => {
    'id': id,
    'name': name,
    'mod': nowSec,
    'usn': -1,
    'desc': '',
    'dyn': 0,
    'conf': 1,
    'collapsed': false,
    'browserCollapsed': false,
    'extendNew': 0,
    'extendRev': 0,
    'newToday': [0, 0],
    'revToday': [0, 0],
    'lrnToday': [0, 0],
    'timeToday': [0, 0],
  };

  static const Map<String, Object?> _deckConfig = {
    'id': 1,
    'name': 'Default',
    'mod': 0,
    'usn': 0,
    'maxTaken': 60,
    'autoplay': true,
    'timer': 0,
    'replayq': true,
    'dyn': false,
    'new': {
      'bury': false,
      'delays': [1.0, 10.0],
      'initialFactor': 2500,
      'ints': [1, 4, 0],
      'order': 1,
      'perDay': 20,
    },
    'rev': {
      'bury': false,
      'ease4': 1.3,
      'ivlFct': 1.0,
      'maxIvl': 36500,
      'perDay': 200,
      'hardFactor': 1.2,
    },
    'lapse': {
      'delays': [10.0],
      'leechAction': 1,
      'leechFails': 8,
      'minInt': 1,
      'mult': 0.0,
    },
  };

  static const _schema = '''
CREATE TABLE col (id integer primary key, crt integer not null,
  mod integer not null, scm integer not null, ver integer not null,
  dty integer not null, usn integer not null, ls integer not null,
  conf text not null, models text not null, decks text not null,
  dconf text not null, tags text not null);
CREATE TABLE notes (id integer primary key, guid text not null,
  mid integer not null, mod integer not null, usn integer not null,
  tags text not null, flds text not null, sfld integer not null,
  csum integer not null, flags integer not null, data text not null);
CREATE TABLE cards (id integer primary key, nid integer not null,
  did integer not null, ord integer not null, mod integer not null,
  usn integer not null, type integer not null, queue integer not null,
  due integer not null, ivl integer not null, factor integer not null,
  reps integer not null, lapses integer not null, left integer not null,
  odue integer not null, odid integer not null, flags integer not null,
  data text not null);
CREATE TABLE revlog (id integer primary key, cid integer not null,
  usn integer not null, ease integer not null, ivl integer not null,
  lastIvl integer not null, factor integer not null, time integer not null,
  type integer not null);
CREATE TABLE graves (usn integer not null, oid integer not null,
  type integer not null);
CREATE INDEX ix_notes_usn ON notes (usn);
CREATE INDEX ix_cards_usn ON cards (usn);
CREATE INDEX ix_revlog_usn ON revlog (usn);
CREATE INDEX ix_cards_nid ON cards (nid);
CREATE INDEX ix_cards_sched ON cards (did, queue, due);
CREATE INDEX ix_revlog_cid ON revlog (cid);
CREATE INDEX ix_notes_csum ON notes (csum);
''';
}
