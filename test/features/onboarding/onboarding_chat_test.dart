import 'package:exhale/core/di/injection_container.dart';
import 'package:exhale/core/presentation/formatting/app_format.dart';
import 'package:exhale/features/habit/domain/entities/habit.dart';
import 'package:exhale/features/onboarding/presentation/onboarding_copy.dart';
import 'package:exhale/features/onboarding/presentation/onboarding_pace.dart';
import 'package:exhale/features/onboarding/presentation/providers/onboarding_chat.dart';
import 'package:exhale/features/onboarding/presentation/providers/onboarding_form_provider.dart';
import 'package:exhale/features/plan/domain/entities/reduction_plan.dart';
import 'package:exhale/features/settings/presentation/providers/settings_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fixed_clock.dart';
import '../../helpers/pump_app.dart';

void main() {
  late ProviderContainer container;
  late OnboardingChat chat;
  late bool still;

  setUp(() async {
    still = true;
    await setUpTestDependencies(FixedClock(DateTime(2026, 11, 8, 9)));
    container = ProviderContainer.test(
      overrides: [deviceRegionProvider.overrideWithValue('US')],
    )..listen(onboardingFormProvider, (_, _) {});
    chat = OnboardingChat(
      form: () => container.read(onboardingFormProvider),
      controller: () => container.read(onboardingFormProvider.notifier),
      reduceMotion: () => still,
    );
  });

  tearDown(() async {
    chat.dispose();
    await InjectionContainer.reset();
  });

  OnboardingFormState form() => container.read(onboardingFormProvider);

  // Every timer in the script, with Reduce Motion on, is well under this.
  Future<void> settle(WidgetTester tester) =>
      tester.pump(const Duration(seconds: 10));

  List<String> texts() => [
    for (final item in chat.items)
      if (item is ChatText) item.text,
  ];

  ChatQuestion question() => chat.items.whereType<ChatQuestion>().last;

  ChatText answerTo(ChatAsk ask) => chat.items
      .whereType<ChatText>()
      .singleWhere((item) => item.answers?.ask == ask);

  ChatQuestion asked(ChatAsk ask) =>
      chat.items.whereType<ChatQuestion>().singleWhere((q) => q.ask == ask);

  ChatText lastMine() =>
      chat.items.whereType<ChatText>().where((item) => item.mine).last;

  Future<void> throughName(WidgetTester tester, {String name = 'Alex'}) async {
    chat.start();
    await settle(tester);
    chat.sendName(name);
    await settle(tester);
  }

  Future<void> throughAmount(
    WidgetTester tester,
    HabitKind kind, {
    int? amount,
  }) async {
    await throughName(tester);
    chat.pickHabit(kind);
    await settle(tester);
    if (amount != null) chat.setAmount(amount);
    chat.sendAmount();
    await settle(tester);
  }

  testWidgets('opens with the excuses, then asks who it is talking to', (
    tester,
  ) async {
    chat.start();
    await settle(tester);

    expect(texts(), [
      ...OnboardingCopy.excuses,
      OnboardingCopy.heardThemAll,
      OnboardingCopy.askWho,
    ]);
    expect(
      OnboardingCopy.askWho,
      'Before you send me another excuse: who am I talking to?',
    );
    expect(chat.ask, ChatAsk.name);
    expect(question().open, isTrue);
    expect(chat.done, isFalse);
  });

  testWidgets('the excuses are sent now and read together', (tester) async {
    final before = DateTime.now();
    chat.start();
    await settle(tester);

    final excuses = chat.items.whereType<ChatText>().where((i) => i.mine);
    expect(excuses.every((e) => !e.time.isBefore(before)), isTrue);
    expect(excuses.map((e) => e.delivery), everyElement(Delivery.read));
  });

  testWidgets('with motion, the excuses are read 1.6 s after the last', (
    tester,
  ) async {
    still = false;
    chat.start();
    final excuses = chat.items.whereType<ChatText>();

    await tester.pump(const Duration(milliseconds: 1700));
    expect(excuses, hasLength(3));
    expect(excuses.map((e) => e.delivery), everyElement(Delivery.sent));
    await tester.pump(const Duration(milliseconds: 1599));
    expect(excuses.last.delivery, Delivery.sent);
    await tester.pump(const Duration(milliseconds: 1));
    expect(excuses.map((e) => e.delivery), everyElement(Delivery.read));
    await tester.pump(const Duration(seconds: 15));
  });

  testWidgets('the excuses come 600 ms apart, with motion on', (tester) async {
    still = false;
    chat.start();

    await tester.pump(const Duration(milliseconds: 500));
    expect(chat.items, hasLength(1));
    await tester.pump(const Duration(milliseconds: 599));
    expect(chat.items, hasLength(1));
    await tester.pump(const Duration(milliseconds: 1));
    expect(chat.items, hasLength(2));
    await tester.pump(const Duration(seconds: 15));
  });

  testWidgets('Exhale replies 1.9 s after an answer', (tester) async {
    chat.start();
    await settle(tester);
    still = false;

    chat.sendName('Alex');
    final count = chat.items.length;

    await tester.pump(const Duration(milliseconds: 1899));
    expect(chat.items, hasLength(count));
    expect(chat.typing, isFalse);
    await tester.pump(const Duration(milliseconds: 1));
    expect(chat.typing, isTrue);

    await tester.pump(const Duration(seconds: 15));
    expect(chat.items.length, greaterThan(count));
  });

  testWidgets('the name folds its card and asks for the habit', (tester) async {
    await throughName(tester, name: '  Alex ');

    expect(form().userName, 'Alex');
    final answer = lastMine();
    expect(answer.text, 'Alex');
    expect(answer.answers?.ask, ChatAsk.name);
    expect(answer.answers?.open, isFalse);
    expect(texts().sublist(texts().length - 2), [
      'Alex. Lovely name. Shame about the excuses.',
      OnboardingCopy.helpingIsMyJob,
    ]);
    expect(chat.ask, ChatAsk.habit);
  });

  testWidgets('a blank name sends nothing', (tester) async {
    chat.start();
    await settle(tester);
    final count = chat.items.length;

    chat.sendName('   ');
    await settle(tester);

    expect(chat.items, hasLength(count));
    expect(chat.ask, ChatAsk.name);
  });

  testWidgets('a container habit asks the price and the pod, then the day', (
    tester,
  ) async {
    await throughAmount(tester, HabitKind.vaping, amount: 12);
    expect(lastMine().text, '12 a day');
    expect(form().startLimit, 12);
    expect(chat.ask, ChatAsk.price);
    expect(
      question().text,
      'Respectable. For now. Now the painful bit. What does a pod cost you?',
    );
    expect(chat.priceChoices, [5, 8, 10, 12, 15]);

    chat.pickPrice(10);
    await settle(tester);
    expect(lastMine().text, r'$10');
    expect(form().priceCents, 1000);
    expect(chat.ask, ChatAsk.perContainer);
    expect(
      question().text,
      'And how many sessions does one pod last? Ballpark is fine. '
      "I'm not your accountant.",
    );

    chat
      ..setPerContainer(30)
      ..sendPerContainer();
    await settle(tester);
    expect(lastMine().text, '30 a pod');
    expect(form().unitsPerContainer, 30);
    final money = chat.items.whereType<MoneyCard>().single.figures;
    expect(money.perYear, r'$1,460');
    // The suggested pace tapers 12 a day to zero within the year.
    expect(money.withPlan, r'$182');
    expect(money.kept, r'$1,278');
    expect(money.planShare, closeTo(182 / 1460, 0.01));
    expect(texts().sublist(texts().length - 2), [
      OnboardingCopy.dayTwoMore,
      OnboardingCopy.daySpread(12),
    ]);
    expect(
      OnboardingCopy.daySpread(12),
      "I'll spread your 12 so they don't all land before lunch. When does "
      "your day start, and when's lights out? Roughly. I won't check.",
    );
    expect(chat.ask, ChatAsk.day);
    expect(chat.done, isFalse);

    container
        .read(onboardingFormProvider.notifier)
        .setDayWindow(wakeMinute: 420, bedMinute: 1380);
    chat.sendDay();
    await settle(tester);
    expect(lastMine().text, '7:00 AM to 11:00 PM');
    expect(
      texts().last,
      "That's everything, Alex. Your plan's ready. Brace yourself.",
    );
    expect(chat.ask, isNull);
    expect(chat.done, isTrue);
  });

  testWidgets("Exhale's new messages are announced, not the user's", (
    tester,
  ) async {
    final heard = <String>[];
    chat.dispose();
    chat = OnboardingChat(
      form: () => container.read(onboardingFormProvider),
      controller: () => container.read(onboardingFormProvider.notifier),
      reduceMotion: () => still,
      announce: heard.add,
    );
    await throughName(tester);

    expect(heard, [
      for (final item in chat.items)
        if (item is ChatText && !item.mine) item.text,
    ]);
    expect(heard, hasLength(greaterThanOrEqualTo(3)));
    expect(heard, isNot(contains('Alex')));
  });

  testWidgets('the money card uses the pace the plan screen opens on', (
    tester,
  ) async {
    await throughAmount(tester, HabitKind.caffeine);
    chat.pickPrice(4);
    await settle(tester);

    final f = form();
    final plan = ReductionPlan(
      startDay: f.startDay,
      startLimit: 3,
      quitDay: OnboardingPace.suggestedQuitDay(f.startDay, 3),
    );
    var units = 0;
    for (var d = 0; d < 365; d++) {
      units += plan.limitOn(plan.startDay.addDays(d));
    }
    final money = chat.items.whereType<MoneyCard>().single.figures;
    expect(
      money.withPlan,
      AppFormat.money(units * 400, symbol: r'$', wholeUnits: true),
    );
  });

  testWidgets('a habit without a container prices one and skips the pod', (
    tester,
  ) async {
    await throughAmount(tester, HabitKind.caffeine);
    expect(lastMine().text, '3 a day');
    expect(question().text, endsWith('What does one cost you, roughly?'));

    chat.pickPrice(4);
    await settle(tester);

    final money = chat.items.whereType<MoneyCard>().single.figures;
    expect(money.perYear, r'$4,380');
    // The plan screen opens on Brisk (4 weeks) at 3 a day.
    expect(money.withPlan, r'$228');
    expect(chat.ask, ChatAsk.day);
  });

  testWidgets('a drink priced alone saves as the preset bottle', (
    tester,
  ) async {
    await throughAmount(tester, HabitKind.alcohol);
    expect(question().text, endsWith('What does one cost you, roughly?'));
    chat.pickPrice(7);
    await settle(tester);

    expect(form().pricedPerUnit, isTrue);
    expect(form().unitPriceCents, 700);
    // Edit plan reads a bottle of 5 at 5 drinks' price.
    expect(form().savedPrice, (priceCents: 3500, unitsPerContainer: 5));
    expect(chat.ask, ChatAsk.day);
  });

  testWidgets('a container question saves the container as answered', (
    tester,
  ) async {
    await throughAmount(tester, HabitKind.vaping);
    chat.pickPrice(10);
    await settle(tester);
    chat
      ..setPerContainer(30)
      ..sendPerContainer();
    await settle(tester);

    expect(form().pricedPerUnit, isFalse);
    expect(form().savedPrice, (priceCents: 1000, unitsPerContainer: 30));
  });

  testWidgets('social media has no price and goes to the day', (tester) async {
    await throughAmount(tester, HabitKind.socialMedia);

    expect(chat.items.whereType<MoneyCard>(), isEmpty);
    expect(
      texts()[texts().length - 2],
      'Respectable. For now. No price tag on this one. Just your time, which '
      'is worse.',
    );
    expect(chat.ask, ChatAsk.day);
  });

  testWidgets('skipping the price counts units and goes to the day', (
    tester,
  ) async {
    await throughAmount(tester, HabitKind.vaping);

    chat.skipPrice();
    await settle(tester);

    expect(lastMine().text, OnboardingCopy.skipPrice);
    expect(form().priceText, isEmpty);
    expect(chat.items.whereType<MoneyCard>(), isEmpty);
    expect(
      texts()[texts().length - 2],
      OnboardingCopy.skipPriceReply('sessions'),
    );
    expect(chat.ask, ChatAsk.day);
  });

  testWidgets('a typed price is sent; an invalid one is not', (tester) async {
    await throughAmount(tester, HabitKind.caffeine);
    final count = chat.items.length;

    expect(chat.sendPriceText('abc'), isFalse);
    await settle(tester);
    expect(chat.items, hasLength(count));
    expect(chat.ask, ChatAsk.price);

    expect(chat.sendPriceText('7.50'), isTrue);
    await settle(tester);
    expect(lastMine().text, r'$7.50');
    expect(form().priceCents, 750);
  });

  testWidgets('skipping the name leaves it out of the replies', (tester) async {
    chat.start();
    await settle(tester);
    chat.skipName();
    await settle(tester);

    expect(lastMine().text, OnboardingCopy.nameSkip);
    expect(form().userName, isEmpty);
    expect(texts()[texts().length - 2], OnboardingCopy.nameSkipReply);

    chat.pickHabit(HabitKind.socialMedia);
    await settle(tester);
    chat.sendAmount();
    await settle(tester);
    chat.sendDay();
    await settle(tester);

    expect(
      texts().last,
      "That's everything. Your plan's ready. Brace yourself.",
    );
  });

  testWidgets('Other names a custom habit counted in times', (tester) async {
    await throughName(tester);

    chat.pickHabit(HabitKind.custom, customName: ' Gaming ');
    await settle(tester);

    expect(lastMine().text, 'Gaming');
    expect(form().habitKind, HabitKind.custom);
    expect(form().customName, 'Gaming');
    expect(form().customUnit, 'time');
    expect(chat.ask, ChatAsk.amount);
  });

  test('the pod caption rounds to a half day', () {
    expect(
      OnboardingCopy.perPodCaption(per: 30, amount: 12, container: 'pod'),
      'About one pod every 2½ days',
    );
    expect(
      OnboardingCopy.perPodCaption(per: 18, amount: 12, container: 'pod'),
      'About one pod every 1½ days',
    );
    expect(
      OnboardingCopy.perPodCaption(per: 60, amount: 12, container: 'pod'),
      'About one pod every 5 days',
    );
    expect(
      OnboardingCopy.perPodCaption(per: 10, amount: 12, container: 'pack'),
      'About one pack every day',
    );
  });

  group('fixing an answer', () {
    // Vaping at 12 a day, a $10 pod lasting 30, the day still to answer.
    Future<void> toTheDay(WidgetTester tester, {int amount = 12}) async {
      await throughAmount(tester, HabitKind.vaping, amount: amount);
      chat.pickPrice(10);
      await settle(tester);
      chat
        ..setPerContainer(30)
        ..sendPerContainer();
      await settle(tester);
    }

    testWidgets('a new name updates its bubble and the reply in place', (
      tester,
    ) async {
      await toTheDay(tester);
      final count = chat.items.length;

      expect(chat.reopen(answerTo(ChatAsk.name)), isTrue);
      expect(asked(ChatAsk.name).open, isTrue);
      expect(chat.ask, ChatAsk.name);
      chat.sendName('Sam');
      await settle(tester);

      expect(chat.items, hasLength(count));
      expect(answerTo(ChatAsk.name).text, 'Sam');
      expect(texts(), contains('Sam. Lovely name. Shame about the excuses.'));
      expect(asked(ChatAsk.name).open, isFalse);
      expect(chat.ask, ChatAsk.day);
    });

    testWidgets('a new amount updates every line that quotes it', (
      tester,
    ) async {
      await toTheDay(tester);
      final count = chat.items.length;

      chat
        ..reopen(answerTo(ChatAsk.amount))
        ..setAmount(20)
        ..sendAmount();
      await settle(tester);

      expect(chat.items, hasLength(count));
      expect(answerTo(ChatAsk.amount).text, '20 a day');
      expect(
        asked(ChatAsk.price).text,
        startsWith("That's not a habit. That's a part-time job."),
      );
      final money = chat.items.whereType<MoneyCard>().single.figures;
      expect(money.perYear, r'$2,433');
      // Gentle (12 weeks), the pace the plan screen opens on at 20.
      expect(money.withPlan, r'$297');
      // Whole units, so the kept figure is the difference shown.
      expect(money.kept, r'$2,136');
      expect(asked(ChatAsk.day).text, OnboardingCopy.daySpread(20));
      expect(chat.ask, ChatAsk.day);
    });

    testWidgets('a new habit drops what came after and asks again', (
      tester,
    ) async {
      await toTheDay(tester);
      chat.sendDay();
      await settle(tester);
      expect(chat.done, isTrue);

      chat
        ..reopen(answerTo(ChatAsk.habit))
        ..pickHabit(HabitKind.caffeine);
      await settle(tester);

      final habitAnswer = chat.items.indexOf(answerTo(ChatAsk.habit));
      expect(answerTo(ChatAsk.habit).text, 'Caffeine');
      expect(
        chat.items
            .sublist(habitAnswer + 1)
            .map((item) => item is ChatText ? item.text : item),
        [
          OnboardingCopy.habitReply(HabitKind.caffeine),
          OnboardingCopy.amountAsk('reach for a coffee'),
        ],
      );
      expect(form().habitKind, HabitKind.caffeine);
      expect(form().startLimit, 3);
      expect(form().priceText, isEmpty);
      expect(form().unitsPerContainer, 1);
      expect(chat.ask, ChatAsk.amount);
      expect(chat.done, isFalse);
    });

    testWidgets('the same habit only folds its card', (tester) async {
      await toTheDay(tester, amount: 15);
      final count = chat.items.length;

      chat
        ..reopen(answerTo(ChatAsk.habit))
        ..pickHabit(HabitKind.vaping);
      await settle(tester);

      expect(chat.items, hasLength(count));
      expect(form().startLimit, 15);
      expect(form().priceCents, 1000);
      expect(asked(ChatAsk.habit).open, isFalse);
      expect(chat.ask, ChatAsk.day);
    });

    testWidgets('pricing a skipped price asks the questions it skipped', (
      tester,
    ) async {
      await throughAmount(tester, HabitKind.vaping);
      chat.skipPrice();
      await settle(tester);

      chat
        ..reopen(answerTo(ChatAsk.price))
        ..pickPrice(10);
      await settle(tester);

      expect(answerTo(ChatAsk.price).text, r'$10');
      expect(
        texts(),
        isNot(contains(OnboardingCopy.skipPriceReply('sessions'))),
      );
      expect(chat.ask, ChatAsk.perContainer);
    });

    testWidgets('the newest card still answers while another is reopened', (
      tester,
    ) async {
      await toTheDay(tester);
      expect(chat.reopen(answerTo(ChatAsk.name)), isTrue);

      chat.sendDay();
      await settle(tester);

      expect(chat.reopened, isNull);
      expect(asked(ChatAsk.name).open, isFalse);
      expect(answerTo(ChatAsk.name).text, 'Alex');
      expect(answerTo(ChatAsk.day).mine, isTrue);
      expect(chat.done, isTrue);
    });

    testWidgets('a habit picked while the name is reopened sets its amounts', (
      tester,
    ) async {
      await throughName(tester);
      chat
        ..reopen(answerTo(ChatAsk.name))
        ..pickHabit(HabitKind.vaping);
      await settle(tester);

      expect(asked(ChatAsk.name).open, isFalse);
      expect(form().habitKind, HabitKind.vaping);
      expect(form().startLimit, ChatHabit.of(HabitKind.vaping).typical);
      expect(form().unitsPerContainer, ChatHabit.of(HabitKind.vaping).per);
      expect(chat.ask, ChatAsk.amount);
    });

    testWidgets('one card reopens at a time', (tester) async {
      await toTheDay(tester);

      chat
        ..reopen(answerTo(ChatAsk.name))
        ..reopen(answerTo(ChatAsk.amount));

      expect(asked(ChatAsk.name).open, isFalse);
      expect(asked(ChatAsk.amount).open, isTrue);
      expect(chat.ask, ChatAsk.amount);
      expect(answerTo(ChatAsk.name).text, 'Alex');
    });

    testWidgets('nothing reopens while Exhale types', (tester) async {
      still = false;
      chat.start();
      await settle(tester);
      chat.sendName('Alex');
      await tester.pump(const Duration(milliseconds: 2000));
      expect(chat.typing, isTrue);

      expect(chat.reopen(answerTo(ChatAsk.name)), isFalse);
      expect(asked(ChatAsk.name).open, isFalse);
      await settle(tester);
    });

    testWidgets('the excuses never reopen', (tester) async {
      chat.start();
      await settle(tester);

      final excuse = chat.items.whereType<ChatText>().first;
      expect(excuse.text, OnboardingCopy.excuses.first);
      expect(chat.reopen(excuse), isFalse);
      expect(chat.ask, ChatAsk.name);
    });
  });
}
