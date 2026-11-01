# Current state

Updated 2026-11-01. Goal: release candidate, M5 of
`docs/superpowers/plans/2026-10-21-home-details-logs-roadmap.md`. The first release
tracks one habit (Fawad, 2026-10-31). `gh` is not installed: Fawad opens PRs from a
prefilled compare link.

**M5 is done on `feat/launch-states` (head fefc700) except the real iPhone pass.**
Tasks 5.1 to 5.3, the independent review (0541760..43131f4, verdict "With fixes") and
all its fixes are committed. The branch is on `origin`; check `git status` for what is not pushed. Local `main`
has one docs commit (0541760) that goes up with the launch PR. Uncommitted: this file,
`CLAUDE.md`, the plan and the roadmap (docs only).

Checks at fefc700: format clean, `analyze --fatal-infos` clean, full suite 677 passed.
Not run at handoff (docs only).

Simulator walk, seen: fresh onboarding on Air and SE; timer counting up and down; Settings;
dark with Ink on Home, Logs and Edit log; light with Eucalyptus and Ocean on Home; largest
text on Home, Logs and Edit log (after the fixes, only the top of Home); SE trigger sheet;
Reduce Transparency.
Not seen: the stage pill fix on SE (rebuilt, no screenshot taken), carry-over, Undo snackbar,
quit reached, Edit plan and Change habit, after-bed live, Reduce Motion in motion (stills
only). Two spare QA simulators may still be booted, one with Reduce Motion and
Reduce Transparency on.

**Next action:** Fawad's calls below, then the launch PR, with the iPhone pass listed as
pending.

Simulator walk (2026-11-01, iPhone Air and SE, from stills): seen working: timer reaching
zero and hiding, a log restarting it, carry-over, Undo, the long + chip, quit reached, Keep
at zero, New goal, Edit plan, Change habit to Home, after bed, the SE stage pill. Not seen:
Reduce Motion in motion, which stills can't show; the fade at zero (only the state after it).

Found and fixed: Replace crashed on iOS (`7b55f5a`). `context.go` removes Edit plan during a
build, and on iOS that fires `didPopNext`, which changed a provider mid-build. The 5.1b note
below that it "never fires here" was wrong: widget tests run as Android, where it doesn't
fire. The new test is iOS only and was seen failing with the app's error. Most widget tests
still run as Android, though the app is iOS only; that gap is open. Also fixed (`56ddde4`):
`1 sessions`, page text showing through the Edit plan footer, the chip over the snackbar, no
gap above the empty triggers box. Those four have no failing test seen first; `1 sessions`
has a test written with the fix. Full suite 680 passed, format and analyze clean.

Fawad's call (2026-11-01): scrolling pages keep running under the status bar, no backdrop.

For Fawad: `limit 0` overlaps the last day's `0` in
the Week chart. New goal after quitting offers a limit of 1 with "0 sessions avoided".

+ chip (Fawad, 2026-11-01): hours and minutes from 60 minutes (`1 h 27 min`, was `87 min`),
which settles `703 min`. VoiceOver reads the same. Spec 8.2 is updated. Not seen on a
simulator, so how a long chip like `11 h 43 min` looks is unchecked.

Timer past zero (Fawad, 2026-11-01): no more count-up. When the timer reaches zero, the
timer, its inner ring and the + ring and chip hide, and the ring shows the count with a
short fade. The next log starts the timer again. This also settles the late first open
with no logs (`+5:10:00`). The pace text under the ring stays. Spec 8.2 is updated. Checks
after the change: format clean, `analyze --fatal-infos` clean, full suite 679 passed; the
timer tests were seen failing first. Not seen on a simulator.

Deferred by Fawad (2026-11-01), not done: the real iPhone pass (plan 5.3 Step 4): glass
performance, chart scrolling with 90+ days, returning from the background. It must happen
before release.

Seed for that pass: `lib/main_seed.dart`, git-excluded in `.git/info/exclude`, so not in
any commit. Run it with `fvm flutter run --profile -t lib/main_seed.dart -d <id>`. On an
install with no habit it writes vaping, a plan from 120 days back to 30 days ahead, and
1,357 logs on past days. It writes nothing if any habit is stored. Delete it after the pass.

Read first: `CLAUDE.md`, roadmap "M5: Release candidate", and the rulings and deferred
minors in `.superpowers/sdd/2026-10-21-home-details-logs/progress.md` (kept for M4).

Product calls to reverse if disliked: text capped at 200%; the timer runs after bed; the
stage pill stacks name above target when both don't fit.

The "exhale" simulator needs a relaunch
to show the timer; its files were deleted outside the session, cause unknown.

Later: Live Activity with the widgets, roadmap "Post-launch backlog".

## Ink accent and no glows (2026-11-01, committed)

Fawad asked. Ink is the third accent in Settings (stored index 2; Eucalyptus and Ocean
keep 0 and 1). `emphasis` now always follows the accent, so Eucalyptus and Ocean are no
longer black in light mode. Glows are gone everywhere: `PrimaryButton` (was `GlowButton`,
renamed because it no longer glows), `ExhaleColors.glow` and `accentGlow`, the ring halo,
the splash's radial wash and logo shadow, the snackbar dot, the unused history chart. The
splash dust stays, unblurred. Neutral black drop shadows under glass stay: they are depth.

Fawad confirmed: new installs start on Ink (`AppPalette.defaultAccentIndex`), so light
onboarding stays black; a saved setting keeps its accent. My calls, easy to reverse: the
table's column default is still 0, unused because every save writes the index, so no
migration. Ink shows paper on dark surfaces, where ink would vanish, so dark onboarding is
now paper, not teal. Under Ink the ring has no green (`ExhaleColors.ringStart`). Status
colours (green, amber, red for on track, at limit, over) stay in every accent.

Not seen on a simulator: Ink in light and dark, the splash without its wash, the + button
in Ink (glass over the page, the mid-grey note below may apply).

## Task 5.1c, next-log timer (2026-10-31, committed)

Fawad chose it from mockups (https://claude.ai/artifact/NBe5B8VGM6iMXDaiuysb88,
"Chosen design"); onboarding spec 8.1 and 8.2 hold the rules. The ring's main number
is the timer, always with hours (`0:47:12`), inside a thin draining ring; past zero it
counts up in green (`+0:12:03`, "You're on schedule"). The + button gets a draining
ring and a chip in whole minutes (`87 min`), on every tab, and neither past zero. One
text under the ring. Both new rings use `AppMotion.fill`. A log with time left adds
that time to the next gap (Fawad), replayed from today's logs. It may run past bed
(`3:00:00` at 10 PM, Fawad removed my cap); the timer still ends at bed.
`pace_line.dart` is gone (`pace_text.dart`, `draining_ring.dart`, `next_log_badge.dart`,
`nextLogTimerProvider`, `secondTickProvider`).

Fixed on the way: `BackwardPager._current` was `late`, so a first step with no earlier
rebuild read the new page and never animated. The past-day test caught it, red seen.
Also closes three M5 minors below (marked).

My calls, easy to reverse (ledger has them): the order under the ring is over note,
first-day note, prompt, pace (I told Fawad prompt before first-day, then swapped: only
pre-v9 data has no window, and it kept the existing tests); the first log of a day
counts against the timer from wake, so a log soon after waking adds most of a gap;
waiting past zero earns no credit.

Checks observed by me: format clean, `analyze --fatal-infos` clean, full suite 494
passed. Red seen on assertions: the pager, and three carry-over tests with the carry
removed, and the past-bed test with the cap still in. Otherwise red on compile errors
only.

Simulator walk (2026-10-31, "exhale", from stills, light and dark): the timer ticks; the
rings, chip and pace text match the design; the chip is not clipped by the glass bar; a
log, a delete and a past day all work; one frame caught both rings filling in step. Not
walked: the count-up past zero, Undo from the snackbar (the log was removed from Edit
log), carry-over, Reduce Motion, and how the seconds feel. The walk ran with a cap at
bed: at 9:49 PM the timer already equalled the time to bed, so a log did not change the
number, and Fawad removed the cap. Second walk without the cap (bedtime set to 3:30 AM
for it, then restored): after bed Home shows the count and no + ring; a log took
`10:03:11` to `11:42:53`, and the rings refilled. Open from that walk: two-digit hours
fit but sit close to the inner ring, and bursts of logs make large numbers (`703 min`).
The simulator's data is back as it was.

For Fawad to look at: a new user finishing onboarding in the afternoon has no logs, so
the timer has already passed and Home opens counting up from their first due time
(`+5:10:00`, "You're on schedule"). The same applies to any day's first open with no
logs. For Task 5.2: at 3× text, `today_logs_card.dart`, `log_row.dart` and the ring
card's header row overflow; not caused by this.

## Task 5.1b (2026-10-31, committed)

Edit plan has a "Change habit" button (`/change-habit/:habitId`, `ChangeHabitPage`).
It runs Habit, Daily amount, Cost and The deal. "Shake on it" asks first, then
`ChangeHabit` archives the old habit and starts the new one in one transaction, and
the app goes Home. Wake, bed and currency are not asked for or written; the currency
chip is read-only. Old logs stay stored and hidden.

My calls, easy to reverse (ledger has them): `replacedHabitProvider` instead of an
`OnboardingMode` enum; `page_visits.dart` was not taken from 5369b50, because
`didPopNext` never fires here (Edit plan sits between Home and the flow); `ChangeHabit`
fails with `NotFoundFailure` when the old habit is no longer active; a stale link
redirects Home; Home's dashboard is keyed by habit id; the habit step's prompt, title
and lead are my copy.

Checks observed by me: format clean, `analyze --fatal-infos` clean, full suite 465
passed. Red seen: the two rollback tests with the rethrow missing, "two presses" and
"a press during the save" with each guard removed. Not seen failing beyond compile
errors: the other flow tests, including the stale link. The dashboard key has no test
of its own. Swipe back on the first step has no test. Not seen on a simulator: the
button, the Replace alert (tests use the Flutter fallback, not the native alert) and
the entrance on Home after replacing.

## Task 5.1 (2026-10-31, committed 2e131b0)

Over limit and first day already worked; their copy is now pinned exactly. New:
quit reached. `ProgressRing` draws a full success ring on a day at zero;
`_FreeDaysCentre` shows "3 / days vape-free / Nothing logged today" (today only);
`QuitReachedCard` sits under the ring with Keep at zero (sets `quitAcknowledgedAt`)
and New goal (Edit plan); `quitCardDueProvider`; `HomeStats.freeDays`; the QUIT pill
is green. The old "so far today" note is gone. `habit_dashboard.dart` needed no
change.

My calls, easy to reverse (ledger has them): the count is consecutive days at zero
including today, so a slip restarts it and the quit day reads "1 day"; a slip today
shows the over state and keeps the card; Keep at zero applies to one quit date, so
a new goal offers the card again; Keep at zero uses the `emphasis` button, not the
design's green.

Checks observed by me: format (1 file), `analyze --fatal-infos` clean, full suite
439 passed. Red seen for the quit tests that needed the state (8 of 11) and for
`freeDays`. Not seen failing: the over-limit and first-day tests (they pin existing
behaviour) and the three guards that the card stays hidden. A failed Keep at zero's
snackbar has no test. Not seen on a simulator.

Stage pill (Fawad asked, 2026-10-31, committed 10f0d2a): now matches spec 4.3 and the
designs: habit icon, "Vaping · Drops to 10 in 4d", "STAGE 2 / 9", and on a plan's
first day "Vaping · Day 1, plan starts today". `nextTarget` moved to `HabitWording`,
as on `feat/multi-habit`, though that branch's `stageLine` and pill will conflict
when it resumes. My calls: a long name truncates before the target; the chip's text
scale is capped at 1.5, because the chip overflowed at 3×. Checks observed by me:
format clean, `analyze --fatal-infos` clean, full suite 442 passed; red seen first.
Not seen on a simulator, and the test font is wider than the real one, so how real
names fit is unchecked.

`splash_page.dart` is restored; the stash stays for the next walk.

Read first: `CLAUDE.md`, plan Task 5.1b, roadmap "M5: Release candidate", and the
ledger's rulings (`.superpowers/sdd/2026-10-21-home-details-logs/progress.md`).

## Parked: multiple habits (`feat/multi-habit`, not merged)

Tasks 4.1 (5369b50), 4.2 (747347d) and 4.3 (8aab391) and the checkpoint docs
(ae8d6c1) are committed on the branch, and the branch matches its last known
`origin` ref. Task 4.4 and the M4 review are not done; see plan Phase 4 for
how to resume and what is open. The sections on 4.1 to 4.3 below are the record.
Ledger: `.superpowers/sdd/2026-10-21-home-details-logs/progress.md` (rulings for
4.1 to 4.3).

Checks on the branch (2026-10-31), before these commits, on the same files:
format (0 changed), `analyze --fatal-infos` clean, full suite 463 passed. They
were not run on the 4.2 commit alone, and CI on those commits was not read.
`main` has none of this work, and its suite was not run for this docs change.

## Task 4.3 (2026-10-31, committed 8aab391)

Details has a back bar: `CircleIconButton` back (moved out of `LogsPage`), the
`HabitSwitcher` pill, tune. With several habits the pill opens a "Switch habit"
sheet; picking one calls `context.replace`, so Back still goes Home, and the
dashboard is keyed by habit id. With one habit the pill only names it. Edit plan
gains "Stop tracking <habit>" with a confirm. `TrackedHabitGuard` wraps Details,
Edit plan and Logs: once the habit is no longer active it goes Home, or to
onboarding when none are left.

Checks observed by me: format clean, `analyze --fatal-infos` clean, full suite
463 passed, rerun after the splash hack was restored (Fawad's OK; the stash is
kept for the next walk). **Red was not observed:** the first run and a run with the guard disabled both
hung without reporting (failed tests skip `disposeApp`, see Test gotchas), so
these tests were never seen failing on an assertion. A failed archive's snackbar
has no test. Not seen on a simulator.

## Task 4.2 (2026-10-31, committed 747347d)

With two or more habits Home is `HabitListHome`: greeting, "Today's habits ·
N active", a `HabitSummaryCard` per habit (opens `/habit/:id`),
`CombinedImpactCard`, `RecentLogsCard` (latest 6, "See all logs" opens Logs
with `habit=all`), quote. New: `ProgressCalculator.combinedStreak`,
`habitDaysProvider`, `combinedImpactProvider`, `recentLogsProvider`,
`AppFormat.ago` and `dayAndTime`, `AppRoutes.habitFor`. `HabitWording` gains
`stageLine`, `nextTarget`, `avoidedTitle` (moved out of `StagePill` and
`RingCard`); `LogsCardHeader` is shared with `TodayLogsCard`; `LogRow` takes
optional `habit` and `when`. The + menu's "Add a missed log" now asks which
habit with a second glass menu. The pace line under Details needed no code
(`HabitDashboard` has it); a test now covers it.

Checks observed by me: format clean, `analyze --fatal-infos` clean, full suite
453 passed. Red was seen only for `combinedStreak`; the widget tests were
written with the code, so they were not seen failing first. Not seen on a
simulator, so the cards' look against `HomeMulti.dc.html` is unchecked. Until
4.4, "See all logs" shows the oldest habit's logs, because Logs has no All view
yet. `home_page_test.dart` lost the interim test "with two habits Home shows
the oldest until it lists them".

## Task 4.1 (2026-10-31, committed 5369b50, pushed)

`/add-habit` (`AddHabitPage`) runs Habit, Daily amount, Cost and The deal; the
+ menu's new "Add a habit" row opens it. `onboardingModeProvider` is overridden
in a nested `ProviderScope`, and `onboardingFormProvider` depends on it. Tracked
presets show "TRACKING" and are disabled; the form opens on the first untracked
preset. Currency, wake and bed come from settings and are not saved; the
currency chip is read-only. The first step's chevron leaves the flow. Also
fixed: `context.go` over a pushed page threw, because `didPopNext` bumped a
provider during a build (`ShellReturnListener` now waits for the frame's end).

Checks observed by me: red first, then format, `analyze --fatal-infos` clean,
full suite 434 passed. Not seen on a simulator; swipe back on the first step has no test; the
prompt "Another one? We can take it." is my copy, not from a spec. Those checks
ran on the working tree before the commit; none ran at handoff, and CI on the
push was not read.

Open for Fawad: the + button reads mid-grey in light mode. Hook gotcha: the global
hook blocks any Bash call whose text mentions "format"/"test" next to
other commands (including `git add` of `formatting/` paths, `git rm` of
`*_test.dart` and `task-done`); run checks bare, stage with `git add -A`
/ `-u`, write ledger lines by hand.

## Phase O4 (2026-10-31, committed)

Task 4.1 (4453e42): `PaceGuide.compute` in `lib/features/home/domain/`.
Task 4.2: `PaceLine` under the ring (`HabitDashboard`), `showYourDaySheet`
and `YourDayTile` in `your_day_sheet.dart`, `AppFormat.minuteOfDay`. The
pace figure rounds up so "every 0 min" never shows.
Checks observed by me: red first, format (1 file), `analyze --fatal-infos`
clean, full suite 416 passed. Neither the polish nor O4 has been seen on a
simulator.

Milestone O4 review (2026-10-31): independent, read the polish and O4
(5ec93e6..18fa52d). Fixed, each seen red first: one-line step titles sat
centred (`OnboardingStepHeader`); the Your day sheet had no inset; its save
error was hidden behind the sheet, now inline; `PaceGuide.next` was
recomputed from now every minute, so the countdown ran at twice the clock.
`next` is now the last log (or wake) plus an even share of what is left to
bed, fixed until the next log (spec 8.1 "recalculated after every log"; the
plan's 12:55 example becomes 13:05). `pace` still uses now. Checks observed
by me: format (1 file), `analyze --fatal-infos` clean, full suite 420
passed.

Pace floor (2026-10-31, Claude's call after Fawad said to continue, easy to
reverse): the guide never suggests going faster than the even rate. `pace`
and `next` use `max((bed − wake) / limit, (bed − from) / remaining)`, so limit
12 at 22:00 reads as The deal's 80 min, not 8. The second line hides when one
gap would run past bed. Spec 8.1 and 8.2 are updated.

Deferred to M5 (minors from the review): Reduce Motion misses `SmoothSwitcher`,
`PressScale`, `deal_step`, `exhale_bubble`, `day_window_picker`, `habit_step`; back
chevron 44 × 36 pt since the polish; older tap targets under 44 pt (Deal chips,
currency chip, units stepper). Closed by Task 5.1c: the pace line on a swiped day,
pace figures only in minutes, the prompt at the limit and on quit day.

Simulator walk (2026-10-31, "exhale", from stills): onboarding in dark
(vaping, 6 steps) and light (social media, 5 steps), Home, the prompt, the Your
day sheet, the pace line and the Settings row all match. Fixed from it: the
countdown read 89 next to a pace of 88 right after a log (a minute-old `now`);
the deal fine print named Settings, which has no plan option, and now says
Home (spec updated). Those two were not seen again on the simulator. Full
suite 425 passed, format and `analyze --fatal-infos` clean.

Not walked: a fresh first launch (the simulator already has a habit, so Shake
on it skips the save; covered by `deal_step_test`), small phones, Dynamic Type,
motion feel. The simulator's data gained a day window and one pouches log; its
theme is back on Dark. For Fawad to look at: the + button reads mid-grey in
light mode, not ink (glass over the page).

The onboarding PR merged as #26; see the top of this file for the next action.

**Stash:** `stash@{0}` "sim-walk splash hack" holds the debug edit to
`splash_page.dart` (always starts onboarding). `git stash apply` it only
for a simulator walk, then `git checkout -- <splash_page.dart>` before
running tests or committing (on 2026-10-30 it was found applied in the
tree and made 74 Home/app tests fail).

## Onboarding polish (2026-10-29, committed 338a92c with the O3 fixes)

Fawad asked after the O3 walk: buttons at one height, mockup stepper
with a visible track, ink (`emphasis`) instead of the accent for every
onboarding selection, two-line awake time (big numbers, small units),
taper chart that travels on entry and on date change (after the Pick
sheet closes), smooth habit reply, more motion throughout. All coded:
`OnboardingStepFrame` now takes `button` + `below` (44 pt slot); new
`widgets/onboarding_motion.dart` (`SelectionColors`, `StepReveal`,
`PressScale`, `RollingNumber`, `CountTo`); `ExhaleReply` morphs in
place; `TaperChart` is stateful with `delay`; `DealStep` is stateful
(`sheetClose` 250 ms); stepper, habit, amount, dots, cost, currency
chip, day picker, deal restyled. Dark mode keeps the accent (emphasis).
Tests: `awakeLabel` finder added to `test/helpers/onboarding.dart`;
day picker/day step asserts moved to it.

2026-10-30: tests updated for the new motion (`habit_step_test` matches
the check icon at full `AnimatedScale`; `amount_step_test` waits out
`ExhaleReply`'s 160 ms fade via `swapReply`). Checks observed: format
clean (0 changed), `analyze --fatal-infos` clean, full suite 394
passed. Not seen on a simulator.

Simulator walk: `git stash apply`, walk light + dark on the "exhale"
simulator, then restore the splash file. Plan:
`docs/superpowers/plans/2026-10-29-onboarding-redesign.md`. Ledger:
`.superpowers/sdd/2026-10-29-onboarding-redesign/progress.md`. Roadmap:
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

- `home/presentation/widgets/history_chart.dart` is unused since 2.4; not
  removed.
- Plan roadmap page is a later design decision.

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
Follow-up fix (Fawad asked): `AppFormat.money` now puts a space after a
symbol ending in a letter and groups thousands ("AED 1,825", "£2,646.25"),
app-wide. Checks observed by me: red first, format, analyze clean, full
suite 397 passed.
Checks observed by me: red first, 7 new tests passed, format (3 files),
`analyze --fatal-infos` clean, full suite 395 passed. Not seen on a
simulator.

Task 3.5 done (129d4f1, 2026-10-29): `DayWindowPicker`
(`lib/features/settings/presentation/widgets/day_window_picker.dart`: arc
with dots, Wake up / Bedtime tiles, inline `CupertinoDatePicker` at 15-min
steps; a window under 4 h is not reported and the wheel snaps back when
scrolling ends) and `DayStep` (wired into `OnboardingPage`; `_PendingStep`
now only stands in for The deal). `OnboardingCopy.hoursAwake` became
`awakeDuration(minutes)` + `awake`. Review Focus 2 is tested (1:00 AM bed =
17 h 30 min; wake 23:00 refused). Tests: 4 picker + 4 step. Checks observed
by me: format (3 files), `analyze --fatal-infos` clean, full suite 405
passed. Red was not observed first; the scroll-end snap-back has no test;
not seen on a simulator.

Task 3.6 done (88e62c5, 2026-10-29): `DealStep` (title, `TaperChart`,
Suggested / 4 weeks / 8 weeks / 3 months / Pick chips, steep warning,
Tomorrow / Quit in / Back a year stats, pace line, **Shake on it** with
the error under it, fine print; success goes to Home) and `TaperChart`
(`widgets/taper_chart.dart`, real daily limits). `_PendingStep` deleted.
Review Focus 3 and 4 are tested: 80 a day suggests 90 days; a failed
save keeps every answer and the retry saves one habit; two presses in
one frame save one habit (seen red with the `isSubmitting` guard
removed). Tests reach `/onboarding` with `GoRouter.go` until 3.7 wires
the splash. Checks observed by me: red first (compile errors), 7 passed,
format (1 file), `analyze --fatal-infos` clean, full suite 412 passed.
Not seen on a simulator.

Task 3.7 done (981f15a, 2026-10-29): first launch shows the logo,
"We need to talk." and one pulse of `TypingDots` (none with Reduce
Motion) for `SplashPage.firstLaunchDuration` (1.2 s), then `/onboarding`
slides in from the right (`CustomTransitionPage`); taps do not postpone
it. Returning users keep the intro + hold to Home. `SetupPage`,
`HabitPickerPage`, `setupFormProvider`, the `/setup` routes and
`pumpToPlanStep` are gone with their tests; `cost_card`,
`projection_card`, `quit_date_card`, `setup_chrome` moved to
`lib/features/plan/presentation/widgets/`; `maxReasonLength` is now
`HabitValidation.maxReasonLength`. Checks observed by me: red first, 19
passed (splash, app, deal), format, `analyze --fatal-infos` clean, full
suite 394 passed. Not seen on a simulator.

Milestone O3 review done (2026-10-29, uncommitted): copy matches spec
§4 and §7 word for word; flow walked on the "exhale" simulator in light
and dark against `flows.html`. Fixes: the light "You" bubbles were
near-invisible (`inset` at 60%), now `surfaceContainerHighest` in light
and `surfaceContainerHigh` in dark (mockup #E9EEF3 / #242A34); the taper
chart's "N today" label sat on the first flat step (plot top 22 → 30,
label 18 above it); the deal stats drop tabular figures ("A$2, 190"
read as a space); the welcome sender line is two constants instead of
`substring(3)`, and the welcome test now checks it and "Read 11:49 PM".
Checks observed by me: welcome tests 3 passed; format clean;
`analyze --fatal-infos` clean and full suite 394 passed with the splash
debug edit stashed. No widget test for the chart label or bubble colour
(paint/colour only). Held as fine: the habit, amount and cost replies
sit right-aligned (as in the mockup); prices over 1,000 hide the totals
until Continue shows the error. Open for Fawad: the mockup wordmark is
lowercase "exhale", the app shows "Exhale" (shared with the returning
splash). Uncommitted debug edit in `splash_page.dart` (always starts
onboarding) is kept for simulator walks; revert it before committing.
The simulator app's saved theme was set to dark for the walk and put
back to light.

`task-done` is blocked by the global hook (it wraps a test
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
