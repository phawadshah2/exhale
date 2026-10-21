// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $PlansTable extends Plans with TableInfo<$PlansTable, PlanRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlansTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _startDayMeta = const VerificationMeta(
    'startDay',
  );
  @override
  late final GeneratedColumn<String> startDay = GeneratedColumn<String>(
    'start_day',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _startLimitMeta = const VerificationMeta(
    'startLimit',
  );
  @override
  late final GeneratedColumn<int> startLimit = GeneratedColumn<int>(
    'start_limit',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _quitDayMeta = const VerificationMeta(
    'quitDay',
  );
  @override
  late final GeneratedColumn<String> quitDay = GeneratedColumn<String>(
    'quit_day',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    startDay,
    startLimit,
    quitDay,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'plans';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlanRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('start_day')) {
      context.handle(
        _startDayMeta,
        startDay.isAcceptableOrUnknown(data['start_day']!, _startDayMeta),
      );
    } else if (isInserting) {
      context.missing(_startDayMeta);
    }
    if (data.containsKey('start_limit')) {
      context.handle(
        _startLimitMeta,
        startLimit.isAcceptableOrUnknown(data['start_limit']!, _startLimitMeta),
      );
    } else if (isInserting) {
      context.missing(_startLimitMeta);
    }
    if (data.containsKey('quit_day')) {
      context.handle(
        _quitDayMeta,
        quitDay.isAcceptableOrUnknown(data['quit_day']!, _quitDayMeta),
      );
    } else if (isInserting) {
      context.missing(_quitDayMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PlanRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlanRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      startDay: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}start_day'],
      )!,
      startLimit: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_limit'],
      )!,
      quitDay: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}quit_day'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $PlansTable createAlias(String alias) {
    return $PlansTable(attachedDatabase, alias);
  }
}

class PlanRow extends DataClass implements Insertable<PlanRow> {
  final int id;

  /// LogicalDay in yyyy-mm-dd form.
  final String startDay;
  final int startLimit;

  /// LogicalDay in yyyy-mm-dd form; the limit is 0 from this day.
  final String quitDay;
  final DateTime createdAt;
  const PlanRow({
    required this.id,
    required this.startDay,
    required this.startLimit,
    required this.quitDay,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['start_day'] = Variable<String>(startDay);
    map['start_limit'] = Variable<int>(startLimit);
    map['quit_day'] = Variable<String>(quitDay);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  PlansCompanion toCompanion(bool nullToAbsent) {
    return PlansCompanion(
      id: Value(id),
      startDay: Value(startDay),
      startLimit: Value(startLimit),
      quitDay: Value(quitDay),
      createdAt: Value(createdAt),
    );
  }

  factory PlanRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlanRow(
      id: serializer.fromJson<int>(json['id']),
      startDay: serializer.fromJson<String>(json['startDay']),
      startLimit: serializer.fromJson<int>(json['startLimit']),
      quitDay: serializer.fromJson<String>(json['quitDay']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'startDay': serializer.toJson<String>(startDay),
      'startLimit': serializer.toJson<int>(startLimit),
      'quitDay': serializer.toJson<String>(quitDay),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  PlanRow copyWith({
    int? id,
    String? startDay,
    int? startLimit,
    String? quitDay,
    DateTime? createdAt,
  }) => PlanRow(
    id: id ?? this.id,
    startDay: startDay ?? this.startDay,
    startLimit: startLimit ?? this.startLimit,
    quitDay: quitDay ?? this.quitDay,
    createdAt: createdAt ?? this.createdAt,
  );
  PlanRow copyWithCompanion(PlansCompanion data) {
    return PlanRow(
      id: data.id.present ? data.id.value : this.id,
      startDay: data.startDay.present ? data.startDay.value : this.startDay,
      startLimit: data.startLimit.present
          ? data.startLimit.value
          : this.startLimit,
      quitDay: data.quitDay.present ? data.quitDay.value : this.quitDay,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlanRow(')
          ..write('id: $id, ')
          ..write('startDay: $startDay, ')
          ..write('startLimit: $startLimit, ')
          ..write('quitDay: $quitDay, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, startDay, startLimit, quitDay, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlanRow &&
          other.id == this.id &&
          other.startDay == this.startDay &&
          other.startLimit == this.startLimit &&
          other.quitDay == this.quitDay &&
          other.createdAt == this.createdAt);
}

class PlansCompanion extends UpdateCompanion<PlanRow> {
  final Value<int> id;
  final Value<String> startDay;
  final Value<int> startLimit;
  final Value<String> quitDay;
  final Value<DateTime> createdAt;
  const PlansCompanion({
    this.id = const Value.absent(),
    this.startDay = const Value.absent(),
    this.startLimit = const Value.absent(),
    this.quitDay = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  PlansCompanion.insert({
    this.id = const Value.absent(),
    required String startDay,
    required int startLimit,
    required String quitDay,
    this.createdAt = const Value.absent(),
  }) : startDay = Value(startDay),
       startLimit = Value(startLimit),
       quitDay = Value(quitDay);
  static Insertable<PlanRow> custom({
    Expression<int>? id,
    Expression<String>? startDay,
    Expression<int>? startLimit,
    Expression<String>? quitDay,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (startDay != null) 'start_day': startDay,
      if (startLimit != null) 'start_limit': startLimit,
      if (quitDay != null) 'quit_day': quitDay,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  PlansCompanion copyWith({
    Value<int>? id,
    Value<String>? startDay,
    Value<int>? startLimit,
    Value<String>? quitDay,
    Value<DateTime>? createdAt,
  }) {
    return PlansCompanion(
      id: id ?? this.id,
      startDay: startDay ?? this.startDay,
      startLimit: startLimit ?? this.startLimit,
      quitDay: quitDay ?? this.quitDay,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (startDay.present) {
      map['start_day'] = Variable<String>(startDay.value);
    }
    if (startLimit.present) {
      map['start_limit'] = Variable<int>(startLimit.value);
    }
    if (quitDay.present) {
      map['quit_day'] = Variable<String>(quitDay.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlansCompanion(')
          ..write('id: $id, ')
          ..write('startDay: $startDay, ')
          ..write('startLimit: $startLimit, ')
          ..write('quitDay: $quitDay, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $HabitLogsTable extends HabitLogs
    with TableInfo<$HabitLogsTable, HabitLogRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HabitLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _loggedAtMeta = const VerificationMeta(
    'loggedAt',
  );
  @override
  late final GeneratedColumn<DateTime> loggedAt = GeneratedColumn<DateTime>(
    'logged_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _habitKindMeta = const VerificationMeta(
    'habitKind',
  );
  @override
  late final GeneratedColumn<String> habitKind = GeneratedColumn<String>(
    'habit_kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('smoking'),
  );
  static const VerificationMeta _triggerMeta = const VerificationMeta(
    'trigger',
  );
  @override
  late final GeneratedColumn<String> trigger = GeneratedColumn<String>(
    'trigger',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    loggedAt,
    habitKind,
    trigger,
    note,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'habit_logs';
  @override
  VerificationContext validateIntegrity(
    Insertable<HabitLogRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('logged_at')) {
      context.handle(
        _loggedAtMeta,
        loggedAt.isAcceptableOrUnknown(data['logged_at']!, _loggedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_loggedAtMeta);
    }
    if (data.containsKey('habit_kind')) {
      context.handle(
        _habitKindMeta,
        habitKind.isAcceptableOrUnknown(data['habit_kind']!, _habitKindMeta),
      );
    }
    if (data.containsKey('trigger')) {
      context.handle(
        _triggerMeta,
        trigger.isAcceptableOrUnknown(data['trigger']!, _triggerMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  HabitLogRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HabitLogRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      loggedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}logged_at'],
      )!,
      habitKind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}habit_kind'],
      )!,
      trigger: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}trigger'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $HabitLogsTable createAlias(String alias) {
    return $HabitLogsTable(attachedDatabase, alias);
  }
}

class HabitLogRow extends DataClass implements Insertable<HabitLogRow> {
  final int id;
  final DateTime loggedAt;

  /// HabitKind.name of the habit when it was logged; rows from before v7
  /// were smoking.
  final String habitKind;

  /// Trigger.name, or null when skipped.
  final String? trigger;
  final String? note;
  final DateTime createdAt;
  const HabitLogRow({
    required this.id,
    required this.loggedAt,
    required this.habitKind,
    this.trigger,
    this.note,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['logged_at'] = Variable<DateTime>(loggedAt);
    map['habit_kind'] = Variable<String>(habitKind);
    if (!nullToAbsent || trigger != null) {
      map['trigger'] = Variable<String>(trigger);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  HabitLogsCompanion toCompanion(bool nullToAbsent) {
    return HabitLogsCompanion(
      id: Value(id),
      loggedAt: Value(loggedAt),
      habitKind: Value(habitKind),
      trigger: trigger == null && nullToAbsent
          ? const Value.absent()
          : Value(trigger),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      createdAt: Value(createdAt),
    );
  }

  factory HabitLogRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HabitLogRow(
      id: serializer.fromJson<int>(json['id']),
      loggedAt: serializer.fromJson<DateTime>(json['loggedAt']),
      habitKind: serializer.fromJson<String>(json['habitKind']),
      trigger: serializer.fromJson<String?>(json['trigger']),
      note: serializer.fromJson<String?>(json['note']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'loggedAt': serializer.toJson<DateTime>(loggedAt),
      'habitKind': serializer.toJson<String>(habitKind),
      'trigger': serializer.toJson<String?>(trigger),
      'note': serializer.toJson<String?>(note),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  HabitLogRow copyWith({
    int? id,
    DateTime? loggedAt,
    String? habitKind,
    Value<String?> trigger = const Value.absent(),
    Value<String?> note = const Value.absent(),
    DateTime? createdAt,
  }) => HabitLogRow(
    id: id ?? this.id,
    loggedAt: loggedAt ?? this.loggedAt,
    habitKind: habitKind ?? this.habitKind,
    trigger: trigger.present ? trigger.value : this.trigger,
    note: note.present ? note.value : this.note,
    createdAt: createdAt ?? this.createdAt,
  );
  HabitLogRow copyWithCompanion(HabitLogsCompanion data) {
    return HabitLogRow(
      id: data.id.present ? data.id.value : this.id,
      loggedAt: data.loggedAt.present ? data.loggedAt.value : this.loggedAt,
      habitKind: data.habitKind.present ? data.habitKind.value : this.habitKind,
      trigger: data.trigger.present ? data.trigger.value : this.trigger,
      note: data.note.present ? data.note.value : this.note,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HabitLogRow(')
          ..write('id: $id, ')
          ..write('loggedAt: $loggedAt, ')
          ..write('habitKind: $habitKind, ')
          ..write('trigger: $trigger, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, loggedAt, habitKind, trigger, note, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HabitLogRow &&
          other.id == this.id &&
          other.loggedAt == this.loggedAt &&
          other.habitKind == this.habitKind &&
          other.trigger == this.trigger &&
          other.note == this.note &&
          other.createdAt == this.createdAt);
}

class HabitLogsCompanion extends UpdateCompanion<HabitLogRow> {
  final Value<int> id;
  final Value<DateTime> loggedAt;
  final Value<String> habitKind;
  final Value<String?> trigger;
  final Value<String?> note;
  final Value<DateTime> createdAt;
  const HabitLogsCompanion({
    this.id = const Value.absent(),
    this.loggedAt = const Value.absent(),
    this.habitKind = const Value.absent(),
    this.trigger = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  HabitLogsCompanion.insert({
    this.id = const Value.absent(),
    required DateTime loggedAt,
    this.habitKind = const Value.absent(),
    this.trigger = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : loggedAt = Value(loggedAt);
  static Insertable<HabitLogRow> custom({
    Expression<int>? id,
    Expression<DateTime>? loggedAt,
    Expression<String>? habitKind,
    Expression<String>? trigger,
    Expression<String>? note,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (loggedAt != null) 'logged_at': loggedAt,
      if (habitKind != null) 'habit_kind': habitKind,
      if (trigger != null) 'trigger': trigger,
      if (note != null) 'note': note,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  HabitLogsCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? loggedAt,
    Value<String>? habitKind,
    Value<String?>? trigger,
    Value<String?>? note,
    Value<DateTime>? createdAt,
  }) {
    return HabitLogsCompanion(
      id: id ?? this.id,
      loggedAt: loggedAt ?? this.loggedAt,
      habitKind: habitKind ?? this.habitKind,
      trigger: trigger ?? this.trigger,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (loggedAt.present) {
      map['logged_at'] = Variable<DateTime>(loggedAt.value);
    }
    if (habitKind.present) {
      map['habit_kind'] = Variable<String>(habitKind.value);
    }
    if (trigger.present) {
      map['trigger'] = Variable<String>(trigger.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HabitLogsCompanion(')
          ..write('id: $id, ')
          ..write('loggedAt: $loggedAt, ')
          ..write('habitKind: $habitKind, ')
          ..write('trigger: $trigger, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $SettingsTable extends Settings
    with TableInfo<$SettingsTable, SettingsRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _userNameMeta = const VerificationMeta(
    'userName',
  );
  @override
  late final GeneratedColumn<String> userName = GeneratedColumn<String>(
    'user_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dayResetHourMeta = const VerificationMeta(
    'dayResetHour',
  );
  @override
  late final GeneratedColumn<int> dayResetHour = GeneratedColumn<int>(
    'day_reset_hour',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(4),
  );
  static const VerificationMeta _themePreferenceMeta = const VerificationMeta(
    'themePreference',
  );
  @override
  late final GeneratedColumn<String> themePreference = GeneratedColumn<String>(
    'theme_preference',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('system'),
  );
  static const VerificationMeta _accentIndexMeta = const VerificationMeta(
    'accentIndex',
  );
  @override
  late final GeneratedColumn<int> accentIndex = GeneratedColumn<int>(
    'accent_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _appIconMeta = const VerificationMeta(
    'appIcon',
  );
  @override
  late final GeneratedColumn<String> appIcon = GeneratedColumn<String>(
    'app_icon',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('breath'),
  );
  static const VerificationMeta _priceCentsMeta = const VerificationMeta(
    'priceCents',
  );
  @override
  late final GeneratedColumn<int> priceCents = GeneratedColumn<int>(
    'price_cents',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _unitsPerContainerMeta = const VerificationMeta(
    'unitsPerContainer',
  );
  @override
  late final GeneratedColumn<int> unitsPerContainer = GeneratedColumn<int>(
    'units_per_container',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(20),
  );
  static const VerificationMeta _askForTriggerMeta = const VerificationMeta(
    'askForTrigger',
  );
  @override
  late final GeneratedColumn<bool> askForTrigger = GeneratedColumn<bool>(
    'ask_for_trigger',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("ask_for_trigger" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _triggerPromptIntroSeenMeta =
      const VerificationMeta('triggerPromptIntroSeen');
  @override
  late final GeneratedColumn<bool> triggerPromptIntroSeen =
      GeneratedColumn<bool>(
        'trigger_prompt_intro_seen',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("trigger_prompt_intro_seen" IN (0, 1))',
        ),
        defaultValue: const Constant(false),
      );
  static const VerificationMeta _habitKindMeta = const VerificationMeta(
    'habitKind',
  );
  @override
  late final GeneratedColumn<String> habitKind = GeneratedColumn<String>(
    'habit_kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('smoking'),
  );
  static const VerificationMeta _customHabitNameMeta = const VerificationMeta(
    'customHabitName',
  );
  @override
  late final GeneratedColumn<String> customHabitName = GeneratedColumn<String>(
    'custom_habit_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _customHabitUnitMeta = const VerificationMeta(
    'customHabitUnit',
  );
  @override
  late final GeneratedColumn<String> customHabitUnit = GeneratedColumn<String>(
    'custom_habit_unit',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  @override
  late final GeneratedColumn<String> reason = GeneratedColumn<String>(
    'reason',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _currencySymbolMeta = const VerificationMeta(
    'currencySymbol',
  );
  @override
  late final GeneratedColumn<String> currencySymbol = GeneratedColumn<String>(
    'currency_symbol',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(r'$'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userName,
    dayResetHour,
    themePreference,
    accentIndex,
    appIcon,
    priceCents,
    unitsPerContainer,
    askForTrigger,
    triggerPromptIntroSeen,
    habitKind,
    customHabitName,
    customHabitUnit,
    reason,
    currencySymbol,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<SettingsRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('user_name')) {
      context.handle(
        _userNameMeta,
        userName.isAcceptableOrUnknown(data['user_name']!, _userNameMeta),
      );
    }
    if (data.containsKey('day_reset_hour')) {
      context.handle(
        _dayResetHourMeta,
        dayResetHour.isAcceptableOrUnknown(
          data['day_reset_hour']!,
          _dayResetHourMeta,
        ),
      );
    }
    if (data.containsKey('theme_preference')) {
      context.handle(
        _themePreferenceMeta,
        themePreference.isAcceptableOrUnknown(
          data['theme_preference']!,
          _themePreferenceMeta,
        ),
      );
    }
    if (data.containsKey('accent_index')) {
      context.handle(
        _accentIndexMeta,
        accentIndex.isAcceptableOrUnknown(
          data['accent_index']!,
          _accentIndexMeta,
        ),
      );
    }
    if (data.containsKey('app_icon')) {
      context.handle(
        _appIconMeta,
        appIcon.isAcceptableOrUnknown(data['app_icon']!, _appIconMeta),
      );
    }
    if (data.containsKey('price_cents')) {
      context.handle(
        _priceCentsMeta,
        priceCents.isAcceptableOrUnknown(data['price_cents']!, _priceCentsMeta),
      );
    }
    if (data.containsKey('units_per_container')) {
      context.handle(
        _unitsPerContainerMeta,
        unitsPerContainer.isAcceptableOrUnknown(
          data['units_per_container']!,
          _unitsPerContainerMeta,
        ),
      );
    }
    if (data.containsKey('ask_for_trigger')) {
      context.handle(
        _askForTriggerMeta,
        askForTrigger.isAcceptableOrUnknown(
          data['ask_for_trigger']!,
          _askForTriggerMeta,
        ),
      );
    }
    if (data.containsKey('trigger_prompt_intro_seen')) {
      context.handle(
        _triggerPromptIntroSeenMeta,
        triggerPromptIntroSeen.isAcceptableOrUnknown(
          data['trigger_prompt_intro_seen']!,
          _triggerPromptIntroSeenMeta,
        ),
      );
    }
    if (data.containsKey('habit_kind')) {
      context.handle(
        _habitKindMeta,
        habitKind.isAcceptableOrUnknown(data['habit_kind']!, _habitKindMeta),
      );
    }
    if (data.containsKey('custom_habit_name')) {
      context.handle(
        _customHabitNameMeta,
        customHabitName.isAcceptableOrUnknown(
          data['custom_habit_name']!,
          _customHabitNameMeta,
        ),
      );
    }
    if (data.containsKey('custom_habit_unit')) {
      context.handle(
        _customHabitUnitMeta,
        customHabitUnit.isAcceptableOrUnknown(
          data['custom_habit_unit']!,
          _customHabitUnitMeta,
        ),
      );
    }
    if (data.containsKey('reason')) {
      context.handle(
        _reasonMeta,
        reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta),
      );
    }
    if (data.containsKey('currency_symbol')) {
      context.handle(
        _currencySymbolMeta,
        currencySymbol.isAcceptableOrUnknown(
          data['currency_symbol']!,
          _currencySymbolMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SettingsRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SettingsRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      userName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_name'],
      ),
      dayResetHour: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}day_reset_hour'],
      )!,
      themePreference: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}theme_preference'],
      )!,
      accentIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}accent_index'],
      )!,
      appIcon: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}app_icon'],
      )!,
      priceCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}price_cents'],
      ),
      unitsPerContainer: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}units_per_container'],
      )!,
      askForTrigger: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}ask_for_trigger'],
      )!,
      triggerPromptIntroSeen: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}trigger_prompt_intro_seen'],
      )!,
      habitKind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}habit_kind'],
      )!,
      customHabitName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}custom_habit_name'],
      ),
      customHabitUnit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}custom_habit_unit'],
      ),
      reason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reason'],
      ),
      currencySymbol: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency_symbol'],
      )!,
    );
  }

  @override
  $SettingsTable createAlias(String alias) {
    return $SettingsTable(attachedDatabase, alias);
  }
}

class SettingsRow extends DataClass implements Insertable<SettingsRow> {
  final int id;
  final String? userName;
  final int dayResetHour;
  final String themePreference;
  final int accentIndex;
  final String appIcon;

  /// Per container when the habit has one, else per unit.
  final int? priceCents;
  final int unitsPerContainer;
  final bool askForTrigger;
  final bool triggerPromptIntroSeen;

  /// HabitKind.name; rows from before v6 were smoking.
  final String habitKind;
  final String? customHabitName;
  final String? customHabitUnit;
  final String? reason;
  final String currencySymbol;
  const SettingsRow({
    required this.id,
    this.userName,
    required this.dayResetHour,
    required this.themePreference,
    required this.accentIndex,
    required this.appIcon,
    this.priceCents,
    required this.unitsPerContainer,
    required this.askForTrigger,
    required this.triggerPromptIntroSeen,
    required this.habitKind,
    this.customHabitName,
    this.customHabitUnit,
    this.reason,
    required this.currencySymbol,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || userName != null) {
      map['user_name'] = Variable<String>(userName);
    }
    map['day_reset_hour'] = Variable<int>(dayResetHour);
    map['theme_preference'] = Variable<String>(themePreference);
    map['accent_index'] = Variable<int>(accentIndex);
    map['app_icon'] = Variable<String>(appIcon);
    if (!nullToAbsent || priceCents != null) {
      map['price_cents'] = Variable<int>(priceCents);
    }
    map['units_per_container'] = Variable<int>(unitsPerContainer);
    map['ask_for_trigger'] = Variable<bool>(askForTrigger);
    map['trigger_prompt_intro_seen'] = Variable<bool>(triggerPromptIntroSeen);
    map['habit_kind'] = Variable<String>(habitKind);
    if (!nullToAbsent || customHabitName != null) {
      map['custom_habit_name'] = Variable<String>(customHabitName);
    }
    if (!nullToAbsent || customHabitUnit != null) {
      map['custom_habit_unit'] = Variable<String>(customHabitUnit);
    }
    if (!nullToAbsent || reason != null) {
      map['reason'] = Variable<String>(reason);
    }
    map['currency_symbol'] = Variable<String>(currencySymbol);
    return map;
  }

  SettingsCompanion toCompanion(bool nullToAbsent) {
    return SettingsCompanion(
      id: Value(id),
      userName: userName == null && nullToAbsent
          ? const Value.absent()
          : Value(userName),
      dayResetHour: Value(dayResetHour),
      themePreference: Value(themePreference),
      accentIndex: Value(accentIndex),
      appIcon: Value(appIcon),
      priceCents: priceCents == null && nullToAbsent
          ? const Value.absent()
          : Value(priceCents),
      unitsPerContainer: Value(unitsPerContainer),
      askForTrigger: Value(askForTrigger),
      triggerPromptIntroSeen: Value(triggerPromptIntroSeen),
      habitKind: Value(habitKind),
      customHabitName: customHabitName == null && nullToAbsent
          ? const Value.absent()
          : Value(customHabitName),
      customHabitUnit: customHabitUnit == null && nullToAbsent
          ? const Value.absent()
          : Value(customHabitUnit),
      reason: reason == null && nullToAbsent
          ? const Value.absent()
          : Value(reason),
      currencySymbol: Value(currencySymbol),
    );
  }

  factory SettingsRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SettingsRow(
      id: serializer.fromJson<int>(json['id']),
      userName: serializer.fromJson<String?>(json['userName']),
      dayResetHour: serializer.fromJson<int>(json['dayResetHour']),
      themePreference: serializer.fromJson<String>(json['themePreference']),
      accentIndex: serializer.fromJson<int>(json['accentIndex']),
      appIcon: serializer.fromJson<String>(json['appIcon']),
      priceCents: serializer.fromJson<int?>(json['priceCents']),
      unitsPerContainer: serializer.fromJson<int>(json['unitsPerContainer']),
      askForTrigger: serializer.fromJson<bool>(json['askForTrigger']),
      triggerPromptIntroSeen: serializer.fromJson<bool>(
        json['triggerPromptIntroSeen'],
      ),
      habitKind: serializer.fromJson<String>(json['habitKind']),
      customHabitName: serializer.fromJson<String?>(json['customHabitName']),
      customHabitUnit: serializer.fromJson<String?>(json['customHabitUnit']),
      reason: serializer.fromJson<String?>(json['reason']),
      currencySymbol: serializer.fromJson<String>(json['currencySymbol']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'userName': serializer.toJson<String?>(userName),
      'dayResetHour': serializer.toJson<int>(dayResetHour),
      'themePreference': serializer.toJson<String>(themePreference),
      'accentIndex': serializer.toJson<int>(accentIndex),
      'appIcon': serializer.toJson<String>(appIcon),
      'priceCents': serializer.toJson<int?>(priceCents),
      'unitsPerContainer': serializer.toJson<int>(unitsPerContainer),
      'askForTrigger': serializer.toJson<bool>(askForTrigger),
      'triggerPromptIntroSeen': serializer.toJson<bool>(triggerPromptIntroSeen),
      'habitKind': serializer.toJson<String>(habitKind),
      'customHabitName': serializer.toJson<String?>(customHabitName),
      'customHabitUnit': serializer.toJson<String?>(customHabitUnit),
      'reason': serializer.toJson<String?>(reason),
      'currencySymbol': serializer.toJson<String>(currencySymbol),
    };
  }

  SettingsRow copyWith({
    int? id,
    Value<String?> userName = const Value.absent(),
    int? dayResetHour,
    String? themePreference,
    int? accentIndex,
    String? appIcon,
    Value<int?> priceCents = const Value.absent(),
    int? unitsPerContainer,
    bool? askForTrigger,
    bool? triggerPromptIntroSeen,
    String? habitKind,
    Value<String?> customHabitName = const Value.absent(),
    Value<String?> customHabitUnit = const Value.absent(),
    Value<String?> reason = const Value.absent(),
    String? currencySymbol,
  }) => SettingsRow(
    id: id ?? this.id,
    userName: userName.present ? userName.value : this.userName,
    dayResetHour: dayResetHour ?? this.dayResetHour,
    themePreference: themePreference ?? this.themePreference,
    accentIndex: accentIndex ?? this.accentIndex,
    appIcon: appIcon ?? this.appIcon,
    priceCents: priceCents.present ? priceCents.value : this.priceCents,
    unitsPerContainer: unitsPerContainer ?? this.unitsPerContainer,
    askForTrigger: askForTrigger ?? this.askForTrigger,
    triggerPromptIntroSeen:
        triggerPromptIntroSeen ?? this.triggerPromptIntroSeen,
    habitKind: habitKind ?? this.habitKind,
    customHabitName: customHabitName.present
        ? customHabitName.value
        : this.customHabitName,
    customHabitUnit: customHabitUnit.present
        ? customHabitUnit.value
        : this.customHabitUnit,
    reason: reason.present ? reason.value : this.reason,
    currencySymbol: currencySymbol ?? this.currencySymbol,
  );
  SettingsRow copyWithCompanion(SettingsCompanion data) {
    return SettingsRow(
      id: data.id.present ? data.id.value : this.id,
      userName: data.userName.present ? data.userName.value : this.userName,
      dayResetHour: data.dayResetHour.present
          ? data.dayResetHour.value
          : this.dayResetHour,
      themePreference: data.themePreference.present
          ? data.themePreference.value
          : this.themePreference,
      accentIndex: data.accentIndex.present
          ? data.accentIndex.value
          : this.accentIndex,
      appIcon: data.appIcon.present ? data.appIcon.value : this.appIcon,
      priceCents: data.priceCents.present
          ? data.priceCents.value
          : this.priceCents,
      unitsPerContainer: data.unitsPerContainer.present
          ? data.unitsPerContainer.value
          : this.unitsPerContainer,
      askForTrigger: data.askForTrigger.present
          ? data.askForTrigger.value
          : this.askForTrigger,
      triggerPromptIntroSeen: data.triggerPromptIntroSeen.present
          ? data.triggerPromptIntroSeen.value
          : this.triggerPromptIntroSeen,
      habitKind: data.habitKind.present ? data.habitKind.value : this.habitKind,
      customHabitName: data.customHabitName.present
          ? data.customHabitName.value
          : this.customHabitName,
      customHabitUnit: data.customHabitUnit.present
          ? data.customHabitUnit.value
          : this.customHabitUnit,
      reason: data.reason.present ? data.reason.value : this.reason,
      currencySymbol: data.currencySymbol.present
          ? data.currencySymbol.value
          : this.currencySymbol,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SettingsRow(')
          ..write('id: $id, ')
          ..write('userName: $userName, ')
          ..write('dayResetHour: $dayResetHour, ')
          ..write('themePreference: $themePreference, ')
          ..write('accentIndex: $accentIndex, ')
          ..write('appIcon: $appIcon, ')
          ..write('priceCents: $priceCents, ')
          ..write('unitsPerContainer: $unitsPerContainer, ')
          ..write('askForTrigger: $askForTrigger, ')
          ..write('triggerPromptIntroSeen: $triggerPromptIntroSeen, ')
          ..write('habitKind: $habitKind, ')
          ..write('customHabitName: $customHabitName, ')
          ..write('customHabitUnit: $customHabitUnit, ')
          ..write('reason: $reason, ')
          ..write('currencySymbol: $currencySymbol')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userName,
    dayResetHour,
    themePreference,
    accentIndex,
    appIcon,
    priceCents,
    unitsPerContainer,
    askForTrigger,
    triggerPromptIntroSeen,
    habitKind,
    customHabitName,
    customHabitUnit,
    reason,
    currencySymbol,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SettingsRow &&
          other.id == this.id &&
          other.userName == this.userName &&
          other.dayResetHour == this.dayResetHour &&
          other.themePreference == this.themePreference &&
          other.accentIndex == this.accentIndex &&
          other.appIcon == this.appIcon &&
          other.priceCents == this.priceCents &&
          other.unitsPerContainer == this.unitsPerContainer &&
          other.askForTrigger == this.askForTrigger &&
          other.triggerPromptIntroSeen == this.triggerPromptIntroSeen &&
          other.habitKind == this.habitKind &&
          other.customHabitName == this.customHabitName &&
          other.customHabitUnit == this.customHabitUnit &&
          other.reason == this.reason &&
          other.currencySymbol == this.currencySymbol);
}

class SettingsCompanion extends UpdateCompanion<SettingsRow> {
  final Value<int> id;
  final Value<String?> userName;
  final Value<int> dayResetHour;
  final Value<String> themePreference;
  final Value<int> accentIndex;
  final Value<String> appIcon;
  final Value<int?> priceCents;
  final Value<int> unitsPerContainer;
  final Value<bool> askForTrigger;
  final Value<bool> triggerPromptIntroSeen;
  final Value<String> habitKind;
  final Value<String?> customHabitName;
  final Value<String?> customHabitUnit;
  final Value<String?> reason;
  final Value<String> currencySymbol;
  const SettingsCompanion({
    this.id = const Value.absent(),
    this.userName = const Value.absent(),
    this.dayResetHour = const Value.absent(),
    this.themePreference = const Value.absent(),
    this.accentIndex = const Value.absent(),
    this.appIcon = const Value.absent(),
    this.priceCents = const Value.absent(),
    this.unitsPerContainer = const Value.absent(),
    this.askForTrigger = const Value.absent(),
    this.triggerPromptIntroSeen = const Value.absent(),
    this.habitKind = const Value.absent(),
    this.customHabitName = const Value.absent(),
    this.customHabitUnit = const Value.absent(),
    this.reason = const Value.absent(),
    this.currencySymbol = const Value.absent(),
  });
  SettingsCompanion.insert({
    this.id = const Value.absent(),
    this.userName = const Value.absent(),
    this.dayResetHour = const Value.absent(),
    this.themePreference = const Value.absent(),
    this.accentIndex = const Value.absent(),
    this.appIcon = const Value.absent(),
    this.priceCents = const Value.absent(),
    this.unitsPerContainer = const Value.absent(),
    this.askForTrigger = const Value.absent(),
    this.triggerPromptIntroSeen = const Value.absent(),
    this.habitKind = const Value.absent(),
    this.customHabitName = const Value.absent(),
    this.customHabitUnit = const Value.absent(),
    this.reason = const Value.absent(),
    this.currencySymbol = const Value.absent(),
  });
  static Insertable<SettingsRow> custom({
    Expression<int>? id,
    Expression<String>? userName,
    Expression<int>? dayResetHour,
    Expression<String>? themePreference,
    Expression<int>? accentIndex,
    Expression<String>? appIcon,
    Expression<int>? priceCents,
    Expression<int>? unitsPerContainer,
    Expression<bool>? askForTrigger,
    Expression<bool>? triggerPromptIntroSeen,
    Expression<String>? habitKind,
    Expression<String>? customHabitName,
    Expression<String>? customHabitUnit,
    Expression<String>? reason,
    Expression<String>? currencySymbol,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userName != null) 'user_name': userName,
      if (dayResetHour != null) 'day_reset_hour': dayResetHour,
      if (themePreference != null) 'theme_preference': themePreference,
      if (accentIndex != null) 'accent_index': accentIndex,
      if (appIcon != null) 'app_icon': appIcon,
      if (priceCents != null) 'price_cents': priceCents,
      if (unitsPerContainer != null) 'units_per_container': unitsPerContainer,
      if (askForTrigger != null) 'ask_for_trigger': askForTrigger,
      if (triggerPromptIntroSeen != null)
        'trigger_prompt_intro_seen': triggerPromptIntroSeen,
      if (habitKind != null) 'habit_kind': habitKind,
      if (customHabitName != null) 'custom_habit_name': customHabitName,
      if (customHabitUnit != null) 'custom_habit_unit': customHabitUnit,
      if (reason != null) 'reason': reason,
      if (currencySymbol != null) 'currency_symbol': currencySymbol,
    });
  }

  SettingsCompanion copyWith({
    Value<int>? id,
    Value<String?>? userName,
    Value<int>? dayResetHour,
    Value<String>? themePreference,
    Value<int>? accentIndex,
    Value<String>? appIcon,
    Value<int?>? priceCents,
    Value<int>? unitsPerContainer,
    Value<bool>? askForTrigger,
    Value<bool>? triggerPromptIntroSeen,
    Value<String>? habitKind,
    Value<String?>? customHabitName,
    Value<String?>? customHabitUnit,
    Value<String?>? reason,
    Value<String>? currencySymbol,
  }) {
    return SettingsCompanion(
      id: id ?? this.id,
      userName: userName ?? this.userName,
      dayResetHour: dayResetHour ?? this.dayResetHour,
      themePreference: themePreference ?? this.themePreference,
      accentIndex: accentIndex ?? this.accentIndex,
      appIcon: appIcon ?? this.appIcon,
      priceCents: priceCents ?? this.priceCents,
      unitsPerContainer: unitsPerContainer ?? this.unitsPerContainer,
      askForTrigger: askForTrigger ?? this.askForTrigger,
      triggerPromptIntroSeen:
          triggerPromptIntroSeen ?? this.triggerPromptIntroSeen,
      habitKind: habitKind ?? this.habitKind,
      customHabitName: customHabitName ?? this.customHabitName,
      customHabitUnit: customHabitUnit ?? this.customHabitUnit,
      reason: reason ?? this.reason,
      currencySymbol: currencySymbol ?? this.currencySymbol,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (userName.present) {
      map['user_name'] = Variable<String>(userName.value);
    }
    if (dayResetHour.present) {
      map['day_reset_hour'] = Variable<int>(dayResetHour.value);
    }
    if (themePreference.present) {
      map['theme_preference'] = Variable<String>(themePreference.value);
    }
    if (accentIndex.present) {
      map['accent_index'] = Variable<int>(accentIndex.value);
    }
    if (appIcon.present) {
      map['app_icon'] = Variable<String>(appIcon.value);
    }
    if (priceCents.present) {
      map['price_cents'] = Variable<int>(priceCents.value);
    }
    if (unitsPerContainer.present) {
      map['units_per_container'] = Variable<int>(unitsPerContainer.value);
    }
    if (askForTrigger.present) {
      map['ask_for_trigger'] = Variable<bool>(askForTrigger.value);
    }
    if (triggerPromptIntroSeen.present) {
      map['trigger_prompt_intro_seen'] = Variable<bool>(
        triggerPromptIntroSeen.value,
      );
    }
    if (habitKind.present) {
      map['habit_kind'] = Variable<String>(habitKind.value);
    }
    if (customHabitName.present) {
      map['custom_habit_name'] = Variable<String>(customHabitName.value);
    }
    if (customHabitUnit.present) {
      map['custom_habit_unit'] = Variable<String>(customHabitUnit.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    if (currencySymbol.present) {
      map['currency_symbol'] = Variable<String>(currencySymbol.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsCompanion(')
          ..write('id: $id, ')
          ..write('userName: $userName, ')
          ..write('dayResetHour: $dayResetHour, ')
          ..write('themePreference: $themePreference, ')
          ..write('accentIndex: $accentIndex, ')
          ..write('appIcon: $appIcon, ')
          ..write('priceCents: $priceCents, ')
          ..write('unitsPerContainer: $unitsPerContainer, ')
          ..write('askForTrigger: $askForTrigger, ')
          ..write('triggerPromptIntroSeen: $triggerPromptIntroSeen, ')
          ..write('habitKind: $habitKind, ')
          ..write('customHabitName: $customHabitName, ')
          ..write('customHabitUnit: $customHabitUnit, ')
          ..write('reason: $reason, ')
          ..write('currencySymbol: $currencySymbol')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $PlansTable plans = $PlansTable(this);
  late final $HabitLogsTable habitLogs = $HabitLogsTable(this);
  late final $SettingsTable settings = $SettingsTable(this);
  late final Index idxHabitLogsLoggedAt = Index(
    'idx_habit_logs_logged_at',
    'CREATE INDEX idx_habit_logs_logged_at ON habit_logs (logged_at)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    plans,
    habitLogs,
    settings,
    idxHabitLogsLoggedAt,
  ];
}

typedef $$PlansTableCreateCompanionBuilder = PlansCompanion Function({
  Value<int> id,
  required String startDay,
  required int startLimit,
  required String quitDay,
  Value<DateTime> createdAt,
});
typedef $$PlansTableUpdateCompanionBuilder = PlansCompanion Function({
  Value<int> id,
  Value<String> startDay,
  Value<int> startLimit,
  Value<String> quitDay,
  Value<DateTime> createdAt,
});

class $$PlansTableFilterComposer extends Composer<_$AppDatabase, $PlansTable> {
  $$PlansTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get startDay => $composableBuilder(
    column: $table.startDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startLimit => $composableBuilder(
    column: $table.startLimit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get quitDay => $composableBuilder(
    column: $table.quitDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PlansTableOrderingComposer
    extends Composer<_$AppDatabase, $PlansTable> {
  $$PlansTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get startDay => $composableBuilder(
    column: $table.startDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startLimit => $composableBuilder(
    column: $table.startLimit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get quitDay => $composableBuilder(
    column: $table.quitDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PlansTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlansTable> {
  $$PlansTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get startDay =>
      $composableBuilder(column: $table.startDay, builder: (column) => column);

  GeneratedColumn<int> get startLimit => $composableBuilder(
    column: $table.startLimit,
    builder: (column) => column,
  );

  GeneratedColumn<String> get quitDay =>
      $composableBuilder(column: $table.quitDay, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$PlansTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PlansTable,
          PlanRow,
          $$PlansTableFilterComposer,
          $$PlansTableOrderingComposer,
          $$PlansTableAnnotationComposer,
          $$PlansTableCreateCompanionBuilder,
          $$PlansTableUpdateCompanionBuilder,
          (PlanRow, BaseReferences<_$AppDatabase, $PlansTable, PlanRow>),
          PlanRow,
          PrefetchHooks Function()
        > {
  $$PlansTableTableManager(_$AppDatabase db, $PlansTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlansTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlansTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlansTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> startDay = const Value.absent(),
                Value<int> startLimit = const Value.absent(),
                Value<String> quitDay = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => PlansCompanion(
                id: id,
                startDay: startDay,
                startLimit: startLimit,
                quitDay: quitDay,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String startDay,
                required int startLimit,
                required String quitDay,
                Value<DateTime> createdAt = const Value.absent(),
              }) => PlansCompanion.insert(
                id: id,
                startDay: startDay,
                startLimit: startLimit,
                quitDay: quitDay,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PlansTable, PlanRow>(table),
                  BaseReferences<_$AppDatabase, $PlansTable, PlanRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PlansTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PlansTable,
      PlanRow,
      $$PlansTableFilterComposer,
      $$PlansTableOrderingComposer,
      $$PlansTableAnnotationComposer,
      $$PlansTableCreateCompanionBuilder,
      $$PlansTableUpdateCompanionBuilder,
      (PlanRow, BaseReferences<_$AppDatabase, $PlansTable, PlanRow>),
      PlanRow,
      PrefetchHooks Function()
    >;
typedef $$HabitLogsTableCreateCompanionBuilder = HabitLogsCompanion Function({
  Value<int> id,
  required DateTime loggedAt,
  Value<String> habitKind,
  Value<String?> trigger,
  Value<String?> note,
  Value<DateTime> createdAt,
});
typedef $$HabitLogsTableUpdateCompanionBuilder = HabitLogsCompanion Function({
  Value<int> id,
  Value<DateTime> loggedAt,
  Value<String> habitKind,
  Value<String?> trigger,
  Value<String?> note,
  Value<DateTime> createdAt,
});

class $$HabitLogsTableFilterComposer
    extends Composer<_$AppDatabase, $HabitLogsTable> {
  $$HabitLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get loggedAt => $composableBuilder(
    column: $table.loggedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get habitKind => $composableBuilder(
    column: $table.habitKind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get trigger => $composableBuilder(
    column: $table.trigger,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$HabitLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $HabitLogsTable> {
  $$HabitLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get loggedAt => $composableBuilder(
    column: $table.loggedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get habitKind => $composableBuilder(
    column: $table.habitKind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get trigger => $composableBuilder(
    column: $table.trigger,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$HabitLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $HabitLogsTable> {
  $$HabitLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get loggedAt =>
      $composableBuilder(column: $table.loggedAt, builder: (column) => column);

  GeneratedColumn<String> get habitKind =>
      $composableBuilder(column: $table.habitKind, builder: (column) => column);

  GeneratedColumn<String> get trigger =>
      $composableBuilder(column: $table.trigger, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$HabitLogsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $HabitLogsTable,
          HabitLogRow,
          $$HabitLogsTableFilterComposer,
          $$HabitLogsTableOrderingComposer,
          $$HabitLogsTableAnnotationComposer,
          $$HabitLogsTableCreateCompanionBuilder,
          $$HabitLogsTableUpdateCompanionBuilder,
          (
            HabitLogRow,
            BaseReferences<_$AppDatabase, $HabitLogsTable, HabitLogRow>,
          ),
          HabitLogRow,
          PrefetchHooks Function()
        > {
  $$HabitLogsTableTableManager(_$AppDatabase db, $HabitLogsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HabitLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HabitLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HabitLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> loggedAt = const Value.absent(),
                Value<String> habitKind = const Value.absent(),
                Value<String?> trigger = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => HabitLogsCompanion(
                id: id,
                loggedAt: loggedAt,
                habitKind: habitKind,
                trigger: trigger,
                note: note,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime loggedAt,
                Value<String> habitKind = const Value.absent(),
                Value<String?> trigger = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => HabitLogsCompanion.insert(
                id: id,
                loggedAt: loggedAt,
                habitKind: habitKind,
                trigger: trigger,
                note: note,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$HabitLogsTable, HabitLogRow>(table),
                  BaseReferences<_$AppDatabase, $HabitLogsTable, HabitLogRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$HabitLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $HabitLogsTable,
      HabitLogRow,
      $$HabitLogsTableFilterComposer,
      $$HabitLogsTableOrderingComposer,
      $$HabitLogsTableAnnotationComposer,
      $$HabitLogsTableCreateCompanionBuilder,
      $$HabitLogsTableUpdateCompanionBuilder,
      (
        HabitLogRow,
        BaseReferences<_$AppDatabase, $HabitLogsTable, HabitLogRow>,
      ),
      HabitLogRow,
      PrefetchHooks Function()
    >;
typedef $$SettingsTableCreateCompanionBuilder = SettingsCompanion Function({
  Value<int> id,
  Value<String?> userName,
  Value<int> dayResetHour,
  Value<String> themePreference,
  Value<int> accentIndex,
  Value<String> appIcon,
  Value<int?> priceCents,
  Value<int> unitsPerContainer,
  Value<bool> askForTrigger,
  Value<bool> triggerPromptIntroSeen,
  Value<String> habitKind,
  Value<String?> customHabitName,
  Value<String?> customHabitUnit,
  Value<String?> reason,
  Value<String> currencySymbol,
});
typedef $$SettingsTableUpdateCompanionBuilder = SettingsCompanion Function({
  Value<int> id,
  Value<String?> userName,
  Value<int> dayResetHour,
  Value<String> themePreference,
  Value<int> accentIndex,
  Value<String> appIcon,
  Value<int?> priceCents,
  Value<int> unitsPerContainer,
  Value<bool> askForTrigger,
  Value<bool> triggerPromptIntroSeen,
  Value<String> habitKind,
  Value<String?> customHabitName,
  Value<String?> customHabitUnit,
  Value<String?> reason,
  Value<String> currencySymbol,
});

class $$SettingsTableFilterComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userName => $composableBuilder(
    column: $table.userName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dayResetHour => $composableBuilder(
    column: $table.dayResetHour,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get themePreference => $composableBuilder(
    column: $table.themePreference,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get accentIndex => $composableBuilder(
    column: $table.accentIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get appIcon => $composableBuilder(
    column: $table.appIcon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get priceCents => $composableBuilder(
    column: $table.priceCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get unitsPerContainer => $composableBuilder(
    column: $table.unitsPerContainer,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get askForTrigger => $composableBuilder(
    column: $table.askForTrigger,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get triggerPromptIntroSeen => $composableBuilder(
    column: $table.triggerPromptIntroSeen,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get habitKind => $composableBuilder(
    column: $table.habitKind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customHabitName => $composableBuilder(
    column: $table.customHabitName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customHabitUnit => $composableBuilder(
    column: $table.customHabitUnit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currencySymbol => $composableBuilder(
    column: $table.currencySymbol,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userName => $composableBuilder(
    column: $table.userName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dayResetHour => $composableBuilder(
    column: $table.dayResetHour,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get themePreference => $composableBuilder(
    column: $table.themePreference,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get accentIndex => $composableBuilder(
    column: $table.accentIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get appIcon => $composableBuilder(
    column: $table.appIcon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get priceCents => $composableBuilder(
    column: $table.priceCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get unitsPerContainer => $composableBuilder(
    column: $table.unitsPerContainer,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get askForTrigger => $composableBuilder(
    column: $table.askForTrigger,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get triggerPromptIntroSeen => $composableBuilder(
    column: $table.triggerPromptIntroSeen,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get habitKind => $composableBuilder(
    column: $table.habitKind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customHabitName => $composableBuilder(
    column: $table.customHabitName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customHabitUnit => $composableBuilder(
    column: $table.customHabitUnit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currencySymbol => $composableBuilder(
    column: $table.currencySymbol,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userName =>
      $composableBuilder(column: $table.userName, builder: (column) => column);

  GeneratedColumn<int> get dayResetHour => $composableBuilder(
    column: $table.dayResetHour,
    builder: (column) => column,
  );

  GeneratedColumn<String> get themePreference => $composableBuilder(
    column: $table.themePreference,
    builder: (column) => column,
  );

  GeneratedColumn<int> get accentIndex => $composableBuilder(
    column: $table.accentIndex,
    builder: (column) => column,
  );

  GeneratedColumn<String> get appIcon =>
      $composableBuilder(column: $table.appIcon, builder: (column) => column);

  GeneratedColumn<int> get priceCents => $composableBuilder(
    column: $table.priceCents,
    builder: (column) => column,
  );

  GeneratedColumn<int> get unitsPerContainer => $composableBuilder(
    column: $table.unitsPerContainer,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get askForTrigger => $composableBuilder(
    column: $table.askForTrigger,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get triggerPromptIntroSeen => $composableBuilder(
    column: $table.triggerPromptIntroSeen,
    builder: (column) => column,
  );

  GeneratedColumn<String> get habitKind =>
      $composableBuilder(column: $table.habitKind, builder: (column) => column);

  GeneratedColumn<String> get customHabitName => $composableBuilder(
    column: $table.customHabitName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get customHabitUnit => $composableBuilder(
    column: $table.customHabitUnit,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => column);

  GeneratedColumn<String> get currencySymbol => $composableBuilder(
    column: $table.currencySymbol,
    builder: (column) => column,
  );
}

class $$SettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SettingsTable,
          SettingsRow,
          $$SettingsTableFilterComposer,
          $$SettingsTableOrderingComposer,
          $$SettingsTableAnnotationComposer,
          $$SettingsTableCreateCompanionBuilder,
          $$SettingsTableUpdateCompanionBuilder,
          (
            SettingsRow,
            BaseReferences<_$AppDatabase, $SettingsTable, SettingsRow>,
          ),
          SettingsRow,
          PrefetchHooks Function()
        > {
  $$SettingsTableTableManager(_$AppDatabase db, $SettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> userName = const Value.absent(),
                Value<int> dayResetHour = const Value.absent(),
                Value<String> themePreference = const Value.absent(),
                Value<int> accentIndex = const Value.absent(),
                Value<String> appIcon = const Value.absent(),
                Value<int?> priceCents = const Value.absent(),
                Value<int> unitsPerContainer = const Value.absent(),
                Value<bool> askForTrigger = const Value.absent(),
                Value<bool> triggerPromptIntroSeen = const Value.absent(),
                Value<String> habitKind = const Value.absent(),
                Value<String?> customHabitName = const Value.absent(),
                Value<String?> customHabitUnit = const Value.absent(),
                Value<String?> reason = const Value.absent(),
                Value<String> currencySymbol = const Value.absent(),
              }) => SettingsCompanion(
                id: id,
                userName: userName,
                dayResetHour: dayResetHour,
                themePreference: themePreference,
                accentIndex: accentIndex,
                appIcon: appIcon,
                priceCents: priceCents,
                unitsPerContainer: unitsPerContainer,
                askForTrigger: askForTrigger,
                triggerPromptIntroSeen: triggerPromptIntroSeen,
                habitKind: habitKind,
                customHabitName: customHabitName,
                customHabitUnit: customHabitUnit,
                reason: reason,
                currencySymbol: currencySymbol,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> userName = const Value.absent(),
                Value<int> dayResetHour = const Value.absent(),
                Value<String> themePreference = const Value.absent(),
                Value<int> accentIndex = const Value.absent(),
                Value<String> appIcon = const Value.absent(),
                Value<int?> priceCents = const Value.absent(),
                Value<int> unitsPerContainer = const Value.absent(),
                Value<bool> askForTrigger = const Value.absent(),
                Value<bool> triggerPromptIntroSeen = const Value.absent(),
                Value<String> habitKind = const Value.absent(),
                Value<String?> customHabitName = const Value.absent(),
                Value<String?> customHabitUnit = const Value.absent(),
                Value<String?> reason = const Value.absent(),
                Value<String> currencySymbol = const Value.absent(),
              }) => SettingsCompanion.insert(
                id: id,
                userName: userName,
                dayResetHour: dayResetHour,
                themePreference: themePreference,
                accentIndex: accentIndex,
                appIcon: appIcon,
                priceCents: priceCents,
                unitsPerContainer: unitsPerContainer,
                askForTrigger: askForTrigger,
                triggerPromptIntroSeen: triggerPromptIntroSeen,
                habitKind: habitKind,
                customHabitName: customHabitName,
                customHabitUnit: customHabitUnit,
                reason: reason,
                currencySymbol: currencySymbol,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SettingsTable, SettingsRow>(table),
                  BaseReferences<_$AppDatabase, $SettingsTable, SettingsRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SettingsTable,
      SettingsRow,
      $$SettingsTableFilterComposer,
      $$SettingsTableOrderingComposer,
      $$SettingsTableAnnotationComposer,
      $$SettingsTableCreateCompanionBuilder,
      $$SettingsTableUpdateCompanionBuilder,
      (SettingsRow, BaseReferences<_$AppDatabase, $SettingsTable, SettingsRow>),
      SettingsRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$PlansTableTableManager get plans =>
      $$PlansTableTableManager(_db, _db.plans);
  $$HabitLogsTableTableManager get habitLogs =>
      $$HabitLogsTableTableManager(_db, _db.habitLogs);
  $$SettingsTableTableManager get settings =>
      $$SettingsTableTableManager(_db, _db.settings);
}
