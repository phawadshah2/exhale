# Current state

Updated 2026-11-15 (Lock Screen presence, Task 10 done). Earlier: `docs/history/` (latest
`2026-11-13_paywall_build_state.md`).

## Where we are

| Work | Status |
|---|---|
| M1 to M7, chat onboarding, paywall | Merged to `main` (`1fff6cb`, PRs 35 to 37) |
| Timer starts at the first log; tap opens today's logs | Done on `feat/timer-first-log` (3 commits), not pushed |
| Lock Screen presence (project 1 of 4) | `feat/lock-screen`, stacked on the timer branch: spec, plan, designs, Tasks 1 to 10 of 15 done |
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
- Task 1 (`d8cb4ed`): extension target, App Group, iOS 17, `NSSupportsLiveActivities`.
- Task 2 spike (`835449a`): Log one starts a Live Activity with the app terminated (via
  Shortcuts); the Action Button never reached the intent, recheck at the device walk.
- Tasks 3 to 5 (`e0c12a1`, `3bb43b2`, `daef015`): 14 pace cases (Swift ±1 ms); schema
  v13; 60 `encouragementLines` (53 drafts for Fawad to review at the walk).
- Tasks 6 to 8 (`143f4c0`, `654119b`, `95b9570`): `PresenceSnapshot.build`,
  `PresenceRepository` + `DrainExternalLogs`, `presenceSyncProvider`, `exhale://` links.
- Task 9 (`48747b9`): `ios/Shared` (synced into Runner + extension), Swift core.
- Task 10 (`af47f4e`): `PresencePlugin` (Runner group, registered in `AppDelegate`),
  `CountdownAttributes` in `ios/Shared`; removing from the queue reloads widgets too.
- Each task's as-built notes are under it in the plan.

## Checks

- Timer branch: format, analyze clean; app, Home, Logs, onboarding 590 passed.
- Task 1: simulator debug build OK, extension embedded (no Dart changes).
- Tasks 3 to 8: format and `analyze --fatal-infos` clean each time. Task 3 test 15/15;
  Task 4 migration + log repository tests 64/64; Task 5 test + `test/features/home/`
  274/274; Task 6 11/11; Task 7 presence + `test/app` 76/76; Task 8 presence, app,
  Home 360/360. Full suite not run (milestone end).
- Task 9: XCTests on iPhone 17 simulator, 16/16, `** TEST SUCCEEDED **` (2026-11-15).
- Task 10: XCTests 21/21, `** TEST SUCCEEDED **` (2026-11-15); red run skipped by Fawad.

## Next action

Task 11, the widgets (Sonnet 5.5 medium), via `execute-plan`. Read: the plan's header,
Task 11 and `design/11._lock_screen_presence/README.md`. Xcode test runs need Fawad's approval, one command each
(simulator iPhone 17 `8C3390A8-020F-41B0-9BB4-7798E769B720`; a run takes ~10 min).

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
- Presence: extension version 1.0 vs app 0.1.0 (Xcode warns; match before release); a
  drained log can count twice in widgets between snapshot write and queue removal; at
  the device walk check a cold start from a widget link and the Action Button.
- Earlier walk items: Reduce Transparency, 200%, priced drink in Edit plan; chat spec
  items waiting on Fawad; iPhone review list.
