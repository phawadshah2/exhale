# Current state

Updated 2026-11-08. Earlier: `docs/history/2026-10-16_to_11-03_state_log.md`, `…11-04_to_11-05…`.

## Where we are

| Milestone | Status |
|---|---|
| M1 to M3, first onboarding redesign | Done, merged |
| M5 Release candidate | Done, merged to `main` (51e0bc6) |
| M6 Plan details, Edit plan, Logs; M7 Stage management; polish rounds | Done on `feat/plan-and-stages`, walked in the simulator |
| TestFlight build 1.0.0 (1) | Installed by Fawad; runs fine on his iPhone (2026-11-06) |
| Onboarding redesign 2 (chat) | C1 to C8 committed; milestone end next |
| M4 Multiple habits | Parked on `feat/multi-habit` for a later release |

## Repo

- `feat/plan-and-stages` pushed, not merged, no PR, CI not read. Last full suite at 7a80954:
  1211 passed.
- `feat/onboarding-chat-prototype` (off `feat/plan-and-stages`), not pushed. Commits: spec
  and plan 96ebd6c, C1 cfbab93 … C6 e054678, C7 554adfd. C8 committed.
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

**C8 in progress** (Fawad, 2026-11-08; spec section 9, plan Task C8, boxes unticked): main's
welcome colours, bubble shapes, 4/12 pt gaps, 450 ms entrance, no times or ticks in bubbles,
tagline 4 pt under the button, dock to the bottom edge, button 8 pt above the safe area.
Round 2 (Fawad, same day, in the spec): opening "You · <current time>"; Sent → Read only under
the last excuse, answers show no status; habit order Vaping, Smoking, Alcohol, Pouches, Energy
drinks, then the rest; money card coral (danger); glass bar fill 0.45 (`GlassSurface.opacity`);
dock hidden while the keyboard is up; jump button follows up to the newest message. Welcome:
headline word by word, then the subtitle, then each row's title, then its line
(`StepReveal.delay`). Never seen in the simulator.

Checks: analyze clean; `test/features/onboarding` 139 passed; `test/app` 21 passed.

Test gotcha: an enabled `ChevronButton` and the plan's dots loop, so tests on the welcome or
the plan turn on Reduce Motion (`reduceMotion` in `test/helpers/onboarding.dart`) or pump
fixed time. A failing test there hangs past `--timeout`; run such files in the background.

Waiting on Fawad (marked in the spec): the answer-fixing rule (section 4, plus the price
skip rule), the italic tagline drafts (section 5), the Other habit and price fields, and
the day's answer bubble.

## Next action

Milestone end (plan "Then"): independent review (Opus 5.5 high), full suite, then the
simulator walk (check the welcome reveal timing, the coral card, the bar over content).

## Open items from Fawad's iPhone review (2026-11-06)

- Home: tap the stage/plan card to open Plan; tap the ring to open that day's logs.
- "Add a price" should scroll Plan to the price field; in Edit plan the keyboard hides it.
- Edit plan: less space between pace and suggested date; text jumps start-then-centre.
- Glassy status bar on scroll, app-wide.
- Not seen: Reduce Transparency, text at 200%, Eucalyptus and Ocean accents, long plans.
