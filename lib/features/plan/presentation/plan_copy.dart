import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/core/presentation/formatting/app_format.dart';
import 'package:exhale/features/habit/domain/entities/habit.dart';
import 'package:exhale/features/plan/domain/services/plan_report.dart';
import 'package:exhale/features/settings/domain/entities/day_window.dart';

/// Every string of the Plan details page.
abstract final class PlanCopy {
  static const title = 'You are here. Regrettably.';
  static const quitTitle = 'You made it. Regrettably.';
  static const lead =
      'Each ring is a stage, filled by what you used. Tap one for the damage.';
  static const loadFailure = "Couldn't load your plan.";

  static const wholePlan = 'The whole plan';
  static const moneySaved = 'Money saved';
  static const daysKept = 'Days kept';
  static const noMoney = '—';
  static const addPrice = 'Add a price ›';

  static const behindTitle = 'BEHIND YOU';
  static const youTitle = 'YOU, REGRETTABLY';
  static const aheadTitle = 'AHEAD OF YOU';
  static const thisPlan = 'This plan';
  static const now = 'NOW';

  static const saved = 'saved';
  static const toSave = 'to save';
  static const daysOver = 'Days over';
  static const average = 'Average';
  static const mostly = 'Mostly';
  static const pace = 'Pace';
  static const toAvoid = 'To avoid';
  static const starts = 'Starts';

  static const quitReached = 'You reached your quit date';

  /// Sessions
  static String unitsTitle(Habit habit) =>
      '${habit.units[0].toUpperCase()}${habit.units.substring(1)}';

  static String used(Habit habit) => '${unitsTitle(habit)} used';

  static String avoided(Habit habit) => '${unitsTitle(habit)} avoided';

  /// 28 sessions, 1 session
  static String amount(int count, Habit habit) =>
      '${AppFormat.count(count)} ${count == 1 ? habit.unit : habit.units}';

  static String withoutPlan(int units, Habit habit, String? money) =>
      'Without a plan: ${amount(units, habit)}'
      '${money == null ? '' : ' and $money'}. Nobody said it was cheap.';

  static String savedSide(String money) => '$money saved';

  static String toSaveSide(String money) => '$money to save';

  static String stageOf(int number, int count) => 'Stage $number of $count';

  static String stage(int number) => 'Stage $number';

  static String earlierPlan(LogicalDay until) =>
      'Earlier plan · until ${AppFormat.monthDay(until)}';

  /// Oct 8 – 14, or Oct 8 for a one-day stage.
  static String range(LogicalDay from, LogicalDay to) =>
      from == to ? AppFormat.monthDay(from) : AppFormat.dayRange(from, to);

  static String currentRange(StageReport report, LogicalDay today) =>
      '${range(report.stage.startDay, report.lastDay)} · day '
      '${report.stage.dayNumberOf(today)} of ${report.days}';

  static String ofToSave(String money) => 'of $money';

  static String usedOf(int used, int allowed) => '$used of $allowed used';

  static String overOf(int over, int days) => '$over of $days';

  static String perDay(double average) => '${average.toStringAsFixed(1)} a day';

  static String allowed(int allowed) => '$allowed allowed';

  /// One every 2 h. Null without a day window or a limit to pace.
  static String? paceEvery(DayWindow? window, int limit) {
    if (window == null || limit <= 0) return null;
    final gap = const Duration(minutes: 1) * (window.awakeMinutes / limit);
    return 'One every ${AppFormat.hoursMinutes(gap)}';
  }

  static String startsIn(int days) => days == 1 ? 'Tomorrow' : 'In $days days';

  static String finishTitle(String freeTitle, LogicalDay quitDay) =>
      '$freeTitle from ${AppFormat.monthDay(quitDay)}';

  static String daysToGo(int days) =>
      '$days ${days == 1 ? 'day' : 'days'} to go. Then this ring stays full.';

  static String note(StageNote note, {required int daysOver}) => switch (note) {
    StageNote.best => 'Your best so far. Try not to let it go to your head.',
    StageNote.easyOne => 'The easy one. It was meant to be.',
    StageNote.noneOver => 'Not one day over. Who are you?',
    StageNote.oneOver => 'One over for the whole stage. Bold.',
    StageNote.someOver => "$daysOver days over. It's over now too.",
    StageNote.last => 'The last one. Literally.',
    StageNote.oneFewer => 'One fewer. You have survived worse Mondays.',
    StageNote.halfway => "Halfway down. Don't tell your thumbs.",
    StageNote.written => 'Already written. Nothing to do yet.',
  };
}
