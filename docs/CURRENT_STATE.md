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

- M2 Task 2.3, committed and pushed (tree clean at handoff). Checks observed
  by me after the last edit: format, `analyze --fatal-infos` clean, full suite
  263 passed. `RingCard(habitId)` (was `DayCard`), `DayTriggers`,
  `ringDayProvider`/`ringShownDayProvider`; ring tests in
  `test/features/home/ring_card_test.dart`; matched to the canvas designs.

- M2 Task 2.5 (Logs page), committed (5900464, tree clean at handoff). Logs tests (9) passed as observed by me; format, analyze and the full suite were run by Fawad and passed (his report, not observed by me). Added
  `lib/features/logs/` (`LogsQuery` + `openLogs`, `logs_providers.dart`,
  `LogsPage`, `LogsPeriodCard`, `LogsDayCard`, `DayGroup`, `LogRow`), route
  `/logs`, tests in `test/features/logs/`. Ring "View logs" and the ring's
  trigger rows now call `openLogs` (header gains "· TAP TO SEE LOGS");
  `day_detail_sheet.dart` deleted; two `home_page_test.dart` day-sheet tests
  and two `ring_card_test.dart` header asserts migrated, one ring test added.
  Choices: single habit only (habit tabs and All come in 4.4; `habitId`
  null falls back to the primary habit); swipe delete confirms, deletes and
  snaps back (the stream removes the row); "No trigger" chip is not
  tappable (a `Trigger?` filter cannot express it); no month/trigger
  dropdown from the design.

## Next action

Task 2.5 is committed. Start Task 2.4 (History card): give it its own anchor
and wire its taps to `openLogs` (plan "Task 2.4", spec §4.5, designs
`ChartA/B/C/All*.dc.html`); then the M2 independent review (Opus 5.5, high) and a
simulator check of every Logs entry point (ask first). Suggested: Sonnet 5.5,
medium, fresh session.

Ring/History decoupling: History still uses `pickedDayProvider` /
`selectedDayProvider` until 2.4 gives it its own anchor.

Test gotcha: never `await` a go_router `push` in a test (it completes on pop);
use `unawaited`.
