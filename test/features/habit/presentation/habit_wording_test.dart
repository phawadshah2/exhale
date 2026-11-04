import 'package:exhale/features/habit/domain/entities/habit.dart';
import 'package:exhale/features/habit/presentation/habit_wording.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('supportLine', () {
    const nicotine =
        'If this keeps being hard, a doctor, pharmacist or local '
        'quit service can help.';
    const other =
        'If this keeps being hard, a doctor or local support service can '
        'help.';

    test('nicotine habits mention a pharmacist and a quit service', () {
      expect(Habit.vaping.supportLine, nicotine);
      expect(Habit.smoking.supportLine, nicotine);
      expect(Habit.nicotinePouches.supportLine, nicotine);
    });

    test('every other habit gets the general line', () {
      for (final habit in [
        Habit.alcohol,
        Habit.caffeine,
        Habit.energyDrinks,
        Habit.junkFood,
        Habit.socialMedia,
        Habit.custom(name: 'Biting nails', unit: 'time'),
      ]) {
        expect(habit.supportLine, other, reason: habit.kind.name);
      }
    });
  });

  group('stopSuddenlyLine', () {
    test('is for alcohol only', () {
      expect(
        Habit.alcohol.stopSuddenlyLine,
        "If you drink heavily, don't stop suddenly without medical advice. "
        'It can be dangerous.',
      );
      expect(Habit.vaping.stopSuddenlyLine, isNull);
      expect(Habit.caffeine.stopSuddenlyLine, isNull);
      expect(
        Habit.custom(name: 'Wine', unit: 'glass').stopSuddenlyLine,
        isNull,
      );
    });
  });
}
