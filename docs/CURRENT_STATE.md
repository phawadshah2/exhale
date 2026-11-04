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
| Green under the limit G1, trigger colours G2 (`docs/superpowers/plans/2026-11-04-green-under.md`) | Done, walked light and dark, approved; merged into `feat/plan-and-stages` |
| M4 Multiple habits | Parked on `feat/multi-habit` for a later release |

Plan: `docs/superpowers/plans/2026-11-02-plan-and-stages.md` (all tasks ticked). Spec for
M7: `docs/superpowers/specs/2026-11-02-stage-management-design.md`.

## Repo

- Branch `feat/plan-and-stages`, 86 commits ahead of `main`; `feat/green-under`
  fast-forwarded into it. Pushed up to d81f915. No PR is open, and CI was not read.
- Checks at 0cf6041: full suite 1206 passed, 0 failed (`build/test-report.json`); format
  and `analyze --fatal-infos` clean.
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

## Walk rulings (Fawad, 2026-11-05)

Plan `docs/superpowers/plans/2026-11-05-walk-rulings.md`, R1 to R3 done and committed, each
with its tests, format and analyze clean; not yet seen in the simulator. Spec 4, 5.2 and 5.3
updated. R1: the review's tiles, average, triggers and "Start from your real number" use the
two failed weeks (the hold's window and the review's), not 14 days in a row. R2: hold card
tiles stand out in light mode. R3: "0%" with no arrow vs baseline.

## Stage polish and colours (2026-11-04)

- Stage polish walked and approved; the sheet fix was not seen (no card showed).
- Under the limit is green (`success.solid`) through `LimitStatus.barColor` alone; Home's
  today ring, all text and the week chart's line keep the accent.
- Triggers use 9 fixed slots, 198° to 318° (`trigger_ui.dart`), distinct within each
  habit. 331° looked crimson beside red, so the range stops at 318°.

## Next action

With Fawad's approval, walk the rulings in the simulator: `SEED_STAGE=review` (light and
dark; logged now above allowed), `SEED_STAGE=hold` in light mode, Home at 0% vs baseline.
Then push `feat/plan-and-stages` and open the PR to `main` from the compare link. After
merge: the real iPhone pass, including the M6 and M7 screens and the colours.

## Open checks

- Not seen: dark mode of the F1 to F4 screens, Reduce Transparency, text at 200% in the
  simulator, a real iPhone (glass performance, chart scrolling with 90+ days, returning
  from the background, the M6 and M7 screens), a long plan, Plan details at 200%.
- Round 2 not seen in the simulator: range mode, the date wheel, tab fade, dark mode.
- M7 not seen: Reduce Transparency, text at 200%, the alcohol line, a late-open hold card.
- Colours walked only under Ink: Eucalyptus and Ocean accents not seen.
