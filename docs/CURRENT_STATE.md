# Current state

Updated 2026-11-13 (paywall P1 to P10 committed; P11 next).
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
| Paywall | Research, designs, spec and plan done on `feat/paywall` (2026-11-13); P1 to P10 done; P11 next |
| M4 Multiple habits | Parked on `feat/multi-habit` |

## Current goal: paywall (then iCloud sync, Export/Import, Stay at zero)

Decisions: `docs/decisions/2026-11-10-monetization-and-sync.md`. Hard paywall; Annual
(7-day trial, default), Monthly, Lifetime; StoreKit 2 via `in_app_purchase` 3.3.1 and
`in_app_purchase_storekit` 0.4.17.

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
- `feat/paywall` (off `feat/onboarding-chat-prototype`): docs, designs, P1 to P10
  committed, nothing pushed.
- Checks (2026-11-13, after P10): format, `analyze --fatal-infos` clean; paywall and
  settings tests pass (147); `test/app` after P9. Full suite: not run since 1279 (due).

## Paywall

- Spec `docs/superpowers/specs/2026-11-13-paywall-design.md`, plan
  `docs/superpowers/plans/2026-11-13-paywall.md` (P1 to P11), designs
  `design/10._paywall/`, research `docs/research/2026-11-13-paywall-research.md`.
- Agreed with Fawad (2026-11-13): the designs, the plan, Settings' "Paid until", walks
  with `--dart-define=FAKE_STORE=…` (debug only).
- Done (deviations noted under each task in the plan): P1 `resolveAccess`; P2 schema v12
  access cache; P3 `StoreRepository` over `StoreKitGateway` (test default: Lifetime); P4
  `accessProvider`, 3 s startup read, refresh on resume; P5 `launch.dart` (splash and
  redirect), keyed placeholder `PaywallPage`/`LockedPage`; P6 welcome back
  (`RestartUnstartedPlan`, `replaceAll`), the reveal pushes the paywall unless entitled;
  P7 `daysToCover`, `PaywallCopy`, `paywallContent` (`PaywallStep.rowTitle` added); P8
  the paywall screen (icon row under 540 pt of body; `NativeUi.openUrl`); P9 locked; P10
  Settings' Subscription card.
- Plugin: updates arrive on `purchaseStream` (also after each purchase call), purchases
  are not finished natively; 10 s timeout on offers and access; `offersProvider` no retry.
- Not in this plan, and needed in the same release: the payment reminders spec (the
  paywall promises the day-5 reminder).

## Next action

Run Task P11 (a store for simulator walks) with `execute-plan` (Sonnet 5.5 medium), then
the milestone end (CLAUDE.md workflow 4). Read: this file, the plan's header and P11.
Open: `LegalLinks.privacy` URL, App Store Terms link (before release). Walk: welcome back
clears the status bar; the paywall at 393 × 852 and 375 × 667, the locked sheet, dark,
200% text, Reduce Transparency (fit is tested with the app fonts, not yet seen).

## Still open from earlier

- Walk: dark, Reduce Transparency, 200%, a priced drink in Edit plan (`stash@{0}` conflicts
  in `splash_page.dart`: keep upstream's switch, send `Success()` to `_startTalking()`).
- Push, merge both branches to `main` (PRs from compare links), real iPhone pass.
- Chat spec items waiting on Fawad: answer-fixing rule, tagline drafts, Other habit and
  price fields, the day's answer bubble.
- iPhone review list: Home taps, "Add a price" scroll, Edit plan spacing, status bar glass.
