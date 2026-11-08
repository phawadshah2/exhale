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

- [ ] Tests in `test/features/onboarding/chat_step_test.dart`: the list fills from the top
  and keeps the newest in view; scrolling back shows "Jump to the newest message", which
  scrolls down and hides; "See my plan" is off until the day is answered, then opens the
  plan screen; the green dot is in the header.
- [ ] `ChatStep`: a `Stack` with a top-anchored `ListView` under an edge-to-edge
  `GlassSurface` app bar (top padding from the bar's height), the jump button, and a solid
  dock with a top hairline. Remove `_Answers`, `_Grid` and the dock's controls.
- [ ] Bubbles in `chat_widgets.dart`: the time at the bottom-right edge of every bubble,
  ticks on the user's; dark and light colours from theme tokens (Exhale black in light mode,
  the user's white with a hairline; money card mint in light mode).
- [ ] Commit `feat(onboarding): give the chat a glass bar and a fixed dock`.

### Task C4: Name, habit and amount cards

- [ ] Tests in `test/features/onboarding/chat_cards_test.dart`: the name card sends on the
  button and on the keyboard, ignores a blank name, skips with "I'd rather not say"; the
  habit card shows eight habits and Other in three rows, Other swaps in a field and "Back to
  the list"; the amount card steps 1 to 80 and sends "12 a day"; an answered card folds to its
  text.
- [ ] `widgets/chat_cards.dart`: `ChatCardFrame` (bubble with the controls under the text,
  animated fold), `NameCard`, `HabitCard` (text-sized pills with a 44 pt hit area),
  `AmountCard` (stepper well and "That's about right").
- [ ] Commit `feat(onboarding): ask the name, habit and amount inside the chat`.

### Task C5: Price, per-pod and day cards

- [ ] Tests in `chat_cards_test.dart`: five scaled chips and Other for vaping ($5 to $15);
  Other's field rejects an invalid price; "Change" opens the currency wheel and the chips
  follow the new symbol; "I'd rather not know" skips; the per-pod card steps by 5 to 100 with
  the caption; the day card steps by 30 minutes, turns a step off at the minimum window and
  shows "16 h awake · one every 1 h 20 min".
- [ ] `PriceCard`, `PerPodCard`, `DayQuestionCard` in `chat_cards.dart`; the money card keeps
  `MoneyCardView`.
- [ ] Commit `feat(onboarding): ask the price and the day inside the chat`.

### Task C6: Tagline

- [ ] Tests in `chat_step_test.dart`: the tagline follows the spec's table after each answer
  (vaping sample, name skipped, price skipped, a non-nicotine habit); under Reduce Motion it
  swaps without sliding; it is a live region.
- [ ] `OnboardingCopy.tagline...` lines; `ChatTagline` widget (slide up and out, slide in
  from below); `OnboardingChat.tagline` set as each answer lands.
- [ ] Commit `feat(onboarding): react to each answer under the button`.

### Task C7: Access and the rest of onboarding

- [ ] Tests: `accessibility_test.dart` covers the chat (card group names, answer bubbles as
  buttons, 44 pt targets, text at 200% with no overflow, light mode, Reduce Transparency);
  `welcome_step_test.dart` back for the new welcome; `onboarding_page_test.dart` and the app
  tests run a first run through welcome, chat and plan.
- [ ] Fix what those tests find.
- [ ] Commit `test(onboarding): cover the chat onboarding end to end`.

### Then

Milestone end, per `CLAUDE.md`: the independent review (Opus 5.5 high) and its fixes, the
full suite, then the simulator walk for Fawad (dark and light, a container habit, a
no-container habit, social media, fixing an answer).
