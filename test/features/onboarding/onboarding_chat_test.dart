import 'package:exhale/core/di/injection_container.dart';
import 'package:exhale/features/habit/domain/entities/habit.dart';
import 'package:exhale/features/onboarding/presentation/onboarding_copy.dart';
import 'package:exhale/features/onboarding/presentation/providers/onboarding_chat.dart';
import 'package:exhale/features/onboarding/presentation/providers/onboarding_form_provider.dart';
import 'package:exhale/features/settings/presentation/providers/settings_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fixed_clock.dart';
import '../../helpers/pump_app.dart';

void main() {
  late ProviderContainer container;
  late OnboardingChat chat;

  setUp(() async {
    await setUpTestDependencies(FixedClock(DateTime(2026, 11, 8, 9)));
    container = ProviderContainer.test(
      overrides: [deviceRegionProvider.overrideWithValue('US')],
    )..listen(onboardingFormProvider, (_, _) {});
    chat = OnboardingChat(
      form: () => container.read(onboardingFormProvider),
      controller: () => container.read(onboardingFormProvider.notifier),
      reduceMotion: () => true,
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
    expect(money.perDay, r'$4.00');
    expect(money.perYear, r'$1,460');
    expect(money.line, r'12 a day, a $10 pod lasts 30. Your rent is jealous.');
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

  testWidgets('a habit without a container prices one and skips the pod', (
    tester,
  ) async {
    await throughAmount(tester, HabitKind.caffeine);
    expect(lastMine().text, '3 a day');
    expect(question().text, endsWith('What does one cost you, roughly?'));

    chat.pickPrice(4);
    await settle(tester);

    expect(
      chat.items.whereType<MoneyCard>().single.figures.line,
      r'3 a day at $4 each. Your rent is jealous.',
    );
    expect(chat.ask, ChatAsk.day);
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
}
