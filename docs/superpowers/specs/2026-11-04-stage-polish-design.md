# Stage polish after the M7 walk

Asked by Fawad on 2026-11-04, after the simulator walk. Branch `feat/plan-and-stages`. The
green "under limit" colour is a separate change on its own branch, after his review.

## 1. Review and reassess sheets fit their content

Both open at a fixed 90% of the screen, so a short sheet has a large empty space under its
footer. They become content-sized sheets (`showAppSheet`, up to 92% of the screen), scrolling
only when the content is taller, for example at large text. The gap above the title matches
the other content-sized sheets (Your why): the frame's grabber and close row, then the title.

## 2. Day rings in past stages

Tapping a stage under Behind you (this plan's and earlier plans') opens its panel as today.
Above the existing figures it now shows the stage's days the way the current stage does:
a ring per day up to 14 days, a dot per day beyond, with the same colours. A past stage has
no today and no days ahead. The key stays on the current stage only.

## 3. Stage ring colour

A stage ring is red (`danger`) when the stage's average is over its limit (`used > allowed`),
amber (`warning`) when it equals it (`used == allowed`, above 0), and the accent otherwise.
In the past-stage panel, "Used" and "Days over" turn red, not amber, when over.

## 4. A day opens its logs

On Plan details, tapping a day ring or a dot of any stage (current or past) opens Logs for
that day, the way History's days do (`LogsQuery(habitId, from: day, to: day)`). Days after
today do nothing. Each ring is a VoiceOver button worded like History's days ("Monday,
Nov 2: 9 of 10"), under the stage's summary. The dot grid stays one image to VoiceOver; its
days are also reachable through Logs.

## Tests

- Sheets: a short review sheet is shorter than 90% of the screen; it still scrolls at the
  largest text size; the existing sheet tests keep passing.
- `StageReport.status`: under, at (equal), over; a 0 limit with 0 used is under.
- Stage rings: over red, equal amber, under accent. Panel figures red when over.
- A past stage's panel shows its day rings (7 days) and dots (15 days), no today ring.
- Tapping a past ring, a current ring and a dot opens Logs on that day; a day ahead does not.
