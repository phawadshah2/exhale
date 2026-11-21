# Current state

Updated 2026-11-21 (Settings redesign closed). Older logs: `docs/history/`.

## Where we are

| Work | Status |
|---|---|
| M1 to M7, chat onboarding, paywall | Merged to `main` (`1fff6cb`, PRs 35 to 37) |
| Timer starts at the first log; tap opens today's logs | Done on `feat/timer-first-log` (3 commits), pushed, no PR yet |
| Lock Screen presence (project 1 of 4) | Closed 2026-11-18 on `feat/lock-screen`, stacked on the timer branch, pushed, no PR yet; closing notes in `docs/history/2026-11-18_lock_screen_presence_state.md` |
| Settings redesign (project 2 of 4) | Closed 2026-11-21 on `feat/settings-redesign`, stacked on Lock Screen, not pushed |
| M4 Multiple habits | Parked on `feat/multi-habit` |

Before the real iPhone pass, Fawad wants (2026-11-14), in order: 1 Lock Screen presence
(done), 2 Settings redesign (done), 3 notifications (careful wording), 4 breathing exercise
(likely the new tab). Launch still needs Export/Import, iCloud sync, Stay at zero.

## Settings redesign (closed 2026-11-21)

- Spec `docs/superpowers/specs/2026-11-19-settings-redesign-design.md`; plan
  `docs/superpowers/plans/2026-11-19-settings-redesign.md`; design `design/12._settings/`.
- On `feat/settings-redesign`, stacked on `feat/lock-screen`, not pushed.
- Review: 11 findings fixed (`1717d10`). Full suite 1587/1587 before the walk fixes;
  Settings and core widget tests 124/124 after them; format, analyze clean.
- iPhone walk (Fawad, 2026-11-21): entitled, trial, monthly, lifetimeRenewing, offline
  and the sandbox (Restore, Manage, Redeem, Refund) all pass after `9d4c0f4` (values at
  the row edge, the Subscription sheet fits its content, no line under the status bar
  glass). Light and dark seen; Reduce Transparency, 200% and VoiceOver not reported on
  the device (widget tests cover 200% and VoiceOver).
- Known, not fixed: the renewal state refreshes only when the sheet reopens or after
  Manage, not on app resume. Spec Open: "New day starts", feedback address, Privacy URL,
  App Store ID (Rate, Send feedback and Privacy stay hidden until set).

## Next action

Fawad pushes `feat/settings-redesign` and merges in order: timer PR, Lock Screen, then
Settings. Then project 3, notifications (careful wording): brainstorm a spec first. It
folds in the payment reminder (day 5) and the Lifetime-with-a-renewing-plan reminders.

## Repo

- `feat/export-import` (2 docs commits, `6b22bf4` and `4ae7705`, not on `main`) holds a
  newer copy of this file and of CLAUDE.md's Status; reconcile when either merges.
  Export/Import itself is not started.
- Untracked on purpose: `design/all-designs.html`, `design/figma-import/`.
- `stash@{0}` (splash hack) for simulator walks only.

## Open

- For Fawad: privacy policy URL; `.storekit` check; submission items (group
  display name, review screenshots, Family Sharing, App Privacy); review the 53 draft
  `encouragementLines`.
- Paywall follow-up (Fawad, 2026-11-14): show something when a purchase succeeds on the
  paywall. (Restore's loading state and its place were fixed by the Settings redesign.)
- Paywall review notes not fixed: sandbox Annual reads as a trial; refunded "ended on" uses expiry; a resubmitted first run saves only the plan.
- Splash overflows at 200% on 375 × 667; paywall button 22 pt high there.
- Payment reminders spec (day 5) needed in the same release.
- Lifetime with Annual or Monthly still renewing (Fawad, 2026-11-21): don't auto-open
  Apple's cancel screen; remind with in-app alerts and notifications until it is cancelled.
- Presence: extension version 1.0 vs app 0.1.0 (Xcode warns; match before release).
- Earlier walk items: Reduce Transparency, 200%, priced drink in Edit plan; chat spec,
  iPhone review list. The iPhone 17 simulator drops injected taps (2026-11-18): walk on
  the iPhone instead.
