import 'package:exhale/features/settings/domain/entities/day_window.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  DayWindow window(int wake, int bed) =>
      DayWindow(wakeMinute: wake, bedMinute: bed);

  test('7:30 to 23:30 is 16 hours awake', () {
    expect(window(450, 1410).awakeMinutes, 960);
    expect(window(450, 1410).isValid, isTrue);
  });

  test('a bedtime after midnight wraps into the next day', () {
    expect(window(450, 60).awakeMinutes, 1050);
    expect(window(450, 60).isValid, isTrue);
  });

  test('23:00 to 2:00 is under 4 hours, so invalid', () {
    expect(window(1380, 120).awakeMinutes, 180);
    expect(window(1380, 120).isValid, isFalse);
  });

  test('exactly 4 hours is valid', () {
    expect(window(480, 720).isValid, isTrue);
  });

  test('bed equal to wake is no time awake', () {
    expect(window(450, 450).awakeMinutes, 0);
    expect(window(450, 450).isValid, isFalse);
  });

  test('the defaults are 7:30 and 23:30', () {
    expect(
      window(DayWindow.defaultWake, DayWindow.defaultBed).awakeMinutes,
      960,
    );
  });
}
