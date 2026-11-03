# Current state

Updated 2026-11-03. The full log of earlier sessions is in
`docs/history/2026-10-16_to_11-03_state_log.md`.

## Where we are

| Milestone | Status |
|---|---|
| M1 Habits foundation, M2 Dashboard and Logs, M3 Logging and editing, onboarding redesign | Done, merged |
| M5 Release candidate | Done, merged to `main` (51e0bc6). Real iPhone pass still open |
| M6 Plan details, Edit plan, Logs (Tasks 1 to 12) | Done on `feat/plan-and-stages`: reviewed, two simulator walks |
| UI fixes from Fawad's review (Phase 4b, F1 to F4) | Done on `feat/plan-and-stages`; not seen in the simulator |
| M7 Stage management (Tasks 13 to 20) | Not started |
| M4 Multiple habits | Parked on `feat/multi-habit` for a later release |

Plan: `docs/superpowers/plans/2026-11-02-plan-and-stages.md`. Ledger with rulings:
`.superpowers/sdd/2026-11-02-plan-and-stages/progress.md` (git-excluded; M7 pre-flight
rows still to do).

## Repo

- `feat/plan-and-stages` is pushed up to 5715c87. Docs and F1 to F4 commits after it are
  local. No PR is open, and CI on the branch was not read.
- Checks at f1bc936, the last code commit: format clean, `analyze --fatal-infos` clean,
  full suite 1038 passed. Not run since, as only docs changed.
- 2026-11-03 setup changes: the new check flow is in `CLAUDE.md` "Workflow". The global
  hook no longer prompts for codegen, builds or simulator runs in this repo. Plans run
  with the `execute-plan` skill (Superpowers is being turned off). This repo's auto
  memory now holds `project_exhale.md`.
- Untracked on purpose: `design/all-designs.html`, `design/figma-import/`.

## Next action

Task 13 (holds in `ReductionPlan`), the start of M7, on Sonnet 5.5 medium. The M7 review
(Task 20) runs on Opus 5.5 high.

UI fixes done 2026-11-03 (commits 543ecc0, 203877e, 381598e, 389f483, plus the docs):
- F1 Ring card: trigger bars 5 pt, tighter panel, icons centred in the info tiles.
- F2 History: thinner week line and dots, thinner month rings, dotted future rings, month
  fixed at six weeks with greyed, untappable neighbour days.
- F3 Plan card: Edit pill removed; the card opens Plan details.
- F4 Logs: weeks only, a calendar sheet from the title, swipe by week, the selected day
  uses the current-stage inset highlight, the log row sits on the card colour in light mode.
- Checked 2026-11-03: full suite 1033 passed at 389f483. Simulator walk (iOS 26.5, seeded,
  light mode): F1 to F4 seen working: thin trigger bars and centred tile icons, Week and
  Month History (dotted future rings, grey neighbour days, six rows), no Edit pill and the
  Plan card opens Plan details, Logs weeks only, calendar sheet jump, week swipe, selected
  day highlight, log row on the card colour.
- Not seen: dark mode of these screens (the app stayed light), Reduce Transparency, text
  at 200%, the Month swipe between a 5-row and 6-row month by hand, a real iPhone. The Logs
  comparison with frame T was by code. A History chip opened on a month range now searches
  only the last week of that month.

## Open checks

- Real iPhone: glass performance, chart scrolling with 90+ days, returning from the
  background, and the M6 screens.
- Simulator, still unseen: a long plan (needs an install with no habit), light mode after
  the M6 fixes, Plan details at 200%.
