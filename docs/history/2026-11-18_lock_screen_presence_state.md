# Lock Screen presence: closing state (2026-11-18)

Moved from `docs/CURRENT_STATE.md` on 2026-11-21.

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

