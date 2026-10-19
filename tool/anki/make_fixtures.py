"""Creates the Anki import fixtures in test/fixtures/anki/ with the official
Anki library, so the importer is tested against files Anki itself wrote.

    python3 -m venv .venv && .venv/bin/pip install anki
    .venv/bin/python -I tool/anki/make_fixtures.py test/fixtures/anki

Not part of the app or the test run. The fixtures are committed.
"""
import os
import sys
import tempfile

from anki.collection import Collection, DeckIdLimit, ExportAnkiPackageOptions

out_dir = os.path.abspath(sys.argv[1])
work = tempfile.mkdtemp()
col = Collection(os.path.join(work, "fixture.anki2"))
deck = col.decks.id("Deutsch::Lektion 1")

basic = col.models.by_name("Basic")
reverse = col.models.by_name("Basic (and reversed card)")

def add(model, fields, tags=()):
    note = col.new_note(model)
    for name, value in fields.items():
        note[name] = value
    note.tags = list(tags)
    col.add_note(note, deck)

add(basic, {"Front": "das Haus", "Back": "خانه<br>منزل"}, ["A1", "Wohnen"])
add(basic, {"Front": "<b>gehen</b>", "Back": "رفتن&nbsp;/ راه رفتن"})
add(basic, {"Front": "die Mühe", "Back": "زحمت [sound:muehe.mp3]"}, ["A2"])
add(reverse, {"Front": "sich freuen", "Back": "خوشحال شدن"}, ["Verben"])
# A duplicate of the first note's word with the same meaning.
add(basic, {"Front": "das Haus", "Back": "خانه"})
# Empty front: must be reported as an invalid row, not crash.
add(basic, {"Front": "", "Back": "بدون لغت"})

for legacy in (False, True):
    name = "legacy_anki21.apkg" if legacy else "modern_anki21b.apkg"
    col.export_anki_package(
        out_path=os.path.join(out_dir, name),
        options=ExportAnkiPackageOptions(
            with_scheduling=False,
            with_deck_configs=False,
            with_media=True,
            legacy=legacy,
        ),
        limit=DeckIdLimit(deck),
    )
    print("wrote", name)
col.close()
