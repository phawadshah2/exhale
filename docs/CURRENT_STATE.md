# Current state

Updated 2026-11-08. Earlier: `docs/history/2026-10-16_to_11-03_state_log.md`, `…11-04_to_11-05…`.

## Where we are

| Milestone | Status |
|---|---|
| M1 to M3, first onboarding redesign | Done, merged |
| M5 Release candidate | Done, merged to `main` (51e0bc6) |
| M6 Plan details, Edit plan, Logs; M7 Stage management; polish rounds | Done on `feat/plan-and-stages`, walked in the simulator |
| TestFlight build 1.0.0 (1) | Installed by Fawad; runs fine on his iPhone (2026-11-06) |
| Onboarding redesign 2 (chat) | Signed off 2026-11-06; spec and plan 2026-11-08; prototype 1efc0c1 |
| M4 Multiple habits | Parked on `feat/multi-habit` for a later release |

## Repo

- `feat/plan-and-stages` pushed, not merged, no PR, CI not read. Last full suite at 7a80954:
  1211 passed, format and analyze clean.
- Untracked on purpose: `design/all-designs.html`, `design/figma-import/`.

## Onboarding redesign 2 (Fawad, 2026-11-06)

Canvas (source of truth): https://claude.ai/artifact/EMRb3MqhssfA6k4qLHTCQa, page
"Onboarding, in order", top row; boards 1 to 3 play in order.

1. **Welcome** (`FlowIntro`, not a chat): "EXHALE", "Stop / negotiating (struck) / with
   your / cravings.", subtitle, four how-it-works rows, "Let's talk", tagline.
2. **One chat** replaces the welcome chat, habit, amount, cost and day steps. Now specified
   by the "Questions inside the chat" page (below), which supersedes `FlowChat`'s answer dock.
3. **Plan** (`VisDots`, 2C): Brisk/Steady/Gentle cards, 12 dots in date order, plan rules,
   tagline. Back button; no counter.

Every screen has a tagline under the main button. Paywall ideas are on the canvas's
"Paywall ideas (later)" page; pricing model undecided.

**Questions inside the chat** (canvas page of that name; signed off by Fawad 2026-11-06).
Row 1 dark, row 2 light, boards 1 to 7; the green "Decided" note lists every ruling.
- Each question is an Exhale message with its controls inside (name field, habit pills,
  steppers, price chips plus Other, one wake-and-bed card). Answered cards fold back to a
  plain message plus the user's bubble with ticks. No answer dock.
- Opening: excuses, "Heard them all…", then "Before you send me another excuse: who am I
  talking to?".
- Habit picker is board **E** (not board 2): three rows of text-sized pills, eight habits + Other.
- Chat fills from the top; edge-to-edge glass app bar (chat scrolls under it); solid dock
  with "See my plan"; green dot on the avatar; timestamps at the bubble's bottom-right edge.
- Tagline under the button reacts to the last answer and slides to a new line.
- Light mode: Exhale's bubbles and cards black, the user's white.

## Onboarding prototype (2026-11-06)

- Branch `feat/onboarding-chat-prototype` (off `feat/plan-and-stages`), commit 1efc0c1, not
  pushed. Throwaway: no spec, plan or tests (Fawad's call).
- Built: `steps/welcome_step.dart`, `steps/chat_step.dart`, reworked `steps/deal_step.dart`,
  `providers/onboarding_chat.dart` (the script), `widgets/chat_widgets.dart`,
  `widgets/chevron_button.dart`. Edited: form provider (`userName`; first-run steps are
  welcome, chat, deal), `onboarding_page.dart`, `onboarding_copy.dart`, `app_icons.dart`.
- Format and analyze clean; tests not run (`welcome_step_test.dart` deleted; page, app and
  a11y onboarding tests need rework). Never seen running in the simulator.
- Deviations: alcohol and energy drinks store 1 unit per container; Steady blurb is generic;
  custom habit is "Something else" / "time"; the name is saved to settings, not shown on Home.

## Next action

Spec `docs/superpowers/specs/2026-11-08-onboarding-chat-design.md` and plan
`docs/superpowers/plans/2026-11-08-onboarding-chat.md` (Tasks C1 to C7) written 2026-11-08.
C1 (the script as question cards) done; the dock is an interim until C3 to C5.
Next: `execute-plan` Task C2 on `feat/onboarding-chat-prototype`.

Waiting on Fawad (marked in the spec): the answer-fixing rule (section 4), the italic
tagline drafts and seven habit taglines (section 5), the Other habit and Other price
fields, and the day's answer bubble with the dropped day-dots card.

## Open items from Fawad's iPhone review (2026-11-06)

- Currency from the region, changeable (in the chat design).
- Home: tap the stage/plan card to open Plan; tap the ring to open that day's logs.
- "Add a price" should scroll Plan to the price field; in Edit plan the keyboard hides it.
- Edit plan: less space between pace and suggested date; text jumps start-then-centre.
- Glassy status bar on scroll, app-wide.
- Not seen: Reduce Transparency, text at 200%, Eucalyptus and Ocean accents, long plans.
