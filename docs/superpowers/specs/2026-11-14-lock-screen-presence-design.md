# Lock Screen presence

Agreed with Fawad on 2026-11-14. Designs: `design/11._lock_screen_presence/` (README lists
which file holds each agreed piece). Branch `feat/lock-screen`, stacked on
`feat/timer-first-log` (the widgets assume the countdown starts at the day's first log).

Project 1 of four pulled in before the real iPhone pass: then the Settings redesign,
notifications, and the breathing exercise.

## Why

Whenever someone picks up their phone, Exhale is in view: a reminder that they chose, and
paid, to quit. Logging must stay one tap, now without opening the app.

## Goals

1. **Live Activity** with the Dynamic Island, started by each log.
2. **Lock Screen widgets**: inline, circular, rectangular.
3. **Home Screen widgets**: five to pick from.
4. **Log one** without opening the app: one action offered by Siri, Shortcuts, the Action
   Button, a Control Center control, a Lock Screen control and the widgets' +.

## Non-goals

- No server, push, Firebase or analytics. Everything works offline.
- No trigger or note from outside the app. Those logs are plain, editable later in Logs.
- No Apple Watch, no StandBy-specific layout, no multi-habit widgets (launch tracks one
  habit; the widgets read the single habit).
- No notifications (project 3).

## Anti-goals

- Never nudge toward using: no "you can have one now", no alert when the countdown ends.
- Never lose or double a log made outside the app.
- Never show stale numbers as if live: when the data is old, say so or fall back to the
  count.

## Approaches

**How logs made outside the app reach the database.**

- Chosen: **a queue.** Swift appends each log to a small file in a shared App Group
  container; the app adds the queued logs to drift when it next runs, then clears them.
  The database stays where it is.
- Moving the drift database into the App Group container so Swift writes it directly:
  a migration with data-loss risk, two writers on one SQLite file, and Swift would still
  need the plan logic to show the right numbers.
- A plugin package (`home_widget`, `live_activities`): a dependency for what an
  in-house method channel already does in this app (`NativeUiPlugin` in
  `AppDelegate.swift`); still needs the Swift targets either way.

**How Swift knows what to show.** The app writes a **snapshot** (below) to the App Group
on every change. Swift reads it and replays the queue on top, so widgets and the Live
Activity are right after a Siri or Action Button log with the app closed. Swift carries a
small port of the countdown math (`PaceGuide.compute`), checked against shared cases.

**Live Activity end.** It keeps running past due (staying in the Dynamic Island) and goes
quiet through its stale date, instead of ending at the log with a dismissal date (exact
removal, but it leaves the Island at once). Fawad chose the Island.

## The pieces

### Live Activity (`LockScreen-v2.html`, Island from `LockScreen.html`)

- **Lock Screen card**, compact: "Exhale" and the countdown (system timer text) on the
  left; "4 of 8 today" and "next at 10:13 AM" on the right; a green bar draining with the
  gap; one line of encouragement in italics.
- **From 15 min past due** (the activity's stale date, no code runs): "On schedule" in
  place of the timer, the bar full and green, "41 days to go" in place of the next time,
  and a second line of encouragement.
- **Dynamic Island**: compact (draining ring, "1:12"), minimal (ring), expanded (count,
  countdown, next time, "+ Log one").
- **Lifecycle**: a log that starts a countdown starts the activity, or updates the
  running one. No countdown (at or over the limit, a limit of 0, before wake, no day
  window) ends it. Opening the app ends it if it is past its stale date. The day reset
  ends it. iOS's own 8-hour limit and the user's swipe also end it.
- **Lines of encouragement**: a list in the app (about 60, short, written for waiting;
  the 7 in `QuoteCard.quotes` join it). Each new activity picks two at random, never the
  previous pair. New lines ship with app updates.
- On by default. A "Show the countdown on the Lock Screen" switch in Settings (moves in
  the Settings redesign). iOS's own Live Activities switch also applies.

### Lock Screen widgets (`LockScreen.html` §3)

- **Inline**: "Exhale · 4 of 8 · 41 days to go".
- **Circular**: today's ring with "4/8".
- **Rectangular**: "4 of 8 today", "Next one at 10:13 AM" (or "8 left today" before the
  first log), "41 days to go".

### Home Screen widgets (`LockScreen-v2.html`, rings from `Rings-v4.html`)

1. **Today**, small: design D. "Today" and the stage pill on top, the ring with
   "4/8 today", the countdown ring around it while the timer runs, the counter
   bottom-left, "41 days" bottom-right, a glow in the day's colour.
2. **Countdown**, small: "Until your next", the live timer, the green bar, "4 of 8 / at
   10:13 AM", a + that logs.
3. **Your why**, small, dark: the reason from setup and the days to go. With no reason
   saved, it shows a line of encouragement instead.
4. **Today and the month**, medium: widget 1's ring column, the month with each day
   coloured, today outlined, a key (Under, At, Over).
5. **This week**, medium: seven bars against each day's limit, the week's total against
   its allowance, "5 of 6 days under".

Widget states (from `Rings-v4.html`):

| State | Ring | Corner counter |
|---|---|---|
| Counting | countdown ring drains | hourglass and the time left, ticking |
| Before the first log | no countdown ring | "8 left today" |
| Past the time on schedule | no countdown ring | "Waited +0:17", counting up |
| At the limit | amber, no countdown ring | "Limit reached" |
| Over the limit | red, no countdown ring | "1 over" |
| Quit day and after | days at zero in the ring | "41 days" becomes "Day 3 at zero" |

Colours: green under, amber at, red over (`LimitStatus`), on both light and dark. Tapping
a widget opens Home; widget 4's calendar and widget 5 open Logs for the week. iOS 18's
tinted and clear Home Screen styles render the ring and bar as accented shapes.

### Log one

- One App Intent, "Log one", with the phrase "Log one in Exhale". It runs without
  opening the app.
- Offered as: an App Shortcut (Siri, Shortcuts, Spotlight, the Action Button), a Control
  Center control and Lock Screen control (iOS 18), and the + on widget 2 and the expanded
  Island.
- It appends `{id (UUID), loggedAt}` to the queue, recomputes from the snapshot plus the
  queue, reloads every widget, and starts or updates the Live Activity.
- Its reply (Siri, the Island toast): "Logged · 5 of 8 today. Next one on schedule at
  12:21 PM." At or over the limit: "Logged · 9 of 8 today." Logging is always allowed.
- Undo: none from outside the app; the log shows in Logs, where swipe-to-delete works.

## Data shared with Swift

App Group `group.com.phawadshah.exhale`. Two JSON files, each written atomically
(`NSFileCoordinator` on the Swift side; temp file and rename from Dart).

**`snapshot.json`**, written by the app after startup, every log or edit, a plan or
settings change, and the day reset:

- `version`, `writtenAt`, `entitled` (the last known access is Entitled).
- Day settings: reset hour, wake minute, awake minutes (or none).
- The habit: name, kind, the reason (or none), the free-day wording.
- Daily limits from 62 days back to 62 days ahead (holds already applied), the stage
  number and count for each, the quit day.
- Each day's count for the same 62 days back, and today's log times.
- The Live Activity switch, the lines of encouragement, and the pair shown last (Swift
  picks the next pair when Log one starts an activity).

**`queue.json`**: the logs made outside the app, each `{id, loggedAt}`.

The app drains the queue on startup, on resume and when Swift signals a new entry (a
Darwin notification while the app runs): it inserts each entry not already stored (by
`id`, kept in a new nullable `external_id` column on logs, schema v13), writes a new
snapshot, then removes exactly the drained ids from the queue. A crash between insert
and removal re-drains safely because of the id check.

When the snapshot is older than its last limit day, or missing, widgets show "Open
Exhale to update" and Log one opens the app.

## Constraints

- Swift targets: a widget extension (widgets, Live Activity, controls) and the intent in
  the Runner app target so Siri runs it in the app's process when it is alive. Both need
  the App Group entitlement and signing under team `5W8A3P22WK`.
- Flutter ⇄ Swift through one method channel, `exhale/presence`, in the style of
  `NativeUiPlugin`: `writeSnapshot`, `startOrUpdateActivity`, `endActivity`,
  `drainQueue`. No new Dart packages.
- The countdown math exists twice (Dart and Swift). A JSON file of cases under
  `test/fixtures/pace_cases.json` is run by both the Dart tests and an XCTest target, so
  they cannot drift.
- Fawad asks first: builds and simulator runs mid-milestone, and any `pubspec.yaml`
  change (none planned). Apple Developer portal steps (App Group, the extension's App ID)
  are his.

## Order of work

1. **Spike** (throwaway, on Fawad's iPhone): can an App Intent started from the Action
   Button with the app closed start a new Live Activity? The answer decides whether Log
   one starts the activity or only updates a running one (if not, the first log of a
   session made outside the app shows on widgets only).
   **Result (2026-11-14, iPhone, iOS 27.2): yes.** A `LiveActivityIntent` run from
   Shortcuts started a new activity both with the app open and after a force-quit
   (`Activity.request` succeeded, activities enabled). Log one starts the activity. The
   Action Button did not run the first build's intent; check it again in the real-device
   walk.
2. App Group, the extension target, the channel, the snapshot writer, queue drain and
   `external_id` (v13).
3. Lock Screen and Home Screen widgets.
4. Log one (intent, App Shortcut, controls, widget +).
5. Live Activity and the Island; the Settings switch; the lines of encouragement.
6. Milestone review, full suite, real-device walk.

## Left to the builder

- Widget refresh timelines: entries at the next due time, due + 15 min, and the day
  reset, plus a reload on every change.
- Exact widget sizes on each iPhone width, Dynamic Type limits inside widgets, VoiceOver
  labels (spoken like the Home ring: "Next one on schedule in 1 h 13 min. 4 of 8 today").
- Writing the ~60 lines of encouragement (Fawad reviews them).
- Icons: SF Symbols matching `AppIcons`.

## Decided by Fawad (2026-11-14)

1. **Minimum iOS 17** (was 15) for the app and the extension. Control Center and Lock
   Screen controls are guarded for iOS 18.
2. **Without access** (the snapshot's last known access is not Entitled: never paid or
   lapsed): every widget shows "Exhale is locked" with the app's lock look and opens the
   app; Log one writes nothing and opens the app; no Live Activity starts. The hard
   paywall holds outside the app too.
