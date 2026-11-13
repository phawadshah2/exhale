# Current state

Updated 2026-11-13 (handoff: paywall P1 to P4 committed, last `77277d5`; P5 next).
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
| Paywall | Research, designs, spec and plan done on `feat/paywall` (2026-11-13); P1 to P4 done; P5 next |
| M4 Multiple habits | Parked on `feat/multi-habit` |

## Current goal: paywall (then iCloud sync, Export/Import, Stay at zero)

Decisions: `docs/decisions/2026-11-10-monetization-and-sync.md`. Hard paywall after the
plan reveal; Annual (7-day trial, default), Monthly, Lifetime; nothing free after the
trial; StoreKit 2 via `in_app_purchase` 3.3.1 and `in_app_purchase_storekit` 0.4.17
(added with Fawad's yes, 2026-11-13).

App Store Connect: agreements, bank, tax Active; Small Business Program awaiting email.
Products: Annual US$34.99 (7-day free intro), Monthly US$7.99 (group `Exhale`), Lifetime
US$59.99; grace 16 days. Sandbox tester (UAE): check sign-in on device. Before
submission: group display name, review screenshots, Family Sharing (irreversible),
privacy and terms URLs, App Privacy.

## Repo

- `feat/plan-and-stages` pushed, not merged, no PR, CI not read.
- `feat/onboarding-chat-prototype`: local ahead of origin (corrections round, docs,
  decisions, this handoff). Nothing pushed this session. Untracked on purpose:
  `design/all-designs.html`, `design/figma-import/`.
- `feat/paywall` (off `feat/onboarding-chat-prototype`): docs, designs, P1 to P4
  committed (last `77277d5`), tree clean, nothing pushed.
- Checks (2026-11-13): format and `analyze --fatal-infos` clean; each task's tests pass,
  last run 94 passed (`test/app`, splash, `test/features/paywall`). Full suite: not run
  since the 1279 pass (due at the milestone end).

## Paywall

- Spec `docs/superpowers/specs/2026-11-13-paywall-design.md`, plan
  `docs/superpowers/plans/2026-11-13-paywall.md` (P1 to P11), designs
  `design/10._paywall/`, research `docs/research/2026-11-13-paywall-research.md`.
- Agreed with Fawad: the paywall (stat card, three steps, three plan cards, no scroll), the
  welcome back (the reveal with two lines changed), the locked screen (Home behind glass).
- Plan and its planning calls approved by Fawad (2026-11-13): Settings says "Paid until";
  walks use `--dart-define=FAKE_STORE=…` (debug only); schema v12 caches the last access.
- Done: P1 `resolveAccess`; P2 schema v12 access cache (no trial flag cached; fixture
  `exhale_v11.sqlite`); P3 `StoreRepository` over `StoreKitGateway`, test default store
  Lifetime; P4 `accessProvider`, 3 s startup read, refresh on resume. Deviations are noted
  under each task in the plan.
- Plugin facts (read from its source): updates arrive on `purchaseStream`, also after
  each purchase call; purchases are not finished natively. 10 s timeout on offers and
  access only. `offersProvider` has no auto-retry. Nothing gates on access yet.
- Not in this plan, and needed in the same release: the payment reminders spec (the
  paywall promises the day-5 reminder).

## Next action

Run Task P5 with the `execute-plan` skill (Sonnet 5.5 medium). Read: this file, the
plan's header and P5, the spec's §8. Widget tests that pump `ExhaleApp` without
`startupOverrides()` (`splash_page_test.dart`) will need it once the router reads access.

Open: `LegalLinks.privacy` URL and the App Store Terms link (before release).

## Still open from earlier

- Walk: dark, Reduce Transparency, 200%, a priced drink in Edit plan (`stash@{0}` conflicts
  in `splash_page.dart`: keep upstream's switch, send `Success()` to `_startTalking()`).
- Push, merge both branches to `main` (PRs from compare links), real iPhone pass.
- Chat spec items waiting on Fawad: answer-fixing rule, tagline drafts, Other habit and
  price fields, the day's answer bubble.
- iPhone review list: Home taps, "Add a price" scroll, Edit plan spacing, status bar glass.
