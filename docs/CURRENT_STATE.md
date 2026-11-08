# Current state

Updated 2026-11-08 (handoff after C10). Earlier: `docs/history/2026-10-16_to_11-03_state_log.md`, `…11-04_to_11-05…`.

## Where we are

| Milestone | Status |
|---|---|
| M1 to M3, first onboarding redesign | Done, merged |
| M5 Release candidate | Done, merged to `main` (51e0bc6) |
| M6 Plan details, Edit plan, Logs; M7 Stage management; polish rounds | Done on `feat/plan-and-stages`, walked in the simulator |
| TestFlight build 1.0.0 (1) | Installed by Fawad; runs fine on his iPhone (2026-11-06) |
| Onboarding redesign 2 (chat) | C1 to C10 committed; milestone end next |
| M4 Multiple habits | Parked on `feat/multi-habit` for a later release |

## Repo

- `feat/plan-and-stages` pushed, not merged, no PR, CI not read. Last full suite at 7a80954:
  1211 passed.
- `feat/onboarding-chat-prototype` (off `feat/plan-and-stages`), not pushed, clean. Latest:
  C8 a6e38c9, round 3 395fef1, money card 7837e5c, C9 46b8912, C10 bf88e04 plus its review fix.
- Untracked on purpose: `design/all-designs.html`, `design/figma-import/`.

## Onboarding chat (current goal)

Spec `docs/superpowers/specs/2026-11-08-onboarding-chat-design.md` (sections 9 and 10 hold
every change Fawad asked for on 2026-11-08). Plan `docs/superpowers/plans/2026-11-08-onboarding-chat.md`,
C1 to C10 ticked, "Then" open.

Done on 2026-11-08: C8 (main's welcome look; Sent → Read under the last excuse only;
money card D, now vs plan; welcome word-by-word reveal, slowed); plan page
(quit date right, Pick my own date above the button, C9 stage ring and day/week grid, Your
date card); C10 (messages grow in, list follows the end per frame, keyboard slides over a
fixed dock, avatars stay while Exhale types, tagline 8 pt under the button; a message
keeps its state when its entrance ends). Never seen in the simulator.

Checks (bf88e04): analyze clean; `test/features/onboarding` 145 passed; `test/app` 21
passed. Full suite: not run since 7a80954 (due at the milestone end).

Test gotcha: an enabled `ChevronButton` loops, so welcome and plan tests turn on Reduce
Motion (`reduceMotion` in `test/helpers/onboarding.dart`) or pump fixed time. A failing
test there hangs past `--timeout`; run such files in the background.

Waiting on Fawad (marked in the spec): the answer-fixing rule (section 4, plus the price
skip rule), the italic tagline drafts (section 5), the Other habit and price fields, and
the day's answer bubble.

## Next action

Milestone end (plan "Then"), on Opus 5.5 high: independent review of
`feat/plan-and-stages..HEAD` (the chat onboarding), fix its findings, run the full suite, then the simulator walk (welcome
timing, money card, plan grid, chat with the keyboard). Read the plan's "Then" and spec
sections 9 and 10 first.

## Open items from Fawad's iPhone review (2026-11-06)

- Home: tap the stage/plan card to open Plan; tap the ring to open that day's logs.
- "Add a price" should scroll Plan to the price field; in Edit plan the keyboard hides it.
- Edit plan: less space between pace and suggested date; text jumps start-then-centre.
- Glassy status bar on scroll, app-wide.
- Not seen: Reduce Transparency, text at 200%, Eucalyptus and Ocean accents, long plans.
