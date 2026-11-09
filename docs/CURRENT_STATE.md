# Current state

Updated 2026-11-09 (chat milestone end: review, fixes, full suite, walk). Earlier: `docs/history/2026-10-16_to_11-03_state_log.md`, `…11-04_to_11-05…`.

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
- `feat/onboarding-chat-prototype` (off `feat/plan-and-stages`), not pushed. Latest: C10
  bf88e04, b54db14, milestone review fixes b8a3b01, then the walk's "1 stage" copy fix.
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
keeps its state when its entrance ends).

Milestone review (2026-11-09, b8a3b01): a newest card answers while another is reopened
(was dead); new Exhale messages announced to VoiceOver; money card uses the pace the plan
opens on and whole units; grid keeps 7 columns for plans under 4 weeks; the own date lives
in the form (`ownQuitDay`); the kept-alive chat mutes its tickers off screen.

Checks: full suite at b8a3b01 1273 passed (onboarding_chat 27, deal_step 12,
onboarding_page 5, chat_step 21, chat_cards 13, accessibility 4, app_test 6). Analyze clean.

Simulator walk (light, iPhone 17 Pro Max size): welcome, chat with the keyboard over the
dock, reopen-then-answer, smoking (pack price and size, money card A$2,190 / A$280 /
A$1,910), social media (no price), plan grid, a 1-day own date, the own-date card after
Back. Not walked: dark mode, Reduce Transparency, text at 200%, a no-container priced
habit, fixing every card. Log, once: chat Column overflow 29,310 px (`chat_step.dart:143`),
likely a keyboard toggle in the simulator; not reproduced.

Open for Fawad: the selected plan card dropped the pace blurb, the dots and the three rules
(per the mockup); bring any back? C10 widened the tagline gap under the button to 8 pt
(spec section 9 said 4); keep it? Alcohol and energy drinks save as a priced bottle/pack
holding 1 (spec section 7), so Edit plan reads "Price of a bottle, 1 a bottle"; ask the
container question or save per drink? Plans under 4 weeks now take fewer than 4 grid rows
(spec section 10 said 4 to 7); fine? A quick double tap on "See my plan" lands on the plan's
save button, which is live during its entrance.

Test gotcha: an enabled `ChevronButton` loops, so welcome and plan tests turn on Reduce Motion (`reduceMotion` in `test/helpers/onboarding.dart`) or pump fixed time. A failing test there hangs past `--timeout`; run such files in the background.

Waiting on Fawad (marked in the spec): the answer-fixing rule (section 4, plus the price
skip rule), the italic tagline drafts (section 5), the Other habit and price fields, and
the day's answer bubble.

## Next action

Fawad: answer the open questions above and walk the rest (dark, Reduce Transparency, 200%).
Then merge `feat/plan-and-stages` and this branch to `main` (PRs from compare links) and
do the real iPhone pass.

## Open items from Fawad's iPhone review (2026-11-06)

- Home: tap the stage/plan card to open Plan; tap the ring to open that day's logs.
- "Add a price" should scroll Plan to the price field; in Edit plan the keyboard hides it.
- Edit plan: less space between pace and suggested date; text jumps start-then-centre.
- Glassy status bar on scroll, app-wide.
- Not seen: Reduce Transparency, text at 200%, Eucalyptus and Ocean accents, long plans.
