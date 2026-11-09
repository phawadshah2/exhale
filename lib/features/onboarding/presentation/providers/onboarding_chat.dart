import 'dart:async';
import 'dart:math' as math;

import 'package:exhale/core/presentation/formatting/app_format.dart';
import 'package:exhale/features/habit/domain/entities/habit.dart';
import 'package:exhale/features/habit/domain/validation/habit_validation.dart';
import 'package:exhale/features/onboarding/presentation/onboarding_copy.dart';
import 'package:exhale/features/onboarding/presentation/onboarding_pace.dart';
import 'package:exhale/features/onboarding/presentation/providers/onboarding_form_provider.dart';
import 'package:exhale/features/plan/domain/entities/reduction_plan.dart';
import 'package:exhale/features/settings/domain/entities/day_window.dart';
import 'package:flutter/foundation.dart';

enum ChatAsk { name, habit, amount, price, perContainer, day }

enum Delivery { sent, read }

sealed class ChatItem {
  /// When the item landed in the chat.
  late final DateTime time;

  /// Whether the chat has played this item's entrance, so it plays once.
  bool entered = false;
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
  DateTime? _statusAt;

  /// When [delivery] last changed.
  DateTime get statusAt => _statusAt ?? time;

  String get text => _text();
}

/// An Exhale message that asks for an answer. Its controls show while
/// [open]; answering folds it back to its text.
class ChatQuestion extends ChatText {
  ChatQuestion(this.ask, String Function() text) : super.exhale(text);

  final ChatAsk ask;
  bool open = true;
}

/// The next 12 months as it is and with the plan, and what the plan keeps;
/// `planShare` is the plan's spend as a share of as it is.
typedef MoneyFigures = ({
  String perYear,
  String withPlan,
  String kept,
  double planShare,
});

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
    ChatHabit(HabitKind.alcohol, verb: 'drink', typical: 3, price: 7),
    ChatHabit(
      HabitKind.nicotinePouches,
      verb: 'reach for a pouch',
      typical: 8,
      price: 6,
      container: 'can',
      per: 20,
    ),
    ChatHabit(
      HabitKind.energyDrinks,
      verb: 'crack one open',
      typical: 2,
      price: 3,
    ),
    ChatHabit(
      HabitKind.caffeine,
      verb: 'reach for a coffee',
      typical: 3,
      price: 4,
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

/// The scripted onboarding conversation: what Exhale says, the questions it
/// asks, and the user's answers. Answers go to the form.
class OnboardingChat extends ChangeNotifier {
  OnboardingChat({
    required this.form,
    required this.controller,
    required this.reduceMotion,
    this.announce,
  });

  final OnboardingFormState Function() form;
  final OnboardingFormController Function() controller;
  final bool Function() reduceMotion;

  /// Reads a new Exhale message out to VoiceOver.
  final void Function(String message)? announce;

  static const String customUnit = 'time';

  final List<ChatItem> items = [];
  final List<Timer> _timers = [];
  bool typing = false;
  bool done = false;

  /// The line under the button, which reacts to the latest answer.
  String tagline = OnboardingCopy.taglineStart;
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

  void _add(ChatItem item, {DateTime? at}) {
    item.time = at ?? DateTime.now();
    items.add(item);
    if (item is ChatText && !item.mine) announce?.call(item.text);
    notifyListeners();
  }

  /// The open question for [ask]. Answering the newest card while an
  /// earlier one is reopened folds the reopened one as it is.
  ChatQuestion? _openFor(ChatAsk ask) {
    if (_reopened case final reopened? when reopened.ask != ask) {
      reopened.open = false;
      _reopened = null;
    }
    final open = question;
    return open?.ask == ask ? open : null;
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
  }

  void _mark(ChatText item, Delivery delivery, {DateTime? at}) {
    item
      ..delivery = delivery
      .._statusAt = at ?? DateTime.now();
    notifyListeners();
  }

  /// Between the last excuse landing and being read.
  static const int _readMs = 1600;

  /// Between an answer and Exhale's reply.
  static const int _replyMs = 1900;

  /// The three excuses arrive 600 ms apart, sent now and read together;
  /// then Exhale asks who it is talking to.
  void start() {
    final still = reduceMotion();
    const excuses = OnboardingCopy.excuses;
    final items = [for (final excuse in excuses) ChatText.mine(() => excuse)];
    for (final (i, item) in items.indexed) {
      _later(still ? 0 : 500 + i * 600, () {
        if (i == excuses.length - 1) {
          tagline = OnboardingCopy.taglineExcuses;
        }
        _add(item);
        if (still) _mark(item, Delivery.read);
      });
    }
    final read = 500 + (excuses.length - 1) * 600 + _readMs;
    if (!still) {
      _later(read, () {
        final at = DateTime.now();
        for (final item in items) {
          item
            ..delivery = Delivery.read
            .._statusAt = at;
        }
        notifyListeners();
      });
    }
    _says([
      ChatText.exhale(() => OnboardingCopy.heardThemAll),
      ChatQuestion(ChatAsk.name, () => OnboardingCopy.askWho),
    ], start: still ? 100 : read + 300);
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
  /// bubble, then runs [then] for Exhale's reply. A reopened question's
  /// bubble updates in place; only when [path] changes does the chat drop
  /// what followed and run [then] again.
  void _answer(
    ChatAsk ask,
    String Function() text,
    VoidCallback apply,
    VoidCallback then, {
    Object? Function()? path,
  }) {
    if (typing) return;
    final open = _openFor(ask);
    if (open == null) return;
    open.open = false;
    if (_answerOf(open) case final answered?) {
      _reopened = null;
      final before = path?.call();
      apply();
      tagline = _taglineAfter(ask);
      if (path != null && path() != before) {
        _truncateAfter(answered);
        then();
      }
      notifyListeners();
      return;
    }
    final still = reduceMotion();
    apply();
    tagline = _taglineAfter(ask);
    final sent = ChatText.mine(text, answers: open);
    _add(sent);
    if (still) _mark(sent, Delivery.read);
    _later(still ? 200 : _replyMs, () {
      if (!still) _mark(sent, Delivery.read);
      then();
    });
  }

  String _taglineAfter(ChatAsk ask) {
    final f = form();
    return switch (ask) {
      ChatAsk.name =>
        f.userName.isEmpty
            ? OnboardingCopy.taglineNameSkipped
            : OnboardingCopy.taglineName(f.userName),
      ChatAsk.habit => OnboardingCopy.taglineHabit(f.habitKind),
      ChatAsk.amount => OnboardingCopy.taglineAmount(f.startLimit, f.habitKind),
      ChatAsk.price => switch (f.priceCents) {
        final cents? => OnboardingCopy.taglinePrice(
          _price(cents),
          habit.container,
        ),
        null => OnboardingCopy.taglinePriceSkipped,
      },
      ChatAsk.perContainer => OnboardingCopy.taglineYear(
        _moneyFigures().perYear,
        f.habitKind,
      ),
      ChatAsk.day => OnboardingCopy.taglineDay,
    };
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
    final question = typing ? null : _openFor(ChatAsk.habit);
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
            ..setPricedPerUnit(perUnit: chosen.container == null)
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

  /// The plan's spend is its daily limits over the next 365 days, the
  /// plan the chat would make now: the pace the plan screen opens on, or
  /// the date chosen there. Figures are whole units, so the three agree.
  MoneyFigures _moneyFigures() {
    final f = form();
    final unit = f.unitPriceCents ?? 0;
    int whole(num cents) => (cents / 100).round() * 100;
    final asItIs = whole(unit * f.startLimit * 365);
    var units = f.startLimit * 365;
    final plan = f.quitPreset == null
        ? f.preview
        : ReductionPlan(
            startDay: f.startDay,
            startLimit: f.startLimit,
            quitDay: OnboardingPace.suggestedQuitDay(f.startDay, f.startLimit),
          );
    if (plan != null) {
      units = 0;
      for (var d = 0; d < 365; d++) {
        units += plan.limitOn(plan.startDay.addDays(d));
      }
    }
    final withPlan = whole(unit * units);
    String money(int cents) =>
        AppFormat.money(cents, symbol: f.currency, wholeUnits: true);
    return (
      perYear: money(asItIs),
      withPlan: money(withPlan),
      kept: money(asItIs - withPlan),
      planShare: asItIs == 0 ? 0 : withPlan / asItIs,
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
