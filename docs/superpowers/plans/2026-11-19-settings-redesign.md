# Settings redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: run with the project's `execute-plan` skill
> (one task at a time: failing test, code, passing test, commit). Steps use checkbox
> (`- [ ]`) syntax for tracking.

**Goal:** A proper iOS Settings: plan and subscription tiles, plan shortcuts, grouped
preference rows, a Subscription sheet per access state with Redeem a code, and an About
section.

**Architecture:** `SettingsPage` is rebuilt in place from small row and tile widgets. The
values the tiles show come from two pure functions, so states are unit-tested apart from
widgets. The store gains three calls: code redemption through the plugin, and refund and
renewal status through a new `exhale/store` method channel in Swift. About actions go
through an `AboutLauncher` built on `url_launcher` and `in_app_review`.

**Tech Stack:** Flutter 3.47.2 / Dart 3.13 (Riverpod 3, get_it, go_router),
`in_app_purchase_storekit` 0.4.17, Swift StoreKit 2, `url_launcher`, `in_app_review`.

**Spec:** `docs/superpowers/specs/2026-11-19-settings-redesign-design.md`. Design:
`design/12._settings/` (the README lists where the spec overrides the mockup).

## Global Constraints

- New packages: only `url_launcher` and `in_app_review`. Ask Fawad before
  `fvm flutter pub add`.
- No drift schema change, no new settings keys.
- No "Soon" rows. No app icon picker. No second habit anywhere.
- iOS look: `AppIcons`, `showAppSheet` / `showAppDraggableSheet`, `showAppSnackBar`,
  `GlassSurface` with the Reduce Transparency fallback, no ink ripples, haptics on
  switches and purchases. Rows at least 44 pt.
- Text to 200%: tiles grow and wrap; the two tiles stack when they no longer fit.
- Prices come from the loaded offers, never hard-coded.
- `StoreKitGateway` stays the only Dart file importing the StoreKit plugin.
- Product ids: `com.phawadshah.exhale.annual`, `.monthly`, `.lifetime` (`PlanKind`).
- Copy is fixed by the spec; quote it exactly. New strings for the sheet live in
  `PaywallCopy`; Settings strings in a new `SettingsCopy`.
- Builds and simulator runs mid-milestone: ask Fawad first, one command per approval.

## Review Focus

1. The free week's last day, and a trial whose end has passed but the store still says
   entitled: the tile says "Ends today", never "0 days left" or a negative (Task 5 test
   `trial ending today says Ends today`).
2. Go Lifetime tapped twice, or while Restore runs: one purchase only; every action row
   is disabled while the controller is busy (Task 6 test `actions are disabled while busy`).
3. The renewal check fails or the store is offline while Lifetime is owned: no amber note
   and no error, the sheet still shows Lifetime (Task 6 test `a failed renewal check
   shows no note`).
4. Text at 200% on a 375 pt screen: no overflow; the tiles stack (Task 7 test `tiles stack
   at 200% on a small phone`).
5. A habit with no price yet, and a plan that starts tomorrow: "Not set" and "Starts …"
   rather than "$0" or "-1 days" (Task 4 tests `no price reads Not set`,
   `a plan starting tomorrow says Starts`).

---

### Task 1: About links and the launcher

**Files:**
- Modify: `pubspec.yaml` (`url_launcher`, `in_app_review`; ask Fawad first)
- Create: `lib/features/settings/domain/entities/app_links.dart`,
  `lib/features/settings/domain/repositories/about_launcher.dart`,
  `lib/features/settings/data/plugin_about_launcher.dart`
- Modify: `lib/features/settings/settings_injection.dart`, `test/helpers/pump_app.dart`
  (register the fake in `setUpTestDependencies`)
- Test: `test/features/settings/domain/feedback_mail_test.dart`,
  `test/helpers/fake_about_launcher.dart`

**Interfaces:**
- Produces:
  - `abstract final class AppLinks { static const Uri? privacyPolicy = null; static const
    Uri? terms = null; static const String? feedbackEmail = null; static const String
    appStoreId = '<from App Store Connect>'; }`. Null hides the row (filled when Fawad
    gives them; spec Open).
  - `Uri feedbackMailUri({required String to, required String appVersion,
    required String iosVersion})`: `mailto:` with subject `Exhale feedback` and a body
    that ends `\n\n—\nExhale <appVersion>, iOS <iosVersion>`.
  - `abstract interface class AboutLauncher { Future<bool> openInApp(Uri url);
    Future<bool> composeMail(Uri mailto); Future<void> requestReview(); }`. `openInApp`
    uses `LaunchMode.inAppBrowserView`; `requestReview` uses `InAppReview.requestReview`
    when `isAvailable`, else `openStoreListing(appStoreId: …)` when `AppLinks.appStoreId` is set, else nothing.
  - `FakeAboutLauncher` records calls; `composeMailResult` controls the return.

- [x] **Step 1:** Ask Fawad to approve `fvm flutter pub add url_launcher in_app_review`.
  Run it once approved.
- [x] **Step 2:** Tests: `subject is Exhale feedback`; `body ends with app and iOS
  versions`; `address is the to`.
- [x] **Step 3:** Run `fvm flutter test test/features/settings/domain/feedback_mail_test.dart`.
  Expected: FAIL.
- [x] **Step 4:** Implement; register `PluginAboutLauncher` in `settings_injection.dart`.
- [x] **Step 5:** Run. Expected: PASS.
- [x] **Step 6:** Commit: `feat(settings): about links and launcher`.

As built: `AppLinks` and `feedbackMailUri` share `app_links.dart`; the query is encoded
with `%20`, not `+` (mail apps read `+` literally). `setupDependencies` and
`setUpTestDependencies` take `about:` (default `FakeAboutLauncher` in tests). Plugin
errors read as false / no-op. `url_launcher` ^6.3.3, `in_app_review` ^2.0.12. Tests 3/3;
Settings page 7/7 after the DI change.

### Task 2: Store additions, Dart side

**Files:**
- Create: `lib/features/paywall/domain/entities/renewing_subscription.dart`,
  `lib/features/paywall/data/storekit/store_channel.dart`
- Modify: `lib/features/paywall/domain/repositories/store_repository.dart`,
  `lib/features/paywall/data/storekit/storekit_gateway.dart`,
  `lib/features/paywall/data/repositories/storekit_store_repository.dart`,
  `lib/features/paywall/data/fake/fake_store_repository.dart`,
  `lib/features/paywall/data/fake/debug_store.dart`
- Test: `test/features/paywall/storekit_store_repository_test.dart`,
  `test/features/paywall/debug_store_test.dart`

**Interfaces:**
- Produces:
  - `class RenewingSubscription { final PlanKind plan; final DateTime renewsAt; }`
    (value equality).
  - `RefundOutcome { requested, cancelled }`.
  - On `StoreRepository`: `Future<Result<void>> presentCodeRedemption();`
    `Future<Result<RefundOutcome>> requestRefund(PlanKind plan);`
    `Future<Result<RenewingSubscription?>> renewingSubscription();` (an Annual or
    Monthly still set to auto-renew; null when none).
  - On `StoreKitGateway`: `Future<void> presentCodeRedemptionSheet()` (plugin:
    `InAppPurchaseStoreKitPlatformAddition().presentCodeRedemptionSheet()`),
    `Future<String> requestRefund(String productId)` (`'requested'` / `'cancelled'`),
    `Future<Map<String, Object?>?> renewingSubscription()` (`{productId, renewsAt}`,
    `renewsAt` ISO 8601 UTC). The last two call `exhale/store` (Task 3), wrapped in
    `store_channel.dart`.
  - Channel failures and timeouts map to `StoreFailure`, as the existing calls do.
  - `FakeStoreRepository` gains `renewing` (a `RenewingSubscription?`) and counters for
    the two sheet calls. `debug_store.dart` gains `FAKE_STORE=trial`, `monthly` and
    `lifetimeRenewing` (Lifetime with Annual renewing in 20 days).

- [x] **Step 1:** Tests: `presentCodeRedemption calls the gateway`; `requestRefund passes
  the plan's product id`; `requestRefund maps cancelled`; `renewingSubscription maps
  productId and renewsAt`; `renewingSubscription null when none`; `a channel error is a
  StoreFailure`; debug store: `lifetimeRenewing is Lifetime with Annual renewing`.
- [x] **Step 2:** Run both test files. Expected: FAIL.
- [x] **Step 3:** Implement.
- [x] **Step 4:** Run. Expected: PASS.
- [x] **Step 5:** Commit: `feat(paywall): code redemption, refunds and renewal status`.

As built: `RefundOutcome` lives in `renewing_subscription.dart`. `StoreChannel`
(`exhale/store`) is injected into `PluginStoreKitGateway` as an optional positional
argument; code redemption uses `InAppPurchaseStoreKitPlatformAddition`. An answer naming
Lifetime, an unknown product or a bad date reads as no renewing subscription; an unknown
refund answer is a `StoreFailure`. Only `renewingSubscription` is timed (no sheet). Added
`test/features/paywall/store_channel_test.dart` (method names and arguments). Tests 41/41
across the three files.

### Task 3: Store additions, Swift side

**Files:**
- Create: `ios/Runner/StorePlugin.swift` (add to the Runner target)
- Modify: `ios/Runner/AppDelegate.swift` (register like `PresencePlugin`)

**Interfaces:**
- Consumes: the channel contract from Task 2.
- Produces: channel `exhale/store` with
  - `requestRefund {productId}`: `Transaction.latest(for:)`, then
    `beginRefundRequest(in:)` on the active `UIWindowScene`; returns `"requested"` on
    `.success`, `"cancelled"` on `.userCancelled`; errors as `FlutterError`
    (`no_transaction`, `refund_failed`).
  - `renewingSubscription`: for each unexpired, unrevoked subscription in
    `Transaction.currentEntitlements`, read `subscriptionStatus`; the first whose
    verified `renewalInfo.willAutoRenew` is true returns
    `{"productId", "renewsAt"}` (`renewalDate` or the transaction's `expirationDate`,
    ISO 8601 UTC); else `nil`.

- [x] **Step 1:** Implement both methods.
- [x] **Step 2:** Ask Fawad to approve `fvm flutter build ios --debug --no-codesign`.
  Expected: `✓ Built`.
- [x] **Step 3:** Commit: `feat(ios): refund request and renewal status channel`.

As built: added to Runner by hand in `project.pbxproj` (file reference, build file,
group and Sources, next to `PresencePlugin.swift`). Calls run in `Task { @MainActor in }`
as in `PresencePlugin`; `bad_args` when `productId` is missing; the refund sheet uses the
foreground-active `UIWindowScene`, else the first. `renewsAt` from
`ISO8601DateFormatter` (UTC, no fraction). Debug build `✓ Built` (60.8 s); not yet run
against StoreKit (the milestone walk covers it).

### Task 4: Plan tile summary and plan shortcuts

**Files:**
- Create: `lib/features/settings/presentation/settings_copy.dart`,
  `lib/features/settings/domain/plan_tile_summary.dart`,
  `lib/features/settings/presentation/widgets/settings_row.dart`,
  `lib/features/settings/presentation/widgets/settings_tile.dart`,
  `lib/features/settings/presentation/widgets/plan_section.dart`
- Modify: `lib/app/router/app_routes.dart`, `lib/app/router/app_router.dart`,
  `lib/features/plan/presentation/pages/edit_plan_page.dart` (scroll to the price card)
- Test: `test/features/settings/domain/plan_tile_summary_test.dart`,
  `test/features/settings/plan_section_test.dart`

**Interfaces:**
- Produces:
  - `class TileSummary { final String eyebrow; final String value; final String? line; }`
    (shared with Task 5).
  - `TileSummary planTileSummary({required TrackedHabit habit, required PlanHistory
    history, required LogicalDay today})`: eyebrow `'<habit name> plan'`; value the
    current plan's `quitDay` as `AppFormat.monthDay`, or `'Quit day'` once today is on or
    after it; line `'N days to go'` / `'1 day to go'`, the quit date once reached, or
    `'Starts <monthDay>'` before `startDay`.
  - `SettingsRow({required IconData icon, required String label, String? value,
    VoidCallback? onTap, bool? switchValue, ValueChanged<bool>? onSwitch,
    Widget? trailing})`: icon in a 28 pt soft tile, chevron when `onTap` is set,
    `CupertinoSwitch` when `onSwitch` is set, min height 44, no ink.
    `SettingsGroup({String? header, required List<Widget> rows})`: one `Card`, hairline
    dividers.
  - `SettingsTile({required IconData icon, required TileSummary summary,
    required VoidCallback onTap, bool accentIcon = false})`: one button, semantics label
    `'<eyebrow>, <value>, <line>'`.
  - `AppRoutes.editPlanFor(int habitId, {bool focusPrice = false})` adds
    `?focus=price`; `EditPlanPage({required int habitId, bool focusPrice = false})`
    scrolls the price card into view after the first frame.
  - `PlanSection` (habit id from `singleHabitIdProvider`): the plan tile (opens
    `planDetailsFor`) and a group: Edit plan (value `'<limit> today'`), Price (value
    the current price as `PriceCard` formats it, or `'Not set'`; opens Edit plan with
    `focusPrice`), Change habit (`changeHabitFor`).

- [x] **Step 1:** Summary tests (habit vaping, start 2026-11-19, quit 2027-01-12):
  `54 days to go`; `1 day to go` on 2027-01-11; `quit day reached says Quit day`;
  `a plan starting tomorrow says Starts` (`'Starts Nov 20'`); `eyebrow names the habit`.
  Widget tests: `Edit plan shows today's limit`; `no price reads Not set`; `Price opens
  Edit plan at the price card`; `Change habit opens change habit`; `the tile opens plan
  details`; `rows are at least 44 tall`.
- [x] **Step 2:** Run both files with `--timeout 60s`. Expected: FAIL.
- [x] **Step 3:** Implement.
- [x] **Step 4:** Run. Expected: PASS.
- [x] **Step 5:** Commit: `feat(settings): plan tile and shortcuts`.

As built: `PlanSection` is split into `PlanTile` and `PlanShortcuts` (both read
`singleHabitProvider`) so Task 7 can set the tile beside the subscription tile; both sit
after the title in `SettingsPage` until then. Price shows only for habits that track cost;
whole prices drop the cents (`$12 a pod`). `settings_copy.dart` is left to Task 7. The
`settings_page_test` opens Settings at height 2400 and scopes its `Not set` to
`YourDayTile`.

### Task 5: Subscription tile summary

**Files:**
- Create: `lib/features/settings/domain/subscription_tile_summary.dart`
- Test: `test/features/settings/domain/subscription_tile_summary_test.dart`

**Interfaces:**
- Consumes: `TileSummary` (Task 4), `Access`, `AppSettings.accessPlan`.
- Produces: `TileSummary subscriptionTileSummary({required Access access,
  required String? cachedPlan, required DateTime now})`:
  - trial: `Free week` / `'N days left'` (`'1 day left'`, `'Ends today'` at 0 or below) /
    `'Annual from <monthDay of expiresAt>'`;
  - Annual / Monthly: `Annual` or `Monthly` / `Active` / `'Renews <monthDay>'`;
  - Lifetime: `Lifetime` / `Yours for good` / null;
  - Unknown: the cached plan's name or `Subscription` / `Can't check now` / null.
  Days are logical days (`LogicalDay.fromDate(expiresAt.toLocal())`).

- [ ] **Step 1:** Tests: one per state above, plus `trial ending today says Ends today`
  and `a passed trial end still says Ends today`.
- [ ] **Step 2:** Run. Expected: FAIL.
- [ ] **Step 3:** Implement.
- [ ] **Step 4:** Run. Expected: PASS.
- [ ] **Step 5:** Commit: `feat(settings): subscription tile summary`.

### Task 6: The Subscription sheet

**Files:**
- Create: `lib/features/settings/presentation/widgets/subscription_sheet.dart`
- Modify: `lib/features/paywall/presentation/paywall_copy.dart`,
  `lib/features/paywall/presentation/providers/paywall_providers.dart`
- Delete: `lib/features/paywall/presentation/widgets/subscription_card.dart`,
  `test/features/paywall/subscription_card_test.dart` (replaced)
- Test: `test/features/settings/subscription_sheet_test.dart`

**Interfaces:**
- Consumes: Task 2's repository calls; `paywallControllerProvider` (`select`, `buy`,
  `restore`); `offersProvider`; `accessProvider`.
- Produces:
  - `Future<void> showSubscriptionSheet(BuildContext context)` via
    `showAppDraggableSheet`.
  - `final renewingSubscriptionProvider = FutureProvider.autoDispose<
    RenewingSubscription?>` (failure reads as null).
  - `PaywallCopy` additions, exact: `subscriptionSheetTitle = 'Subscription'`,
    `changePlan = 'Change plan'`, `payMonthly = 'Pay monthly'`, `payYearly = 'Pay yearly'`,
    `payMonthlyInstead = 'Pay monthly instead'`, `goLifetime = 'Go Lifetime'`,
    `billing = 'Billing'`, `afterFreeWeek = 'After your free week'`,
    `manageInAppStore = 'Manage in the App Store'`, `cancelFreeWeek = 'Cancel free week'`,
    `redeemCode = 'Redeem a code'`, `requestRefund = 'Request a refund'`,
    `active = 'Active'`, `lifetimeTitle = 'Exhale Lifetime'`,
    `cantReachStore = "Can't reach the App Store right now."`,
    `cancelAnyTime(plan, date) => 'Cancel any time in the App Store. $plan stays open
    until $date, and your plan and logs stay on this iPhone either way.'`,
    `trialStarts(date, price) => 'Annual starts $date at $price a year.'`,
    `cancelBefore(date) => "Cancel before $date and you won't be charged."`,
    `stillRenews(plan, date) => '$plan still renews on $date. Lifetime already covers
    you, so cancel $plan to avoid being charged again.'`,
    `cancelPlan(plan) => 'Cancel $plan'`, `lifetimeBought = 'Lifetime is yours.'`.
- Rows per state as the spec's "Subscription sheet" section. Manage, Pay monthly / yearly,
  Pay monthly instead, Cancel free week and Cancel <plan> call `manageSubscriptions`.
  Go Lifetime: `select(PlanKind.lifetime)` then `buy()`; on `purchased` a success snackbar
  `lifetimeBought`. Restore: spinner in its row while `busy`, then today's snackbars.

- [ ] **Step 1:** Tests with `FakeStoreRepository`: `annual shows change plan and
  billing`; `monthly offers Pay yearly`; `trial shows days left and Cancel free week`;
  `trial has no refund row`; `lifetime has no change plan`; `lifetime with a renewing
  Annual shows the note and Cancel Annual`; `a failed renewal check shows no note`;
  `unknown offers only Restore and Redeem`; `restore shows a spinner while busy`;
  `actions are disabled while busy`; `Go Lifetime buys Lifetime and says so`;
  `Redeem a code calls the store`; `Request a refund passes the current plan`.
- [ ] **Step 2:** Run with `--timeout 60s`. Expected: FAIL.
- [ ] **Step 3:** Implement.
- [ ] **Step 4:** Run. Expected: PASS.
- [ ] **Step 5:** Commit: `feat(settings): the Subscription sheet`.

### Task 7: The Settings page

**Files:**
- Modify: `lib/features/settings/presentation/pages/settings_page.dart`,
  `lib/features/settings/presentation/widgets/your_day_sheet.dart` (export an
  `showYourDaySheet` opener; `YourDayTile` goes),
  `lib/features/settings/presentation/widgets/trigger_prompt_tile.dart` (becomes a
  `SettingsRow`, or is removed if the page builds the row)
- Create: `lib/features/settings/presentation/widgets/appearance_sheet.dart`,
  `lib/features/settings/presentation/widgets/about_section.dart`
- Test: `test/features/settings/settings_page_test.dart`

**Interfaces:**
- Consumes: Tasks 1, 4, 5, 6.
- Order: title; tiles (plan, subscription) side by side, stacked when
  `MediaQuery.textScalerOf(context).scale(1) > 1.6` or width under 340; plan shortcuts;
  `Your day` (Awake); `Logging` (Ask what set it off); `Lock Screen` (Countdown on Lock
  Screen); `Appearance` (Theme, Accent → `showAppearanceSheet` holding
  `ThemePreferenceControl` and `AccentPicker`); `About` (Rate Exhale, Send feedback,
  Privacy policy, Terms of use; each hidden when its `AppLinks` value is null); footer
  `Exhale <version>` from `PackageInfo`.
- Send feedback when `composeMail` returns false: copy the address and
  `showAppSnackBar(SettingsCopy.addressCopied)` (`'Address copied. No Mail account on
  this iPhone.'`).

- [ ] **Step 1:** Tests (update the file; keep the Your day and Lock Screen cases):
  `sections in order`; `the subscription tile opens the sheet`; `Awake opens Your day`;
  `Appearance rows open one sheet with theme and accent`; `ask what set it off is
  stored`; `the Lock Screen switch is stored`; `about rows hidden without links`;
  `Rate asks for a review`; `feedback without Mail copies the address`; `footer shows
  the version`; `no Restore on the main list`; `tiles stack at 200% on a small phone`;
  `reduce transparency renders` (existing helper).
- [ ] **Step 2:** Run with `--timeout 60s`. Expected: FAIL.
- [ ] **Step 3:** Implement.
- [ ] **Step 4:** Run. Expected: PASS.
- [ ] **Step 5:** Commit: `feat(settings): the redesigned Settings page`.

### Task 8: Redeem a code on the paywall and the locked screen

**Files:**
- Modify: `lib/features/paywall/presentation/pages/paywall_page.dart`,
  `lib/features/paywall/presentation/pages/locked_page.dart`
- Test: `test/features/paywall/paywall_page_test.dart`,
  `test/features/paywall/locked_page_test.dart`

**Interfaces:**
- Consumes: `presentCodeRedemption` (Task 2), `PaywallCopy.redeemCode`.
- Paywall: a "Redeem a code" text button under the plan buttons' fine print (top bar
  stays Back and Restore). Locked: a text button under Restore. Both disabled while busy.

- [ ] **Step 1:** Tests: `paywall Redeem a code calls the store`; `locked Redeem a code
  calls the store`; `redeeming then a store change leaves the paywall` (fake emits an
  entitled change).
- [ ] **Step 2:** Run both files with `--timeout 60s`. Expected: FAIL.
- [ ] **Step 3:** Implement.
- [ ] **Step 4:** Run. Expected: PASS.
- [ ] **Step 5:** Commit: `feat(paywall): redeem a code`.

### Task 9: Milestone close

- [ ] **Step 1:** Independent review (Opus 5.5 high) against the spec and Review Focus;
  fix findings.
- [ ] **Step 2:** Full suite: `fvm flutter test --reporter failures-only
  --file-reporter json:build/test-report.json`; report totals per task's files.
- [ ] **Step 3:** Walk on Fawad's iPhone (debug, `fvm flutter run`) with
  `FAKE_STORE=entitled`, `trial`, `monthly`, `lifetimeRenewing`, `offline`: light and
  dark, Reduce Transparency, 200%, VoiceOver on the tiles. Then sandbox: Restore, Manage,
  Redeem a code sheet, refund sheet.
- [ ] **Step 4:** Update `docs/CURRENT_STATE.md` and `design/12._settings/README.md`;
  commit `docs: close the Settings redesign milestone`.
