# Current state

Updated 2026-10-26. Roadmap:
`docs/superpowers/plans/2026-10-21-home-details-logs-roadmap.md`; tasks in
`docs/superpowers/plans/2026-10-21-home-details-logs.md`.

## Goal

Home, Details and Logs redesign. **M1 (Habits foundation)** is merged to main.
In **M2 (Dashboard and Logs)** on branch `feat/dashboard-stats`.

## Done

- M1, Tasks 1.1–1.3: schema v8, habit domain/data/providers, plans and logs
  keyed by `habit_id`.
- M2 Task 2.1, committed and pushed (tree clean at handoff): `PeriodStats`,
  `TriggerBreakdown`, `AllTimeSeries` and `ProgressCalculator.periodStats`,
  `triggerBreakdown`, `allTime`. Format, `analyze --fatal-infos` and the
  services tests (36) passed. The full suite was not run after it.
- Choices fixed by the tests: `average7` is aligned to `counts` (trailing mean,
  up to 7 days) and is null when `weekly`; weekly blocks are 7 days from the
  start day; `daysOnTrack` counts days not over their limit; `logged` ignores
  logs before the plan.

- M2 Task 2.2, committed (tree clean at handoff). Checks: `fvm flutter test
  test/features/home` 29 passed; analyze and format were clean before the
  last test edit (not rerun after); full suite run by Fawad, passed (his
  report, not observed by me). Built:
  `HabitDashboard` + `DashboardHeaderKind`, `DashboardHeader`, `PlanCard`,
  `TodayLogsCard`, `HabitDetailsPage` stub on `/habit/:habitId`,
  `AppFormat.shortWeekdayDate`. Section order per spec §4.3; quote card kept
  last. Home still uses `primaryHabitProvider` (not `singleHabitIdProvider`)
  until the multi-habit list exists (M4). "See all logs" is plain text until
  Task 2.5; money tile caption unchanged until 3.5; `stage_pill.dart`
  unchanged (its wording is covered by existing tests).

## Next action

Task 2.3, Ring card, on `feat/dashboard-stats`: done, uncommitted. Format
(Fawad), analyze `--fatal-infos` clean, `test/features/home` (33) and the full
suite (262) passed, observed. Next: Fawad commits as
`feat(home): ring card with last entry and day triggers`, then Task 2.4.

Task 2.3 changes: `day_card.dart` → `ring_card.dart` (`RingCard(habitId)`);
new `day_triggers.dart` (`DayTriggers`, `onSelect` unset); `ringDayProvider`
and `ringShownDayProvider` in `home_providers.dart`; ring tests moved to
`test/features/home/ring_card_test.dart`. Today's details are now Last entry /
Last trigger (the old "Time since last" / "Next target" cells are gone, per
spec §4.4). History still uses `pickedDayProvider`/`selectedDayProvider` until
Task 2.4 gives it its own anchor, so the ring and chart no longer move
together (the old "ring and chart move together" test was removed).

Left for later: trigger rows do not open Logs until Task 2.6 (wire `onSelect`
with `LogsQuery` and add that test then); the over-limit note, before-plan and
after-quit-date states from spec §4.4 are not built; the first-day triggers
placeholder has a solid border, not dashed.

Then Tasks 2.4–2.5, then the M2 independent review (Opus 5.5, high) and a
full-suite run before merging.

Test gotcha: never `await` a go_router `push` in a test (it completes on pop);
use `unawaited`.
