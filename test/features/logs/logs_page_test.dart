import 'dart:async';

import 'package:exhale/app/bootstrap.dart';
import 'package:exhale/core/di/injection_container.dart';
import 'package:exhale/core/domain/result/result.dart';
import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/features/logs/presentation/logs_query.dart';
import 'package:exhale/features/logs/presentation/pages/logs_page.dart';
import 'package:exhale/features/logs/presentation/widgets/logs_rail_card.dart';
import 'package:exhale/features/plan/domain/entities/plan_draft.dart';
import 'package:exhale/features/plan/presentation/widgets/stage_ring.dart';
import 'package:exhale/features/settings/domain/entities/app_settings.dart';
import 'package:exhale/features/settings/domain/repositories/settings_repository.dart';
import 'package:exhale/features/tracking/domain/entities/trigger.dart';
import 'package:exhale/features/tracking/domain/usecases/add_habit_log.dart';
import 'package:exhale/features/tracking/presentation/providers/tracking_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../helpers/fixed_clock.dart';
import '../../helpers/haptics.dart';
import '../../helpers/large_text.dart';
import '../../helpers/pump_app.dart';

void main() {
  // Friday 16 Oct 2026, 15:42. The week runs Mon 12 to Sun 18 Oct.
  final now = DateTime(2026, 10, 16, 15, 42);
  final today = LogicalDay(2026, 10, 16);
  LogicalDay oct(int day) => LogicalDay(2026, 10, day);

  late FixedClock clock;

  setUp(() {
    clock = FixedClock(now);
    return setUpTestDependencies(clock);
  });
  tearDown(InjectionContainer.reset);

  // Disposes either way: a failure that leaves the app up hangs the run.
  void logsTest(
    String name,
    Future<void> Function(WidgetTester) body, {
    bool semantics = false,
  }) {
    testWidgets(name, (tester) async {
      final handle = semantics ? tester.ensureSemantics() : null;
      try {
        await body(tester);
      } finally {
        await tester.disposeApp();
        handle?.dispose();
      }
    });
  }

  // From Wed 14 Oct by default: the limit is 9 through Tue 20 Oct.
  Future<void> startPlan({LogicalDay? from, int limit = 9, int? days}) {
    final start = from ?? oct(14);
    return seedHabit(
      PlanDraft(
        startDay: start,
        startLimit: limit,
        quitDay: start.addDays(days ?? 63),
      ),
    );
  }

  Future<void> setDayWindow() async {
    final repository = sl<SettingsRepository>();
    final current = await repository.get() as Success<AppSettings>;
    await repository.save(
      current.value.copyWith(wakeMinute: () => 450, bedMinute: () => 1410),
    );
  }

  Future<void> logAt(
    DateTime at, {
    int times = 1,
    Trigger? trigger,
    String? note,
  }) async {
    for (var i = 0; i < times; i++) {
      await sl<AddHabitLog>()(
        AddHabitLogInput(
          habitId: 1,
          loggedAt: at.add(Duration(minutes: i)),
          trigger: trigger,
          note: note,
        ),
      );
    }
  }

  Future<void> openPage(
    WidgetTester tester, [
    LogsQuery query = const LogsQuery(habitId: 1),
  ]) async {
    await tester.pumpAppPastSplash(height: 2400);
    final context = tester.element(find.byType(Scaffold).first);
    unawaited(GoRouter.of(context).push(query.toUri().toString()));
    await tester.pumpAndSettle();
  }

  LogsQuery onDay(LogicalDay day, {Trigger? trigger}) =>
      LogsQuery(habitId: 1, from: day, to: day, trigger: trigger);

  Finder cell(LogicalDay day) => find.byKey(ValueKey(day));

  StageRingPainter ringOf(WidgetTester tester, LogicalDay day) =>
      tester
              .widget<CustomPaint>(
                find.descendant(
                  of: cell(day),
                  matching: find.byType(CustomPaint),
                ),
              )
              .painter!
          as StageRingPainter;

  Text dateOf(WidgetTester tester, LogicalDay day) => tester.widget<Text>(
    find.descendant(of: cell(day), matching: find.text('${day.day}')),
  );

  Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  IconButton arrow(WidgetTester tester, String tooltip) =>
      tester.widget<IconButton>(
        find.ancestor(
          of: find.byTooltip(tooltip),
          matching: find.byType(IconButton),
        ),
      );

  group('the page', () {
    testWidgets('a failed log stream shows an error and can retry', (
      tester,
    ) async {
      await startPlan();
      var attempts = 0;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...await startupOverrides(),
            logsInRangeProvider.overrideWith((ref, key) {
              attempts++;
              return attempts == 1
                  ? Stream.error(StateError('storage'))
                  : const Stream.empty();
            }),
          ],
          child: MaterialApp(home: LogsPage(query: onDay(today))),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text("Couldn't load your logs."), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      await tester.tap(find.text('Try again'));
      await tester.pump();
      await tester.pump();
      expect(find.text("Couldn't load your logs."), findsNothing);
      expect(attempts, 2);
      await tester.disposeApp();
    });

    logsTest('opens on this week with today selected', (tester) async {
      await startPlan();
      await openPage(tester);

      expect(find.text('The evidence.'), findsOneWidget);
      expect(
        find.text('You logged it, so it counts. Pick a day, any day.'),
        findsOneWidget,
      );
      expect(find.text('Oct 12 – Oct 18'), findsOneWidget);
      expect(find.text('Today · Fri, Oct 16'), findsOneWidget);
    });

    logsTest('+ opens the editor on the selected day', (tester) async {
      await startPlan();
      await openPage(tester, onDay(oct(15)));

      await tapAndSettle(tester, find.byTooltip('Add a missed log'));

      expect(find.text('Add missed log'), findsOneWidget);
      expect(find.text('Smoking · Thu, Oct 15'), findsOneWidget);

      await tester.scrollAndTap(find.text('Add log'));
      await tester.pumpAndSettle();

      expect(find.text('1 of 9'), findsOneWidget);
    });

    logsTest('a selection plays a haptic', (tester) async {
      await startPlan();
      await openPage(tester);
      final played = recordHaptics(tester);

      await tapAndSettle(tester, cell(oct(15)));

      expect(played, ['HapticFeedbackType.selectionClick']);
    });
  });

  group('the calendar', () {
    logsTest('week arrows step and stop at the earliest week', (tester) async {
      await startPlan();
      await openPage(tester);

      expect(arrow(tester, 'Later').onPressed, isNull);
      expect(find.text('This week'), findsNWidgets(2));

      await tapAndSettle(tester, find.byTooltip('Earlier'));
      expect(find.text('Oct 5 – Oct 11'), findsOneWidget);
      expect(find.text('Last week'), findsNWidgets(2));
      expect(find.text('Sun, Oct 11'), findsOneWidget);
      expect(arrow(tester, 'Later').onPressed, isNotNull);

      await tapAndSettle(tester, find.byTooltip('Earlier'));
      expect(find.text('Sep 28 – Oct 4'), findsOneWidget);
      expect(find.text('2 weeks ago'), findsNWidgets(2));

      // The plan starts Oct 14; the earliest day is Mon Sep 14.
      await tapAndSettle(tester, find.byTooltip('Earlier'));
      expect(arrow(tester, 'Earlier').onPressed, isNotNull);
      await tapAndSettle(tester, find.byTooltip('Earlier'));
      expect(find.text('Sep 14 – Sep 20'), findsOneWidget);
      expect(arrow(tester, 'Earlier').onPressed, isNull);
    });

    logsTest('stepping back to this week selects today', (tester) async {
      await startPlan();
      await openPage(tester, onDay(oct(7)));

      await tapAndSettle(tester, find.byTooltip('Later'));

      expect(find.text('Oct 12 – Oct 18'), findsOneWidget);
      expect(find.text('Today · Fri, Oct 16'), findsOneWidget);
    });

    logsTest('Month shows the month, and its arrows step', (tester) async {
      await startPlan(from: LogicalDay(2026, 9, 1));
      await openPage(tester);

      await tapAndSettle(tester, find.text('Month'));
      expect(find.text('October 2026'), findsOneWidget);
      expect(find.text('This month'), findsOneWidget);
      expect(find.text('October'), findsOneWidget);

      await tapAndSettle(tester, find.byTooltip('Earlier'));
      expect(find.text('September 2026'), findsOneWidget);
      expect(find.text('Last month'), findsOneWidget);
      expect(find.text('September'), findsOneWidget);
      expect(find.text('Wed, Sep 30'), findsOneWidget);

      await tapAndSettle(tester, find.byTooltip('Earlier'));
      expect(find.text('2 months ago'), findsOneWidget);
    });

    logsTest('switching keeps the selected day', (tester) async {
      await startPlan();
      await openPage(tester);

      await tapAndSettle(tester, cell(oct(14)));
      await tapAndSettle(tester, find.text('Month'));
      expect(find.text('Wed, Oct 14'), findsOneWidget);
      expect(find.text('October 2026'), findsOneWidget);

      await tapAndSettle(tester, cell(oct(5)));
      await tapAndSettle(tester, find.text('Week'));
      expect(find.text('Mon, Oct 5'), findsOneWidget);
      expect(find.text('Oct 5 – Oct 11'), findsOneWidget);
    });

    logsTest('the title opens month chips, and a pick closes them', (
      tester,
    ) async {
      await startPlan();
      await openPage(tester);
      expect(find.text('Sep 2026'), findsNothing);

      await tapAndSettle(tester, find.text('Oct 12 – Oct 18'));
      expect(find.text('Sep 2026'), findsOneWidget);
      expect(find.text('Oct 2026'), findsOneWidget);

      await tapAndSettle(tester, find.text('Sep 2026'));

      expect(find.text('September 2026'), findsOneWidget);
      expect(find.text('Wed, Sep 30'), findsOneWidget);
      expect(find.text('Sep 2026'), findsNothing);
    });

    logsTest('a plan day fills by use, coloured by status', (tester) async {
      await startPlan();
      await logAt(DateTime(2026, 10, 14, 9), times: 3);
      await logAt(DateTime(2026, 10, 15, 9), times: 9);
      await openPage(tester, onDay(oct(16)));
      final context = tester.element(find.byType(LogsPage));

      final under = ringOf(tester, oct(14));
      expect(under.fill, closeTo(3 / 9, 0.001));
      expect(under.color, context.colors.primaryContainer);
      expect(under.dashed, isFalse);

      final at = ringOf(tester, oct(15));
      expect(at.fill, 1);
      expect(at.color, context.exhale.warning.solid);
    });

    logsTest('an over day is full and in the danger colour', (tester) async {
      await startPlan();
      await logAt(DateTime(2026, 10, 15, 9), times: 10);
      await openPage(tester, onDay(oct(16)));
      final context = tester.element(find.byType(LogsPage));

      final over = ringOf(tester, oct(15));
      expect(over.fill, 1);
      expect(over.color, context.exhale.danger.solid);
    });

    logsTest('a day at limit 0 with no logs is a full success ring', (
      tester,
    ) async {
      await startPlan(from: LogicalDay(2026, 10, 1), limit: 2, days: 14);
      await openPage(tester);
      final context = tester.element(find.byType(LogsPage));

      await tapAndSettle(tester, cell(oct(15)));
      final zero = ringOf(tester, oct(16));

      expect(zero.fill, 1);
      expect(zero.color, context.exhale.success.solid);
    });

    logsTest('the selected day uses the on-accent ring and date', (
      tester,
    ) async {
      await startPlan();
      await openPage(tester, onDay(oct(15)));
      final context = tester.element(find.byType(LogsPage));

      expect(ringOf(tester, oct(15)).color, context.exhale.onEmphasis);
      expect(dateOf(tester, oct(15)).style?.color, context.exhale.onEmphasis);
      expect(ringOf(tester, oct(14)).color, isNot(context.exhale.onEmphasis));
    });

    logsTest('today has a heavier date', (tester) async {
      await startPlan();
      await openPage(tester, onDay(oct(15)));

      expect(dateOf(tester, today).style?.fontWeight, FontWeight.w800);
      expect(dateOf(tester, oct(14)).style?.fontWeight, FontWeight.w600);
    });

    logsTest('a day before the plan is dashed and can be selected', (
      tester,
    ) async {
      await startPlan();
      await openPage(tester);

      final before = ringOf(tester, oct(13));
      expect(before.dashed, isTrue);
      expect(before.fill, 0);

      await tapAndSettle(tester, cell(oct(13)));

      expect(find.text('Tue, Oct 13'), findsOneWidget);
      expect(find.text('0 logged · before your plan'), findsOneWidget);
    });

    logsTest('a future day is dashed and does not select', (tester) async {
      await startPlan();
      await openPage(tester);

      expect(ringOf(tester, oct(17)).dashed, isTrue);

      await tapAndSettle(tester, cell(oct(17)));

      expect(find.text('Today · Fri, Oct 16'), findsOneWidget);
    });

    logsTest('a day before the earliest does not select', (tester) async {
      // The earliest day is Tue Sep 15, so Mon Sep 14 is out.
      await startPlan(from: oct(15));
      await openPage(tester, onDay(LogicalDay(2026, 9, 15)));
      final out = LogicalDay(2026, 9, 14);

      expect(ringOf(tester, out).dashed, isTrue);

      await tapAndSettle(tester, cell(out));

      expect(find.text('Tue, Sep 15'), findsOneWidget);
    });

    logsTest('VoiceOver reads a day and its count', (tester) async {
      await startPlan();
      await logAt(DateTime(2026, 10, 15, 9), times: 5);
      await logAt(DateTime(2026, 10, 13, 9), times: 2);
      await openPage(tester);

      expect(find.bySemanticsLabel('Oct 15, 5 of 9'), findsOneWidget);
      expect(find.bySemanticsLabel('Oct 13, 2 logged'), findsOneWidget);
      expect(find.bySemanticsLabel('Oct 12'), findsOneWidget);
      expect(find.bySemanticsLabel('Oct 17'), findsOneWidget);
    }, semantics: true);
  });

  group('the period card', () {
    logsTest('shows what is allowed so far in a running period', (
      tester,
    ) async {
      await startPlan();
      await logAt(DateTime(2026, 10, 15, 9), times: 16);
      await openPage(tester);

      // 9 a day: 45 for Oct 14 to 18, 27 through today.
      expect(
        find.text('16 / 45 (27 so far) allowed', findRichText: true),
        findsOneWidget,
      );
      expect(find.text('11 under'), findsOneWidget);
    });

    logsTest('a finished period has no so far', (tester) async {
      await startPlan(from: oct(5));
      await logAt(DateTime(2026, 10, 7, 9), times: 2);
      await openPage(tester, onDay(oct(7)));

      expect(find.text('2 / 63 allowed', findRichText: true), findsOneWidget);
      expect(find.text('61 under'), findsOneWidget);
    });

    logsTest('the pill reads over past what is allowed so far', (tester) async {
      await startPlan();
      await logAt(DateTime(2026, 10, 15, 9), times: 30);
      await openPage(tester);

      expect(find.text('3 over'), findsOneWidget);
    });

    logsTest('exactly at what is allowed so far reads 0 under', (tester) async {
      await startPlan();
      await logAt(DateTime(2026, 10, 15, 9), times: 27);
      await openPage(tester);

      expect(find.text('0 under'), findsOneWidget);
    });

    logsTest('a period with no plan days says so and has no pill', (
      tester,
    ) async {
      await startPlan();
      await logAt(DateTime(2026, 10, 7, 9), times: 2);
      await openPage(tester, onDay(oct(7)));

      expect(find.text('Before your plan'), findsOneWidget);
      expect(find.textContaining(' under'), findsNothing);
      expect(find.textContaining(' over'), findsNothing);
      expect(find.textContaining('allowed', findRichText: true), findsNothing);
    });
  });

  group('triggers', () {
    Future<void> seedTriggers() async {
      await startPlan();
      await logAt(DateTime(2026, 10, 16, 8), times: 2, trigger: Trigger.stress);
      await logAt(DateTime(2026, 10, 16, 10), trigger: Trigger.work);
      await logAt(DateTime(2026, 10, 16, 12));
    }

    List<ColoredBox> segments(WidgetTester tester) => tester
        .widgetList<ColoredBox>(
          find.descendant(
            of: find.byKey(const Key('logs-trigger-bar')),
            matching: find.byType(ColoredBox),
          ),
        )
        .toList();

    logsTest('the bar and chips show the counts, most used first', (
      tester,
    ) async {
      await seedTriggers();
      await openPage(tester);

      expect(find.text('Stress 2'), findsOneWidget);
      expect(find.text('Work 1'), findsOneWidget);
      expect(find.text('None 1'), findsOneWidget);
      expect(segments(tester), hasLength(3));
    });

    logsTest('no logs in the period hides the bar and chips', (tester) async {
      await startPlan();
      await openPage(tester);

      expect(find.byKey(const Key('logs-trigger-bar')), findsNothing);
      expect(find.textContaining('None'), findsNothing);
    });

    logsTest('a chip filters the rail, and again clears', (tester) async {
      await seedTriggers();
      await openPage(tester);
      expect(find.byType(Dismissible), findsNWidgets(4));
      expect(segments(tester).map((s) => s.color.a), [1, 1, 1]);

      await tapAndSettle(tester, find.text('Stress 2'));
      expect(find.byType(Dismissible), findsNWidgets(2));
      expect(segments(tester).first.color.a, 1);
      expect(segments(tester)[1].color.a, lessThan(1));
      expect(segments(tester)[2].color.a, lessThan(1));

      await tapAndSettle(tester, find.text('Stress 2'));
      expect(find.byType(Dismissible), findsNWidgets(4));
    });

    logsTest('a filter keeps the day rings on every log', (tester) async {
      await seedTriggers();
      await openPage(tester);

      await tapAndSettle(tester, find.text('Work 1'));

      expect(ringOf(tester, today).fill, closeTo(4 / 9, 0.001));
    });

    logsTest('None is not tappable', (tester) async {
      await seedTriggers();
      await openPage(tester);

      await tapAndSettle(tester, find.text('None 1'));

      expect(find.byType(Dismissible), findsNWidgets(4));
    });

    logsTest('a filter with 0 in the period stays clearable', (tester) async {
      await startPlan();
      await logAt(DateTime(2026, 10, 16, 8));
      await openPage(tester, onDay(today, trigger: Trigger.stress));

      expect(find.text('Stress 0'), findsOneWidget);
      expect(find.text('No Stress logs this day.'), findsOneWidget);

      await tapAndSettle(tester, find.text('Stress 0'));

      expect(find.text('Stress 0'), findsNothing);
      expect(find.text('No Stress logs this day.'), findsNothing);
      expect(find.byType(Dismissible), findsOneWidget);
    });

    logsTest('with no logs at all a filter stays clearable', (tester) async {
      await startPlan();
      await openPage(tester, onDay(today, trigger: Trigger.stress));

      expect(find.text('Stress 0'), findsOneWidget);

      await tapAndSettle(tester, find.text('Stress 0'));

      expect(find.text('Stress 0'), findsNothing);
    });

    logsTest('a filter carries across periods', (tester) async {
      await seedTriggers();
      await openPage(tester);

      await tapAndSettle(tester, find.text('Stress 2'));
      await tapAndSettle(tester, find.byTooltip('Earlier'));

      expect(find.text('Stress 0'), findsOneWidget);
    });
  });

  group('the day card', () {
    Color? countColor(WidgetTester tester, String text) =>
        tester.widget<Text>(find.text(text)).style?.color;

    logsTest('over', (tester) async {
      await startPlan();
      await logAt(DateTime(2026, 10, 15, 9), times: 10);
      await openPage(tester, onDay(oct(15)));
      final context = tester.element(find.byType(LogsPage));

      expect(find.text('Thu, Oct 15'), findsOneWidget);
      expect(
        countColor(tester, '10 of 9 · 1 over'),
        context.exhale.danger.foreground,
      );
    });

    logsTest('today, not over', (tester) async {
      await startPlan();
      await logAt(DateTime(2026, 10, 16, 9), times: 4);
      await openPage(tester);
      final context = tester.element(find.byType(LogsPage));

      expect(
        countColor(tester, '4 of 9 · 5 left'),
        context.exhale.success.foreground,
      );
    });

    logsTest('past, at limit', (tester) async {
      await startPlan();
      await logAt(DateTime(2026, 10, 15, 9), times: 9);
      await openPage(tester, onDay(oct(15)));
      final context = tester.element(find.byType(LogsPage));

      expect(
        countColor(tester, '9 of 9 · at limit'),
        context.exhale.warning.foreground,
      );
    });

    logsTest('past, under', (tester) async {
      await startPlan();
      await logAt(DateTime(2026, 10, 15, 9), times: 2);
      await openPage(tester, onDay(oct(15)));
      final context = tester.element(find.byType(LogsPage));

      expect(countColor(tester, '2 of 9'), context.exhale.success.foreground);
    });

    logsTest('before the plan', (tester) async {
      await startPlan();
      await logAt(DateTime(2026, 10, 13, 9), times: 2);
      await openPage(tester, onDay(oct(13)));
      final context = tester.element(find.byType(LogsPage));

      expect(
        countColor(tester, '2 logged · before your plan'),
        context.colors.onSurfaceVariant,
      );
    });

    logsTest('the slot bar has one slot for each of limit or count', (
      tester,
    ) async {
      await startPlan();
      await logAt(DateTime(2026, 10, 15, 9), times: 12);
      await openPage(tester, onDay(oct(15)));

      final bar = tester.widget<LogsSlotBar>(find.byType(LogsSlotBar));
      expect(bar.limit, 9);
      expect(bar.count, 12);
    });

    logsTest('the slot bar hides before the plan', (tester) async {
      await startPlan();
      await logAt(DateTime(2026, 10, 13, 9));
      await openPage(tester, onDay(oct(13)));

      expect(find.byType(LogsSlotBar), findsNothing);
    });

    logsTest('the slot bar hides at limit 0 with no logs', (tester) async {
      await startPlan(from: LogicalDay(2026, 10, 1), limit: 2, days: 14);
      await openPage(tester);

      expect(find.byType(LogsSlotBar), findsNothing);
    });
  });

  group('the rail', () {
    logsTest('a past day shows its marks, logs and gaps', (tester) async {
      await setDayWindow();
      await startPlan();
      await logAt(
        DateTime(2026, 10, 15, 9),
        trigger: Trigger.stress,
        note: 'Deadline call',
      );
      await logAt(DateTime(2026, 10, 15, 10));
      await logAt(DateTime(2026, 10, 15, 11, 47));
      await openPage(tester, onDay(oct(15)));

      expect(find.text('Woke up'), findsOneWidget);
      expect(find.text('7:30 AM'), findsOneWidget);
      expect(find.text('Bed'), findsOneWidget);
      expect(find.text('11:30 PM'), findsOneWidget);
      expect(find.text('9:00 AM'), findsOneWidget);
      expect(find.text('Stress'), findsOneWidget);
      expect(find.text('Deadline call'), findsOneWidget);
      expect(find.text('No trigger'), findsNWidgets(2));
      expect(find.text('No note'), findsNWidgets(2));
      expect(find.text('1 h'), findsOneWidget);
      expect(find.text('1 h 47 min. Longest that day.'), findsOneWidget);
      expect(find.text('Then nothing. Well done, or asleep.'), findsOneWidget);
      expect(find.text('Nothing here yet. Keep it that way.'), findsNothing);
      expect(
        find.text(
          'Forgot one? Tap + at the top to add it to this day. '
          "I'll pretend it was on time.",
        ),
        findsOneWidget,
      );
    });

    logsTest('a past day with no logs says so', (tester) async {
      await setDayWindow();
      await startPlan();
      await openPage(tester, onDay(oct(15)));

      expect(find.text('Woke up'), findsOneWidget);
      expect(
        find.text('Nothing logged. Well done, or forgot.'),
        findsOneWidget,
      );
      expect(find.text('Bed'), findsOneWidget);
    });

    logsTest('today has its own longest gap and closing line', (tester) async {
      await setDayWindow();
      await startPlan();
      await logAt(DateTime(2026, 10, 16, 8));
      await logAt(DateTime(2026, 10, 16, 8, 30));
      await logAt(DateTime(2026, 10, 16, 11));
      await openPage(tester);

      expect(find.text('2 h 30 min. Longest today. Frame it.'), findsOneWidget);
      expect(find.text('Nothing here yet. Keep it that way.'), findsOneWidget);
      expect(find.text('Then nothing. Well done, or asleep.'), findsNothing);
    });

    logsTest('an over log is marked, and its note is kept', (tester) async {
      await setDayWindow();
      await startPlan(limit: 2, days: 14);
      await logAt(DateTime(2026, 10, 15, 9), times: 2);
      await logAt(DateTime(2026, 10, 15, 12));
      await logAt(DateTime(2026, 10, 15, 14), note: 'Bad call');
      await openPage(tester, onDay(oct(15)));

      expect(find.text('Limit reached here'), findsOneWidget);
      expect(find.text('2 of 2'), findsOneWidget);
      expect(find.text('Over the limit. Noted.'), findsOneWidget);
      expect(find.text('Bad call'), findsOneWidget);
    });

    logsTest('before the plan has no marks', (tester) async {
      await setDayWindow();
      await startPlan();
      await logAt(DateTime(2026, 10, 13, 9));
      await openPage(tester, onDay(oct(13)));

      expect(find.text('Woke up'), findsNothing);
      expect(find.text('Bed'), findsNothing);
      expect(find.text('Then nothing. Well done, or asleep.'), findsNothing);
      expect(find.text('9:00 AM'), findsOneWidget);
    });

    logsTest('with no day window there are no marks or next', (tester) async {
      await startPlan();
      await logAt(DateTime(2026, 10, 16, 15, 40));
      await openPage(tester);

      expect(find.text('Woke up'), findsNothing);
      expect(find.text('Bed'), findsNothing);
      expect(find.text('Next on schedule'), findsNothing);
      expect(find.text('Nothing here yet. Keep it that way.'), findsOneWidget);
    });

    logsTest('next on schedule shows while the timer runs', (tester) async {
      await setDayWindow();
      await startPlan();
      await logAt(DateTime(2026, 10, 16, 15, 40));
      await openPage(tester);

      // 16 h over a limit of 9 is an even gap of 106 min 40 s.
      expect(find.text('Next on schedule'), findsOneWidget);
      expect(find.text('5:26 PM'), findsOneWidget);
    });

    logsTest('next on schedule hides once the timer has passed', (
      tester,
    ) async {
      await setDayWindow();
      await startPlan();
      await logAt(DateTime(2026, 10, 16, 8));
      await openPage(tester);

      expect(find.text('Next on schedule'), findsNothing);
      expect(find.text('Nothing here yet. Keep it that way.'), findsOneWidget);
    });

    logsTest('next on schedule is not on a past day', (tester) async {
      await setDayWindow();
      await startPlan();
      await logAt(DateTime(2026, 10, 16, 15, 40));
      await openPage(tester, onDay(oct(15)));

      expect(find.text('Next on schedule'), findsNothing);
    });

    logsTest('a filtered day has only its logs and no hint', (tester) async {
      await setDayWindow();
      await startPlan();
      await logAt(DateTime(2026, 10, 15, 9), trigger: Trigger.stress);
      await logAt(DateTime(2026, 10, 15, 11), trigger: Trigger.work);
      await openPage(tester, onDay(oct(15), trigger: Trigger.stress));

      expect(find.byType(Dismissible), findsOneWidget);
      expect(find.text('Woke up'), findsNothing);
      expect(find.text('Then nothing. Well done, or asleep.'), findsNothing);
      expect(find.textContaining('Forgot one?'), findsNothing);
    });

    logsTest('a filter with no match on the day says so', (tester) async {
      await startPlan();
      await logAt(DateTime(2026, 10, 14, 9), trigger: Trigger.stress);
      await logAt(DateTime(2026, 10, 15, 9), trigger: Trigger.work);
      await openPage(tester, onDay(oct(15), trigger: Trigger.stress));

      expect(find.text('No Stress logs this day.'), findsOneWidget);
      expect(find.byType(Dismissible), findsNothing);
    });

    logsTest('tapping a log opens the editor', (tester) async {
      await startPlan();
      await logAt(DateTime(2026, 10, 16, 9));
      await openPage(tester);

      await tapAndSettle(tester, find.text('9:00 AM'));
      expect(find.text('Edit log'), findsOneWidget);
      expect(find.text('Smoking · Fri, Oct 16'), findsOneWidget);

      await tester.tap(find.text('Stress').last);
      await tester.enterText(find.byType(TextField), 'After the meeting');
      await tester.scrollAndTap(find.text('Save changes'));
      await tester.pumpAndSettle();

      expect(find.text('Edit log'), findsNothing);
      expect(find.text('After the meeting'), findsOneWidget);
    });

    logsTest('swiping deletes after a confirm, and Undo restores', (
      tester,
    ) async {
      await startPlan();
      await logAt(DateTime(2026, 10, 16, 9), times: 2);
      await openPage(tester);
      expect(find.text('2 of 9 · 7 left'), findsOneWidget);

      await tester.drag(find.byType(Dismissible).first, const Offset(-500, 0));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete').last);
      await tester.pumpAndSettle();

      expect(find.text('1 of 9 · 8 left'), findsOneWidget);
      expect(find.text('Log deleted'), findsOneWidget);

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();

      expect(find.text('2 of 9 · 7 left'), findsOneWidget);
    });

    logsTest('VoiceOver reads a row and offers Delete', (tester) async {
      await startPlan();
      await logAt(DateTime(2026, 10, 16, 9));
      await openPage(tester);

      final row = find.bySemanticsLabel(
        '9:00 AM. Tap to edit, swipe to delete.',
      );
      expect(row, findsOneWidget);

      const delete = CustomSemanticsAction(label: 'Delete');
      final node = tester.getSemantics(row);
      expect(
        node.getSemanticsData().customSemanticsActionIds,
        contains(CustomSemanticsAction.getIdentifier(delete)),
      );

      node.owner!.performAction(
        node.id,
        SemanticsAction.customAction,
        CustomSemanticsAction.getIdentifier(delete),
      );
      await tester.pumpAndSettle();

      expect(find.text('Delete this log?'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
    }, semantics: true);

    test('a gap is taller the longer it is, within its limits', () {
      expect(LogsRailCard.gapHeight(Duration.zero), 28);
      expect(LogsRailCard.gapHeight(const Duration(hours: 1)), 40);
      expect(
        LogsRailCard.gapHeight(const Duration(hours: 7, minutes: 40)),
        120,
      );
      expect(LogsRailCard.gapHeight(const Duration(hours: 12)), 120);
    });
  });

  group('open across the reset hour', () {
    logsTest('the selected day stays and today moves on', (tester) async {
      await setDayWindow();
      await startPlan();
      await logAt(DateTime(2026, 10, 16, 15, 40));
      await openPage(tester);
      expect(find.text('Today · Fri, Oct 16'), findsOneWidget);
      expect(find.text('Nothing here yet. Keep it that way.'), findsOneWidget);

      clock.current = DateTime(2026, 10, 17, 4, 1);
      await tester.pump(const Duration(minutes: 1));
      await tester.pumpAndSettle();

      expect(find.text('Fri, Oct 16'), findsOneWidget);
      expect(find.text('Then nothing. Well done, or asleep.'), findsOneWidget);
      expect(find.text('Nothing here yet. Keep it that way.'), findsNothing);

      await tapAndSettle(tester, cell(oct(17)));

      expect(find.text('Today · Sat, Oct 17'), findsOneWidget);
      expect(find.text('Nothing here yet. Keep it that way.'), findsOneWidget);
    });

    logsTest('the later arrow opens when today is a new period', (
      tester,
    ) async {
      clock.current = DateTime(2026, 10, 18, 20);
      await startPlan();
      await openPage(tester);
      expect(arrow(tester, 'Later').onPressed, isNull);

      clock.current = DateTime(2026, 10, 19, 4, 1);
      await tester.pump(const Duration(minutes: 1));
      await tester.pumpAndSettle();

      expect(find.text('Sun, Oct 18'), findsOneWidget);
      expect(arrow(tester, 'Later').onPressed, isNotNull);

      await tapAndSettle(tester, find.byTooltip('Later'));

      expect(find.text('Today · Mon, Oct 19'), findsOneWidget);
    });
  });

  group('at the 200% cap on an SE width', () {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();

    setUpAll(loadAppFonts);
    setUp(() {
      binding.platformDispatcher.textScaleFactorTestValue = 3;
    });
    tearDown(binding.platformDispatcher.clearTextScaleFactorTestValue);

    Future<void> expectWhole(WidgetTester tester) async {
      tester.view.physicalSize = const Size(375 * 3, 812 * 3);
      await tester.pumpAndSettle();
      final clipped = tester.clippedTexts(within: find.byType(LogsPage));
      expect(clipped, isEmpty);
    }

    logsTest('a busy Week stays whole', (tester) async {
      await setDayWindow();
      await startPlan();
      await logAt(
        DateTime(2026, 10, 16, 8),
        times: 10,
        trigger: Trigger.avoidingTasks,
        note: 'Between meetings, again',
      );
      await logAt(DateTime(2026, 10, 16, 12), trigger: Trigger.watchingTv);
      await logAt(DateTime(2026, 10, 16, 15, 40));
      await openPage(tester);
      await tapAndSettle(tester, find.text('Oct 12 – Oct 18'));

      await expectWhole(tester);
    });

    logsTest('a Month and an extreme limit stay whole', (tester) async {
      await setDayWindow();
      await startPlan(from: LogicalDay(2026, 9, 1), limit: 80, days: 560);
      await logAt(DateTime(2026, 10, 16, 8), times: 90);
      await openPage(tester);
      await tapAndSettle(tester, find.text('Month'));

      await expectWhole(tester);
    });

    logsTest('before the plan stays whole', (tester) async {
      await startPlan();
      await openPage(tester, onDay(oct(7), trigger: Trigger.avoidingTasks));

      await expectWhole(tester);
    });
  });
}
