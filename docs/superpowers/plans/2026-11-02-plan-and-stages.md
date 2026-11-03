# Plan details, Edit plan, Logs and stage management Implementation Plan

> **For agentic workers:** REQUIRED SKILL: Use execute-plan (the project's stated
> method, see `CLAUDE.md`) to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax
> for tracking.

**Goal:** Build the three signed-off screens with day-accurate money, then the stage management
that reacts to repeated overs.

**Architecture:** Pure domain code decides everything: `PriceHistory`, `PlanReport`, `LogsSelection`,
`DayRail`, `StageChecks` and `PlanChoices` take plain values and are unit tested. Widgets format what
they return. Storage follows the existing data source, repository, use case and `sl` pattern, with
hand-written Riverpod providers.

**Tech Stack:** Flutter 3.47.2 and Dart 3.13 through `fvm`, Riverpod 3 (no generator), get_it, drift,
go_router.

**Specs (read the relevant section before each task; copy and rules live there and are not repeated
here):**
- `docs/superpowers/specs/2026-11-02-plan-edit-logs-design.md` ("Screens spec"), Phases 1 to 4
- `docs/superpowers/specs/2026-11-02-stage-management-design.md` ("Stages spec"), Phase 5

## Global Constraints

- Branch `feat/plan-and-stages`. Commit under Fawad's identity with Conventional Commit messages. No
  Co-Authored-By trailers or any Claude attribution. Push only when he asks.
- Never stage `design/all-designs.html` or `design/figma-import/`. Stage `lib`, `test` and `docs`
  paths only. The global hook may refuse a `git add` naming `test` beside another command; run it as
  its own call.
- Only `fvm flutter` and `fvm dart`. Run each check as a bare command: `fvm dart format .`,
  `fvm flutter analyze --fatal-infos`, `fvm flutter test --reporter failures-only`. All three must be
  clean before every commit. A failing test needs `--timeout 60s`, because a failed assert skips
  `disposeApp()`.
- Ask Fawad before each `fvm dart run build_runner build -d` (Tasks 1 and 14) and before any build or
  simulator run.
- Dependencies: none added.
- iOS look on every surface: `AppIcons`, `showAppSheet` / `showAppDraggableSheet`, `showAppConfirm`,
  `showWheelPicker`, `showAppSnackBar`, `PrimaryButton`, `GlassSurface` with its Reduce Transparency
  fallback, no ink ripples, selection haptics. Text to the 200% cap, 44 pt targets, Reduce Motion, light
  and dark, all three accents.
- Style: no tutorials or teaching comments. Match the surrounding code. Repositories return `Result`
  and use `guardStorage`.
- Drift imports: `hide isNull, isNotNull` (matcher) and `hide Trigger` (drift).
- Tests that return Home or pop run as iOS, as `7b55f5a` did. Use `pumpAppPastSplash(height: 2400)`
  for Home, `tester.pumpInSteps()` for animations, and `tester.runAsync` to read drift streams.
- Copy is exact: take it word for word from the spec section named in each task.
- Update `docs/CURRENT_STATE.md` when a task finishes, saying what was and wasn't seen.

## Decisions this plan makes

- **Schema:** `habit_prices` is v10 and the stage tables are v11. Each phase ends on a shippable,
  migratable database, and a device already on v10 still gets the stage tables.
- **Writing a price:** a new `SetHabitPrice` is the only path that changes price or units, so
  `UpdateHabit` keeps writing the unchanged values and needs no day. `StartTracking` writes the first
  point, using `plan.startDay`.
- **Build order inside Phase 1 to 4:** prices first, because Plan details and Edit plan both read them.
- **Riverpod:** `PlanReport` is read through one provider that combines three streams; pages stay
  `ConsumerWidget`s. Logs keeps its page-level `setState`, as today.

## Review Focus

- Entering a first price and clearing it on the same day must leave no point, so "Add a price" returns
  and a later price still counts from Day 1 (test in Task 2).
- Logs left open past the reset hour: the selected day stays, the later arrow becomes available, and
  today's marks move to the new today (tests in Tasks 9 and 11).
- Saving Edit plan while a review card waits: the new plan has no waiting check, so the card must go
  and not return (test in Task 18).
- The check firing twice at once, at start and on a day change: one row, one hold (test in Task 16).
- Extreme plans: 80 stages, a 365-day current stage and 41 preview rings at 200% text on an SE width,
  with no overflow (tests in Tasks 4, 5 and 8).

---

# Phase 1: Price history (Screens spec 2)

### Task 1: `habit_prices` table, v10

**Files:**
- Create: `lib/core/data/local/database/tables/habit_prices_table.dart`, `test/fixtures/exhale_v9.sqlite`
- Modify: `lib/core/data/local/database/app_database.dart`, `app_database.g.dart` (codegen)
- Test: `test/core/data/app_database_migration_test.dart`

**Interfaces:**
- Produces: drift `HabitPrices` with data class `HabitPriceRow` (`id`, `habitId`, `fromDay` as
  yyyy-mm-dd text, nullable `priceCents`, `unitsPerContainer`), unique on `{habitId, fromDay}`.

- [ ] **Step 1: Make the v9 fixture.** With the schema still on v9, copy `test/fixtures/exhale_v8.sqlite`
  aside, open the copy once through `AppDatabase(NativeDatabase(file))` in a throwaway test so it
  upgrades, close it, save it as `test/fixtures/exhale_v9.sqlite` and delete the throwaway test. It holds
  habit 1, price 1500, plan from 2026-10-20.
- [ ] **Step 2: Write the failing tests.** Change `_expectLatest` to compare `PRAGMA user_version` with
  `database.schemaVersion` and rename the "ends on v9" tests "ends on the latest version". Add group
  `upgrade from v9`:

```dart
test('a priced habit gets one point on its first plan day', () async {
  final rows = await _rows(database, 'SELECT * FROM habit_prices');
  expect(rows.single['habit_id'], 1);
  expect(rows.single['from_day'], '2026-10-20');
  expect(rows.single['price_cents'], 1500);
});
test('a habit with no price gets no point', () async { /* null the price in setup, reopen, expect empty */ });
```

- [ ] **Step 3: Run, expect failure.** `fvm flutter test test/core/data/app_database_migration_test.dart`
  fails: no table `habit_prices`.
- [ ] **Step 4: Implement.** Add the table to `@DriftDatabase`, set `schemaVersion` to 10, and in
  `onUpgrade` add, after the v8 steps:

```dart
if (from < 10) {
  await migrator.createTable(habitPrices);
  await customStatement('''
    INSERT INTO habit_prices (habit_id, from_day, price_cents, units_per_container)
    SELECT h.id,
      COALESCE((SELECT MIN(p.start_day) FROM plans p WHERE p.habit_id = h.id),
               date(h.created_at, 'unixepoch', 'localtime')),
      h.price_cents, h.units_per_container
    FROM habits h WHERE h.price_cents IS NOT NULL
  ''');
}
```

  Ask Fawad, then run `fvm dart run build_runner build -d`.
- [ ] **Step 5: Run, expect pass**, including every older upgrade group.
- [ ] **Step 6: Commit** `feat(data): add habit price history at schema v10`.

### Task 2: `PriceHistory`, `SetHabitPrice` and saved money

**Files:**
- Create: `lib/features/habit/domain/entities/price_history.dart`,
  `lib/features/habit/domain/usecases/set_habit_price.dart`
- Modify: `habit_repository.dart`, `local_habit_repository.dart`, `habit_local_data_source.dart`,
  `start_tracking.dart`, `habit_injection.dart`, `habit_providers.dart`, `progress_calculator.dart`,
  `home_providers.dart`, `test/helpers/pump_app.dart`
- Test: `test/features/habit/domain/price_history_test.dart`,
  `test/features/habit/domain/usecases/set_habit_price_test.dart`, `progress_calculator_test.dart`,
  `home_page_test.dart`

**Interfaces:**
- Produces:
  - `class PricePoint { LogicalDay fromDay; int? priceCents; int unitsPerContainer; }`
  - `PriceHistory.forHabit(Habit habit, List<PricePoint> points)`;
    `double? unitPriceCentsOn(LogicalDay day)`; `double? get currentUnitPriceCents`
  - `HabitRepository.watchPrices(int habitId) → Stream<List<PricePoint>>`, oldest first
  - `HabitRepository.setPrice(int habitId, {required LogicalDay day, required int? priceCents, required int unitsPerContainer}) → Future<Result<void>>`
  - `typedef SetHabitPriceInput = ({int habitId, LogicalDay day, int? priceCents, int unitsPerContainer});`
    and `SetHabitPrice`, validating with `HabitValidation.validate`
  - `priceHistoryProvider`: `StreamProviderFamily<PriceHistory?, int>`, null until the habit is loaded
  - `setHabitPriceProvider`
  - `ProgressCalculator.homeStats(..., required PriceHistory? prices)` replaces `unitPriceCents`

- [ ] **Step 1: Write the failing domain tests** in `price_history_test.dart`. Use the spec's example:
  points $0.40 until Nov 1 and $0.45 from Nov 2.
  - `unitPriceCentsOn(Nov 1) == 40`, `unitPriceCentsOn(Nov 2) == 45`
  - the first point counts backwards: `unitPriceCentsOn(day before the first point) == 40`
  - a point with `priceCents: null` from Nov 3 gives null on Nov 3 and later; a later priced point
    resumes; a day inside the gap stays null
  - a pack price divides by that point's `unitsPerContainer`, so a units change reprices from that day only
  - `Habit` with `tracksCost == false` returns null for every day and for `currentUnitPriceCents`
- [ ] **Step 2: Write the failing `homeStats` tests.** Baseline 12; Nov 1 logged 9; Nov 2 logged 8; today
  Nov 3: `moneySavedCents == 300`. Cleared current price: `moneySavedCents` null, and adding a price
  again returns the earlier savings. `avoided` is unchanged in both.
- [ ] **Step 3: Write the failing repository tests** on a real in-memory database:
  - `setPrice` updates `habits.price_cents` and writes a point; a failure leaves neither (use a habit id
    that doesn't exist and expect `NotFoundFailure`, no point)
  - a second change on the same day replaces that day's point, one row
  - no price and no points: no point written
  - **first price then clear on the same day: the point is deleted**, and a price on a later day counts
    from Day 1 (Review Focus)
  - clearing on a later day writes a null point
  - `StartTracking` with a price writes one point on `plan.startDay`; with no price, none; a failed plan
    save rolls the point back
- [ ] **Step 4: Run, expect failure** (compile errors, then assertions). Note which were seen red on an
  assertion.
- [ ] **Step 5: Implement.** `setPrice` runs in one `_database.transaction`: update the habit row
  (`NotFoundFailure` on 0 rows), then apply the point rules from Step 3 with `insertOnConflictUpdate`.
  Pass `SetHabitPrice` into `StartTracking` and call it after the plan saves, when
  `input.habit.priceCents != null`, inside the existing transaction. Change `seedHabit` to go through
  `sl<StartTracking>()`, so seeded prices have a point.

  `moneySavedCents` is:

```dart
final current = prices?.currentUnitPriceCents;
final saved = current == null ? null : math.max(0.0, completed.fold<double>(0,
    (sum, d) => sum + (baseline - d.count) * (prices!.unitPriceCentsOn(d.day) ?? 0)));
```

  In `EditPlanController.save`, write the price through `SetHabitPrice` with `state.today` (passing
  `habit.habit.tracksCost ? state.priceCents : null`) and the reason through `UpdateHabit` with the habit's
  stored price, so no path changes a price without a point. It still always starts a plan until Task 6.
- [ ] **Step 6: Run the new tests and the full suite, expect pass**, including `home_page_test`'s "price
  updates money saved".
- [ ] **Step 7: Commit** `feat(habit): count saved money at the price of each day`.

# Phase 2: Plan details (Screens spec 3)

### Task 3: `PlanReport`

**Files:**
- Create: `lib/features/plan/domain/services/plan_report.dart`
- Test: `test/features/plan/domain/plan_report_test.dart`

**Interfaces:**
- Consumes: `PriceHistory`, `PlanHistory`, `buildDailyProgress`, `ProgressCalculator.homeStats`,
  `ProgressCalculator.triggerBreakdown`.
- Produces:

```dart
enum StageNote { best, easyOne, noneOver, oneOver, someOver, last, oneFewer, halfway, written }

class PlanTotals { int used, usedOf, avoided, avoidedOf, kept, keptOf, withoutPlanUnits;
  double? savedCents, savedOfCents, withoutPlanCents; }

class StageReport { PlanStage stage; LogicalDay lastDay; int days, used, allowed, daysOver;
  double average; double? savedCents, toSaveCents; Trigger? mostly; StageNote? note;
  List<DailyProgress> daily; bool get isOverAllowed; }

class StageGroup { LogicalDay? earlierUntil; List<StageReport> stages; } // null: "This plan"

class PlanReport { PlanTotals totals; List<StageGroup> behind; StageReport? current;
  List<StageReport> ahead; double? behindSavedCents, aheadToSaveCents; int stageCount;
  bool get showsThisPlanLabel; bool get quitReached; LogicalDay quitDay;
  static PlanReport build({required List<HabitLog> logs, required DayBoundary boundary,
    required PlanHistory history, required PriceHistory? prices, required LogicalDay today}); }
```

- [ ] **Step 1: Write the failing tests**, using K's data: 12 a day from 2026-10-08, quit 2026-12-31,
  price 40 cents a session, today 2026-11-01, logs per day from `LogsCombined`'s `used` array.
  - `usedOf == 546`, `avoidedOf == 462`, `savedOfCents == 18480`, `withoutPlanUnits == 1008`,
    `withoutPlanCents == 40320`, `keptOf == 24`
  - `totals.avoided` and `totals.savedCents` equal `ProgressCalculator.homeStats` on the same data
  - `behindSavedCents` plus `current.savedCents` equals `totals.savedCents`
  - a stage with used over baseline: its unclamped value still sums (widgets clamp)
  - replan on Oct 20: `behind` has an earlier group with `earlierUntil == Oct 19`; the cut-off stage's
    `days` and `allowed` use its real days; unstarted stages are gone; the new plan's numbers restart;
    totals span both
  - a replan above the baseline: no tile or "of" is negative
  - first day: `kept == 0`, `keptOf == 0`, `behind` empty
  - on and after the quit date: `current` null, `ahead` empty, `quitReached` true
  - `mostly` null when no log has a trigger
  - every note rule and its order (Screens spec 3.5), including a next stage that drops by 2 getting no
    `oneFewer`
- [ ] **Step 2: Run, expect failure.**
- [ ] **Step 3: Implement** `PlanReport.build`. `end` is the later of `current.quitDay − 1` and today.
  Take the logs once into `buildDailyProgress` from `firstDay` to today. Stage money uses
  `prices.unitPriceCentsOn(d)` over finished days. `toSaveCents` uses the current price and is at least
  0. All money is null when `prices?.currentUnitPriceCents` is null. Pass `prices` to `homeStats` so
  avoided and saved can't drift from Home.
- [ ] **Step 4: Run, expect pass.**
- [ ] **Step 5: Commit** `feat(plan): add the plan report`.

### Task 4: Plan details page

**Files:**
- Create: `lib/features/plan/presentation/pages/plan_details_page.dart`,
  `lib/features/plan/presentation/providers/plan_report_provider.dart`,
  `lib/features/plan/presentation/widgets/plan_totals_card.dart`,
  `lib/features/plan/presentation/widgets/stage_row.dart`,
  `lib/features/plan/presentation/plan_copy.dart`
- Modify: `app_routes.dart`, `app_router.dart`, `home/presentation/widgets/plan_card.dart`
- Test: `test/features/plan/plan_details_page_test.dart`, `home_page_test.dart`

**Interfaces:**
- Consumes: `PlanReport`, `priceHistoryProvider`.
- Produces:
  - `AppRoutes.planDetails = '/habit/:habitId/stages'`, `AppRoutes.planDetailsFor(int)`
  - `planReportProvider`: `ProviderFamily<AsyncValue<PlanReport?>, int>`, combining `logsInRangeProvider`,
    `planHistoryProvider` and `priceHistoryProvider`
  - `PlanDetailsPage({required int habitId})`
  - `StageRow({required StageReport report, required StageRowKind kind, required Habit habit, required DayWindow? window})`
    with `enum StageRowKind { behind, ahead }`
  - `PlanCopy.note(StageNote, ...)`, holding every string of Screens spec 3.3 to 3.7

- [ ] **Step 1: Write the failing widget tests.**
  - tapping Home's plan card opens "You are here. Regrettably."; its Edit pill still opens Edit plan
  - the page's Edit pill opens Edit plan
  - tiles show `546`, `462`, the money tile, and the "Without a plan" line; a no-cost habit has 3 tiles and
    the short line; a cost habit with no price shows "—" and "Add a price ›"
  - section headers and side text; empty sections hidden; earlier-plan labels after a replan, and "This
    plan"
  - a stage opens and closes independently, showing the four stats; Mostly hidden with no trigger
  - a future stage's Pace and To avoid; **with `dayWindow` null, Pace is hidden**
  - the finish row, and from the quit date "You made it. Regrettably." with no YOU or AHEAD
  - a failed plan read shows `LoadFailure`, and retry works
  - **80 stages at 200% text on an SE width: no overflow** (Review Focus)
- [ ] **Step 2: Run, expect failure.**
- [ ] **Step 3: Implement** against frame K, using `SingleChildScrollView` + `Column`, as the dashboard
  does. Rings are a shared `StageRing` with `FillIn` at `AppMotion.fill`; opening uses `AnimatedSize`;
  Reduce Motion removes both. The current stage shows a stub card with the header only until Task 5. Make
  Home's plan card tappable with a `GestureDetector`, a selection haptic and `Semantics(label: 'Plan details')`,
  leaving `_EditPill` on top.
- [ ] **Step 4: Run, expect pass.**
- [ ] **Step 5: Commit** `feat(plan): add the plan details page`.

### Task 5: The current stage

**Files:**
- Create: `lib/features/plan/presentation/widgets/current_stage_card.dart`,
  `lib/features/plan/presentation/dot_layout.dart`
- Modify: `plan_details_page.dart`
- Test: `test/features/plan/dot_layout_test.dart`, `plan_details_page_test.dart`

**Interfaces:**
- Consumes: `StageReport.daily`.
- Produces: `DotLayout.of({required int days, required double width}) → ({int cols, int rows, double size, double gap})`;
  `CurrentStageCard({required StageReport report, required LogicalDay today, required int stageCount, required Habit habit})`.

- [ ] **Step 1: Write the failing layout test** at `width: 322`, using the Screens spec 3.6 formula:

| days | cols | rows | size |
|---|---|---|---|
| 15 | 13 | 2 | 16 |
| 52 | 13 | 4 | 16 |
| 53 | 14 | 4 | 16 |
| 132 | 33 | 4 | 7 |
| 133 | 33 | 5 | 7 |
| 365 | 33 | 12 | 7 |

- [ ] **Step 2: Write the failing widget tests.** 14 days shows rings with counts and limits for days ahead;
  15 days shows dots with "Each dot is a day" and both dates; the footer "{used} of {allowed} used · {n}
  days over" includes today once over; "Drops to 5 in 3 days…", "…tomorrow…", and 0 on the last stage;
  the VoiceOver label; no chevron. **A 365-day stage at 200% text: no overflow** (Review Focus).
- [ ] **Step 3: Run, expect failure.**
- [ ] **Step 4: Implement** against frames Y and Z, keeping rings and dots unscaled with
  `MediaQuery.withNoTextScaling`.
- [ ] **Step 5: Run, expect pass.**
- [ ] **Step 6: Commit** `feat(plan): show the current stage day by day`.

# Phase 3: Edit plan (Screens spec 4)

### Task 6: Saving without a new plan

**Files:**
- Modify: `lib/features/plan/presentation/providers/edit_plan_provider.dart`
- Test: `test/features/plan/edit_plan_controller_test.dart` (create)

**Interfaces:**
- Consumes: `setHabitPriceProvider`, `savePlanProvider`.
- Produces on `EditPlanState`: `int currentLimit`, `int? storedPriceCents`, `int storedUnits`,
  `int rulerSpanDays`, `bool get planChanged`, `bool get priceChanged`, `bool get canSave`.
  On the controller: `setQuitDayFromRuler(LogicalDay)` (keeps `rulerSpanDays`); `setQuitDay` and
  `selectQuitPreset` recompute it as `max(119, quitDay − today + 28)`. `reason` and `setReason` are
  removed. `EditPlanPage` keeps compiling by leaving the old Your why card reading `habit.reason` until
  Task 8.

- [ ] **Step 1: Write the failing tests** on real dependencies:
  - **only the price changed: plan history is unchanged and today's stage number stays; one point written**
  - a limit or date change starts one plan
  - both: the point and the plan
  - nothing changed: `canSave` false and `save()` writes nothing
  - a plan past its quit date: `planChanged` true from the start
  - invalid price: error set, nothing saved
  - plan save fails after a price save: price stays, error set, retry saves one plan
  - two calls in one frame save once
  - `rulerSpanDays`: 119 by default; a chip or wheel date 200 days out gives 228;
    `setQuitDayFromRuler` never changes it
- [ ] **Step 2: Run, expect failure.**
- [ ] **Step 3: Implement.** `save()` calls `SetHabitPrice` when `priceChanged`, passing
  `habit.tracksCost ? priceCents : null`, then `SavePlan` when `planChanged`.
- [ ] **Step 4: Run, expect pass**, including `edit_plan_page_test`, until Task 8 replaces it.
- [ ] **Step 5: Commit** `fix(plan): keep the plan when only the price changes`.

### Task 7: Dial and ruler

**Files:**
- Create: `lib/features/plan/presentation/widgets/limit_dial.dart`,
  `lib/features/plan/presentation/widgets/quit_ruler.dart`
- Test: `test/features/plan/limit_dial_test.dart`, `test/features/plan/quit_ruler_test.dart`

**Interfaces:**
- Produces:
  - `LimitDial({required int value, required int planStartLimit, required ValueChanged<int> onChanged, required String unitsLabel, required String? gapLabel})`;
    `static int scaleFor({required int planStartLimit, required int value})`, the smallest multiple of 20
    at least the larger of the two
  - `QuitRuler({required LogicalDay today, required LogicalDay selected, required int spanDays, required ValueChanged<LogicalDay> onChanged})`

- [ ] **Step 1: Write the failing tests.**
  - `scaleFor(12, 9) == 20`, `scaleFor(12, 21) == 40`, `scaleFor(45, 9) == 60`, `scaleFor(1, 80) == 80`
  - − and + step by one and stop at 1 and 80
  - dragging past the top stops at `R` and doesn't wrap to 1; dragging past the start stops at 1
  - a selection haptic on each change
  - the semantics are adjustable, with value "9 sessions a day"
  - ruler: dragging gives the nearest day, never before tomorrow and never past `today + spanDays`; a tick
    every week up to 40 weeks, every 4 weeks beyond; month names under their first days
- [ ] **Step 2: Run, expect failure.**
- [ ] **Step 3: Implement** against frame N, with `CustomPaint` for both. Dial angle is value ÷ `R`; the
  drag maps position to angle and clamps instead of wrapping by tracking the previous value.
- [ ] **Step 4: Run, expect pass.**
- [ ] **Step 5: Commit** `feat(plan): add the limit dial and quit ruler`.

### Task 8: Edit plan page

**Files:**
- Create: `lib/features/plan/presentation/widgets/plan_preview_card.dart`,
  `lib/features/plan/presentation/widgets/price_card.dart`,
  `lib/features/plan/presentation/widgets/your_why_sheet.dart`
- Modify: `edit_plan_page.dart`
- Delete: `cost_card.dart`, `projection_card.dart`, `quit_date_card.dart`
- Test: rewrite `test/features/plan/edit_plan_page_test.dart`

**Interfaces:**
- Consumes: `EditPlanState`, `LimitDial`, `QuitRuler`, `ExhaleReply`, `updateHabitProvider`.
- Produces: `dropSentence(ReductionPlan) → String`; `previewLimits(ReductionPlan) → List<int?>` (null is
  the "…"); `showYourWhySheet(BuildContext, {required int habitId})`.

- [ ] **Step 1: Write the failing tests.**
  - `dropSentence`: 63 days at 9 is "one fewer every 7 days"; 21 days at 4 is "one fewer about every 5 days";
    14 days at 10 is "dropping about every day"; steep (5 days at 10) is "dropping fast"
  - `previewLimits`: 9 stages gives 9..1, 0; 40 stages gives the first 5, null, then the last 4 including 0
  - footer: three states and the caption (Screens spec 4.6); a price-only save reads "Save price" and goes back
  - price card: hidden for a no-cost habit; "Was" appears on change; tiles; reply up and down; no reply with
    no stored price; "Counts from Day 1." with no stored price; "I'd rather not know" empties and hides itself
  - Keep current hidden past the quit date; tapping the date opens the wheel; the steep warning shows
  - Your why saves alone, and a failure keeps the sheet with a snackbar
  - **41 preview rings at 200% on an SE width: no overflow** (Review Focus)
- [ ] **Step 2: Run, expect failure.**
- [ ] **Step 3: Implement** against frame N in `SetupScaffold`, with `SetupFooter` pinned. The price field's
  prefix is the settings currency symbol as plain text; it can't be changed here. "One every {gap}" uses `AppFormat.hoursMinutes(awakeMinutes ÷ value)`
  and is hidden when `dayWindow` is null. Delete the three old cards.
- [ ] **Step 4: Run, expect pass.**
- [ ] **Step 5: Commit** `feat(plan): rebuild edit plan as a dial and ruler`.

# Phase 4: Logs (Screens spec 5)

### Task 9: `LogsSelection`

**Files:**
- Create: `lib/features/logs/domain/logs_selection.dart`
- Test: `test/features/logs/logs_selection_test.dart`

**Interfaces:**
- Consumes: `LogsQuery`, `PeriodRange`.
- Produces:

```dart
enum LogsMode { week, month }
class LogsSelection { LogsMode mode; PeriodRange period; LogicalDay selected; Trigger? trigger;
  factory LogsSelection.fromQuery(LogsQuery q, {required LogicalDay today});
  LogsSelection step(int by, {required LogicalDay today});
  LogsSelection withMode(LogsMode mode);
  LogsSelection pickMonth(LogicalDay anyDayInMonth, {required LogicalDay today});
  LogsSelection select(LogicalDay day);
  LogsSelection toggleTrigger(Trigger trigger);
  bool canGoEarlier(LogicalDay earliest); bool canGoLater(LogicalDay today); }
```

- [ ] **Step 1: Write the failing tests** for each `LogsQuery` shape in Screens spec 5.1:
  - no range → Week of today, today selected
  - one day → its Week, that day
  - a whole week → Week, last day or today
  - a calendar month → Month
  - History's All range → Month of its end
  - a trigger is kept
  - `step` selects the period's last available day; `withMode` keeps `selected` and shows the period holding it
  - `canGoEarlier` stops at the period holding `earliest`, `canGoLater` at the period holding today
  - **a selection made yesterday, with `today` moved forward: `selected` stays and `canGoLater` becomes true when
    the new today is in a later period** (Review Focus)
- [ ] **Step 2: Run, expect failure.**
- [ ] **Step 3: Implement** using `PeriodRange.weekOf` and `monthOf`.
- [ ] **Step 4: Run, expect pass.**
- [ ] **Step 5: Commit** `feat(logs): add the logs selection`.

### Task 10: `DayRail`

**Files:**
- Create: `lib/features/logs/domain/day_rail.dart`
- Modify: `lib/features/home/domain/pace_guide.dart` (make `_onDay` public as `PaceGuide.onDay`)
- Test: `test/features/logs/day_rail_test.dart`

**Interfaces:**
- Consumes: `HabitLog`, `DayWindow`, `DayBoundary`, `PaceGuide.onDay`.
- Produces:

```dart
sealed class RailEntry {}
class RailWake / RailBed { DateTime at; }
class RailLog { HabitLog log; bool over; }
class RailLimitReached { int limit; }
class RailGap { Duration gap; bool longest; }
class RailNext { DateTime at; }
class RailNothingYet / RailThenNothing / RailNothingLogged {}
abstract final class DayRail { static List<RailEntry> build({required List<HabitLog> logs,
  required int? limit, required DayWindow? window, required LogicalDay day,
  required bool isToday, required DateTime? next, Trigger? filter}); }
```

  `logs` are oldest first. `limit` null means before the plan.

- [ ] **Step 1: Write the failing tests.** Each pins an entry order, using `isA<>`:
  - wake 7:30, bed 23:30; 3 logs in the day: wake, log, gap, log, gap (longest), log, then-nothing, bed
  - a 6:50 log sits before wake; a 00:40 log after midnight sits after bed
  - limit 2 with 3 logs: limit-reached just before the third, whose `over` is true
  - limit 0 with one log: limit-reached first
  - one gap: not `longest`; a tie: the earliest
  - today with `next`: ... last log, next, nothing-yet, bed; `next` null hides next and keeps nothing-yet
  - past day with no logs: wake, nothing-logged, bed
  - before the plan: logs and gaps only
  - **`window` null: no wake or bed** and everything else the same
  - filter: matching logs only, no marks or gaps; no match gives an empty list
- [ ] **Step 2: Run, expect failure.**
- [ ] **Step 3: Implement.** Merge marks and logs by instant, using `onDay(day, wakeMinute)` and
  `onDay(day, wakeMinute + awakeMinutes)` for bed. Then-nothing and nothing-yet follow the last log; bed
  stays placed by time, last when nothing is after it.
- [ ] **Step 4: Run, expect pass.**
- [ ] **Step 5: Commit** `feat(logs): add the day rail`.

### Task 11: Logs page

**Files:**
- Create: `lib/features/logs/presentation/widgets/logs_calendar_card.dart`,
  `logs_trigger_card.dart`, `logs_rail_card.dart` (same folder)
- Modify: `logs_page.dart`
- Delete: `logs_period_card.dart`, `logs_day_card.dart`, `day_group.dart`
- Test: rewrite `test/features/logs/logs_page_test.dart`; `logs_query_test.dart` stays

**Interfaces:**
- Consumes: `LogsSelection`, `DayRail`, `logsViewProvider`, `earliestDayProvider`, `nextLogTimerProvider`,
  `Trigger.tint` and `textTint`. `LogRow` stays for `TodayLogsCard`.
- Produces: `LogsCalendarCard`, `LogsTriggerCard`, `LogsRailCard`, each taking the selection, its `LogsView`
  and callbacks.

- [ ] **Step 1: Write the failing widget tests.**
  - title, subtitle and arrows for Week and Month; month chips switch to Month and close
  - every cell state in the Screens spec 5.2 table, including limit 0 with no logs and a selectable before-plan
    day; a future day isn't tappable; VoiceOver "Nov 1, 5 of 9"
  - the period card's text with "(N so far)", the pill both ways, and "Before your plan"
  - bar and chips; tapping a chip filters and tapping again clears; a query-opened filter with 0 in the period
    still shows a clearable chip; None isn't tappable
  - the day card's five count cases
  - rail: tapping a log opens the editor; swipe confirms, deletes, and Undo restores; + opens on the selected day;
    the hint hides on a filtered day; "No Stress logs this day."
  - `nextLogTimerProvider` past or null hides "Next on schedule"
  - **the page open across the reset hour: the selected day stays, and today's marks appear on the new today when
    it's selected** (Review Focus)
  - no overflow at 200% on an SE width
- [ ] **Step 2: Run, expect failure.**
- [ ] **Step 3: Implement** against frame T. Keep `_delete` as it is. The rail's swipe is `Dismissible` with
  `confirmDismiss`, as `DayGroup` does now, plus a Delete `CustomSemanticsAction`. `RailNext.at` is
  `timer.guide.next`, null when the timer is null or `isPast`. Delete the three old widgets.
- [ ] **Step 4: Run, expect pass.**
- [ ] **Step 5: Commit** `feat(logs): rebuild logs as a calendar and rail`.

### Task 12: Milestone M6 review

- [x] **Step 1: Ask Fawad** for the review on Opus 5.5 high, in a fresh session, reading the Screens spec and the
  diff from `51e0bc6`. Focus: the price rules, `PlanReport` against Home, the price-only save, and Logs' query mapping.
- [x] **Step 2: Fix findings**, each seen red first where a test can show it.
- [x] **Step 3: Ask Fawad** for a simulator walk: all three screens, light and dark, a replan's Behind you, a price
  change, and `lib/main_seed.dart` for a long plan. Record in `docs/CURRENT_STATE.md` what was seen and what wasn't.
- [x] **Step 4: Commit** `docs: record the M6 review`, and give Fawad the push command.

# Phase 4b: UI fixes from Fawad's review (2026-11-03)

Fixes on the M6 screens, before M7. Tasks are labelled F1 to F4 so Tasks 13 to 20 keep their numbers.
Each starts by opening its design frame next to the current widget and listing the differences it will
close. Frames: `design/6._home_details_logs/` (`Main`, `ChartB`, `ChartC`, `StateLight`) and
`design/8._plan_edit_logs/` (`LogsCombined` is frame T, `HomeToday`, `StageToday` for the current-stage
highlight). Sonnet 5.5 medium. Same per-task check flow as Phase 1 to 4.

Decided (Fawad, 2026-11-03): in Logs, picking a date jumps to its week with that day selected and its logs
listed, and swiping moves week by week. In Home Month, the greyed-out days of the neighbouring months are
display only.

### Task F1: Ring card

**Files:**
- Modify: `lib/features/home/presentation/widgets/ring_card.dart`, `day_triggers.dart`
- Test: the existing ring card and day triggers tests, extended

- [ ] **Step 1: Compare with `Main.dc.html`** and list the differences.
- [ ] **Step 2: Write the failing tests:** the trigger bars are smaller with less spacing than today's
  constants (assert the new sizes); the icon in the last-entry tile and in the tiles like it is centred
  (compare the icon's centre with the tile's centre).
- [ ] **Step 3: Implement.** Quieter trigger bars so the ring leads; centre the icons.
- [ ] **Step 4: Run, expect pass.**
- [ ] **Step 5: Commit** `fix(home): quieten the trigger bars and centre tile icons`.

### Task F2: History card

**Files:**
- Modify: `lib/features/home/presentation/widgets/history/week_line_chart.dart`,
  `history/month_ring_calendar.dart`, `history_card.dart`
- Test: the existing history tests, extended

- [ ] **Step 1: Compare with `ChartB.dc.html` (Week) and `ChartC.dc.html` (Month)** and list the differences.
- [ ] **Step 2: Write the failing tests:**
  - Week: line and day dots use the thinner widths
  - Month: ring stroke is thinner; a dotted future ring and a past ring are drawn differently (assert the
    two paint styles differ in more than stroke width, so they read apart at a glance)
  - Month swipe: the grid keeps one fixed height for 4, 5 and 6-row months, with no overflow, and the
    leading and trailing cells show the neighbouring months' days greyed out and not tappable
    (a tap on one does nothing)
- [ ] **Step 3: Implement.** Always lay out 6 rows, or the tallest month's height, so the swipe never resizes.
- [ ] **Step 4: Run, expect pass.**
- [ ] **Step 5: Commit** `fix(home): thinner history strokes and a fixed-height month`.

### Task F3: Plan card opens Plan details

**Files:**
- Modify: `lib/features/home/presentation/widgets/plan_card.dart` (and `plan/presentation/widgets/edit_pill.dart`
  only if the pill stays)
- Test: the existing plan card test

The card body already opens Plan details (`openDetails`); only its `EditPill` opens Edit plan. **Decided
(Fawad, 2026-11-03): remove the pill from the card.** Edit plan stays reachable from Plan details, the
dashboard header and the stats grid. Keep `EditPill` if Plan details or others use it.

- [ ] **Step 1: Write the failing test** (the card has no Edit pill; every tap on it lands on Plan details,
  none on Edit plan).
- [ ] **Step 2: Implement. Step 3: Run, expect pass.**
- [ ] **Step 4: Commit** `fix(home): open plan details from the plan card`.

### Task F4: Logs page

**Files:**
- Modify: `lib/features/logs/domain/logs_selection.dart`, `presentation/pages/logs_page.dart`,
  `widgets/logs_calendar_card.dart`, `widgets/logs_rail_card.dart`
- Test: `logs_selection_test.dart`, `logs_page_test.dart`

- [ ] **Step 1: Compare with `LogsCombined.dc.html` (frame T)**, and the selected-day style with the current
  stage on Plan details; list the differences.
- [ ] **Step 2: Write the failing tests.**
  - the selected day uses the same highlight as the current stage on Plan details (share the style, don't
    copy it)
  - the arrow next to the period opens a calendar; picking a date jumps to that date's week with the day
    selected and its logs listed; dates before `earliestDayProvider` or in the future can't be picked
  - no Week/Month switch and no month chips; `LogsMode` and `withMode` go, and `LogsQuery` ranges that were
    Month (History's All) open the week of the range's end
  - swiping the week row moves one week; the arrows do the same and keep their limits
  - the log list (stepper) and the log card background match the frame
- [ ] **Step 3: Run, expect failure.**
- [ ] **Step 4: Implement.** Remove the mode from `LogsSelection`; add `pickDay(LogicalDay, {today})`
  (replacing `pickMonth`); the calendar is a `showAppSheet`. Update Screens spec 5.1 to 5.2 to match.
- [ ] **Step 5: Run, expect pass.**
- [ ] **Step 6: Commit** `fix(logs): weeks only, with a calendar to pick a day`.

### Task F5: Review the fixes

- [ ] **Step 1:** Run `fvm dart format .`, `fvm flutter analyze --fatal-infos` and the tests of F1 to F4.
- [ ] **Step 2:** Update `docs/CURRENT_STATE.md` (what was and wasn't seen; M7 is next). Commit
  `docs: record the UI fixes`.

# Phase 5: Stage management (Stages spec)

### Task 13: Holds in `ReductionPlan`

**Files:**
- Create: `lib/features/plan/domain/entities/plan_hold.dart`
- Modify: `reduction_plan.dart`, `plan_model.dart`
- Test: `test/features/plan/domain/reduction_plan_holds_test.dart`

**Interfaces:**
- Produces: `PlanHold({required LogicalDay startDay, int days = 7})`. `ReductionPlan(..., quitDay: agreed, List<PlanHold> holds = const [])`,
  with `LogicalDay get agreedQuitDay` (stored) and `LogicalDay get quitDay` (agreed plus held days). `totalDays` uses
  `quitDay`; `daysPerDrop` uses `agreedQuitDay`. Equality includes `holds`. `ReductionPlanMapper.toCompanion` writes
  `agreedQuitDay`.

- [ ] **Step 1: Write the failing tests** from Stages spec 3 and 9. 12 a day from Oct 12, quit Jan 4, hold from Nov 9:
  - stage 4 runs Nov 2 to 15, 14 days, and stage count stays 12
  - `limitOn`: Nov 8 is 9, Nov 15 is 9, Nov 16 is 8
  - `quitDay` is Jan 11, `agreedQuitDay` Jan 4, `daysPerDrop` still 7
  - two holds add up; a hold on the first stage's end and on the last stage (`limitOn` holds 1 for 7 days, then 0)
  - stages under and over 7 days
  - `nextDropOn`, `plannedReduction`
  - a plan with no holds matches today's results, day by day, for several plans
- [ ] **Step 2: Run, expect failure.**
- [ ] **Step 3: Implement** the limit rule:

```dart
int _limitAt(int real) {
  var shift = 0;
  for (final hold in _sortedHolds) {
    final at = hold.startDay.daysSince(startDay);
    if (real < at) break;
    if (real < at + hold.days) return _taperAt(at - 1 - shift);
    shift += hold.days;
  }
  return _taperAt(real - shift);
}
```

  `_taperAt` is today's `_limitAt` over `agreedQuitDay − startDay`.
- [ ] **Step 4: Run, expect pass**, then the full suite: every existing `quitDay` reader must be unchanged with no holds.
- [ ] **Step 5: Commit** `feat(plan): let a plan hold a stage`.

### Task 14: `plan_holds` and `stage_checks`, v11

**Files:**
- Create: `tables/plan_holds_table.dart`, `tables/stage_checks_table.dart`, `test/fixtures/exhale_v10.sqlite`,
  `lib/features/plan/domain/entities/stage_check.dart`, `lib/features/plan/domain/repositories/stage_check_repository.dart`,
  `lib/features/plan/data/datasources/stage_check_local_data_source.dart`,
  `lib/features/plan/data/repositories/local_stage_check_repository.dart`
- Modify: `app_database.dart` (and `.g`), `plan_local_data_source.dart`, `local_plan_repository.dart`, `plan_model.dart`,
  `plan_injection.dart`, `plan_providers.dart`
- Test: migration test, `test/features/plan/data/stage_check_repository_test.dart`, the plan repository test

**Interfaces:**
- Produces:

```dart
enum StageOutcome { passed, skipped, hold, review, reassess }
class StageCheck { LogicalDay planStartDay, windowEndDay, checkDay; StageOutcome outcome; DateTime? answeredAt; }
abstract interface class StageCheckRepository {
  Stream<List<StageCheck>> watchChecks(int habitId);          // newest first
  Future<Result<List<StageCheck>>> getChecks(int habitId);
  Future<Result<void>> record(int habitId, StageCheck check, {PlanHold? hold, LogicalDay? closesHoldWindow});
  Future<Result<void>> answer(int habitId, LogicalDay planStartDay, LogicalDay windowEndDay, DateTime at);
  Future<Result<void>> keepOriginalDate(int habitId, LogicalDay planStartDay, LogicalDay windowEndDay, LogicalDay holdStart, DateTime at);
}
```

  `stageCheckRepositoryProvider`, `stageChecksProvider` (`StreamProviderFamily<List<StageCheck>, int>`).

- [ ] **Step 1: Make the v10 fixture** the way Task 1 did, from `exhale_v9.sqlite`, before bumping.
- [ ] **Step 2: Write the failing tests.**
  - `upgrade from v10`: `_expectLatest`, and both tables are empty with existing rows kept
  - `watchHistory` and `getHistory` return a plan's holds, and `watchHistory` emits when a hold is added
  - `record` writes the check and hold together; a duplicate `(plan, window_end)` writes neither and returns success
  - `keepOriginalDate` deletes the hold and answers, together
  - `replaceFrom` removes holds and checks of the plans it drops, with foreign keys on
- [ ] **Step 3: Run, expect failure.**
- [ ] **Step 4: Implement.** Tables per Stages spec 6. Add `if (from < 11)` creating both. Plans read through a join on
  `plan_holds`, grouped by plan, so the stream sees both tables. Resolve `plan_id` from `(habit_id, start_day)`. Ask Fawad,
  then run codegen.
- [ ] **Step 5: Run, expect pass.**
- [ ] **Step 6: Commit** `feat(data): add stage checks and holds at schema v11`.

### Task 15: `StageChecks`

**Files:**
- Create: `lib/features/plan/domain/services/stage_checks.dart`
- Test: `test/features/plan/domain/stage_checks_test.dart`

**Interfaces:**
- Consumes: `PlanHistory`, `StageCheck`, `buildDailyProgress`.
- Produces:

```dart
class StageCheckResult { StageOutcome outcome; LogicalDay windowEndDay; int logged, allowed, overDays;
  PlanHold? hold; bool closesWaitingHold; }
abstract final class StageChecks { static StageCheckResult? evaluate({required PlanHistory history,
  required List<HabitLog> logs, required DayBoundary boundary, required List<StageCheck> checks,
  required LogicalDay today}); }
```

- [ ] **Step 1: Write the failing tests**, the Stages spec 9 "The check" list:
  - one day over and the rest at the limit passes; two over with the total over fails; two over with the total under
    passes; `logged == allowed` passes
  - a window across short stages uses each day's limit
  - no check under 7 days of plan; no check within 7 days of the last window; only the latest stage is checked
  - a stage ended 2 days ago checks, 3 days ago gives `skipped`
  - near the start at exactly 90%, just under, and before 14 days; a plan on target in its first stage is never `reassess`
  - streak: hold then review; passed in between; after a kept review; across a new plan
  - no check while a review card waits; a waiting hold is closed by the next check
  - the hold's `startDay` is the stage's last day + 1, also on a late open
- [ ] **Step 2: Run, expect failure.**
- [ ] **Step 3: Implement** Stages spec 2, with only the current plan's checks counted.
- [ ] **Step 4: Run, expect pass.**
- [ ] **Step 5: Commit** `feat(plan): add the stage check rules`.

### Task 16: Running the check

**Files:**
- Create: `lib/features/plan/domain/usecases/run_stage_check.dart`, `lib/app/shell/stage_check_listener.dart`
- Modify: `app_shell.dart`, `plan_injection.dart`, `plan_providers.dart`
- Test: `test/features/plan/domain/usecases/run_stage_check_test.dart`, `test/app/stage_check_listener_test.dart`

**Interfaces:**
- Consumes: `StageChecks`, `StageCheckRepository`, `PlanRepository`, `HabitLogRepository`, `TransactionRunner`.
- Produces: `RunStageCheck` with `Future<Result<void>> call(({int habitId, LogicalDay today, DayBoundary boundary}))`;
  `StageCheckListener` wrapping the shell's child, running on first build and when `todayProvider` changes.

- [ ] **Step 1: Write the failing tests.**
  - a failed check stores `hold` and a `plan_holds` row together; a pass stores only the check
  - a read failure stores nothing and returns the failure, and the next run works
  - **two simultaneous calls store one check and one hold** (Review Focus)
  - no habit or no plan: nothing
  - the listener runs at start and when the logical day changes, not on every rebuild
- [ ] **Step 2: Run, expect failure.**
- [ ] **Step 3: Implement.** Everything from reading checks to writing runs inside `TransactionRunner.run`, so the second
  call sees the first's row. Failures are logged and shown to no one (Stages spec 7).
- [ ] **Step 4: Run, expect pass.**
- [ ] **Step 5: Commit** `feat(plan): run the stage check at start and each new day`.

### Task 17: `PlanChoices` and wording

**Files:**
- Create: `lib/features/plan/domain/services/plan_choices.dart`
- Modify: `lib/features/habit/presentation/habit_wording.dart`
- Test: `test/features/plan/domain/plan_choices_test.dart`, the wording test

**Interfaces:**
- Produces: `enum ChoiceKind { realNumber, slowDown, keep, startAgain }`;
  `class PlanChoice { ChoiceKind kind; int limit; LogicalDay quitDay; double daysPerDrop; int changeDays; }`;
  `PlanChoices.review({required ReductionPlan current, required LogicalDay today, required int windowAverage, required int checkedLimit})`;
  `PlanChoices.reassess({required ReductionPlan current, required LogicalDay today, required int average})`.
  `HabitWording.supportLine` and `HabitWording.stopSuddenlyLine` (null except alcohol).

- [ ] **Step 1: Write the failing tests** with the mocks' numbers:
  - **AC:** 12 a day from 2026-10-12, quit Jan 4, a hold from Nov 9, today Nov 16, average 11, checked limit 9. Real number:
    11 a day, Feb 1, +21 days. Slow down: 9 a day, every 14 days, Mar 22, +70. Keep: 8 today, Jan 11, 0.
  - **AD:** no hold, today Nov 9, average 12. Start again: 12, Feb 1, +28. Keep: Jan 4, 0.
  - the 80 cap; the plan length rounded up; `pace` under 1.5; the later-of rule when `suggestedQuitDay` is earlier than the
    current quit date
  - wording: nicotine habits and others per Stages spec 5.4; `stopSuddenlyLine` for alcohol only
- [ ] **Step 2: Run, expect failure.**
- [ ] **Step 3: Implement** Stages spec 4.
- [ ] **Step 4: Run, expect pass.**
- [ ] **Step 5: Commit** `feat(plan): add the review and reassess choices`.

### Task 18: Home cards

**Files:**
- Create: `lib/features/home/presentation/widgets/stage_cards.dart`,
  `lib/features/home/presentation/providers/stage_card_provider.dart`,
  `lib/features/plan/domain/usecases/answer_stage_check.dart`, `keep_original_date.dart` (same folder)
- Modify: `ring_card.dart`
- Test: `test/features/home/stage_cards_test.dart`

**Interfaces:**
- Consumes: `stageChecksProvider`, `planHistoryProvider`.
- Produces: `sealed class StageCard` with `HoldCardData`, `ReviewCardData`, `ReassessCardData`, each carrying its figures;
  `stageCardProvider`: `ProviderFamily<StageCard?, int>`, reading only the **current plan's** unanswered row;
  `AnswerStageCheck` and `KeepOriginalDate` use cases.

- [ ] **Step 1: Write the failing tests** (iOS where they pop):
  - hold card copy from Stages spec 5.1, including "Zero can wait." on the last stage and the late-open wording
  - Keep is offered only on the check's day; it restores today's limit and removes the card; the next day only Got it shows
  - Got it answers; a failed save keeps the card with a snackbar; two presses save once
  - review card copy, with and without the number; no dismiss
  - reassess card copy
  - cards show on today only; a review card hides `QuitReachedCard`
  - **saving Edit plan while a review card waits: the card goes and doesn't return** (Review Focus)
- [ ] **Step 2: Run, expect failure.**
- [ ] **Step 3: Implement** against frames AA and AB, in the `_Reveal` slot beside `QuitReachedCard`. Buttons open the sheets
  through a stub until Task 19.
- [ ] **Step 4: Run, expect pass.**
- [ ] **Step 5: Commit** `feat(home): show the hold, review and reassess cards`.

### Task 19: Review and reassess sheets

**Files:**
- Create: `lib/features/home/presentation/widgets/plan_review_sheet.dart`, `plan_reassess_sheet.dart`,
  `lib/features/plan/domain/usecases/answer_with_new_plan.dart`
- Modify: `stage_cards.dart`
- Test: `test/features/home/plan_sheets_test.dart`, `test/features/plan/domain/usecases/answer_with_new_plan_test.dart`

**Interfaces:**
- Consumes: `PlanChoices`, `PlanReport.totals`, `ProgressCalculator.triggerBreakdown`, `TransactionRunner`.
- Produces: `AnswerWithNewPlan` with input `({int habitId, PlanDraft draft, LogicalDay planStartDay, LogicalDay windowEndDay})`,
  saving the plan and the answer in one transaction.

- [ ] **Step 1: Write the failing tests.**
  - review: tiles over the 14 days; top 3 triggers, hidden when none; three choices with the first selected; button and
    under-button text changing with the selection; detail and change labels (Stages spec 5.3)
  - reassess: "Still yours" totals match Plan details; saved hidden for a no-cost habit; the support line; the alcohol line
    for alcohol only
  - a new plan from a sheet: stages restart at 1 and Behind you lists the earlier stages; the card goes
  - Keep answers with no new plan, and the next failure holds first
  - a failed save keeps the sheet and changes nothing; two presses save once
  - VoiceOver reads a choice's name, detail, date and change as one; scrolling works at 200%
- [ ] **Step 2: Run, expect failure.**
- [ ] **Step 3: Implement** against frames AC and AD with `showAppDraggableSheet`.
- [ ] **Step 4: Run, expect pass.**
- [ ] **Step 5: Commit** `feat(home): add the review and reassess sheets`.

### Task 20: Milestone M7 review and handoff

- [ ] **Step 1: Ask Fawad** for the review on Opus 5.5 high, in a fresh session, over the Stages spec and Phase 5's diff. Focus:
  the limit rule with holds, the streak, transactions, and past limits never changing.
- [ ] **Step 2: Fix findings**, each seen red first where a test can show it.
- [ ] **Step 3: Ask Fawad** for a simulator walk: a hold, a review and a reassess from seeded data.
- [ ] **Step 4: Update** `docs/CURRENT_STATE.md`, `CLAUDE.md` ("schema v11", new features) and the roadmap's rows.
- [ ] **Step 5: Commit** `docs: record the M7 review`, and give Fawad the push command. The real iPhone pass stays pending
  and must include these screens.
