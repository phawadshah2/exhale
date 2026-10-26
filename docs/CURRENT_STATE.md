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

## Next action

Task 2.3 is done. Start Task 2.5 now (see below); no work is in progress.

**Do Task 2.5 (Logs page) before Task 2.4 (History card).** 2.4's taps, and the
ring's trigger rows, all need `LogsQuery` / `openLogs` from 2.5. The plan's
"Task 2.6" references mean 2.5. Suggested: Sonnet 5.5, medium effort (new
feature, so a fresh session). Commit message per the plan:
`feat(logs): logs page with filters, allowed counts and swipe delete`.

Read first: plan "Task 2.5", spec §4.6, designs `Logs.dc.html` and
`LogsFiltered.dc.html` (canvas
https://claude.ai/artifact/Es7ju6TWmMj5pkNon4tbHu is the source of truth).
Reuse from `day_detail_sheet.dart` (to be deleted): the confirm-delete flow
(`showAppConfirm`, `deleteHabitLogProvider`, `failureMessage`). The router has
no `/logs` yet (`app_router.dart`, `app_routes.dart`). The ring's "View logs"
button (`ring_card.dart`) calls `showDayDetailSheet`: switch it to `openLogs`.

After 2.5: wire `DayTriggers.onSelect` in `ring_card.dart` to `openLogs`
(this also adds "· TAP TO SEE LOGS" to its header; add that test), then Task
2.4 with its taps wired, then the M2 independent review (Opus 5.5, high) and
the full suite. Once the one-habit Home is complete, ask Fawad before running
the simulator to review it against the canvas.

Not built, deliberately: the after-quit-date ring state and "You reached your
quit date" card (`StateQuit`), because Edit plan does not exist yet.

Ring/History decoupling: History still uses `pickedDayProvider` /
`selectedDayProvider` until 2.4 gives it its own anchor.

Test gotcha: never `await` a go_router `push` in a test (it completes on pop);
use `unawaited`.
