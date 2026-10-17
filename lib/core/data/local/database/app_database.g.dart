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
  static const VerificationMeta _stepDaysMeta = const VerificationMeta(
    'stepDays',
  );
  @override
  late final GeneratedColumn<int> stepDays = GeneratedColumn<int>(
    'step_days',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetLimitMeta = const VerificationMeta(
    'targetLimit',
  );
  @override
  late final GeneratedColumn<int> targetLimit = GeneratedColumn<int>(
    'target_limit',
    aliasedName,
    false,
    type: DriftSqlType.int,
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
    stepDays,
    targetLimit,
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
    if (data.containsKey('step_days')) {
      context.handle(
        _stepDaysMeta,
        stepDays.isAcceptableOrUnknown(data['step_days']!, _stepDaysMeta),
      );
    } else if (isInserting) {
      context.missing(_stepDaysMeta);
    }
    if (data.containsKey('target_limit')) {
      context.handle(
        _targetLimitMeta,
        targetLimit.isAcceptableOrUnknown(
          data['target_limit']!,
          _targetLimitMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_targetLimitMeta);
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
      stepDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}step_days'],
      )!,
      targetLimit: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}target_limit'],
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
  final int stepDays;
  final int targetLimit;
  final DateTime createdAt;
  const PlanRow({
    required this.id,
    required this.startDay,
    required this.startLimit,
    required this.stepDays,
    required this.targetLimit,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['start_day'] = Variable<String>(startDay);
    map['start_limit'] = Variable<int>(startLimit);
    map['step_days'] = Variable<int>(stepDays);
    map['target_limit'] = Variable<int>(targetLimit);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  PlansCompanion toCompanion(bool nullToAbsent) {
    return PlansCompanion(
      id: Value(id),
      startDay: Value(startDay),
      startLimit: Value(startLimit),
      stepDays: Value(stepDays),
      targetLimit: Value(targetLimit),
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
      stepDays: serializer.fromJson<int>(json['stepDays']),
      targetLimit: serializer.fromJson<int>(json['targetLimit']),
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
      'stepDays': serializer.toJson<int>(stepDays),
      'targetLimit': serializer.toJson<int>(targetLimit),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  PlanRow copyWith({
    int? id,
    String? startDay,
    int? startLimit,
    int? stepDays,
    int? targetLimit,
    DateTime? createdAt,
  }) => PlanRow(
    id: id ?? this.id,
    startDay: startDay ?? this.startDay,
    startLimit: startLimit ?? this.startLimit,
    stepDays: stepDays ?? this.stepDays,
    targetLimit: targetLimit ?? this.targetLimit,
    createdAt: createdAt ?? this.createdAt,
  );
  PlanRow copyWithCompanion(PlansCompanion data) {
    return PlanRow(
      id: data.id.present ? data.id.value : this.id,
      startDay: data.startDay.present ? data.startDay.value : this.startDay,
      startLimit: data.startLimit.present
          ? data.startLimit.value
          : this.startLimit,
      stepDays: data.stepDays.present ? data.stepDays.value : this.stepDays,
      targetLimit: data.targetLimit.present
          ? data.targetLimit.value
          : this.targetLimit,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlanRow(')
          ..write('id: $id, ')
          ..write('startDay: $startDay, ')
          ..write('startLimit: $startLimit, ')
          ..write('stepDays: $stepDays, ')
          ..write('targetLimit: $targetLimit, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, startDay, startLimit, stepDays, targetLimit, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlanRow &&
          other.id == this.id &&
          other.startDay == this.startDay &&
          other.startLimit == this.startLimit &&
          other.stepDays == this.stepDays &&
          other.targetLimit == this.targetLimit &&
          other.createdAt == this.createdAt);
}

class PlansCompanion extends UpdateCompanion<PlanRow> {
  final Value<int> id;
  final Value<String> startDay;
  final Value<int> startLimit;
  final Value<int> stepDays;
  final Value<int> targetLimit;
  final Value<DateTime> createdAt;
  const PlansCompanion({
    this.id = const Value.absent(),
    this.startDay = const Value.absent(),
    this.startLimit = const Value.absent(),
    this.stepDays = const Value.absent(),
    this.targetLimit = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  PlansCompanion.insert({
    this.id = const Value.absent(),
    required String startDay,
    required int startLimit,
    required int stepDays,
    required int targetLimit,
    this.createdAt = const Value.absent(),
  }) : startDay = Value(startDay),
       startLimit = Value(startLimit),
       stepDays = Value(stepDays),
       targetLimit = Value(targetLimit);
  static Insertable<PlanRow> custom({
    Expression<int>? id,
    Expression<String>? startDay,
    Expression<int>? startLimit,
    Expression<int>? stepDays,
    Expression<int>? targetLimit,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (startDay != null) 'start_day': startDay,
      if (startLimit != null) 'start_limit': startLimit,
      if (stepDays != null) 'step_days': stepDays,
      if (targetLimit != null) 'target_limit': targetLimit,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  PlansCompanion copyWith({
    Value<int>? id,
    Value<String>? startDay,
    Value<int>? startLimit,
    Value<int>? stepDays,
    Value<int>? targetLimit,
    Value<DateTime>? createdAt,
  }) {
    return PlansCompanion(
      id: id ?? this.id,
      startDay: startDay ?? this.startDay,
      startLimit: startLimit ?? this.startLimit,
      stepDays: stepDays ?? this.stepDays,
      targetLimit: targetLimit ?? this.targetLimit,
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
    if (stepDays.present) {
      map['step_days'] = Variable<int>(stepDays.value);
    }
    if (targetLimit.present) {
      map['target_limit'] = Variable<int>(targetLimit.value);
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
          ..write('stepDays: $stepDays, ')
          ..write('targetLimit: $targetLimit, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $SmokeLogsTable extends SmokeLogs
    with TableInfo<$SmokeLogsTable, SmokeLogRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SmokeLogsTable(this.attachedDatabase, [this._alias]);
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
    trigger,
    note,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'smoke_logs';
  @override
  VerificationContext validateIntegrity(
    Insertable<SmokeLogRow> instance, {
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
  SmokeLogRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SmokeLogRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      loggedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}logged_at'],
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
  $SmokeLogsTable createAlias(String alias) {
    return $SmokeLogsTable(attachedDatabase, alias);
  }
}

class SmokeLogRow extends DataClass implements Insertable<SmokeLogRow> {
  final int id;
  final DateTime loggedAt;

  /// SmokeTrigger.name, or null when skipped.
  final String? trigger;
  final String? note;
  final DateTime createdAt;
  const SmokeLogRow({
    required this.id,
    required this.loggedAt,
    this.trigger,
    this.note,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['logged_at'] = Variable<DateTime>(loggedAt);
    if (!nullToAbsent || trigger != null) {
      map['trigger'] = Variable<String>(trigger);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  SmokeLogsCompanion toCompanion(bool nullToAbsent) {
    return SmokeLogsCompanion(
      id: Value(id),
      loggedAt: Value(loggedAt),
      trigger: trigger == null && nullToAbsent
          ? const Value.absent()
          : Value(trigger),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      createdAt: Value(createdAt),
    );
  }

  factory SmokeLogRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SmokeLogRow(
      id: serializer.fromJson<int>(json['id']),
      loggedAt: serializer.fromJson<DateTime>(json['loggedAt']),
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
      'trigger': serializer.toJson<String?>(trigger),
      'note': serializer.toJson<String?>(note),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  SmokeLogRow copyWith({
    int? id,
    DateTime? loggedAt,
    Value<String?> trigger = const Value.absent(),
    Value<String?> note = const Value.absent(),
    DateTime? createdAt,
  }) => SmokeLogRow(
    id: id ?? this.id,
    loggedAt: loggedAt ?? this.loggedAt,
    trigger: trigger.present ? trigger.value : this.trigger,
    note: note.present ? note.value : this.note,
    createdAt: createdAt ?? this.createdAt,
  );
  SmokeLogRow copyWithCompanion(SmokeLogsCompanion data) {
    return SmokeLogRow(
      id: data.id.present ? data.id.value : this.id,
      loggedAt: data.loggedAt.present ? data.loggedAt.value : this.loggedAt,
      trigger: data.trigger.present ? data.trigger.value : this.trigger,
      note: data.note.present ? data.note.value : this.note,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SmokeLogRow(')
          ..write('id: $id, ')
          ..write('loggedAt: $loggedAt, ')
          ..write('trigger: $trigger, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, loggedAt, trigger, note, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SmokeLogRow &&
          other.id == this.id &&
          other.loggedAt == this.loggedAt &&
          other.trigger == this.trigger &&
          other.note == this.note &&
          other.createdAt == this.createdAt);
}

class SmokeLogsCompanion extends UpdateCompanion<SmokeLogRow> {
  final Value<int> id;
  final Value<DateTime> loggedAt;
  final Value<String?> trigger;
  final Value<String?> note;
  final Value<DateTime> createdAt;
  const SmokeLogsCompanion({
    this.id = const Value.absent(),
    this.loggedAt = const Value.absent(),
    this.trigger = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  SmokeLogsCompanion.insert({
    this.id = const Value.absent(),
    required DateTime loggedAt,
    this.trigger = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : loggedAt = Value(loggedAt);
  static Insertable<SmokeLogRow> custom({
    Expression<int>? id,
    Expression<DateTime>? loggedAt,
    Expression<String>? trigger,
    Expression<String>? note,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (loggedAt != null) 'logged_at': loggedAt,
      if (trigger != null) 'trigger': trigger,
      if (note != null) 'note': note,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  SmokeLogsCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? loggedAt,
    Value<String?>? trigger,
    Value<String?>? note,
    Value<DateTime>? createdAt,
  }) {
    return SmokeLogsCompanion(
      id: id ?? this.id,
      loggedAt: loggedAt ?? this.loggedAt,
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
    return (StringBuffer('SmokeLogsCompanion(')
          ..write('id: $id, ')
          ..write('loggedAt: $loggedAt, ')
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
    defaultValue: const Constant('dark'),
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
  static const VerificationMeta _packPriceCentsMeta = const VerificationMeta(
    'packPriceCents',
  );
  @override
  late final GeneratedColumn<int> packPriceCents = GeneratedColumn<int>(
    'pack_price_cents',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cigarettesPerPackMeta = const VerificationMeta(
    'cigarettesPerPack',
  );
  @override
  late final GeneratedColumn<int> cigarettesPerPack = GeneratedColumn<int>(
    'cigarettes_per_pack',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(20),
  );
  static const VerificationMeta _glassEffectsMeta = const VerificationMeta(
    'glassEffects',
  );
  @override
  late final GeneratedColumn<bool> glassEffects = GeneratedColumn<bool>(
    'glass_effects',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("glass_effects" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
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
    packPriceCents,
    cigarettesPerPack,
    glassEffects,
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
    if (data.containsKey('pack_price_cents')) {
      context.handle(
        _packPriceCentsMeta,
        packPriceCents.isAcceptableOrUnknown(
          data['pack_price_cents']!,
          _packPriceCentsMeta,
        ),
      );
    }
    if (data.containsKey('cigarettes_per_pack')) {
      context.handle(
        _cigarettesPerPackMeta,
        cigarettesPerPack.isAcceptableOrUnknown(
          data['cigarettes_per_pack']!,
          _cigarettesPerPackMeta,
        ),
      );
    }
    if (data.containsKey('glass_effects')) {
      context.handle(
        _glassEffectsMeta,
        glassEffects.isAcceptableOrUnknown(
          data['glass_effects']!,
          _glassEffectsMeta,
        ),
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
      packPriceCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}pack_price_cents'],
      ),
      cigarettesPerPack: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cigarettes_per_pack'],
      )!,
      glassEffects: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}glass_effects'],
      )!,
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
  final int? packPriceCents;
  final int cigarettesPerPack;
  final bool glassEffects;
  final String currencySymbol;
  const SettingsRow({
    required this.id,
    this.userName,
    required this.dayResetHour,
    required this.themePreference,
    required this.accentIndex,
    required this.appIcon,
    this.packPriceCents,
    required this.cigarettesPerPack,
    required this.glassEffects,
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
    if (!nullToAbsent || packPriceCents != null) {
      map['pack_price_cents'] = Variable<int>(packPriceCents);
    }
    map['cigarettes_per_pack'] = Variable<int>(cigarettesPerPack);
    map['glass_effects'] = Variable<bool>(glassEffects);
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
      packPriceCents: packPriceCents == null && nullToAbsent
          ? const Value.absent()
          : Value(packPriceCents),
      cigarettesPerPack: Value(cigarettesPerPack),
      glassEffects: Value(glassEffects),
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
      packPriceCents: serializer.fromJson<int?>(json['packPriceCents']),
      cigarettesPerPack: serializer.fromJson<int>(json['cigarettesPerPack']),
      glassEffects: serializer.fromJson<bool>(json['glassEffects']),
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
      'packPriceCents': serializer.toJson<int?>(packPriceCents),
      'cigarettesPerPack': serializer.toJson<int>(cigarettesPerPack),
      'glassEffects': serializer.toJson<bool>(glassEffects),
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
    Value<int?> packPriceCents = const Value.absent(),
    int? cigarettesPerPack,
    bool? glassEffects,
    String? currencySymbol,
  }) => SettingsRow(
    id: id ?? this.id,
    userName: userName.present ? userName.value : this.userName,
    dayResetHour: dayResetHour ?? this.dayResetHour,
    themePreference: themePreference ?? this.themePreference,
    accentIndex: accentIndex ?? this.accentIndex,
    appIcon: appIcon ?? this.appIcon,
    packPriceCents: packPriceCents.present
        ? packPriceCents.value
        : this.packPriceCents,
    cigarettesPerPack: cigarettesPerPack ?? this.cigarettesPerPack,
    glassEffects: glassEffects ?? this.glassEffects,
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
      packPriceCents: data.packPriceCents.present
          ? data.packPriceCents.value
          : this.packPriceCents,
      cigarettesPerPack: data.cigarettesPerPack.present
          ? data.cigarettesPerPack.value
          : this.cigarettesPerPack,
      glassEffects: data.glassEffects.present
          ? data.glassEffects.value
          : this.glassEffects,
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
          ..write('packPriceCents: $packPriceCents, ')
          ..write('cigarettesPerPack: $cigarettesPerPack, ')
          ..write('glassEffects: $glassEffects, ')
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
    packPriceCents,
    cigarettesPerPack,
    glassEffects,
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
          other.packPriceCents == this.packPriceCents &&
          other.cigarettesPerPack == this.cigarettesPerPack &&
          other.glassEffects == this.glassEffects &&
          other.currencySymbol == this.currencySymbol);
}

class SettingsCompanion extends UpdateCompanion<SettingsRow> {
  final Value<int> id;
  final Value<String?> userName;
  final Value<int> dayResetHour;
  final Value<String> themePreference;
  final Value<int> accentIndex;
  final Value<String> appIcon;
  final Value<int?> packPriceCents;
  final Value<int> cigarettesPerPack;
  final Value<bool> glassEffects;
  final Value<String> currencySymbol;
  const SettingsCompanion({
    this.id = const Value.absent(),
    this.userName = const Value.absent(),
    this.dayResetHour = const Value.absent(),
    this.themePreference = const Value.absent(),
    this.accentIndex = const Value.absent(),
    this.appIcon = const Value.absent(),
    this.packPriceCents = const Value.absent(),
    this.cigarettesPerPack = const Value.absent(),
    this.glassEffects = const Value.absent(),
    this.currencySymbol = const Value.absent(),
  });
  SettingsCompanion.insert({
    this.id = const Value.absent(),
    this.userName = const Value.absent(),
    this.dayResetHour = const Value.absent(),
    this.themePreference = const Value.absent(),
    this.accentIndex = const Value.absent(),
    this.appIcon = const Value.absent(),
    this.packPriceCents = const Value.absent(),
    this.cigarettesPerPack = const Value.absent(),
    this.glassEffects = const Value.absent(),
    this.currencySymbol = const Value.absent(),
  });
  static Insertable<SettingsRow> custom({
    Expression<int>? id,
    Expression<String>? userName,
    Expression<int>? dayResetHour,
    Expression<String>? themePreference,
    Expression<int>? accentIndex,
    Expression<String>? appIcon,
    Expression<int>? packPriceCents,
    Expression<int>? cigarettesPerPack,
    Expression<bool>? glassEffects,
    Expression<String>? currencySymbol,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userName != null) 'user_name': userName,
      if (dayResetHour != null) 'day_reset_hour': dayResetHour,
      if (themePreference != null) 'theme_preference': themePreference,
      if (accentIndex != null) 'accent_index': accentIndex,
      if (appIcon != null) 'app_icon': appIcon,
      if (packPriceCents != null) 'pack_price_cents': packPriceCents,
      if (cigarettesPerPack != null) 'cigarettes_per_pack': cigarettesPerPack,
      if (glassEffects != null) 'glass_effects': glassEffects,
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
    Value<int?>? packPriceCents,
    Value<int>? cigarettesPerPack,
    Value<bool>? glassEffects,
    Value<String>? currencySymbol,
  }) {
    return SettingsCompanion(
      id: id ?? this.id,
      userName: userName ?? this.userName,
      dayResetHour: dayResetHour ?? this.dayResetHour,
      themePreference: themePreference ?? this.themePreference,
      accentIndex: accentIndex ?? this.accentIndex,
      appIcon: appIcon ?? this.appIcon,
      packPriceCents: packPriceCents ?? this.packPriceCents,
      cigarettesPerPack: cigarettesPerPack ?? this.cigarettesPerPack,
      glassEffects: glassEffects ?? this.glassEffects,
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
    if (packPriceCents.present) {
      map['pack_price_cents'] = Variable<int>(packPriceCents.value);
    }
    if (cigarettesPerPack.present) {
      map['cigarettes_per_pack'] = Variable<int>(cigarettesPerPack.value);
    }
    if (glassEffects.present) {
      map['glass_effects'] = Variable<bool>(glassEffects.value);
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
          ..write('packPriceCents: $packPriceCents, ')
          ..write('cigarettesPerPack: $cigarettesPerPack, ')
          ..write('glassEffects: $glassEffects, ')
          ..write('currencySymbol: $currencySymbol')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $PlansTable plans = $PlansTable(this);
  late final $SmokeLogsTable smokeLogs = $SmokeLogsTable(this);
  late final $SettingsTable settings = $SettingsTable(this);
  late final Index idxSmokeLogsLoggedAt = Index(
    'idx_smoke_logs_logged_at',
    'CREATE INDEX idx_smoke_logs_logged_at ON smoke_logs (logged_at)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    plans,
    smokeLogs,
    settings,
    idxSmokeLogsLoggedAt,
  ];
}

typedef $$PlansTableCreateCompanionBuilder = PlansCompanion Function({
  Value<int> id,
  required String startDay,
  required int startLimit,
  required int stepDays,
  required int targetLimit,
  Value<DateTime> createdAt,
});
typedef $$PlansTableUpdateCompanionBuilder = PlansCompanion Function({
  Value<int> id,
  Value<String> startDay,
  Value<int> startLimit,
  Value<int> stepDays,
  Value<int> targetLimit,
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

  ColumnFilters<int> get stepDays => $composableBuilder(
    column: $table.stepDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get targetLimit => $composableBuilder(
    column: $table.targetLimit,
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

  ColumnOrderings<int> get stepDays => $composableBuilder(
    column: $table.stepDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get targetLimit => $composableBuilder(
    column: $table.targetLimit,
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

  GeneratedColumn<int> get stepDays =>
      $composableBuilder(column: $table.stepDays, builder: (column) => column);

  GeneratedColumn<int> get targetLimit => $composableBuilder(
    column: $table.targetLimit,
    builder: (column) => column,
  );

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
                Value<int> stepDays = const Value.absent(),
                Value<int> targetLimit = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => PlansCompanion(
                id: id,
                startDay: startDay,
                startLimit: startLimit,
                stepDays: stepDays,
                targetLimit: targetLimit,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String startDay,
                required int startLimit,
                required int stepDays,
                required int targetLimit,
                Value<DateTime> createdAt = const Value.absent(),
              }) => PlansCompanion.insert(
                id: id,
                startDay: startDay,
                startLimit: startLimit,
                stepDays: stepDays,
                targetLimit: targetLimit,
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
typedef $$SmokeLogsTableCreateCompanionBuilder = SmokeLogsCompanion Function({
  Value<int> id,
  required DateTime loggedAt,
  Value<String?> trigger,
  Value<String?> note,
  Value<DateTime> createdAt,
});
typedef $$SmokeLogsTableUpdateCompanionBuilder = SmokeLogsCompanion Function({
  Value<int> id,
  Value<DateTime> loggedAt,
  Value<String?> trigger,
  Value<String?> note,
  Value<DateTime> createdAt,
});

class $$SmokeLogsTableFilterComposer
    extends Composer<_$AppDatabase, $SmokeLogsTable> {
  $$SmokeLogsTableFilterComposer({
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

class $$SmokeLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $SmokeLogsTable> {
  $$SmokeLogsTableOrderingComposer({
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

class $$SmokeLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SmokeLogsTable> {
  $$SmokeLogsTableAnnotationComposer({
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

  GeneratedColumn<String> get trigger =>
      $composableBuilder(column: $table.trigger, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$SmokeLogsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SmokeLogsTable,
          SmokeLogRow,
          $$SmokeLogsTableFilterComposer,
          $$SmokeLogsTableOrderingComposer,
          $$SmokeLogsTableAnnotationComposer,
          $$SmokeLogsTableCreateCompanionBuilder,
          $$SmokeLogsTableUpdateCompanionBuilder,
          (
            SmokeLogRow,
            BaseReferences<_$AppDatabase, $SmokeLogsTable, SmokeLogRow>,
          ),
          SmokeLogRow,
          PrefetchHooks Function()
        > {
  $$SmokeLogsTableTableManager(_$AppDatabase db, $SmokeLogsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SmokeLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SmokeLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SmokeLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> loggedAt = const Value.absent(),
                Value<String?> trigger = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => SmokeLogsCompanion(
                id: id,
                loggedAt: loggedAt,
                trigger: trigger,
                note: note,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime loggedAt,
                Value<String?> trigger = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => SmokeLogsCompanion.insert(
                id: id,
                loggedAt: loggedAt,
                trigger: trigger,
                note: note,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SmokeLogsTable, SmokeLogRow>(table),
                  BaseReferences<_$AppDatabase, $SmokeLogsTable, SmokeLogRow>(
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

typedef $$SmokeLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SmokeLogsTable,
      SmokeLogRow,
      $$SmokeLogsTableFilterComposer,
      $$SmokeLogsTableOrderingComposer,
      $$SmokeLogsTableAnnotationComposer,
      $$SmokeLogsTableCreateCompanionBuilder,
      $$SmokeLogsTableUpdateCompanionBuilder,
      (
        SmokeLogRow,
        BaseReferences<_$AppDatabase, $SmokeLogsTable, SmokeLogRow>,
      ),
      SmokeLogRow,
      PrefetchHooks Function()
    >;
typedef $$SettingsTableCreateCompanionBuilder = SettingsCompanion Function({
  Value<int> id,
  Value<String?> userName,
  Value<int> dayResetHour,
  Value<String> themePreference,
  Value<int> accentIndex,
  Value<String> appIcon,
  Value<int?> packPriceCents,
  Value<int> cigarettesPerPack,
  Value<bool> glassEffects,
  Value<String> currencySymbol,
});
typedef $$SettingsTableUpdateCompanionBuilder = SettingsCompanion Function({
  Value<int> id,
  Value<String?> userName,
  Value<int> dayResetHour,
  Value<String> themePreference,
  Value<int> accentIndex,
  Value<String> appIcon,
  Value<int?> packPriceCents,
  Value<int> cigarettesPerPack,
  Value<bool> glassEffects,
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

  ColumnFilters<int> get packPriceCents => $composableBuilder(
    column: $table.packPriceCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cigarettesPerPack => $composableBuilder(
    column: $table.cigarettesPerPack,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get glassEffects => $composableBuilder(
    column: $table.glassEffects,
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

  ColumnOrderings<int> get packPriceCents => $composableBuilder(
    column: $table.packPriceCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cigarettesPerPack => $composableBuilder(
    column: $table.cigarettesPerPack,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get glassEffects => $composableBuilder(
    column: $table.glassEffects,
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

  GeneratedColumn<int> get packPriceCents => $composableBuilder(
    column: $table.packPriceCents,
    builder: (column) => column,
  );

  GeneratedColumn<int> get cigarettesPerPack => $composableBuilder(
    column: $table.cigarettesPerPack,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get glassEffects => $composableBuilder(
    column: $table.glassEffects,
    builder: (column) => column,
  );

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
                Value<int?> packPriceCents = const Value.absent(),
                Value<int> cigarettesPerPack = const Value.absent(),
                Value<bool> glassEffects = const Value.absent(),
                Value<String> currencySymbol = const Value.absent(),
              }) => SettingsCompanion(
                id: id,
                userName: userName,
                dayResetHour: dayResetHour,
                themePreference: themePreference,
                accentIndex: accentIndex,
                appIcon: appIcon,
                packPriceCents: packPriceCents,
                cigarettesPerPack: cigarettesPerPack,
                glassEffects: glassEffects,
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
                Value<int?> packPriceCents = const Value.absent(),
                Value<int> cigarettesPerPack = const Value.absent(),
                Value<bool> glassEffects = const Value.absent(),
                Value<String> currencySymbol = const Value.absent(),
              }) => SettingsCompanion.insert(
                id: id,
                userName: userName,
                dayResetHour: dayResetHour,
                themePreference: themePreference,
                accentIndex: accentIndex,
                appIcon: appIcon,
                packPriceCents: packPriceCents,
                cigarettesPerPack: cigarettesPerPack,
                glassEffects: glassEffects,
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
  $$SmokeLogsTableTableManager get smokeLogs =>
      $$SmokeLogsTableTableManager(_db, _db.smokeLogs);
  $$SettingsTableTableManager get settings =>
      $$SettingsTableTableManager(_db, _db.settings);
}
