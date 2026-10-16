import 'package:ai_wortbox/features/scan/domain/word_selection.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('toggle selects and deselects, kept sorted', () {
    var s = const WordSelection();
    s = s.toggle(const SelectedRange(10, 14)).toggle(const SelectedRange(0, 3));
    expect(s.ranges, [const SelectedRange(0, 3), const SelectedRange(10, 14)]);
    s = s.toggle(const SelectedRange(11, 12));
    expect(s.ranges, [const SelectedRange(0, 3)]);
  });

  test('adding an expression replaces overlapping selections', () {
    final s = const WordSelection()
        .add(const SelectedRange(0, 3))
        .add(const SelectedRange(4, 8))
        .add(const SelectedRange(20, 25))
        .add(const SelectedRange(2, 10));
    expect(s.ranges, [const SelectedRange(2, 10), const SelectedRange(20, 25)]);
  });

  test('remap keeps unchanged selections and shifts later ones', () {
    const old = 'Das Haus ist alt und schön.';
    const edited = 'Das Haus ist sehr alt und schön.';
    final selection = const WordSelection()
        .add(SelectedRange(old.indexOf('Haus'), old.indexOf('Haus') + 4))
        .add(SelectedRange(old.indexOf('schön'), old.indexOf('schön') + 5));
    final (remapped, dropped) = selection.remap(old, edited);
    expect(dropped, 0);
    expect(remapped.ranges.map((r) => edited.substring(r.start, r.end)), [
      'Haus',
      'schön',
    ]);
  });

  test('remap drops selections whose text was corrected', () {
    const old = 'Das Hans ist alt.';
    const edited = 'Das Haus ist alt.';
    final selection = const WordSelection()
        .add(const SelectedRange(4, 8))
        .add(const SelectedRange(13, 16));
    final (remapped, dropped) = selection.remap(old, edited);
    expect(dropped, 1);
    expect(remapped.ranges, [const SelectedRange(13, 16)]);
  });
}
