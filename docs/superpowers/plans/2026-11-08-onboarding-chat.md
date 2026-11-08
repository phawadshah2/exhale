# Onboarding chat plan

Spec: `docs/superpowers/specs/2026-11-08-onboarding-chat-design.md`. Branch
`feat/onboarding-chat-prototype` (off `feat/plan-and-stages`). One commit per task: failing
test, code, passing test. Builds on the prototype's files; nothing in the change-habit steps
moves.

### Task C1: The script as question cards

- [x] Tests in `test/features/onboarding/onboarding_chat_test.dart` (fake async, Reduce
  Motion on): the opening order (three excuses, "Heard them all…", the name question); each
  answer writes the form and adds the user's bubble; the branches: container habit (price,
  per pod, money card, day), no-container habit (price, money card, day), social media (no
  price), price skipped, name skipped; `ask` is `done` only after the day.
- [x] `OnboardingChat`: a `ChatQuestion` item (its `ChatAsk`, its text, open or folded)
  replaces the dock's `ask` switch; an answer bubble records the question it answers;
  Exhale's lines take a `String Function()` so they re-read the form. Wake and bed become
  one `ChatAsk.day` answered with both times. Drop `DayCard` and the wake and bed choices.
- [x] Copy in `OnboardingCopy`: the new opening line, "12 a day", "30 a pod", "7:00 AM to
  11:00 PM", the per-pod caption, the price Other and habit Other strings.
- [x] Commit `feat(onboarding): ask each chat question as a card`.

### Task C2: Fixing an answer

- [x] Tests in `onboarding_chat_test.dart`: reopening the name and sending a new one updates
  its bubble and the reply, with no new items; a new amount updates the reaction, the money
  card and "your 12"; a new habit drops every item after the habit answer, resets the amounts
  to the habit's defaults and asks the amount again; the same habit only folds; nothing
  reopens while Exhale types; the excuses never reopen.
- [x] `OnboardingChat.reopen(ChatText answer)`, one reopened card at a time; answering a
  reopened card updates in place; the habit, and a price switched to or from skipped, truncate and replay.
- [x] Commit `feat(onboarding): reopen a chat answer to change it`.

### Task C3: The chat screen

- [x] Tests in `test/features/onboarding/chat_step_test.dart`: the list fills from the top
  and keeps the newest in view; scrolling back shows "Jump to the newest message", which
  scrolls down and hides; "See my plan" is off until the day is answered, then opens the
  plan screen; the green dot is in the header.
- [x] `ChatStep`: a `Stack` with a top-anchored `ListView` under an edge-to-edge
  `GlassSurface` app bar (top padding from the bar's height), the jump button, and a solid
  dock with a top hairline. The interim answers stay in the
  dock until C4 and C5 move each into its card, so the chat can still be answered.
- [x] Bubbles in `chat_widgets.dart`: the time at the bottom-right edge of every bubble,
  ticks on the user's; dark and light colours from theme tokens (Exhale black in light mode,
  the user's white with a hairline; money card mint in light mode).
- [x] `OnboardingPage` keeps the safe area for every step but the chat. The plan card's
  pace name shrinks rather than overflow (seen in the test font).
- [x] Commit `feat(onboarding): give the chat a glass bar and a fixed dock`.

### Task C4: Name, habit and amount cards

- [x] Tests in `test/features/onboarding/chat_cards_test.dart`: the name card sends on the
  button and on the keyboard, ignores a blank name, skips with "I'd rather not say"; the
  habit card shows eight habits and Other in three rows, Other swaps in a field and "Back to
  the list"; the amount card steps 1 to 80 and sends "12 a day"; an answered card folds to its
  text.
- [x] `widgets/chat_cards.dart`: `ChatCardFrame` (bubble with the controls under the text,
  animated fold), `NameCard`, `HabitCard` (text-sized pills with a 44 pt hit area),
  `AmountCard` (stepper well and "That's about right"). Drop their dock answers.
- [x] Also here: tapping an answer bubble reopens its card (spec section 4), and a card that
  resizes at the bottom keeps the newest in view. Chat test helpers moved to
  `test/helpers/onboarding.dart`.
- [x] Commit `feat(onboarding): ask the name, habit and amount inside the chat`.

### Task C5: Price, per-pod and day cards

- [x] Tests in `chat_cards_test.dart`: five scaled chips and Other for vaping ($5 to $15);
  Other's field rejects an invalid price; "Change" opens the currency wheel and the chips
  follow the new symbol; "I'd rather not know" skips; the per-pod card steps by 5 to 100 with
  the caption; the day card steps by 30 minutes, turns a step off at the minimum window and
  shows "16 h awake · one every 1 h 20 min".
- [x] `PriceCard`, `PerPodCard`, `DayQuestionCard` in `chat_cards.dart`; the money card keeps
  `MoneyCardView`. Remove the last dock answers (`_Answers`, `_Grid`).
- [x] Also here: `CurrencyChip.pickCurrency` opens the wheel from the price card's "Change";
  the money card's figures wrap at large text; the unused `ChatChip` is gone.
- [x] Commit `feat(onboarding): ask the price and the day inside the chat`.

### Task C6: Tagline

- [x] Tests in `chat_step_test.dart`: the tagline follows the spec's table after each answer
  (vaping sample, name skipped, price skipped, a non-nicotine habit); under Reduce Motion it
  swaps without sliding; it is a live region.
- [x] `OnboardingCopy.tagline...` lines; `ChatTagline` widget (slide up and out, slide in
  from below); `OnboardingChat.tagline` set as each answer lands.
- [x] Also here: the tagline replaces `chatFinePrint` (now `taglineStart`); a reopened answer
  sets it too; it is one line with an ellipsis at any text size. `chat_cards_test` finds
  answers inside `ChatBubble`, since the tagline can quote them.
- [x] Commit `feat(onboarding): react to each answer under the button`.

### Task C7: Access and the rest of onboarding

- [x] Tests: `accessibility_test.dart` covers the chat (card group names, answer bubbles as
  buttons, 44 pt targets, text at 200% with no overflow, light mode, Reduce Transparency);
  `welcome_step_test.dart` back for the new welcome; `onboarding_page_test.dart` and the app
  tests run a first run through welcome, chat and plan. The habit, amount, cost and day step
  tests reach their steps through the change-habit flow (the first run no longer has them).
  `change_habit_test.dart` "declining the confirm…" times out in `pumpAndSettle` on the plan
  screen, already at the prototype commit f920bbd: find what never settles.
- [x] Fix what those tests find.
- [x] Found and decided (Fawad, 2026-11-08): an enabled `ChevronButton` and the plan's dots
  loop forever, so `pumpAndSettle` never returns on the welcome or the plan. Tests turn
  Reduce Motion on (`reduceMotion` in `test/helpers/onboarding.dart`); one plan test checks
  the loops run with motion on and stop under Reduce Motion. `DayStep` was in no flow, so it,
  `OnboardingStep.day`, its test and its copy are gone (the chat's day card replaced it).
- [x] Also here: a zero-length `AnimatedSize` under Reduce Motion threw on the habit and cost
  steps; `StepGrow` skips it instead. `deal_step_test` rewritten for the paces screen; the
  cost step's currency test dropped (Change habit locks the currency; the chat's price card
  covers the wheel); the form controller tests follow the three-step first run and the
  saved name. Helpers: `chatToPlan`, `pumpAppToPlan`, `pumpChangeHabit`, `planButton`.
- [x] The 200% walk found: a bubble's time and ticks scaled twice (`WidgetSpan`, now
  unscaled inside); the name hint clipped (wraps to two lines); the pace card header clipped
  (wraps at large text) and had no VoiceOver label (now "Brisk, 4 weeks, Nov 17"); the dot
  dates clipped (3 columns at large text); "negotiating" did not fit at 1.5 (the headline
  scales down to the width).
- [x] Commit `test(onboarding): cover the chat onboarding end to end`.

### Task C8: The chat as `main`'s welcome (spec section 9)

- [x] Tests: `onboarding_chat_test` (motion on) for sent, delivered at 0.4 s, read 1.2 s
  later, and Exhale only after the read; `chat_step_test` for the opening line, the status
  under the latest message only, no times in bubbles, the 4 and 12 pt gaps, the bubble
  colours in light and dark, the entrance under Reduce Motion, and the dock (tagline 4 pt
  under the button, the dock to the bottom edge, the button at the welcome's height).
- [x] `chat_widgets.dart`: `ChatBubbleColors` and the bubble shapes from `main`;
  `ChatEntrance`; the status line; typing dots without a bubble; drop `ChatMessageText`
  and `DeliveryTicks`. `onboarding_chat.dart`: the new timings, `ChatText.statusAt`, the
  excuses at 11:48 PM. `chat_step.dart` and `OnboardingStepFrame`: the dock.
- [x] Commit `feat(onboarding): give the chat the welcome's look`.
  Round 2 (Fawad, 2026-11-08): status only under the last excuse, Sent → Read; current
  time in the opening; habit order; coral money card; clearer bar; dock behind the
  keyboard; jump follow-up; welcome word-by-word reveal; dock 8 pt above the safe area.

### Then

Milestone end, per `CLAUDE.md`: the independent review (Opus 5.5 high) and its fixes, the
full suite, then the simulator walk for Fawad (dark and light, a container habit, a
no-container habit, social media, fixing an answer).
