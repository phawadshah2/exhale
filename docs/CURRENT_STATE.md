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
| M7 Stage management (Tasks 13 to 20) | Tasks 13 to 19 done; Task 20 (M7 review) next |
| M4 Multiple habits | Parked on `feat/multi-habit` for a later release |

Plan: `docs/superpowers/plans/2026-11-02-plan-and-stages.md`. Spec for M7:
`docs/superpowers/specs/2026-11-02-stage-management-design.md`. Ledger with rulings:
`.superpowers/sdd/2026-11-02-plan-and-stages/progress.md` (git-excluded; M7 pre-flight
rows still to do).

## Repo

- Branch `feat/plan-and-stages`, code at d090f30 (trigger chips 34 pt, stage ring track
  darker). Pushed up to 5715c87; every later commit is local. No PR is open, and CI was not
  read.
- Checks: full suite 1073 passed at 0c513c3, not run since. After Task 19: format and
  `analyze --fatal-infos` clean; `test/features/home`, `test/app` and the new use case tests
  pass (265). Simulator not run for rounds 2 or M7.
- Untracked on purpose: `design/all-designs.html`, `design/figma-import/`.

## Done this session (2026-11-03)

- F1 to F4 (543ecc0, 203877e, 381598e, 389f483): ring card, History, Plan card (Edit pill
  removed), Logs (weeks only, calendar sheet, week swipe, current-stage highlight).
- Tasks 13 and 14 (cdbb703, 0c513c3): `PlanHold` and `ReductionPlan.holds` (`quitDay` includes
  held days, `agreedQuitDay` is stored); schema v11 (`plan_holds`, `stage_checks`,
  `exhale_v10.sqlite` fixture), `StageCheck`, `StageCheckRepository`, `stageChecksProvider`.
  `record(closesHoldWindow:)` stamps the old hold card with midnight of the new check's day.
- Task 15: `StageChecks.evaluate` (`stage_checks.dart`); a skipped result closes no hold.
- Task 16: `RunStageCheck` (one transaction) and `StageCheckListener` in the shell; runs at
  start and on a day change. Added `HabitLogRepository.getLogs`.
- Task 17: `PlanChoices.review` / `reassess` and `PlanChoice` (`plan_choices.dart`, integer
  length maths), `HabitWording.supportLine` and `stopSuddenlyLine`.
- Task 18: `stageCardProvider` (current plan's unanswered row only), `StageCards` in the
  ring card's slot like `QuitReachedCard` (the mock draws separate cards; the spec says the
  slot), `AnswerStageCheck`, `KeepOriginalDate`. Not seen in the simulator or dark mode.
- Task 19: `StageChoiceSheet` (shared), review and reassess sheets, `AnswerWithNewPlan`
  (answer first, one transaction), `stageWindowStatsProvider`. Not seen in the simulator.

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

Task 20, the M7 review (Opus 5.5 at high): independent review, fix findings, full suite with
the JSON report, then the simulator walk. Fawad may still ask for round 2 fixes after a full
restart. The spec has only "later" labels, so a choice that moves the quit date earlier reads
"N days/weeks earlier" (my call; say if wrong).

## Open checks

- Not seen: dark mode of the F1 to F4 screens, Reduce Transparency, text at 200% in the
  simulator, a real iPhone (glass performance, chart scrolling with 90+ days, returning
  from the background, the M6 screens), a long plan, Plan details at 200%.
- Round 2 not seen in the simulator: range mode, the date wheel, tab fade, dark mode.
