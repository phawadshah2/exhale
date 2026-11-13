# Current state

Updated 2026-11-13 (handoff: paywall designed, specified and planned; no code yet).
Earlier: `docs/history/` (latest `2026-11-09_to_11-11_state_log.md`: onboarding chat and
the corrections round).

## Where we are

| Milestone | Status |
|---|---|
| M1 to M3, first onboarding redesign | Done, merged |
| M5 Release candidate | Done, merged to `main` (51e0bc6) |
| M6, M7 (plan, logs, stages), polish rounds | Done on `feat/plan-and-stages`, walked in the simulator |
| TestFlight build 1.0.0 (1) | Runs fine on Fawad's iPhone (2026-11-06) |
| Onboarding redesign 2 (chat) | C1 to C10 done, reviewed, full suite 1279 passed; walked in part |
| Monetization and sync decisions | Locked 2026-11-10 |
| App Store Connect payments | Set up 2026-11-10/11 (below) |
| Paywall | Research, designs, spec and plan done on `feat/paywall` (2026-11-13); P1 to P11 not started |
| M4 Multiple habits | Parked on `feat/multi-habit` |

## Current goal: paywall (then iCloud sync, Export/Import, Stay at zero)

Decisions: `docs/decisions/2026-11-10-monetization-and-sync.md`. Hard paywall after the
plan reveal; Annual (7-day trial, default), Monthly, Lifetime; nothing free after the
trial; StoreKit 2 via `in_app_purchase` (dependency change: ask Fawad before `pub get`).

App Store Connect: agreements, bank (AED), W-8BEN and Certificate of Foreign Status Active;
Small Business Program applied, awaiting email. Draft products: group `Exhale` with Annual
`com.phawadshah.exhale.annual` (level 1, US$34.99, 7-day free intro offer) and Monthly
`com.phawadshah.exhale.monthly` (level 2, US$7.99); non-consumable Lifetime
`com.phawadshah.exhale.lifetime` (US$59.99). Grace period 16 days, paid-to-paid. Sandbox
tester (UAE) listed; web verification failed, check sign-in on device.

Before submission: group display name (save hung), review screenshots for the three
products, Family Sharing decision (irreversible), privacy policy and terms URLs, App Privacy.

## Repo

- `feat/plan-and-stages` pushed, not merged, no PR, CI not read.
- `feat/onboarding-chat-prototype`: local ahead of origin (corrections round, docs,
  decisions, this handoff). Nothing pushed this session. Untracked on purpose:
  `design/all-designs.html`, `design/figma-import/`.
- `feat/paywall` (off `feat/onboarding-chat-prototype`): 6 commits, docs and designs only
  (last `fb07adf`), nothing pushed, tree clean.
- Checks: not run since the 1279-pass suite (no code has changed since).

## Paywall

- Spec `docs/superpowers/specs/2026-11-13-paywall-design.md`, plan
  `docs/superpowers/plans/2026-11-13-paywall.md` (P1 to P11), designs
  `design/10._paywall/`, research `docs/research/2026-11-13-paywall-research.md`.
- Agreed with Fawad: the paywall (stat card, three steps, three plan cards, no scroll), the
  welcome back (the reveal with two lines changed), the locked screen (Home behind glass).
- Spec approved by Fawad ("write the plan"). The plan is written but he has not yet said
  it captures what he wants: confirm before P1.
- Planning calls to check with him: Settings says "Paid until", not "Renews"; walks use
  `--dart-define=FAKE_STORE=…` (debug only); schema v12 caches the last access.
- Unverified until the package is installed: how the plugin reports new transactions in
  StoreKit 2 mode (P3 reads its source first).
- Not in this plan, and needed in the same release: the payment reminders spec (the
  paywall promises the day-5 reminder).

## Next action

Get Fawad's yes on the plan, then run Task P1 with the `execute-plan` skill (Sonnet 5.5
medium). Read: this file, the plan, the spec's §7 to §8. Task P3 needs his yes before
`pub get` (`in_app_purchase`, `in_app_purchase_storekit`).

Open: the privacy policy URL (`LegalLinks.privacy`, before release); the Terms link in the
App Store description. Sync stays in the launch build; fallback (1.0.1) on Fawad's call.

## Still open from earlier

- Walk: dark, Reduce Transparency, 200%, a priced drink in Edit plan (`stash@{0}` conflicts
  in `splash_page.dart`: keep upstream's switch, send `Success()` to `_startTalking()`).
- Push, merge both branches to `main` (PRs from compare links), real iPhone pass.
- Chat spec items waiting on Fawad: answer-fixing rule, tagline drafts, Other habit and
  price fields, the day's answer bubble.
- iPhone review: Home card and ring taps, "Add a price" scroll, Edit plan spacing and text
  jump, status bar glass unseen on device, accents and long plans unseen.
