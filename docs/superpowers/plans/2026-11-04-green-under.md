# Green for under the limit plan

Spec: `docs/superpowers/specs/2026-11-04-green-under-design.md`. Branch `feat/green-under`
(off `feat/plan-and-stages`). Run with `execute-plan`: failing test, code, passing test,
commit.

## Review focus

- Ink accent, light and dark: under-limit fills are green, not ink or paper.
- Home's today ring under its limit keeps the accent gradient (no `finalColor`).
- The week chart's line and fill stay the accent; only the points change.
- A stage with no data keeps its dashed accent ring.

### Task G1: Under the limit is green

Files: `lib/features/tracking/presentation/limit_status_ui.dart`,
`lib/features/plan/presentation/widgets/stage_days.dart`, `stage_ring.dart`,
`lib/features/home/presentation/widgets/history/week_line_chart.dart`.

- [x] Tests (fail first):
  - New `test/features/tracking/limit_status_ui_test.dart`: in a pumped themed app,
    `LimitStatus.under.barColor(context) == context.exhale.success.solid`, `at` is
    `warning.solid`, `over` is `danger.solid`. Under the Ink accent, under is not
    `colors.primaryContainer`.
  - `plan_details_page_test.dart:339, 690, 703`: expect `context.exhale.success.solid`
    instead of `colors.primaryContainer`. A test that the `DayDotsPainter`'s `under` is
    `success.solid` (next to the test at line 761).
  - `logs_page_test.dart:279, 403`: `success.solid` instead of `primaryContainer`.
  - `history_card_test.dart`: in the week view, an under day's point is drawn
    (`drawCircle`) in `success.solid`, and the line (`drawPath`, stroke 3) in
    `colors.primaryContainer`. In the month view, the "Under" legend swatch is
    `success.solid`.
- [x] `barColor`: under returns `context.exhale.success.solid`; its doc comment drops
  "the accent while under the limit".
- [x] `stage_days.dart`: delete `_statusColor`; the rings use
  `progress.status.barColor(context)` and `DayDotsPainter(under:)` takes
  `LimitStatus.under.barColor(context)`. The no-data ring keeps `primaryContainer`.
- [x] `stage_ring.dart`: the three-way switch becomes `status.barColor(context)`.
- [x] `week_line_chart.dart`: add `required Color under` to the painter beside `accent`;
  the point switch uses it for `LimitStatus.under`; the widget passes
  `LimitStatus.under.barColor(context)`. (`shouldRepaint` already returns true.)
- [x] Leave `progress_ring.dart` and all text colours as they are.
- [x] Commit `feat(theme): colour under-limit days green`.

### Then

Format, analyze, the task's test files plus `test/features/home/accessibility_test.dart`, then the
simulator for Fawad: Ink accent, light and dark, on Home (History week and month), Plan
details (stages, day rings, dots) and Logs (calendar, rail).
