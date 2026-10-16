/// Source of the current time, injectable so tests can pin it.
class Clock {
  const Clock();

  DateTime now() => DateTime.now();
}
