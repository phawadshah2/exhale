import 'dart:async';
import 'dart:math' as math;

import 'package:exhale/core/presentation/formatting/app_format.dart';
import 'package:exhale/features/habit/domain/entities/habit.dart';
import 'package:exhale/features/onboarding/presentation/onboarding_copy.dart';
import 'package:exhale/features/onboarding/presentation/providers/onboarding_form_provider.dart';
import 'package:flutter/foundation.dart';

enum ChatAsk { none, name, habit, amount, price, perContainer, wake, bed, done }

enum Delivery { sent, delivered, read }

sealed class ChatItem {
  ChatItem() : time = DateTime.now();

  final DateTime time;
}

class ChatText extends ChatItem {
  ChatText.exhale(this.text) : mine = false, delivery = Delivery.read;
  ChatText.mine(this.text) : mine = true, delivery = Delivery.sent;

  final String text;
  final bool mine;
  Delivery delivery;
}

class MoneyCard extends ChatItem {
  MoneyCard({required this.perDay, required this.perYear, required this.line});

  final String perDay;
  final String perYear;
  final String line;
}

class DayCard extends ChatItem {
  DayCard({
    required this.wakeShort,
    required this.bedShort,
    required this.awake,
    required this.gap,
    required this.dots,
    required this.label,
  });

  final String wakeShort;
  final String bedShort;
  final String awake;
  final String gap;
  final int dots;
  final String label;
}

/// How one habit sounds in the chat. Containers are only asked about for the
/// three habits that come in a pod, pack or can.
class ChatHabit {
  const ChatHabit(
    this.kind, {
    required this.verb,
    required this.typical,
    required this.price,
    this.container,
    this.per = 1,
  });

  final HabitKind kind;
  final String verb;
  final int typical;

  /// Base price for the price chips; null when the habit has no price.
  final int? price;
  final String? container;
  final int per;

  static const List<ChatHabit> all = [
    ChatHabit(
      HabitKind.vaping,
      verb: 'vape',
      typical: 12,
      price: 10,
      container: 'pod',
      per: 30,
    ),
    ChatHabit(
      HabitKind.smoking,
      verb: 'smoke',
      typical: 10,
      price: 12,
      container: 'pack',
      per: 20,
    ),
    ChatHabit(
      HabitKind.nicotinePouches,
      verb: 'reach for a pouch',
      typical: 8,
      price: 6,
      container: 'can',
      per: 20,
    ),
    ChatHabit(HabitKind.alcohol, verb: 'drink', typical: 3, price: 7),
    ChatHabit(
      HabitKind.caffeine,
      verb: 'reach for a coffee',
      typical: 3,
      price: 4,
    ),
    ChatHabit(
      HabitKind.energyDrinks,
      verb: 'crack one open',
      typical: 2,
      price: 3,
    ),
    ChatHabit(HabitKind.junkFood, verb: 'snack', typical: 2, price: 5),
    ChatHabit(
      HabitKind.socialMedia,
      verb: 'open the apps',
      typical: 20,
      price: null,
    ),
    ChatHabit(HabitKind.custom, verb: 'do it', typical: 5, price: 5),
  ];

  static ChatHabit of(HabitKind kind) =>
      all.firstWhere((habit) => habit.kind == kind);
}

/// The scripted onboarding conversation: what Exhale says, what the user's
/// taps send, and which answer is asked next. Answers go to the form.
class OnboardingChat extends ChangeNotifier {
  OnboardingChat({
    required this.form,
    required this.controller,
    required this.reduceMotion,
  });

  final OnboardingFormState Function() form;
  final OnboardingFormController Function() controller;
  final bool Function() reduceMotion;

  static const List<int> wakeChoices = [300, 360, 420, 480, 540, 600];
  static const List<int> bedChoices = [1260, 1320, 1380, 1440, 1500, 1560];

  final List<ChatItem> items = [];
  final List<Timer> _timers = [];
  ChatAsk ask = ChatAsk.none;
  bool typing = false;
  bool priceSkipped = false;
  bool _disposed = false;

  ChatHabit get habit => ChatHabit.of(form().habitKind);

  bool get busy => typing || ask == ChatAsk.none;

  void _later(int ms, VoidCallback fn) {
    _timers.add(
      Timer(Duration(milliseconds: ms), () {
        if (!_disposed) fn();
      }),
    );
  }

  void _add(ChatItem item) {
    items.add(item);
    notifyListeners();
  }

  void _mark(ChatText item, Delivery delivery) {
    item.delivery = delivery;
    notifyListeners();
  }

  void _ask(ChatAsk next) {
    ask = next;
    notifyListeners();
  }

  /// The three excuses arrive, then Exhale asks who it is talking to.
  void start() {
    final still = reduceMotion();
    for (final (i, excuse) in OnboardingCopy.excuses.indexed) {
      final item = ChatText.mine(excuse);
      _later(still ? 0 : 500 + i * 1000, () {
        _add(item);
        if (still) _mark(item, Delivery.read);
      });
      if (!still) _later(850 + i * 1000, () => _mark(item, Delivery.delivered));
    }
    if (!still) {
      _later(3300, () {
        for (final item in items.whereType<ChatText>()) {
          item.delivery = Delivery.read;
        }
        notifyListeners();
      });
    }
    _says(
      [OnboardingCopy.askWho],
      () => _ask(ChatAsk.name),
      start: still ? 100 : 3700,
    );
  }

  /// Plays [lines] with typing dots before each: a [String] is Exhale's line,
  /// a function builds a card when it lands.
  void _says(List<Object> lines, VoidCallback after, {int start = 0}) {
    final still = reduceMotion();
    var t = start;
    for (final line in lines) {
      final text = line is String ? line : null;
      if (!still) {
        _later(t, () {
          typing = true;
          notifyListeners();
        });
      }
      t += still
          ? 250
          : text != null
          ? math.min(1700, 500 + text.length * 13)
          : 1300;
      _later(t, () {
        typing = false;
        _add(
          text != null
              ? ChatText.exhale(text)
              : (line as ChatItem Function())(),
        );
      });
      if (!still) t += 380;
    }
    _later(t, after);
  }

  /// Sends the user's [text], ticks it sent, delivered and read, then runs
  /// [then] to apply the answer and let Exhale reply.
  void _answer(String text, VoidCallback apply, VoidCallback then) {
    if (busy) return;
    final still = reduceMotion();
    final item = ChatText.mine(text);
    ask = ChatAsk.none;
    apply();
    _add(item);
    if (still) {
      _mark(item, Delivery.read);
      _later(200, then);
      return;
    }
    _later(400, () => _mark(item, Delivery.delivered));
    _later(900, () => _mark(item, Delivery.read));
    _later(1100, then);
  }

  void sendName(String raw) {
    final name = raw.trim();
    if (name.isEmpty) return;
    _answer(
      name,
      () => controller().setUserName(name),
      () => _afterName(OnboardingCopy.nameReply(name)),
    );
  }

  void skipName() => _answer(
    OnboardingCopy.nameSkip,
    () => controller().setUserName(''),
    () => _afterName(OnboardingCopy.nameSkipReply),
  );

  void _afterName(String first) => _says([
    first,
    OnboardingCopy.heardThemAll,
    OnboardingCopy.helpingIsMyJob,
  ], () => _ask(ChatAsk.habit));

  String labelOf(HabitKind kind) => kind == HabitKind.custom
      ? OnboardingCopy.somethingElse
      : Habit.preset(kind).name;

  void pickHabit(HabitKind kind) {
    final chosen = ChatHabit.of(kind);
    _answer(
      labelOf(kind),
      () {
        priceSkipped = false;
        final c = controller()..selectHabit(kind);
        if (kind == HabitKind.custom) {
          c
            ..setCustomName(OnboardingCopy.somethingElse)
            ..setCustomUnit('time');
        }
        c
          ..setStartLimit(chosen.typical)
          ..setUnitsPerContainer(chosen.per)
          ..skipPrice();
      },
      () => _says([
        OnboardingCopy.habitReply(kind),
        OnboardingCopy.amountAsk(chosen.verb),
      ], () => _ask(ChatAsk.amount)),
    );
  }

  void setAmount(int value) => controller().setStartLimit(value);

  void setPerContainer(int value) => controller().setUnitsPerContainer(value);

  /// Sends the stepper's value for whichever question is open.
  void sendStepper() {
    if (ask == ChatAsk.amount) {
      _answer(OnboardingCopy.aboutAmount(form().startLimit), () {}, () {
        final reaction = OnboardingCopy.amountReaction(
          amount: form().startLimit,
          typical: habit.typical,
        );
        if (habit.price == null) {
          _says([
            OnboardingCopy.noPriceReply(reaction),
            ..._dayIntro(),
          ], () => _ask(ChatAsk.wake));
        } else {
          _says([
            reaction + OnboardingCopy.painfulAsk(habit.container),
          ], () => _ask(ChatAsk.price));
        }
      });
    } else if (ask == ChatAsk.perContainer) {
      _answer(
        OnboardingCopy.aboutAmount(form().unitsPerContainer),
        () {},
        () => _says([_moneyCard, ..._dayIntro()], () => _ask(ChatAsk.wake)),
      );
    }
  }

  /// Price chips: the base price scaled, whole units, no duplicates.
  List<int> get priceChoices => habit.price == null
      ? const []
      : {
          for (final f in const [0.5, 0.8, 1.0, 1.5])
            math.max(1, (habit.price! * f).round()),
        }.toList();

  String money(int whole) =>
      AppFormat.money(whole * 100, symbol: form().currency, wholeUnits: true);

  void pickPrice(int price) =>
      _answer(money(price), () => controller().setPriceText('$price'), () {
        final container = habit.container;
        if (container != null) {
          _says([
            OnboardingCopy.perContainerAsk(
              Habit.preset(form().habitKind).units,
              container,
            ),
          ], () => _ask(ChatAsk.perContainer));
        } else {
          _says([_moneyCard, ..._dayIntro()], () => _ask(ChatAsk.wake));
        }
      });

  void skipPrice() => _answer(
    OnboardingCopy.skipPrice,
    () {
      priceSkipped = true;
      controller().skipPrice();
    },
    () => _says([
      OnboardingCopy.skipPriceReply(_unitsLabel),
      ..._dayIntro(),
    ], () => _ask(ChatAsk.wake)),
  );

  String get _unitsLabel => form().habit.units;

  ChatItem _moneyCard() {
    final f = form();
    final unit = f.unitPriceCents ?? 0;
    final daily = (unit * f.startLimit).round();
    return MoneyCard(
      perDay: AppFormat.money(daily, symbol: f.currency),
      perYear: AppFormat.money(
        (unit * f.startLimit * 365).round(),
        symbol: f.currency,
        wholeUnits: true,
      ),
      line: OnboardingCopy.moneyLine(
        amount: f.startLimit,
        price: AppFormat.money(
          f.priceCents ?? 0,
          symbol: f.currency,
          wholeUnits: true,
        ),
        container: habit.container,
        per: f.unitsPerContainer,
      ),
    );
  }

  List<Object> _dayIntro() => [
    OnboardingCopy.dayTwoMore,
    OnboardingCopy.daySpread(form().startLimit),
  ];

  static String hour(int minute) {
    final h = (minute % 1440) ~/ 60;
    final h12 = h % 12 == 0 ? 12 : h % 12;
    return '$h12 ${h < 12 ? 'AM' : 'PM'}';
  }

  static String _short(int minute) {
    final h = (minute % 1440) ~/ 60;
    final h12 = h % 12 == 0 ? 12 : h % 12;
    return '$h12${h < 12 ? 'a' : 'p'}';
  }

  static String _span(num minutes) {
    final h = minutes ~/ 60;
    final m = (minutes % 60).round();
    if (h == 0) return '$m min';
    return m == 0 ? '$h h' : '$h h $m min';
  }

  void pickTime(int minute) {
    if (ask == ChatAsk.wake) {
      _answer(
        hour(minute),
        () => controller().setDayWindow(
          wakeMinute: minute,
          bedMinute: form().bedMinute,
        ),
        () => _says([
          OnboardingCopy.wakeLead(minute) + OnboardingCopy.lightsOut,
        ], () => _ask(ChatAsk.bed)),
      );
    } else if (ask == ChatAsk.bed) {
      _answer(
        hour(minute),
        () => controller().setDayWindow(
          wakeMinute: form().wakeMinute,
          bedMinute: minute,
        ),
        () => _says([
          _dayCard,
          OnboardingCopy.planReady(form().userName),
        ], () => _ask(ChatAsk.done)),
      );
    }
  }

  ChatItem _dayCard() {
    final f = form();
    final span = f.dayWindow.awakeMinutes;
    return DayCard(
      wakeShort: _short(f.wakeMinute),
      bedShort: _short(f.bedMinute),
      awake: _span(span),
      gap: _span(span / f.startLimit),
      dots: math.min(f.startLimit, 16),
      label:
          '${f.startLimit} ${f.habit.units} spread from '
          '${hour(f.wakeMinute)} to ${hour(f.bedMinute)}',
    );
  }

  @override
  void dispose() {
    _disposed = true;
    for (final timer in _timers) {
      timer.cancel();
    }
    super.dispose();
  }
}
