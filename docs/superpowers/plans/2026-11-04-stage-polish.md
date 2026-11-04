# Stage polish plan

Spec: `docs/superpowers/specs/2026-11-04-stage-polish-design.md`. Branch
`feat/plan-and-stages`. One commit per task: failing test, code, passing test.

### Task P1: Sheets fit their content

- [x] Test in `test/features/home/plan_sheets_test.dart`: the review sheet's frame is shorter
  than 90% of the screen; at the largest text size its button is still reachable by scrolling.
- [x] `StageChoiceSheet` drops its `controller` and builds a `SingleChildScrollView`, padded
  like Your why. Both sheets open with `showAppSheet`.
- [x] Commit `fix(home): fit the review and reassess sheets to their content`.

### Task P2: Stage ring colours

- [x] Tests: `StageReport.status` in `plan_report_test.dart`; ring and panel colours in
  `plan_details_page_test.dart` (update "warns when over" and "warning colour" tests).
- [x] Add `LimitStatus get status` to `StageReport`; `StageRing` and the panel read it.
- [x] Commit `fix(plan): colour stages red when over and amber at the limit`.

### Task P3: Day rings in past stages

- [ ] Tests: a 7-day past stage's panel shows 7 `StageDayRing`s, none today; a 15-day one
  shows the dots and both dates.
- [ ] Move the rings and dots out of `current_stage_card.dart` into a shared `StageDays`
  widget; the panel shows it above the figures.
- [ ] Commit `feat(plan): show a past stage's days`.

### Task P4: A day opens its logs

- [ ] Tests: tapping a past ring, a current ring and a dot opens Logs on that day; a ring
  ahead does nothing; a ring is a VoiceOver button.
- [ ] `StageDays` takes an `onDay` callback; Plan details opens `LogsQuery` for the day.
- [ ] Commit `feat(plan): open a day's logs from its ring or dot`.

### Then

Format, analyze, the four tasks' test files, then the simulator for Fawad (light and dark).
