# Paywall design

Date: 2026-11-13. Branch `feat/paywall` (off `feat/onboarding-chat-prototype`).
Product decisions: `docs/decisions/2026-11-10-monetization-and-sync.md` (locked by Fawad).

## 1. Intent

Exhale is a paid app with a free download. The plan reveal is the moment the user has
seen their own taper, so the hard paywall goes straight after it. Nothing works without an
active trial, subscription or Lifetime purchase, and data is never deleted. Entitlements
are checked on the device through StoreKit 2, offline, with no server and no third-party
SDK, so the privacy label stays "Data Not Collected".

## 2. Goals

- A paywall after the plan reveal: Annual (default, 7-day trial), Monthly, Lifetime.
- Someone who reaches the paywall and leaves keeps their answers: reopening shows the plan
  reveal again, reworded, then the paywall.
- A locked screen when a trial, subscription or Lifetime purchase is no longer active
  (ended, refunded or revoked), showing the saved progress.
- Restore purchases on the paywall, the locked screen and Settings.
- A user already entitled on this Apple account who has no plan goes through onboarding
  with no paywall at the end.

## 3. Non-goals (separate specs)

- Payment notifications (trial day 5, renewal reminder, quit date, subscription ended)
  and the card-failed banner. They need a local notifications dependency and renewal
  details; they get their own spec after this one.
- iCloud sync, Export/Import, the second-phone "Welcome back / Use my plan" flow that
  needs iCloud, Stay at zero.
- Win-back and promotional offers, offer codes.

## 4. Anti-goals

- No data leaves the phone. No analytics, no receipt validation server, no account.
- No free tier and no "close" on the paywall.
- No dark patterns: real prices from StoreKit, the trial timeline states the charge day
  and amount, Restore, Terms and Privacy always visible.
- Logs and plans are never deleted or changed by losing access.

## 5. Constraints

- `in_app_purchase` plus `in_app_purchase_storekit` (its StoreKit 2 wrappers, imported
  directly, so it is listed in `pubspec.yaml`). Adding both is a dependency change:
  ask Fawad before `pub get`.
- Products (App Store Connect, group `Exhale`):
  - `com.phawadshah.exhale.annual`: auto-renewable, 1 year, 7-day free introductory offer.
  - `com.phawadshah.exhale.monthly`: auto-renewable, 1 month, no trial.
  - `com.phawadshah.exhale.lifetime`: non-consumable.
- Billing grace period (16 days) is on; StoreKit keeps the entitlement during it.
- Project rules: iOS look (glass, `showAppSnackBar`, `AppIcons`, no ripples, haptics),
  light and dark, Reduce Transparency, Reduce Motion, 44 pt targets, text to 200%.
- Riverpod 3 hand-written providers reading from `sl`; repositories return `Result` and
  wrap store calls the way `guardStorage` wraps drift.

## 6. Approaches

| | Approach | Trade-off |
|---|---|---|
| **A (picked)** | `in_app_purchase` with its StoreKit 2 wrappers: `currentEntitlements()` (offline, with expiry), `transactions()` (history), `isIntroductoryOfferEligible`, `sync()`, `showManageSubscriptions()` | Matches the locked decision; no native code; offline. No auto-renew status or renewal info, which only the later notifications spec might need. |
| B | `in_app_purchase` cross-platform API only | No offline entitlement list and no trial eligibility; finding the status needs Restore, which can prompt an Apple sign-in. Breaks "checked on the device, offline". |
| C | Own Swift StoreKit 2 bridge over a method channel | Full control incl. renewal info, but more native code to write and test for nothing this spec needs. A small Swift addition stays possible later. |

Fawad picked A (2026-11-13): "trustworthy and more secure". Transactions from
`currentEntitlements()` are already verified by StoreKit on the device.

## 7. Access states

One domain type, computed from StoreKit, never stored as the source of truth:

```dart
sealed class Access
  Entitled(product: annual | monthly | lifetime, expires: DateTime?)   // trial counts
  NeverPaid                                                           // no transactions for our products
  Lapsed(lastProduct)                                                 // history, but nothing current
  Unknown                                                             // StoreKit failed to answer
```

- `currentEntitlements()` holding any of our three products → `Entitled`.
- Else `transactions()` holding any of them → `Lapsed`; else `NeverPaid`.
- `Unknown` (StoreKit error): the app uses the last known access, cached in settings
  (a single enum and date, a convenience for offline starts, not a security boundary). If
  none is cached, it shows the paywall with a "Couldn't reach the App Store, Try again"
  state. *(Builder's call where the cache lives; settings is the natural place.)*
- Checked at startup (before the splash leaves), on every return to the foreground, and
  after each purchase, restore or transaction update. The transaction listener starts in
  `bootstrap.dart`; every verified transaction is finished after access is updated.

## 8. Routing

The splash picks the first screen from the plan and the access:

| Plan | Logs | Access | First screen |
|---|---|---|---|
| none | – | NeverPaid / Lapsed / Unknown | Onboarding (as today) |
| none | – | Entitled | Onboarding; the reveal's button goes Home, no paywall |
| saved | none | NeverPaid / Unknown with no cache | **Welcome back** (the reveal, §9) |
| saved | some | NeverPaid / Unknown with no cache | Paywall |
| saved | any | Lapsed | Locked screen |
| saved | any | Entitled | Home |

A go_router redirect sends every in-app route (Home, Settings, habit, plan, logs,
change habit) to the paywall or the locked screen whenever access is not `Entitled`, so a
lapse found on resume takes effect at once. The paywall and locked screen are new routes
(`AppRoutes.paywall`, `AppRoutes.locked`). "Saved plan with logs and never paid" only
happens for TestFlight testers; it gets the paywall directly so their tracked days are not
re-dated.

## 9. Welcome back (reopened, saved plan, never paid, no logs)

The plan reveal (`DealStep`) exactly as it is today, filled from the saved plan, with two
lines changed (Fawad, 2026-11-13):

- Eyebrow: "Welcome back, Fawad." ("Welcome back." with no name).
- Headline: "Your plan's still here."

Everything else is unchanged: the three pace cards with the saved pace open, "Pick my own
date", the "Go steady · zero by 8 Jan" button, the fine print. The plan is re-dated to
start today, keeping the start limit and the plan length, because no day was tracked.
The button saves any change (replacing the unpaid plan, no confirmation) and opens the
paywall. There is no separate "Start a new plan" button, and no way back into the chat
from this screen (it opens on its own, not after the chat).

## 10. The paywall

Mockup: `.superpowers/brainstorm/` (paywall-v1, approved by Fawad 2026-11-13). Top to
bottom:

1. Back chevron (to the reveal, to change the pace), shown only when the paywall was
   opened from the reveal or the locked screen. No close button.
2. Headline "Your plan is ready, Fawad" ("Your plan is ready" with no name), then the plan
   line: "12 a day → 0 by 14 Jan. Unlock it to start today."
3. Money card: "Exhale pays for itself in N days", from what the user stops spending.
4. Three offer cards, Annual selected by default:
   - Annual: tag "7 days free", the yearly price, "Your plan, plus a year at zero ·
     {monthly equivalent}/mo".
   - Monthly: the monthly price, "Cancel any time".
   - Lifetime: the price, "Pay once, keep it for good".
5. The button: "Start my free week" (Annual with trial), "Subscribe" (Annual without
   trial, Monthly), "Buy once" (Lifetime).
6. Under the button, only for Annual with the trial: the timeline "Today · Everything
   open", "Day 5 · We remind you", "Day 7 · {price} charged".
7. Restore purchases · Terms · Privacy.

Rules:

- Prices are StoreKit's localized `displayPrice`; the monthly equivalent is computed from
  the Annual price in the same currency. Nothing is hard-coded. The App Store Connect
  prices are the source.
- Trial eligibility from `isIntroductoryOfferEligible(annual)`. Not eligible (this Apple
  account used it): no tag, no timeline, button "Subscribe".
- "Pays for itself": the first day d where the money kept by the plan (units avoided
  versus the start limit, times the unit price, summed day by day along the taper)
  reaches the selected offer's price (Monthly: one month's price). Hidden when the habit
  has no price, or N is over 365.
- Products not loaded (offline first launch, StoreKit error): the offers area shows
  "Couldn't reach the App Store" with Try again; the button is disabled.
- Purchase results: success → access refreshes → Home (the plan's start is today; an
  Entitled user's plan is not re-dated). User cancelled → stays, silent. Pending (Ask to
  Buy) → a snackbar "Waiting for approval"; access updates via the listener later.
  Failed → snackbar with a plain message.
- Restore: `sync()` (may ask for the Apple ID password), then re-check access. Entitled →
  Home. Nothing found → snackbar "No purchases found for this Apple ID".
- Terms: Apple's standard EULA URL. Privacy: Fawad's privacy policy URL (open item, §14).

## 11. Locked screen (Lapsed)

From the decisions record: the saved progress (days on plan, units avoided, money kept,
the stage reached), "See offers" (opens the paywall; trial hidden if not eligible) and
"Restore purchases". Reuses the existing stats (`HomeStats`, the plan totals) and card
styles. On payment everything returns as it was: the plan keeps its dates, nothing is
re-dated. *(Builder's call: the exact layout, following Home's stats cards.)*

The change-habit flow (`ChangeHabitPage`) is only reachable while Entitled and never
shows the paywall.

## 12. Settings

A "Subscription" section: the current plan ("Annual · renews 3 Dec", "Lifetime"), Manage
subscription (`showManageSubscriptions()`, hidden for Lifetime) and Restore purchases.
The later "Your data" section from the decisions record will absorb Restore.

## 13. Architecture

- `lib/features/paywall/{data,domain,presentation}` with `paywall_injection.dart`.
- Domain: `Access`, `Offer` (product id, kind, display price, price as a decimal, trial
  eligible), `StoreRepository` (load offers, current access, purchase, restore, manage,
  a stream of access changes). Returns `Result`.
- Data: `StoreKitStoreRepository` over the StoreKit 2 wrappers; maps errors to `Failure`.
- Presentation: `accessProvider` (refreshes on start, resume and the listener),
  `offersProvider`, `PaywallPage`, `LockedPage`, the `DealStep` welcome-back wording.
- Tests use a `FakeStoreRepository`. An Xcode StoreKit configuration file
  (`ios/Runner/Exhale.storekit`, mirroring the three products) is set on the Runner scheme
  so the simulator walk can buy, restore and expire without a sandbox account.

## 14. Open items for Fawad (not blocking the plan)

- Privacy policy URL (also needed for App Store submission).
- Copy review of the paywall lines above.

## 15. Left to the builder

The paywall's spacing and motion within the onboarding style (`StepReveal`, the chevron
button), accessibility labels for the offers (VoiceOver reads name, price, trial), the
cached-access storage, the exact error messages.
