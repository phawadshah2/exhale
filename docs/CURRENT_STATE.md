# Current state

Updated 2026-11-18 (Lock Screen presence, Task 15 Steps 1 and 2 done). Older logs: `docs/history/`.

## Where we are

| Work | Status |
|---|---|
| M1 to M7, chat onboarding, paywall | Merged to `main` (`1fff6cb`, PRs 35 to 37) |
| Timer starts at the first log; tap opens today's logs | Done on `feat/timer-first-log` (3 commits), not pushed |
| Lock Screen presence (project 1 of 4) | `feat/lock-screen`, stacked on the timer branch: spec, plan, designs, Tasks 1 to 14 of 15 done |
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
- Task 1 (`d8cb4ed`) the extension target and App Group. Task 2 spike (`835449a`): Log one
  starts a Live Activity with the app terminated (via Shortcuts); the Action Button never
  reached the intent, recheck at the device walk.
- Tasks 3 to 5 (`e0c12a1`, `3bb43b2`, `daef015`): 14 pace cases (Swift ±1 ms); schema
  v13; 60 `encouragementLines` (53 drafts for Fawad to review at the walk).
- Tasks 6 to 8 (`143f4c0`, `654119b`, `95b9570`): `PresenceSnapshot.build`,
  `PresenceRepository` + `DrainExternalLogs`, `presenceSyncProvider`, `exhale://` links.
- Tasks 9 to 11 (`48747b9`, `af47f4e`, `e841c4d`, `d91e33a`): Swift core in `ios/Shared`;
  `PresencePlugin`; `PresenceTimeline`, Lock Screen trio, widgets 1 to 5 (2's + is Task
  12). Fawad's ring: thin drawn countdown ring inside, timer alone under it (5 min steps).
- Task 12 (`5692502`): `LogOneIntent` in both targets (`WIDGET_EXTENSION` hides app-only
  parts), App Shortcut, iOS 18 control, widget 2's +.
- Task 13 (`852cf6d`): `CountdownActivity` (card, quiet state, Island); its screenshots
  wait for the Task 15 walk (the simulator froze mid-walk).
- Task 14: "Show the countdown on the Lock Screen" switch in Settings (own card after
  Your day); settings page tests 7/7.
- Each task's as-built notes are under it in the plan.

## Checks

- Timer branch: format, analyze clean; app, Home, Logs, onboarding 590 passed.
- Tasks 3 to 8 (format, analyze clean): 15/15; 64/64; 274/274; 11/11; 76/76; 360/360
  (each task's files, listed in the plan). Full suite not run (milestone end).
- XCTests, iPhone 17 simulator, `** TEST SUCCEEDED **`: Task 9 16/16; Task 10 21/21;
  Task 11 24/24 twice (2026-11-18, around the ring change); Task 12 29/29 (2026-11-18).
- Task 11 simulator: widgets render; state × appearance matrix and trio at Task 15.

## Next action

Task 15 Step 3, the walk with Fawad: each widget, Siri, the Action Button, Control
Center, the Island, a lapsed walk (`FAKE_STORE=lapsed`), airplane mode; plus the Task 11
state matrix and Task 13 screenshots. Then Step 4 (close the milestone). Steps 1 and 2
done 2026-11-18:

- Review: Review Focus 1 to 5 hold in the code; no blocking findings. Minor, not fixed:
  opening the app re-picks the activity's lines (Dart doesn't know Swift's pair); two
  Swift Log ones in a row both avoid the snapshot's `lastPair`, not the pair just shown;
  `removeFromQueue` reloads widgets milliseconds before the new snapshot (could show one
  fewer briefly).
- Full suite 1510/1510. Task files: deep link 5, migration 49, pace cases 15, channel
  repository 8, drain 7, encouragement 5, snapshot 11, sync 10, settings page 7, log
  repository 15. XCTests `** TEST SUCCEEDED **` (count not captured).
- Simulator walk: app runs entitled and Home renders, but injected input dropped again
  (tap timeouts on the trigger sheet), so nothing past Home was walked.

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
  Settings' Restore purchases has no loading state and shows even when entitled.
- Paywall review notes not fixed: sandbox Annual reads as a trial; Lifetime over Annual
  hides Manage; refunded "ended on" uses expiry; a resubmitted first run saves only the plan.
- Splash overflows at 200% on 375 × 667; paywall button 22 pt high there.
- Payment reminders spec (day 5) needed in the same release.
- Presence: extension version 1.0 vs app 0.1.0 (Xcode warns; match before release); a
  drained log can count twice in widgets between snapshot write and queue removal; at
  the device walk check a cold start from a widget link and the Action Button.
- Earlier walk items: Reduce Transparency, 200%, priced drink in Edit plan; chat spec,
  iPhone review list. iPhone 17 sim froze 2026-11-18 (Flutter stopped redrawing).
