# Current state

Updated 2026-11-14 (Lock Screen presence, Task 5 done). Earlier: `docs/history/` (latest
`2026-11-13_paywall_build_state.md`).

## Where we are

| Work | Status |
|---|---|
| M1 to M7, chat onboarding, paywall | Merged to `main` (`1fff6cb`, PRs 35 to 37) |
| Timer starts at the first log; tap opens today's logs | Done on `feat/timer-first-log` (3 commits), not pushed |
| Lock Screen presence (project 1 of 4) | `feat/lock-screen`, stacked on the timer branch: spec, plan, designs, Tasks 1 to 5 of 15 done |
| M4 Multiple habits | Parked on `feat/multi-habit` |

Before the real iPhone pass, Fawad wants (2026-11-14), in order: 1 Lock Screen presence
(Live Activity, Island, widgets, Log one from Siri and the Action Button), 2 Settings
redesign, 3 notifications (careful wording), 4 breathing exercise (likely the new tab).
Launch still needs Export/Import, iCloud sync, Stay at zero.

## Lock Screen presence

- Spec `docs/superpowers/specs/2026-11-14-lock-screen-presence-design.md`; plan
  `docs/superpowers/plans/2026-11-14-lock-screen-presence.md`; designs
  `design/11._lock_screen_presence/` (README maps the agreed files).
- Decided: queue + snapshot in the App Group (no DB move, no packages); minimum iOS 17;
  without access widgets lock and Log one opens the app; Live Activity goes quiet 15 min
  past due and keeps the Island; widgets 1 to 5, rings in design D (`Rings-v4.html`).
- Task 1 (commit `d8cb4ed`): `ExhaleWidgetsExtension` target, App Group on both targets,
  iOS 17 everywhere, `NSSupportsLiveActivities`, embed phase before Thin Binary. Portal
  steps done by Fawad. `ios/Shared` not made yet (see the plan's Task 1 note).

## Checks

- Timer branch: format and analyze clean; app, Home, Logs, onboarding tests 590 passed.
  Full suite not run.
- Task 1: `fvm flutter build ios --simulator --debug` built, extension embedded.
  No Dart changes, so no Dart checks.

## Next action

Task 6, the snapshot (Sonnet 5.5 medium). Done so far: Task 3 countdown cases, Task 4
schema v13, Task 5 lines of encouragement (53 new drafts in
`lib/features/presence/domain/encouragement.dart`, Fawad reviews them at the walk).
Spike (Task 2): Log one starts a Live Activity with the app terminated (iOS 27.2, from
Shortcuts); recheck the Action Button in the device walk. Fawad's iPhone runs release
builds over the cable.

## Repo

- `feat/export-import` (2 docs commits, `6b22bf4` and `4ae7705`, not on `main`) holds a
  newer copy of this file and of CLAUDE.md's Status; reconcile when either merges.
  Export/Import itself is not started.
- Untracked on purpose: `design/all-designs.html`, `design/figma-import/`.
- `stash@{0}` (splash hack) for simulator walks only.

## Open

- For Fawad: privacy policy URL; Terms link; `.storekit` check; submission items (group
  display name, review screenshots, Family Sharing, App Privacy).
- Paywall follow-ups (Fawad, 2026-11-14): show something when a purchase succeeds;
  Settings' Restore purchases has no loading state (the row only greys out while busy,
  then a snackbar) and shows even when entitled (decide whether to hide it then).
- Paywall review notes not fixed: sandbox Annual reads as a trial; Lifetime over Annual
  hides Manage; refunded "ended on" uses expiry; a resubmitted first run saves only the plan.
- Splash overflows at 200% on 375 × 667; paywall button 22 pt high there.
- Payment reminders spec (day 5) needed in the same release.
- Earlier walk items: Reduce Transparency, 200%, priced drink in Edit plan; chat spec
  items waiting on Fawad; iPhone review list.
