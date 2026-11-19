# Current state

Updated 2026-11-18 (Lock Screen presence milestone closed). Older logs: `docs/history/`.

## Where we are

| Work | Status |
|---|---|
| M1 to M7, chat onboarding, paywall | Merged to `main` (`1fff6cb`, PRs 35 to 37) |
| Timer starts at the first log; tap opens today's logs | Done on `feat/timer-first-log` (3 commits), pushed, no PR yet |
| Lock Screen presence (project 1 of 4) | Closed 2026-11-18 on `feat/lock-screen`, stacked on the timer branch, pushed, no PR yet |
| M4 Multiple habits | Parked on `feat/multi-habit` |

Before the real iPhone pass, Fawad wants (2026-11-14), in order: 1 Lock Screen presence
(done), 2 Settings redesign, 3 notifications (careful wording), 4 breathing exercise
(likely the new tab). Launch still needs Export/Import, iCloud sync, Stay at zero.

## Lock Screen presence (closed)

- Spec `docs/superpowers/specs/2026-11-14-lock-screen-presence-design.md`; plan
  `docs/superpowers/plans/2026-11-14-lock-screen-presence.md` (as-built notes under each
  task); designs `design/11._lock_screen_presence/`.
- Built: App Group queue + snapshot, Swift `PaceGuide` port, widgets 1 to 5 and the Lock
  Screen trio, Log one (Siri, Shortcuts, Action Button, iOS 18 controls, widget and Island
  +), the countdown Live Activity and Island, the Settings switch (temporary row; its
  place comes with the Settings redesign, Fawad 2026-11-18).
- Review: Review Focus 1 to 5 hold. Minor, not fixed: opening the app re-picks the
  activity's lines (Dart doesn't know Swift's pair); two Swift Log ones in a row both
  avoid the snapshot's `lastPair`, not the pair just shown; `removeFromQueue` reloads
  widgets milliseconds before the new snapshot (could show one fewer briefly).
- Checks: full suite 1510/1510 (before the walk fixes); Home 272/272 after them; format,
  analyze clean; XCTests `** TEST SUCCEEDED **`.
- Walk on Fawad's iPhone: all passed after two fixes (`3385ed8` Island margins,
  `c413a8f` Home ring opens the day's logs at or over the limit). Lapsed walk passed on
  a debug build: `FAKE_STORE` is ignored in release builds.

## Next action

Settings redesign (project 2) on `feat/settings-redesign`, stacked on `feat/lock-screen`:
spec `docs/superpowers/specs/2026-11-19-settings-redesign-design.md`, plan
`docs/superpowers/plans/2026-11-19-settings-redesign.md` (9 tasks), design
`design/12._settings/`. Tasks 1 to 3 done; next Task 4 (plan tile and shortcuts)
with `execute-plan`. Spec Open: "New day
starts", feedback address, legal URLs, App Store ID. Fawad merges the timer PR, then Lock
Screen (both pushed).

## Repo

- `feat/export-import` (2 docs commits, `6b22bf4` and `4ae7705`, not on `main`) holds a
  newer copy of this file and of CLAUDE.md's Status; reconcile when either merges.
  Export/Import itself is not started.
- Untracked on purpose: `design/all-designs.html`, `design/figma-import/`.
- `stash@{0}` (splash hack) for simulator walks only.

## Open

- For Fawad: privacy policy URL; Terms link; `.storekit` check; submission items (group
  display name, review screenshots, Family Sharing, App Privacy); review the 53 draft
  `encouragementLines`.
- Paywall follow-ups (Fawad, 2026-11-14): show something when a purchase succeeds;
  Settings' Restore purchases has no loading state and shows even when entitled.
- Paywall review notes not fixed: sandbox Annual reads as a trial; Lifetime over Annual
  hides Manage; refunded "ended on" uses expiry; a resubmitted first run saves only the plan.
- Splash overflows at 200% on 375 × 667; paywall button 22 pt high there.
- Payment reminders spec (day 5) needed in the same release.
- Presence: extension version 1.0 vs app 0.1.0 (Xcode warns; match before release).
- Earlier walk items: Reduce Transparency, 200%, priced drink in Edit plan; chat spec,
  iPhone review list. The iPhone 17 simulator drops injected taps (2026-11-18): walk on
  the iPhone instead.
