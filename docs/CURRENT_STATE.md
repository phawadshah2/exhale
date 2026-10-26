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

- M2 Task 2.2, written, tests passing (Fawad ran them), not yet committed:
  `HabitDashboard` + `DashboardHeaderKind`, `DashboardHeader`, `PlanCard`,
  `TodayLogsCard`, `HabitDetailsPage` stub on `/habit/:habitId`,
  `AppFormat.shortWeekdayDate`. Section order per spec §4.3; quote card kept
  last. Home still uses `primaryHabitProvider` (not `singleHabitIdProvider`)
  until the multi-habit list exists (M4). "See all logs" is plain text until
  Task 2.5; money tile caption unchanged until 3.5; `stage_pill.dart`
  unchanged (its wording is covered by existing tests).

## Next action

Task 2.3, Ring card (plan section "Task 2.3" only), on `feat/dashboard-stats`.
Suggested: Sonnet 5.5, medium effort. Commit Task 2.2 first
(`feat(home): habit dashboard as Home`).

1. Read the Task 2.3 section and spec §4.4, then `day_card.dart` and the
   matching design (`Main.dc.html`, `StateOver.dc.html`, `StateFirstDay.dc.html`,
   `StatePastDay.dc.html`, `StateQuit.dc.html`).
2. Write failing widget tests first, then implement. Ask Fawad before each
   check (format, analyze, `fvm flutter test test/features/home`, then the
   full suite).
3. Then Tasks 2.4–2.5, then the M2 independent review (Opus 5.5, high) and a
   full-suite run before merging.

Test gotcha: never `await` a go_router `push` in a test (it completes on pop);
use `unawaited`.
