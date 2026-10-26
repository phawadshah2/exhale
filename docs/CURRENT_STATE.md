# Current state

Updated 2026-10-25. Roadmap:
`docs/superpowers/plans/2026-10-21-home-details-logs-roadmap.md`; tasks in
`docs/superpowers/plans/2026-10-21-home-details-logs.md`.

## Goal

Home, Details and Logs redesign, milestone **M1 (Habits foundation)**:
Tasks 1.1–1.3.

## Done (uncommitted, branch `feat/habits-foundation`)

- Schema v8: a `habits` table; plans and logs keyed by `habit_id`; settings
  lose the habit and price fields and gain `log_hint_seen`.
- Habit domain, data and providers, plus `StartTracking`, which adds a habit
  and its plan in one transaction.
- Home uses `primaryHabitProvider` until M4.
- The independent review's fixes are in.
- About 65 files changed. See `git status`.

## Checks (2026-10-21, before the decision below)

- Format, `analyze --fatal-infos` and `flutter test` (237 tests) all passed.
- A simulator upgrade over the real v7 data showed Home at 13 / 14, as
  before.

## Decision (2026-10-25), implemented

Every v7 log maps to habit 1 in the v8 migration; the `smoking` stamp came
from the v7 column default. The archived-habit insert is gone. Migration
tests, the spec (§6) and Task 1.2 in the plan match. Changed files:
`app_database.dart`, `test/core/data/app_database_migration_test.dart`, the
spec and the plan.

## Checks since the decision

Not run. Fawad chose to skip them for now. The migration change and its
tests are unverified.

## Commit messages (given to Fawad, not yet committed as of handoff)

- `feat(data): per-habit plans and logs, schema v8` (includes spec/plan edits)
- `docs: add CLAUDE.md and current state`

## Next action

1. Ask Fawad before running `fvm dart format .`, then
   `fvm flutter analyze --fatal-infos`, then `fvm flutter test`. Fix any
   migration test failure first.
2. After M1 is merged: Phase 2 / Task 2.1 (read it in the implementation
   plan; no other docs needed).
