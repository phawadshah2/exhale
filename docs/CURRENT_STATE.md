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
| Paywall | Research, designs, spec and plan done on `feat/paywall` (2026-11-13); P1 to P3 done; P4 next |
| M4 Multiple habits | Parked on `feat/multi-habit` |

## Current goal: paywall (then iCloud sync, Export/Import, Stay at zero)

Decisions: `docs/decisions/2026-11-10-monetization-and-sync.md`. Hard paywall after the
plan reveal; Annual (7-day trial, default), Monthly, Lifetime; nothing free after the
trial; StoreKit 2 via `in_app_purchase` 3.3.1 and `in_app_purchase_storekit` 0.4.17
(added with Fawad's yes, 2026-11-13).

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
- `feat/paywall` (off `feat/onboarding-chat-prototype`): docs, designs, P1 to P3;
  nothing pushed.
- Checks: full suite not run since the 1279 pass; P1 to P3's format, analyze and tests
  pass (plus `test/features/settings`).

## Paywall

- Spec `docs/superpowers/specs/2026-11-13-paywall-design.md`, plan
  `docs/superpowers/plans/2026-11-13-paywall.md` (P1 to P11), designs
  `design/10._paywall/`, research `docs/research/2026-11-13-paywall-research.md`.
- Agreed with Fawad: the paywall (stat card, three steps, three plan cards, no scroll), the
  welcome back (the reveal with two lines changed), the locked screen (Home behind glass).
- Plan and its planning calls approved by Fawad (2026-11-13): Settings says "Paid until";
  walks use `--dart-define=FAKE_STORE=…` (debug only); schema v12 caches the last access.
- P1 done (`Access`, `PlanKind`, `StoreTransaction`, `resolveAccess`; 14 tests pass).
- P2 done: schema v12 (`access_state`, `access_plan`, `access_until` in settings),
  `access_cache.dart`, fixture `test/fixtures/exhale_v11.sqlite`. The cache does not keep
  the trial flag: an offline start in the trial shows a paid Annual until the store answers.
- P3 done: `StoreRepository` over a `StoreKitGateway` (the only plugin import),
  `FakeStoreRepository` (test default: Lifetime), `StoreFailure`. Read from the plugin's
  source: updates come through `InAppPurchase.instance.purchaseStream` (also fires after
  every purchase call); purchases are not finished natively, and an unfinished one blocks
  buying that product again. The 10 s timeout covers offers and access only.
- Not in this plan, and needed in the same release: the payment reminders spec (the
  paywall promises the day-5 reminder).

## Next action

Run Task P4 with the `execute-plan` skill (Sonnet 5.5 medium). Read: this file, the
plan's header and P4, the spec's §7.

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
