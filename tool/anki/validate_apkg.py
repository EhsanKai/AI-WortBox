"""Imports an .apkg into a fresh, empty collection with the official Anki
library and checks the result against an expectations JSON file.

    .venv/bin/python -I tool/anki/validate_apkg.py export.apkg expected.json

expected.json: {"deck": str, "note_type": str, "fields": [str],
                "notes": [{"fields": {name: value}, "tags": [str]}]}
Exit code 0 only if Anki imported every note with exactly these values.
"""
import json
import os
import sys
import tempfile

from anki.collection import Collection, ImportAnkiPackageRequest

package, expected_path = map(os.path.abspath, sys.argv[1:3])
expected = json.load(open(expected_path, encoding="utf-8"))

col = Collection(os.path.join(tempfile.mkdtemp(), "check.anki2"))
result = col.import_anki_package(ImportAnkiPackageRequest(package_path=package))
log = result.log
print(f"anki import: new={len(log.new)} updated={len(log.updated)} "
      f"duplicate={len(log.duplicate)} conflicting={len(log.conflicting)} "
      f"first_field_match={len(log.first_field_match)} missing_notetype="
      f"{len(log.missing_notetype)} empty_first_field={len(log.empty_first_field)}")

errors = []
note_ids = col.find_notes("")
if len(note_ids) != len(expected["notes"]):
    errors.append(f"note count {len(note_ids)} != {len(expected['notes'])}")

model = col.models.by_name(expected["note_type"])
if model is None:
    errors.append(f"note type {expected['note_type']!r} missing")
else:
    names = [f["name"] for f in model["flds"]]
    if names != expected["fields"]:
        errors.append(f"fields {names} != {expected['fields']}")

if col.decks.id_for_name(expected["deck"]) is None:
    errors.append(f"deck {expected['deck']!r} missing")

actual = []
for nid in note_ids:
    note = col.get_note(nid)
    actual.append({"fields": dict(note.items()), "tags": sorted(note.tags)})
actual.sort(key=lambda n: n["fields"].get(expected["fields"][0], ""))
want = sorted(
    ({"fields": n["fields"], "tags": sorted(n["tags"])} for n in expected["notes"]),
    key=lambda n: n["fields"].get(expected["fields"][0], ""),
)
for a, w in zip(actual, want):
    for name, value in w["fields"].items():
        if a["fields"].get(name) != value:
            errors.append(f"{w['fields'][expected['fields'][0]]!r}: field "
                          f"{name!r} = {a['fields'].get(name)!r}, expected {value!r}")
    if a["tags"] != w["tags"]:
        errors.append(f"tags {a['tags']} != {w['tags']}")

cards = col.find_cards("")
print(f"notes={len(note_ids)} cards={len(cards)} "
      f"check_database={col.fix_integrity()[1]}")
col.close()
if errors:
    print("FAILED:\n  " + "\n  ".join(errors))
    sys.exit(1)
print("OK: Anki imported the package with the expected content")
