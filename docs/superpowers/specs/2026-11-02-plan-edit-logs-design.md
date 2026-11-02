# Plan details, Edit plan and Logs

Designs signed off by Fawad on 2026-11-01. Canvas
https://claude.ai/artifact/JaQJQ5meV7qTnZNeKiPkoK, source `design/8._plan_edit_logs/`:

| Screen | Frame | File |
|---|---|---|
| Plan details | K, current stage from Y and Z | `StagesRings`, `StageShort`, `StageLong`, `StageLongMax` |
| Edit plan | N | `EditDial` |
| Logs | T | `LogsCombined` |

Colours, sizes and spacing come from those frames and are not repeated here. This spec records
what the frames can't show: where numbers come from, rules, states and failures. Where a frame's
sample number disagrees with a rule here, the rule wins. Section 8 lists the calls Claude made
that no frame or chat settled.

Build this before stage management (`2026-11-02-stage-management-design.md`), which relies on
Plan details' earlier-stage view and shares its totals.

## 1. Purpose

- **Plan details** is new: the whole plan, stage by stage, with what each stage cost and saved.
- **Edit plan** becomes a dial and a ruler, and stops starting a new plan when only the price
  changes.
- **Logs** becomes a ring calendar and one day's timeline, replacing the newest-first list.
- **Money saved** stops repricing the past: a price change counts from the day it is made.

## 2. Price history

### 2.1 Rule

Each day is priced at the price in force that day.

- A day uses the latest price point on or before it.
- Days before the first point use the first point. So a first price entered on day 20 still
  counts from Day 1, as "Add a price" does today.
- A point with no price means nothing is counted from that day until the next priced point.

**Example.** Baseline 12. A session costs $0.40 until Nov 1 and $0.45 from Nov 2. Nov 1 has 9
logged, Nov 2 has 8. Saved: 3 × $0.40 + 4 × $0.45 = $3.00. Changing the price on Nov 2 leaves
Nov 1's $1.20 as it was.

### 2.2 Data

Schema v10. Stage management also targets v10; the implementation plan decides whether it joins
this version or takes v11.

**`habit_prices`:** `id`; `habit_id` (references `habits`); `from_day` (yyyy-mm-dd); `price_cents`
(nullable); `units_per_container`. Unique on `habit_id`, `from_day`.

`habits.price_cents` and `habits.units_per_container` stay as the current values, so onboarding
and every other reader are untouched. A write that changes either one also writes a point, in the
same transaction:

- `from_day` is today's logical day
- a second change on the same day replaces that day's point
- a habit created with a price gets a point on its first plan's start day
- a habit with no price and no earlier point gets no point when it is saved without one, so a
  point with no price is only ever written after a priced one

**Migration.** Each habit with a price gets one point: its earliest plan's `start_day`, or
`created_at`'s date when it has no plan. A habit with no price gets none.

### 2.3 Domain

`PriceHistory` holds the points and answers `unitPriceCentsOn(day)`, using the same per-container
rule as `TrackedHabit.unitPriceCents`. It returns null for a habit that does not track cost.

`ProgressCalculator.homeStats` takes a `PriceHistory` instead of `unitPriceCents`.
`moneySavedCents` is `max(0, Σ (baseline − count) × unitPriceCentsOn(day))` over finished days. It
is null when the current price is null, so Home still shows "—" and "Add a price". History is
kept, so adding a price again brings the earlier savings back.

`avoided` does not change.

## 3. Plan details (frames K, Y, Z)

### 3.1 Entry

Route `/habit/:habitId/stages` (`AppRoutes.planDetailsFor`). Tapping Home's plan card opens it, with
a selection haptic. The card's Edit pill still opens Edit plan. The page's Edit pill opens Edit
plan too, and the page updates when that closes. Everything else that opens Edit plan is unchanged.

### 3.2 `PlanReport`

A pure builder, `PlanReport.build(logs, boundary, history, prices, window, today)`, in
`lib/features/plan/domain/services/`. Widgets only format what it returns. Stage management reads
its totals.

Definitions used below:

- `baseline`: `history.plans.first.startLimit`, as on Home
- `first`: `history.firstDay`
- `end`: the later of `current.quitDay − 1` and today
- `finished`: `first` through yesterday. Today has no result until it ends

### 3.3 Header and totals

Back, the Edit pill, "You are here. Regrettably." and "Each ring is a stage, filled by what you
used. Tap one for the damage." From the quit date on, the title is "You made it. Regrettably."

"The whole plan" spans every plan:

| Tile | Value | Of |
|---|---|---|
| {Units} used | logs from `first` through today | Σ `limitOn(d)`, `first` to `end` |
| {Units} avoided | Home's `avoided` | `max(0, Σ (baseline − limitOn(d)))`, `first` to `end` |
| Money saved | Home's `moneySavedCents` | `max(0, Σ (baseline − limitOn(d)) × price(d))`, `first` to `end`; days after today use the current price |
| Days kept | `finished` days not over their limit | number of `finished` days |

Each tile's bar is value ÷ of, from 0 to 1, and empty when "of" is 0.

Money saved follows Home's rules: hidden for a habit that does not track cost, and "—" with "Add a
price ›" opening Edit plan when no price is set. With three tiles the last one takes the full
width, as `StatsGrid` does. At large text sizes the tiles stack, also as `StatsGrid` does.

Under the tiles: "Without a plan: {baseline × days} {units} and {money}. Nobody said it was cheap."
`days` runs from `first` to `end`. With no money figure: "Without a plan: {n} {units}. Nobody said
it was cheap."

### 3.4 Sections

Sections run oldest first. A section with no stages is hidden.

| Section | Side text | Holds |
|---|---|---|
| BEHIND YOU | "{money} saved" | every stage that has ended, across all plans |
| YOU, REGRETTABLY | "Stage {n} of {count}" | the current stage |
| AHEAD OF YOU | "{money} to save" | the current plan's later stages |

Side money is hidden when the habit has no price.

**Earlier plans.** Stage numbers restart with each plan, so each earlier plan's stages sit under a
small label inside BEHIND YOU: "Earlier plan · until {last day}". When there is one or more earlier
plan, the current plan's ended stages get the label "This plan".

A stage cut off by a replan ends the day before the new plan starts, and all its figures use those
days. Stages that never started are not shown. Rows are never removed, however many there are.

### 3.5 Stage rows

All stages show a ring with the limit inside, "Stage {n}", its date range, money on the right and a
chevron. Stages open and close independently; all start closed.

**Ring.** Fill is used ÷ allowed, clamped to 1, with `allowed = limit × days`. Its colour is the
accent, or `warn` when used is over allowed. Nothing is drawn at 0 used. Stages ahead have a dashed
track and no fill.

**Money.** `saved` is `Σ (baseline − count) × price(d)` over the stage's finished days, shown as at
least 0 but summed as it is, so BEHIND YOU plus the current stage equals the total. `to save` is
`(baseline − limit) × days × price`, at least 0. Hidden when the habit has no price.

| | Right side | Label |
|---|---|---|
| Behind | saved, in success colour | "saved" |
| Current | saved, in success colour | "of {to save}" |
| Ahead | to save, muted | "to save" |

**Open, behind you:**

- {Units}: "{used} of {allowed} used", in warning colour when over
- Days over: "{n} of {days}", in warning colour when above 0
- Average: "{used ÷ days, one decimal} a day"
- Mostly: the top trigger from `triggerBreakdown`. Hidden when no log in the stage has one
- Note, first match wins:
  1. the lowest used ÷ allowed of all ended stages, with at least two ended: "Your best so far. Try
     not to let it go to your head."
  2. the first stage of the first plan: "The easy one. It was meant to be."
  3. no days over: "Not one day over. Who are you?"
  4. one day over: "One over for the whole stage. Bold."
  5. otherwise: "{n} days over. It's over now too."

**Open, ahead of you:**

- {Units}: "{allowed} allowed"
- Pace: "One every {awake minutes ÷ limit}", from the settings day window, formatted like the +
  chip. "One every 16 h" at a limit of 1 on the default window
- To avoid: "{(baseline − limit) × days} {units}", at least 0. Hidden at 0
- Starts: "Tomorrow" or "In {n} days"
- Note, first match wins:
  1. the last stage: "The last one. Literally."
  2. the next stage, when the limit drops by exactly one: "One fewer. You have survived worse
     Mondays."
  3. the first stage whose limit is at most half the plan's start: "Halfway down. Don't tell your
     thumbs."
  4. otherwise: "Already written. Nothing to do yet."

### 3.6 The current stage

Always open, with no chevron, as in Y and Z. A 56 pt ring, the NOW pill, and "{range} · day {n} of
{days}".

**Up to 14 days (Y):** 7 rings to a row, each with its count inside and the weekday under it.

- a day with a result is coloured by `LimitStatus` (accent, warn, danger)
- today has the inner background and a heavier weekday, and is coloured the same way
- a day ahead has a dashed track with its limit inside

**Over 14 days (Z):** one dot per day, start date above the first dot, and under them "Each dot is
a day" and the end date.

```
width = the card's inner width
cols  = days <= 52 ? 13 : min(33, ceil(days / 4))
size  = clamp(floor(width / cols × 0.72), 7, 16)
gap   = clamp(round(size × 0.5), 3, 8)
```

That gives 13 across up to 4 rows (52 days), then 4 rows with more across and smaller dots, down
to 7 px at 33 across (132 days). Past that the dots stay at 7 px and the rows grow. Finished days
are filled by result. Today is hollow in the accent, because it has no result yet. Days ahead are
hollow with a dashed-track colour.

**Both:** the key (Under, At limit, Over) and then:

- "{used} of {allowed} used · {n} days over", which includes today once it has gone over
- "Drops to {next} in {n} days. Try to look surprised." On the stage's last day: "Drops to {next}
  tomorrow. Try to look surprised." On the last stage, `next` is 0

The rings and dots are one image to VoiceOver: "{days} days, limit {limit}. {n} over. Today is day
{n}."

### 3.7 Finish row and quit

The flag ring, "{freeTitle} from {date}", and "{n} days to go. Then this ring stays full." "1 day"
is singular. From the quit date, YOU and AHEAD are hidden, every stage is behind you, and the second
line is "You reached your quit date", as on the plan card.

### 3.8 Motion

Rings fill with `FillIn` at `AppMotion.fill`. Opening a stage uses `AnimatedSize`. Reduce Motion
removes both.

## 4. Edit plan (frame N)

Replaces the page's content under the same route. `CostCard`, `ProjectionCard` and `QuitDateCard`
go, as nothing else uses them. `SetupScaffold` and the pinned footer stay.

Back, "Edit plan", "Turn it down. Not up." and "It does go up. I'd just rather not watch."

### 4.1 Daily limit dial

The number in the middle with "{units} a day" ("{unit} a day" at 1) and "One every {gap}", as in
3.5. A full ring is `R`,
the smallest multiple of 20 that is at least the larger of the plan's start limit and the value.

- dragging the ring sets the value, from 1 to `R`, and stops at both ends instead of wrapping
- − and + step by one, up to 80, and `R` follows
- each change is a selection haptic
- VoiceOver treats it as one adjustable control: "Daily limit, 9 sessions a day"

### 4.2 Quit date

The date on the right, a ruler, the chips, and the existing steep warning when `isSteep`.

**Ruler.** It starts today. It spans 17 weeks, or to 4 weeks past the selected date if that is
later; the span changes only when a chip or the wheel sets a date, so it never moves under a
finger. One tick a week, every 4th taller, up to 40 weeks; past that one tick every 4 weeks. Month
names sit under their first days.

- dragging sets the date to the nearest day, with a selection haptic on each tick
- it can't go before tomorrow
- tapping the date opens `showWheelPicker` for any later date, since a ruler can't reach every date

**Chips.** Keep current, Suggested, 8 wks, 16 wks, following the existing `EditQuitPreset` rules.
Keep current is hidden once the plan has reached its quit date. Dragging or using the wheel clears
the selection.

### 4.3 What that makes

"{n} stages · one fewer every {d} days" and a row of rings for each stage's limit, then 0 in success
colour. The first ring is in the accent and the others are dashed.

- `d` is `daysPerDrop`. Whole number: "every 7 days". Otherwise: "about every 5 days". Under 1.5:
  "dropping about every day". For a steep plan, where the limit falls by more than one a day:
  "dropping fast"
- more than 10 rings: the first 5, "…", then the last 4 including 0

### 4.4 Price card

Shown only when the habit tracks cost. Title "Price of a {container}", or "Price of one {unit}" with
no container.

- "Was {money}" on the right once the price differs from the stored one
- the price field with the currency symbol, and the units-per-container stepper when the habit has a
  container
- tiles once the price is valid: "One {unit}" and "At your old {baseline} a day", "{money} a year",
  rounded to whole units of money as onboarding does
- `ExhaleReply` when the unit price changes against a stored price. Up: "Up again? Almost like they
  want you to quit." Down: "Cheaper? Don't celebrate with one."
- fine print: "Counts from today. What you've saved so far stays as it is." With no stored price:
  "Counts from Day 1."
- "I'd rather not know" empties the field. Hidden when it is already empty

### 4.5 Your why and Change habit

Two outlined buttons. Your why opens a glass sheet with the existing text field and limits. Its Save
writes the reason at once through `UpdateHabit`, independent of the page. Change habit is unchanged.
The Your why card leaves the page, and `reason` leaves `EditPlanState`.

### 4.6 Saving

`planChanged` is limit ≠ today's limit or quit date ≠ the current plan's quit date.
`priceChanged` is price or units ≠ the stored ones.

| Case | Footer | On press |
|---|---|---|
| `planChanged` | "Shake on it again" | saves the price if changed, then starts a new plan today |
| only `priceChanged` | "Save price" | saves the price; **no new plan**, stage numbers stay |
| neither | "Shake on it again", disabled | none |

When `planChanged`, the footer caption is "Past days keep their limits. Stages start again at 1."
Otherwise there is no caption.

A press goes back on success. Two presses save once, using the existing `isSubmitting` guard. An
invalid price shows the existing error and saves nothing.

This fixes the bug in `EditPlanController.save`, which always calls `savePlan`.

## 5. Logs (frame T)

Replaces the page's content under the same route. `LogsPeriodCard`, `LogsDayCard` and `DayGroup`
go. `LogRow` stays, because Home's `TodayLogsCard` uses it. `logsViewProvider` stays as the data
source.

Back, + (neutral, as T draws it), "The evidence." and "You logged it, so it counts. Pick a day, any
day."

### 5.1 State

The page holds a mode (Week or Month), the shown period, a selected day and an optional trigger.

- **Opening:** from `LogsQuery`
  - no range: Week of today, today selected
  - one day: its Week, that day selected
  - a range that is a whole week: Week
  - any other range, such as History's All: Month of the range's end
  - the selected day is the period's last day, or today if earlier
  - `trigger` opens with that filter on
- **Stepping** with the arrows moves the period and selects its last available day.
- **Switching** Week and Month keeps the selected day and shows the period holding it.
- **Limits:** the earlier arrow stops at the period holding `earliestDayProvider`. The later arrow
  stops at the period holding today and is disabled there.

### 5.2 Calendar card

Week and Month switch; earlier arrow; title with chevron; later arrow.

- Title: "{Oct 27} – {Nov 2}" with "This week", "Last week" or "{n} weeks ago". Month: "November
  2026" with "This month", "Last month" or "{n} months ago".
- The title opens a row of month chips, from `earliestDayProvider`'s month to this month. It wraps.
  Picking one switches to Month, shows that month and closes the row.
- Weeks start on Monday, matching `PeriodRange.weekOf`.

**Cells:** a 38 pt ring with the date inside, not scaled with text, in a 48 pt target.

| Day | Ring | Tap |
|---|---|---|
| Plan day | fill `usedFraction`, coloured by `LimitStatus` | selects |
| A day at limit 0 with no logs | full, success colour, as `ProgressRing` | selects |
| Selected | accent background, on-accent ring and date | selected |
| Today | heavier date | selects |
| Before the plan, on or after `earliestDayProvider` | dashed track, no fill | selects |
| Earlier than that, or in the future | dashed track, muted, disabled | none |

VoiceOver: "{Nov 1}, {5} of {9}". The key (Under, At limit, Over) sits under the grid.

### 5.3 Period card

The period's label ("This week", or the month's name), "{logged} / {allowed} allowed", with
"({allowedByToday} so far)" when those differ. From `PeriodStats`, plan days only.

The pill compares `logged` with `allowedByToday`: "{n} under" in success colour, "{n} over" in
danger colour. A period with no plan days shows "Before your plan" and no pill.

**Trigger bar:** the period's triggers by count, using `Trigger.tint`, then None in the muted colour.
Hidden with no logs. Chips underneath, "{label} {count}", using `textTint`:

- tapping a chip filters by it; tapping it again clears
- the selected chip is filled and the bar's other segments dim
- the selected chip stays even at count 0, so it can always be cleared
- None is not tappable, as today (a `Trigger?` filter can't express it)

### 5.4 Day card

"Today · Sun, Nov 1" or "Sun, Nov 1" and the count on the right:

| Case | Text | Colour |
|---|---|---|
| Over | "{n} of {limit} · {over} over" | danger |
| Today, not over | "{n} of {limit} · {left} left" | success |
| Past, at limit | "{n} of {n} · at limit" | warning |
| Past, under | "{n} of {limit}" | success |
| Before the plan | "{n} logged · before your plan" | muted |

The slot bar has one segment for each of `max(limit, count)`: accent for used, danger past the
limit, track colour for unused. Hidden before the plan and at limit 0 with no logs.

### 5.5 The rail

Everything is placed by time, oldest first, from the logical day's start. So a log before waking
sits above "Woke up", and a 1:30 AM log sits after "Bed".

- **Woke up** and **Bed**, from the settings day window, as small muted marks
- **Log rows:** a trigger tile using `Trigger.icon` and `tint`, the time, the trigger's label ("No
  trigger" without one), and the note ("No note" without one)
- **Over logs:** those past the limit have a danger-tinted tile, and with no note read "Over the
  limit. Noted."
- **Limit reached here:** "{limit} of {limit}", in danger colour, placed just before the first over
  log. Only when there is one
- **Gaps between logs:** "{1 h 47 min}", with height `clamp(28 + minutes ÷ 5, 28, 120)`. The longest
  is in success colour with ". Longest today. Frame it." or ". Longest that day." Only with at least
  two gaps; the earliest wins a tie
- **Today:** a dashed "Next on schedule", with the time from `nextLogTimerProvider`, hidden whenever
  the timer is, then a dashed line, "Nothing here yet. Keep it that way."
- **A past day:** after the last log, "Then nothing. Well done, or asleep." With no logs, one row:
  "Nothing logged. Well done, or forgot."
- **Before the plan:** logs and gaps only; no marks and no limit

With a filter on, the rail shows only matching logs and no marks or gaps. With none: "No {trigger}
logs this day."

**Actions:**

- tapping a log opens `showLogEditorSheet`
- swiping left deletes, with the existing confirm and Undo. VoiceOver reads each row as "{time}. Tap
  to edit, swipe to delete." and offers Delete as a custom action
- + opens `showLogEditorSheet` on the selected day

Under the rail: "Forgot one? Tap + at the top to add it to this day. I'll pretend it was on time."
Hidden on a filtered day.

## 6. Failure and states

- **Loading:** an adaptive spinner under the back button, as Edit plan does now.
- **A failed read:** `LoadFailure` with a retry, on Plan details and Logs. A failed price read is a
  failed read.
- **A failed save:** Edit plan, the Your why sheet and a log's delete all use the existing danger
  snackbar. The form or sheet stays and its values are kept. Writing a price and its point is one
  transaction, so neither is left without the other.
- **Save order:** the price is saved first, then the plan, as today. If the plan fails, the price
  stays saved and a retry is safe.
- **Plan details and Logs** react to log and plan streams, so changes elsewhere show at once.

**Every surface:** the iOS look in `CLAUDE.md`, light, dark and all three accents, text up to the
app's 200% cap, 44 pt targets, Reduce Motion and Reduce Transparency. Rings and dots don't scale with
text, because the row beside them says the same thing.

## 7. Not in this work

- stage management and anything it adds
- multiple habits. `feat/multi-habit` will conflict on Logs when it resumes
- day-level interaction in the current stage's rings or dots
- a None filter
- showing price history anywhere
- an unsaved-changes prompt on Edit plan, which has none today
- finishing the Figma copy

## 8. Claude's calls, easy to reverse

**Reading the frames**

- "Missed" came from frame I, not K. K says "Days over", which is what this spec uses, so that open
  question is settled.
- The current stage is always open, as in Y and Z. K drew a chevron on it, but Y and Z came later.
- K's sample counts today in avoided and saved. This counts finished days only, as Home does, so
  the two screens can't disagree and logging can't lower "saved" mid-day.
- The Edit plan footer stays pinned, as now. N draws the page flat, so it can't show this.

**Filling gaps**

- The first price ever entered counts back to Day 1, and later ones count from today.
- "I'd rather not know" stops counting from today, and Home goes back to "—". Earlier savings are
  stored and return if a price is added again.
- Tapping Home's plan card opens Plan details.
- The earlier-plan labels in BEHIND YOU are not mocked.
- Dial scale `R`, ruler span, tapping the date for the wheel, and the more-than-10-rings rule.
- "Save price" for a price-only save, and the "Stages start again at 1" caption.
- Your why saves from its own sheet.
- Before-plan days stay selectable on Logs, because logs can exist there (`backfillDays`). T disabled
  them.
- Stepping a period selects its last available day. T kept the old selection, which could leave the
  day card outside the period shown.
- History's All opens Logs on the current month, since T has no All.
- A trigger filter narrows the rail only, and rings keep the whole day's counts.

**Copy written here, not in a frame**

- "You made it. Regrettably."
- the stage notes "Not one day over. Who are you?" and "{n} days over. It's over now too."
- "Cheaper? Don't celebrate with one."
- "Counts from Day 1."
- "Nothing logged. Well done, or forgot."
- "No {trigger} logs this day."
- "dropping fast"

## 9. Tests

**`PriceHistory` and saved money**

- the section 2.1 example
- the first point counts backwards
- a cleared stretch counts nothing, and a later price resumes
- a same-day change replaces the point
- a units-per-container change reprices from that day only
- a no-cost habit returns null
- `moneySavedCents` is null when cleared and returns when a price is added

**Migration.** A v9 fixture to the new version, following `_expectLatest`: a habit with a price gets
one point on its first plan's start day, and one without gets none.

**`PlanReport`**

- K's tiles from K's data: 546, 462, $184.80, and 1,008 without a plan. Used, avoided and days kept
  use the rules here, so they won't match K's samples exactly
- tiles equal Home's `avoided` and `moneySavedCents` for the same data
- BEHIND YOU plus the current stage's saved equals the total
- a replan: earlier stages listed, the cut-off stage's figures use its real days, unstarted stages
  gone, numbers restart, totals span both plans
- a replan above the baseline never gives a negative tile or "of"
- first day: 0 of 0 days kept, no BEHIND section
- from the quit date: no YOU or AHEAD
- each note rule, and its order
- no trigger hides Mostly

**Dot layout.** 15, 52, 53, 132, 133 and 365 days, with the frame's columns, size and rows.

**Edit plan**

- a price-only save leaves plan history unchanged and the stage number as it was
- a limit or date change starts one plan
- the footer's three states and the caption
- a price is recorded once from a save, and a same-day edit replaces it
- a failed save keeps the form
- two presses save once
- invalid price
- dial steps, drag stops at both ends, and `R` follows +
- ruler limits, and the span holds still during a drag
- Keep current hidden after the quit date
- no price card for a no-cost habit
- the reply's direction
- Your why saves alone

The existing `edit_plan_page_test.dart` is rewritten for the new page.

**Logs**

- each `LogsQuery` shape opens the right mode, period, selected day and filter
- arrows stop at both ends
- Week and Month keep the selected day
- month chips
- each cell state, including limit 0 and before the plan
- the period card's text, pill and no-plan-days case
- the filter, its count-0 chip, and clearing
- rail order: a log before waking, a log after bed, the limit mark, the longest gap and ties, one gap
  with no "Longest", today's marks, a past empty day, a before-plan day
- swipe delete and Undo
- + opens on the selected day

The existing `logs_page_test.dart` is rewritten. `logs_query_test.dart` stays, since the query does
not change.

**Across all three:** at 200% text, on an SE width, with no overflow.

Android-default widget tests miss iOS-only route behaviour, so tests that return Home or pop run as
iOS, as `7b55f5a` did.

**On a simulator, with Fawad's approval:** all three screens in light and dark, a replan's Behind
you, a price change, and the `lib/main_seed.dart` data for a long plan. Glass and scroll performance
stays with the real iPhone pass.
