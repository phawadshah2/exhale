# Home, Details and Logs: design spec

Date: 21 Oct 2026 · Branch: `feat/home-details-logs` · Status: awaiting review

## 1. Why

Home tried to be both a quick glance and an analysis screen, and became
crowded: two navigations for one selected day, a tall chart card and log
buttons under every day. This redesign splits the jobs:

- **Home** answers "how am I doing today?" at a glance.
- **The habit dashboard** (Home with one habit, Details with several) holds
  history, the plan, impact and today's logs.
- **Logs** holds every log, filterable by habit, period and trigger.

It also prepares the app for several habits at once (free at launch).

## 2. Design source

- Live canvas (private until shared from its Share menu):
  https://claude.ai/artifact/Es7ju6TWmMj5pkNon4tbHu
- Figma (editable frames, same screens in 4 sections; glass blur shows as
  flat translucent fills there):
  https://www.figma.com/design/KMF3WeQgfFv5g2MhOiwXMM
- Copy in the repo: `design/6._home_details_logs/` (one `*.dc.html` per
  screen, `README.md` maps files to screens).
- Visual system: Obsidian Sanctuary (`lib/core/theme/app_palette.dart`),
  Manrope and Plus Jakarta Sans, current Liquid Glass for the tab bar, the +
  button, sheets, menus and the hint. Light mode follows the same layouts.

Board names below match the canvas.

## 3. Navigation

| Route | Screen | Notes |
| --- | --- | --- |
| `/home` | Home | One habit: the habit dashboard. Two or more: the habit list. |
| `/habit/:habitId` | Habit dashboard | Pushed from a habit card; back button, habit switcher. |
| `/logs` | Logs | Query: `habit` (id or `all`), `from`, `to`, `trigger`. |
| `/habit/:habitId/plan` | Edit plan | From the dashboard's tune button. |
| `/add-habit` | Add a habit, step 1 → step 2 | Step 2 is the existing plan screen. |
| sheets | Trigger sheet, Edit log, + menu, hint | Glass sheets, no routes. |

The tab bar stays Home and Settings. The day detail bottom sheet is removed;
Logs replaces it.

## 4. Screens

### 4.1 Home, one habit (`Main`)

The habit dashboard (4.3) with a greeting header instead of the back bar:
avatar with day badge, date, "Good afternoon". No Add habit button on the
page; it lives in the + menu (4.8).

### 4.2 Home, two or more habits (`HomeMulti`)

1. Greeting header.
2. "Today's habits · N active".
3. One card per habit, ordered by creation. The whole card opens that
   habit's dashboard; no buttons. Card: icon, name, stage and daily limit,
   status chip (On track / At limit / Over limit / <habit>-free), today's
   count "4 / 9 cigarettes", "5 left today", a progress bar coloured by
   status, "Last: 1h 42m ago", "Drops to 8 in 3d", chevron.
4. Combined impact: money saved across habits; "All on track" streak
   (days where every habit was within its limit); avoided per habit (units
   are never summed across habits).
5. Recent logs: the latest 6 across all habits (habit icon and name, time,
   trigger chip), "See all logs" → Logs with `habit=all`.
6. Daily quote.

### 4.3 Habit dashboard (`Main`, `Details`)

One widget, two headers. Sections in order:

1. **Header.** Home: greeting. Details: back, habit switcher pill
   (lists active habits), tune button → Edit plan.
2. **Stage pill**: habit icon, "Vaping · Drops to 10 in 4d", "STAGE 2 / 9".
   After the quit date: "Vape-free since Jan 12", "QUIT".
3. **Ring card** (4.4).
4. **Impact tiles**, 2×2: Streak, Vs baseline, Money saved, Avoided.
   Money saved without a price shows "—" and "Add a price ›" (Edit plan).
5. **History card** (4.5).
6. **Your plan**: progress bar start → quit with "22% of the way", current
   stage (now), next stage with start date, quit date with days to go.
7. **Your why** (only when set).
8. **Today's logs**: first 3 of today, "+N more today · See all logs",
   header link "See all logs" → Logs for this habit and today.

### 4.4 Ring card

- Title "Today's Consumption" with status badge on today; the date
  ("Tuesday, Oct 20") and a "Today ›" chip on other days.
- Ring as today (gradient, overflow arc when over). Centre: "4 / 11",
  "7 left today" (past day: "1 under limit"), "36% of daily limit".
- Swipe or ‹ › to move between days; › disabled on today, ‹ disabled on the
  earliest day (30 days before the plan's first day). Light haptic per step.
  The ring is independent of the History card.
- Below the divider: "Last entry" (relative time and clock time) and
  "Last trigger" (with note). Past days: "Limit that day" and "Status".
- **Today's triggers** (or "That day's triggers"): up to 3 rows with bar,
  count and percent, each with a chevron. Tapping opens Logs filtered to
  that habit, that day and that trigger. Shown on over-limit days too.
- States (canvas row "States"):
  - Over limit: coral badge and headline, a short supportive note
    ("A harder day. Tomorrow starts fresh at 11…"), triggers kept.
  - Before the plan: no limit, neutral ring, "Before your plan".
  - First day: empty ring, "No sessions logged today. Nice start.",
    dashed placeholder for triggers.
  - After the quit date: full green ring, "9 days vape-free", card "You
    reached your quit date" with "Keep at zero" (default) and "New goal"
    (opens Edit plan).

### 4.5 History card

- Header "History" with Week | Month | All.
- Week and Month: ‹ period label › ("This week", "Oct 12 – 18",
  "October 2026"); swipe also moves between periods. Back to 30 days before
  the plan; not into the future. All: "Since Oct 10 · day 12 of 95".
- Total line: "23 / 77 allowed" and an under/over pill ("10 under",
  "3 over"). Nothing else.
- **Week**: smooth line with gradient fill, weekday letters on top, value
  under each point, dotted limit line labelled at the right, faint guides,
  future days dashed. No day is highlighted by default.
- **Month**: calendar of day rings (Mon-first). Each ring fills toward that
  day's limit; colours: under accent, at limit amber, over coral, before
  plan faint, future dashed, today's number in accent. Colour key below.
- **All**: x-axis from the plan's first day to the quit date (extends to
  today once the quit date has passed). Plan drawn as a dotted staircase to
  zero, a "Today" marker and a "Quit" flag. Under 14 days: one daily line.
  From 14 days: bold 7-day average with fill plus a faint daily line;
  legend "7-day average · Each day · Your plan".
- Stats line for every period: "Avg 7.7/day · 0 days over · 3 days on
  track".
- Top triggers for the shown period, at most 3 chips with percent, plus
  "All triggers ›" → Logs with that period and habit.
- Taps: a day (point or ring) → Logs for that habit and day. A trigger chip
  → Logs for that habit, period and trigger. Each day has a full-height tap
  column (44 pt minimum).
- The old bar chart code stays in the repo, unused.

### 4.6 Logs (`Logs`, `LogsFiltered`)

- Bar: back, "Logs", + (add a missed log).
- Habit tabs: All · each habit (hidden with one habit).
- Active filter chips (day or period, trigger), each removable.
- Period card: ‹ period ›, "23 logged", "77 allowed this week · 33 by
  today", under/over pill, progress bar. All triggers for the period as
  chips with count and percent; tapping one filters. Opened from a ring
  trigger, the card instead reads "2 of 4 logs today · 50%" with
  "Allowed today: 4 of 11 used · 7 left" and a split bar.
- Day groups, newest first: header with status dot, "Today · Wed, Oct 21",
  "4 of 11 allowed" (or "13 of 11 allowed · 2 over", "0 of 12 allowed").
  With `habit=all`, headers show per-habit counts and no combined limit.
- Rows: trigger icon tile, time, note (or "No note"), trigger chip.
  Tap → Edit log sheet. Swipe left → Delete with confirm and Undo.
- Long days collapse after 3 rows ("Show 7 more"). Empty days show a
  dashed "Add a missed log for this day". Earlier days load on scroll.

### 4.7 Edit log sheet (`EditLog`)

Glass sheet: "Edit log", habit and date, Time row (wheel picker), trigger
grid with icons (that habit's triggers), note field, "Save changes",
"Delete this log". The same sheet in add mode is "Add missed log".

### 4.8 The + button and hint

- One habit: tap logs (trigger sheet if "Ask for a trigger" is on, else an
  instant log with Undo snackbar). Hold opens the menu: "Log now", "Add a
  missed log", "Add a habit".
- Two or more habits: tap opens the menu: each habit with "4 of 9 today"
  (at-limit in amber), "Add a missed log", "Add a habit". Choosing a habit
  opens its trigger sheet.
- Trigger sheet (`TriggerSheet`): habit chip "Smoking · 5 of 9 after this",
  "What triggered this one?", trigger grid with icons, "Save" and "Save
  without trigger". First-ever log still offers "Ask every time".
- One-time hint (`StateHint`), shown after the user's first log with one
  habit: glass bubble above + "Hold + for more · Add a missed log, or start
  tracking another habit", "Got it". Stored in settings.

### 4.9 Add a habit (`AddHabit`)

Step 1: picker grid like setup; habits already tracked are shown as
"TRACKING" and disabled; optional "Why this one?". Step 2: the existing
plan screen. Saving creates the habit and its first plan and returns Home,
which now shows the multi-habit list.

### 4.10 Edit plan (`EditPlan`)

Habit summary, notice "Changes start today. Past days keep the limits they
had.", daily limit from today (stepper), quit date card with presets ("Keep
current", "Suggested", 8 and 16 weeks) and the projection line, cost (price
per container or unit, units per container), your why, "Save changes",
"Stop tracking <habit>" (archives; logs kept; can be added again).
Saving starts a new plan from today (existing `PlanHistory.replan`).

## 5. Rules

- **Allowed** for a period = sum of each day's limit from the plan in force
  that day, from the later of the period start and the plan's first day,
  to the period end. "By today" stops at today.
- **Under / over** = allowed by today − logged in the period (completed days
  plus today).
- **Avg/day** = logged ÷ tracked days in the period (today included).
- **On track** = days with count ≤ limit; **over** = count > limit.
- **Streak** per habit = consecutive days within limit ending today.
  **All on track** streak = consecutive days where every active habit was
  within its limit.
- **Vs baseline, Avoided, Money saved** as today, per habit; Money needs a
  price; habits without cost (social media) hide money.
- **Trigger percent** = logs with that trigger ÷ logs in scope; "No
  trigger" counts as its own entry in Logs but not in the top 3.
- **Before the plan**: up to 30 days of back-fill, no limit, excluded from
  every stat and total.
- **Quit reached**: the limit stays 0; slips are logged and never reset the
  plan. "New goal" opens Edit plan.
- **Ask for a trigger** stays one global setting.

## 6. Data model (schema v8)

New table `habits`:

| Column | Type | Notes |
| --- | --- | --- |
| `id` | int, PK | |
| `kind` | text | `HabitKind.name` |
| `custom_name`, `custom_unit` | text, nullable | custom habits |
| `reason` | text, nullable | |
| `price_cents` | int, nullable | per container or per unit |
| `units_per_container` | int | default 20 |
| `created_at` | datetime | order on Home |
| `archived_at` | datetime, nullable | "Stop tracking" |

Changes:

- `plans.habit_id` (FK, not null); the unique key on `start_day` becomes
  unique on (`habit_id`, `start_day`).
- `habit_logs.habit_id` (FK, not null) replaces `habit_kind`.
- `settings` drops the habit, reason and price columns; adds
  `log_hint_seen` (bool, default false).

Migration v7 → v8:

1. Create `habits` and insert the current habit from settings (kind,
   custom name and unit, reason, price, units) as id 1.
2. Point every plan and every log at habit 1. A v7 log's `habit_kind` came
   from the column default, so it is ignored.
3. Rebuild `settings`, `plans` and `habit_logs` without the moved columns.

Code: a `features/habit` data layer (repository, use cases: add, update,
archive, watch active); plan and log repositories take a `habitId`;
providers become families keyed by habit id; a `currentHabitsProvider`
drives Home.

## 7. Code changes (outline)

- Home: `HomePage` chooses dashboard (one habit) or `HabitList`.
- Dashboard widgets: `StagePill`, ring card (from `DayCard`, keeps the
  pager), impact tiles (`StatsGrid`), `HistoryCard` rewritten with
  `WeekLineChart`, `MonthRingCalendar`, `AllTimeChart`, plan card, why card,
  today's logs preview.
- New `features/logs`: `LogsPage`, filters, period card, day groups.
- Sheets: trigger sheet gains the habit chip; Edit log restyled; + menu
  lists habits; hint overlay.
- Edit plan and Add habit pages.
- Removed: `day_detail_sheet.dart`, the ring↔chart selected-day link.
- Kept unused: `history_chart.dart` (bars).

## 8. Out of scope

Time-of-day insights, reminders, widgets, the Pro paywall, reordering
habits, exporting data, iPad layouts.

## 9. Testing

- Unit: allowed / under / avg / on-track per period, All-time series (daily
  vs 7-day average switch), combined streak, trigger percentages, migration
  v7 → v8 on a real v7 database (plans and logs land on habit 1, settings
  columns dropped).
- Widget: one-habit Home shows the dashboard; two habits show the list;
  card opens the dashboard; + tap vs hold; menu habit → trigger sheet with
  the habit chip; ring trigger → Logs with the right filters; bar/day and
  chip taps; Week / Month / All switch and stats line; Logs filters, swipe
  to delete with Undo, Show more, add missed log; Edit plan saves a new plan
  from today; Add habit flow; hint shows once.
- Manual on the simulator: dark and light, both accents, Reduce
  Transparency.
