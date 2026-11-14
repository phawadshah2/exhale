# Timer starts at the first log: plan

Spec: `docs/superpowers/specs/2026-11-14-timer-first-log-design.md`. Branch
`feat/timer-first-log`.

## Task 1: no countdown before the first log

- Test (`test/features/home/next_log_timer_test.dart`): with a window and no logs today,
  at a time the old timer would run, Home shows the count, no `DrainingRing`, no chip.
  Update "a log from yesterday does not count as the last one" to expect no timer until
  today's first log, then a 2:00:00 gap from it.
- Code: `nextLogTimerProvider` returns null when today's logs are empty.
- Check: the Logs rail test for the next mark still passes
  (`test/features/logs/`).

## Task 2: tapping the timer opens today's logs

- Test: tapping the ring's timer opens Logs on today; tapping the + chip does the same;
  both carry a button semantics label.
- Code: `_TimerCentre` (`ring_card.dart`) and the chip in `next_log_badge.dart` call
  `openLogs` with a selection haptic. The chip leaves the `IgnorePointer`; the ring keeps
  it.

After each task: `fvm dart format .`, `fvm flutter analyze --fatal-infos`, the task's
tests.
