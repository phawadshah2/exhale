# Current state

Updated 2026-10-26. Roadmap:
`docs/superpowers/plans/2026-10-21-home-details-logs-roadmap.md`; tasks in
`docs/superpowers/plans/2026-10-21-home-details-logs.md`.

## Goal

Home, Details and Logs redesign. Milestone **M1 (Habits foundation)** is
done and merged to main. Now starting **M2 (Dashboard and Logs)**.

## Done

- M1, Tasks 1.1–1.3: schema v8 (`habits` table; plans and logs keyed by
  `habit_id`), habit domain/data/providers, `StartTracking`, Home on
  `primaryHabitProvider`. Every v7 log maps to habit 1 in the migration.
- Checks passed on the merged code: format, `analyze --fatal-infos`, all
  tests.

## Next action

1. Task 2.1 on branch `feat/dashboard-stats` is done and checked (2026-10-26):
   `period_stats.dart`, `trigger_breakdown.dart`, `all_time_series.dart`, plus
   `periodStats`, `triggerBreakdown`, `allTime` in `ProgressCalculator`.
   Format, `analyze --fatal-infos` and the services tests (36) pass; the full
   suite has not been run. `average7` is null when `weekly` (weekly sums are
   already smoothed). Waiting on Fawad to commit; then start Task 2.2.
   Commit message: `feat(stats): period stats, trigger breakdown, all-time series`.
   Choices the plan left open, fixed by the tests: `average7` is aligned to
   `counts` (trailing mean, window up to 7 days); weekly blocks are 7 days
   counted from the start day; `daysOnTrack` counts tracked days not over
   their limit (at limit counts); `logged` ignores logs before the plan.
2. Then Tasks 2.2–2.5 (dashboard shell, ring card, History card, Logs page),
   with an independent review at the end of M2.
