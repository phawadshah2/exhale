# Exhale: project context for Claude

You built this app with Fawad (the owner) over many sessions. Treat it as
your own project: you know the architecture, the decisions and the plan
below. Don't ask Fawad to re-explain any of it. Read the linked docs when a
task touches them.

## What it is

Exhale is a paid, offline iOS app for cutting down a habit to zero by a quit
date. Marketing leads with vaping; all habits stay in the app. The user sets a
starting daily limit and a quit date, the limit tapers evenly to 0, and they
log each use with one tap (logging is always allowed, even over the limit).

- Habits: `HabitKind` presets (vaping, smoking, nicotinePouches, alcohol,
  caffeine, energyDrinks, junkFood, socialMedia) plus custom. Each `Habit`
  carries its wording, unit, container, free label and whether it tracks cost.
- Each log has an optional trigger (20 `Trigger` values; each habit shows 8)
  and a note.
- No profile data is collected. Monetization comes later (free core + Pro).

## Working rules (Fawad's preferences)

- **Git:** you create branches and edit files only. Fawad commits and pushes.
  At each checkpoint, give him the git commands in order with a Conventional
  Commit message (`.githooks/commit-msg` enforces it), as set out in his
  global session rhythm. Branches are `feat/<name>` off an up-to-date `main`.
  Never add Co-Authored-By trailers.
- **Model per task:** the global default applies. Use Opus 5.5 (high) for each
  milestone-end independent review and for Task 4.1–4.4 (multi-habit).
- **Toolchain:** only `fvm flutter` / `fvm dart` (Flutter 3.47.2, Dart 3.13).
  Never `gem install`, `fvm global` or Homebrew node.
- **Style:** no tutorials, teaching comments or learning notes. Keep
  summaries short. Match the surrounding code.
- **Checks:** `fvm dart format .`, `fvm flutter analyze --fatal-infos`,
  `fvm flutter test` (the same checks CI runs in
  `.github/workflows/app-ci.yml`). Ask Fawad before running each one, and
  before builds or simulator runs.
- **Codegen:** run `fvm dart run build_runner build -d` after changing drift
  tables.
- **iOS look for every new screen:** Cupertino icons via `AppIcons`, glass
  sheets via `showAppSheet` / `showAppDraggableSheet`, `showAppConfirm`,
  `showWheelPicker`, `showAppSnackBar` (the only way to show a snackbar),
  `GlassSurface` / liquid glass with the Reduce Transparency fallback, no ink
  ripples, haptics.
- Don't reverse engineer third-party apps.

## Architecture

- `lib/app`: `app.dart`, `bootstrap.dart` (`startupOverrides()` loads settings
  before `runApp`), `router/` (go_router, `AppRoutes`), `shell/`
  (floating glass tab bar).
- `lib/core`: `data/local/database` (drift `AppDatabase`, tables, migrations),
  `di` (get_it `sl`, `InjectionContainer.setupDependencies()`), `domain`
  (`Result`/`Failure`, `Clock`, `LogicalDay`, `DayBoundary`), `presentation`,
  `theme`, `widgets`.
- `lib/features/<feature>/{data,domain,presentation}`: clean architecture.
  Each feature has a `*_injection.dart`. Features: habit, home, onboarding,
  plan, settings, tracking, design_system.
- **State:** Riverpod 3 with hand-written providers. **No riverpod_generator.**
  Providers read repositories and use cases from `sl`.
- **Storage:** drift, fully offline, currently **schema v9** (`habits`;
  plans and logs keyed by `habit_id`; v9 adds wake and bed times). Repositories
  return `Result` and wrap storage calls with `guardStorage`.
- **Day logic:** a logical day resets at a user-set hour (default 4 AM). Logs
  between midnight and the reset hour belong to the previous day.
- **Plan:** `ReductionPlan(startDay, startLimit, quitDay)`. The limit on day d
  is `ceil(start × (D − d) / D)`. `PlanHistory.replan` keeps earlier plans so
  past days keep their own limit.

## Gotchas

- In Riverpod 3 a provider with no listeners is paused, so
  `ref.read(streamProvider.future)` can hang. Read from the repository or
  `ref.watch` instead.
- Tests: use `pumpAppPastSplash(height: 2400)` for Home so the lazy list
  builds every card; use `tester.pumpInSteps()` for animations; read drift
  streams in test bodies through `tester.runAsync`. Helpers live in
  `test/helpers/`.
- drift name clashes: `hide isNull, isNotNull` (matcher) and `hide Trigger`
  (drift) on imports.
- Simulator (iOS 26): debug builds need `fvm flutter run`, not a plain
  install. Injected taps need a duration of about 0.15 s. Fawad sometimes has
  two booted simulators, so pass explicit UDIDs to `simctl`.

## Current work: Home, Details and Logs redesign

Approved on 2026-10-21. Read these before working on it:

- Spec: `docs/superpowers/specs/2026-10-21-home-details-logs-design.md`
- Roadmap (phases, milestones, scope cuts, risks):
  `docs/superpowers/plans/2026-10-21-home-details-logs-roadmap.md`
- Implementation plan (18 tasks):
  `docs/superpowers/plans/2026-10-21-home-details-logs.md`
- Designs: `design/6._home_details_logs/` (see its README), Figma
  https://www.figma.com/design/KMF3WeQgfFv5g2MhOiwXMM, canvas
  https://claude.ai/artifact/Es7ju6TWmMj5pkNon4tbHu

The design in short: with one habit, Home is the habit dashboard (ring, impact
tiles, History with Week line / Month rings / All vs plan, plan card, why,
today's logs). With two or more habits, Home lists habit cards and tapping one
opens Details (the same dashboard plus a switcher). A new Logs page shows
"allowed" per period and supports filters and swipe-to-delete with Undo. With
one habit, tapping + logs and holding it opens the menu (shown once by a
hint). The second habit is free.

**How to execute:** natively in the session with the
`superpowers:executing-plans` skill, phase by phase (M1 to M5), with an
independent review at the end of each milestone. Give Fawad a commit message
at each checkpoint.

## Status

Current progress and the next action are in `docs/CURRENT_STATE.md`. Read it
first and update it when a task or milestone finishes.

After launch: time-of-day insights, reminders, widgets, the Pro paywall,
habit reordering, export.
