/// Wraps [text] in Unicode directional isolates (FSI … PDI).
///
/// Use when user content of unknown direction (a German word, a deck name)
/// is inserted into a localized sentence. Without isolation, punctuation at
/// the edge of a German word inside a Persian sentence (e.g. «Hallo!») is
/// reordered by the bidi algorithm and appears on the wrong side.
String bidiIsolate(String text) => '\u2068$text\u2069';
