# Anki compatibility tools

Developer tools for checking AI WortBox's Anki support with the official
Anki library (the Python backend of Anki desktop, `pip install anki`).
They are not part of the app, and they are not run by `flutter test`.

```sh
python3 -m venv .venv && .venv/bin/pip install anki

# Recreate the import fixtures in test/fixtures/anki/ (written by Anki):
.venv/bin/python -I tool/anki/make_fixtures.py test/fixtures/anki

# Write a sample export from the app's exporter, then import it with Anki
# and compare every field and tag:
ANKI_EXPORT_DIR=/tmp/aiwb-anki flutter test test/features/anki \
  --plain-name "writes a sample"
.venv/bin/python -I tool/anki/validate_apkg.py \
  /tmp/aiwb-anki/sample.apkg /tmp/aiwb-anki/sample.expected.json
```

Last verified result (Anki library 26.09.3, 2026-10-19): `new=2`, all
fields and tags as expected, Anki's database check passed; importing the
same file again reported both notes as duplicates.
