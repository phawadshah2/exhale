# Current state

Updated 2026-11-04. Earlier sessions: `docs/history/2026-10-16_to_11-03_state_log.md`.

## Where we are

| Milestone | Status |
|---|---|
| M1 Habits foundation, M2 Dashboard and Logs, M3 Logging and editing, onboarding redesign | Done, merged |
| M5 Release candidate | Done, merged to `main` (51e0bc6). Real iPhone pass still open |
| M6 Plan details, Edit plan, Logs (Tasks 1 to 12) | Done on `feat/plan-and-stages`: reviewed, two simulator walks |
| UI fixes from Fawad's review (Phase 4b, F1 to F4) | Done; seen in the simulator, light mode |
| UI review round 2 (Logs, Plan, Home, transitions) | Done, committed (a947c2d) |
| M7 Stage management (Tasks 13 to 20) | Done: reviewed, fixed, simulator walk 2026-11-04 |
| Stage polish P1 to P4 (`docs/superpowers/plans/2026-11-04-stage-polish.md`) | Done, committed; seen in the simulator, approved by Fawad |
| Green under the limit G1, trigger colours G2 (`docs/superpowers/plans/2026-11-04-green-under.md`) | Done on `feat/green-under`; walked light and dark, waiting for Fawad |
| M4 Multiple habits | Parked on `feat/multi-habit` for a later release |

Plan: `docs/superpowers/plans/2026-11-02-plan-and-stages.md` (all tasks ticked). Spec for
M7: `docs/superpowers/specs/2026-11-02-stage-management-design.md`.

## Repo

- Branch `feat/plan-and-stages` at ef45ca7, tree clean. Pushed up to 5715c87; every later
  commit is local. No PR is open, and CI was not read.
- Branch `feat/green-under` off it (ef45ca7): G1 and G2, local only. Their test files and
  `test/features/home/accessibility_test.dart` passed; format and `analyze --fatal-infos`
  clean; the full suite was not rerun.
- Untracked on purpose: `design/all-designs.html`, `design/figma-import/`.

## M7 simulator walk (2026-11-04, `exhale` iOS 26.5)

`lib/main_seed.dart` (git-excluded) now takes `--dart-define=SEED_STAGE=hold|review|reassess`:
12 a day with weekly drops, the latest stage ending yesterday. Uninstall the app between runs.

- Hold, dark and light: "9 can wait.", 76 against 70, next drop Nov 11 (was today), quit
  Jan 13 (was Jan 6). Keep moved today to 9 and stage 4; Got it kept 10 and stage 3.
- Review, light and dark: card without a number (two limits in the 14 days); sheet tiles,
  top 3 triggers, three choices with dates and change labels; Keep variant of button and
  footer. "Shake on it again" started stage 1/10 at 10.
- Reassess, dark and light: card, sheet, Still yours tiles, nicotine support line, Start
  again from 12 (Jan 27, 3 weeks later). Keep my plan closed the card, plan unchanged.

## Questions for Fawad (from the walk, nothing changed)

1. "Start from your real number" uses the 14-day average (`plan_choices.dart:60`); spec 4
   says the window's average, and spec 2 defines the window as 7 days. The seed shows 10,
   where the 7-day window gives 11. Which is meant?
2. After a hold, the review's 14 days are the held week plus the second failed week, so the
   tiles can show logged under allowed (seed: 139 against 147) beside "Two weeks over
   your limit".
3. Hold card date tiles barely stand out from the card in light mode.
4. Before M7: "Vs baseline" shows "↓ 0%" with an arrow at 0%.

## Stage polish (2026-11-04)

Walked on `exhale`, light and dark, approved by Fawad. The sheet fix was not seen there
(no card showed).

## Next action

Fawad reviews `feat/green-under` (walked on `exhale`, Ink, light and dark: green day,
stage and week points; triggers blue to magenta, 198° to 318°). Then he decides whether
it merges into `feat/plan-and-stages`, rules on the questions above, and the branch is
pushed and the PR to `main` opened from the compare link. After merge: the real iPhone
pass, including the M6 and M7 screens (hold, review, reassess via `SEED_STAGE`).

## Open checks

- Not seen: dark mode of the F1 to F4 screens, Reduce Transparency, text at 200% in the
  simulator, a real iPhone (glass performance, chart scrolling with 90+ days, returning
  from the background, the M6 and M7 screens), a long plan, Plan details at 200%.
- Round 2 not seen in the simulator: range mode, the date wheel, tab fade, dark mode.
- M7 not seen: Reduce Transparency, text at 200%, the alcohol line, a late-open hold card.
