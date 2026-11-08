import 'dart:async';
import 'dart:math' as math;

import 'package:exhale/core/presentation/formatting/app_format.dart';
import 'package:exhale/features/habit/domain/entities/habit.dart';
import 'package:exhale/features/habit/domain/validation/habit_validation.dart';
import 'package:exhale/features/onboarding/presentation/onboarding_copy.dart';
import 'package:exhale/features/onboarding/presentation/providers/onboarding_form_provider.dart';
import 'package:exhale/features/settings/domain/entities/day_window.dart';
import 'package:flutter/foundation.dart';

enum ChatAsk { name, habit, amount, price, perContainer, day }

enum Delivery { sent, delivered, read }

sealed class ChatItem {
  /// When the item landed in the chat.
  late final DateTime time;
}

/// A text bubble. Its text is read when shown, so a line that quotes an
/// answer always shows the current one.
class ChatText extends ChatItem {
  ChatText.exhale(this._text)
    : mine = false,
      answers = null,
      delivery = Delivery.read;
  ChatText.mine(this._text, {this.answers})
    : mine = true,
      delivery = Delivery.sent;

  final String Function() _text;
  final bool mine;

  /// The question this bubble answers; null for Exhale's and the excuses.
  final ChatQuestion? answers;
  Delivery delivery;

  String get text => _text();
}

/// An Exhale message that asks for an answer. Its controls show while
/// [open]; answering folds it back to its text.
class ChatQuestion extends ChatText {
  ChatQuestion(this.ask, String Function() text) : super.exhale(text);

  final ChatAsk ask;
  bool open = true;
}

typedef MoneyFigures = ({String perDay, String perYear, String line});

class MoneyCard extends ChatItem {
  MoneyCard(this._figures);

  final MoneyFigures Function() _figures;

  MoneyFigures get figures => _figures();
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
    ChatHabit(HabitKind.alcohol, verb: 'drink', typical: 3, price: 7),
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

/// The scripted onboarding conversation: what Exhale says, the questions it
/// asks, and the user's answers. Answers go to the form.
class OnboardingChat extends ChangeNotifier {
  OnboardingChat({
    required this.form,
    required this.controller,
    required this.reduceMotion,
  });

  final OnboardingFormState Function() form;
  final OnboardingFormController Function() controller;
  final bool Function() reduceMotion;

  static const String customUnit = 'time';

  final List<ChatItem> items = [];
  final List<Timer> _timers = [];
  bool typing = false;
  bool done = false;
  bool _disposed = false;
  ChatQuestion? _reopened;

  ChatHabit get habit => ChatHabit.of(form().habitKind);

  /// The reopened question, else the newest open one, if any.
  ChatQuestion? get question {
    if (_reopened case final reopened?) return reopened;
    for (final item in items.reversed) {
      if (item is ChatQuestion && item.open) return item;
    }
    return null;
  }

  ChatAsk? get ask => question?.ask;

  /// An earlier question opened again to change its answer.
  ChatQuestion? get reopened => _reopened;

  void _later(int ms, VoidCallback fn) {
    _timers.add(
      Timer(Duration(milliseconds: ms), () {
        if (!_disposed) fn();
      }),
    );
  }

  void _add(ChatItem item) {
    item.time = DateTime.now();
    items.add(item);
    notifyListeners();
  }

  ChatText? _answerOf(ChatQuestion question) {
    for (final item in items) {
      if (item is ChatText && item.answers == question) return item;
    }
    return null;
  }

  /// Opens the question [answer] answered again, folding any other reopened
  /// one. Not while Exhale types, and never for the excuses.
  bool reopen(ChatText answer) {
    final asked = answer.answers;
    if (typing || asked == null || !items.contains(answer)) return false;
    _reopened?.open = false;
    _reopened = asked..open = true;
    notifyListeners();
    return true;
  }

  /// Drops everything after [answer], for an answer that changes which
  /// questions follow.
  void _truncateAfter(ChatText answer) {
    for (final timer in _timers) {
      timer.cancel();
    }
    _timers.clear();
    typing = false;
    done = false;
    items.removeRange(items.indexOf(answer) + 1, items.length);
    for (final item in items.whereType<ChatText>()) {
      if (item.mine) item.delivery = Delivery.read;
    }
  }

  void _mark(ChatText item, Delivery delivery) {
    item.delivery = delivery;
    notifyListeners();
  }

  /// The three excuses arrive, then Exhale asks who it is talking to.
  void start() {
    final still = reduceMotion();
    for (final (i, excuse) in OnboardingCopy.excuses.indexed) {
      final item = ChatText.mine(() => excuse);
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
    _says([
      ChatText.exhale(() => OnboardingCopy.heardThemAll),
      ChatQuestion(ChatAsk.name, () => OnboardingCopy.askWho),
    ], start: still ? 100 : 3700);
  }

  /// Plays [lines] with typing dots before each, then runs [after].
  void _says(List<ChatItem> lines, {VoidCallback? after, int start = 0}) {
    final still = reduceMotion();
    var t = start;
    for (final line in lines) {
      if (!still) {
        _later(t, () {
          typing = true;
          notifyListeners();
        });
      }
      t += still
          ? 250
          : line is ChatText
          ? math.min(1700, 500 + line.text.length * 13)
          : 1300;
      _later(t, () {
        typing = false;
        _add(line);
      });
      if (!still) t += 380;
    }
    if (after != null) _later(t, after);
  }

  /// Folds the open [ask], applies the answer, sends [text] as the user's
  /// bubble with sent, delivered and read ticks, then runs [then] for
  /// Exhale's reply. A reopened question's bubble updates in place; only when
  /// [path] changes does the chat drop what followed and run [then] again.
  void _answer(
    ChatAsk ask,
    String Function() text,
    VoidCallback apply,
    VoidCallback then, {
    Object? Function()? path,
  }) {
    final open = question;
    if (typing || open == null || open.ask != ask) return;
    open.open = false;
    if (_answerOf(open) case final answered?) {
      _reopened = null;
      final before = path?.call();
      apply();
      if (path != null && path() != before) {
        _truncateAfter(answered);
        then();
      }
      notifyListeners();
      return;
    }
    final still = reduceMotion();
    apply();
    final item = ChatText.mine(text, answers: open);
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
      ChatAsk.name,
      _nameAnswer,
      () => controller().setUserName(name),
      _askHabit,
    );
  }

  void skipName() => _answer(
    ChatAsk.name,
    _nameAnswer,
    () => controller().setUserName(''),
    _askHabit,
  );

  String _nameAnswer() {
    final name = form().userName;
    return name.isEmpty ? OnboardingCopy.nameSkip : name;
  }

  void _askHabit() => _says([
    ChatText.exhale(() {
      final name = form().userName;
      return name.isEmpty
          ? OnboardingCopy.nameSkipReply
          : OnboardingCopy.nameReply(name);
    }),
    ChatQuestion(ChatAsk.habit, () => OnboardingCopy.helpingIsMyJob),
  ]);

  String labelOf(HabitKind kind) =>
      kind == HabitKind.custom ? OnboardingCopy.other : Habit.preset(kind).name;

  /// Picks a preset, or with [customName] the user's own habit.
  void pickHabit(HabitKind kind, {String? customName}) {
    final name = customName?.trim() ?? '';
    if (kind == HabitKind.custom && name.isEmpty) return;
    final chosen = ChatHabit.of(kind);
    final question = this.question;
    final again = question != null && _answerOf(question) != null;
    _answer(
      ChatAsk.habit,
      () {
        final f = form();
        return f.habitKind == HabitKind.custom
            ? f.customName
            : Habit.preset(f.habitKind).name;
      },
      () {
        final c = controller();
        if (!again || form().habitKind != kind) {
          c
            ..selectHabit(kind)
            ..setStartLimit(chosen.typical)
            ..setUnitsPerContainer(chosen.per)
            ..skipPrice();
        }
        if (kind == HabitKind.custom) {
          c
            ..setCustomName(name)
            ..setCustomUnit(customUnit);
        }
      },
      () => _says([
        ChatText.exhale(() => OnboardingCopy.habitReply(form().habitKind)),
        ChatQuestion(
          ChatAsk.amount,
          () => OnboardingCopy.amountAsk(habit.verb),
        ),
      ]),
      path: () => form().habitKind,
    );
  }

  void setAmount(int value) => controller().setStartLimit(value);

  void setPerContainer(int value) => controller().setUnitsPerContainer(value);

  String get _reaction => OnboardingCopy.amountReaction(
    amount: form().startLimit,
    typical: habit.typical,
  );

  void sendAmount() => _answer(
    ChatAsk.amount,
    () => OnboardingCopy.amountAnswer(form().startLimit),
    () {},
    () => habit.price == null
        ? _says([
            ChatText.exhale(() => OnboardingCopy.noPriceReply(_reaction)),
            _dayQuestion(),
          ])
        : _says([
            ChatQuestion(
              ChatAsk.price,
              () => _reaction + OnboardingCopy.painfulAsk(habit.container),
            ),
          ]),
  );

  /// Price chips: the base price scaled, whole units, no duplicates.
  List<int> get priceChoices => habit.price == null
      ? const []
      : {
          for (final f in const [0.5, 0.8, 1.0, 1.2, 1.5])
            math.max(1, (habit.price! * f).round()),
        }.toList();

  String money(int whole) =>
      AppFormat.money(whole * 100, symbol: form().currency, wholeUnits: true);

  String _price(int cents) => AppFormat.money(
    cents,
    symbol: form().currency,
    wholeUnits: cents % 100 == 0,
  );

  void pickPrice(int price) => _sendPrice('$price');

  /// A price typed under Other. Returns false, and sends nothing, when it is
  /// not a valid price.
  bool sendPriceText(String raw) {
    final cents = AppFormat.parseCents(raw.trim());
    if (cents == null || cents <= 0) return false;
    if (cents > HabitValidation.maxPriceCents) return false;
    _sendPrice(raw.trim());
    return true;
  }

  void _sendPrice(String text) => _answer(
    ChatAsk.price,
    _priceAnswer,
    () => controller().setPriceText(text),
    () {
      final container = habit.container;
      _says([
        if (container != null)
          ChatQuestion(
            ChatAsk.perContainer,
            () => OnboardingCopy.perContainerAsk(form().habit.units, container),
          )
        else
          ..._moneyAndDay(),
      ]);
    },
    path: _priced,
  );

  void skipPrice() => _answer(
    ChatAsk.price,
    _priceAnswer,
    () => controller().skipPrice(),
    () => _says([
      ChatText.exhale(() => OnboardingCopy.skipPriceReply(form().habit.units)),
      _dayQuestion(),
    ]),
    path: _priced,
  );

  String _priceAnswer() => switch (form().priceCents) {
    final cents? => _price(cents),
    null => OnboardingCopy.skipPrice,
  };

  /// Whether a price was given: it decides the pod and money card.
  bool _priced() => form().priceCents != null;

  void sendPerContainer() => _answer(
    ChatAsk.perContainer,
    () => OnboardingCopy.perContainerAnswer(
      form().unitsPerContainer,
      habit.container ?? '',
    ),
    () {},
    () => _says(_moneyAndDay()),
  );

  List<ChatItem> _moneyAndDay() => [
    MoneyCard(_moneyFigures),
    ChatText.exhale(() => OnboardingCopy.dayTwoMore),
    _dayQuestion(),
  ];

  MoneyFigures _moneyFigures() {
    final f = form();
    final unit = f.unitPriceCents ?? 0;
    return (
      perDay: AppFormat.money(
        (unit * f.startLimit).round(),
        symbol: f.currency,
      ),
      perYear: AppFormat.money(
        (unit * f.startLimit * 365).round(),
        symbol: f.currency,
        wholeUnits: true,
      ),
      line: OnboardingCopy.moneyLine(
        amount: f.startLimit,
        price: _price(f.priceCents ?? 0),
        container: habit.container,
        per: f.unitsPerContainer,
      ),
    );
  }

  ChatQuestion _dayQuestion() => ChatQuestion(
    ChatAsk.day,
    () => OnboardingCopy.daySpread(form().startLimit),
  );

  /// Moves the day window; ignored when it would leave too little time
  /// awake.
  void setDay({required int wakeMinute, required int bedMinute}) =>
      controller().setDayWindow(
        wakeMinute: wakeMinute % DayWindow.minutesPerDay,
        bedMinute: bedMinute % DayWindow.minutesPerDay,
      );

  /// Sends the wake and bed times already on the form.
  void sendDay() => _answer(
    ChatAsk.day,
    () => OnboardingCopy.dayAnswer(
      AppFormat.minuteOfDay(form().wakeMinute),
      AppFormat.minuteOfDay(form().bedMinute),
    ),
    () {},
    () => _says(
      [ChatText.exhale(() => OnboardingCopy.planReady(form().userName))],
      after: () {
        done = true;
        notifyListeners();
      },
    ),
  );

  @override
  void dispose() {
    _disposed = true;
    for (final timer in _timers) {
      timer.cancel();
    }
    super.dispose();
  }
}
