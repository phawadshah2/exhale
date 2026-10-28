# Current state

Updated 2026-10-28. Roadmap:
`docs/superpowers/plans/2026-10-21-home-details-logs-roadmap.md`; tasks in
`docs/superpowers/plans/2026-10-21-home-details-logs.md`.

## Goal

Home, Details and Logs redesign. M1, M2, M3 and the Home design fixes are
merged to `main` (PR #23, 50bef85). M3 review done: `fix/m3-review`
pushed, PR not opened yet (no `gh` on this Mac; Fawad opens it from
GitHub). Next: redesign onboarding (and maybe splash) from scratch, then
revise the plan; M4 waits for that.

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

## M3 and Home design fixes (merged)

- M3 (log flow), Tasks 3.1–3.5: PRs #20–#22. Checks per Fawad's reports,
  not observed by me for 3.3–3.5.
- Home design fixes (PR #23, 8 commits from 66db4aa to d79d506): shared
  motion (`core/theme/app_motion.dart`, `core/widgets/fill_in.dart`,
  `core/widgets/smooth_switcher.dart`); ring, triggers and History fills all
  reach today at `AppMotion.fill`; History toggles fade out then in, with
  every period prefetched; Home entrance (`ScrollReveal`,
  `DashboardSkeleton`) replays only when a page closes or the tab returns
  (`app/shell/page_visits.dart` ignores popup routes); the dashboard is a
  `SingleChildScrollView` + `Column` (a lazy list made it jump at the
  bottom); plan card is a vertical stepper with an outlined Edit pill; the
  trigger sheet has the Edit log note field; Today's logs expand in place.
- Plan stepper, note field and logs expand were approved from inline
  mockups; `design/6._home_details_logs/` and the canvas are not updated.

## M3 review (2026-10-28)

Independent review done. Fixed on `fix/m3-review`, committed and merged
into `main` locally (not pushed):
- The hold hint opened a full-screen barrier at the same moment as the
  "Logged at … Undo" snackbar, in the same spot, so the first log could not
  be undone. `showAppSnackBar` now returns its controller, `logNow` returns
  the Undo snackbar (null when nothing was logged), and `_logAndHint` shows
  the hint only after it closes; it is skipped (and `logHintSeen` stays
  false) when the log was undone or a sheet is on top by then.
- Missing plan tests added: `instant_on_logical_day_test.dart` (01:30 maps
  to the next calendar date), `add missed log on a past day lands on that
  day` (Logs). Shell hint tests now pump past the snackbar; one added for
  Undo on the first log.

Checks observed by me after the fixes: format (1 test file changed),
`analyze --fatal-infos` clean, the three changed test files 28 passed,
full suite 307 passed. The new Undo test was not seen failing before the
fix (written after it). Nothing seen on a simulator.

Held as fine: trigger chip count, future-time validation in the use cases,
note/reason normalisation, Edit plan replan and keep-current logic.
Not fixed (later): "edit changes time" has no widget test (wheel picker;
covered by the unit test); "price updates money saved" checks the stored
price only.

## Open

- Logs spins forever if the log stream or plan history fails (M5 states).
- `home/presentation/widgets/history_chart.dart` is unused since 2.4; not
  removed.
- Plan roadmap page is a later design decision.
- M4 (4.2): the multi-habit menu's "Add a missed log" always uses the first
  habit; it needs a habit choice.
- M5 (5.2): the + button's `Semantics(excludeSemantics: true)` drops the
  tap and long-press semantic actions (VoiceOver falls back to a touch; the
  menu has no action).

## Onboarding redesign (decided 2026-10-28)

Fawad wants onboarding redone from scratch (splash maybe too) before M4,
because onboarding may change Home; the roadmap gets revised once the
onboarding design is settled. Direction discussed, not yet a spec:
- Tone: sardonic and funny, but motivating; jokes hit the habit and the
  excuses, never the person; no medical claims.
- 5–6 uncrowded screens with purposeful animation (Reduce Motion
  fallback). Proposal: Welcome → habit → daily amount (reactive copy) →
  cost (price + pack size + currency chip from locale; skipped when the
  habit has no cost) → your day (bedtime/wake dial) → the deal (taper
  line, suggested quit date preselected, presets, money saved).
- One visual thread: the daily-amount dots reappear on every screen.
- Bedtime/wake (times, not hours) feed a pace guide on Home
  ("next one on schedule in N min" = awake minutes ÷ today's limit, never
  a lock) and could set the day reset hour; the Home timer is its own task.
- Suggested cuts: no language picker at launch (no l10n; humour needs a
  native writer); "Your why" moves to a Home prompt; optional "Less
  sarcasm" setting.

## Next action

Onboarding redesign spec (Opus 5.5 high): use
`superpowers:brainstorming` to settle screens, copy and the pace guide
with Fawad, write the spec under `docs/superpowers/specs/`, then mockups,
then revise `docs/superpowers/plans/2026-10-21-home-details-logs-roadmap.md`
(M4 Task 4.1 Add a habit should reuse the new onboarding steps). Branch
`feat/onboarding-redesign` off `main` once the M3 PR is merged.

**Git:** Claude may branch, commit and merge locally; push only when asked;
no Co-Authored-By trailers. GitHub `main` is protected (PR plus the
"Analyze & test" check), so pushing `main` directly fails. Local `main`
holds a local merge of `fix/m3-review` (aaf7d36, not on GitHub); after the
PR merges, reset it: `git fetch origin`, then `git reset --hard
origin/main` (ask Fawad first). Not run: nothing since the full suite
(307 passed) before the commits. Untracked `todo.md` is Fawad's.

Test gotchas: never `await` a go_router `push` in a test (use `unawaited`);
a failed assert skips `disposeApp()`, so run a failing test with
`--timeout 60s`; delayed reveals (the over note) need a `pump` past the
delay before `pumpAndSettle`. The hold hint shows only after the 2 s Undo
snackbar closes.
