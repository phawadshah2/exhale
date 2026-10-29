# Current state

Updated 2026-10-29 (checkpoint after Task 3.4, code HEAD 7a72513).
Onboarding plan, Phase O3 in progress: Tasks 3.1–3.4 done, next is Task 3.5
(Your day step and `DayWindowPicker`). To continue, read the plan section
"Task 3.5" in `docs/superpowers/plans/2026-10-29-onboarding-redesign.md`,
the ledger's Task 3.3–3.4 rulings
(`.superpowers/sdd/2026-10-29-onboarding-redesign/progress.md`),
`lib/features/onboarding/presentation/pages/onboarding_page.dart`
(`OnboardingStepFrame`, `OnboardingStepHeader`, `_PendingStep`) and
`steps/cost_step.dart` as the pattern for a step. Roadmap:
`docs/superpowers/plans/2026-10-21-home-details-logs-roadmap.md` (row 3b).

## Goal

Home, Details and Logs redesign. M1, M2, M3 and the Home design fixes are
merged to `main` (PR #23, 50bef85). M3 review merged (PR #24, 4457aea).
Onboarding redesign spec approved (2026-10-29, commits 64d8fc8 and
6055570 on `feat/onboarding-redesign`, local only). Its implementation plan is written (see "Onboarding plan"); M4 waits
for it to be built.

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

## Onboarding redesign (decided 2026-10-28, refined 2026-10-29)

Fawad wants onboarding redone from scratch before M4, because onboarding
may change Home; the roadmap gets revised once the spec is settled.
Spec approved 2026-10-29:
`docs/superpowers/specs/2026-10-29-onboarding-redesign-design.md`.

Decided with Fawad (2026-10-29):
- Flow A, "the excuse chat": Exhale talks in short chat bubbles at the
  top of each step. Mockups: `design/7._onboarding/flows.html` (Flow A
  black = light mode; Flow A app accent dark = dark mode; Flow B and the
  accent-light row are rejected alternatives).
- Screens: splash (flows into Welcome on first launch) → 1 Welcome (your
  excuses as sent texts, Exhale replies) → 2 Habit → 3 Daily amount →
  4 Cost (price, pack size, currency chip; skipped for no-cost habits;
  "I'd rather not know" skips the price) → 5 Your day (wake/bed, inline
  wheel) → 6 The deal (taper chart, Suggested preselected, presets,
  "Shake on it").
- Stepper: six thin segments, back chevron, quiet "2/6" (Welcome is 1/6;
  "/5" when Cost is skipped). No Skip button; a tap on Welcome only skips
  its animation.
- English only (no language picker at launch). Daily amount is one number
  per day. Name, start date picker (start is today) and "Your why" leave
  onboarding.
- Sleep times feed only the pace guide; the 4 AM day reset stays separate
  in Settings. The Home pace guide is in the same spec as a later phase.
- Colour: a new `emphasis` / `onEmphasis` role in `ExhaleColors`: ink
  (#111418, white text) in light, the accent (primaryContainer, dark teal
  text) in dark. Used for primary filled buttons app-wide, Exhale's
  bubbles, avatar, stepper and dots; the accent keeps selection and state
  (selected cards and chips, ring, charts). Splash logo glyph and avatar
  icon follow the accent. Easy to revert: only the role's colours change.
- Tone: sardonic but motivating; jokes hit the habit and the excuses,
  never the person; no medical claims ("A behaviour tool, not medical
  advice." on Welcome).

Data, reuse and the pace guide (spec §5, §8) were approved in chat.
Suggested quit date: `startLimit × 7` days clamped to 14–90 (spec §9).

## Onboarding plan (written 2026-10-29)

`docs/superpowers/plans/2026-10-29-onboarding-redesign.md`: phases O1–O4,
13 tasks (1.1; 2.1–2.3; 3.1–3.7; 4.1–4.2), milestone review after each
phase. Roadmap gained the "3b. Onboarding redesign" row; plan Task 4.1
(Add a habit) now reuses the onboarding steps (no "Why", per spec §5.3).
Deviation from spec §5.3: `cost_card`, `projection_card`, `quit_date_card`
and `setup_chrome` move to `lib/features/plan/presentation/widgets/`
(Edit plan uses them) instead of being deleted.

Choices in the plan Fawad may want to revisit: the GlowButton accent halo
shows only in dark mode; the "Set your day" prompt shows until the day is
set (no dismiss flag); first launch skips the long splash intro and shows
"We need to talk." for 1.2 s.

## Next action

Task 1.1 done (04b699b): `ExhaleColors.emphasis` / `onEmphasis`
(`AppPalette.ink` in light, the accent in dark) on filled buttons, the
+ button, the wheel picker's Done; the GlowButton halo shows in dark only.
Checks observed by me: full suite 314 passed, then format (2 files
reflowed) and `analyze --fatal-infos` clean. Not seen on a simulator.

Milestone O1 review done (2026-10-29, code read, no fixes): every
`primaryContainer` use under `lib/` is state, selection, a chart/ring
accent, a tint or decoration. Filled buttons get `emphasis` from
`filledButtonTheme`; no FAB or `ElevatedButton` falls back to the accent.
Closest call: Home's `_TodayChip` is tappable but a 16% accent ghost chip
(a secondary jump back to today), held as fine. `SetupStepChip`'s accent dot
is decorative.

Task 2.1 done (281324e): schema v9 adds nullable `settings.wake_minute`
/ `bed_minute`; `AppSettings.wakeMinute`, `bedMinute`, `dayWindow`;
`DayWindow` (default 7:30–23:30, at least 4 h awake); validation rejects
times outside the day and windows under 4 h. New fixture
`test/fixtures/exhale_v8.sqlite`. Plan fix: the v8 settings rebuild must
list the two columns in `newColumns` (drift copies other columns by name),
so v1–v7 upgrades reach v9. Checks observed by me: red first, Task 2.1
files 48 passed, format (2 test files), `analyze --fatal-infos` clean,
full suite 331 passed.

Task 2.2 done (a49c35c): `CurrencyChoices` (28 entries, `$` first and
the fallback, case-insensitive region match) and `deviceRegionProvider`
in `settings_providers.dart`. Checks observed by me: red first, 8 new
tests passed, format clean, `analyze --fatal-infos` clean, full suite 339
passed.

Task 2.3 done (4f768d9): `ReductionPlan.suggestedQuitDay` is
`startLimit × 7` days clamped to `minSuggestedDays` (14) and
`maxSuggestedDays` (90). Checks observed by me: red first (limit 1 gave
7 days), format (1 file), `analyze --fatal-infos` clean, full suite 340
passed. No onboarding or Edit plan test needed new dates.

Milestone O2 review done (2026-10-29): code read, no `lib/` changes.
Migration logic holds (v8 adds the two columns; older versions get them
from the v8 settings rebuild). Test gaps fixed: `_expectLatest` now
compares every table's columns (type, not null, default, key) and the
indexes with a fresh install; new `upgrade from v3` / `v4` groups (they
had no test). Seen catching a mutation (bed_minute add removed on the v8
path). Checks observed by me: format (1 file), `analyze --fatal-infos`
clean, full suite 348 passed. 2.2 and 2.3 held as fine.

Task 3.1 done (df1f03b): `OnboardingFormState` / `OnboardingFormController`
/ `onboardingFormProvider` (`onboarding_form_provider.dart`; its own
`QuitPreset`, Suggested first; `OnboardingStep`), `OnboardingCopy`. A
price is ignored for a habit that does not track cost (no stale error or
yearly cost after a switch). The old setup pages still use
`setupFormProvider`. Checks observed by me: red first (compile errors),
25 new tests passed, format, `analyze --fatal-infos` clean, full suite 373
passed.

Task 3.2 done (bdd0950): `/onboarding` route (not reached from the
splash until 3.7), `OnboardingPage` + `OnboardingScope` (next/back),
`OnboardingStepFrame` (scrollable body with min height, pinned footer;
bodies use `Column` `spaceBetween`, not `IntrinsicHeight`, which
overflowed), `OnboardingStepper`, `ExhaleBubble`, `YouBubble`,
`TypingDots`, `WelcomeStep` (3.4 s timeline, tap skips, Reduce Motion
starts at the end, kept alive so back does not replay). Steps 2–6 are
`_PendingStep` placeholders. Helper `test/helpers/onboarding.dart`.
Checks observed by me: red first, 7 new tests passed, format,
`analyze --fatal-infos` clean, full suite 380 passed. Not seen on a
simulator.

Task 3.3 done (180dff8): `HabitStep` (2-column preset grid, dashed
Something else with name and unit fields in place, reply per pick),
`AmountStep` (round − / +, 64 px number, `AmountRuler`, `DotsGrid`,
reaction by range), `OnboardingStepHeader`, `ExhaleReply`. The ruler's
scale follows the finger: drag left raises (the plan said right; ledgered).
Checks observed by me: red first (compile errors), 8 new tests passed,
format (5 files), `analyze --fatal-infos` clean, full suite 388 passed.
Not seen on a simulator.

Task 3.4 done (7a72513): `CostStep` (price card with `CurrencyChip`,
units-per-container stepper, month/year tiles and reply once a price is
valid, "I'd rather not know" clears and moves on, invalid price errors on
Continue), `showOptionWheel` in `app_dialogs.dart` (shares the date
wheel's header), `RoundIconButton` (moved out of the amount step). Review
Focus 1 is tested (Cost leaves the steps after a switch to Social media).
Tile amounts read like "AED1825": `AppFormat.money` has no space or
thousands separator (mockup "AED 1,825"); left alone, it is shared.
Checks observed by me: red first, 7 new tests passed, format (3 files),
`analyze --fatal-infos` clean, full suite 395 passed. Not seen on a
simulator.

Next: Task 3.5 (Your day step and `DayWindowPicker`) with
`superpowers:executing-plans` (Sonnet 5.5 medium). Its tests cover Review
Focus 2 (bedtime after midnight). `task-done` is blocked by the global hook (it wraps a test
command); run the tests bare and write the ledger line by hand. Ledger:
`.superpowers/sdd/2026-10-29-onboarding-redesign/progress.md` (git-excluded
via `.git/info/exclude`).

**Git:** Claude may branch, commit and merge locally; push only when asked;
no Co-Authored-By trailers. GitHub `main` is protected (PR plus the
"Analyze & test" check), so pushing `main` directly fails. Local `main` is
`origin/main` plus the handoff docs commit 372e0ba; the branch adds the
spec, plan, Task 1.1, Task 2.1 and checkpoint commits (not pushed).
All go up with the onboarding PR.

Task 1.1 rulings (in the ledger): `showAppConfirm` is a native alert, so
the wheel picker's Done got the emphasis tint instead; tinted
`GlassIconButton` icons use `onEmphasis`; an extra
`test/core/widgets/glow_button_test.dart` covers the dark-only halo.

Checks policy (2026-10-29): format, analyze and test run without asking
(global hook and settings allow them). Codegen, builds and simulator runs
still need Fawad's approval. Run each check as a bare command: the hook
still asks on redirects or `$(...)` and rejects a check chained with a gated
command. Full-suite output is large; use `--reporter failures-only`.

Task 2.2 starts from: plan section "Task 2.2: `CurrencyChoices`" in
`docs/superpowers/plans/2026-10-29-onboarding-redesign.md` and the
ledger's Task 2.1 rulings.

Test gotchas: never `await` a go_router `push` in a test (use `unawaited`);
a failed assert skips `disposeApp()`, so run a failing test with
`--timeout 60s`; delayed reveals (the over note) need a `pump` past the
delay before `pumpAndSettle`. The hold hint shows only after the 2 s Undo
snackbar closes.
