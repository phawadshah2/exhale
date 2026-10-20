import 'package:meta/meta.dart';

/// Built-in habits. [custom] takes its name and unit from the user.
enum HabitKind {
  vaping,
  smoking,
  nicotinePouches,
  alcohol,
  caffeine,
  energyDrinks,
  junkFood,
  socialMedia,
  custom,
}

/// What the user is cutting down, and the words the app uses for it.
@immutable
class Habit {
  const Habit({
    required this.kind,
    required this.name,
    required this.unit,
    required this.units,
    required this.shortUnits,
    required this.defaultDailyAmount,
    this.container,
    this.defaultUnitsPerContainer = 1,
    this.freeLabel,
    this.tracksCost = true,
  });

  /// A user-defined habit; plural is a plain "s" unless given.
  factory Habit.custom({required String name, required String unit}) {
    final singular = unit.trim().isEmpty ? 'time' : unit.trim().toLowerCase();
    final plural = singular.endsWith('s') ? singular : '${singular}s';
    return Habit(
      kind: HabitKind.custom,
      name: name.trim().isEmpty ? 'My habit' : name.trim(),
      unit: singular,
      units: plural,
      shortUnits: plural,
      defaultDailyAmount: 5,
    );
  }

  static const smoking = Habit(
    kind: HabitKind.smoking,
    name: 'Smoking',
    unit: 'cigarette',
    units: 'cigarettes',
    shortUnits: 'cigs',
    defaultDailyAmount: 9,
    container: 'pack',
    defaultUnitsPerContainer: 20,
    freeLabel: 'smoke-free',
  );

  static const vaping = Habit(
    kind: HabitKind.vaping,
    name: 'Vaping',
    unit: 'session',
    units: 'sessions',
    shortUnits: 'sessions',
    defaultDailyAmount: 12,
    container: 'pod',
    defaultUnitsPerContainer: 30,
    freeLabel: 'vape-free',
  );

  static const nicotinePouches = Habit(
    kind: HabitKind.nicotinePouches,
    name: 'Nicotine pouches',
    unit: 'pouch',
    units: 'pouches',
    shortUnits: 'pouches',
    defaultDailyAmount: 10,
    container: 'can',
    defaultUnitsPerContainer: 20,
    freeLabel: 'nicotine-free',
  );

  static const alcohol = Habit(
    kind: HabitKind.alcohol,
    name: 'Alcohol',
    unit: 'drink',
    units: 'drinks',
    shortUnits: 'drinks',
    defaultDailyAmount: 4,
    container: 'bottle',
    defaultUnitsPerContainer: 5,
    freeLabel: 'alcohol-free',
  );

  static const caffeine = Habit(
    kind: HabitKind.caffeine,
    name: 'Caffeine',
    unit: 'cup',
    units: 'cups',
    shortUnits: 'cups',
    defaultDailyAmount: 4,
    freeLabel: 'caffeine-free',
  );

  static const energyDrinks = Habit(
    kind: HabitKind.energyDrinks,
    name: 'Energy drinks',
    unit: 'can',
    units: 'cans',
    shortUnits: 'cans',
    defaultDailyAmount: 2,
    container: 'pack',
    defaultUnitsPerContainer: 4,
  );

  static const junkFood = Habit(
    kind: HabitKind.junkFood,
    name: 'Junk food',
    unit: 'snack',
    units: 'snacks',
    shortUnits: 'snacks',
    defaultDailyAmount: 3,
  );

  static const socialMedia = Habit(
    kind: HabitKind.socialMedia,
    name: 'Social media',
    unit: 'session',
    units: 'sessions',
    shortUnits: 'sessions',
    defaultDailyAmount: 20,
    tracksCost: false,
  );

  /// Presets in picker order (custom is offered separately).
  static const List<Habit> presets = [
    vaping,
    smoking,
    nicotinePouches,
    alcohol,
    caffeine,
    energyDrinks,
    junkFood,
    socialMedia,
  ];

  final HabitKind kind;
  final String name;

  /// What one log counts: "cigarette" / "cigarettes".
  final String unit;
  final String units;

  /// Compact unit next to a number stepper.
  final String shortUnits;
  final int defaultDailyAmount;

  /// What it is bought in ("pack"), or null when priced per [unit].
  final String? container;
  final int defaultUnitsPerContainer;

  /// "smoke-free"; null when no natural word exists.
  final String? freeLabel;

  /// False when money isn't part of the habit (social media).
  final bool tracksCost;

  bool get hasContainer => container != null;

  String unitsFor(int count) => count == 1 ? unit : units;

  @override
  bool operator ==(Object other) =>
      other is Habit &&
      other.kind == kind &&
      other.name == name &&
      other.unit == unit;

  @override
  int get hashCode => Object.hash(kind, name, unit);
}
