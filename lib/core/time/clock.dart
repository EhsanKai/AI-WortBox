/// Source of the current time. Inject a fixed clock in tests so that
/// timestamps and (later) review scheduling are deterministic.
abstract interface class Clock {
  /// The current instant in UTC.
  DateTime nowUtc();
}

class SystemClock implements Clock {
  const SystemClock();

  @override
  DateTime nowUtc() => DateTime.now().toUtc();
}

/// A manually controlled clock for tests.
class FixedClock implements Clock {
  FixedClock(DateTime now) : _now = now.toUtc();

  DateTime _now;

  @override
  DateTime nowUtc() => _now;

  void set(DateTime now) => _now = now.toUtc();

  void advance(Duration duration) => _now = _now.add(duration);
}
