# Current state

Updated 2026-11-10 (monetization and sync decisions locked). Earlier: `docs/history/2026-10-16_to_11-03_state_log.md`, `…11-04_to_11-05…`.

## Where we are

| Milestone | Status |
|---|---|
| M1 to M3, first onboarding redesign | Done, merged |
| M5 Release candidate | Done, merged to `main` (51e0bc6) |
| M6 Plan details, Edit plan, Logs; M7 Stage management; polish rounds | Done on `feat/plan-and-stages`, walked in the simulator |
| TestFlight build 1.0.0 (1) | Installed by Fawad; runs fine on his iPhone (2026-11-06) |
| Onboarding redesign 2 (chat) | C1 to C10 done; reviewed, fixed, full suite green, walked in part |
| M4 Multiple habits | Parked on `feat/multi-habit` for a later release |

## Repo

- `feat/plan-and-stages` pushed, not merged, no PR, CI not read. Last full suite at 7a80954:
  1211 passed.
- `feat/onboarding-chat-prototype` (off `feat/plan-and-stages`) on origin, local ahead by
  the corrections round (c9d9e6b, 0aba537), its docs and the decisions record.
- Untracked on purpose: `design/all-designs.html`, `design/figma-import/`.

## Onboarding chat (current goal)

Spec `docs/superpowers/specs/2026-11-08-onboarding-chat-design.md` (sections 9 and 10 hold
every change Fawad asked for on 2026-11-08). Plan `docs/superpowers/plans/2026-11-08-onboarding-chat.md`,
C1 to C10 ticked; "Then" done except the rest of the walk.

C8 to C10 and the milestone review (b8a3b01) are done; detail in `docs/history/2026-11-08_to_11-09_chat_log.md`.

Checks at 10b62ee: onboarding + plan tests 505 passed, analyze clean.

Simulator walk (light, iPhone 17 Pro Max size): welcome, chat with the keyboard over the
dock, reopen-then-answer, smoking (pack price and size, money card A$2,190 / A$280 /
A$1,910), social media (no price), plan grid, a 1-day own date, the own-date card after
Back. Not walked: dark mode, Reduce Transparency, text at 200%, a no-container priced
habit, fixing every card. Log, once: chat Column overflow 29,310 px (`chat_step.dart:143`),
likely a keyboard toggle in the simulator; not reproduced.

Decided (Claude, Fawad's go-ahead, 2026-11-09; spec section 11): drinks priced one at a
time save as the preset container; short plans keep 7 grid columns; a double tap on "See my
plan" already cannot save (the slide ignores touches; tested); selected card stays as the
mockup; tagline gap 8 pt. Drink pricing: `pricedPerUnit` and `savedPrice` on the form.

Test gotcha: an enabled `ChevronButton` loops, so welcome and plan tests turn on Reduce Motion (`reduceMotion` in `test/helpers/onboarding.dart`) or pump fixed time. A failing test there hangs past `--timeout`; run such files in the background.

Waiting on Fawad (marked in the spec): the answer-fixing rule (section 4, plus the price
skip rule), the italic tagline drafts (section 5), the Other habit and price fields, and
the day's answer bubble.

## Corrections round (2026-11-09, committed)

- Chat could not be scrolled up: `chat_step.dart` `_onMetrics` no longer follows the end
  while a finger scrolls (`isScrollingNotifier`). Not seen in the simulator.
- Habit pills in `chat_cards.dart` are one `Wrap` (was 3 per row); test rewritten.
- Money card wears the user bubble colour (`ChatBubbleColors mine: true`), bar track on `surface`.
- Plan tab stage rows open at `AppMotion.swap` / `swapCurve` (was 250 ms), `stage_row.dart`.
- New `StatusBarGlass` (opacity 0.3, blur 20): glass strip over the status bar after 4 px of
  scroll. Wraps Home/habit dashboard, Logs, Plan details, Settings, `SetupScaffold` (Edit plan
  and forms). Not seen in the simulator; Fawad asked for 70% transparent.
- Default theme is Light: `AppSettings` default and mapper fallback. The drift column default
  stays `'system'` (changing it broke the migration schema tests). Saved choices are kept, so
  Fawad's TestFlight install may still be on System. Two tests now use Dark.

- Sent/Read status now sits under the newest user message (answers too), not only the excuses;
  Sent until Exhale replies, then Read (`_answer` in `onboarding_chat.dart`). Chat + a11y tests pass.

Checks: full suite 1279 passed, 0 failed (`build/test-report.json`); analyze clean.

## Next action

Locked 2026-11-10: `docs/decisions/2026-11-10-monetization-and-sync.md` (paywall with
three offers, locked screen, payment notifications, Export/Import and iCloud sync in the
launch build, Stay at zero). Now: Fawad sets up App Store Connect payments step by step
(Paid Apps agreement, banking, tax, Small Business Program, products). Then specs for the
paywall and sync.

Still open: walk the rest (dark, Reduce Transparency, 200%, a priced drink in Edit plan; the
walk needs `stash@{0}`, which now conflicts in `splash_page.dart`: keep upstream's switch,
send `Success()` to `_startTalking()`). Then push, merge `feat/plan-and-stages` and this
branch to `main` (PRs from compare links), and do the real iPhone pass. Read first: this
file, spec section 11.

## Open items from Fawad's iPhone review (2026-11-06)

- Home: tap the stage/plan card to open Plan; tap the ring to open that day's logs.
- "Add a price" should scroll Plan to the price field; in Edit plan the keyboard hides it.
- Edit plan: less space between pace and suggested date; text jumps start-then-centre.
- Glassy status bar on scroll: built (see Corrections round), unseen on device.
- Not seen: Reduce Transparency, text at 200%, Eucalyptus and Ocean accents, long plans.
