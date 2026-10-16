import 'package:flutter/foundation.dart';

/// A selected word or contiguous expression, as a character range in the
/// scan text. Ranges never overlap.
@immutable
class SelectedRange implements Comparable<SelectedRange> {
  const SelectedRange(this.start, this.end) : assert(start < end);

  final int start;
  final int end;

  bool overlaps(SelectedRange other) => start < other.end && other.start < end;

  bool contains(int offset) => offset >= start && offset < end;

  SelectedRange shift(int delta) => SelectedRange(start + delta, end + delta);

  @override
  int compareTo(SelectedRange other) => start.compareTo(other.start);

  @override
  bool operator ==(Object other) =>
      other is SelectedRange && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => 'SelectedRange($start, $end)';
}

/// The user's selections, kept sorted. Anchored to character offsets, so they
/// do not depend on how the text is laid out on screen.
@immutable
class WordSelection {
  const WordSelection([this.ranges = const []]);

  final List<SelectedRange> ranges;

  bool get isEmpty => ranges.isEmpty;

  int get length => ranges.length;

  SelectedRange? rangeAt(int offset) =>
      ranges.where((r) => r.contains(offset)).firstOrNull;

  /// Adds [range], replacing any selections it overlaps.
  WordSelection add(SelectedRange range) {
    final kept = ranges.where((r) => !r.overlaps(range)).toList()
      ..add(range)
      ..sort();
    return WordSelection(List.unmodifiable(kept));
  }

  /// Selects the word [range], or deselects the selection containing it.
  WordSelection toggle(SelectedRange range) {
    final existing = rangeAt(range.start);
    if (existing != null) return remove(existing);
    return add(range);
  }

  WordSelection remove(SelectedRange range) =>
      WordSelection(List.unmodifiable(ranges.where((r) => r != range)));

  /// Keeps selections valid after the text changed from [oldText] to
  /// [newText]. Selections before or after the changed region are kept
  /// (shifted if needed) when their text is unchanged; selections touching
  /// the changed region are dropped.
  (WordSelection, int dropped) remap(String oldText, String newText) {
    var prefix = 0;
    final minLength = oldText.length < newText.length
        ? oldText.length
        : newText.length;
    while (prefix < minLength && oldText[prefix] == newText[prefix]) {
      prefix++;
    }
    var suffix = 0;
    while (suffix < minLength - prefix &&
        oldText[oldText.length - 1 - suffix] ==
            newText[newText.length - 1 - suffix]) {
      suffix++;
    }
    final changedOldEnd = oldText.length - suffix;
    final delta = newText.length - oldText.length;

    final kept = <SelectedRange>[];
    for (final range in ranges) {
      if (range.end <= prefix) {
        kept.add(range);
      } else if (range.start >= changedOldEnd) {
        kept.add(range.shift(delta));
      }
    }
    return (
      WordSelection(List.unmodifiable(kept)),
      ranges.length - kept.length,
    );
  }
}
