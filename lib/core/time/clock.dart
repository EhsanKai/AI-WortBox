/// Source of the current time. Inject a fixed clock in tests so that
/// timestamps and local-day calculations are deterministic.
abstract interface class Clock {
  /// The current instant in UTC.
  DateTime nowUtc();

  /// [utc] as wall-clock time in the device's time zone. Only its calendar
  /// and clock fields are meaningful (used for local days).
  DateTime toLocal(DateTime utc);
}

class SystemClock implements Clock {
  const SystemClock();

  @override
  DateTime nowUtc() => DateTime.now().toUtc();

  @override
  DateTime toLocal(DateTime utc) => utc.toLocal();
}

/// A manually controlled clock for tests. [utcOffset] stands in for the
/// device time zone (a fixed offset, no daylight saving).
class FixedClock implements Clock {
  FixedClock(DateTime now, {this.utcOffset = Duration.zero})
    : _now = now.toUtc();

  DateTime _now;
  Duration utcOffset;

  @override
  DateTime nowUtc() => _now;

  @override
  DateTime toLocal(DateTime utc) => utc.toUtc().add(utcOffset);

  void set(DateTime now) => _now = now.toUtc();

  void advance(Duration duration) => _now = _now.add(duration);
}
