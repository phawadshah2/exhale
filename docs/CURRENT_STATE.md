# Current state

Updated 2026-11-06. Earlier sessions: `docs/history/2026-10-16_to_11-03_state_log.md`,
`docs/history/2026-11-04_to_11-05_state_log.md`.

## Where we are

| Milestone | Status |
|---|---|
| M1 to M3, first onboarding redesign | Done, merged |
| M5 Release candidate | Done, merged to `main` (51e0bc6) |
| M6 Plan details, Edit plan, Logs; M7 Stage management; polish rounds | Done on `feat/plan-and-stages`, walked in the simulator |
| TestFlight build 1.0.0 (1) | Installed by Fawad; runs fine on his iPhone (2026-11-06) |
| Onboarding redesign 2 (chat) | Design settled on the canvas; prototype not started |
| M4 Multiple habits | Parked on `feat/multi-habit` for a later release |

## Repo

- Branch `feat/plan-and-stages`, pushed; not merged to `main`, no PR open, CI not read.
- Last checks at 7a80954: full suite 1211 passed, format and analyze clean. Not run since:
  no Dart code changed.
- Untracked on purpose: `design/all-designs.html`, `design/figma-import/`.

## Onboarding redesign 2 (Fawad, 2026-11-06)

Canvas (source of truth): https://claude.ai/artifact/EMRb3MqhssfA6k4qLHTCQa, page
"Onboarding, in order", top row; boards 1 to 3 play in order.

1. **Welcome** (`FlowIntro`, not a chat): "EXHALE", "Stop / negotiating (struck) / with
   your / cravings.", subtitle, four how-it-works rows, "Let's talk", tagline.
2. **One chat** (`FlowChat`) replaces the welcome chat, habit, amount, cost and day steps:
   excuses, name (or refuse), habit chips, amount stepper, price chips or skip, units per
   container, money card, wake and bed chips, day card, "See my plan". Sardonic Exhale,
   real times and sent/delivered/read ticks inside bubbles, answers in the area above a
   fixed button, cards inside the chat. No step counter, no back button.
3. **Plan** (`VisDots`, 2C): Brisk/Steady/Gentle cards, 12 dots in date order, plan rules,
   tagline. Back button; no counter.

Every screen has a tagline under the main button. Paywall ideas are on the canvas's
"Paywall ideas (later)" page; pricing model undecided.

## Next action

Build a throwaway prototype on `feat/onboarding-chat-prototype` (off `feat/plan-and-stages`):
the three screens above, reusing `onboarding_form_provider.dart` and `OnboardingCopy`. No
spec or tests (Fawad's call). Ask before the simulator run, then Fawad reviews and refines;
spec, plan and tests come after. Read: this file, the canvas boards above,
`lib/features/onboarding/presentation/`.

## Open items from Fawad's iPhone review (2026-11-06)

- Currency from the region, changeable (in the chat design).
- Home: tap the stage/plan card to open Plan; tap the ring to open that day's logs.
- "Add a price" should scroll Plan to the price field; in Edit plan the keyboard hides it.
- Edit plan: less space between pace and suggested date; text jumps start-then-centre.
- Glassy status bar on scroll, app-wide.
- Not seen: Reduce Transparency, text at 200%, Eucalyptus and Ocean accents, long plans.
