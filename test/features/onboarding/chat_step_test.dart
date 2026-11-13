import 'package:exhale/core/di/injection_container.dart';
import 'package:exhale/core/theme/app_theme.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/features/onboarding/presentation/onboarding_copy.dart';
import 'package:exhale/features/onboarding/presentation/providers/onboarding_chat.dart';
import 'package:exhale/features/onboarding/presentation/steps/chat_step.dart';
import 'package:exhale/features/onboarding/presentation/widgets/chat_widgets.dart';
import 'package:exhale/features/onboarding/presentation/widgets/chevron_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fixed_clock.dart';
import '../../helpers/large_text.dart';
import '../../helpers/onboarding.dart';
import '../../helpers/pump_app.dart';

void main() {
  setUp(() => setUpTestDependencies(FixedClock(DateTime(2026, 11, 8, 9))));
  tearDown(InjectionContainer.reset);

  // Name, vaping at the default amount, no price, the default day.
  Future<void> answerAll(WidgetTester tester) async {
    await answerName(tester);
    await tester.tap(find.text('Vaping'));
    await settleChat(tester);
    await tester.tap(find.text(OnboardingCopy.aboutRight));
    await settleChat(tester);
    await tester.tap(find.text(OnboardingCopy.skipPrice));
    await settleChat(tester);
    await tester.tap(find.text(OnboardingCopy.thatsMyDay));
    await settleChat(tester);
  }

  Finder seePlan() =>
      find.widgetWithText(ChevronButton, OnboardingCopy.chatSeePlan);
  Finder jump() => labelled(OnboardingCopy.jumpToNewest);
  Finder tagline(String line) =>
      find.descendant(of: find.byType(ChatTagline), matching: find.text(line));

  testWidgets('the chat fills from the top, under the glass bar', (
    tester,
  ) async {
    await pumpOnboardingChat(tester);

    final barBottom = tester
        .getBottomLeft(find.text(OnboardingCopy.chatIdle))
        .dy;
    final first = tester
        .getTopLeft(find.textContaining(OnboardingCopy.excuses.first))
        .dy;
    expect(first, greaterThan(barBottom));
    expect(first, lessThan(barBottom + 60));
    expect(find.byKey(ChatAvatar.onlineKey), findsOneWidget);
    expect(jump(), findsNothing);

    await tester.disposeApp();
  });

  testWidgets('See my plan waits for the day, then opens the plan', (
    tester,
  ) async {
    await pumpOnboardingChat(tester);
    expect(tester.widget<ChevronButton>(seePlan()).onPressed, isNull);

    await answerAll(tester);

    final newest = tester
        .getBottomLeft(find.textContaining("That's everything, Alex."))
        .dy;
    expect(newest, lessThanOrEqualTo(tester.getTopLeft(seePlan()).dy));
    expect(tester.widget<ChevronButton>(seePlan()).onPressed, isNotNull);

    await tester.tap(seePlan());
    await tester.pumpAndSettle();
    expect(find.text(OnboardingCopy.dealHeadline), findsOneWidget);

    await tester.disposeApp();
  });

  testWidgets('scrolling back offers a jump to the newest message', (
    tester,
  ) async {
    await pumpOnboardingChat(tester);
    await answerAll(tester);

    await tester.drag(
      find.descendant(
        of: find.byType(ChatStep),
        matching: find.byType(ListView),
      ),
      const Offset(0, 5000),
    );
    await tester.pumpAndSettle();
    expect(jump(), findsOneWidget);
    expect(
      find.textContaining("That's everything, Alex.").hitTestable(),
      findsNothing,
    );

    await tester.tap(jump());
    await tester.pumpAndSettle();
    expect(jump(), findsNothing);
    expect(
      find.textContaining("That's everything, Alex.").hitTestable(),
      findsOneWidget,
    );

    await tester.disposeApp();
  });

  Finder list() => find.descendant(
    of: find.byType(ChatStep),
    matching: find.byType(ListView),
  );

  testWidgets('the keyboard slides over the dock; the list ends above it', (
    tester,
  ) async {
    await pumpOnboardingChat(tester);
    final dock = tester.getRect(seePlan());

    tester.view.viewInsets = const FakeViewPadding(bottom: 336 * 3);
    await tester.pump();
    expect(tester.getRect(seePlan()), dock);
    expect(find.byType(ChatTagline), findsOneWidget);
    expect(tester.getRect(list()).bottom, 844 - 336);

    tester.view.resetViewInsets();
    await tester.pump();
    expect(tester.getRect(list()).bottom, lessThan(dock.top));

    await tester.disposeApp();
  });

  group('with motion on, after an answer', () {
    /// Answers the name with Reduce Motion off, so Exhale types its reply.
    Future<void> answerWithMotion(WidgetTester tester) async {
      await pumpOnboardingChat(tester);
      tester.platformDispatcher.clearAccessibilityFeaturesTestValue();
      await tester.pump();
      await tester.enterText(
        find.widgetWithText(TextField, OnboardingCopy.nameHint),
        'Alex',
      );
      await tester.tap(labelled(OnboardingCopy.sendName));
    }

    Iterable<ChatAvatar> shownAvatars(WidgetTester tester) => tester
        .widgetList<ChatAvatar>(
          find.descendant(of: list(), matching: find.byType(ChatAvatar)),
        )
        .where((avatar) => avatar.visible);

    testWidgets('earlier avatars stay while Exhale types', (tester) async {
      await answerWithMotion(tester);
      await tester.pump(const Duration(milliseconds: 1950));
      expect(find.byType(ChatTyping), findsOneWidget);
      // The run that asked the name keeps its avatar; the dots carry one.
      expect(shownAvatars(tester), hasLength(2));

      await tester.pump(const Duration(seconds: 15));
      await tester.disposeApp();
    });

    testWidgets('the list only moves forward and ends on the newest', (
      tester,
    ) async {
      await answerWithMotion(tester);
      var last = tester
          .state<ScrollableState>(
            find
                .descendant(of: list(), matching: find.byType(Scrollable))
                .first,
          )
          .position
          .pixels;
      for (var i = 0; i < 400; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        final now = tester
            .state<ScrollableState>(
              find
                  .descendant(of: list(), matching: find.byType(Scrollable))
                  .first,
            )
            .position
            .pixels;
        expect(now, greaterThanOrEqualTo(last));
        last = now;
      }
      final card = find.text('Vaping');
      expect(card, findsOneWidget);
      expect(
        tester.getBottomLeft(card).dy,
        lessThanOrEqualTo(tester.getRect(list()).bottom),
      );

      await tester.pump(const Duration(seconds: 15));
      await tester.disposeApp();
    });
  });

  group('the tagline', () {
    testWidgets('reacts to each answer of a vaping run', (tester) async {
      await pumpOnboardingChat(tester);
      expect(tagline(OnboardingCopy.taglineExcuses), findsOneWidget);

      await answerName(tester);
      expect(
        tagline('Nice to meet you, Alex. Your excuses already have.'),
        findsOneWidget,
      );

      await tester.tap(find.text('Vaping'));
      await settleChat(tester);
      expect(
        tagline('Vaping. Flavoured air with a monthly bill.'),
        findsOneWidget,
      );

      await tester.tap(find.text(OnboardingCopy.aboutRight));
      await settleChat(tester);
      expect(
        tagline('12 a day. Your lungs have filed a complaint.'),
        findsOneWidget,
      );

      await tester.tap(find.text('AED 10'));
      await settleChat(tester);
      expect(tagline('AED 10 a pod. Your wallet felt that.'), findsOneWidget);

      await tester.tap(find.text(OnboardingCopy.aboutRight));
      await settleChat(tester);
      expect(
        tagline("AED 1,460 a year. That's a holiday you inhaled."),
        findsOneWidget,
      );

      await tester.tap(find.text(OnboardingCopy.thatsMyDay));
      await settleChat(tester);
      expect(tagline(OnboardingCopy.taglineDay), findsOneWidget);
      expect(find.byType(ChatTagline), findsOneWidget);

      await tester.disposeApp();
    });

    testWidgets('answers a skipped name and a skipped price', (tester) async {
      await pumpOnboardingChat(tester);
      await tester.tap(find.text(OnboardingCopy.nameSkip));
      await settleChat(tester);
      expect(tagline(OnboardingCopy.taglineNameSkipped), findsOneWidget);

      await tester.tap(find.text('Vaping'));
      await settleChat(tester);
      await tester.tap(find.text(OnboardingCopy.aboutRight));
      await settleChat(tester);
      await tester.tap(find.text(OnboardingCopy.skipPrice));
      await settleChat(tester);
      expect(tagline(OnboardingCopy.taglinePriceSkipped), findsOneWidget);

      await tester.disposeApp();
    });

    testWidgets('has its own lines for a habit without nicotine', (
      tester,
    ) async {
      await pumpOnboardingChat(tester);
      await answerName(tester);
      await tester.tap(find.text('Caffeine'));
      await settleChat(tester);
      expect(
        tagline('Caffeine. Borrowed energy, paid back at 3 PM.'),
        findsOneWidget,
      );

      await tester.tap(find.text(OnboardingCopy.aboutRight));
      await settleChat(tester);
      expect(tagline('3 a day. Noted. Judged, slightly.'), findsOneWidget);

      await tester.tap(find.text('AED 4'));
      await settleChat(tester);
      expect(tagline('AED 4 each. Your wallet felt that.'), findsOneWidget);

      await tester.disposeApp();
    });

    testWidgets('is a live region with the current line', (tester) async {
      await pumpOnboardingChat(tester);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Semantics &&
              (widget.properties.liveRegion ?? false) &&
              widget.properties.label == OnboardingCopy.taglineExcuses,
        ),
        findsOneWidget,
      );

      await tester.disposeApp();
    });

    Future<void> swap(WidgetTester tester, {required bool still}) async {
      Widget line(String text) => MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: still),
          child: Scaffold(body: ChatTagline(text)),
        ),
      );
      await tester.pumpWidget(line('One'));
      await tester.pumpWidget(line('Two'));
      await tester.pump(const Duration(milliseconds: 100));
    }

    Finder slides() => find.descendant(
      of: find.byType(ChatTagline),
      matching: find.byType(SlideTransition),
    );

    testWidgets('slides the old line up and the new one in', (tester) async {
      await swap(tester, still: false);
      expect(find.text('One'), findsOneWidget);
      expect(find.text('Two'), findsOneWidget);
      expect(
        tester.getCenter(find.text('One')).dy,
        lessThan(tester.getCenter(find.text('Two')).dy),
      );
      expect(slides(), findsNWidgets(2));

      await tester.pumpAndSettle();
      expect(find.text('One'), findsNothing);
      expect(find.text('Two'), findsOneWidget);
    });

    testWidgets('cross-fades without sliding under Reduce Motion', (
      tester,
    ) async {
      await swap(tester, still: true);
      expect(find.text('One'), findsOneWidget);
      expect(find.text('Two'), findsOneWidget);
      expect(slides(), findsNothing);

      await tester.pumpAndSettle();
      expect(find.text('One'), findsNothing);
    });
  });

  group("main's welcome look", () {
    Rect bubbleOf(WidgetTester tester, Finder text) => tester.getRect(
      find.ancestor(of: text, matching: find.byType(DecoratedBox)).first,
    );

    final readAt = RegExp(r'^Read \d{1,2}:\d{2} [AP]M$');

    testWidgets('opens with who sent the excuses and when', (tester) async {
      await pumpOnboardingChat(tester);

      final header = find.textContaining(
        RegExp(r'^You · \d{1,2}:\d{2} [AP]M$'),
        findRichText: true,
      );
      expect(header, findsOneWidget);
      expect(
        tester.getBottomLeft(header).dy,
        lessThan(tester.getTopLeft(find.text(OnboardingCopy.excuses.first)).dy),
      );

      await tester.disposeApp();
    });

    testWidgets('only the last excuse shows its status', (tester) async {
      await pumpOnboardingChat(tester);
      final read = find.textContaining(readAt);
      expect(read, findsOneWidget);
      expect(
        tester.getTopLeft(read).dy,
        greaterThan(
          bubbleOf(tester, find.text(OnboardingCopy.excuses.last)).bottom,
        ),
      );
      expect(
        find.descendant(
          of: find.byType(ChatBubble),
          matching: find.textContaining(RegExp(r'\d:\d\d')),
        ),
        findsNothing,
      );

      await answerName(tester);
      expect(
        tester
            .widgetList<ChatStatus>(
              find.byType(ChatStatus, skipOffstage: false),
            )
            .map((status) => status.item.text),
        everyElement(OnboardingCopy.excuses.last),
      );

      await tester.disposeApp();
    });

    testWidgets('4 pt within a run, 12 pt when the side changes', (
      tester,
    ) async {
      await pumpOnboardingChat(tester);
      const excuses = OnboardingCopy.excuses;

      expect(
        bubbleOf(tester, find.text(excuses[1])).top -
            bubbleOf(tester, find.text(excuses[0])).bottom,
        4,
      );
      final heard = bubbleOf(tester, find.text(OnboardingCopy.heardThemAll));
      expect(
        heard.top - tester.getBottomLeft(find.textContaining(readAt)).dy,
        12,
      );
      expect(
        bubbleOf(tester, find.textContaining(OnboardingCopy.askWho)).top -
            heard.bottom,
        4,
      );

      await tester.disposeApp();
    });

    testWidgets("bubbles take main's colours in light and dark", (
      tester,
    ) async {
      for (final theme in [AppTheme.light, AppTheme.dark]) {
        late BuildContext context;
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: Builder(
              builder: (c) {
                context = c;
                return const SizedBox();
              },
            ),
          ),
        );
        // Let the theme finish animating from the last one.
        await tester.pumpAndSettle();
        final colors = context.colors;
        final exhale = ChatBubbleColors.of(context, mine: false);
        final mine = ChatBubbleColors.of(context, mine: true);
        expect(exhale.background, context.exhale.emphasis);
        expect(exhale.foreground, context.exhale.onEmphasis);
        expect(
          mine.background,
          theme.brightness == Brightness.dark
              ? colors.surfaceContainerHigh
              : colors.surfaceContainerHighest,
        );
        expect(mine.foreground, colors.onSurface);
      }
    });

    Future<void> pumpEntrance(
      WidgetTester tester,
      ChatItem item, {
      required bool still,
    }) => tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: still),
          child: Align(
            alignment: Alignment.topLeft,
            child: ChatEntrance(item: item, child: const Text('Hi')),
          ),
        ),
      ),
    );

    /// The entrance's fade; it drops the fade once fully in.
    double opacity(WidgetTester tester) {
      final fade = find.descendant(
        of: find.byType(ChatEntrance),
        matching: find.byType(Opacity),
      );
      return fade.evaluate().isEmpty ? 1 : tester.widget<Opacity>(fade).opacity;
    }

    double height(WidgetTester tester) =>
        tester.getSize(find.byType(ChatEntrance)).height;

    testWidgets('a new message grows, fades and rises in once', (tester) async {
      final item = ChatText.exhale(() => 'Hi');
      await pumpEntrance(tester, item, still: false);
      expect(opacity(tester), 0);
      expect(height(tester), 0);

      await tester.pump(const Duration(milliseconds: 225));
      expect(opacity(tester), allOf(greaterThan(0), lessThan(1)));
      final halfway = height(tester);
      await tester.pump(const Duration(milliseconds: 225));
      expect(opacity(tester), 1);
      expect(height(tester), greaterThan(halfway));

      await tester.pumpWidget(const SizedBox());
      await pumpEntrance(tester, item, still: false);
      expect(opacity(tester), 1);
    });

    testWidgets('a field inside keeps its text when the entrance ends', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: ChatEntrance(
              item: ChatText.exhale(() => 'Hi'),
              // No controller passed, so a rebuilt field would come back
              // empty.
              child: const TextField(),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));
      await tester.enterText(find.byType(TextField), 'Alex');
      final before = tester.state(find.byType(EditableText));

      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.state(find.byType(EditableText)), same(before));
      expect(find.text('Alex'), findsOneWidget);
    });

    testWidgets('under Reduce Motion a new message just appears', (
      tester,
    ) async {
      await pumpEntrance(tester, ChatText.exhale(() => 'Hi'), still: true);
      expect(opacity(tester), 1);
    });

    testWidgets('the dock reaches the bottom edge, its tagline close under', (
      tester,
    ) async {
      tester.view.padding = const FakeViewPadding(bottom: 34 * 3);
      await pumpOnboardingChat(tester);

      final button = tester.getRect(seePlan());
      final line = tester.getRect(find.byType(ChatTagline));
      expect(line.top - button.bottom, 8);
      expect(line.bottom, 844 - 34);
      final dock = find
          .ancestor(of: seePlan(), matching: find.byType(DecoratedBox))
          .first;
      expect(tester.getRect(dock).bottom, 844);

      await tester.disposeApp();
    });

    testWidgets('the button stays put from the welcome to the plan', (
      tester,
    ) async {
      // The test font's square glyphs would wrap the welcome's fine print.
      await loadAppFonts();
      reduceMotion(tester);
      tester.view.padding = const FakeViewPadding(bottom: 34 * 3);
      await pumpOnboarding(tester);
      await tester.pumpAndSettle();
      final welcome = tester.getRect(
        find.widgetWithText(ChevronButton, OnboardingCopy.welcomeButton),
      );

      await tester.tap(find.text(OnboardingCopy.welcomeButton));
      await settleChat(tester);
      expect(tester.getRect(seePlan()), welcome);

      await answerAll(tester);
      await tester.tap(seePlan());
      await tester.pumpAndSettle();
      expect(tester.getRect(planButton()), welcome);

      await tester.disposeApp();
    });
  });
}
