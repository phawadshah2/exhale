# M7 walk rulings plan

Fawad's answers (2026-11-05) to the four questions from the M7 simulator walk. Spec:
`docs/superpowers/specs/2026-11-02-stage-management-design.md` (sections 4, 5.2, 5.3 updated).
Commit on `feat/plan-and-stages`. Run with `execute-plan`: failing test, code, passing test,
commit.

## Rulings

1. "Start from your real number" uses the average the review sheet shows. With ruling 2 that
   is the average of the two failed windows.
2. The review's tiles, average, triggers and card limit cover the two failed windows: the
   review check's 7 days and the 7 days of the `hold` check before it. A held week between
   them is left out.
3. The hold card's date tiles stand out more in light mode. Dark mode stays.
4. "Vs baseline" at 0% shows "0%" with no arrow, in the muted colour.

## Review focus

- The seed's review (`SEED_STAGE=review`) shows logged above allowed.
- When the two windows touch, the result equals the old 14 days in a row.
- Reassess keeps its 14 days in a row.

### Task R1: The review covers the two failed windows

Files: `lib/features/home/presentation/providers/stage_card_provider.dart`,
`lib/features/home/presentation/widgets/plan_review_sheet.dart`,
`lib/features/plan/domain/services/plan_choices.dart` (doc comment only).

- [x] Tests (fail first), in `test/features/home/plan_sheets_test.dart` and
  `test/features/home/stage_cards_test.dart`: a hold, then a passed-looking held week, then
  a failed week. The sheet's logged, allowed and "About N" count only the two failed weeks,
  logged is above allowed, the triggers leave out the held week's logs, and "Start from your
  real number" starts at that "About N". The card shows the number when both windows had
  one limit and drops it when they had two. The existing adjacent-window tests keep passing.
- [x] The review's key carries both window ends: the review check's `windowEndDay` and the
  newest earlier check of the same plan (`stageChecksProvider`). Logs load for each 7-day
  window; `StageWindowStats` adds both; `average` divides by 14.
- [x] `_build` for `review` takes its limits from the two windows; `reassess` keeps the
  14 days ending on its window end.
- [x] Update doc comments that say "the 14 days" for the review, and `PlanChoices.review`'s
  `windowAverage` comment.
- [x] Commit `fix(plan): base the review on the two failed weeks`.

### Task R2: Hold date tiles stand out in light mode

Files: `lib/features/home/presentation/widgets/stage_cards.dart`.

- [ ] Test (fail first), in `stage_cards_test.dart`: in light mode, `_Tile`'s decoration has
  an opaque `colors.surface` fill and an `outlineVariant` border; in dark mode it keeps
  `surface` at 0.6 and no border.
- [ ] `_Tile`: branch on `Theme.of(context).brightness`.
- [ ] Commit `fix(home): make hold card tiles stand out in light mode`.

### Task R3: No arrow at 0% vs baseline

Files: `lib/features/home/presentation/widgets/stats_grid.dart`.

- [ ] Test (fail first), in `test/features/home/home_page_test.dart` beside the "↓ 33%" test:
  a change that rounds to 0% shows "0%", no "↓ 0%", and the tile's icon is `AppIcons.remove`
  in `onSurfaceVariant`.
- [ ] `stats_grid.dart`: when `(change.abs() * 100).round() == 0`, value "0%", icon
  `AppIcons.remove`, icon and value in the muted colour.
- [ ] Commit `fix(home): show no arrow at 0% vs baseline`.

### Then

- `fvm dart format .`, `fvm flutter analyze --fatal-infos`, the three tasks' tests.
- Simulator walk with Fawad's approval: `SEED_STAGE=review` (light and dark), `SEED_STAGE=hold`
  in light mode, Home with a 0% baseline change.
- Then push and the PR to `main`.
