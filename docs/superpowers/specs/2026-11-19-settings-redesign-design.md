# Settings redesign

Agreed with Fawad on 2026-11-19. Design: `design/12._settings/` (take 3; the README lists
where this spec overrides the mockup). Branch `feat/settings-redesign`, stacked on
`feat/lock-screen` (it moves that branch's temporary Lock Screen switch).

Project 2 of four before the real iPhone pass: after Lock Screen presence, before
notifications and the breathing exercise.

## Why

Fawad wants a proper Settings for the user. Today it is five unrelated cards with no
headers, no About or legal rows, and no place for what is coming. It should read like a
finished iOS app's Settings: everything a user expects has an obvious home, and later
projects (notifications, Your data) add rows without another redesign.

## Goals

1. Two tiles at the top: the plan and the subscription.
2. Plan shortcuts that open the pages that already exist.
3. Grouped sections for the preferences, each row with a soft icon tile.
4. A Subscription sheet with the right options for each kind of access.
5. "Redeem a code" in that sheet, on the paywall and on the locked screen, so Fawad's
   one-time Lifetime links and typed codes both work.
6. An About section: Rate, Send feedback, Privacy policy, Terms of use, version.

## Non-goals

- No plan, habit or price editing inside Settings. The rows link to the existing pages.
- No second habit. Change habit swaps the one habit, as today.
- No notifications and no Your data (iCloud, Export, Import). Their projects add the rows.
- No app icon picker. `AppIconChoice` stays stored and unused; the iOS project has no
  alternate icons.
- No own unlock codes or links. App Review 3.1.1 allows only Apple's offer codes.
- No change to the lapsed flow: the locked screen still covers the app.

## Anti-goals

- "Coming soon" rows or placeholder features (App Review rejects them).
- Settings growing its own copies of plan screens that drift from the real ones.
- A subscription screen that hides how to stop paying.

## Approaches

1. **Rebuild `SettingsPage` in place, pickers as sheets. Chosen.** New tile and row
   widgets; the existing day, theme and accent controls move into glass sheets; the
   Subscription sheet is a new `showAppDraggableSheet`. One route, matches the iOS look
   rules (sheets, not pushed pages, for small choices).
2. **Settings as a hub of pushed sub-pages** (`/settings/subscription`, `/settings/day`).
   More routes and more back-navigation for choices that fit in a sheet. Rejected.
3. **A native iOS Settings bundle** (rows in the iPhone's own Settings app). Splits Settings
   across two apps and can't show the plan or subscription. Rejected.

## The screen, top to bottom

Large title "Settings", the page margin and `ReplayOnVisit` / `ScrollReveal` as today.

### Tiles

Two square tiles side by side (`Card`, 24 pt radius), each with an icon tile, an eyebrow,
a big value and a small line. Each tile is one button with one semantic label.

**Plan tile** (accent-filled icon tile with the habit's icon) opens plan details
(`AppRoutes.planDetailsFor`).

| State | Eyebrow | Value | Line |
|---|---|---|---|
| Plan with a quit date | "<Habit> plan" | quit date ("Jan 12") | "54 days to go" / "1 day to go" |
| Quit day reached or passed | "<Habit> plan" | "Quit day" | the date |
| Plan starts later | "<Habit> plan" | quit date | "Starts Nov 20" |

**Subscription tile** opens the Subscription sheet. It reads `accessProvider`.

| Access | Eyebrow | Value | Line |
|---|---|---|---|
| Entitled, in trial | "Free week" | "N days left" | "Annual from Nov 21" |
| Entitled, trial cancelled | "Free week" | "N days left" | "Free week ends Nov 21" |
| Entitled, Annual / Monthly | "Annual" / "Monthly" | "Active" | "Renews Dec 3" |
| Entitled, Annual / Monthly cancelled | "Annual" / "Monthly" | "Ends Dec 3" | none |
| Entitled, Lifetime | "Lifetime" | "Yours for good" | none |
| Unknown (store unreachable) | the cached plan, or "Subscription" | "Can't check now" | none |

NeverPaid and Lapsed never reach Settings (the router redirects them).

Cancelled means StoreKit reports auto-renew off (Fawad, 2026-11-20). The sheet then says
"ends <date>" or "Free week ends <date>.", drops the Active badge and the charge lines
("Annual starts…", "Cancel before…", "Cancel any time…"), and offers Manage in the App
Store instead of Cancel free week. When the renewal check fails, the wording claims
neither: "Paid until Dec 3" / "Free until Nov 21".

### Plan shortcuts (one group, no header)

- **Edit plan**, value "8 today", opens `AppRoutes.editPlanFor`.
- **Price**, value "$12 a pod" (or "Not set"), opens Edit plan scrolled to the price card.
- **Change habit**, opens `AppRoutes.changeHabitFor`.

### Your day

- **Awake**, value "7 AM – 11 PM" or "Not set", opens the existing Your day sheet
  (`your_day_sheet.dart`).

(Corrected 2026-11-19 while planning: the reset hour has no editor anywhere today, so a
"New day starts" row would be a new feature. It waits for Fawad's call; see Open.)

### Logging

- **Ask what set it off**, a switch bound to `askForTrigger` (today's `TriggerPromptTile`).

### Lock Screen

- **Countdown on Lock Screen**, a switch bound to `showLiveActivity` (today's
  `_LockScreenTile`, moved).

### Appearance

- **Theme**, value "System" / "Light" / "Dark".
- **Accent**, value the accent's name.

Both open one Appearance sheet holding the existing `ThemePreferenceControl` and
`AccentPicker`.

### About

- **Rate Exhale**: the App Store's write-a-review page; hidden until the App Store ID is
  set (Fawad, 2026-11-20). Apple's prompt is kept for a later automatic moment.
- **Send feedback**: Mail, to Fawad's feedback address, subject "Exhale feedback", body
  ending with the app version and iOS version. No Mail account: copy the address and
  say so with `showAppSnackBar`.
- **Privacy policy**, **Terms of use**: open the URLs in Safari's in-app view.
- Footer: "Exhale <version>" from `package_info_plus`.

## Subscription sheet

A glass draggable sheet, title "Subscription", close button. Copy and prices come from the
loaded offers (paywall copy and `PaywallCopy` where it exists). Mockup: `Settings.html` 2 to 4.

**Status card**: plan icon tile, plan name, price and date line, and an "Active" badge for
renewing subscriptions.

**Annual or Monthly**

- *Change plan*: "Pay monthly" (on Annual) or "Pay yearly" (on Monthly), with the price,
  opens Apple's Manage Subscriptions (Apple makes the switch). "Go Lifetime", with the
  price, buys Lifetime through the paywall controller's purchase.
- *Billing*: "Manage in the App Store", "Restore purchases", "Redeem a code",
  "Request a refund".
- Fine print: "Cancel any time in the App Store. <Plan> stays open until <date>, and your
  plan and logs stay on this iPhone either way."

**Free week** (Entitled with `inTrial`)

- Status card: "Free week", "N days left" badge, a bar for days used, "Annual starts
  <date> at <price> a year."
- *After your free week*: "Pay monthly instead" (Manage Subscriptions), "Go Lifetime".
- *Billing*: "Cancel free week" (Manage Subscriptions), "Restore purchases",
  "Redeem a code".
- Fine print: "Cancel before <date> and you won't be charged."

**Lifetime**

- Status card: "Exhale Lifetime", "Yours for good".
- If an Annual or Monthly subscription is still set to renew: an amber note "<Plan> still
  renews on <date>. Lifetime already covers you, so cancel <Plan> to avoid being charged
  again." with a "Cancel <Plan>" pill (Manage Subscriptions). This fixes the paywall
  review note "Lifetime over Annual hides Manage".
- Rows: "Restore purchases", "Redeem a code", "Request a refund".

**Unknown**: the status card says the App Store can't be reached and shows the cached plan;
only "Restore purchases" and "Redeem a code" are offered.

**Behaviour**

- Restore shows a spinner in its row while it runs, and the row is disabled; the result
  uses today's snackbars (`purchasesRestored` / `noPurchases`). This fixes the paywall
  follow-up "Restore has no loading state".
- Restore is offered only in this sheet, the paywall and the locked screen, so Settings no
  longer shows it to entitled users on the main list (the other follow-up).
- Go Lifetime success: the sheet updates to Lifetime and shows a success snackbar. Cancel
  or failure: today's paywall handling.
- Request a refund: Apple's refund sheet for the current transaction (Lifetime's, or the
  subscription's latest). What happens after is Apple's.
- Redeem a code: Apple's offer code sheet. A redemption arrives as a store update;
  `accessProvider` already refreshes on store updates.

## Redeem a code elsewhere

- **Paywall**: a "Redeem a code" text button next to (or under) Restore.
- **Locked screen**: a "Redeem a code" text button under Restore.
- A redeemed link works without the app: the App Store redeems it, and the next launch
  reads the access as today. No deep-link handling in the app.

## Store additions

`StoreRepository` gains, each returning `Result`:

- `presentCodeRedemption()`: Apple's offer code sheet.
- `requestRefund()`: the refund sheet for the current entitlement's transaction.
- `renewingAlongsideLifetime()` (name is the builder's): the plan and renewal date of an
  auto-renewing subscription still set to renew while Lifetime is owned, or none.

`StoreKitGateway` stays the only place the plugin is imported. Where
`in_app_purchase_storekit` lacks a call (likely the refund sheet and the renewal status),
add it to the existing Swift side (`ios/Runner/`, next to `PresencePlugin.swift`) behind
a method channel. `FakeStoreRepository` and `FAKE_STORE` get matching fakes, including a
Lifetime-plus-renewing state for the walk.

## Constraints

- iOS look rules: `AppIcons`, `showAppSheet` / `showAppDraggableSheet`, `showAppSnackBar`,
  `GlassSurface` with the Reduce Transparency fallback, no ink ripples, haptics on switches
  and the purchase.
- Light and dark, Reduce Transparency, 44 pt rows, text up to 200%: tiles grow taller
  and their text wraps; at the largest sizes the two tiles stack.
- VoiceOver: each tile is one button ("Vaping plan, quit January 12, 54 days to go");
  switches announce their state.
- New dependencies: only `url_launcher` and `in_app_review` (decided below).
- Existing settings keys and drift schema are unchanged (no migration).

## Testing

- Widget tests per section: rows, values, navigation targets, switches writing settings.
- Subscription tile and sheet: one test per access state (trial, Annual, Monthly,
  Lifetime, Lifetime with renewing, Unknown), Restore's loading state, Go Lifetime success.
- Paywall and locked screen: the Redeem button calls the repository.
- Fake store covers each new call.
- Walk on the iPhone with `FAKE_STORE` states (debug), then a sandbox redeem of a real
  one-time code once App Store Connect allows codes.

## Left to the builder

- Exact widget split and file names under `lib/features/settings/presentation/`.
- Icons for each row from `AppIcons` (add Cupertino ones where missing).
- How "Price" scrolls Edit plan to the price card (a query parameter or an `extra`).
- Whether the renewal check reads `SubscriptionInfo.status` natively or through the
  plugin, if it supports it.

## Decided by Fawad (2026-11-19)

- Settings also links to the plan (habit, plan, price), with links only, no copies.
- Layout B, take 3: plan and subscription tiles at the top.
- The Subscription sheet with options per state, plus Redeem a code.
- Friends and family get one-time Lifetime offer-code links, one per person, made in App
  Store Connect after launch.
- Add `url_launcher` (Safari's in-app view, Mail) and `in_app_review` (review prompt)
  rather than more Swift. Adding them still waits for Fawad's go-ahead at that task.

## Calls made in the brainstorm (Fawad can overrule)

- No "Soon" rows; no app icon picker.
- Privacy and Terms open in Safari's in-app view; Rate opens write-a-review.
- Restore lives in the Subscription sheet, not the main list.
- Your day and Appearance rows open sheets with the existing controls.

## Open

Still open (none blocks the plan; each has a safe default in it):

1. **"New day starts"**: make the reset hour editable here (new behaviour: logs between
   midnight and the new hour move to the other day) or leave it out. Planned without it.
2. **Feedback address** for Send feedback.
3. **Privacy policy URL** (already open for the submission). Links live in `AppLinks`,
   shared with the paywall; Terms uses Apple's standard EULA (Fawad, 2026-11-20).
   Privacy is left out until set.
4. **Exhale's App Store ID** (App Store Connect, App Information); Rate is hidden until
   it is set.

Builder's calls made while writing (check while reading):

- The Unknown tile shows no "checked" date: settings caches the plan's end date, not when
  it was checked, and this project adds no schema change.
- Request a refund is not offered during the free week (nothing has been charged).
