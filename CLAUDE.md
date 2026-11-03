# Exhale

Paid, offline iOS app for cutting a habit down to zero by a quit date. Marketing leads
with vaping; every habit stays in the app. The user sets a starting daily limit and a quit
date, the limit tapers evenly to 0, and each use is one tap (logging is always allowed,
even over the limit). No profile data is collected. Monetization comes later (free core
plus Pro).

This is your project with Fawad (the owner). You know its architecture, decisions and
plan; don't ask him to re-explain them. Read the linked docs when a task touches them.

## Status

Progress and the single next action live in `docs/CURRENT_STATE.md`. Read it first; update
it when a task or milestone finishes. Older session logs are in `docs/history/`.

- Active plan: `docs/superpowers/plans/2026-11-02-plan-and-stages.md` on branch
  `feat/plan-and-stages`. M6 (Plan details, Edit plan, Logs) is done; M7 (stage
  management) is next.
- Specs: `docs/superpowers/specs/` (one per plan). Designs: `design/` (each folder has a
  README).
- Launch scope (Fawad, 2026-10-31): the first release tracks one habit. Never offer a
  second habit in the launch build. Multi-habit Tasks 4.1 to 4.3 are parked, unmerged, on
  `feat/multi-habit`.
- After launch: multiple habits, then time-of-day insights, reminders, widgets and the
  Live Activity, the Pro paywall, habit reordering, export.

## Workflow

This section overrides the global approval rules for this project only.

1. Every feature gets a spec and a task plan in `docs/superpowers/` before code.
2. Run plans with the `execute-plan` skill, one task at a time: failing test, code,
   passing test, commit.
3. After each task, run `fvm dart format .`, `fvm flutter analyze --fatal-infos`, and only
   that task's tests: `fvm flutter test <the task's test files>`.
4. At the end of a milestone:
   - Run the independent review (Opus 5.5 at high), then fix its findings.
   - Run the full suite once:
     `fvm flutter test --reporter failures-only --file-reporter json:build/test-report.json`.
     Report the total and the pass count for each task's test files, read from that JSON.
   - Then, without asking: builds, `fvm flutter run` and the simulator walk.
5. Codegen (`fvm dart run build_runner build -d`) may run any time, without asking. Run it
   after changing drift tables.
6. Still ask Fawad first: dependency changes (`pub get`, `pubspec.yaml`), builds or
   simulator runs in the middle of a milestone, pushing, and anything touching CI.
7. Give Fawad a short summary at each checkpoint, and say when a fresh session is due.

## Git

- You branch and commit (Fawad, 2026-10-31), replacing the global rule about giving
  him the commands. Branches are `feat/<name>` off an up-to-date `main`.
- Conventional Commit messages (`.githooks/commit-msg` enforces them).
- Commit only under Fawad's git identity. Never add Co-Authored-By trailers or any
  Claude attribution, in commits or PRs.
- Push only when he asks, or give him the command. GitHub `main` is protected (PR plus
  the "Analyze & test" check). `gh` is not installed: he opens PRs from a compare link.

## Rules

- Toolchain: only `fvm flutter` / `fvm dart` (Flutter 3.47.2, Dart 3.13). Never
  `gem install`, `fvm global` or Homebrew node.
- No tutorials, teaching comments or learning notes. Keep summaries short. Match the
  surrounding code.
- Model per task: Sonnet 5.5 medium for specified work; Opus 5.5 high for milestone
  reviews and for multi-habit Task 4.4.
- iOS look for every new screen: Cupertino icons via `AppIcons`, glass sheets via
  `showAppSheet` / `showAppDraggableSheet`, `showAppConfirm`, `showWheelPicker`,
  `showAppSnackBar` (the only way to show a snackbar), `GlassSurface` / liquid glass with
  the Reduce Transparency fallback, no ink ripples, haptics. Check light mode, Reduce
  Transparency, 44 pt targets and text up to 200%.
- Don't reverse engineer third-party apps.

## Architecture

- `lib/app`: `app.dart`, `bootstrap.dart` (`startupOverrides()` loads settings before
  `runApp`), `router/` (go_router, `AppRoutes`), `shell/` (floating glass tab bar).
- `lib/core`: `data/local/database` (drift `AppDatabase`, tables, migrations), `di` (get_it
  `sl`, `InjectionContainer.setupDependencies()`), `domain` (`Result`/`Failure`, `Clock`,
  `LogicalDay`, `DayBoundary`), `presentation`, `theme`, `widgets`.
- `lib/features/<feature>/{data,domain,presentation}`, each with a `*_injection.dart`.
  Features: habit, home, logs, onboarding, plan, settings, tracking.
- State: Riverpod 3 with hand-written providers. No riverpod_generator. Providers read
  repositories and use cases from `sl`.
- Storage: drift, fully offline, schema v10 (`habits`; plans and logs keyed by
  `habit_id`; v9 wake and bed times; v10 `habit_prices`). Repositories return `Result`
  and wrap storage calls in `guardStorage`.
- Day logic: a logical day resets at a user-set hour (default 4 AM). Logs between
  midnight and the reset hour belong to the previous day.
- Plan: `ReductionPlan(startDay, startLimit, quitDay)`; the limit on day d is
  `ceil(start × (D − d) / D)`. `PlanHistory.replan` keeps earlier plans so past days keep
  their own limit.
- Habits: `HabitKind` presets (vaping, smoking, nicotinePouches, alcohol, caffeine,
  energyDrinks, junkFood, socialMedia) plus custom. Logs carry an optional trigger (20
  `Trigger` values, 8 per habit) and a note.

## Gotchas

- Riverpod 3 pauses a provider with no listeners, so `ref.read(streamProvider.future)` can
  hang. Read from the repository or `ref.watch` instead.
- Tests: `pumpAppPastSplash(height: 2400)` for Home so the lazy list builds every card;
  `tester.pumpInSteps()` for animations; read drift streams in test bodies through
  `tester.runAsync`. Helpers live in `test/helpers/`.
- Tests: never `await` a go_router `push` (use `unawaited`); run a failing test with
  `--timeout 60s` (a failed assert skips `disposeApp()`); pump past delayed reveals before
  `pumpAndSettle`.
- drift name clashes: `hide isNull, isNotNull` (matcher) and `hide Trigger` (drift).
- Run each check as its own bare command. The global hook rejects chained checks and
  asks on redirects or `$(...)`.
- `stash@{0}` "sim-walk splash hack" always starts onboarding. Apply it only for a
  simulator walk, and revert `splash_page.dart` before tests or commits.
- Simulator (iOS 26): debug builds need `fvm flutter run`, not a plain install. Injected
  taps need about 0.15 s. Fawad sometimes has two booted simulators: pass explicit UDIDs
  to `simctl`.
