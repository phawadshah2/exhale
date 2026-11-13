# Paywall design

Date: 2026-11-13. Branch `feat/paywall` (off `feat/onboarding-chat-prototype`).
Product decisions: `docs/decisions/2026-11-10-monetization-and-sync.md` (locked by Fawad).
Research behind the paywall's content: `docs/research/2026-11-13-paywall-research.md`.
Designs: `design/10._paywall/` (agreed by Fawad, 2026-11-13).

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
  details; they get their own spec after this one. The paywall promises the day-5
  reminder, so that spec must ship in the same release as this one.
- iCloud sync, Export/Import, the second-phone "Welcome back / Use my plan" flow that
  needs iCloud, Stay at zero.
- Win-back and promotional offers, offer codes.

## 4. Anti-goals

- No data leaves the phone. No analytics, no receipt validation server, no account.
- No free tier and no "close" on the paywall.
- No dark patterns: real prices from StoreKit, the steps state the charge day and
  amount, Restore, Terms and Privacy always visible.
- No invented proof: no testimonials, ratings or user statistics. Every figure on the
  paywall comes from the user's own answers or the App Store price.
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
from this screen (it opens on its own, not after the chat). Design:
`design/10._paywall/WelcomeBack.html`.

## Colours (all screens here)

No colour is hard-coded. Every fill uses the theme's emphasis colour, as onboarding, the
welcome chat and the plan reveal already do. On a new install that is the default Ink
accent (ink fill and white text in light mode, paper fill and ink text in dark). The
welcome back and the paywall are always Ink in practice, since the accent can only be
changed in Settings after paying. The locked screen and Settings follow the user's
chosen accent, as Home does.

## 10. The paywall

Design: `design/10._paywall/Paywall.html` (every state, to scale, live). One screen, no
scrolling at the standard text size. Top to bottom on a regular iPhone:

1. Back chevron (to the reveal, to change the pace), shown only when the paywall was
   opened from the reveal or the locked screen, and "Restore" at the top right. No close
   button.
2. Headline: "Quitting is hard. Trying Exhale is free."
3. Stat card: "{N} days" and "of {pods} costs more than a year of Exhale.", with the
   small label "FROM YOUR ANSWERS".
4. Three steps down the page, each a small filled icon joined by a visible line:
   "Today / Everything opens. Your plan starts.", "Day 5 / We remind you, before any
   charge.", "Day 7 / Your year starts: {annual price}."
5. Three plan cards, full width, stacked, Annual selected by default. Each has a radio
   dot, the name with one line under it, and the price with its period under it:
   - Annual: "Your plan + a year at zero", "{price}" / "per year". The "7 DAYS FREE" tag
     sits on the card's top edge at the right, above the price.
   - Monthly: "No trial. Cancel any time.", "{price}" / "per month".
   - Lifetime: "Yours for good. No renewals.", "{price}" / "once".
6. The button, then "Terms" and "Privacy". The button sits exactly where it does on the
   chat, the plan reveal and the welcome: the links take the fine print's place, and
   their 44 pt tap targets reach into the bottom inset (Fawad, 2026-11-14).

What follows the selected plan (the plan cards themselves never change):

| | Annual (trial) | Monthly | Lifetime |
|---|---|---|---|
| Stat card | N days … "a year of Exhale" | N days … "a month of Exhale" | N days … "Exhale for good" |
| Step 1 | Today: Everything opens. Your plan starts. | Today: Everything opens. {price} is charged. | Today: Everything opens. {price}, once. |
| Step 2 | Day 5: We remind you, before any charge. | Each month: Renews at {price} until you cancel. | After that: Nothing more to pay. No renewals. |
| Step 3 | Day 7: Your year starts: {price}. | Any time: Cancel in Settings, keep the month. | For good: Staying at zero is included. |
| Button | Start my free week | Subscribe | Buy once |

Variants:

- **Small iPhones** (not enough height for the steps down the page): the three steps
  become one row of three icons with a word under each ("Today / Full access", "Day 5 /
  We remind you", "Day 7 / Year starts"; the Monthly and Lifetime rows as in the design).
  *(Builder's call: the height at which it switches; the design switches for 375 × 667.)*
- **No stat available** (the habit has no price, the user skipped it, the price's
  currency differs from the App Store's, or N is longer than the offer's period): the
  three steps down the page when they fit (the icon row on a small iPhone), then "WHAT
  YOU GET" with three plain lines: "Go from {start limit} a day to 0", "Extra time when
  it gets hard", "Your data stays private" (two lines on a small iPhone, dropping the
  middle one). Any spare height is shared out evenly between the headline, the steps,
  "What you get" and the plan cards, so the cards stay just above the button with no
  hole above them (Fawad, 2026-11-14; `design/10._paywall/NoPrice.html`, option B).
- **Trial already used** (`isIntroductoryOfferEligible(annual)` is false): no tag; the
  headline is "Quitting is hard. Starting isn't."; Annual's steps are "Today /
  Everything opens. {price} is charged.", "Each year / Renews at {price} until you
  cancel.", "Any time / Cancel in Settings, keep the year."; the button is "Subscribe".
- **App Store unreachable** (products not loaded): the headline, the "What you get"
  lines, then in place of the plan cards a card "Couldn't reach the App Store / Check
  your connection. Your plan is saved on this phone." with "Try again"; the button reads
  "Continue" and is disabled.
- **Larger accessibility text**: the page scrolls and the button stays pinned at the
  bottom. At the standard size nothing scrolls on any iPhone iOS 26 runs on.

Rules:

- Prices are StoreKit's localized `displayPrice`. Nothing is hard-coded; App Store
  Connect is the source. The billed amount is the largest price on the screen (Apple's
  rule), so no per-month breakdown of Annual is shown.
- The stat: daily spend = start limit × the unit price from onboarding. N = the offer's
  price ÷ daily spend, rounded up, at least 1 ("1 day", "4 days"). It is shown only when
  the user's currency matches the storefront's currency and N is within the offer's
  period (365 days for Annual and Lifetime, 30 for Monthly). "{pods}" is the habit's
  container or unit word in the plural. *(Builder's call: the word per habit, from the
  existing habit copy.)*
- Purchase results: success → access refreshes → Home (the plan's start is today; an
  Entitled user's plan is not re-dated). User cancelled → stays, silent. Pending (Ask to
  Buy) → a snackbar "Waiting for approval"; access updates via the listener later.
  Failed → snackbar with a plain message.
- Restore: `sync()` (may ask for the Apple ID password), then re-check access. Entitled →
  Home. Nothing found → snackbar "No purchases found for this Apple ID".
- Terms: Apple's standard EULA URL (also added to the App Store description). Privacy:
  Fawad's privacy policy URL (open item, §14).
- Motion: the existing `StepReveal` entrance for each block; nothing decorative. Reduce
  Motion: everything just appears.

## 11. Locked screen (Lapsed)

Design: `design/10._paywall/LockedSettings.html`.

- The user's real Home behind a glass sheet: blurred, dimmed, not tappable, with no tab
  bar and no log button. The sheet cannot be dismissed.
- The sheet: "Your progress is saved"; "Your {Annual / Monthly / Lifetime} plan ended on
  {date}. Everything here comes back the moment you do."; one line of progress, "{n}
  days on plan · {n} {units} avoided" and "{money} saved · stage {i} of {n}" (the money
  part is left out with no price), from the existing `HomeStats` and plan providers;
  "See offers" (the emphasis button; opens the paywall with a back chevron); "Restore
  purchases" (a text button).
- Reduce Transparency: the sheet is opaque and Home is only dimmed.
- On payment the sheet goes and Home is exactly as it was: the plan keeps its dates,
  nothing is re-dated.

The change-habit flow (`ChangeHabitPage`) is only reachable while Entitled and never
shows the paywall.

## 12. Settings

Design: `design/10._paywall/LockedSettings.html`. A "Subscription" `SectionCard`
between Appearance and the trigger tile, three rows: the current plan ("Annual" with
"Paid until 3 Dec"; in the trial "Free until 20 Nov"; "Lifetime" with "Yours for good"),
Manage subscription › (`showManageSubscriptions()`, hidden for Lifetime) and Restore
purchases.
"Paid until", not "Renews": the StoreKit wrappers do not say whether a subscription will
renew, so the card states only what is known.
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
  for runs started from Xcode. A plain Flutter run does not apply it, so simulator walks
  use a debug-only `--dart-define=FAKE_STORE=neverPaid|lapsed|entitled|offline`, which
  registers the fake store. It is ignored in release builds.

## 14. Open items for Fawad (not blocking the plan)

- Privacy policy URL (also needed for App Store submission).
- The Terms link in the App Store description (Apple's standard licence has no field for
  it).

## 15. Left to the builder

Exact spacing within the onboarding style, accessibility labels for the plan cards
(VoiceOver reads the name, its line, the price and period, "7 days free", selected), the
Cupertino icons for the steps, the height at which the steps become the icon row, the
habit word in the stat, the cached-access storage, the exact error messages.
