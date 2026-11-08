# Current state

Updated 2026-11-08. Earlier: `docs/history/2026-10-16_to_11-03_state_log.md`, `…11-04_to_11-05…`.

## Where we are

| Milestone | Status |
|---|---|
| M1 to M3, first onboarding redesign | Done, merged |
| M5 Release candidate | Done, merged to `main` (51e0bc6) |
| M6 Plan details, Edit plan, Logs; M7 Stage management; polish rounds | Done on `feat/plan-and-stages`, walked in the simulator |
| TestFlight build 1.0.0 (1) | Installed by Fawad; runs fine on his iPhone (2026-11-06) |
| Onboarding redesign 2 (chat) | In progress: Tasks C1 to C6 of 7 done on `feat/onboarding-chat-prototype` |
| M4 Multiple habits | Parked on `feat/multi-habit` for a later release |

## Repo

- `feat/plan-and-stages` pushed, not merged, no PR, CI not read. Last full suite at 7a80954:
  1211 passed.
- `feat/onboarding-chat-prototype` (off `feat/plan-and-stages`), not pushed, tree clean.
  Commits: spec and plan 96ebd6c, C1 cfbab93, C2 838aff3, C3 68c9427, C4 b5849d1, C5 98819c5,
  C6 (tagline) after it.
- Untracked on purpose: `design/all-designs.html`, `design/figma-import/`.

## Onboarding chat (current goal)

Spec `docs/superpowers/specs/2026-11-08-onboarding-chat-design.md` (from the canvas
https://claude.ai/artifact/EMRb3MqhssfA6k4qLHTCQa, page "Questions inside the chat").
Plan `docs/superpowers/plans/2026-11-08-onboarding-chat.md`.

Done: the script as question cards with reopen-to-change (`providers/onboarding_chat.dart`);
glass bar, top-filled list, jump button, solid dock (`steps/chat_step.dart`,
`pages/onboarding_page.dart`); every question's card (`widgets/chat_cards.dart`); bubbles
(`widgets/chat_widgets.dart`); the tagline under the button (`ChatTagline`,
`OnboardingChat.tagline`). Deviations are noted in the plan's ticked tasks.

Checks at C6 (2026-11-08): format and `analyze --fatal-infos` clean; `onboarding_chat_test`,
`chat_step_test`, `chat_cards_test`: 41 passed. Full suite not run (milestone end).
Known failing, already at prototype f920bbd: first-run step tests (habit, amount, cost,
day) and `change_habit_test` "declining the confirm…" (`pumpAndSettle` timeout on the plan
screen). Both are in Task C7. Never seen in the simulator.

Waiting on Fawad (marked in the spec): the answer-fixing rule (section 4, plus the price
skip rule), the italic tagline drafts (section 5), the Other habit and price fields, and
the day's answer bubble.

## Next action

`execute-plan` Task C7 (access and the rest of onboarding: accessibility, welcome, page and
app tests; the first-run step tests and `change_habit_test` failures). Read: this file, the
plan's C7, spec sections 6 and Tests. Chat test helpers are in `test/helpers/onboarding.dart`.
Then the milestone end (review, full suite, simulator walk).

## Open items from Fawad's iPhone review (2026-11-06)

- Home: tap the stage/plan card to open Plan; tap the ring to open that day's logs.
- "Add a price" should scroll Plan to the price field; in Edit plan the keyboard hides it.
- Edit plan: less space between pace and suggested date; text jumps start-then-centre.
- Glassy status bar on scroll, app-wide.
- Not seen: Reduce Transparency, text at 200%, Eucalyptus and Ocean accents, long plans.
