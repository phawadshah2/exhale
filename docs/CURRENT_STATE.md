# Current state

Updated 2026-11-14 (paywall milestone closed). Earlier: `docs/history/` (latest
`2026-11-13_paywall_build_state.md`: P1 to P11 and App Store Connect details).

## Where we are

| Milestone | Status |
|---|---|
| M1 to M3, M5 release candidate | Done, merged to `main` (51e0bc6) |
| M6, M7 (plan, logs, stages), polish rounds | Done on `feat/plan-and-stages`, not merged |
| Onboarding redesign 2 (chat) | Done on `feat/onboarding-chat-prototype`, not merged |
| Paywall | Done on `feat/paywall`: reviewed, full suite, walked (2026-11-14) |
| M4 Multiple habits | Parked on `feat/multi-habit` |

Launch still needs: Export/Import, iCloud sync (CloudKit), Stay at zero
(`docs/decisions/2026-11-10-monetization-and-sync.md`).

## Paywall close-out (2026-11-14)

- Review: Review focus 1 to 5 hold. Fixed: startup caches a known access and retries an
  unknown one; the locked sheet scrolls at large text; Settings' Subscription date wraps
  at large text.
- Changed with Fawad on the walk: every paywall state flows from the top (spare height
  above the button); the button sits where the chat, plan and welcome put theirs (links
  in the fine print's slot, 44 pt targets into the inset); no-price "What you get" has
  plain lines ("Go from 12 a day to 0", "Extra time when it gets hard", "Your data stays
  private"); the headline is 28 pt. Spec §10 and `design/10._paywall/NoPrice.html`.
- Checks: full suite 1435, 1434 passed (the failure fixed in `2db4e19`); after the last
  layout commits, paywall and app tests 166 passed. Format and analyze clean.
- Walked on 440 × 956: all states but Reduce Transparency (no simctl switch) and the
  iPhone SE (its iOS 18 run hung before building).

## Repo

- Stacked: `main` ⊂ `feat/plan-and-stages` (96 commits) ⊂ `feat/onboarding-chat-prototype`
  (+29) ⊂ `feat/paywall` (+28, last `bf7ed68`). Pushed (checked 2026-11-14 against the
  local remote refs): `feat/paywall` and `feat/onboarding-chat-prototype` match origin;
  `feat/plan-and-stages` is 1 ahead (`0b621fd`, docs only, already inside the onboarding
  branch on origin). Untracked on purpose: `design/all-designs.html`,
  `design/figma-import/`.
- Read to continue: this file, `CLAUDE.md` (Status, Git). Nothing else is needed for the
  merge.
- `stash@{0}` (splash hack) unused this session.

## Next action

Push `feat/plan-and-stages` (1 commit), then merge the three into `main` in order
(plan-and-stages, then onboarding-chat-prototype, then paywall), each through a PR from a
compare link once the previous one is merged; Fawad pushes or asks for the commands. Then the real iPhone pass, including a sandbox purchase,
restore and expiry.

## Open

- For Fawad: privacy policy URL (`LegalLinks.privacy`, the link hides while null); Terms
  link in the App Store description; check the `.storekit` in Xcode (Edit Scheme →
  Options); before submission: group display name, review screenshots, Family Sharing,
  App Privacy.
- Review notes, not fixed: a sandbox Annual reads as a trial (period under 8 days);
  Lifetime over a live Annual hides Manage; a refunded subscription's "ended on" uses its
  expiry; a resubmitted first run saves only the plan.
- Found in passing: the splash overflows at 200% text on 375 × 667.
- Smallest iPhone: on 375 × 667 the paywall button sits 22 pt above the other pages'
  (no bottom inset for the links to reach into).
- Payment reminders spec (day 5) is needed in the same release.
- Earlier walk items: Reduce Transparency, 200%, a priced drink in Edit plan; chat spec
  items waiting on Fawad (answer-fixing rule, tagline drafts, Other habit and price
  fields, the day's answer bubble); iPhone review list (Home taps, "Add a price" scroll,
  Edit plan spacing, status bar glass).
