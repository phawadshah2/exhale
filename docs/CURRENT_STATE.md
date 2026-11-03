# Current state

Updated 2026-11-03. The full log of earlier sessions is in
`docs/history/2026-10-16_to_11-03_state_log.md`.

## Where we are

| Milestone | Status |
|---|---|
| M1 Habits foundation, M2 Dashboard and Logs, M3 Logging and editing, onboarding redesign | Done, merged |
| M5 Release candidate | Done, merged to `main` (51e0bc6). Real iPhone pass still open |
| M6 Plan details, Edit plan, Logs (Tasks 1 to 12) | Done on `feat/plan-and-stages`: reviewed, two simulator walks |
| UI fixes from Fawad's review (below) | Next, before M7 |
| M7 Stage management (Tasks 13 to 20) | Not started |
| M4 Multiple habits | Parked on `feat/multi-habit` for a later release |

Plan: `docs/superpowers/plans/2026-11-02-plan-and-stages.md`. Ledger with rulings:
`.superpowers/sdd/2026-11-02-plan-and-stages/progress.md` (git-excluded; M7 pre-flight
rows still to do).

## Repo

- `feat/plan-and-stages` is pushed up to 5715c87. Docs commits after it are local. No PR
  is open, and CI on the branch was not read.
- Checks at f1bc936, the last code commit: format clean, `analyze --fatal-infos` clean,
  full suite 1038 passed.
- Untracked on purpose: `design/all-designs.html`, `design/figma-import/`.

## Next action

The UI fixes Fawad asked for on 2026-11-03. Sort out the open questions with him first,
then add them to the plan as tasks.

1. Ring card: make the trigger bars quieter so the eye goes to the ring (smaller, less
   spacing). Centre the icon in the last-entry tile and the tiles like it.
2. Home History card:
   - Week: thinner line and day dots.
   - Month: thinner rings. Make the dotted future rings and the past rings clearer, so
     the two are easy to tell apart.
   - Month swipe overflows. Keep one fixed height, with greyed-out days from the
     previous and next months.
3. Plan card: open Plan details, not Edit plan.
4. Logs page:
   - Highlight the selected day the same way as the current stage on Plan details.
   - The arrow next to the period opens a calendar.
   - Drop the Week/Month switch: weeks only, with a specific day picked from the
     calendar.
   - The log list (stepper) and the log card background must match the design.

After that comes Task 13 (holds in `ReductionPlan`), the start of M7, on Sonnet 5.5
medium. The M7 review (Task 20) runs on Opus 5.5 high.

## Open checks

- Real iPhone: glass performance, chart scrolling with 90+ days, returning from the
  background, and the M6 screens.
- Simulator, still unseen: a long plan (needs an install with no habit), light mode after
  the M6 fixes, Plan details at 200%.
