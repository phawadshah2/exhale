# Lock Screen presence Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: run with the project's `execute-plan` skill
> (one task at a time: failing test, code, passing test, commit). Steps use checkbox
> (`- [ ]`) syntax for tracking.

**Goal:** Exhale on the Lock Screen and Home Screen (Live Activity with the Dynamic Island,
Lock Screen widgets, five Home Screen widgets) and "Log one" without opening the app.

**Architecture:** The Flutter app writes a JSON snapshot to an App Group and drives the
Live Activity through one method channel, `exhale/presence`. Swift (a widget extension and
an App Intent) reads the snapshot, appends logs made outside the app to a JSON queue, and
replays the queue over the snapshot with a Swift port of `PaceGuide`. The app drains the
queue into drift on startup, resume and a Darwin notification.

**Tech Stack:** Flutter 3.47.2 / Dart 3.13 (Riverpod 3, drift, get_it), Swift 6 with
WidgetKit, ActivityKit and App Intents, XCTest.

**Spec:** `docs/superpowers/specs/2026-11-14-lock-screen-presence-design.md`. Designs:
`design/11._lock_screen_presence/` (README maps each piece to its file).

## Global Constraints

- Minimum iOS 17.0 for Runner, RunnerTests and the extension; controls guarded with
  `@available(iOS 18, *)`.
- App Group `group.com.phawadshah.exhale`; extension bundle id
  `com.phawadshah.exhale.ExhaleWidgets`; team `5W8A3P22WK`.
- Method channel name `exhale/presence`. Darwin notification name
  `com.phawadshah.exhale.queueChanged`.
- No new Dart packages; no `pubspec.yaml` change.
- Fully offline: no server, push, Firebase or analytics.
- Never nudge toward using: no "you can have one now", no alert when a countdown ends.
- Not entitled (last known access is not Entitled): widgets show "Exhale is locked" and
  open the app; Log one writes nothing and opens the app; no Live Activity.
- Snapshot older than its last limit day, or missing: widgets show "Open Exhale to update";
  Log one opens the app.
- Copy is fixed by the spec and designs; quote it exactly.
- Builds, simulator runs and `xcodebuild test` mid-milestone: ask Fawad first, one
  command per approval. Apple Developer portal and Xcode target creation are Fawad's.

## Review Focus

1. A log from Siri between midnight and the reset hour counts on the previous logical day,
   in Swift as in Dart (Task 9 test `queuedLogBeforeResetHourCountsYesterday`).
2. The queue drained twice, or the app killed between insert and removal, never doubles a
   log (Task 7 test `drainingTwiceInsertsOnce`, `aStoredIdIsRemovedNotReinserted`).
3. The app unopened for longer than the snapshot covers: widgets say "Open Exhale to
   update" instead of guessing a limit (Task 9 test `pastTheLastLimitDayIsStale`).
4. Log one while the app is open: the app drains at once and its next snapshot already
   holds the log, so widgets never drop back a count (Task 8 test
   `queueChangeWhileOpenDrainsThenWritesSnapshot`).
5. Access lapses while widgets are on screen: the next snapshot is not entitled and the
   Live Activity ends (Task 8 test `losingAccessEndsActivityAndLocksSnapshot`).

---

### Task 1: Xcode targets, App Group and iOS 17

**Files:**
- Modify: `ios/Runner.xcodeproj/project.pbxproj` (deployment target 17.0 everywhere;
  the new target and group, added by Fawad in Xcode)
- Create: `ios/Runner/Runner.entitlements` (App Group)
- Create (by Xcode): `ios/ExhaleWidgets/` with `ExhaleWidgetsBundle.swift`, `Info.plist`,
  `ExhaleWidgets.entitlements`
- Create: `ios/Shared/` (a folder group added to both Runner and ExhaleWidgets)

**Interfaces:**
- Produces: targets `Runner` and `ExhaleWidgets` both with the App Group; `ios/Shared`
  compiled into both.

- [x] **Step 1 (Fawad):** Apple Developer portal: register App Group
  `group.com.phawadshah.exhale`; enable it on `com.phawadshah.exhale`; register
  `com.phawadshah.exhale.ExhaleWidgets` with the same group.
- [x] **Step 2 (Fawad, Xcode):** File > New > Target > Widget Extension named
  `ExhaleWidgets`, "Include Live Activity" and "Include Control" ticked, embedded in
  Runner. Signing & Capabilities: add App Groups with the group on Runner and
  ExhaleWidgets. Add Runner's Info.plist key `NSSupportsLiveActivities = YES`.
- [x] **Step 3:** Set `IPHONEOS_DEPLOYMENT_TARGET = 17.0` for every configuration of
  Runner, RunnerTests and ExhaleWidgets; delete the template's sample widget, Live
  Activity and control bodies, leaving an empty `@main ExhaleWidgetsBundle`.
- [x] **Step 4:** Ask Fawad, then run `fvm flutter build ios --simulator --debug`.
  Expected: `✓ Built build/ios/iphonesimulator/Runner.app`.
- [x] **Step 5:** Commit: `build(ios): add the widget extension, App Group and iOS 17`.

Done 2026-11-14. As built: the target is `ExhaleWidgetsExtension` (folder
`ios/ExhaleWidgets`, an Xcode 16 synchronized folder), entitlements at
`ios/ExhaleWidgetsExtension.entitlements`; the bundle holds an `EmptyWidgetConfiguration`
placeholder; "Embed Foundation Extensions" moved before "Thin Binary" (the Flutter build
cycle). `ios/Shared` is not made yet: the first task that adds a shared Swift file creates
it as a synchronized folder in both targets (in Xcode, by Fawad, or in the project file
with Xcode closed).

### Task 2: Spike, Live Activity from Log one with the app closed

Throwaway, on branch `spike/log-one-activity` off this branch. Not merged.

- [x] **Step 1:** In `ios/Shared/LogOneIntent.swift`, an `AppIntent & LiveActivityIntent`
  named `LogOneIntent` whose `perform()` calls `Activity<CountdownAttributes>.request`
  with a fixed 1-hour countdown; an `AppShortcutsProvider` with "Log one in ${applicationName}".
  `CountdownAttributes` with a `ContentState { next: Date }` and a one-line view.
- [x] **Step 2:** Ask Fawad, run on his iPhone (`fvm flutter run --release -d <his
  device>`), assign the shortcut to the Action Button, force-quit the app, press it.
- [x] **Step 3:** Record in the spec's "Order of work" item 1 whether the activity
  appeared (and on which iOS). If not, Task 12's intent only updates a running activity and
  Task 13 notes it.
- [x] **Step 4:** Commit the spec note on this branch: `docs: record the Live Activity
  spike result`. Delete the spike branch.

Done 2026-11-14: yes, Log one starts a new Live Activity with the app terminated (iOS
27.2, from Shortcuts). Spike code was commit `22710db` on the deleted spike branch: it had
`ios/Shared` as a synchronized folder in both targets, with `LogOneIntent.swift` excluded
from the extension (`Activity.request` is app-only).

### Task 3: Shared countdown cases

**Files:**
- Create: `test/fixtures/pace_cases.json`
- Test: `test/features/home/domain/pace_cases_test.dart`

**Interfaces:**
- Produces: `pace_cases.json`, an array of
  `{name, now, day, resetHour, wakeMinute, awakeMinutes, limit, countToday, logs: [ISO], expect: null | {next, gap, pace, bed}}`
  (times ISO 8601 local without zone, durations in seconds). Read by Task 9's XCTest.

- [x] **Step 1:** Write 14 cases: each test in `pace_guide_test.dart` (wake split, mid-day,
  carry, first log fresh, stacking, past bed, before wake, log before wake, at limit,
  limit 0) plus a reset at 4 AM with a log at 2 AM, and a window running past midnight.
- [x] **Step 2:** Test `every case matches PaceGuide.compute`: loads the file, calls
  `PaceGuide.compute` per case, expects `null` or the four values.
- [x] **Step 3:** Run `fvm flutter test test/features/home/domain/pace_cases_test.dart`.
  Expected: all pass (the file is written to match; a failure means a wrong case).
- [x] **Step 4:** Commit: `test(home): shared countdown cases for the Swift port`.

Done 2026-11-14. Expected values come from `PaceGuide.compute` and match every value the
existing `pace_guide_test.dart` asserts. Durations truncate to whole microseconds in Dart
(16 h / 7 is 8228.571428 s), so Task 9's XCTest compares within 1 ms.

### Task 4: Schema v13, external ids and the Live Activity switch

**Files:**
- Modify: `lib/core/data/local/database/tables/habit_logs_table.dart`,
  `.../tables/settings_table.dart`, `.../app_database.dart` (v13 step),
  `lib/features/tracking/domain/repositories/habit_log_repository.dart`, its drift
  implementation, `lib/features/settings/domain/entities/app_settings.dart` and its mapper
- Test: `test/core/data/app_database_migration_test.dart`,
  `test/features/tracking/data/habit_log_repository_test.dart`

**Interfaces:**
- Produces: `HabitLogs.externalId` (`external_id`, text, nullable, unique index
  `idx_habit_logs_external_id`); `Settings.showLiveActivity` (`show_live_activity`, bool,
  default true); `AppSettings.showLiveActivity` (bool, default `true`, in `copyWith`);
  `HabitLogRepository.addLog({..., String? externalId})`;
  `Future<Result<Set<String>>> storedExternalIds(Iterable<String> ids)`.

- [x] **Step 1:** Migration tests: from v12 `adds external_id and show_live_activity`
  (columns exist, old logs null, setting true); `ends on the latest version` covers v13.
  Repository tests: `addLog stores the external id`; `storedExternalIds returns only stored ones`;
  `a second log with the same external id fails` (a `Failure`, not a throw).
- [x] **Step 2:** Run both files with `--timeout 60s`. Expected: FAIL (no column).
- [x] **Step 3:** Add the columns, the `from < 13` step (`addColumn` both, create the
  index), `schemaVersion => 13`, the repository parameter and query; run
  `fvm dart run build_runner build -d`.
- [x] **Step 4:** Run both test files. Expected: PASS.
- [x] **Step 5:** Commit: `feat(tracking): schema v13 with external log ids`.

Done 2026-11-14. As built: the repository tests live in
`test/features/tracking/data/local_habit_log_repository_test.dart` (the existing file); a
v12 fixture `test/fixtures/exhale_v12.sqlite` (the v11 data plus a log and a cached
access) backs the upgrade test. v7 and older get both columns from the v8 table rebuilds
(`newColumns`), so `addColumn` runs only from v8 to v12; the index is created for every
version below 13.

### Task 5: Lines of encouragement

**Files:**
- Create: `lib/features/presence/domain/encouragement.dart`
- Modify: `lib/features/home/presentation/widgets/quote_card.dart` (reads the shared list)
- Test: `test/features/presence/domain/encouragement_test.dart`

**Interfaces:**
- Produces: `const List<String> encouragementLines` (60 lines, the 7 from `QuoteCard`
  first, each at most 40 characters, none suggesting using);
  `typedef LinePair = ({String counting, String waiting})`;
  `LinePair pickLinePair(Random random, {LinePair? last})`.

- [x] **Step 1:** Tests: `has 60 distinct lines of at most 40 characters`;
  `starts with the Home quotes` (the 7, in order);
  `a pair has two different lines`; `never repeats the last pair's lines` (1,000 seeded
  picks); `no line says "you can"` (case-insensitive).
- [x] **Step 2:** Run. Expected: FAIL (no file).
- [x] **Step 3:** Write the list (draft 53 new lines in the Home quotes' voice; Fawad
  reviews them at the milestone walk) and `pickLinePair`. `QuoteCard.quotes` becomes
  `encouragementLines.take(7)`.
- [x] **Step 4:** Run the new test and `test/features/home/`. Expected: PASS.
- [x] **Step 5:** Commit: `feat(presence): lines of encouragement`.

Done 2026-11-14. The 53 new lines are drafts for Fawad's review at the milestone walk.
`QuoteCard.quotes` is a `static final List<String>` (a `take` is not const).

### Task 6: The snapshot

**Files:**
- Create: `lib/features/presence/domain/presence_snapshot.dart`
- Test: `test/features/presence/domain/presence_snapshot_test.dart`

**Interfaces:**
- Consumes: `PlanHistory` (its plans carry their holds: limit and stage for a day, the
  quit day as shifted), `AppSettings`, `TrackedHabit` (for the reason), `LinePair`.
- Produces: `class PresenceSnapshot` with `Map<String, Object?> toJson()`, built by
  `factory PresenceSnapshot.build({required DateTime now, required LogicalDay today,
  required AppSettings settings, required TrackedHabit habit, required PlanHistory history,
  required Map<LogicalDay, int> counts,
  required List<DateTime> todayLogs, required bool entitled, required LinePair lastPair})`.
  JSON keys: `version` (1), `writtenAt`, `entitled`, `resetHour`, `wakeMinute`,
  `awakeMinutes`, `habit {name, kind, reason, freeDayTitle}`, `quitDay`,
  `days: [{day, limit, stage, stageCount, count?}]` from today − 62 to today + 62,
  `todayLogs`, `showLiveActivity`, `lines`, `lastPair {counting, waiting}`. Times
  (`writtenAt`, `todayLogs`) are UTC ISO 8601; `count` is absent on future days.
  (Changed 2026-11-14 with Fawad: a separate holds list would apply holds twice, and the
  reason lives on `TrackedHabit`.)

- [x] **Step 1:** Tests: `covers 62 days each side of today`; `past days carry their own
  plan's limit` (a replan mid-range); `a hold shifts later limits and the quit day`;
  `counts only on past days and today`; `no window writes null wake and awake`;
  `not entitled writes entitled false`; `toJson round-trips through jsonDecode`.
- [x] **Step 2:** Run. Expected: FAIL.
- [x] **Step 3:** Implement with the existing plan services (no new limit maths).
- [x] **Step 4:** Run. Expected: PASS.
- [x] **Step 5:** Commit: `feat(presence): the snapshot for widgets`.

### Task 7: Channel, repository and draining the queue

**Files:**
- Create: `lib/features/presence/domain/queued_log.dart`,
  `.../domain/activity_content.dart`,
  `.../domain/repositories/presence_repository.dart`,
  `.../data/presence_channel_repository.dart`,
  `.../domain/usecases/drain_external_logs.dart`,
  `lib/features/presence/presence_injection.dart`
- Modify: `lib/core/di/injection_container.dart`
- Test: `test/features/presence/domain/drain_external_logs_test.dart`,
  `test/features/presence/data/presence_channel_repository_test.dart`,
  `test/helpers/fake_presence_repository.dart`

**Interfaces:**
- Produces:
  - `class QueuedLog {String id; DateTime loggedAt}` with `fromJson`.
  - `class ActivityContent {DateTime next; Duration gap; int count; int limit;
    int daysToGo; String countingLine; String waitingLine; DateTime staleAt}` with
    `toJson()`; `staleAt = next + 15 min`.
  - `abstract interface class PresenceRepository { Future<Result<void>>
    writeSnapshot(PresenceSnapshot s); Future<Result<List<QueuedLog>>> readQueue();
    Future<Result<void>> removeFromQueue(Set<String> ids); Future<Result<void>>
    showActivity(ActivityContent c); Future<Result<void>> endActivity(); Stream<void>
    get queueChanged; }`
  - `class DrainExternalLogs { Future<Result<int>> call(int habitId) }`: inserted count.
  - Channel methods (Task 10 implements them): `writeSnapshot(String json)`,
    `readQueue() -> String json`, `removeFromQueue(List<String> ids)`,
    `showActivity(String json)`, `endActivity()`; Swift calls `queueChanged` on the
    channel.
  - As built: `readQueue` returning null or empty reads as an empty queue; any channel
    exception is a `StorageFailure`; `ActivityContent` JSON keys are `next`,
    `gapSeconds`, `count`, `limit`, `daysToGo`, `countingLine`, `waitingLine`,
    `staleAt` (times UTC ISO 8601). The spec's `startOrUpdateActivity` / `drainQueue`
    names are superseded by these. `setupDependencies` takes `presence:`.

- [x] **Step 1:** Drain tests with an in-memory database and the fake: `inserts each
  queued log at its time with no trigger`; `drainingTwiceInsertsOnce`;
  `aStoredIdIsRemovedNotReinserted`; `removes exactly the drained ids` (an id appended
  during the drain stays); `a failed insert removes nothing`.
  Channel tests with a mocked `MethodChannel`: method names and arguments as above.
- [x] **Step 2:** Run. Expected: FAIL.
- [x] **Step 3:** Implement; register in `presence_injection.dart` (repository as the
  channel one; tests override with the fake in `setUpTestDependencies`).
- [x] **Step 4:** Run. Expected: PASS.
- [x] **Step 5:** Commit: `feat(presence): queue drain and the presence channel`.

### Task 8: Keeping Swift in sync

**Files:**
- Create: `lib/features/presence/presentation/presence_sync.dart`
- Modify: `lib/app/app.dart` (lifecycle resume), `lib/app/bootstrap.dart` or the shell
  (start the sync once a habit exists), `lib/app/router/app_router.dart` and
  `ios/Runner/Info.plist` (URL scheme `exhale`: `exhale://home` opens Home,
  `exhale://logs/week` opens Logs on the current week; both go through `accessRedirect`)
- Test: `test/features/presence/presentation/presence_sync_test.dart`,
  `test/app/deep_link_test.dart` (`exhale://logs/week opens this week`,
  `a lapsed user's link lands on the locked screen`)

**Interfaces:**
- Consumes: `nextLogTimerProvider`, `logsForDayProvider`, `currentSettingsProvider`,
  `accessProvider`, plan providers, `PresenceRepository`, `DrainExternalLogs`,
  `pickLinePair`.
- Produces: `final presenceSyncProvider` (kept alive by the shell) that drains, then
  writes the snapshot, then shows or ends the activity; `ActivityContent?
  activityFor({NextLogTimer? timer, required bool entitled, required bool enabled, ...})`.
- As built: the sync is kept alive by `ExhaleApp` (`listenManual`), not the shell, so a
  lapsed user on the locked screen still gets a locked snapshot. Each run reads
  storage (not providers) after draining, so the snapshot already holds drained logs.
  The countdown comes from the new `NextLogTimer.at` (shared with
  `nextLogTimerProvider`). A new countdown (`next` changed) takes a new line pair;
  the first sync with no countdown always ends (an activity Log one started while the
  app was closed). Deep links map in the router's `redirect` (`deepLinkRoute`); Logs'
  Back goes Home when there is nothing to pop. Line pairs live in memory only.

- [x] **Step 1:** Tests with the fake: `startup drains then writes a snapshot`;
  `a log writes a snapshot and shows the activity with a new line pair`;
  `the first log of the day starts it, none before`; `at the limit ends it`;
  `the switch off ends it and never shows it`; `losingAccessEndsActivityAndLocksSnapshot`;
  `queueChangeWhileOpenDrainsThenWritesSnapshot`; `resume past staleAt ends it`;
  `the day reset ends it and writes a snapshot`.
- [x] **Step 2:** Run with `--timeout 60s`. Expected: FAIL.
- [x] **Step 3:** Implement. Writes are serialised (one in flight, the latest wins).
- [x] **Step 4:** Run, plus `test/app/` and `test/features/home/`. Expected: PASS.
- [x] **Step 5:** Commit: `feat(presence): keep widgets and the Live Activity in sync`.

### Task 9: Swift core

**Files:**
- Create: `ios/Shared/PresenceSnapshot.swift`, `ios/Shared/QueueStore.swift`,
  `ios/Shared/PaceGuide.swift`, `ios/Shared/PresenceState.swift`,
  `ios/Shared/AppGroup.swift`
- Test: `ios/RunnerTests/PaceGuideParityTests.swift`,
  `ios/RunnerTests/PresenceStateTests.swift`, `ios/RunnerTests/QueueStoreTests.swift`
  (RunnerTests reads `test/fixtures/pace_cases.json` as a bundle resource)

**Interfaces:**
- Consumes: Task 6's JSON, Task 3's cases.
- Produces:
  - `enum AppGroup { static let id; static var snapshotURL: URL; static var queueURL: URL }`
  - `struct PresenceSnapshot: Decodable`
  - `final class QueueStore { init(url: URL); func append(_ log: QueuedLog) throws;
    func read() throws -> [QueuedLog]; func remove(ids: Set<String>) throws }`
    (`NSFileCoordinator`, atomic writes)
  - `struct PaceGuide { static func compute(now:day:resetHour:wakeMinute:awakeMinutes:
    limit:countToday:logs:) -> PaceGuide? }` with `next`, `gap`, `pace`, `bed`
  - `struct PresenceState { static func make(snapshot: PresenceSnapshot?, queue:
    [QueuedLog], now: Date) -> PresenceState }` with `kind` (`.live`, `.locked`,
    `.stale`), `count`, `limit`, `status` (`.under`, `.at`, `.over`), `timer`
    (`next`, `gapStart`)?, `stage`, `stageCount`, `daysToGo`, `daysAtZero`,
    `month: [Date: Status]`, `week: [(day: Date, count: Int, limit: Int)]`, `reason`,
    `freeDayTitle`, `quitReached`.
- As built: `ios/Shared` is a synchronized folder in Runner and the extension, and
  `ios/RunnerTests` became a synchronized folder (project file edited with Xcode closed).
  The parity test reads the fixture through `#filePath`, not as a bundle resource.
  `AppGroup.swift` also holds `Day`, `DayBoundary` and an ISO 8601 reader for Dart's
  six-digit fractions. `PresenceState.week` is `[WeekDay]` (Monday to Sunday);
  `daysAtZero` counts the quit day as day 1. Known gap: between the app's snapshot
  write and its queue removal, a drained log can count twice in widgets for a moment.
  Green run 2026-11-15: 16 tests, `** TEST SUCCEEDED **` (two earlier runs failed on
  test code only).

- [x] **Step 1:** Tests: `everyPaceCaseMatches` (all of Task 3); `queuedLogAddsToToday`;
  `queuedLogBeforeResetHourCountsYesterday`; `pastTheLastLimitDayIsStale`;
  `missingSnapshotIsStale`; `notEntitledIsLocked`; `quitDayShowsDaysAtZero`;
  `appendWhileReadingKeepsBoth` (QueueStore); `removeLeavesOtherIds`.
- [x] **Step 2:** Ask Fawad, run `xcodebuild test -workspace ios/Runner.xcworkspace
  -scheme Runner -destination 'platform=iOS Simulator,name=iPhone 17'`. Expected: FAIL.
- [x] **Step 3:** Implement; `PaceGuide` mirrors the Dart replay line for line.
- [x] **Step 4:** Ask Fawad, run the same command. Expected: `** TEST SUCCEEDED **`.
- [x] **Step 5:** Commit: `feat(ios): presence core shared with the widgets`.

### Task 10: The Swift side of the channel

**Files:**
- Create: `ios/Runner/PresencePlugin.swift`, `ios/Shared/CountdownAttributes.swift`
- Modify: `ios/Runner/AppDelegate.swift` (register like `NativeUiPlugin`)
- Test: `ios/RunnerTests/PresencePluginTests.swift`

**Interfaces:**
- Consumes: Task 7's method names, Task 9's core.
- Produces: `struct CountdownAttributes: ActivityAttributes` with `ContentState {next,
  gapStart, count, limit, daysToGo, countingLine, waitingLine}`; the plugin writes the
  snapshot, reads and trims the queue, requests, updates or ends the one activity (with
  `staleDate = staleAt`), reloads all widget timelines after each write, and observes the
  Darwin notification to call `queueChanged`.

- As built: `PresencePlugin.swift` was added to the Runner group in the project file
  (Runner is not a synchronized folder). `CountdownActivities` and `WidgetReloading` wrap
  ActivityKit and WidgetCenter; `showActivity` updates the first running (active or
  stale) activity and ends any extras. `removeFromQueue` reloads widgets too, which
  shortens Task 9's double-count gap. Bad arguments are `bad_arguments` errors; other
  failures are `presence`. Extra tests: `readQueueThenRemoveLeavesOtherIdsAndReloads`,
  `unknownMethodIsNotImplemented`. Red run skipped (Fawad, 2026-11-15: compile-only
  failure). Green run 2026-11-15: 21 tests, `** TEST SUCCEEDED **`.

- [x] **Step 1:** Tests: `writeSnapshotWritesTheFileAndReloads` (a reload spy);
  `showActivityTwiceUpdatesTheSameActivity` (an activity spy); `endActivityEndsAll`.
- [x] **Step 2:** Ask Fawad, run the Task 9 command. Expected: FAIL.
- [x] **Step 3:** Implement behind small protocols for ActivityKit and WidgetCenter so
  the tests use spies.
- [x] **Step 4:** Ask Fawad, run it. Expected: `** TEST SUCCEEDED **`.
- [x] **Step 5:** Commit: `feat(ios): presence channel and Live Activity control`.

### Task 11: Widgets

**Files:**
- Create: `ios/ExhaleWidgets/PresenceProvider.swift` (timeline),
  `ios/ExhaleWidgets/Views/` (`RingView`, `CountdownRing`, `CornerCounter`,
  `MonthGrid`, `WeekBars`, `LockedView`, `StaleView`),
  `ios/ExhaleWidgets/Widgets/` (`LockScreenWidget` (inline, circular, rectangular),
  `TodayWidget`, `CountdownWidget`, `WhyWidget`, `MonthWidget`, `WeekWidget`)
- Modify: `ios/ExhaleWidgets/ExhaleWidgetsBundle.swift`
- Test: `ios/RunnerTests/PresenceProviderTests.swift`

**Interfaces:**
- Consumes: `PresenceState`, `AppGroup`.
- Produces: timeline entries at now, the next due time, due + 15 min and the next day
  reset; widget URLs `exhale://home` and `exhale://logs/week` (Task 8 adds the routes).

- As built: the entry dates live in `ios/Shared/PresenceTimeline.swift` (RunnerTests
  can't import the extension); `PresenceProvider` wraps it and reads the snapshot and
  queue. Helpers: `Views/PresenceFormat.swift` (status colours light/dark, `CornerState`,
  spoken labels, days lines). Widgets 1 and 4 (Fawad, 2026-11-18, like Home): a thin
  2 pt countdown ring inside the day's ring, "4/8 today" in the middle, and under the
  ring only the timer, centred (no days line). The ring is drawn, not the system
  `ProgressView` (its stroke scales with its size), so the timeline adds an entry every
  5 min while the timer runs (`PresenceTimeline.ringStep`). Widget 2 past the time shows
  "Waited" and the wait counting up; widget 3 with no reason shows the last counting
  line under "For today"; the + on widget 2 waits for Task 12. Red run skipped (Fawad,
  2026-11-18: compile-only). Green runs 2026-11-18: 24 tests, `** TEST SUCCEEDED **`, before and after the ring change.
  Simulator 2026-11-18: all five Home Screen widgets render in the gallery, Today live
  with a debug snapshot (`counting`); the month key and ring fixes after that ran in a
  rebuilt app but weren't re-screenshotted. The light/dark/tinted × state matrix and the
  Lock Screen trio move to the Task 15 walk (Fawad, 2026-11-18).

- [x] **Step 1:** Tests: `entriesAtDueStaleAndReset`; `noTimerHasNoDueEntries`;
  `lockedAndStaleHaveOneEntryUntilReset`.
- [x] **Step 2:** Ask Fawad, run the Task 9 command. Expected: FAIL.
- [x] **Step 3:** Implement the provider, then the views to the designs: widget 1 and the
  ring column of 4 from `Rings-v4.html` (all six states in the spec's table), 2, 3, 5 from
  `LockScreen-v2.html`, the key "Under / At / Over" on 4, the Lock Screen trio from
  `LockScreen.html`. Counters use `Text(timerInterval:)` and `Text(_, style: .timer)`.
  VoiceOver labels as on Home. Tinted and clear Home Screen styles use
  `widgetAccentable()` on the ring and bars.
- [x] **Step 4:** Ask Fawad, run the tests, then the simulator; screenshot every widget in
  light, dark and tinted, and every state via a debug snapshot.
- [x] **Step 5:** Commit: `feat(ios): Lock Screen and Home Screen widgets`.

### Task 12: Log one

**Files:**
- Create: `ios/Shared/LogOneIntent.swift`, `ios/Shared/ExhaleShortcuts.swift`,
  `ios/Shared/LinePicker.swift`, `ios/ExhaleWidgets/LogOneControl.swift`
- Modify: `CountdownWidget` and the Island expanded view (the + buttons)
- Test: `ios/RunnerTests/LogOneIntentTests.swift`

**Interfaces:**
- Consumes: `QueueStore`, `PresenceState`, `pickLinePair` port (`LinePicker.pick(lines:last:)`
  in `ios/Shared/LinePicker.swift`), `CountdownAttributes`.
- Produces: `LogOneIntent` (`openAppWhenRun = false`; `LiveActivityIntent` if Task 2
  passed) that appends `{UUID, now}`, posts the Darwin notification, reloads widgets,
  starts or updates the activity, and replies with the spec's dialog.

- [ ] **Step 1:** Tests: `appendsOneLogAndReplies` ("Logged · 5 of 8 today. Next one on
  schedule at 12:21 PM."); `overTheLimitStillLogs` ("Logged · 9 of 8 today.");
  `pickNeverRepeatsLastPair` (LinePicker, as Task 5);
  `lockedWritesNothingAndOpensTheApp`; `staleWritesNothingAndOpensTheApp`.
- [ ] **Step 2:** Ask Fawad, run the Task 9 command. Expected: FAIL.
- [ ] **Step 3:** Implement; the control is `@available(iOS 18, *)`, title "Log one",
  symbol `plus`.
- [ ] **Step 4:** Ask Fawad, run the tests. Expected: PASS.
- [ ] **Step 5:** Commit: `feat(ios): Log one from Siri, the Action Button and controls`.

### Task 13: Live Activity and the Island

**Files:**
- Create: `ios/ExhaleWidgets/CountdownActivity.swift`
- Test: snapshot by screenshot (no unit test: views only)

- [ ] **Step 1:** Implement to `LockScreen-v2.html` (card, counting and from `staleDate`)
  and `LockScreen.html` §2 (compact, minimal, expanded with "+ Log one").
- [ ] **Step 2:** Ask Fawad, run on the simulator; log from the app, wait past due + 15
  min (shortened by a debug gap), screenshot both states and the three Island sizes.
- [ ] **Step 3:** Commit: `feat(ios): the countdown Live Activity`.

### Task 14: The Settings switch

**Files:**
- Modify: `lib/features/settings/presentation/pages/settings_page.dart`
- Test: `test/features/settings/settings_page_test.dart`

- [ ] **Step 1:** Tests: `the Lock Screen switch is on by default`; `turning it off is
  stored`; `it reads "Show the countdown on the Lock Screen"`.
- [ ] **Step 2:** Run with `--timeout 60s`. Expected: FAIL.
- [ ] **Step 3:** Add a `CupertinoSwitch` row in the existing style; Task 8's sync reacts.
- [ ] **Step 4:** Run. Expected: PASS.
- [ ] **Step 5:** Commit: `feat(settings): switch for the Lock Screen countdown`.

### Task 15: Milestone close

- [ ] **Step 1:** Independent review (Opus 5.5 high) against the spec and Review Focus;
  fix findings.
- [ ] **Step 2:** Full suite: `fvm flutter test --reporter failures-only
  --file-reporter json:build/test-report.json`; report totals per task's files. Then the
  XCTest run.
- [ ] **Step 3:** Device walk with Fawad: each widget, Siri, the Action Button, Control
  Center, the Island, a lapsed walk (`--dart-define=FAKE_STORE=lapsed`), airplane mode.
- [ ] **Step 4:** Update `docs/CURRENT_STATE.md`; commit
  `docs: close the Lock Screen presence milestone`.
