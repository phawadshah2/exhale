# Home, Details and Logs: roadmap

Spec: `docs/superpowers/specs/2026-10-21-home-details-logs-design.md`
Engineering plan: `docs/superpowers/plans/2026-10-21-home-details-logs.md`
Designs: Figma https://www.figma.com/design/KMF3WeQgfFv5g2MhOiwXMM ·
canvas https://claude.ai/artifact/Es7ju6TWmMj5pkNon4tbHu

## Product goal

A vaping-first quit app people open several times a day: logging takes one
tap, Home tells them in a glance whether today is on track, and one scroll
down answers "am I getting better, and why do I slip?". Several habits work
from day one, free.

**Launch definition of done:** a new vaper can set up, log for a week, see
the week line and their top triggers, edit a wrong log, change their plan,
and add a second habit, with no crash, in dark and light mode, on a real
iPhone.

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
| 4. Multiple habits | **M4:** Add habit, multi-habit Home, Details with switcher, Logs "All", stop tracking | Yes | L | Yes |
| 5. States and launch polish | **M5:** every state from the "States" row, light mode, accessibility, release blockers, device QA | Yes | M | Release candidate |

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

### M4: Multiple habits

- "Add a habit" creates a second habit with its own plan.
- Home switches to the habit list with combined impact and recent logs.
- Details has back, the habit switcher and Edit plan; stop tracking
  archives a habit and Home falls back to the dashboard with one habit.

### M5: Release candidate

- States: over limit, before the plan, first day, quit reached.
- Light mode and Reduce Transparency checked on every new screen.
- 44 pt tap targets, VoiceOver labels on charts and trigger rows.
- Release blockers from the earlier roadmap: remove the Design system
  link; settings caption matches what Settings can do.
- Real iPhone pass: glass performance, chart scrolling with 90+ days.

## Scope cuts if time runs short (product owner call)

Cut in this order, each keeps the app coherent:

1. All-time 7-day average (show the daily line only).
2. Logs trigger filter chips (keep habit and period filters).
3. Recent logs on the multi-habit Home (cards + combined impact remain).
4. Phase 4 entirely: launch single-habit, hide "Add a habit", ship M4 as
   1.1. Phase 1 still lands first so 1.1 needs no data migration.

Never cut: the migration test, Undo on delete, Edit log, Edit plan.

## Risks

| Risk | Mitigation |
| --- | --- |
| Migration loses data for existing installs | Real v7 fixture test; migration runs in one transaction; manual upgrade test on the simulator |
| Charts slow with long history | Period summaries computed once per period provider; All-time uses at most one point per day, downsampled to weekly after 180 days |
| Glass cost on older iPhones | Reduce Transparency fallback already exists; measure on device in M5 |
| Scope creep from new chart ideas | Out-of-scope list in the spec; new ideas go to the post-launch backlog |
| Day boundary bugs (logs after midnight) | Review Focus item 1, tested in Phase 2 |

## Post-launch backlog

Time-of-day insights, trend vs plan with projections, reminders, widgets,
Pro paywall (history beyond 30 days, insights), habit reorder, export.
