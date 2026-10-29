# Onboarding Redesign and Pace Guide Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the habit picker and setup page with a six-step chat-style
onboarding, add the `emphasis` colour role, store wake and bed times, and show
a pace guide under the ring on Home.

**Architecture:** One `/onboarding` route hosts a `PageView` of step widgets
that read and write a single autoDispose form notifier
(`onboardingFormProvider`). Settings gain `wakeMinute` / `bedMinute`
(schema v9). A pure `PaceGuide.compute` feeds a `PaceLine` on the dashboard.
Edit plan keeps the old cost, projection and quit-date widgets, moved into
the plan feature.

**Tech Stack:** Flutter 3.47.2 / Dart 3.13 via `fvm`, Riverpod 3
(hand-written providers), drift, go_router, get_it.

**Spec:** `docs/superpowers/specs/2026-10-29-onboarding-redesign-design.md`
(read it with this plan). Mockups: `design/7._onboarding/flows.html`, Flow A
black (light) and Flow A app accent dark (dark).

## Global Constraints

- Toolchain: `fvm flutter` / `fvm dart` only. Codegen after table changes:
  `fvm dart run build_runner build -d`.
- Checks (ask Fawad before each, one command per call): `fvm dart format .`,
  `fvm flutter analyze --fatal-infos`, `fvm flutter test <path>`.
- Commits: Conventional Commits (`.githooks/commit-msg`), no Co-Authored-By
  trailers. Claude may commit on `feat/onboarding-redesign`; push only when
  asked.
- iOS look: icons via `AppIcons`, sheets via `showAppSheet` /
  `showAppDraggableSheet`, `showWheelPicker`, `showAppSnackBar`, no ink
  ripples, haptics on selection and primary buttons.
- No `intl`. English only. No teaching comments.
- Every line of onboarding copy lives in `OnboardingCopy` (spec §7, exact
  strings from §4 and §7).
- Defaults are filled in: Continue works on every step without typing,
  except a custom habit with an empty name or unit.
- Sleep times feed only the pace guide. `dayResetHour` (default 4) is not
  touched by onboarding.
- Plans start today. No name, start date or "Your why" in onboarding.
- Reduce Motion (`MediaQuery.disableAnimationsOf`) shows every animated
  end state at once.
- Light emphasis `#111418` with white text; dark emphasis
  `primaryContainer` with `onPrimaryContainer`.
- Suggested quit date: `startLimit × 7` days, clamped to 14–90.
- Minimum waking window: 4 h (240 min). Wheel minutes in 15-minute steps.
  Defaults: wake 7:30 AM (450), bed 11:30 PM (1410).
- Onboarding is done when an active habit exists (no new flag).

## Review Focus

1. **Going back after the Cost step disappears.** Pick smoking, reach Your
   day, go back to Habit, switch to social media, then go forward: the
   stepper reads `n/5` and back from Your day lands on Daily amount. No
   blank or stale Cost page. Test in Task 3.4.
2. **A bedtime after midnight.** Wake 7:30 AM, bed 1:00 AM is a 17.5 h
   window, not negative. Wake 11:00 PM, bed 2:00 AM (3 h) is rejected. A
   bedtime after the reset hour is cut at the reset. Tests in Tasks 2.1
   (`awakeMinutes`), 3.5 and 4.1.
3. **The biggest daily amount.** At `PlanValidation.maxStartLimit` (80) the
   dots grid draws at most 12 dots with "Each dot is 7 {units}", the ruler
   stops at 80, and The deal shows a 90-day plan. Tests in Tasks 3.1 and
   3.3.
4. **A failed save, then a retry.** After a storage error, a second
   **Shake on it** saves exactly one habit and lands on Home. A fast double
   tap also saves one. Test in Task 3.6.
5. **A device locale with no region.** `countryCode` null or unknown gives
   `$`; a euro country gives `€`. Test in Task 2.2.

## File map

Create:
- `lib/core/theme/app_palette.dart`: add `ink` (modify).
- `lib/features/settings/domain/entities/currency_choices.dart`
- `lib/features/settings/domain/entities/day_window.dart`
- `lib/features/settings/presentation/widgets/day_window_picker.dart`:
  arc, two tiles, inline wheel (used by Your day, the Your day sheet and
  Settings).
- `lib/features/settings/presentation/widgets/your_day_sheet.dart`
- `lib/features/onboarding/presentation/onboarding_copy.dart`
- `lib/features/onboarding/presentation/providers/onboarding_form_provider.dart`
  (started as a copy of `setup_form_provider.dart`, which stays for the old
  pages until Task 3.7 deletes both).
- `lib/features/onboarding/presentation/pages/onboarding_page.dart`
- `lib/features/onboarding/presentation/steps/{welcome,habit,amount,cost,day,deal}_step.dart`
- `lib/features/onboarding/presentation/widgets/{onboarding_stepper,exhale_bubble,you_bubble,typing_dots,dots_grid,amount_ruler,currency_chip,taper_chart}.dart`
- `lib/features/home/domain/pace_guide.dart`
- `lib/features/home/presentation/widgets/pace_line.dart`

Move (`git mv`, imports updated, class names kept):
- `onboarding/presentation/widgets/{cost_card,projection_card,quit_date_card,setup_chrome}.dart`
  → `plan/presentation/widgets/`. Only `edit_plan_page.dart` uses them.

Delete: `onboarding/presentation/pages/{setup_page,habit_picker_page}.dart`,
`onboarding/presentation/providers/setup_form_provider.dart` and their
tests.

Spec deviation: §5.3 says to remove `cost_card`, `projection_card`,
`quit_date_card` and `setup_chrome`, but Edit plan uses all four, so they
move to the plan feature instead. `drifting_particles.dart` stays (`splash_scene.dart` uses
it).

---

## Phase O1: Emphasis role

### Task 1.1: `emphasis` / `onEmphasis` and primary buttons

**Files:**
- Modify: `lib/core/theme/app_palette.dart`, `lib/core/theme/exhale_colors.dart`,
  `lib/core/theme/app_theme.dart` (`filledButtonTheme`, lines 80–89),
  `lib/core/widgets/glow_button.dart`, `lib/core/widgets/app_dialogs.dart:100`
  (confirm button tint), `lib/app/shell/app_shell.dart` (`_LogButton` tint
  and icon colour, about line 233)
- Test: `test/core/theme/exhale_colors_test.dart` (new)

**Interfaces:**
- Produces: `AppPalette.ink` (`Color(0xFF111418)`);
  `ExhaleColors.emphasis` and `ExhaleColors.onEmphasis` (`Color`), in the
  constructor, `fromScheme`, `copyWith` and `lerp`. Read as
  `context.exhale.emphasis`.

- [ ] **Step 1: Write the failing tests**

```dart
test('light emphasis is ink with white text', () {
  final c = ExhaleColors.fromScheme(buildColorScheme(brightness: Brightness.light));
  expect(c.emphasis, const Color(0xFF111418));
  expect(c.onEmphasis, Colors.white);
});
test('dark emphasis is the accent', () {
  final s = buildColorScheme(brightness: Brightness.dark);
  final c = ExhaleColors.fromScheme(s);
  expect(c.emphasis, s.primaryContainer);
  expect(c.onEmphasis, s.onPrimaryContainer);
});
test('lerp blends emphasis', () { /* light.lerp(dark, 1).emphasis == dark.emphasis */ });
testWidgets('filled buttons use emphasis in light and dark', (tester) async {
  // pump a FilledButton under AppTheme.light, then AppTheme.dark; the
  // resolved backgroundColor equals theme.extension<ExhaleColors>()!.emphasis
  // and foregroundColor equals onEmphasis.
});
```

- [ ] **Step 2: Run** `fvm flutter test test/core/theme/exhale_colors_test.dart`.
  Expected: FAIL (`emphasis` not defined).

- [ ] **Step 3: Implement.** Add the role to `ExhaleColors`. In
  `app_theme.dart` the filled button background and foreground come from the
  `ExhaleColors` the theme registers. `GlowButton`: spinner in
  `onEmphasis`; the `accentGlow` halo shows only in dark mode (an accent halo
  around an ink pill is off-design). `showAppConfirm` confirm tint and the
  Home + button (`_LogButton`) tint use `emphasis`, its icon `onEmphasis`.
  Selected chips, cards, the ring, charts and the tab bar's selected
  indicator keep `primaryContainer`.

- [ ] **Step 4: Run** the test file again. Expected: PASS. Then ask to run
  `fvm flutter test`; existing asserts on the + button or confirm colours
  move to `emphasis`.

- [ ] **Step 5: Commit** `feat(theme): add the emphasis colour role for primary actions`

**Milestone O1 review:** Opus 5.5 high, read-only. Check every
`primaryContainer` use under `lib/` is state, not a primary action.

---

## Phase O2: Data

### Task 2.1: Schema v9, wake and bed times

**Files:**
- Modify: `lib/core/data/local/database/tables/settings_table.dart`,
  `lib/core/data/local/database/app_database.dart` (`schemaVersion` 9,
  `onUpgrade`), `lib/features/settings/domain/entities/app_settings.dart`,
  `lib/features/settings/data/models/settings_model.dart`,
  `lib/features/settings/domain/validation/settings_validation.dart`
- Create: `lib/features/settings/domain/entities/day_window.dart`
- Generated: `app_database.g.dart` (build_runner)
- Test: `test/core/data/app_database_migration_test.dart`,
  `test/features/settings/data/local_settings_repository_test.dart`,
  `test/features/settings/domain/day_window_test.dart` (new)

**Interfaces:**
- Produces:
  - Columns `wakeMinute => integer().named('wake_minute').nullable()()`,
    `bedMinute => integer().named('bed_minute').nullable()()`.
  - `AppSettings.wakeMinute`, `AppSettings.bedMinute` (`int?`, default
    null), in `copyWith` as `int? Function()?`, `==`, `hashCode`, both
    mappers. `AppSettings.dayWindow` → `DayWindow?` (null unless both set).
  - `class DayWindow { const DayWindow({required int wakeMinute, required int bedMinute}); static const defaultWake = 450; static const defaultBed = 1410; static const minAwakeMinutes = 240; int get awakeMinutes; bool get isValid; }`
    `awakeMinutes = (bed − wake) mod 1440` (bed equal to wake is 0).
  - `SettingsValidation.validate` rejects a minute outside 0–1439
    ("Times must be within the day.") and a set window under 4 h ("Your day
    must be at least 4 hours.").

- [ ] **Step 1: Write the failing tests**
  - `day_window_test.dart`: `awakeMinutes` 7:30→23:30 is 960; 7:30→1:00 is
    1050; 23:00→2:00 is 180 and `isValid` false; 450→450 is 0, invalid.
  - Fixture first, before touching the table: create
    `test/fixtures/exhale_v8.sqlite` from today's v8 code (a throwaway
    script in the scratchpad that opens `AppDatabase` on a file, saves
    settings with `currencySymbol 'AED'` and starts one smoking habit with a
    plan). Load it the way the "a real v7 database" test loads
    `exhale_v7.sqlite`.
  - Migration test: rename `_expectV8` to `_expectLatest`, assert
    `user_version` 9 and `settings` columns contain `wake_minute` and
    `bed_minute`. New group `upgrade from v8` on the fixture: ends on v9,
    keeps `AED`, the habit and its plan; `wake_minute` and `bed_minute` are
    null. Existing v3–v7 groups keep passing (they reach v9 through the v8
    rebuild).
  - Repository test: saving `wakeMinute: 420, bedMinute: 60` reads back
    the same; default settings read back null for both.

- [ ] **Step 2: Run** the three test files. Expected: FAIL.

- [ ] **Step 3: Implement.** Bump to v9 and add the columns. In
  `onUpgrade`, add the columns only when `from == 8`
  (`if (from >= 8 && from < 9)` with `migrator.addColumn(settings,
  settings.wakeMinute)` and `bedMinute`): an older database reaches v9
  through `_moveHabitsToTheirOwnTable`, whose `alterTable(settings)` already
  rebuilds `settings` with the new columns, so adding them again would
  fail. Run `fvm dart run build_runner build -d` (ask first).

- [ ] **Step 4: Run** the three test files. Expected: PASS.

- [ ] **Step 5: Commit** `feat(settings): store wake and bed times (schema v9)`

### Task 2.2: `CurrencyChoices`

**Files:**
- Create: `lib/features/settings/domain/entities/currency_choices.dart`
- Modify: `lib/features/settings/presentation/providers/settings_providers.dart`
- Test: `test/features/settings/domain/currency_choices_test.dart`

**Interfaces:**
- Produces:
  - `class CurrencyChoice { const CurrencyChoice(this.symbol, this.regions); final String symbol; final Set<String> regions; }`
  - `abstract final class CurrencyChoices { static const List<CurrencyChoice> all; static String forRegion(String? region); }`
    About 25 entries; must include `AED {AE}`, `SAR {SA}`, `£ {GB}`,
    `€` (all euro-area ISO codes), `$ {US}`, `Rs {PK}`, `₹ {IN}`. `$` is
    first and is the fallback. Region match is case-insensitive.
  - `final deviceRegionProvider = Provider<String?>((ref) => PlatformDispatcher.instance.locale.countryCode);`
    (overridden in tests).

- [ ] **Step 1: Write the failing tests:** `forRegion('AE') == 'AED'`,
  `forRegion('de') == '€'`, `forRegion('PK') == 'Rs'`,
  `forRegion(null) == r'$'`, `forRegion('ZZ') == r'$'`; every symbol in
  `all` is unique; no region appears twice.
- [ ] **Step 2: Run** the test. Expected: FAIL.
- [ ] **Step 3: Implement** the list and the provider.
- [ ] **Step 4: Run** the test. Expected: PASS.
- [ ] **Step 5: Commit** `feat(settings): add currency choices with a locale default`

### Task 2.3: Clamp the suggested quit date

**Files:**
- Modify: `lib/features/plan/domain/entities/reduction_plan.dart:31-33`
- Test: `test/features/plan/domain/entities/reduction_plan_test.dart:185-189`

**Interfaces:**
- Produces: `ReductionPlan.suggestedQuitDay(startDay, startLimit)` =
  `startDay.addDays((startLimit * 7).clamp(14, 90))`; constants
  `minSuggestedDays = 14`, `maxSuggestedDays = 90`. Edit plan's Suggested
  chip picks it up unchanged.

- [ ] **Step 1: Update the test:** limit 9 → 63 days; limit 1 → 14; limit 2
  → 14; limit 13 → 90; limit 80 → 90.
- [ ] **Step 2: Run** it. Expected: FAIL on limits 1, 2, 13, 80.
- [ ] **Step 3: Implement.** Update the doc comment.
- [ ] **Step 4: Run** it, then ask to run
  `fvm flutter test test/features/plan` and
  `fvm flutter test test/features/onboarding` (setup tests that assume the
  old suggestion may need their expected dates updated).
- [ ] **Step 5: Commit** `feat(plan): clamp the suggested quit date to 14-90 days`

**Milestone O2 review:** Opus 5.5 high. Focus: the migration from every
version (v3–v8 and fresh) ends on v9 with the same columns.

---

## Phase O3: Onboarding flow

### Task 3.1: Form provider and copy

**Files:**
- Create: `providers/onboarding_form_provider.dart` (copied from
  `setup_form_provider.dart`, then changed; the original stays until 3.7),
  `lib/features/onboarding/presentation/onboarding_copy.dart`
- Test: `test/features/onboarding/onboarding_form_controller_test.dart`
  (copied from `setup_form_controller_test.dart`, then changed)

**Interfaces:**
- Consumes: `CurrencyChoices.forRegion`, `deviceRegionProvider` (2.2);
  `DayWindow` (2.1); `ReductionPlan.suggestedQuitDay` (2.3).
- Produces:
  - `enum OnboardingStep { welcome, habit, amount, cost, day, deal }`
  - `QuitPreset` order: `suggested, weeks4, weeks8, months3` (chips show
    them in this order, then Pick).
  - `OnboardingFormState` (was `SetupFormState`): drops `name`, `reason`,
    `startDay` stays (always today, no setter). Adds
    `int wakeMinute` (default `DayWindow.defaultWake`), `int bedMinute`
    (default `DayWindow.defaultBed`), `String currency`.
    Getters: `List<OnboardingStep> steps` (no `cost` when
    `!habit.tracksCost`); `int get total => steps.length`;
    `String stepLabel(OnboardingStep s)` → `'${steps.indexOf(s) + 1}/$total'`;
    `int get dotUnit` (1 up to 12, else `(startLimit / 12).ceil()`);
    `int get dotCount` (`(startLimit / dotUnit).ceil()`);
    `int? get monthlyCostCents` / `yearlyCostCents`
    (`(unitPriceCents! * startLimit * 30).round()` / `* 365`; null without a
    price); `int get tomorrowLimit` (the preview plan's limit for
    `startDay.addDays(1)`); `int get paceMinutes`
    (`max(1, (DayWindow(...).awakeMinutes / startLimit).round())`).
  - `OnboardingFormController` (was `SetupFormController`): keeps
    `selectHabit`, `setCustomName`, `setCustomUnit`, `setStartLimit`,
    `selectQuitPreset`, `setQuitDay`, `setPriceText`,
    `setUnitsPerContainer`, `earliestQuitDay`; removes `setName`,
    `setReason`, `setStartDay`; adds `setCurrency(String)`,
    `skipPrice()` (clears `priceText` and the error),
    `setDayWindow({required int wakeMinute, required int bedMinute})`
    (ignored when the window is under 4 h), `Future<bool> submit()`.
  - `final onboardingFormProvider = NotifierProvider.autoDispose(OnboardingFormController.new);`
  - `abstract final class OnboardingCopy`: static strings for every line in
    spec §4 and §7, plus `static String habitReply(HabitKind kind)` and
    `static String amountReaction({required int amount, required int typical})`
    (`amount / typical`: `< 0.5` hobby, `<= 1` respectable, `<= 2`
    part-time job, above that full-time job).

- [ ] **Step 1: Write the failing tests** (`ProviderContainer` with
  `todayProvider` and `deviceRegionProvider` overridden, as the setup test
  does today):
  - defaults: vaping, its `defaultDailyAmount`, `quitPreset` suggested,
    wake 450, bed 1410, `currency` from region `'AE'` is `'AED'`.
  - `steps` has six entries for smoking and five for social media;
    `stepLabel(OnboardingStep.day)` is `'5/6'` for smoking and `'4/5'` for
    social media.
  - dots: amount 12 → `dotUnit` 1, `dotCount` 12; 13 → 2 and 7; 80 → 7 and
    12.
  - costs: smoking, price `'14.50'`, 20 per pack, 10 a day →
    `monthlyCostCents` 21750, `yearlyCostCents` 264625; `skipPrice()` → both
    null and `hasInvalidPrice` false.
  - `setDayWindow(wakeMinute: 1380, bedMinute: 120)` leaves the window
    unchanged; `(420, 60)` is stored.
  - `paceMinutes` 960 min / 12 → 80; amount 80 at 960 → 12.
  - `OnboardingCopy.amountReaction`: (2, 5) hobby, (5, 5) respectable,
    (10, 5) part-time, (11, 5) full-time. `habitReply` has a line for every
    `HabitKind`.
  - existing submit tests kept: saves settings, then habit and plan; a
    second submit does not add a second habit; a failing save keeps every
    answer and sets `errorMessage`. Submit now also stores `wakeMinute`,
    `bedMinute` and `currencySymbol`, and no longer touches `userName`.
- [ ] **Step 2: Run** `fvm flutter test test/features/onboarding/onboarding_form_controller_test.dart`.
  Expected: FAIL.
- [ ] **Step 3: Implement.** Keep the submit order (spec §5.4); settings
  update uses `copyWith(wakeMinute: () => …, bedMinute: () => …, currencySymbol: …)`.
  The old pages keep using `setupFormProvider` untouched.
- [ ] **Step 4: Run** the test. Expected: PASS.
- [ ] **Step 5: Commit** `feat(onboarding): onboarding form state and copy`

### Task 3.2: Onboarding page, stepper, bubbles and Welcome

**Files:**
- Create: `pages/onboarding_page.dart`, `steps/welcome_step.dart`,
  `widgets/onboarding_stepper.dart`, `widgets/exhale_bubble.dart`,
  `widgets/you_bubble.dart`, `widgets/typing_dots.dart`
- Modify: `lib/app/router/app_routes.dart` (`onboarding = '/onboarding'`),
  `lib/app/router/app_router.dart` (add the route; `/setup` stays until
  3.7)
- Test: `test/features/onboarding/onboarding_page_test.dart`,
  `test/features/onboarding/welcome_step_test.dart`

**Interfaces:**
- Consumes: `onboardingFormProvider`, `OnboardingStep`, `OnboardingCopy`.
- Produces:
  - `OnboardingPage` (ConsumerStatefulWidget) owns a `PageController`;
    pages are `state.steps` mapped to step widgets; `NeverScrollableScrollPhysics`
    forward, swipe right and the back chevron go back one page.
    Steps advance through `OnboardingScope.of(context).next()` /
    `.back()` (an `InheritedWidget` in `onboarding_page.dart`), so steps
    never hold the controller. When `steps` changes (Cost added or
    removed), the page keeps the current step by identity, not index.
  - `OnboardingStepper({required int index, required int total, VoidCallback? onBack})`:
    `total` thin segments, filled up to `index` in `emphasis`, the rest
    `inset`; back chevron (`AppIcons.back`) only when `onBack` is non-null;
    label `'${index + 1}/$total'`.
  - `ExhaleBubble({required String text, bool showAvatar = true})`
    (bubble and avatar in `emphasis` / `onEmphasis`, avatar glyph in the
    accent); `YouBubble({required String text})` (sent style, right
    aligned); `TypingDots({bool animate = true})` (three dots, `emphasis`).
  - `WelcomeStep`: the exact copy of spec §4.1; bubbles 400 ms apart, then
    typing dots, the reply, then the headline slides up. A tap anywhere
    jumps to the end state; Reduce Motion starts there. Button
    `GlowButton(label: 'Make a plan')` calls `next()`.

- [ ] **Step 1: Write the failing tests**
  - `welcome_step_test`: after the animation all three excuses, both
    replies, the headline, body, **Make a plan** and the fine print show;
    one tap right after pump shows the headline without waiting; with
    `disableAnimations` it shows at once; no back chevron; label `'1/6'`.
  - `onboarding_page_test`: **Make a plan** → `'2/6'` and "What are we
    quitting?"; back chevron → Welcome; a right swipe on step 2 → Welcome.
- [ ] **Step 2: Run** both files. Expected: FAIL.
- [ ] **Step 3: Implement.** Steps not built yet render a private
  `_PendingStep` with only a Continue that calls `next()`; each later task
  replaces its case, and Task 3.6 deletes `_PendingStep`.
- [ ] **Step 4: Run** both files. Expected: PASS.
- [ ] **Step 5: Commit** `feat(onboarding): onboarding page, stepper and welcome step`

### Task 3.3: Habit and Daily amount steps

**Files:**
- Create: `steps/habit_step.dart`, `steps/amount_step.dart`,
  `widgets/dots_grid.dart`, `widgets/amount_ruler.dart`
- Test: `test/features/onboarding/habit_step_test.dart`,
  `test/features/onboarding/amount_step_test.dart`

**Interfaces:**
- Consumes: `OnboardingFormController.selectHabit/setCustomName/setCustomUnit/setStartLimit`,
  `OnboardingFormState.canContinue/dotUnit/dotCount`, `OnboardingCopy.habitReply/amountReaction`.
- Produces:
  - `HabitStep`: 2-column grid of `Habit.presets` (icon + name), selected
    card in the accent with a check; **Something else** full width, dashed,
    expands name and unit fields in place; the reply bubble under the
    question updates per pick. Continue disabled while `!canContinue`.
  - `DotsGrid({required int count, required int unit, required String units})`:
    `count` dots in `emphasis`; caption `'Each dot is $unit $units'` only
    when `unit > 1`.
  - `AmountRuler({required int value, required int min, required int max, required ValueChanged<int> onChanged})`:
    horizontal drag, one tick per unit, `HapticFeedback.selectionClick` per
    change.
  - `AmountStep`: big number with − / + (`NumberStepper` if it fits the
    design, else two icon buttons), ruler, dots grid, reaction bubble; title
    `'How many ${habit.units} on a normal day?'`.

- [ ] **Step 1: Write the failing tests**
  - Habit: vaping is selected by default; tapping Smoking shows "Classic.
    Retro, even."; **Something else** shows two fields and Continue is
    disabled until both have text; Continue goes to `'3/6'`.
  - Amount: smoking starts at 9 with "Respectable. For now."; + makes 10
    and shows "That's not a habit. That's a part-time job."; set to 4 shows
    "Practically a hobby."; − at 1 stays 1; dragging the ruler right raises
    the number; at 80 there are 12 dots and "Each dot is 7 cigarettes"; +
    at 80 stays 80.
- [ ] **Step 2: Run** both files. Expected: FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run** both files. Expected: PASS.
- [ ] **Step 5: Commit** `feat(onboarding): habit and daily amount steps`

### Task 3.4: Cost step

**Files:**
- Create: `steps/cost_step.dart`, `widgets/currency_chip.dart`
- Test: `test/features/onboarding/cost_step_test.dart`

**Interfaces:**
- Consumes: `setPriceText`, `setUnitsPerContainer`, `setCurrency`,
  `skipPrice`, `monthlyCostCents`, `yearlyCostCents`, `hasInvalidPrice`;
  `CurrencyChoices.all`; `AppFormat.money`.
- Produces:
  - `CurrencyChip({required String symbol, required ValueChanged<String> onChanged})`:
    tap opens a Cupertino wheel of `CurrencyChoices.all` in `showAppSheet`.
  - `CostStep`: title `'What does a ${habit.container} cost?'`, or
    `'What does one ${habit.unit} cost?'` without a container; decimal pad
    amount field; units-per-container stepper and its hint only with a
    container; tiles "A month" / "A year" (year in
    `exhale.warning.foreground`) and the reply "Your rent is jealous.",
    shown once a valid price exists; **I'd rather not know** calls `skipPrice()` then `next()`. Continue with
    an invalid price shows "Enter a valid price, or leave it empty." and
    stays.

- [ ] **Step 1: Write the failing tests**
  - Smoking, price 14.50, 20 per pack, 10 a day, currency `£`: tiles show
    the month and year totals formatted by `AppFormat.money` with `£`.
  - Alcohol (container `bottle`) shows the stepper and "What does a bottle
    cost?"; a cost-tracking preset without a container (pick it from
    `Habit.presets`) shows "What does one {its unit} cost?" and no stepper.
  - `abc` + Continue → the error message, still on Cost.
  - `abc` + **I'd rather not know** → Your day, price cleared.
  - Review Focus 1: smoking to Your day, back to Habit, pick Social media,
    Continue, Continue → `'4/5'` on Your day; back → Daily amount.
- [ ] **Step 2: Run** it. Expected: FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run** it. Expected: PASS.
- [ ] **Step 5: Commit** `feat(onboarding): cost step with currency chip`

### Task 3.5: Your day step and `DayWindowPicker`

**Files:**
- Create: `lib/features/settings/presentation/widgets/day_window_picker.dart`,
  `lib/features/onboarding/presentation/steps/day_step.dart`
- Test: `test/features/settings/day_window_picker_test.dart`,
  `test/features/onboarding/day_step_test.dart`

**Interfaces:**
- Consumes: `DayWindow` (2.1), `setDayWindow` (3.1), `AppFormat.time`.
- Produces:
  - `DayWindowPicker({required DayWindow window, required ValueChanged<DayWindow> onChanged})`:
    arc with dots along it and `'16 h awake'` in the middle (`'17 h 30 min
    awake'` when the minutes are not whole), Wake up / Bedtime
    tiles, the selected tile opens an inline `CupertinoDatePicker`
    (`mode: time`, `minuteInterval: 15`). A change that makes the window
    under 4 h snaps the wheel back to the last valid value and is not
    reported.
  - `DayStep`: Exhale line, title, the picker, note "Used to pace your
    limit. Never to lock you out.", Continue.

- [ ] **Step 1: Write the failing tests**
  - Picker: defaults show 7:30 AM, 11:30 PM, "16 h awake"; setting bedtime
    to 1:00 AM reports 60 and shows "17 h 30 min awake"; wake 11:00 PM with
    bed 2:00 AM is not reported and the tile keeps its old time.
  - Step: Continue with defaults goes to The deal; the form holds 450 and
    1410.
- [ ] **Step 2: Run** both files. Expected: FAIL.
- [ ] **Step 3: Implement.** Drive the wheel in tests through
  `tester.drag` on the `CupertinoDatePicker` columns or by calling
  `onDateTimeChanged` found via `tester.widget`.
- [ ] **Step 4: Run** both files. Expected: PASS.
- [ ] **Step 5: Commit** `feat(onboarding): your day step with the day window picker`

### Task 3.6: The deal step and saving

**Files:**
- Create: `steps/deal_step.dart`, `widgets/taper_chart.dart`
- Test: `test/features/onboarding/deal_step_test.dart`

**Interfaces:**
- Consumes: `preview`, `quitDay`, `quitPreset`, `selectQuitPreset`,
  `setQuitDay`, `earliestQuitDay`, `isSteep`, `tomorrowLimit`,
  `yearlyCostCents`, `paceMinutes`, `submit`, `isSubmitting`,
  `errorMessage`; `showWheelPicker`; `AppFormat.monthDay`.
- Produces:
  - `TaperChart({required ReductionPlan plan})`: the limit per day from
    start to quit as a line in the accent, today and quit-day date labels.
  - `DealStep`: title `'$startLimit today. Zero by ${AppFormat.monthDay(quitDay)}.'`;
    chips Suggested, 4 weeks, 8 weeks, 3 months, Pick (wheel date picker
    from `earliestQuitDay`); steep warning with the existing copy "That's
    more than one fewer a day. A later date may feel easier."; stats
    Tomorrow / Quit in (`'${plan.totalDays} days'`) / Back a year (hidden
    without a price); pace line `'Today that's about one every
    ${paceMinutes} min. It gets slower from here.'`; **Shake on it**
    (`GlowButton`, `isBusy: isSubmitting`); error text under the button;
    fine print. On `submit() == true`: `context.go(AppRoutes.home)`.

- [ ] **Step 1: Write the failing tests** (full app via
  `pumpAppPastSplash`, walking the steps with defaults, smoking):
  - title reads "9 today. Zero by {63 days from today}." and Suggested is
    selected; 4 weeks moves the date to 28 days; Pick then a date updates
    the title.
  - without a price "Back a year" is absent; with 14.50 it shows.
  - **Shake on it** lands on Home with a smoking habit, a plan from today
    with limit 9, settings with wake 450, bed 1410 and the chosen currency.
  - Review Focus 4: with the habit repository throwing once
    (`guardStorage` failure through a fake `HabitRepository` override), the
    error shows under the button and every answer is kept; the second tap
    lands on Home and `getActive()` returns exactly one habit. Two quick
    taps (`tap` twice before `pump`) also save one habit.
  - Review Focus 3: amount 80 → Suggested is 90 days.
- [ ] **Step 2: Run** it. Expected: FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run** it. Expected: PASS.
- [ ] **Step 5: Commit** `feat(onboarding): the deal step saves the plan`

### Task 3.7: Splash hand-off and old setup removed

**Files:**
- Modify: `lib/features/onboarding/presentation/pages/splash_page.dart`,
  `lib/features/onboarding/presentation/widgets/splash_scene.dart`,
  `lib/app/router/app_router.dart`, `lib/app/router/app_routes.dart`
  (remove `setup`, `setupPlan`), `lib/features/plan/presentation/pages/edit_plan_page.dart`
  (imports), `lib/features/habit/domain/validation/habit_validation.dart`
  (`maxReasonLength = 80`, moved from `HabitPickerPage`), `test/helpers/pump_app.dart`
  (remove `pumpToPlanStep`; add `pumpToOnboardingStep(OnboardingStep step)`
  if two or more tests need it)
- Move: the four widgets in the file map to `lib/features/plan/presentation/widgets/`
- Delete: `setup_page.dart`, `habit_picker_page.dart`,
  `setup_form_provider.dart`,
  `test/features/onboarding/setup_page_test.dart`,
  `test/features/onboarding/habit_picker_page_test.dart`,
  `test/features/onboarding/setup_form_controller_test.dart`
- Test: `test/features/onboarding/splash_page_test.dart`,
  `test/app/app_test.dart` ("first launch goes from splash to setup to
  home" becomes "first launch goes from splash through onboarding to home")

**Interfaces:**
- Produces: `SplashPage.firstLaunchDuration = Duration(milliseconds: 1200)`;
  `SplashScene({…, bool talking = false})` shows "We need to talk." and
  `TypingDots` (pulse once) under the wordmark when `talking`. `/onboarding`
  uses a `CustomTransitionPage` sliding in from the right.

- [ ] **Step 1: Migrate the failing tests**
  - Splash: with no habit, once the destination resolves the scene shows
    "We need to talk.", and after `firstLaunchDuration` the app is on
    Welcome (`'1/6'`); with a habit, today's intro + hold then Home (as
    today); a tap on first launch does not postpone leaving; Reduce Motion
    skips the dots.
  - App test: splash → onboarding with defaults → Home shows the vaping
    dashboard.
  - Edit plan tests keep passing with the moved widgets (no edits beyond
    imports).
- [ ] **Step 2: Run** the splash and app tests. Expected: FAIL.
- [ ] **Step 3: Implement.** First launch waits for the destination; it
  does not replay the long intro. Delete the old pages and tests, move the
  widgets, fix imports. Search `lib/` and `test/` for `AppRoutes.setup`,
  `HabitPickerPage`, `SetupPage`, `setupFormProvider` and
  `pumpToPlanStep`: none left.
- [ ] **Step 4: Run** the splash and app tests, then ask to run
  `fvm dart format .`, `fvm flutter analyze --fatal-infos` and
  `fvm flutter test` (one at a time).
- [ ] **Step 5: Commit** `feat(onboarding): route first launch through the new onboarding`

**Milestone O3 review:** Opus 5.5 high. Walk the flow against
`design/7._onboarding/flows.html` in light and dark on a simulator (ask
first). Check the copy against spec §4 and §7 word for word.

---

## Phase O4: Pace guide

### Task 4.1: `PaceGuide.compute`

**Files:**
- Create: `lib/features/home/domain/pace_guide.dart`
- Test: `test/features/home/domain/pace_guide_test.dart`

**Interfaces:**
- Consumes: `DayWindow`, `DayBoundary`, `LogicalDay`.
- Produces:
  ```dart
  @immutable
  class PaceGuide {
    const PaceGuide({required this.next, required this.pace});
    final DateTime next;
    final Duration pace;
    static PaceGuide? compute({
      required DateTime now,
      required LogicalDay day,
      required DayBoundary boundary,
      required DayWindow window,
      required int limit,
      required int countToday,
      DateTime? lastLogToday,
    });
  }
  ```
  Window: wake is `day`'s calendar date at `wakeMinute`, but never before
  `boundary.startOf(day)`; bed is the first `bedMinute` after wake, cut to
  `boundary.endOf(day)`. Null when
  `limit <= 0`, `countToday >= limit`, `now` is before wake or not before
  bed. `pace = (bed − max(now, wake)) / (limit − countToday)`;
  `next = max(lastLogToday ?? wake, wake) + pace`.

- [ ] **Step 1: Write the failing tests** (day 2026-10-29, reset 4,
  window 7:30–23:30, limit 8):
  - 7:30, no logs → pace 2 h, next 9:30.
  - 12:00, 2 logs, last 11:00 → pace 11.5 h / 6 = 1 h 55 min, next 12:55.
  - 7:00 → null; 23:30 → null; count 8 → null; count 9 → null; limit 0 →
    null.
  - bed 1:00 AM, 23:00, 7 logs → pace 2 h (bed on 30 Oct 1:00), next
    `lastLog + 2 h`.
  - bed 5:00 AM with reset 4 → the window ends at 30 Oct 4:00.
  - Review Focus 2: wake 3:00 with reset 4, limit 6, 4:00, no logs → the
    window starts at 4:00; pace 19.5 h / 6 = 3 h 15 min, next 7:15.
- [ ] **Step 2: Run** it. Expected: FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run** it. Expected: PASS.
- [ ] **Step 5: Commit** `feat(home): pace guide calculation`

### Task 4.2: Pace line, "Set your day" prompt and the Settings row

**Files:**
- Create: `lib/features/home/presentation/widgets/pace_line.dart`,
  `lib/features/settings/presentation/widgets/your_day_sheet.dart`
- Modify: `lib/features/home/presentation/widgets/habit_dashboard.dart`
  (after `RingCard`, line 85), `lib/features/settings/presentation/pages/settings_page.dart`
- Test: `test/features/home/pace_line_test.dart`,
  `test/features/settings/settings_page_test.dart` (add or extend)

**Interfaces:**
- Consumes: `PaceGuide.compute` (4.1), `DayWindowPicker` (3.5),
  `AppSettings.dayWindow` (2.1), `nowProvider`, `todayProvider`,
  `dayBoundaryProvider`, `dayProgressProvider((habitId:, day:))`,
  `latestLogProvider(habitId)` (used only when its logical day is today),
  `settingsActionsProvider`.
- Produces:
  - `PaceLine({required int habitId})`: watches `nowProvider` (minute
    tick). With a guide: line 1 `'Next one on schedule in ${minutes} min'`
    when `next` is after now, else "You're on schedule"; line 2
    `'About one every ${pace.inMinutes} min until bed'`. Without a guide:
    nothing. With `dayWindow == null`: the prompt "Set your day to get a
    pace guide", which opens `showYourDaySheet`. The prompt shows until the
    day is set (only users from before v9 can see it).
  - `Future<void> showYourDaySheet(BuildContext context)`: `showAppSheet`
    with `DayWindowPicker` on the current window (or defaults) and Save,
    which writes both minutes through `settingsActionsProvider.update`.
  - Settings page: a "Your day" row showing `'${wake} – ${bed}'` (or "Not
    set"), opening `showYourDaySheet`.

- [ ] **Step 1: Write the failing tests** (`FixedClock`, a seeded habit,
  `pumpAppPastSplash(height: 2400)`):
  - 9:00, limit 8, one log at 8:00 → "Next one on schedule in" and "About
    one every"; at 12:00 with that same log → "You're on schedule".
  - at the limit → no pace text; quit day (limit 0) → none; 6:00 → none.
  - settings without a window → "Set your day to get a pace guide"; tap,
    Save → the pace line appears and settings hold 450 / 1410.
  - Settings: the "Your day" row shows "Not set", then the saved times.
  - The minute tick: advance the clock past `next` and pump a minute → the
    line flips to "You're on schedule".
- [ ] **Step 2: Run** both files. Expected: FAIL.
- [ ] **Step 3: Implement.** Minutes are `ceil` of the remaining duration
  so "in 0 min" never shows.
- [ ] **Step 4: Run** both files, then ask to run format, analyze and the
  full suite (one at a time).
- [ ] **Step 5: Commit** `feat(home): pace line under the ring and the your day setting`

**Milestone O4 review:** Opus 5.5 high. Then update
`docs/CURRENT_STATE.md` and open the onboarding PR (push only when asked).
