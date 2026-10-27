# Current state

Updated 2026-10-27. Roadmap:
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

- M2 Task 2.4 (History card), committed (74aba14, tree clean at handoff). Observed by me:
  analyze clean, `test/features/home` 43 passed; format run once more after
  that (one file changed); full suite 281 passed after it (observed by me).
  Not checked on a simulator against the designs. `HistoryCard(habitId)` is rewritten
  with Week line, Month rings and All (`widgets/history/`: `week_line_chart`,
  `month_ring_calendar`, `all_time_chart`, `history_stats_line`,
  `top_triggers`, `chart_paint`); providers `historyPeriodProvider`,
  `historyAnchorProvider`, `historyShownDayProvider`, `historyStatsProvider`,
  `allTimeSeriesProvider`; `chartPeriodProvider`, `pickedDayProvider` and
  `selectedDayProvider` removed. Header is now plain "History";
  `HabitWording.historyTitle` is unused. Tests: `history_card_test.dart`
  (new); the old chart test and two "Vaping History" asserts in
  `home_page_test.dart` migrated. Choices: day taps open Logs for that day;
  chips and "All triggers" open Logs for the shown period (All = plan start
  to today); the chart pager covers the chart only, totals and chips follow
  the shown period; "Since ... day N of D" uses quit day minus first day.
  `AllTimeChart` also takes `quitDay`.

## M2 review (2026-10-26)

Independent review done (code read). Review Focus 1, 2, 5 hold and are
covered by the 2.1 tests. Fixes committed and pushed (26f58d0, tree clean):
"See all logs" opens today's Logs; `DayGroup` keyed by day; the Logs pill
matches History ("N under" / "N over", hidden when nothing is tracked); the
Logs previous-week arrow stops at `earliestDayProvider`; `logsInRangeProvider`,
`backfillDays`, `earliestDayProvider` moved to `tracking_providers.dart`;
`HabitWording.historyTitle` removed. Tests: 1 extended in
`home_page_test.dart`, 4 added in `logs_page_test.dart`.

Checks observed by me: format and `analyze --fatal-infos` clean; full suite
282 passed, 3 Home failures from one wrong assert (fixed); after the fix
`test/features/home` 43 passed. The full suite was not rerun after the fix.

Open: Logs spins forever if the log stream or plan history fails (M5
states). The plan's Review Focus 5 wording was corrected (uncommitted doc edit).

## Next action

Handoff 2026-10-27. Branch `feat/plan-logs-design-fix`, tree clean (Fawad
committed; push status not checked). **M3 Task 3.1 is merged** (PR #18).

Done this session (Fawad's ring card edits, reviewed and finished):
- `ring_card.dart`: edge-to-edge pager, spacing only when the day has logs,
  "View logs" / "Add missed log" buttons and the info-cell detail text removed
  on purpose; dead `detail` and unused import removed; null-safe `logs.value`.
- `today_logs_card.dart`: shows the newest 3 logs (`logsForDayProvider` is
  oldest first; the old test was masked by the ring's "Last entry" time).
- Tests updated to open Logs via `openLogs`. Observed by me: format and
  `analyze --fatal-infos` clean, full suite 287 passed (analyze/format ran
  before the one-line `.reversed` edit).

**Plan card and Logs design fixes are edited (2026-10-27), uncommitted.**
Observed by me: format (0 changed), `analyze --fatal-infos` clean, full suite
287 passed. Not seen on a simulator.
Plan card: "Stage N / M" pill, start date / % / quit date labels, stages in an
inner panel with check / arrow / flag markers, "Since <date>". Logs: 44px
circle back/add buttons, trigger-tinted icon tile and chip (`TriggerUi.tint`),
84px red "Delete" swipe panel, "Yesterday" label, red "N over", footer hint,
"No trigger" pill. Tests updated in `home_page_test.dart` and
`logs_page_test.dart` (the swipe test taps `find.text('Delete').last`).

**M3 Task 3.2 (trigger sheet habit chip), uncommitted.** `showTriggerSheet`
takes `habitId`; the sheet is a `ConsumerStatefulWidget` showing a chip
"<Habit> · N of L after this" (name only when there is no plan). Test
`trigger sheet names the habit and the count after this log` in
`home_page_test.dart`. Observed by me: format, `analyze --fatal-infos` clean,
full suite 288 passed. Not seen on a simulator.

**Next:** Task 3.3 (one-time hold hint). Test gotchas: never `await` a
go_router `push` in a test (use `unawaited`); a failed assert skips
`disposeApp()` and the test hangs to the 10 min timeout, so run a single
failing test with `--timeout 60s`.
