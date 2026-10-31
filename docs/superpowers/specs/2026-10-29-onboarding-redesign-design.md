# Onboarding redesign and pace guide: design spec

Date: 29 Oct 2026 · Branch: `feat/onboarding-redesign` · Status: approved 29 Oct 2026

## 1. Why

Today's onboarding is a habit picker and one long setup page (name, start
date, amount, price, quit date, your why). It works but it is crowded and
says nothing about what the app is. The redesign makes first launch short,
funny and clear: one question per screen, a sardonic voice, and a plan at
the end that the user believes in.

Success: a new user finishes in about a minute, gets the tone, and lands on
Home with everything Home needs, including wake and bed times for a new
pace guide.

Onboarding comes before M4 of the Home, Details and Logs roadmap because
M4 Task 4.1 (Add a habit) reuses its steps.

## 2. Design source

- Mockups: `design/7._onboarding/flows.html` (390 × 844 frames).
  - **Flow A · The excuse chat, black** is light mode.
  - **Flow A · App accent, dark** is dark mode.
  - Flow A · App accent, light and Flow B · The breath are rejected
    alternatives, kept for reference.
- Visual system: Obsidian Sanctuary (`lib/core/theme/app_palette.dart`) plus
  the new `emphasis` role (§6). iOS look rules from `CLAUDE.md` apply
  (Cupertino icons via `AppIcons`, `showWheelPicker`, haptics, no ripples).

## 3. Decisions

| Topic | Decision |
| --- | --- |
| Structure | Splash, then six steps in one `PageView`. |
| Voice | Sardonic but motivating. Jokes hit the habit and the excuses, never the person. No medical claims. |
| Chat motif | Exhale speaks in short chat bubbles (avatar + bubble) at the top of each step and replies to answers. |
| Stepper | Six thin segments, back chevron, a quiet `n/6` under them. Welcome is 1/6. When Cost is skipped the total is 5. |
| Skip | No Skip button. A tap on Welcome only skips its animation. "I'd rather not know" on Cost skips the price. |
| Language | English only at launch, no language picker. |
| Amount | One number per day. |
| Removed from onboarding | Name, start date (the plan starts today), "Your why". |
| Sleep | Wake and bed times feed only the pace guide. The day reset hour (default 4 AM) stays separate in Settings. |
| Colour | Light mode: ink buttons and bubbles, accent for state. Dark mode: accent for both (§6). |

## 4. Screens

Defaults are filled in, so Continue always works without typing.

### 4.0 Splash

First launch: the app icon tile (glyph in the accent) and the `exhale`
wordmark, a line "We need to talk.", three typing dots pulse once, then
the screen slides into Welcome (about 1.2 s). Returning users (an active
habit exists): the short splash goes straight to Home, as today.

### 4.1 Welcome (1/6)

- No back chevron.
- "You · Tonight 11:48 PM", then the user's excuses as sent chat bubbles
  ("just one more", "it's basically flavoured air", "I'll quit properly on
  Monday"), "Read 11:49 PM".
- Exhale replies: "Heard them all. Twice." / "How about a limit that gets a
  little smaller every day, until it hits zero?"
- Headline at the bottom: "Stop negotiating with your cravings." Body:
  "They're not your business partner. One tap to log, a limit that drops
  every day, and nothing leaves your phone."
- Button **Make a plan**; fine print "A behaviour tool, not medical advice."
- Animation: bubbles 0.4 s apart, typing dots, reply, headline slides up.
  A tap shows the end state. Reduce Motion shows it at once.

### 4.2 Habit (2/6)

- Exhale: "Let's start with the obvious." Title "What are we quitting?",
  lead "Pick the main one. You can add another later."
- 2-column grid of the 8 presets (icon + name), selected card in the accent
  with a check. Default: vaping.
- **Something else** (full width, dashed) expands name and unit fields in
  place; Continue needs both (existing `canContinue` rule).
- Each pick gets a one-line Exhale reply (§7).

### 4.3 Daily amount (3/6)

- Exhale: "Be honest. I can't help with a number you made up." Title
  "How many {units} on a normal day?"
- Big number with − / + and a drag ruler under it. Default: the habit's
  `defaultDailyAmount`.
- Dots grid: one dot per unit up to 12; above 12 each dot stands for
  `ceil(n / 12)` units, with the caption "Each dot is N {units}".
- Exhale reply by range (§7), updated as the number changes.

### 4.4 Cost (4/6)

Skipped when `habit.tracksCost` is false.

- Exhale: "Now the painful bit." Title "What does a {container} cost?"
  (habits without a container: "What does one {unit} cost?").
- Price card: currency chip (default from the locale, §5.2; tap opens a
  wheel of the currency list) and the amount field with the decimal pad.
- "{Units} per {container}" stepper when the habit has a container
  (default `defaultUnitsPerContainer`), with "Check the box. Or guess, we
  won't tell."
- Two tiles: "A month" and "A year" (the year in the warning colour),
  from `unitPriceCents × amount × 30` and `× 365`.
- Exhale reply: "Your rent is jealous."
- Link **I'd rather not know** clears the price and continues.
- Invalid price keeps the existing message ("Enter a valid price, or leave
  it empty.").

### 4.5 Your day (5/6)

- Exhale: "When are you awake? I'll spread your limit across it." Title
  "When does your day run?"
- Arc with the awake hours in the middle ("16 h awake"); dots along the arc.
- Two tiles, Wake up (default 7:30 AM) and Bedtime (default 11:30 PM). The
  selected tile opens an inline wheel (hour, minute in 15-minute steps,
  AM/PM).
- The waking window must be at least 4 h; the wheel will not settle on a
  shorter one.
- Note: "Used to pace your limit. Never to lock you out."

### 4.6 The deal (6/6)

- Exhale: "Here's the deal." Title "{amount} today. Zero by {date}."
- Taper chart from today's amount to 0 on the quit day, with date labels.
- Chips: **Suggested** (preselected), 4 weeks, 8 weeks, 3 months, Pick (wheel
  date picker). The steep-plan warning stays as today.
- Stats row: Tomorrow (tomorrow's limit), Quit in (days), Back a year
  (yearly cost; hidden when there is no price).
- Pace line: "Today that's about one every N min. It gets slower from
  here." (§8, using the chosen wake and bed).
- Button **Shake on it**; fine print "Change the plan any time from Home."
- Saving: §5.4. On success Home opens with the existing entrance.

## 5. Data and structure

### 5.1 Schema v9

`settings` gets two nullable integer columns, `wake_minute` and
`bed_minute` (minutes after midnight, 0–1439). Migration v8 → v9 adds them
as null. Null means not set (existing users). `AppSettings` gains
`wakeMinute` and `bedMinute` (`int?`). Run
`fvm dart run build_runner build -d` after the table change.

### 5.2 Currency default

No `intl`. A hand-written `CurrencyChoices` list of about 25 entries
(display string and the regions that use it), for example AED (AE),
SAR (SA), £ (GB), € (euro countries), $ (US), Rs (PK), ₹ (IN). The default
comes from the device locale's region; unknown regions fall back to `$`.
The chosen display string is stored in `currencySymbol` as today.

### 5.3 Structure

`lib/features/onboarding/presentation/`:

- `pages/onboarding_page.dart`: the step header and a `PageView` of the
  steps; back chevron and swipe back.
- `steps/`: `WelcomeStep`, `HabitStep`, `AmountStep`, `CostStep`,
  `DayStep`, `DealStep`. Each reads and writes the form provider only.
- `widgets/`: `OnboardingStepper`, `ExhaleBubble`, `YouBubble`,
  `DotsGrid`, `TaperChart`, `AmountRuler`, `CurrencyChip`.
- `providers/onboarding_form_provider.dart`: grows from `SetupFormState`
  (habit, custom fields, amount, price, units per container, quit preset
  and day) plus `wakeMinute`, `bedMinute`, `currency`; `steps` (the visible
  list, without Cost when the habit has no cost) and the `n/total` count.
- `onboarding_copy.dart`: every line of copy (§7).

M4 Task 4.1 Add a habit reuses `HabitStep`, `AmountStep`, `CostStep` and
`DealStep` in the same order, without Welcome and Your day.

Removed: `setup_page.dart`, `habit_picker_page.dart`, `cost_card.dart`,
`projection_card.dart`, `quit_date_card.dart`, `setup_chrome.dart` and
`drifting_particles.dart` if nothing else uses it. Routes `/setup` and
`/setup/plan` become one `/onboarding` route.

### 5.4 Saving

**Shake on it** keeps today's submit order: guard against a second habit,
save settings (wake, bed, currency), then `startTrackingProvider` with the
habit draft and the plan draft (start today). On failure the deal screen
shows the error under the button and keeps every answer. Onboarding is done
when an active habit exists (no new flag).

## 6. Colour role: emphasis

`ExhaleColors` gains `emphasis` and `onEmphasis`:

| Mode | emphasis | onEmphasis |
| --- | --- | --- |
| Light | ink (`#111418`) | white |
| Dark | accent (`primaryContainer`) | `onPrimaryContainer` |

Used for primary filled buttons app-wide (onboarding buttons, the Home +
button, sheet confirm buttons, Edit plan save), Exhale's bubbles and
avatar, stepper segments and the dots. The accent keeps state: selected
cards and chips, the ring, charts, accent text. The splash and avatar glyph
use the accent. Reverting means changing the light row only.

## 7. Copy

All copy lives in `OnboardingCopy`.

- Welcome: the excuse bubbles and reply in §4.1.
- Habit replies: vaping "Ah. The USB stick you inhale."; smoking "Classic.
  Retro, even."; pouches "Discreet. Your gums disagree."; alcohol "Cutting
  down, not cancelling weekends."; caffeine "Bold. Good luck with
  Mondays."; energy drinks "Your heart would like a word."; junk food
  "Fries are not a personality."; social media "Doomscrolling, meet your
  limit."; custom "Mysterious. We respect it."
- Amount reactions, by share of the habit's `defaultDailyAmount`: under
  half "Practically a hobby."; up to 1× "Respectable. For now."; up to 2×
  "That's not a habit. That's a part-time job."; above "That's a full-time
  job with overtime."
- Cost: "Your rent is jealous."
- Deal: "Here's the deal."

Copy is a first pass; it gets one rewrite before release.

## 8. Pace guide (Home)

A guide, never a lock, with no notifications.

### 8.1 Rule

Pure function `PaceGuide.compute(now, wake, bed, limit, countToday,
lastLogToday)`:

- `remaining = limit − countToday`
- window = wake to bed of the current logical day. A bedtime after
  midnight works. If the bedtime falls after the day reset hour, the window
  is cut at the reset.
- `even = (bed − wake) / limit`, the gap for the whole day
- `gap(from) = max(even, (bed − from) / remaining)`
- `pace = gap(max(now, wake))`
- `next = anchor + gap(anchor)`, with `anchor = max(lastLogToday ?? wake, wake)`

`next` is recalculated after every log, so it adapts: logging early stretches
later gaps. Waiting never shortens them below the even rate, because a guide
to cutting down must not suggest going faster (changed 2026-10-31).

### 8.2 Home line

Under the ring on the single-habit dashboard, updated each minute:

| Case | Shows |
| --- | --- |
| `next` in the future | "Next one on schedule in N min" |
| `next` passed | "You're on schedule" |
| Second line | "About one every N min until bed"; hidden when one gap would run past bed |
| At or over the limit | The existing over-limit state; no pace line |
| Limit 0 (quit day or later) | The quit-day state; no pace line |
| Before wake or after bed | Hidden |
| Wake/bed not set | One-time prompt "Set your day to get a pace guide", opens a Your day sheet |

Settings gets a "Your day" row (the same arc and wheel in a sheet).
Multi-habit Home cards get a compact "next in N min" in M4, from the same
function.

## 9. Suggested quit date

`ReductionPlan.suggestedQuitDay` was `max(7, startLimit × 7)` days, which
gives 840 days for 120 puffs. It becomes `startLimit × 7` days clamped to
14–90 (decided 29 Oct 2026). Existing plans are unchanged; only new
suggestions (onboarding, Add a habit, the Suggested chip in Edit plan) use
it. Part of phase 2.

## 10. Phases

1. **Emphasis role**: `ExhaleColors`, then primary buttons app-wide.
2. **Data**: schema v9, `AppSettings`, `CurrencyChoices`, the
   suggested quit date clamp.
3. **Onboarding flow**: steps, copy, stepper, splash hand-off, saving,
   old setup removed.
4. **Pace guide**: `PaceGuide`, the ring line, the prompt and the Settings
   row.

Then the Home, Details and Logs roadmap continues with M4, whose Task 4.1
reuses the steps.

## 11. Out of scope

Language selection and l10n, a "Less sarcasm" setting, the "Your why"
prompt on Home, reminders and notifications, onboarding analytics.

## 12. Testing

- Unit: form rules (Cost skip and `n/5`, dots scale, suggested date
  clamp at 14 and 90 days, presets, monthly and yearly cost), `CurrencyChoices` locale default, the
  v8 → v9 migration, `PaceGuide.compute` (midnight bedtime, cut at the
  reset hour, limit 0, over the limit, outside the window, no logs today).
- Widget: each step (defaults, Continue, replies, custom habit fields,
  "I'd rather not know", minimum window), the full flow ending on Home with
  the habit, plan and settings saved, the save error, the pace line cases,
  the "Set your day" prompt, the `emphasis` colours in light and dark.
- Existing setup and splash tests are migrated or removed with the old
  pages.
