# Home, Details and Logs Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Per-habit data, a habit dashboard as Home, a filterable Logs page, the new logging menus and editors, multiple habits, and every designed state.

**Architecture:** Phase 1 moves the habit out of settings into a `habits` table and keys plans and logs by habit id (schema v8); every provider that reads plans or logs becomes a family keyed by habit id. Phases 2–5 build screens on those providers. Pure calculations live in `ProgressCalculator` and are unit-tested; widgets are tested through `pumpAppPastSplash`.

**Tech Stack:** Flutter 3.47.2 / Dart 3.13 via FVM, Riverpod 3 (manual providers, no codegen), get_it `sl`, drift, go_router, very_good_analysis.

**Spec:** `docs/superpowers/specs/2026-10-21-home-details-logs-design.md` (designs linked there). Roadmap and milestones: `docs/superpowers/plans/2026-10-21-home-details-logs-roadmap.md`.

## Global Constraints

- Run Flutter and Dart only through FVM: `fvm flutter …`, `fvm dart …`.
- Every task ends green on: `fvm dart format --set-exit-if-changed lib test`, `fvm flutter analyze --fatal-infos`, `fvm flutter test`.
- Drift codegen after table changes: `fvm dart run build_runner build -d`.
- Claude creates branches and edits files only; **Fawad commits and pushes**. Each task ends with a checkpoint giving the commit message. No Co-Authored-By trailers.
- Manual Riverpod providers (no codegen); repositories registered in `*_injection.dart` with get_it; use cases return `Result<T>`.
- Copy is exactly as in the spec (e.g. "23 / 77 allowed", "Save without trigger", "Hold + for more").
- Back-fill reaches 30 days before a habit's first plan day; never into the future.
- No teaching comments; match the surrounding comment density.
- Tests use `FixedClock(DateTime(2026, 10, 16, 15, 42))` (Friday) unless a test says otherwise.

## Review Focus

1. **Logs between midnight and the reset hour (4 AM)** belong to the previous logical day in period stats, trigger breakdowns, Logs day groups and the All-time series. Test owner: Task 2.1.
2. **Plan edited mid-period:** "allowed" sums each day's own limit from the plan in force that day, not today's limit. Test owner: Task 2.1.
3. **Habit archived while its dashboard or Logs filter is open:** the app returns to Home and never throws. Test owner: Task 4.3.
4. **Upgrading a real v7 database** with a null price, logs stamped with another kind and two plans keeps every plan and log on habit 1. Test owner: Task 1.2.
5. **A period entirely before the plan or a plan starting tomorrow:** a period entirely before the plan has allowed 0; a plan starting tomorrow gives the whole period's allowance with `allowedByToday` 0 (spec §5). Average is null (shown as "—"), no division by zero. Test owner: Task 2.1.

---

## Phase 1: Habits foundation (milestone M1)

### Task 1.1: Habit entity, table, repository

**Files:**
- Create: `lib/core/data/local/database/tables/habits_table.dart`
- Create: `lib/features/habit/domain/entities/tracked_habit.dart`, `lib/features/habit/domain/entities/habit_draft.dart`
- Create: `lib/features/habit/domain/repositories/habit_repository.dart`
- Create: `lib/features/habit/domain/usecases/add_habit.dart`, `update_habit.dart`, `archive_habit.dart`
- Create: `lib/features/habit/data/datasources/habit_local_data_source.dart`, `data/models/tracked_habit_model.dart`, `data/repositories/local_habit_repository.dart`
- Create: `lib/features/habit/habit_injection.dart`; register in `lib/core/di/injection_container.dart`
- Modify: `lib/core/data/local/database/app_database.dart` (add table only; schema bump happens in 1.2)
- Test: `test/features/habit/data/local_habit_repository_test.dart`, `test/features/habit/domain/tracked_habit_test.dart`

**Interfaces:**
- Produces:
  - `class TrackedHabit { int id; Habit habit; String? reason; int? priceCents; int unitsPerContainer; DateTime createdAt; DateTime? archivedAt; DateTime? quitAcknowledgedAt; double? get unitPriceCents; TrackedHabit copyWith(...) }` (value equality)
  - `class HabitDraft { Habit habit; String? reason; int? priceCents; int unitsPerContainer }`
  - `abstract interface class HabitRepository { Stream<List<TrackedHabit>> watchActive(); Future<Result<List<TrackedHabit>>> getActive(); Future<Result<TrackedHabit>> add(HabitDraft draft); Future<Result<void>> update(TrackedHabit habit); Future<Result<void>> archive(int id); }`
  - Use cases `AddHabit(HabitDraft) → Result<TrackedHabit>`, `UpdateHabit(TrackedHabit) → Result<void>`, `ArchiveHabit(int id) → Result<void>` (archive stamps `archivedAt` from `Clock`).
  - Table `Habits` (`@DataClassName('HabitRow')`): `id`, `kind` text, `custom_name`, `custom_unit`, `reason`, `price_cents`, `units_per_container` (default 20), `created_at` (default now), `archived_at`, `quit_acknowledged_at`.

- [ ] **Step 1: Write failing tests**
  - `tracked_habit_test.dart`: `unitPriceCents` is `price / unitsPerContainer` for a container habit (Vaping 1200 / 30 → 40.0), `price` for a per-unit habit (Caffeine 450 → 450.0), `null` for Social media and when price is null. A custom habit row maps to `Habit.custom(name, unit)`.
  - `local_habit_repository_test.dart`: `add` returns an id > 0; `watchActive` emits habits ordered by `createdAt`; `archive(id)` removes it from `watchActive` but keeps the row; `update` persists `reason` and `priceCents`.
- [ ] **Step 2: Run** `fvm flutter test test/features/habit` — expect FAIL (types missing).
- [ ] **Step 3: Implement** the files above; move the `unitPriceCents` rule from `AppSettings` into `TrackedHabit` (AppSettings keeps its copy until Task 1.3 removes it). Run build_runner.
- [ ] **Step 4: Run** `fvm flutter test test/features/habit` — expect PASS; full suite green.
- [ ] **Step 5: Checkpoint (Fawad commits):** `feat(habit): habits table, entity and repository`

### Task 1.2: Schema v8 and migration

**Files:**
- Modify: `lib/core/data/local/database/tables/plans_table.dart` (add `habitId` FK to habits; replace `start_day` unique with unique `{habitId, startDay}`)
- Modify: `lib/core/data/local/database/tables/habit_logs_table.dart` (add `habitId` FK; remove `habitKind`)
- Modify: `lib/core/data/local/database/tables/settings_table.dart` (remove `habitKind`, `customHabitName`, `customHabitUnit`, `reason`, `priceCents`, `unitsPerContainer`; add `logHintSeen` bool default false)
- Modify: `lib/core/data/local/database/app_database.dart` (`schemaVersion => 8`, `from < 8` step)
- Create: `test/fixtures/exhale_v7.sqlite` (copied from the simulator, see roadmap)
- Test: `test/core/data/app_database_migration_test.dart`

**Interfaces:**
- Produces: schema v8 as in spec §6. Migration `from < 8`, in one transaction: create `habits`; insert habit id 1 from the settings row; rebuild `plans` and `habit_logs` with `habit_id = 1` (v7's `habit_kind` came from the column default and is ignored); rebuild `settings` without the moved columns. Older versions run their existing steps first, then this one.

- [ ] **Step 1: Write failing tests** in `app_database_migration_test.dart`:
  - `upgrade from v7 keeps the habit, plans and logs`: open the fixture copy; expect `user_version` 8; one active habit whose kind and reason match the fixture's settings; plan count unchanged and all `habit_id = 1`; log count unchanged.
  - `logs of every kind join habit 1` (in-memory v7 schema built in the test with one `smoking` and two `vaping` logs while settings say `vaping`): one active vaping habit; every log has `habit_id = 1`.
  - `null price survives`: price null → `priceCents` null.
  - Existing v1, v2 and v5 upgrade tests now expect v8 and assert plans and logs carry `habit_id` 1.
- [ ] **Step 2: Run** `fvm flutter test test/core/data/app_database_migration_test.dart` — expect FAIL.
- [ ] **Step 3: Implement** the table changes and the `from < 8` step with `migrator.alterTable(TableMigration(..., columnTransformer: ...))` per table; run build_runner. The app does not compile yet; Task 1.3 fixes the callers. Keep this task's tests compiling by building them against the database directly.
- [ ] **Step 4: Run** the migration test file — expect PASS.
- [ ] **Step 5: Checkpoint:** combined with Task 1.3 (the app must build before a commit).

### Task 1.3: Plans and logs keyed by habit; providers become families

**Files:**
- Modify: `lib/features/plan/domain/repositories/plan_repository.dart`, `data/datasources/plan_local_data_source.dart`, `data/repositories/local_plan_repository.dart`, `data/models/plan_model.dart`, `domain/usecases/save_plan.dart`, `presentation/providers/plan_providers.dart`
- Modify: `lib/features/tracking/domain/entities/habit_log.dart`, `domain/repositories/habit_log_repository.dart`, `data/**`, `domain/usecases/*.dart`, `presentation/providers/tracking_providers.dart`, `presentation/log_flow.dart`, `presentation/widgets/*`
- Modify: `lib/features/settings/domain/entities/app_settings.dart`, `data/models/settings_model.dart`, `presentation/providers/settings_providers.dart`
- Modify: `lib/features/home/presentation/**`, `lib/features/onboarding/presentation/providers/setup_form_provider.dart`
- Create: `lib/features/habit/presentation/providers/habit_providers.dart`
- Test: update every affected test; add `test/features/habit/presentation/habit_providers_test.dart`

**Interfaces:**
- Consumes: Task 1.1 `HabitRepository`, `TrackedHabit`.
- Produces:
  - `PlanRepository { Stream<PlanHistory?> watchHistory(int habitId); Future<Result<PlanHistory?>> getHistory(int habitId); Future<Result<void>> savePlan(int habitId, ReductionPlan plan); }`; `SavePlan.call(({int habitId, PlanDraft draft}))`.
  - `HabitLog { int id; int habitId; DateTime loggedAt; Trigger? trigger; String? note }` (`habitKind` removed).
  - `HabitLogRepository { addLog({required int habitId, required DateTime loggedAt, Trigger? trigger, String? note}); updateLog(HabitLog); deleteLog(int id); Stream<List<HabitLog>> watchLogs({int? habitId, required DateTime from, required DateTime to}); Stream<HabitLog?> watchLatest({int? habitId}); Stream<List<HabitLog>> watchRecent({required int limit}); }` — `habitId: null` means every active habit.
  - `AddHabitLogInput { int habitId; DateTime? loggedAt; Trigger? trigger; String? note }`.
  - Providers in `habit_providers.dart`: `habitRepositoryProvider`, `activeHabitsProvider = StreamProvider<List<TrackedHabit>>`, `habitProvider = Provider.family<TrackedHabit?, int>` (replaces the settings `habitProvider`), `singleHabitIdProvider = Provider<int?>` (the id when exactly one habit is active).
  - Families: `planHistoryProvider(int habitId)`, `logsForDayProvider(({int habitId, LogicalDay day}))`, `latestLogProvider(int habitId)`, `dayProgressProvider(({int habitId, LogicalDay day}))`, `logsInRangeProvider(({int? habitId, PeriodRange range}))`, `periodSummaryProvider(({int habitId, PeriodRange range}))`, `habitStatsProvider(int habitId)` (renamed from `homeStatsProvider`), `earliestDayProvider(int habitId)`.
  - `AppSettings` loses habit, reason and price fields; gains `logHintSeen`.
  - `SetupFormController.submit()` creates the habit with `AddHabit`, then `SavePlan` with its id.
- [ ] **Step 1: Update tests first**: repository tests pass `habitId: 1`; `local_plan_repository_test` adds `plans of two habits do not replace each other` (same start day, habits 1 and 2, both kept); `local_habit_log_repository_test` adds `watchLogs with null habitId returns every active habit's logs` and `watchRecent returns the newest N across habits`; setup controller test `submit creates habit 1 with reason and price, then its plan`; `habit_providers_test` `singleHabitIdProvider is null with zero or two habits`.
- [ ] **Step 2: Run** `fvm flutter test` — expect compile errors and failures.
- [ ] **Step 3: Implement** the signature changes; every widget that read `habitProvider`/`planHistoryProvider` gets the habit id from `singleHabitIdProvider` for now (Phase 2 passes it explicitly). The splash routes to setup when `activeHabitsProvider` is empty.
- [ ] **Step 4: Run** the format, analyze and full test commands — expect all green. Run the app on the exhale simulator over the existing v7 data: Home shows the same numbers as before the upgrade.
- [ ] **Step 5: Checkpoint (Fawad commits Tasks 1.2 and 1.3 together):** `feat(data): per-habit plans and logs, schema v8`

**Milestone M1 reached.**

---

## Phase 2: Dashboard and Logs (milestone M2)

### Task 2.1: Period stats, trigger breakdown and all-time series

**Files:**
- Create: `lib/features/tracking/domain/entities/period_stats.dart`, `trigger_breakdown.dart`, `all_time_series.dart`
- Modify: `lib/features/tracking/domain/services/progress_calculator.dart`
- Test: `test/features/tracking/domain/services/period_stats_test.dart`, `trigger_breakdown_test.dart`, `all_time_series_test.dart`

**Interfaces:**
- Produces:
  - `class PeriodStats { int logged; int allowed; int allowedByToday; int get underBy => allowedByToday - logged; double? avgPerDay; int daysOver; int daysOnTrack; }`
  - `ProgressCalculator.periodStats({required PeriodRange range, required Iterable<HabitLog> logs, required DayBoundary boundary, required PlanHistory history, required LogicalDay today}) → PeriodStats` — only days from `history.firstDay` count; allowed uses `history.limitOn(day)` per day.
  - `class TriggerShare { Trigger trigger; int count; double fraction; }`; `class TriggerBreakdown { List<TriggerShare> shares; int noTrigger; int total; List<TriggerShare> top(int n); }` (shares sorted by count desc then enum order; `top` excludes no-trigger).
  - `ProgressCalculator.triggerBreakdown(Iterable<HabitLog> logs) → TriggerBreakdown`.
  - `class AllTimeSeries { LogicalDay start; LogicalDay end; LogicalDay today; List<int> counts; List<double>? average7; List<int> limits; bool weekly; }` where `end = max(quitDay, today)`, `counts` covers start..today, `limits` covers start..end, `average7` non-null once there are 14 or more days, and `weekly` is true (counts and limits summed per week) once there are more than 180 days.
  - `ProgressCalculator.allTime({required Iterable<HabitLog> logs, required DayBoundary boundary, required PlanHistory history, required LogicalDay today}) → AllTimeSeries`.
- [ ] **Step 1: Write failing tests** (plan from Oct 14, 9/day, quit Dec 16; today Oct 16):
  - `week allowed and under`: week Mon Oct 12–Sun Oct 18, logs 6 on Oct 14, 6 on Oct 15, 4 today → `logged 16`, `allowed 45` (plan days Oct 14–18 × 9), `allowedByToday 27`, `underBy 11`, `avgPerDay closeTo(16 / 3)`, `daysOver 0`, `daysOnTrack 3`.
  - `log at 01:30 counts to the previous day` (Review Focus 1).
  - `plan edited mid-week keeps earlier days' limits` (Review Focus 2): replan on Oct 16 to 5/day → allowed = 9 + 9 + 5 + 5 + 5.
  - `period before the plan` (Review Focus 5): range Oct 5–11 → `allowed 0`, `avgPerDay null`.
  - `trigger breakdown`: 2 stress, 1 work, 1 null → shares stress 0.5, work 0.25; `noTrigger 1`; `top(3)` has 2 entries.
  - `all-time switches to a 7-day average from 14 days`; `end extends to today after the quit date`; `over 180 days of history, counts are weekly sums plotted once per week` (series exposes `bool weekly`).
- [ ] **Step 2: Run** `fvm flutter test test/features/tracking/domain/services` — FAIL.
- [ ] **Step 3: Implement** in `ProgressCalculator`, reusing `buildDailyProgress`.
- [ ] **Step 4: Run** — PASS.
- [ ] **Step 5: Checkpoint:** `feat(stats): period stats, trigger breakdown, all-time series`

### Task 2.2: Habit dashboard shell and Home

**Files:**
- Create: `lib/features/home/presentation/widgets/habit_dashboard.dart`, `dashboard_header.dart`, `plan_card.dart`, `today_logs_card.dart`
- Modify: `lib/features/home/presentation/pages/home_page.dart`, `widgets/stage_pill.dart`, `widgets/stats_grid.dart` (money tile "Add a price ›" opens Edit plan; route added in 3.5, until then the link is hidden), `widgets/why_card.dart`
- Modify: `lib/app/router/app_routes.dart`, `app_router.dart` (add `habit = '/habit/:habitId'` with a `HabitDetailsPage` stub that renders `HabitDashboard(header: back)`)
- Test: `test/features/home/home_page_test.dart`

**Interfaces:**
- Consumes: Task 1.3 families, Task 2.1 types.
- Produces: `HabitDashboard({required int habitId, required DashboardHeaderKind header})`, `enum DashboardHeaderKind { greeting, back }`. Section order exactly as spec §4.3. `TodayLogsCard(habitId)` shows the first 3 of today and "+N more today · See all logs".
- [ ] **Step 1: Write failing widget tests** (smoking plan from Oct 14 at 9/day, quit Dec 16; today Oct 16): `one habit shows the dashboard sections in order` (find "Today's Consumption", "Streak", "History", "Your plan", "Today's logs" with ascending y); `your plan shows stage, next stage and quit date` ("Stage 1 · 9 a day (now)", "Stage 2 · 8 a day", "Starts Wed, Oct 21", "Smoke-free from Dec 16", "61 days to go"); `today's logs shows 3 and a more link` (4 logs today → "+1 more today · See all logs").
- [ ] **Step 2: Run** `fvm flutter test test/features/home` — FAIL.
- [ ] **Step 3: Implement** the dashboard; Home renders it with `singleHabitIdProvider`.
- [ ] **Step 4: Run** — PASS; full suite green.
- [ ] **Step 5: Checkpoint:** `feat(home): habit dashboard as Home`

### Task 2.3: Ring card

**Files:**
- Rename: `lib/features/home/presentation/widgets/day_card.dart` → `ring_card.dart` (`DayCard` → `RingCard`)
- Create: `lib/features/home/presentation/widgets/day_triggers.dart`
- Modify: `lib/features/home/presentation/providers/home_providers.dart` (`pickedDayProvider` → `ringDayProvider = NotifierProvider.family<RingDayController, LogicalDay?, int>`; History no longer reads it)
- Test: `test/features/home/ring_card_test.dart` (move the ring tests out of `home_page_test.dart`)

**Interfaces:**
- Consumes: `TriggerBreakdown` (2.1), `logsForDayProvider`, Logs route from Task 2.6 (`LogsQuery`).
- Produces: `RingCard({required int habitId})`; `DayTriggers({required int habitId, required LogicalDay day})` showing at most 3 rows "Stress · 2 · 50%" with a chevron, each pushing `LogsQuery(habitId, from: day, to: day, trigger: t)`.
- [ ] **Step 1: Write failing tests**: `shows last entry and last trigger` (a stress log at 15:18 → "24m ago", "3:18 PM", "Stress"); `today's triggers show top 3 with counts`; `tapping a trigger opens Logs filtered to that day and trigger` (expect the Logs filter chips "Today" and "Stress"); `swiping the ring does not move the History card` (History label stays "This week" after stepping back 7 days); existing swipe/back-fill tests still pass.
- [ ] **Step 2: Run** — FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run** — PASS.
- [ ] **Step 5: Checkpoint:** `feat(home): ring card with last entry and day triggers`

### Task 2.4: History card (Week line, Month rings, All)

**Files:**
- Create: `lib/features/home/presentation/widgets/history/week_line_chart.dart`, `month_ring_calendar.dart`, `all_time_chart.dart`, `history_stats_line.dart`, `top_triggers.dart`
- Modify: `lib/features/home/presentation/widgets/history_card.dart` (rewrite), `providers/home_providers.dart` (`historyPeriodProvider` family `{week, month, all}`, `historyAnchorProvider(habitId)`)
- Keep unused: `widgets/history_chart.dart`
- Test: `test/features/home/history_card_test.dart`

**Interfaces:**
- Consumes: `PeriodStats`, `TriggerBreakdown`, `AllTimeSeries` (2.1); `LogsQuery` (2.6).
- Produces: `enum HistoryPeriod { week, month, all }`; `HistoryCard({required int habitId})`; charts take data only: `WeekLineChart({required PeriodSummary summary, required ValueChanged<LogicalDay> onDayTap})`, `MonthRingCalendar({required PeriodSummary summary, required ValueChanged<LogicalDay> onDayTap})`, `AllTimeChart({required AllTimeSeries series})` (CustomPainter each). Each day gets a full-height tap column ≥ 44 pt (week) / one ring cell (month).
- [ ] **Step 1: Write failing tests** (same fixture as Task 2.1: plan Oct 14, 9/day, quit Dec 16; logs 6, 6, 4): `week shows total and stats line` ("16 / 45 allowed", "11 under", "Avg 5.3/day", "0 days over", "3 days on track"); `month shows the ring calendar and colour key` (find "Under", "At limit", "Over", "Before plan"); `all shows since-day-1 label` ("Since Oct 14 · day 3 of 63"); `top triggers capped at 3 with All triggers link`; `tapping Wednesday opens Logs for Oct 14`; `tapping a trigger chip opens Logs for the period and trigger`; semantics label per day ("Wednesday, Oct 14: 6 of 9").
- [ ] **Step 2: Run** — FAIL.
- [ ] **Step 3: Implement** painters (smooth line via cubic segments between points; dotted limit line labelled "limit N" at the right; rings with `drawArc`).
- [ ] **Step 4: Run** — PASS; golden-free.
- [ ] **Step 5: Checkpoint:** `feat(home): history card with week line, month rings and all-time`

### Task 2.5: Logs page

**Files:**
- Create: `lib/features/logs/presentation/logs_query.dart`, `pages/logs_page.dart`, `widgets/logs_period_card.dart`, `widgets/day_group.dart`, `widgets/log_row.dart`, `providers/logs_providers.dart`
- Modify: router (`logs = '/logs'`, query params `habit`, `from`, `to`, `trigger`)
- Delete: `lib/features/tracking/presentation/widgets/day_detail_sheet.dart` and its uses
- Test: `test/features/logs/logs_page_test.dart`, `test/features/logs/logs_query_test.dart`

**Interfaces:**
- Produces: `class LogsQuery { int? habitId; LogicalDay? from; LogicalDay? to; Trigger? trigger; Uri toUri(); static LogsQuery fromUri(Uri); }`; `void openLogs(BuildContext, LogsQuery)`; `LogsPage({required LogsQuery query})`. Period card shows `PeriodStats` and the full `TriggerBreakdown` as filter chips; day groups newest first, header "4 of 11 allowed" / "13 of 11 allowed · 2 over"; rows collapse after 3 ("Show 7 more"); empty day → "Add a missed log for this day"; swipe left deletes with confirm and Undo snackbar; tap opens the log editor (Task 3.4 restyles it).
  When the query is one day plus a trigger (opened from the ring), the period card reads "2 of 4 logs today · 50%" and "Allowed today: 4 of 11 used · 7 left" with a bar split into that trigger, other triggers and what is left.
- [ ] **Step 1: Write failing tests**: `LogsQuery round-trips through a URI`; `groups by logical day with allowed counts`; `one day plus a trigger shows the trigger's share and today's allowance`; `trigger chip filters the list and shows a removable chip`; `swipe left deletes after confirm and Undo restores`; `long day collapses to 3 with Show more`; `day before the plan shows no limit`.
- [ ] **Step 2: Run** — FAIL.
- [ ] **Step 3: Implement**; remove the day detail sheet and update callers to `openLogs`.
- [ ] **Step 4: Run** — PASS; simulator check of every Logs entry point.
- [ ] **Step 5: Checkpoint:** `feat(logs): logs page with filters, allowed counts and swipe delete`

**Milestone M2 reached.**

---

## Phase 3: Logging and editing (milestone M3)

### Task 3.1: + button tap, hold and menu

**Files:**
- Modify: `lib/app/shell/app_shell.dart` (`_LogButton`), `lib/features/tracking/presentation/log_flow.dart`
- Create: `lib/features/tracking/presentation/widgets/log_menu.dart`
- Test: `test/app/ios_shell_test.dart`

**Interfaces:**
- Consumes: `activeHabitsProvider`, `singleHabitIdProvider`.
- Produces: `Future<void> logNow(BuildContext context, WidgetRef ref, {required int habitId})`; `Future<void> showLogMenu(BuildContext context, WidgetRef ref, {required Rect anchor})` with items: one habit → "Log now", "Add a missed log", "Add a habit"; two or more → each habit row ("4 of 9 today", amber when at limit), "Add a missed log", "Add a habit". "Add a habit" routes to `/add-habit` (Task 4.1; hidden until then).
- [ ] **Step 1: Write failing tests**: `one habit: tap logs`; `one habit: long-press opens the menu with Log now`; `two habits: tap opens the menu listing both with today's counts`; `menu habit opens its trigger sheet`.
- [ ] **Step 2: Run** — FAIL. **Step 3: Implement.** **Step 4: Run** — PASS.
- [ ] **Step 5: Checkpoint:** `feat(log): plus button tap and hold with habit menu`

### Task 3.2: Trigger sheet habit chip

**Files:** Modify `lib/features/tracking/presentation/widgets/trigger_sheet.dart`, `trigger_picker.dart`; Test `test/features/home/home_page_test.dart`

**Interfaces:** `showTriggerSheet(BuildContext, {required int habitId, bool offerToStopAsking})`; chip text `'${habit.name} · ${count + 1} of $limit after this'`; picker uses that habit's kind triggers.
- [ ] **Steps 1–4:** test `trigger sheet names the habit and the count after this log` ("Smoking · 5 of 9 after this"), then implement.
- [ ] **Step 5: Checkpoint:** `feat(log): trigger sheet shows the habit`

### Task 3.3: One-time hold hint

**Files:** Create `lib/app/shell/log_hint.dart`; Modify `app_shell.dart`, `log_flow.dart`; Test `test/app/ios_shell_test.dart`

**Interfaces:** shows after the first saved log when one habit is active and `settings.logHintSeen` is false; glass bubble "Hold + for more", body "Add a missed log, or start tracking another habit.", button "Got it" sets `logHintSeen`.
- [ ] **Steps 1–4:** tests `hint shows once after the first log` and `Got it hides it for good`.
- [ ] **Step 5: Checkpoint:** `feat(log): one-time hold hint`

### Task 3.4: Edit log sheet

**Files:** Modify `lib/features/tracking/presentation/widgets/log_editor_sheet.dart`; Test `test/features/logs/logs_page_test.dart`

**Interfaces:** `showLogEditorSheet(BuildContext, {required int habitId, required LogicalDay day, HabitLog? log})`; glass sheet title "Edit log" / "Add missed log", subtitle "Vaping · Wed, Oct 21", trigger grid with icons, note, "Save changes", "Delete this log".
- [ ] **Steps 1–4:** tests `edit changes time and trigger`, `delete from the sheet asks to confirm`, `add missed log on a past day lands on that day`.
- [ ] **Step 5: Checkpoint:** `feat(log): restyled edit log sheet`

### Task 3.5: Edit plan

**Files:**
- Create: `lib/features/plan/presentation/pages/edit_plan_page.dart`, `providers/edit_plan_provider.dart`
- Modify: router (`/habit/:habitId/plan`), `stats_grid.dart` (show "Add a price ›"), dashboard tune button
- Test: `test/features/plan/edit_plan_page_test.dart`

**Interfaces:** `EditPlanController` (`Notifier.family<EditPlanState, int>`) with `setDailyLimit(int)`, `selectQuitPreset(EditQuitPreset)` (`keepCurrent`, `suggested`, `weeks8`, `weeks16`), `setQuitDay`, `setPriceText`, `setUnitsPerContainer`, `setReason`, `Future<bool> save()` → `UpdateHabit` then `SavePlan(habitId, plan starting today)`.
- [ ] **Steps 1–4:** tests `saving starts a new plan today and keeps yesterday's limit`, `price updates money saved`, `Add a price link opens Edit plan`.
- [ ] **Step 5: Checkpoint:** `feat(plan): edit plan page`

**Milestone M3 reached.**

---

## Phase 4: Multiple habits (milestone M4)

### Task 4.1: Add a habit flow

**Files:** Modify `habit_picker_page.dart`, `setup_page.dart`, `setup_form_provider.dart` (mode `SetupMode { firstRun, addHabit }`); router `/add-habit`, `/add-habit/plan`; Test `test/features/onboarding/add_habit_test.dart`

**Interfaces:** in `addHabit` mode the picker marks active kinds "TRACKING" and disables them, asks "Why this one?", and `submit()` adds the habit and its plan then returns Home.
- [ ] **Steps 1–4:** tests `tracked habit is disabled`, `adding a second habit shows the habit list on Home`.
- [ ] **Step 5: Checkpoint:** `feat(habit): add a habit flow`

### Task 4.2: Multi-habit Home

**Files:** Create `lib/features/home/presentation/widgets/habit_list_home.dart`, `habit_summary_card.dart`, `combined_impact_card.dart`, `recent_logs_card.dart`; Modify `home_page.dart`, `progress_calculator.dart` (`combinedStreak(Map<int, List<DailyProgress>>) → int`); Test `test/features/home/habit_list_home_test.dart`, calculator test

**Interfaces:** Home shows `HabitDashboard` when `singleHabitIdProvider != null`, else `HabitListHome`. Cards push `/habit/:id`. Combined impact: money summed, "All on track" streak, avoided per habit. Recent logs: `watchRecent(limit: 6)`, "See all logs" → `LogsQuery(habitId: null)`.
- [ ] **Steps 1–4:** tests `combined streak breaks when any habit is over`, `cards show status and progress`, `recent logs mix habits newest first`.
- [ ] **Step 5: Checkpoint:** `feat(home): multi-habit home`

### Task 4.3: Details header, switcher and stop tracking

**Files:** Modify `dashboard_header.dart`, `edit_plan_page.dart` ("Stop tracking <habit>" → `ArchiveHabit`); Test `test/features/home/habit_details_test.dart`

**Interfaces:** back bar with habit switcher pill (bottom sheet listing active habits) and tune button; archiving pops to Home.
- [ ] **Steps 1–4:** tests `switcher changes the shown habit`, `stopping tracking returns Home and shows the remaining habit's dashboard`, `an archived habit's open Logs filter returns Home without error` (Review Focus 3).
- [ ] **Step 5: Checkpoint:** `feat(habit): details header, switcher and stop tracking`

### Task 4.4: Logs habit tabs and All

**Files:** Modify `logs_page.dart`, `day_group.dart`; Test `logs_page_test.dart`

**Interfaces:** tabs "All" + each active habit (hidden with one); with `habitId == null` day headers list per-habit counts ("Vaping 4 · Smoking 3") and no combined limit; period card hides "allowed".
- [ ] **Steps 1–4:** tests `All shows per-habit counts without a combined limit`, `switching tab keeps the period`.
- [ ] **Step 5: Checkpoint:** `feat(logs): habit tabs and all-habits view`

**Milestone M4 reached.**

---

## Phase 5: States and launch polish (milestone M5)

### Task 5.1: Ring and dashboard states

**Files:** Modify `ring_card.dart`, `stage_pill.dart`, `habit_dashboard.dart`; Create `quit_reached_card.dart`; Test `ring_card_test.dart`

**Interfaces:** over limit → coral badge, "2 over limit", note "A harder day. Tomorrow starts fresh at {nextLimit}, and your streak picks up again from there."; first day → "No sessions logged today. Nice start." and dashed "Today's triggers show here once you log."; quit reached → full success ring, "{n} days vape-free", card "You reached your quit date" with "Keep at zero" (sets `quitAcknowledgedAt`) and "New goal" (Edit plan).
- [ ] **Steps 1–4:** one test per state with the exact copy above.
- [ ] **Step 5: Checkpoint:** `feat(home): over, first-day and quit states`

### Task 5.2: Light mode, Reduce Transparency, accessibility

**Files:** new widgets from Phases 2–4 as needed; Test `test/features/home/accessibility_test.dart`

**Interfaces:** every new surface reads colours from `ColorScheme`/`ExhaleColors`; glass falls back to solid with Reduce Transparency; `meetsGuideline(androidTapTargetGuideline)` and `textContrastGuideline` pass on Home, Logs and both sheets.
- [ ] **Steps 1–4:** guideline tests on Home (dark and light) and Logs; simulator pass in light mode with both accents.
- [ ] **Step 5: Checkpoint:** `fix(ui): light mode and accessibility for new screens`

### Task 5.3: Release blockers and device QA

**Files:** Modify `settings_page.dart` (remove Design system link), `setup_chrome.dart` captions to match Settings; Delete `lib/features/design_system/` and its route
- [ ] **Step 1:** remove the link and route; update tests that referenced them.
- [ ] **Step 2:** run the full checks.
- [ ] **Step 3:** real-iPhone pass using the roadmap's M5 checklist; record results in the PR.
- [ ] **Step 4: Checkpoint:** `chore: release blockers for launch`

**Milestone M5 reached: release candidate.**
