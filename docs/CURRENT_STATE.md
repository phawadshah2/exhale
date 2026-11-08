# Current state

Updated 2026-11-08. Earlier: `docs/history/2026-10-16_to_11-03_state_log.md`, `…11-04_to_11-05…`.

## Where we are

| Milestone | Status |
|---|---|
| M1 to M3, first onboarding redesign | Done, merged |
| M5 Release candidate | Done, merged to `main` (51e0bc6) |
| M6 Plan details, Edit plan, Logs; M7 Stage management; polish rounds | Done on `feat/plan-and-stages`, walked in the simulator |
| TestFlight build 1.0.0 (1) | Installed by Fawad; runs fine on his iPhone (2026-11-06) |
| Onboarding redesign 2 (chat) | Tasks C1 to C7 done on `feat/onboarding-chat-prototype`; milestone end next |
| M4 Multiple habits | Parked on `feat/multi-habit` for a later release |

## Repo

- `feat/plan-and-stages` pushed, not merged, no PR, CI not read. Last full suite at 7a80954:
  1211 passed.
- `feat/onboarding-chat-prototype` (off `feat/plan-and-stages`), not pushed, tree clean.
  Commits: spec and plan 96ebd6c, C1 cfbab93, C2 838aff3, C3 68c9427, C4 b5849d1, C5 98819c5,
  C6 e054678, C7 after it.
- Untracked on purpose: `design/all-designs.html`, `design/figma-import/`.

## Onboarding chat (current goal)

Spec `docs/superpowers/specs/2026-11-08-onboarding-chat-design.md` (from the canvas
https://claude.ai/artifact/EMRb3MqhssfA6k4qLHTCQa, page "Questions inside the chat").
Plan `docs/superpowers/plans/2026-11-08-onboarding-chat.md`.

Done: the script as question cards with reopen-to-change (`providers/onboarding_chat.dart`);
glass bar, top-filled list, jump button, solid dock (`steps/chat_step.dart`,
`pages/onboarding_page.dart`); every question's card (`widgets/chat_cards.dart`); bubbles
(`widgets/chat_widgets.dart`); the tagline under the button (`ChatTagline`,
`OnboardingChat.tagline`); every onboarding test reworked for the welcome, chat and plan
first run, and the change-habit steps (C7). `DayStep` is deleted (Fawad, 2026-11-08).
Deviations are noted in the plan's ticked tasks.

Checks at C7 (2026-11-08): format and `analyze --fatal-infos` clean; every file in
`test/features/onboarding` and `test/app/app_test.dart` passed, file by file. Full suite not
run (milestone end). Never seen in the simulator.

Test gotcha: an enabled `ChevronButton` and the plan's dots loop, so tests on the welcome or
the plan turn on Reduce Motion (`reduceMotion` in `test/helpers/onboarding.dart`) or pump
fixed time. A failing test there hangs past `--timeout`; run such files in the background.

Waiting on Fawad (marked in the spec): the answer-fixing rule (section 4, plus the price
skip rule), the italic tagline drafts (section 5), the Other habit and price fields, and
the day's answer bubble.

## Next action

Milestone end for the onboarding chat (plan "Then"): the independent review (Opus 5.5
high) and its fixes, the full suite with the JSON report, then the simulator walk for Fawad
(dark and light, a container habit, a no-container habit, social media, fixing an answer).

## Open items from Fawad's iPhone review (2026-11-06)

- Home: tap the stage/plan card to open Plan; tap the ring to open that day's logs.
- "Add a price" should scroll Plan to the price field; in Edit plan the keyboard hides it.
- Edit plan: less space between pace and suggested date; text jumps start-then-centre.
- Glassy status bar on scroll, app-wide.
- Not seen: Reduce Transparency, text at 200%, Eucalyptus and Ocean accents, long plans.
