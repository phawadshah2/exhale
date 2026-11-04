# Green for under the limit

Asked by Fawad on 2026-11-04, after the stage polish review. Branch `feat/green-under`, off
`feat/plan-and-stages`, kept separate so it can be reverted.

## Colour

A day or stage under its limit is drawn in green (`exhale.success.solid`), in every
accent. At the limit stays amber, over stays red. Today the under colour is the accent
(`primaryContainer`), so under Ink most days are black, or white in dark mode.

## One source

`LimitStatus.barColor` (`limit_status_ui.dart`) returns `success.solid` for under. The
copies of the under colour read it instead of the accent:

- `stage_days.dart`: `_statusColor` goes; the rings and the dots' `under` use `barColor`.
- `stage_ring.dart`: the stage ring under its limit.
- `week_line_chart.dart`: an `under` colour for the points; the line and its fill stay
  the accent.

Already on `barColor`, so green with no change: History bars, the month calendar and its
legend, the Logs calendar, the Logs rail days, the log menu. Reverting means changing
`barColor` back.

## Unchanged

- Home's today ring keeps its accent gradient while under, then amber or red (today is
  not finished). Today elsewhere (stage ring, History bar, calendar day) is green like any
  other day.
- Text keeps its colours (Home's "3 left today" in the accent).
- The dashed stage ring of a stage with no data, buttons, emphasis, the chart's line.

## Tests

- `barColor`: under is `success.solid`, at is `warning.solid`, over is `danger.solid`.
- Plan details: an under stage ring, day ring and dot are green
  (`plan_details_page_test.dart`, replacing the `primaryContainer` expectations).
- Logs: under days are green (`logs_page_test.dart`, same replacement).
- Week chart: an under point is green, the line is the accent.
- History legend: the "Under" swatch is green.

## Trigger colours (G2)

Asked by Fawad on 2026-11-04: trigger colours must not look like a status colour. Today
each trigger has its own hue round the whole wheel, so vaping's Stress is red, After meal
amber, and Social, Commute and Habit green.

Triggers take 9 hues from blue to magenta: 195°, 212°, 229°, 246°, 263°, 280°, 297°,
314°, 331° (at least 29° from emerald, red and amber). Each trigger has one fixed slot,
so it keeps its colour everywhere, and no two triggers offered by the same `HabitKind`
share a slot (8 slots cannot do this for the nine lists; 9 can):

| Slot | Hue | Triggers |
|---|---|---|
| 0 | 195° | Stress |
| 1 | 212° | Habit |
| 2 | 229° | Boredom |
| 3 | 246° | After meal, Notification, Workout, Late night |
| 4 | 263° | Social, Bedtime |
| 5 | 280° | Tired, Coffee, Avoiding tasks |
| 6 | 297° | Work, Watching TV, Celebrating, Drinks |
| 7 | 314° | Lonely, Studying |
| 8 | 331° | Morning, Commute |

Saturation and lightness stay as they are; `tint` and `textTint` keep their signatures.
Under the Ocean accent the blue triggers sit near the accent; that is not a status colour.

Tests: each `HabitKind`'s triggers have 8 different tints; every trigger hue is at least
25° from 160° (green), 38° (amber) and 0° (red); the readability and light/dark hue tests
keep passing. "Every trigger has its own colour" gives way to the per-habit test.
