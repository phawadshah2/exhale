# Stage management

Rules and mocks approved in chat by Fawad on 2026-11-02. Mocks: canvas
https://claude.ai/artifact/JaQJQ5meV7qTnZNeKiPkoK, frames AA to AD
(`design/8._plan_edit_logs/Stage*.dc.html`).

Build this after the Plan details, Edit plan and Logs pass, because a replan here relies on
frame K's earlier-stage view.

## 1. Purpose

Today a reduction plan is fixed: going over never changes later stages, and nothing notices a
pattern. The app should respond to repeated overs without punishing one bad day and without
hiding a change to the agreed quit date.

| Scenario | Name | Response |
|---|---|---|
| 1 | Occasional over-limit day | Continue. No change |
| 2 | One unsuccessful check | Hold the stage for 7 days, then notify |
| 3 | Two unsuccessful checks in a row | Plan review; the user approves any new timeline |
| 4 | Back near original use | Reassess the baseline; ask about recommitting; offer support |

History is always kept. Past days keep the limits they had when they were shown.

## 2. The check

A check runs when the app starts and whenever today's logical day changes while it is open.

**When a check is due.** Take the latest stage of the current plan that ended before today. A
check is due when all of these hold:

- the stage ended at least 7 days after the previous check's window end, if there was one
- the plan had run for at least 7 days by the stage's last day
- no review or reassess card is waiting for an answer

Stages that ended earlier are not checked. This is what limits short-stage plans to one check
per 7 days.

**Late opens.** If today is more than 2 days after the stage's end, store the check as `skipped`
and change nothing.

**Blocked stages** (Fawad, 2026-11-04). If a review or reassess card was still waiting when the
stage ended (answered on a later logical day), store the check as `skipped` too: the days after
the stage were shown unheld, and a hold would change them.

**The window** is the 7 logical days ending on the stage's last day. Use `PlanHistory.limitOn`
for each day's limit.

- `logged`: the logs in the window
- `allowed`: the sum of the window's limits
- `overDays`: days where the count is above that day's limit

**Failed** means `logged > allowed` and `overDays >= 2`. Anything else passes. This is what
separates scenario 1 from scenario 2: with one day over and the rest at the limit, the average
is over target but the check passes.

**Back near the start** means the check failed, the first plan started at least 14 days before
the window's end, and the average of the 14 days ending on the stage's last day is at least 90%
of `plans.first.startLimit`.

**Outcome**

| Result | Streak | Outcome |
|---|---|---|
| Passed | any | `passed`; streak resets to 0 |
| Failed and back near the start | any | `reassess` |
| Failed | 0 | `hold`; streak becomes 1 |
| Failed | 1 | `review` |

The streak is read from stored checks, newest first, counting `hold` rows until a `passed`,
`skipped`, `review` or `reassess` row. Stop at the plan's first check, so a new plan starts at 0.
A kept review therefore gives: hold, then review on the next failure, which is "two more failed
checks". There is never a second hold in a row without a review between them.

A result is stored once. Logs added or deleted later never reopen it, and a window with few or
no logs simply passes. Nothing asks about missing logs.

## 3. Holds

A hold is a 7-day pause inside the plan, not a new plan. The stage keeps its number, the stage
count stays, and later drops and the quit date all move exactly 7 days.

**Rule.** A hold starting on real day index `H` keeps the limit of `H − 1` for 7 days, and every
later day reads the taper 7 days earlier. Holds add up. `H` is always the day after the checked
stage's last day, including on a late open: the check is the first open since that stage ended,
so the days between were never shown.

**Example.** 12 a day from Oct 12, quit Jan 4, weekly drops. Stage 4 is 9 a day, Nov 2 to 8. A
hold starting Nov 9:

- Stage 4 runs Nov 2 to 15 (14 days), still "STAGE 4 / 12"
- Stage 5 (8 a day) starts Nov 16
- the quit date is Jan 11

**`ReductionPlan`** takes a list of holds.

- `quitDay` includes held days, so the stage pill, plan card, History and frame K read the true
  date with no change. The stored `plans.quit_day` stays as agreed.
- `totalDays` includes held days. `daysPerDrop` excludes them, so "same pace" stays the same.
- `limitOn`, `stages`, `stageOn`, `nextDropOn` and `plannedReduction` all follow from the new
  limit rule.
- `PlanValidation` and the taper chart see only drafts, which have no holds.

Editing the plan or replanning starts a new plan with no holds. The old plan keeps its holds, so
its past limits stay right.

**Keeping the original date** deletes the hold, so today's limit returns to the plan's. It is
offered only on the logical day of the check, so no limit the user has seen ever changes. After
that day, Edit plan is the way to change the date.

## 4. The review and reassess choices

Both sheets show each choice's new quit date before anything is saved. All dates and numbers are
worked out when the sheet opens.

`pace` is the current plan's `daysPerDrop`. Round the plan's length up to whole days.

**Review** (scenario 3):

| Choice | New plan from today | Selected at first |
|---|---|---|
| Start from your real number | Limit: the review sheet's average (5.3), at most 80. Length: limit × `pace` | Yes |
| Slow down | Limit: the checked stage's limit. Length: limit × `pace` × 2 | No |
| Keep my plan | None | No |

The checked stage's limit is used because the plan has already dropped by then: by the time the
review appears, the current limit is lower than the one that failed.

**Reassess** (scenario 4):

| Choice | New plan from today | Selected at first |
|---|---|---|
| Start again from N | N: the 14-day average, rounded up, at most 80. Quit date: the later of `suggestedQuitDay` and the current quit date | Yes |
| Keep my plan | None | No |

New plans go through `PlanHistory.replan`: stage numbers restart at 1, and frame K shows the
earlier plan's stages under Behind you. After Keep my plan, the streak restarts.

An unanswered card stays on Home and the plan carries on as it is. The app never chooses for the
user.

Replanning on the plan's own start day drops that plan, as `replan` already does. Its holds and
checks go with it.

## 5. Screens and copy

Cards sit under the ring on today only, in the slot `QuitReachedCard` uses in `ring_card.dart`.
At most one shows. A review or reassess card hides `QuitReachedCard` until answered.

The numbers below are the mock's example. Units come from `HabitWording`.

### 5.1 Hold card (AA)

- Title: "{next limit} can wait." On the last stage, where the next limit is 0: "Zero can wait."
- Body: "Last week came to {logged} against an allowed {allowed}, so you stay at {limit} for one
  more week. Nothing's lost." On a late open, "until {next drop}" replaces "for one more week".
- Tiles: Next drop {date}, "Was today" (or "Was {date}" on a late open). Quit date {date},
  "Was {date}".
- Buttons: "Keep {old quit date}" and "Got it".
- Fine print: "Keep {date} moves you to {next limit} today. You can choose it until tonight, then
  Edit plan is the way."

From the next logical day the Keep button and the fine print are gone and only "Got it" stays. A
hold card still unanswered when the next check runs is closed by that check.

### 5.2 Review card (AB)

- Title: "This pace isn't fitting."
- Body: "Two weeks over {limit} a day. The plan can bend, and you decide how." Use the checked
  stage's limit. When the two failed windows (5.3) had more than one limit, drop the number:
  "Two weeks over your limit."
- Button: "Review my plan". No dismiss.

### 5.3 Review sheet (AC)

`showAppDraggableSheet`, with scrolling at large text sizes.

- Title: "Let's look at the plan". Lead: "Not a telling-off. Just the numbers."
- Tiles, for the two failed windows: the review's own window and the window of the `hold`
  check before it (the newest earlier check of the plan, always a `hold` by the streak rule).
  These 14 days need not be in a row; a held week between them is left out (Fawad,
  2026-11-05). {logged} logged, {allowed} allowed, "About {average}" a day, rounded up.
- "What came up most": the top 3 triggers with counts in the same two windows, from
  `ProgressCalculator.triggerBreakdown`. Hide this when no log in those days has a trigger.
- The three choices of section 4. Each shows name, detail, date and change.
- Button: "Shake on it again", or "Keep my plan" when that is selected.
- Under the button: "Past days keep their limits. Stages start again at 1." With Keep selected:
  "We'll look again if two more checks run over."

**Detail lines:** "{limit} a day, one fewer every {n} days"; with Keep, "{today's limit} today, one
fewer every {n} days". When `pace` is under 1.5 days: "{limit} a day, dropping about every day".

**Change labels:** "No change"; "{n} weeks later" when the difference is a whole number of weeks;
otherwise "{n} days later".

### 5.4 Reassess card and sheet (AD)

The Home card matches the review card, not separately mocked:

- Title: "Back around where you started."
- Body: "About {average} a day lately. Nothing's been wiped."
- Button: "Have a look".

Sheet:

- Title: "Back around where you started". Lead: "About {average} a day these last two weeks. It
  happens, and none of this gets wiped."
- "Still yours": totals across all plans for avoided, saved and days kept, the same figures as
  frame K's tiles. Hide saved for a habit that does not track cost.
- The two choices of section 4, with the same detail lines, change labels and buttons as the
  review sheet.
- Support line for all habits, worded per habit in `HabitWording`:
  - nicotine habits: "If this keeps being hard, a doctor, pharmacist or local quit service can
    help."
  - every other habit: "If this keeps being hard, a doctor or local support service can help."
- Alcohol only, in ink and bold: "If you drink heavily, don't stop suddenly without medical
  advice. It can be dangerous."

No phone numbers, links or other medical claims.

### 5.5 Every surface

iOS look as in `CLAUDE.md`: `AppIcons`, `PrimaryButton`, the glass sheet with its Reduce
Transparency fallback, `showAppSnackBar`, no ink ripples, a selection haptic on choices. Reduce
Motion is respected, text scales to the app's 200% cap, tap targets are at least 44 pt, and
VoiceOver reads each choice's name, detail, date and change as one. Light, dark and all three
accents.

## 6. Data

Schema v11. The price-history migration in the screens pass takes v10.

**`plan_holds`:** `id`; `plan_id` (references `plans`); `start_day` (yyyy-mm-dd); `days` (7).
Unique on `plan_id`, `start_day`.

**`stage_checks`:** `id`; `plan_id` (references `plans`); `window_end_day` (yyyy-mm-dd);
`check_day` (yyyy-mm-dd); `outcome` (`passed`, `skipped`, `hold`, `review`, `reassess`);
`answered_at` (nullable). Unique on `plan_id`, `window_end_day`.

A card shows while its row is `hold`, `review` or `reassess` with `answered_at` null. "Got it",
Keep and a confirmed new plan set `answered_at`.

`PlanRepository.getHistory` loads each plan's holds. Rows of a plan dropped by `replan` are removed
with it.

Each of these runs in one transaction:

- a check that holds: its check row and hold row
- Keep on a hold: delete the hold and answer the check
- a new plan from a sheet: the plan and the answer

## 7. Failure

Repositories return `Result` and use `guardStorage`, like the rest of the app.

- **A check fails to read or write:** nothing changes and no card shows. It runs again at the next
  start or day change, and the transaction leaves no partial hold.
- **A button fails to save:** a snackbar, the card or sheet stays, and nothing has changed.
- **Two presses:** one save, guarded like `DealStep`.
- **No plan, or on or after the quit date with no ended stage to check:** no check.

## 8. Not in this work

- notifications or anything running in the background
- questionnaires about why
- any change to the limit from a single day
- a plan page card or a held-stage label on frame K (K just shows the stage's longer length)
- multiple habits. Checks hang off plans, so they should carry over, but that isn't designed here
- behaviour after quit date beyond what the last stage's check gives

## 9. Tests

**`ReductionPlan` with holds**

- the section 3 example, day by day around the hold
- two holds, a hold on the first and last stages, and a hold on stages under 7 days and over 7
  days
- `stages`, `stageCount`, `nextDropOn`, `quitDay`, `daysPerDrop`, `plannedReduction`
- a plan with no holds matches today's results

**The check, as a pure function over logs and history**

- one day over and the rest at the limit passes; two days over with the total over fails; two
  days over with the total under passes
- `logged == allowed` passes
- a window across short stages uses each day's limit
- no check under 7 days of plan; no check within 7 days of the last window; only the latest stage
  checked
- a stage ended 2 days ago checks, 3 days ago is `skipped`
- back near the start at exactly 90%, just under, and before 14 days
- a plan on target in its first stage is never reassess
- the streak: hold then review; passed in between; after Keep; across a new plan
- no check while a review card waits; a waiting hold card is closed by the next check

**The choices.** The AC and AD example dates (Feb 1, Mar 22, Jan 11; Feb 1, Jan 4), the 80 cap,
rounding, `pace` under 1.5 days, and the later-of rule.

**Migration.** A v10 fixture to v11, following `_expectLatest`.

**Widgets**

- each card and sheet in its states, light and dark
- Keep offered only on the check's day
- triggers hidden when none are tagged
- saved hidden for no-cost habits
- the alcohol line for alcohol only
- the review card hiding `QuitReachedCard`
- a failed save keeping the sheet open
- Android-default widget tests miss iOS-only route behaviour, so tests that return Home from a
  sheet run as iOS, as `7b55f5a` did

**On a simulator, with Fawad's approval:** a hold, a review and a reassess from seeded data.
