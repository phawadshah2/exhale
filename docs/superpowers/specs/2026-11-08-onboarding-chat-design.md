# Onboarding chat: questions inside the chat

Signed off by Fawad on 2026-11-06 on the canvas
(https://claude.ai/artifact/EMRb3MqhssfA6k4qLHTCQa, page "Questions inside the chat": dark
row 1, light row 2, habit picker board E, green "Decided" note). Branch
`feat/onboarding-chat-prototype`. This replaces the prototype's chat step (1efc0c1): its
answer dock above the button goes, and every question becomes an Exhale message with its
controls inside.

First run stays welcome, chat, plan (`OnboardingStep.welcome, chat, deal`). Changing the
habit later keeps the old habit, amount, cost and plan steps; this spec does not touch them.

## 1. The screen

- **App bar**: edge to edge, glass (`GlassSurface`; solid under Reduce Transparency), over
  the chat, which scrolls under it. Exhale's avatar (36 pt) with a green dot at its lower
  right (`success` colour, no "online" label), "Exhale", and "here to help. Unfortunately."
  (the prototype's "typing…" swap stays while Exhale types).
- **Chat**: fills from the top, newest at the bottom. New messages scroll into view. When
  the user has scrolled back up, a round glass button (44 pt, "Jump to the newest message")
  sits at the chat's lower right and scrolls to the newest.
- **Dock**: solid, with a hairline on top. "See my plan" (`ChevronButton`), off until every
  question is answered, then opens the plan screen. Under it, the tagline (section 5).
- **Bubbles** *(revised by Fawad, 2026-11-08: as `main`'s welcome chat, section 9)*:
  Exhale's on the left with the avatar on the last of a run; the user's on the right. No
  time or ticks inside bubbles.
- **Colours** *(revised, section 9)*: Exhale's bubbles and cards in the emphasis colour,
  the user's in the raised surface, as `main`'s welcome chat. The money card is pale mint in
  light mode. The glass bar takes a white tint in light mode. All from theme tokens.

## 2. Questions are cards

A question is an Exhale message with its controls under the text, inside the same bubble
(284 pt wide; the habit card 300 pt). When answered:

1. the controls fold away (animated size; instant under Reduce Motion), leaving a plain
   Exhale message with the question's text;
2. the answer lands as the user's bubble, with ticks;
3. Exhale replies and the next card arrives.

Only the newest question is open, unless an earlier one is reopened (section 4).

## 3. The script

Sample: Alex, vaping, 12 a day, a $10 pod lasts 30. Units come from the habit
(`habit.units`, for example "sessions").

**Opening.** The three excuses arrive as the user's bubbles ("just one more", "it's
basically flavoured air", "I'll quit properly on Monday"), ticks going to read. Exhale:
"Heard them all, by the way. Twice." Then the name card.

**Name card.** "Before you send me another excuse: who am I talking to?"
- A field "Your first name" (24 characters, given-name autofill, capitalised words, Send
  on the keyboard) and a round send button (arrow up, 44 pt, "Send your name"); a blank
  name does nothing.
- "I'd rather not say" pill.
- Answer bubble: the name, or "I'd rather not say". Exhale: "Alex. Lovely name. Shame about
  the excuses." (skipped: "A mystery. Your excuses weren't.").

**Habit card** (board E). "Lucky for you, helping is my whole job. Let's start with the
obvious. What are we quitting?" Text-sized pills in this order (Fawad, 2026-11-08):
Vaping, Smoking, Alcohol, Nicotine pouches, Energy drinks, Caffeine, Junk food, Social
media, Other (dashed border).
Rows wrap to more rows when the text is large.
- Other swaps the pills for a field "What is it?" (30 characters, placeholder "Gaming") and
  a send button, plus "Back to the list". The custom unit is "time". *(Assumption: the
  canvas only says "Other for custom".)*
- Answer bubble: the habit's name (Other: what they typed). Exhale: the habit's reply
  (`OnboardingCopy.habitReply`, for example "Ah. The USB stick you inhale.").

**Amount card.** "Be honest. How many times a day do you vape? A real number. Not a Monday
one." (the verb per habit, as in the prototype). A stepper well: minus ("Less"), the number
large with "sessions a day" under it, plus ("More"); 1 to 80 (`PlanValidation`), starting
at the habit's typical amount. A full-width primary button "That's about right".
- Answer bubble: "12 a day".

**Price card** (habits with a price). The amount reaction, then the ask, in one message:
"Respectable. For now. Now the painful bit. What does a pod cost you?" (no container: "What
does one cost you, roughly?").
- Five price chips scaled from the habit's base price (×0.5, 0.8, 1, 1.2, 1.5, whole units,
  no duplicates; $5 $8 $10 $12 $15 for vaping) and an "Other" chip. Other swaps the chips for
  a decimal field and a send button, validated like the cost step (up to
  `HabitValidation.maxPriceCents`). *(Assumption: the canvas shows the chip only.)*
- A line "USD · Change": the current currency (from the region, `CurrencyChoices`) and the
  existing currency wheel. *(The line shows the stored symbol, for example "$ · Change".)*
- "I'd rather not know" pill.
- Answer bubble: "$10", or "I'd rather not know". Skipped: Exhale says the skip reply and
  goes to the day card; no money card.
- Social media has no price: Exhale says the amount reaction with the no-price line and goes
  to the day card.

**Per-pod card** (vaping pod, smoking pack, nicotine pouches can). "And how many sessions
does one pod last? Ballpark is fine. I'm not your accountant." Stepper by 5 ("5 fewer", "5
more"), 5 to 100 (`HabitValidation.maxUnitsPerContainer`), "sessions a pod", and under it
"About one pod every 2½ days" (`per / amount` days, rounded to a half; "every day" at 1 or
less). "That's about right".
- Answer bubble: "30 a pod".

**Money card** (after a price). "YOUR HABIT, IN NUMBERS", "$4.00 a day", "$1,460 a year",
and "12 a day, a $10 pod lasts 30. Your rent is jealous." (no container: "3 a day at $7
each. Your rent is jealous."). Then "Two more, then your plan."

**Day card.** "I'll spread your 12 so they don't all land before lunch. When does your day
start, and when's lights out? Roughly. I won't check." Two rows in one well:
- sun icon, "Up at" / "7:00 AM", minus and plus ("Wake up 30 minutes earlier", "… later");
- moon icon, "Lights out" / "11:00 PM", minus and plus ("Lights out 30 minutes earlier",
  "… later").
- Steps of 30 minutes. A step that would leave less than `DayWindow.minAwakeMinutes` awake
  is off. Starts from the form's wake and bed times.
- Under them: "16 h awake · one every 1 h 20 min". Then "That's my day".
- Answer bubble: "7:00 AM to 11:00 PM". Exhale: "That's everything, Alex. Your plan's ready.
  Brace yourself." The prototype's day-dots card is dropped. *(Assumption: the canvas ends
  at the open day card.)*

"See my plan" turns on.

## 4. Fixing an answer *(assumption, for Fawad to confirm)*

- Tapping one of the user's answer bubbles reopens its card in place, prefilled with the
  current answer; any other reopened card folds back unchanged. The excuses are not
  tappable. Nothing is tappable while Exhale is typing.
- Each answer bubble is a VoiceOver button: "Alex. Double tap to change."
- Sending again updates that bubble and folds the card. Exhale's later messages that quote
  an answer re-read it (the name reply, the amount reaction, the money card, "your 12", the
  plan-ready line), so the chat never shows a stale number. No new messages arrive.
- Changing the habit is the exception: every message after the habit answer goes, the
  amount, price and per-pod answers reset to the new habit's defaults, and the chat carries
  on from the habit reply. "See my plan" turns off until the day is answered again.
- Picking the same habit just folds the card.
- Switching the price between a price and "I'd rather not know" changes what follows (the
  per-pod question and the money card), so it works like a new habit: what came after goes
  and the chat carries on from the price.

## 5. Tagline

One line under "See my plan". When an answer lands, the old line slides up and fades out
and the new one slides in from below (cross-fade only under Reduce Motion). It is a polite
live region for VoiceOver.

| After | Line |
|---|---|
| Start | Nothing you type leaves your phone. |
| The excuses | Three excuses before hello. Bold opener. |
| Name | Nice to meet you, Alex. Your excuses already have. |
| Name skipped | *Fine. Your excuses introduced themselves.* |
| Habit | Vaping. Flavoured air with a monthly bill. (one line per habit, below) |
| Amount | 12 a day. Your lungs have filed a complaint. *(non-nicotine: "12 a day. Noted. Judged, slightly.")* |
| Price | $10 a pod. Your wallet felt that. *(no container: "$7 each. Your wallet felt that.")* |
| Price skipped | *Not knowing is still paying.* |
| Per pod | $1,460 a year. That's a holiday you inhaled. *(non-inhaled: "…a holiday you spent on this.")* |
| Day | *Plan's ready. No more Mondays.* |

Habit lines (vaping from the canvas, the rest drafts): smoking "Smoking. A classic with a
cough."; nicotine pouches "Pouches. Discreet, not free."; caffeine "Caffeine. Borrowed energy,
paid back at 3 PM."; energy drinks "Energy drinks. Rent for your heartbeat."; alcohol
"Alcohol. The weekend wants a word."; junk food "Junk food. Snacks are not a personality.";
social media "Social media. Hours you'll never get back."; Other "Something else. Mysterious.
Expensive, probably."

*Italic lines are drafts for Fawad to approve or rewrite.*

## 6. iOS look, motion and access

- Cupertino icons through `AppIcons`; no ink ripples; selection haptics on pills, chips and
  steppers, a light impact on each send.
- Pills look text-sized (12 pt text, 28 pt tall) but each has a 44 pt hit area. Every other
  control is at least 44 pt.
- Text at 200%: cards and bubbles grow, pills and chips wrap, the time drops under the text
  when it does not fit, the dock keeps one line of tagline (ellipsis).
- Each card is a VoiceOver group named for its question ("Your name", "What are we
  quitting?", "Times a day", "Price of a pod", "Sessions per pod", "Your day"). The status
  line reads as text ("Read 9:42 AM"). New Exhale messages are announced.
- Reduce Motion: no typing delays beyond a short beat, no slide in the tagline, cards fold
  without animating.
- The keyboard: the dock stays pinned above it, and the chat scrolls so the open card stays
  in view.

## 7. Data

Answers write to `OnboardingFormController` as the prototype does (name to settings on
submit; habit, start limit, price text, units per container, currency, wake and bed times).
`submit()` is unchanged. Habits without a container question keep one unit per container.

## 8. Out of scope

The welcome and plan screens as prototyped (only their tests are added here), the
change-habit steps, showing the name on Home, the paywall.

## 9. The chat as `main`'s welcome (Fawad, 2026-11-08)

Copied from the welcome chat on `main` (`welcome_step.dart`, `you_bubble.dart`,
`exhale_bubble.dart`):

- **Colours**: Exhale's bubbles, cards and typing dots in `exhale.emphasis` with
  `onEmphasis` text; the user's in `surfaceContainerHighest` (light) or
  `surfaceContainerHigh` (dark) with `onSurface` text; no hairlines. Card controls take
  their ink from Exhale's bubble.
- **Shape and sides**: the user's on the right, 20 pt corners, the tail corner 6 pt at the
  bottom right, the top right 6 pt on a continued line, and the last line of a run back to
  20 pt there. Exhale's on the left after a 32 pt avatar and a 9 pt gap, the bottom left
  6 pt and the top left 6 pt on a continued line. Bubbles up to 280 pt, 14 by 10 padding.
  Typing is the three dots, no bubble, at the avatar's offset.
- **Gaps**: 4 pt within a run, 12 pt when the side changes.
- **Motion**: each new message fades in and rises 12 pt, over 450 ms (`main`: 300 ms),
  once; under Reduce Motion it just appears. The opening excuses come 600 ms apart.
- **Opening**: "You · 9:42 AM" (the current time) centred above the excuses ("You"
  semibold).
- **Status** (Fawad, 2026-11-08): no time or ticks in bubbles. Under the last of the three
  excuses only, right aligned and faint: "Sent 9:42 AM", then "Read 9:42 AM" 1.6 s after
  the last lands. Answers show no status; Exhale replies 1.9 s after one. Reduce Motion goes
  straight to read.
- **Money card** (Fawad, 2026-11-08, mockup D): "YOUR NEXT 12 MONTHS" on Exhale's bubble
  colours. "As it is" with the year in danger and a full danger bar; "With the plan" (the
  suggested pace's daily limits over 365 days) with a grey bar at its share; "You keep $X."
  with the amount in success. The per-day figure and the price line are gone.
- **Glass bar**: fill at 0.45 opacity. **Keyboard**: the dock stays behind it.
- **Jump button**: follows up until the newest message is in view (the list estimates
  rows it has not built).
- **Dock**: the tagline 4 pt under the button, no reserved space under it; the dock's
  surface reaches the bottom edge and the button sits 8 pt above the safe area. The welcome
  and plan frames place their button the same way, so it does not move between steps.

## 10. Plan cards show their stages (Fawad, 2026-11-08)

- **Closed card**: a 38 pt stage ring left of the name, one segment per stage (length by
  days, darker for a higher limit); inside, how long a stage lasts ("7d", "2–3d").
- **Selected card**: header, then "12 stages, 7 days each", then a grid of squares with
  each square's limit inside, then "Each square is a day; its number is that day's limit.
  Today is outlined." It replaces the blurb, the dots and the rules.
- **Grid**: one square a day (plus the quit day, a check) while that fits 14 × 7; longer
  plans use one square per week, or per N weeks, and say so ("its number is the daily
  limit when it starts"). 7 to 14 columns and 4 to 7 rows, the fewest columns that fit, so
  shorter plans get bigger squares; figures scale with the square (7 to 14 pt), fixed
  against text size, the grid read by VoiceOver as one summary line. Today outlined, a
  drop in bold, fill the emphasis colour at a strength set by the limit.
- **Your date**: after "Pick my own date", a fourth card, styled like the others, with the
  picked date; it stays after another pace is chosen and selects that date again.
- **Chat smoothness**: a new message grows into place (height with its fade and rise),
  and the list follows the newest message frame by frame instead of restarting a scroll
  animation on each change.

## Tests

- `OnboardingChat` (the script, fake timers, Reduce Motion on): the opening order; each
  answer writes the form; the branches (container habit, no-container habit, social media,
  price skipped, name skipped, Other habit, Other price); "See my plan" only after the day.
- Fixing: reopening the name updates the reply in place; changing the amount updates the
  reaction, money card and "your 12" with no new messages; changing the habit drops later
  messages and resets the amounts; the same habit changes nothing.
- Day card: steps of 30 minutes, the minimum awake window turns a step off, the summary line.
- Per-pod caption: 30 a pod at 12 a day is "every 2½ days"; at or under 1 day is "every day".
- Widget: a full first run from the welcome to the plan screen with taps only; the tagline
  changes after each answer; the jump button appears when scrolled back.
- Accessibility: card groups and labels, 44 pt targets (`meetsGuideline`), text at 200% has
  no overflow, light mode and Reduce Transparency render.
- Restore the onboarding page, app and accessibility tests broken by the prototype, and add
  `welcome_step_test.dart` back for the new welcome screen.
