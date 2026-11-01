# Home, Details and Logs: roadmap

Spec: `docs/superpowers/specs/2026-10-21-home-details-logs-design.md`
Engineering plan: `docs/superpowers/plans/2026-10-21-home-details-logs.md`
Designs: Figma https://www.figma.com/design/KMF3WeQgfFv5g2MhOiwXMM ·
canvas https://claude.ai/artifact/Es7ju6TWmMj5pkNon4tbHu

## Product goal

A vaping-first quit app people open several times a day: logging takes one
tap, Home tells them in a glance whether today is on track, and one scroll
down answers "am I getting better, and why do I slip?". The first release
tracks one habit; tracking several comes in a later release.

**Launch definition of done:** a new vaper can set up, log for a week, see
the week line and their top triggers, edit a wrong log, change their plan and
replace their habit with another, with no crash, in dark and light mode, on a
real iPhone.

**Scope change (decided by Fawad, 2026-10-31):** launch with one tracked habit.
Phase 4 moves out of the launch and ships in a later release (version not
fixed). The launch goes M3 and the onboarding redesign, then M5. The per-habit
data from M1 stays, so the later release needs no data migration for this.

## Before Phase 1

- Merge the open branches into `main` in order: `feat/liquid-glass`,
  `feat/habit-tracking`. Start `feat/home-details-logs` from `main`.
- Back up a real v7 database from the simulator into
  `test/fixtures/exhale_v7.sqlite` for the migration test (Task 1.2).

## Phases and milestones

| Phase | Milestone (demo) | User-visible? | Size | Ships alone? |
| --- | --- | --- | --- | --- |
| 1. Habits foundation | **M1:** app looks the same; data is per-habit; upgrade from today's build keeps every log | No | M | Yes |
| 2. Dashboard and Logs | **M2:** new one-habit Home (ring, impact, Week/Month/All, plan, why, today's logs) and the Logs page | Yes | L | Yes, as one-habit app |
| 3. Logging and editing | **M3:** + tap/hold, trigger sheet with habit, hint, Edit log, Edit plan | Yes | M | Yes |
| 3b. Onboarding redesign | **O1–O4:** emphasis colour, schema v9 (wake/bed), six-step chat onboarding, pace guide on Home. Plan: `2026-10-29-onboarding-redesign.md` | Yes | L | Yes |
| 5. States and launch polish | **M5:** every state from the "States" row, change habit, light mode, accessibility, release blockers, device QA | Yes | L | Release candidate |
| 4. Multiple habits (after launch) | **M4:** Add habit, multi-habit Home, Details with switcher, Logs "All", stop tracking | Yes | L | Later release |

Each milestone ends with: all tests passing, analyze clean, a simulator run
recorded in the PR, and Fawad's review before merging.

### M1: Habits foundation (exit criteria)

- `habits` table, plans and logs keyed by habit id, schema v8.
- Upgrading a real v7 database keeps the plan history and every log.
- Setup creates habit #1; every existing screen still works unchanged.

### M2: Dashboard and Logs

- Home for one habit is the dashboard in the spec order.
- The ring swipes through days; the History card swipes by week or month on
  its own; All shows the plan to the quit date.
- Every tap target in the ring and History opens Logs already filtered.
- Logs shows "allowed" per period and per day; swipe to delete with Undo.
- The day detail sheet is gone.

### M3: Logging and editing

- One habit: tap + logs, hold opens the menu; the hint shows once.
- Two habits (testable via a seeded second habit): tap opens the menu.
- Edit log sheet (glass, icons) and Edit plan page work end to end.

### Onboarding redesign (added 2026-10-29, before M4)

- Spec `docs/superpowers/specs/2026-10-29-onboarding-redesign-design.md`,
  plan `docs/superpowers/plans/2026-10-29-onboarding-redesign.md`.
- Comes first because M4 Task 4.1 reuses its Habit, Daily amount, Cost and
  The deal steps, and the old setup pages are gone afterwards.
- Exit: a new install goes splash → six steps → Home with the habit, plan,
  wake/bed and currency saved; upgrades from v3–v8 end on v9; the pace
  line shows under the ring.

### M4: Multiple habits (later release, not part of the launch)

Status: Tasks 4.1 to 4.3 are built and committed on `feat/multi-habit`, which
is not merged and stays parked. Task 4.4 and the M4 review are not done. When
this release is scheduled, bring the branch up to date with `main`, finish 4.4,
then run the review and a simulator walk (4.1 to 4.3 have never been seen on a
simulator).

- "Add a habit" creates a second habit with its own plan, through the
  onboarding steps (Habit, Daily amount, Cost, The deal).
- Home switches to the habit list with combined impact and recent logs.
- Details has back, the habit switcher and Edit plan; stop tracking
  archives a habit and Home falls back to the dashboard with one habit.

### M5: Release candidate

- States: over limit, before the plan, first day, quit reached.
- Change habit (Task 5.1b): from Edit plan, pick another habit and shake on a
  new deal. Backing out or a failed save keeps the old habit; wake, bed and
  currency stay as they are; old logs stay stored but hidden.
- Next-log timer (Task 5.1c): in the ring with hours, on the + button in minutes,
  one text under the ring; time left when logging early carries over.
- Light mode and Reduce Transparency checked on every new screen.
- 44 pt tap targets, VoiceOver labels on charts and trigger rows.
- Release blockers from the earlier roadmap: remove the Design system
  link; settings caption matches what Settings can do.
- No copy or path in the launch build offers a second habit (the hold hint
  says "start tracking another habit" today).
- Real iPhone pass: glass performance, chart scrolling with 90+ days.

## Scope cuts if time runs short (product owner call)

Cut in this order, each keeps the app coherent:

1. All-time 7-day average (show the daily line only).
2. Logs trigger filter chips (keep the period filters).

Never cut: the migration test, Undo on delete, Edit log, Edit plan.

## Risks

| Risk | Mitigation |
| --- | --- |
| Migration loses data for existing installs | Real v7 fixture test; migration runs in one transaction; manual upgrade test on the simulator |
| Charts slow with long history | Period summaries computed once per period provider; All-time uses at most one point per day, downsampled to weekly after 180 days |
| Glass cost on older iPhones | Reduce Transparency fallback already exists; measure on device in M5 |
| Scope creep from new chart ideas | Out-of-scope list in the spec; new ideas go to the post-launch backlog |
| Day boundary bugs (logs after midnight) | Review Focus item 1, tested in Phase 2 |
| `feat/multi-habit` drifts from `main` while M5 lands | Keep it parked and pushed; expect conflicts in `logs_page.dart`, `edit_plan_page.dart` and the dashboard widgets when it is brought up to date |

## Post-launch backlog

**Multiple habits (M4) comes first**, in a release after launch: the work is
partly built, see M4 above. Whether a second habit stays free is rechecked then
(the 2026-10-21 design said free).

Then: time-of-day insights, trend vs plan with projections, reminders, Home and
Lock Screen widgets with the Live Activity (below), Pro paywall (history beyond
30 days, insights), habit reorder, export.

### Widgets and Live Activity

Fawad wants the next-log timer on the Lock Screen and Dynamic Island (2026-10-31),
planned together with the widgets, as both need the same native target. Mockup:
`LockScreen` on https://claude.ai/artifact/NBe5B8VGM6iMXDaiuysb88

- Needs a Swift widget extension (WidgetKit, ActivityKit) and an App Group so the
  extension can read today's state; Exhale has neither today.
- The countdown can tick on its own from the `next` time, with no server.
- Limits to design around: iOS ends a Live Activity after about 8 hours, and
  starting one from the background needs a push server, which an offline app does
  not have. So it starts and refreshes only when the app is opened or a log is
  saved. Check these against the iOS version we target before planning.
- Open: whether a Log button on the Live Activity is worth writing to the database
  from the extension.
