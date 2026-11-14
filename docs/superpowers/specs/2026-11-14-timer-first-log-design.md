# Timer starts at the first log

Asked by Fawad on 2026-11-14, before the real iPhone pass. Branch `feat/timer-first-log`,
off `main`.

## 1. No countdown before the first log

Today the countdown to the next log runs from wake when nothing is logged yet. It now
waits for the day's first log: `nextLogTimerProvider` returns null while today has no
logs. So before the first log:

- Home's ring shows the count (with the first-day note under it, as now).
- No draining ring or chip around the + button.
- The Logs rail shows no "next" mark.

From the first log on, nothing changes: the gap is replayed from the day's logs as now
(`PaceGuide` is untouched). A log before wake starts it too; the timer still waits for
wake as today. Yesterday's logs never count.

## 2. Tapping the timer opens today's logs

The timer in Home's ring opens Logs for today (`LogsQuery(habitId, from: today, to:
today)`, as the Today's logs card does), with a selection haptic. The chip above the +
button does the same; its draining ring stays non-interactive so the + keeps its taps.
Both are buttons to VoiceOver ("Opens today's logs"); the chip's target is at least
44 pt tall.

## Approaches

- Chosen: gate in the provider. One line, and every reader (ring, badge, rail, pace line)
  follows.
- Gate in `PaceGuide.compute`: would also drop the pace for callers that want it, and
  the domain test fixtures assume wake anchoring.
- A `started` flag on `NextLogTimer`: three call sites to update for no gain, since the
  pace line already gives way to the first-day note when there are no logs.
