# Current state

Updated 2026-11-03. The full log of earlier sessions is in
`docs/history/2026-10-16_to_11-03_state_log.md`.

## Where we are

| Milestone | Status |
|---|---|
| M1 Habits foundation, M2 Dashboard and Logs, M3 Logging and editing, onboarding redesign | Done, merged |
| M5 Release candidate | Done, merged to `main` (51e0bc6). Real iPhone pass still open |
| M6 Plan details, Edit plan, Logs (Tasks 1 to 12) | Done on `feat/plan-and-stages`: reviewed, two simulator walks |
| UI fixes from Fawad's review (Phase 4b, F1 to F4) | Done; seen in the simulator, light mode |
| UI review round 2 (Logs, Plan, Home, transitions) | Done, committed (a947c2d) |
| M7 Stage management (Tasks 13 to 20) | Tasks 13 to 17 done; Task 18 next |
| M4 Multiple habits | Parked on `feat/multi-habit` for a later release |

Plan: `docs/superpowers/plans/2026-11-02-plan-and-stages.md`. Spec for M7:
`docs/superpowers/specs/2026-11-02-stage-management-design.md`. Ledger with rulings:
`.superpowers/sdd/2026-11-02-plan-and-stages/progress.md` (git-excluded; M7 pre-flight
rows still to do).

## Repo

- Branch `feat/plan-and-stages`. Round 2 is committed (a947c2d). Pushed up to 5715c87; every commit after it is
  local (UI fixes, Tasks 13 and 14, docs). No PR is open, and CI was not read.
- Checks at 0c513c3: full suite 1073 passed. Round 2, last run: format and `analyze
  --fatal-infos` clean; `test/features/{logs,home,settings,plan}` and `test/app` pass. Full
  suite not run since; simulator not run.
- Untracked on purpose: `design/all-designs.html`, `design/figma-import/`.

## Done this session (2026-11-03)

- F1 to F4 (543ecc0, 203877e, 381598e, 389f483): ring card, History, Plan card (Edit pill
  removed), Logs (weeks only, calendar sheet, week swipe, current-stage highlight).
- Task 13 (cdbb703): `PlanHold`; `ReductionPlan` takes `holds`; `quitDay` includes held
  days, `agreedQuitDay` is stored; `daysPerDrop` ignores holds.
- Task 14 (0c513c3): schema v11, `plan_holds` and `stage_checks`, `exhale_v10.sqlite`
  fixture, plans read their holds, `replaceFrom` drops their holds and checks,
  `StageCheck`, `StageCheckRepository`, `stageCheckRepositoryProvider`,
  `stageChecksProvider`. `record(closesHoldWindow:)` stamps the old hold card with
  midnight of the new check's day (no clock in the data layer).
- Simulator walk of F1 to F4 seen working (iOS 26.5, seeded, light mode).

- Task 15: `StageChecks.evaluate` in `lib/features/plan/domain/services/stage_checks.dart`
  (37 tests). A skipped result stores zeros and closes no waiting hold.
- Task 16: `RunStageCheck` (one transaction from read to write) and `StageCheckListener` in the
  shell; runs for the single habit at start and on a day change. Added
  `HabitLogRepository.getLogs`, a one-shot `watchLogs`.
- Task 17: `PlanChoices.review` / `reassess` and `PlanChoice` (`plan_choices.dart`, integer
  length maths), `HabitWording.supportLine` and `stopSuddenlyLine`.

## UI review round 2 (a947c2d, 2026-11-03)

- Logs: weekday above ring, highlight wraps both; iOS date wheel replaces the sheet
  (`logs_date_picker.dart` deleted); count ring on the right of the day header
  (`LogsCountRing`); a trigger filter lists the whole week's matches (`_RangeLogs`); picking
  a date clears the filter; hint under the chips; no SafeArea.
- Range mode: History Month/All opens `LogsSelection.isRange` (a span reaching before the
  week of its end). No calendar; "Back to weeks"; filtered = matches across the range,
  unfiltered = one row per day (tap opens that week). Fixed for a just-begun month.
- Plan: Edit plan pace note ("Pace: ... (was ...)") and "Use suggested date"; "8 weeks" and
  "16 weeks" pills, smaller; price card and preview animate; `ScrollReveal` moved to
  `lib/core/widgets` and used on Plan details, Edit plan, Settings (`ReplayOnVisit` tab 1).
- Home: trigger rows 28 pt (under the 44 pt rule, Fawad asked), smaller History pills, "Details
  ›" on the plan card. Tab switch fades via `lib/app/shell/branch_fade.dart`.
- Not done: Change habit and onboarding have no entry reveal.

## Next action

Task 18, Home cards (Sonnet 5.5 medium): read its block in the plan and Stages spec section 5.
Open point for Tasks 18 and 19: a choice's quit date can fall before the current one (a late
plan, a small real number), and the spec has only "later" labels. Fawad may still ask for round 2 fixes after a full restart. The M7 review
(Task 20) runs on Opus 5.5 high.

## Open checks

- Not seen: dark mode of the F1 to F4 screens, Reduce Transparency, text at 200% in the
  simulator, a real iPhone (glass performance, chart scrolling with 90+ days, returning
  from the background, the M6 screens), a long plan, Plan details at 200%.
- Round 2 not seen in the simulator: range mode, the date wheel, tab fade, dark mode.
