// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $HabitsTable extends Habits with TableInfo<$HabitsTable, HabitRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HabitsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _customNameMeta = const VerificationMeta(
    'customName',
  );
  @override
  late final GeneratedColumn<String> customName = GeneratedColumn<String>(
    'custom_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _customUnitMeta = const VerificationMeta(
    'customUnit',
  );
  @override
  late final GeneratedColumn<String> customUnit = GeneratedColumn<String>(
    'custom_unit',
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
  static const VerificationMeta _archivedAtMeta = const VerificationMeta(
    'archivedAt',
  );
  @override
  late final GeneratedColumn<DateTime> archivedAt = GeneratedColumn<DateTime>(
    'archived_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _quitAcknowledgedAtMeta =
      const VerificationMeta('quitAcknowledgedAt');
  @override
  late final GeneratedColumn<DateTime> quitAcknowledgedAt =
      GeneratedColumn<DateTime>(
        'quit_acknowledged_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    kind,
    customName,
    customUnit,
    reason,
    priceCents,
    unitsPerContainer,
    createdAt,
    archivedAt,
    quitAcknowledgedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'habits';
  @override
  VerificationContext validateIntegrity(
    Insertable<HabitRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('custom_name')) {
      context.handle(
        _customNameMeta,
        customName.isAcceptableOrUnknown(data['custom_name']!, _customNameMeta),
      );
    }
    if (data.containsKey('custom_unit')) {
      context.handle(
        _customUnitMeta,
        customUnit.isAcceptableOrUnknown(data['custom_unit']!, _customUnitMeta),
      );
    }
    if (data.containsKey('reason')) {
      context.handle(
        _reasonMeta,
        reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta),
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
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('archived_at')) {
      context.handle(
        _archivedAtMeta,
        archivedAt.isAcceptableOrUnknown(data['archived_at']!, _archivedAtMeta),
      );
    }
    if (data.containsKey('quit_acknowledged_at')) {
      context.handle(
        _quitAcknowledgedAtMeta,
        quitAcknowledgedAt.isAcceptableOrUnknown(
          data['quit_acknowledged_at']!,
          _quitAcknowledgedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  HabitRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HabitRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      customName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}custom_name'],
      ),
      customUnit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}custom_unit'],
      ),
      reason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reason'],
      ),
      priceCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}price_cents'],
      ),
      unitsPerContainer: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}units_per_container'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      archivedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}archived_at'],
      ),
      quitAcknowledgedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}quit_acknowledged_at'],
      ),
    );
  }

  @override
  $HabitsTable createAlias(String alias) {
    return $HabitsTable(attachedDatabase, alias);
  }
}

class HabitRow extends DataClass implements Insertable<HabitRow> {
  final int id;

  /// HabitKind.name.
  final String kind;

  /// Name and unit of a custom habit.
  final String? customName;
  final String? customUnit;
  final String? reason;

  /// Per container when the habit has one, else per unit.
  final int? priceCents;
  final int unitsPerContainer;
  final DateTime createdAt;

  /// Set when the user stops tracking the habit; its data is kept.
  final DateTime? archivedAt;

  /// Set once the user has seen the quit date reached.
  final DateTime? quitAcknowledgedAt;
  const HabitRow({
    required this.id,
    required this.kind,
    this.customName,
    this.customUnit,
    this.reason,
    this.priceCents,
    required this.unitsPerContainer,
    required this.createdAt,
    this.archivedAt,
    this.quitAcknowledgedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['kind'] = Variable<String>(kind);
    if (!nullToAbsent || customName != null) {
      map['custom_name'] = Variable<String>(customName);
    }
    if (!nullToAbsent || customUnit != null) {
      map['custom_unit'] = Variable<String>(customUnit);
    }
    if (!nullToAbsent || reason != null) {
      map['reason'] = Variable<String>(reason);
    }
    if (!nullToAbsent || priceCents != null) {
      map['price_cents'] = Variable<int>(priceCents);
    }
    map['units_per_container'] = Variable<int>(unitsPerContainer);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || archivedAt != null) {
      map['archived_at'] = Variable<DateTime>(archivedAt);
    }
    if (!nullToAbsent || quitAcknowledgedAt != null) {
      map['quit_acknowledged_at'] = Variable<DateTime>(quitAcknowledgedAt);
    }
    return map;
  }

  HabitsCompanion toCompanion(bool nullToAbsent) {
    return HabitsCompanion(
      id: Value(id),
      kind: Value(kind),
      customName: customName == null && nullToAbsent
          ? const Value.absent()
          : Value(customName),
      customUnit: customUnit == null && nullToAbsent
          ? const Value.absent()
          : Value(customUnit),
      reason: reason == null && nullToAbsent
          ? const Value.absent()
          : Value(reason),
      priceCents: priceCents == null && nullToAbsent
          ? const Value.absent()
          : Value(priceCents),
      unitsPerContainer: Value(unitsPerContainer),
      createdAt: Value(createdAt),
      archivedAt: archivedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(archivedAt),
      quitAcknowledgedAt: quitAcknowledgedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(quitAcknowledgedAt),
    );
  }

  factory HabitRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HabitRow(
      id: serializer.fromJson<int>(json['id']),
      kind: serializer.fromJson<String>(json['kind']),
      customName: serializer.fromJson<String?>(json['customName']),
      customUnit: serializer.fromJson<String?>(json['customUnit']),
      reason: serializer.fromJson<String?>(json['reason']),
      priceCents: serializer.fromJson<int?>(json['priceCents']),
      unitsPerContainer: serializer.fromJson<int>(json['unitsPerContainer']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      archivedAt: serializer.fromJson<DateTime?>(json['archivedAt']),
      quitAcknowledgedAt: serializer.fromJson<DateTime?>(
        json['quitAcknowledgedAt'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'kind': serializer.toJson<String>(kind),
      'customName': serializer.toJson<String?>(customName),
      'customUnit': serializer.toJson<String?>(customUnit),
      'reason': serializer.toJson<String?>(reason),
      'priceCents': serializer.toJson<int?>(priceCents),
      'unitsPerContainer': serializer.toJson<int>(unitsPerContainer),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'archivedAt': serializer.toJson<DateTime?>(archivedAt),
      'quitAcknowledgedAt': serializer.toJson<DateTime?>(quitAcknowledgedAt),
    };
  }

  HabitRow copyWith({
    int? id,
    String? kind,
    Value<String?> customName = const Value.absent(),
    Value<String?> customUnit = const Value.absent(),
    Value<String?> reason = const Value.absent(),
    Value<int?> priceCents = const Value.absent(),
    int? unitsPerContainer,
    DateTime? createdAt,
    Value<DateTime?> archivedAt = const Value.absent(),
    Value<DateTime?> quitAcknowledgedAt = const Value.absent(),
  }) => HabitRow(
    id: id ?? this.id,
    kind: kind ?? this.kind,
    customName: customName.present ? customName.value : this.customName,
    customUnit: customUnit.present ? customUnit.value : this.customUnit,
    reason: reason.present ? reason.value : this.reason,
    priceCents: priceCents.present ? priceCents.value : this.priceCents,
    unitsPerContainer: unitsPerContainer ?? this.unitsPerContainer,
    createdAt: createdAt ?? this.createdAt,
    archivedAt: archivedAt.present ? archivedAt.value : this.archivedAt,
    quitAcknowledgedAt: quitAcknowledgedAt.present
        ? quitAcknowledgedAt.value
        : this.quitAcknowledgedAt,
  );
  HabitRow copyWithCompanion(HabitsCompanion data) {
    return HabitRow(
      id: data.id.present ? data.id.value : this.id,
      kind: data.kind.present ? data.kind.value : this.kind,
      customName: data.customName.present
          ? data.customName.value
          : this.customName,
      customUnit: data.customUnit.present
          ? data.customUnit.value
          : this.customUnit,
      reason: data.reason.present ? data.reason.value : this.reason,
      priceCents: data.priceCents.present
          ? data.priceCents.value
          : this.priceCents,
      unitsPerContainer: data.unitsPerContainer.present
          ? data.unitsPerContainer.value
          : this.unitsPerContainer,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      archivedAt: data.archivedAt.present
          ? data.archivedAt.value
          : this.archivedAt,
      quitAcknowledgedAt: data.quitAcknowledgedAt.present
          ? data.quitAcknowledgedAt.value
          : this.quitAcknowledgedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HabitRow(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('customName: $customName, ')
          ..write('customUnit: $customUnit, ')
          ..write('reason: $reason, ')
          ..write('priceCents: $priceCents, ')
          ..write('unitsPerContainer: $unitsPerContainer, ')
          ..write('createdAt: $createdAt, ')
          ..write('archivedAt: $archivedAt, ')
          ..write('quitAcknowledgedAt: $quitAcknowledgedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    kind,
    customName,
    customUnit,
    reason,
    priceCents,
    unitsPerContainer,
    createdAt,
    archivedAt,
    quitAcknowledgedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HabitRow &&
          other.id == this.id &&
          other.kind == this.kind &&
          other.customName == this.customName &&
          other.customUnit == this.customUnit &&
          other.reason == this.reason &&
          other.priceCents == this.priceCents &&
          other.unitsPerContainer == this.unitsPerContainer &&
          other.createdAt == this.createdAt &&
          other.archivedAt == this.archivedAt &&
          other.quitAcknowledgedAt == this.quitAcknowledgedAt);
}

class HabitsCompanion extends UpdateCompanion<HabitRow> {
  final Value<int> id;
  final Value<String> kind;
  final Value<String?> customName;
  final Value<String?> customUnit;
  final Value<String?> reason;
  final Value<int?> priceCents;
  final Value<int> unitsPerContainer;
  final Value<DateTime> createdAt;
  final Value<DateTime?> archivedAt;
  final Value<DateTime?> quitAcknowledgedAt;
  const HabitsCompanion({
    this.id = const Value.absent(),
    this.kind = const Value.absent(),
    this.customName = const Value.absent(),
    this.customUnit = const Value.absent(),
    this.reason = const Value.absent(),
    this.priceCents = const Value.absent(),
    this.unitsPerContainer = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.archivedAt = const Value.absent(),
    this.quitAcknowledgedAt = const Value.absent(),
  });
  HabitsCompanion.insert({
    this.id = const Value.absent(),
    required String kind,
    this.customName = const Value.absent(),
    this.customUnit = const Value.absent(),
    this.reason = const Value.absent(),
    this.priceCents = const Value.absent(),
    this.unitsPerContainer = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.archivedAt = const Value.absent(),
    this.quitAcknowledgedAt = const Value.absent(),
  }) : kind = Value(kind);
  static Insertable<HabitRow> custom({
    Expression<int>? id,
    Expression<String>? kind,
    Expression<String>? customName,
    Expression<String>? customUnit,
    Expression<String>? reason,
    Expression<int>? priceCents,
    Expression<int>? unitsPerContainer,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? archivedAt,
    Expression<DateTime>? quitAcknowledgedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (kind != null) 'kind': kind,
      if (customName != null) 'custom_name': customName,
      if (customUnit != null) 'custom_unit': customUnit,
      if (reason != null) 'reason': reason,
      if (priceCents != null) 'price_cents': priceCents,
      if (unitsPerContainer != null) 'units_per_container': unitsPerContainer,
      if (createdAt != null) 'created_at': createdAt,
      if (archivedAt != null) 'archived_at': archivedAt,
      if (quitAcknowledgedAt != null)
        'quit_acknowledged_at': quitAcknowledgedAt,
    });
  }

  HabitsCompanion copyWith({
    Value<int>? id,
    Value<String>? kind,
    Value<String?>? customName,
    Value<String?>? customUnit,
    Value<String?>? reason,
    Value<int?>? priceCents,
    Value<int>? unitsPerContainer,
    Value<DateTime>? createdAt,
    Value<DateTime?>? archivedAt,
    Value<DateTime?>? quitAcknowledgedAt,
  }) {
    return HabitsCompanion(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      customName: customName ?? this.customName,
      customUnit: customUnit ?? this.customUnit,
      reason: reason ?? this.reason,
      priceCents: priceCents ?? this.priceCents,
      unitsPerContainer: unitsPerContainer ?? this.unitsPerContainer,
      createdAt: createdAt ?? this.createdAt,
      archivedAt: archivedAt ?? this.archivedAt,
      quitAcknowledgedAt: quitAcknowledgedAt ?? this.quitAcknowledgedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (customName.present) {
      map['custom_name'] = Variable<String>(customName.value);
    }
    if (customUnit.present) {
      map['custom_unit'] = Variable<String>(customUnit.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    if (priceCents.present) {
      map['price_cents'] = Variable<int>(priceCents.value);
    }
    if (unitsPerContainer.present) {
      map['units_per_container'] = Variable<int>(unitsPerContainer.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (archivedAt.present) {
      map['archived_at'] = Variable<DateTime>(archivedAt.value);
    }
    if (quitAcknowledgedAt.present) {
      map['quit_acknowledged_at'] = Variable<DateTime>(
        quitAcknowledgedAt.value,
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HabitsCompanion(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('customName: $customName, ')
          ..write('customUnit: $customUnit, ')
          ..write('reason: $reason, ')
          ..write('priceCents: $priceCents, ')
          ..write('unitsPerContainer: $unitsPerContainer, ')
          ..write('createdAt: $createdAt, ')
          ..write('archivedAt: $archivedAt, ')
          ..write('quitAcknowledgedAt: $quitAcknowledgedAt')
          ..write(')'))
        .toString();
  }
}

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
  static const VerificationMeta _habitIdMeta = const VerificationMeta(
    'habitId',
  );
  @override
  late final GeneratedColumn<int> habitId = GeneratedColumn<int>(
    'habit_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES habits (id)',
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
    habitId,
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
    if (data.containsKey('habit_id')) {
      context.handle(
        _habitIdMeta,
        habitId.isAcceptableOrUnknown(data['habit_id']!, _habitIdMeta),
      );
    } else if (isInserting) {
      context.missing(_habitIdMeta);
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
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {habitId, startDay},
  ];
  @override
  PlanRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlanRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      habitId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}habit_id'],
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
  final int habitId;

  /// LogicalDay in yyyy-mm-dd form.
  final String startDay;
  final int startLimit;

  /// LogicalDay in yyyy-mm-dd form; the limit is 0 from this day.
  final String quitDay;
  final DateTime createdAt;
  const PlanRow({
    required this.id,
    required this.habitId,
    required this.startDay,
    required this.startLimit,
    required this.quitDay,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['habit_id'] = Variable<int>(habitId);
    map['start_day'] = Variable<String>(startDay);
    map['start_limit'] = Variable<int>(startLimit);
    map['quit_day'] = Variable<String>(quitDay);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  PlansCompanion toCompanion(bool nullToAbsent) {
    return PlansCompanion(
      id: Value(id),
      habitId: Value(habitId),
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
      habitId: serializer.fromJson<int>(json['habitId']),
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
      'habitId': serializer.toJson<int>(habitId),
      'startDay': serializer.toJson<String>(startDay),
      'startLimit': serializer.toJson<int>(startLimit),
      'quitDay': serializer.toJson<String>(quitDay),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  PlanRow copyWith({
    int? id,
    int? habitId,
    String? startDay,
    int? startLimit,
    String? quitDay,
    DateTime? createdAt,
  }) => PlanRow(
    id: id ?? this.id,
    habitId: habitId ?? this.habitId,
    startDay: startDay ?? this.startDay,
    startLimit: startLimit ?? this.startLimit,
    quitDay: quitDay ?? this.quitDay,
    createdAt: createdAt ?? this.createdAt,
  );
  PlanRow copyWithCompanion(PlansCompanion data) {
    return PlanRow(
      id: data.id.present ? data.id.value : this.id,
      habitId: data.habitId.present ? data.habitId.value : this.habitId,
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
          ..write('habitId: $habitId, ')
          ..write('startDay: $startDay, ')
          ..write('startLimit: $startLimit, ')
          ..write('quitDay: $quitDay, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, habitId, startDay, startLimit, quitDay, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlanRow &&
          other.id == this.id &&
          other.habitId == this.habitId &&
          other.startDay == this.startDay &&
          other.startLimit == this.startLimit &&
          other.quitDay == this.quitDay &&
          other.createdAt == this.createdAt);
}

class PlansCompanion extends UpdateCompanion<PlanRow> {
  final Value<int> id;
  final Value<int> habitId;
  final Value<String> startDay;
  final Value<int> startLimit;
  final Value<String> quitDay;
  final Value<DateTime> createdAt;
  const PlansCompanion({
    this.id = const Value.absent(),
    this.habitId = const Value.absent(),
    this.startDay = const Value.absent(),
    this.startLimit = const Value.absent(),
    this.quitDay = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  PlansCompanion.insert({
    this.id = const Value.absent(),
    required int habitId,
    required String startDay,
    required int startLimit,
    required String quitDay,
    this.createdAt = const Value.absent(),
  }) : habitId = Value(habitId),
       startDay = Value(startDay),
       startLimit = Value(startLimit),
       quitDay = Value(quitDay);
  static Insertable<PlanRow> custom({
    Expression<int>? id,
    Expression<int>? habitId,
    Expression<String>? startDay,
    Expression<int>? startLimit,
    Expression<String>? quitDay,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (habitId != null) 'habit_id': habitId,
      if (startDay != null) 'start_day': startDay,
      if (startLimit != null) 'start_limit': startLimit,
      if (quitDay != null) 'quit_day': quitDay,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  PlansCompanion copyWith({
    Value<int>? id,
    Value<int>? habitId,
    Value<String>? startDay,
    Value<int>? startLimit,
    Value<String>? quitDay,
    Value<DateTime>? createdAt,
  }) {
    return PlansCompanion(
      id: id ?? this.id,
      habitId: habitId ?? this.habitId,
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
    if (habitId.present) {
      map['habit_id'] = Variable<int>(habitId.value);
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
          ..write('habitId: $habitId, ')
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
  static const VerificationMeta _habitIdMeta = const VerificationMeta(
    'habitId',
  );
  @override
  late final GeneratedColumn<int> habitId = GeneratedColumn<int>(
    'habit_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES habits (id)',
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
    habitId,
    loggedAt,
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
    if (data.containsKey('habit_id')) {
      context.handle(
        _habitIdMeta,
        habitId.isAcceptableOrUnknown(data['habit_id']!, _habitIdMeta),
      );
    } else if (isInserting) {
      context.missing(_habitIdMeta);
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
  HabitLogRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HabitLogRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      habitId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}habit_id'],
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
  $HabitLogsTable createAlias(String alias) {
    return $HabitLogsTable(attachedDatabase, alias);
  }
}

class HabitLogRow extends DataClass implements Insertable<HabitLogRow> {
  final int id;
  final int habitId;
  final DateTime loggedAt;

  /// Trigger.name, or null when skipped.
  final String? trigger;
  final String? note;
  final DateTime createdAt;
  const HabitLogRow({
    required this.id,
    required this.habitId,
    required this.loggedAt,
    this.trigger,
    this.note,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['habit_id'] = Variable<int>(habitId);
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

  HabitLogsCompanion toCompanion(bool nullToAbsent) {
    return HabitLogsCompanion(
      id: Value(id),
      habitId: Value(habitId),
      loggedAt: Value(loggedAt),
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
      habitId: serializer.fromJson<int>(json['habitId']),
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
      'habitId': serializer.toJson<int>(habitId),
      'loggedAt': serializer.toJson<DateTime>(loggedAt),
      'trigger': serializer.toJson<String?>(trigger),
      'note': serializer.toJson<String?>(note),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  HabitLogRow copyWith({
    int? id,
    int? habitId,
    DateTime? loggedAt,
    Value<String?> trigger = const Value.absent(),
    Value<String?> note = const Value.absent(),
    DateTime? createdAt,
  }) => HabitLogRow(
    id: id ?? this.id,
    habitId: habitId ?? this.habitId,
    loggedAt: loggedAt ?? this.loggedAt,
    trigger: trigger.present ? trigger.value : this.trigger,
    note: note.present ? note.value : this.note,
    createdAt: createdAt ?? this.createdAt,
  );
  HabitLogRow copyWithCompanion(HabitLogsCompanion data) {
    return HabitLogRow(
      id: data.id.present ? data.id.value : this.id,
      habitId: data.habitId.present ? data.habitId.value : this.habitId,
      loggedAt: data.loggedAt.present ? data.loggedAt.value : this.loggedAt,
      trigger: data.trigger.present ? data.trigger.value : this.trigger,
      note: data.note.present ? data.note.value : this.note,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HabitLogRow(')
          ..write('id: $id, ')
          ..write('habitId: $habitId, ')
          ..write('loggedAt: $loggedAt, ')
          ..write('trigger: $trigger, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, habitId, loggedAt, trigger, note, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HabitLogRow &&
          other.id == this.id &&
          other.habitId == this.habitId &&
          other.loggedAt == this.loggedAt &&
          other.trigger == this.trigger &&
          other.note == this.note &&
          other.createdAt == this.createdAt);
}

class HabitLogsCompanion extends UpdateCompanion<HabitLogRow> {
  final Value<int> id;
  final Value<int> habitId;
  final Value<DateTime> loggedAt;
  final Value<String?> trigger;
  final Value<String?> note;
  final Value<DateTime> createdAt;
  const HabitLogsCompanion({
    this.id = const Value.absent(),
    this.habitId = const Value.absent(),
    this.loggedAt = const Value.absent(),
    this.trigger = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  HabitLogsCompanion.insert({
    this.id = const Value.absent(),
    required int habitId,
    required DateTime loggedAt,
    this.trigger = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : habitId = Value(habitId),
       loggedAt = Value(loggedAt);
  static Insertable<HabitLogRow> custom({
    Expression<int>? id,
    Expression<int>? habitId,
    Expression<DateTime>? loggedAt,
    Expression<String>? trigger,
    Expression<String>? note,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (habitId != null) 'habit_id': habitId,
      if (loggedAt != null) 'logged_at': loggedAt,
      if (trigger != null) 'trigger': trigger,
      if (note != null) 'note': note,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  HabitLogsCompanion copyWith({
    Value<int>? id,
    Value<int>? habitId,
    Value<DateTime>? loggedAt,
    Value<String?>? trigger,
    Value<String?>? note,
    Value<DateTime>? createdAt,
  }) {
    return HabitLogsCompanion(
      id: id ?? this.id,
      habitId: habitId ?? this.habitId,
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
    if (habitId.present) {
      map['habit_id'] = Variable<int>(habitId.value);
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
    return (StringBuffer('HabitLogsCompanion(')
          ..write('id: $id, ')
          ..write('habitId: $habitId, ')
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
  static const VerificationMeta _logHintSeenMeta = const VerificationMeta(
    'logHintSeen',
  );
  @override
  late final GeneratedColumn<bool> logHintSeen = GeneratedColumn<bool>(
    'log_hint_seen',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("log_hint_seen" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
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
  static const VerificationMeta _wakeMinuteMeta = const VerificationMeta(
    'wakeMinute',
  );
  @override
  late final GeneratedColumn<int> wakeMinute = GeneratedColumn<int>(
    'wake_minute',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bedMinuteMeta = const VerificationMeta(
    'bedMinute',
  );
  @override
  late final GeneratedColumn<int> bedMinute = GeneratedColumn<int>(
    'bed_minute',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userName,
    dayResetHour,
    themePreference,
    accentIndex,
    appIcon,
    askForTrigger,
    triggerPromptIntroSeen,
    logHintSeen,
    currencySymbol,
    wakeMinute,
    bedMinute,
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
    if (data.containsKey('log_hint_seen')) {
      context.handle(
        _logHintSeenMeta,
        logHintSeen.isAcceptableOrUnknown(
          data['log_hint_seen']!,
          _logHintSeenMeta,
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
    if (data.containsKey('wake_minute')) {
      context.handle(
        _wakeMinuteMeta,
        wakeMinute.isAcceptableOrUnknown(data['wake_minute']!, _wakeMinuteMeta),
      );
    }
    if (data.containsKey('bed_minute')) {
      context.handle(
        _bedMinuteMeta,
        bedMinute.isAcceptableOrUnknown(data['bed_minute']!, _bedMinuteMeta),
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
      askForTrigger: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}ask_for_trigger'],
      )!,
      triggerPromptIntroSeen: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}trigger_prompt_intro_seen'],
      )!,
      logHintSeen: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}log_hint_seen'],
      )!,
      currencySymbol: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency_symbol'],
      )!,
      wakeMinute: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}wake_minute'],
      ),
      bedMinute: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}bed_minute'],
      ),
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
  final bool askForTrigger;
  final bool triggerPromptIntroSeen;

  /// True once the one-time "Hold + for more" hint was shown.
  final bool logHintSeen;
  final String currencySymbol;

  /// Wake and bed times in minutes after midnight; null until set.
  final int? wakeMinute;
  final int? bedMinute;
  const SettingsRow({
    required this.id,
    this.userName,
    required this.dayResetHour,
    required this.themePreference,
    required this.accentIndex,
    required this.appIcon,
    required this.askForTrigger,
    required this.triggerPromptIntroSeen,
    required this.logHintSeen,
    required this.currencySymbol,
    this.wakeMinute,
    this.bedMinute,
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
    map['ask_for_trigger'] = Variable<bool>(askForTrigger);
    map['trigger_prompt_intro_seen'] = Variable<bool>(triggerPromptIntroSeen);
    map['log_hint_seen'] = Variable<bool>(logHintSeen);
    map['currency_symbol'] = Variable<String>(currencySymbol);
    if (!nullToAbsent || wakeMinute != null) {
      map['wake_minute'] = Variable<int>(wakeMinute);
    }
    if (!nullToAbsent || bedMinute != null) {
      map['bed_minute'] = Variable<int>(bedMinute);
    }
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
      askForTrigger: Value(askForTrigger),
      triggerPromptIntroSeen: Value(triggerPromptIntroSeen),
      logHintSeen: Value(logHintSeen),
      currencySymbol: Value(currencySymbol),
      wakeMinute: wakeMinute == null && nullToAbsent
          ? const Value.absent()
          : Value(wakeMinute),
      bedMinute: bedMinute == null && nullToAbsent
          ? const Value.absent()
          : Value(bedMinute),
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
      askForTrigger: serializer.fromJson<bool>(json['askForTrigger']),
      triggerPromptIntroSeen: serializer.fromJson<bool>(
        json['triggerPromptIntroSeen'],
      ),
      logHintSeen: serializer.fromJson<bool>(json['logHintSeen']),
      currencySymbol: serializer.fromJson<String>(json['currencySymbol']),
      wakeMinute: serializer.fromJson<int?>(json['wakeMinute']),
      bedMinute: serializer.fromJson<int?>(json['bedMinute']),
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
      'askForTrigger': serializer.toJson<bool>(askForTrigger),
      'triggerPromptIntroSeen': serializer.toJson<bool>(triggerPromptIntroSeen),
      'logHintSeen': serializer.toJson<bool>(logHintSeen),
      'currencySymbol': serializer.toJson<String>(currencySymbol),
      'wakeMinute': serializer.toJson<int?>(wakeMinute),
      'bedMinute': serializer.toJson<int?>(bedMinute),
    };
  }

  SettingsRow copyWith({
    int? id,
    Value<String?> userName = const Value.absent(),
    int? dayResetHour,
    String? themePreference,
    int? accentIndex,
    String? appIcon,
    bool? askForTrigger,
    bool? triggerPromptIntroSeen,
    bool? logHintSeen,
    String? currencySymbol,
    Value<int?> wakeMinute = const Value.absent(),
    Value<int?> bedMinute = const Value.absent(),
  }) => SettingsRow(
    id: id ?? this.id,
    userName: userName.present ? userName.value : this.userName,
    dayResetHour: dayResetHour ?? this.dayResetHour,
    themePreference: themePreference ?? this.themePreference,
    accentIndex: accentIndex ?? this.accentIndex,
    appIcon: appIcon ?? this.appIcon,
    askForTrigger: askForTrigger ?? this.askForTrigger,
    triggerPromptIntroSeen:
        triggerPromptIntroSeen ?? this.triggerPromptIntroSeen,
    logHintSeen: logHintSeen ?? this.logHintSeen,
    currencySymbol: currencySymbol ?? this.currencySymbol,
    wakeMinute: wakeMinute.present ? wakeMinute.value : this.wakeMinute,
    bedMinute: bedMinute.present ? bedMinute.value : this.bedMinute,
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
      askForTrigger: data.askForTrigger.present
          ? data.askForTrigger.value
          : this.askForTrigger,
      triggerPromptIntroSeen: data.triggerPromptIntroSeen.present
          ? data.triggerPromptIntroSeen.value
          : this.triggerPromptIntroSeen,
      logHintSeen: data.logHintSeen.present
          ? data.logHintSeen.value
          : this.logHintSeen,
      currencySymbol: data.currencySymbol.present
          ? data.currencySymbol.value
          : this.currencySymbol,
      wakeMinute: data.wakeMinute.present
          ? data.wakeMinute.value
          : this.wakeMinute,
      bedMinute: data.bedMinute.present ? data.bedMinute.value : this.bedMinute,
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
          ..write('askForTrigger: $askForTrigger, ')
          ..write('triggerPromptIntroSeen: $triggerPromptIntroSeen, ')
          ..write('logHintSeen: $logHintSeen, ')
          ..write('currencySymbol: $currencySymbol, ')
          ..write('wakeMinute: $wakeMinute, ')
          ..write('bedMinute: $bedMinute')
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
    askForTrigger,
    triggerPromptIntroSeen,
    logHintSeen,
    currencySymbol,
    wakeMinute,
    bedMinute,
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
          other.askForTrigger == this.askForTrigger &&
          other.triggerPromptIntroSeen == this.triggerPromptIntroSeen &&
          other.logHintSeen == this.logHintSeen &&
          other.currencySymbol == this.currencySymbol &&
          other.wakeMinute == this.wakeMinute &&
          other.bedMinute == this.bedMinute);
}

class SettingsCompanion extends UpdateCompanion<SettingsRow> {
  final Value<int> id;
  final Value<String?> userName;
  final Value<int> dayResetHour;
  final Value<String> themePreference;
  final Value<int> accentIndex;
  final Value<String> appIcon;
  final Value<bool> askForTrigger;
  final Value<bool> triggerPromptIntroSeen;
  final Value<bool> logHintSeen;
  final Value<String> currencySymbol;
  final Value<int?> wakeMinute;
  final Value<int?> bedMinute;
  const SettingsCompanion({
    this.id = const Value.absent(),
    this.userName = const Value.absent(),
    this.dayResetHour = const Value.absent(),
    this.themePreference = const Value.absent(),
    this.accentIndex = const Value.absent(),
    this.appIcon = const Value.absent(),
    this.askForTrigger = const Value.absent(),
    this.triggerPromptIntroSeen = const Value.absent(),
    this.logHintSeen = const Value.absent(),
    this.currencySymbol = const Value.absent(),
    this.wakeMinute = const Value.absent(),
    this.bedMinute = const Value.absent(),
  });
  SettingsCompanion.insert({
    this.id = const Value.absent(),
    this.userName = const Value.absent(),
    this.dayResetHour = const Value.absent(),
    this.themePreference = const Value.absent(),
    this.accentIndex = const Value.absent(),
    this.appIcon = const Value.absent(),
    this.askForTrigger = const Value.absent(),
    this.triggerPromptIntroSeen = const Value.absent(),
    this.logHintSeen = const Value.absent(),
    this.currencySymbol = const Value.absent(),
    this.wakeMinute = const Value.absent(),
    this.bedMinute = const Value.absent(),
  });
  static Insertable<SettingsRow> custom({
    Expression<int>? id,
    Expression<String>? userName,
    Expression<int>? dayResetHour,
    Expression<String>? themePreference,
    Expression<int>? accentIndex,
    Expression<String>? appIcon,
    Expression<bool>? askForTrigger,
    Expression<bool>? triggerPromptIntroSeen,
    Expression<bool>? logHintSeen,
    Expression<String>? currencySymbol,
    Expression<int>? wakeMinute,
    Expression<int>? bedMinute,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userName != null) 'user_name': userName,
      if (dayResetHour != null) 'day_reset_hour': dayResetHour,
      if (themePreference != null) 'theme_preference': themePreference,
      if (accentIndex != null) 'accent_index': accentIndex,
      if (appIcon != null) 'app_icon': appIcon,
      if (askForTrigger != null) 'ask_for_trigger': askForTrigger,
      if (triggerPromptIntroSeen != null)
        'trigger_prompt_intro_seen': triggerPromptIntroSeen,
      if (logHintSeen != null) 'log_hint_seen': logHintSeen,
      if (currencySymbol != null) 'currency_symbol': currencySymbol,
      if (wakeMinute != null) 'wake_minute': wakeMinute,
      if (bedMinute != null) 'bed_minute': bedMinute,
    });
  }

  SettingsCompanion copyWith({
    Value<int>? id,
    Value<String?>? userName,
    Value<int>? dayResetHour,
    Value<String>? themePreference,
    Value<int>? accentIndex,
    Value<String>? appIcon,
    Value<bool>? askForTrigger,
    Value<bool>? triggerPromptIntroSeen,
    Value<bool>? logHintSeen,
    Value<String>? currencySymbol,
    Value<int?>? wakeMinute,
    Value<int?>? bedMinute,
  }) {
    return SettingsCompanion(
      id: id ?? this.id,
      userName: userName ?? this.userName,
      dayResetHour: dayResetHour ?? this.dayResetHour,
      themePreference: themePreference ?? this.themePreference,
      accentIndex: accentIndex ?? this.accentIndex,
      appIcon: appIcon ?? this.appIcon,
      askForTrigger: askForTrigger ?? this.askForTrigger,
      triggerPromptIntroSeen:
          triggerPromptIntroSeen ?? this.triggerPromptIntroSeen,
      logHintSeen: logHintSeen ?? this.logHintSeen,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      wakeMinute: wakeMinute ?? this.wakeMinute,
      bedMinute: bedMinute ?? this.bedMinute,
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
    if (askForTrigger.present) {
      map['ask_for_trigger'] = Variable<bool>(askForTrigger.value);
    }
    if (triggerPromptIntroSeen.present) {
      map['trigger_prompt_intro_seen'] = Variable<bool>(
        triggerPromptIntroSeen.value,
      );
    }
    if (logHintSeen.present) {
      map['log_hint_seen'] = Variable<bool>(logHintSeen.value);
    }
    if (currencySymbol.present) {
      map['currency_symbol'] = Variable<String>(currencySymbol.value);
    }
    if (wakeMinute.present) {
      map['wake_minute'] = Variable<int>(wakeMinute.value);
    }
    if (bedMinute.present) {
      map['bed_minute'] = Variable<int>(bedMinute.value);
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
          ..write('askForTrigger: $askForTrigger, ')
          ..write('triggerPromptIntroSeen: $triggerPromptIntroSeen, ')
          ..write('logHintSeen: $logHintSeen, ')
          ..write('currencySymbol: $currencySymbol, ')
          ..write('wakeMinute: $wakeMinute, ')
          ..write('bedMinute: $bedMinute')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $HabitsTable habits = $HabitsTable(this);
  late final $PlansTable plans = $PlansTable(this);
  late final $HabitLogsTable habitLogs = $HabitLogsTable(this);
  late final $SettingsTable settings = $SettingsTable(this);
  late final Index idxHabitLogsLoggedAt = Index(
    'idx_habit_logs_logged_at',
    'CREATE INDEX idx_habit_logs_logged_at ON habit_logs (logged_at)',
  );
  late final Index idxHabitLogsHabitIdLoggedAt = Index(
    'idx_habit_logs_habit_id_logged_at',
    'CREATE INDEX idx_habit_logs_habit_id_logged_at ON habit_logs (habit_id, logged_at)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    habits,
    plans,
    habitLogs,
    settings,
    idxHabitLogsLoggedAt,
    idxHabitLogsHabitIdLoggedAt,
  ];
}

typedef $$HabitsTableCreateCompanionBuilder = HabitsCompanion Function({
  Value<int> id,
  required String kind,
  Value<String?> customName,
  Value<String?> customUnit,
  Value<String?> reason,
  Value<int?> priceCents,
  Value<int> unitsPerContainer,
  Value<DateTime> createdAt,
  Value<DateTime?> archivedAt,
  Value<DateTime?> quitAcknowledgedAt,
});
typedef $$HabitsTableUpdateCompanionBuilder = HabitsCompanion Function({
  Value<int> id,
  Value<String> kind,
  Value<String?> customName,
  Value<String?> customUnit,
  Value<String?> reason,
  Value<int?> priceCents,
  Value<int> unitsPerContainer,
  Value<DateTime> createdAt,
  Value<DateTime?> archivedAt,
  Value<DateTime?> quitAcknowledgedAt,
});

final class $$HabitsTableReferences
    extends BaseReferences<_$AppDatabase, $HabitsTable, HabitRow> {
  $$HabitsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$PlansTable, List<PlanRow>> _plansRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.plans,
    aliasName: 'habits__id__plans__habit_id',
  );

  $$PlansTableProcessedTableManager get plansRefs {
    final manager = $$PlansTableTableManager(
      $_db,
      $_db.plans,
    ).filter((f) => f.habitId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_plansRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$HabitLogsTable, List<HabitLogRow>>
  _habitLogsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.habitLogs,
    aliasName: 'habits__id__habit_logs__habit_id',
  );

  $$HabitLogsTableProcessedTableManager get habitLogsRefs {
    final manager = $$HabitLogsTableTableManager(
      $_db,
      $_db.habitLogs,
    ).filter((f) => f.habitId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_habitLogsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$HabitsTableFilterComposer
    extends Composer<_$AppDatabase, $HabitsTable> {
  $$HabitsTableFilterComposer({
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

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customName => $composableBuilder(
    column: $table.customName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customUnit => $composableBuilder(
    column: $table.customUnit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reason => $composableBuilder(
    column: $table.reason,
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

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get quitAcknowledgedAt => $composableBuilder(
    column: $table.quitAcknowledgedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> plansRefs(
    Expression<bool> Function($$PlansTableFilterComposer f) f,
  ) {
    final $$PlansTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.plans,
      getReferencedColumn: (t) => t.habitId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlansTableFilterComposer(
            $db: $db,
            $table: $db.plans,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> habitLogsRefs(
    Expression<bool> Function($$HabitLogsTableFilterComposer f) f,
  ) {
    final $$HabitLogsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.habitLogs,
      getReferencedColumn: (t) => t.habitId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HabitLogsTableFilterComposer(
            $db: $db,
            $table: $db.habitLogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$HabitsTableOrderingComposer
    extends Composer<_$AppDatabase, $HabitsTable> {
  $$HabitsTableOrderingComposer({
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

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customName => $composableBuilder(
    column: $table.customName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customUnit => $composableBuilder(
    column: $table.customUnit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reason => $composableBuilder(
    column: $table.reason,
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

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get quitAcknowledgedAt => $composableBuilder(
    column: $table.quitAcknowledgedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$HabitsTableAnnotationComposer
    extends Composer<_$AppDatabase, $HabitsTable> {
  $$HabitsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get customName => $composableBuilder(
    column: $table.customName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get customUnit => $composableBuilder(
    column: $table.customUnit,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => column);

  GeneratedColumn<int> get priceCents => $composableBuilder(
    column: $table.priceCents,
    builder: (column) => column,
  );

  GeneratedColumn<int> get unitsPerContainer => $composableBuilder(
    column: $table.unitsPerContainer,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get quitAcknowledgedAt => $composableBuilder(
    column: $table.quitAcknowledgedAt,
    builder: (column) => column,
  );

  Expression<T> plansRefs<T extends Object>(
    Expression<T> Function($$PlansTableAnnotationComposer a) f,
  ) {
    final $$PlansTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.plans,
      getReferencedColumn: (t) => t.habitId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlansTableAnnotationComposer(
            $db: $db,
            $table: $db.plans,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> habitLogsRefs<T extends Object>(
    Expression<T> Function($$HabitLogsTableAnnotationComposer a) f,
  ) {
    final $$HabitLogsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.habitLogs,
      getReferencedColumn: (t) => t.habitId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HabitLogsTableAnnotationComposer(
            $db: $db,
            $table: $db.habitLogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$HabitsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $HabitsTable,
          HabitRow,
          $$HabitsTableFilterComposer,
          $$HabitsTableOrderingComposer,
          $$HabitsTableAnnotationComposer,
          $$HabitsTableCreateCompanionBuilder,
          $$HabitsTableUpdateCompanionBuilder,
          (HabitRow, $$HabitsTableReferences),
          HabitRow,
          PrefetchHooks Function({bool plansRefs, bool habitLogsRefs})
        > {
  $$HabitsTableTableManager(_$AppDatabase db, $HabitsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HabitsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HabitsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HabitsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String?> customName = const Value.absent(),
                Value<String?> customUnit = const Value.absent(),
                Value<String?> reason = const Value.absent(),
                Value<int?> priceCents = const Value.absent(),
                Value<int> unitsPerContainer = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> archivedAt = const Value.absent(),
                Value<DateTime?> quitAcknowledgedAt = const Value.absent(),
              }) => HabitsCompanion(
                id: id,
                kind: kind,
                customName: customName,
                customUnit: customUnit,
                reason: reason,
                priceCents: priceCents,
                unitsPerContainer: unitsPerContainer,
                createdAt: createdAt,
                archivedAt: archivedAt,
                quitAcknowledgedAt: quitAcknowledgedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String kind,
                Value<String?> customName = const Value.absent(),
                Value<String?> customUnit = const Value.absent(),
                Value<String?> reason = const Value.absent(),
                Value<int?> priceCents = const Value.absent(),
                Value<int> unitsPerContainer = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> archivedAt = const Value.absent(),
                Value<DateTime?> quitAcknowledgedAt = const Value.absent(),
              }) => HabitsCompanion.insert(
                id: id,
                kind: kind,
                customName: customName,
                customUnit: customUnit,
                reason: reason,
                priceCents: priceCents,
                unitsPerContainer: unitsPerContainer,
                createdAt: createdAt,
                archivedAt: archivedAt,
                quitAcknowledgedAt: quitAcknowledgedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$HabitsTable, HabitRow>(table),
                  $$HabitsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({plansRefs = false, habitLogsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (plansRefs) db.plans,
                if (habitLogsRefs) db.habitLogs,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (plansRefs)
                    await $_getPrefetchedData<HabitRow, $HabitsTable, PlanRow>(
                      currentTable: table,
                      referencedTable: $$HabitsTableReferences._plansRefsTable(
                        db,
                      ),
                      managerFromTypedResult: (p0) =>
                          $$HabitsTableReferences(db, table, p0).plansRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.habitId == item.id),
                      typedResults: items,
                    ),
                  if (habitLogsRefs)
                    await $_getPrefetchedData<
                      HabitRow,
                      $HabitsTable,
                      HabitLogRow
                    >(
                      currentTable: table,
                      referencedTable: $$HabitsTableReferences
                          ._habitLogsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$HabitsTableReferences(db, table, p0).habitLogsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.habitId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$HabitsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $HabitsTable,
      HabitRow,
      $$HabitsTableFilterComposer,
      $$HabitsTableOrderingComposer,
      $$HabitsTableAnnotationComposer,
      $$HabitsTableCreateCompanionBuilder,
      $$HabitsTableUpdateCompanionBuilder,
      (HabitRow, $$HabitsTableReferences),
      HabitRow,
      PrefetchHooks Function({bool plansRefs, bool habitLogsRefs})
    >;
typedef $$PlansTableCreateCompanionBuilder = PlansCompanion Function({
  Value<int> id,
  required int habitId,
  required String startDay,
  required int startLimit,
  required String quitDay,
  Value<DateTime> createdAt,
});
typedef $$PlansTableUpdateCompanionBuilder = PlansCompanion Function({
  Value<int> id,
  Value<int> habitId,
  Value<String> startDay,
  Value<int> startLimit,
  Value<String> quitDay,
  Value<DateTime> createdAt,
});

final class $$PlansTableReferences
    extends BaseReferences<_$AppDatabase, $PlansTable, PlanRow> {
  $$PlansTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $HabitsTable _habitIdTable(_$AppDatabase db) =>
      db.habits.createAlias('plans__habit_id__habits__id');

  $$HabitsTableProcessedTableManager get habitId {
    final $_column = $_itemColumn<int>('habit_id')!;

    final manager = $$HabitsTableTableManager(
      $_db,
      $_db.habits,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_habitIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

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

  $$HabitsTableFilterComposer get habitId {
    final $$HabitsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.habitId,
      referencedTable: $db.habits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HabitsTableFilterComposer(
            $db: $db,
            $table: $db.habits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
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

  $$HabitsTableOrderingComposer get habitId {
    final $$HabitsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.habitId,
      referencedTable: $db.habits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HabitsTableOrderingComposer(
            $db: $db,
            $table: $db.habits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
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

  $$HabitsTableAnnotationComposer get habitId {
    final $$HabitsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.habitId,
      referencedTable: $db.habits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HabitsTableAnnotationComposer(
            $db: $db,
            $table: $db.habits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
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
          (PlanRow, $$PlansTableReferences),
          PlanRow,
          PrefetchHooks Function({bool habitId})
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
                Value<int> habitId = const Value.absent(),
                Value<String> startDay = const Value.absent(),
                Value<int> startLimit = const Value.absent(),
                Value<String> quitDay = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => PlansCompanion(
                id: id,
                habitId: habitId,
                startDay: startDay,
                startLimit: startLimit,
                quitDay: quitDay,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int habitId,
                required String startDay,
                required int startLimit,
                required String quitDay,
                Value<DateTime> createdAt = const Value.absent(),
              }) => PlansCompanion.insert(
                id: id,
                habitId: habitId,
                startDay: startDay,
                startLimit: startLimit,
                quitDay: quitDay,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PlansTable, PlanRow>(table),
                  $$PlansTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({habitId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (habitId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.habitId,
                        referencedTable: $$PlansTableReferences._habitIdTable(
                          db,
                        ),
                        referencedColumn: $$PlansTableReferences
                            ._habitIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
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
      (PlanRow, $$PlansTableReferences),
      PlanRow,
      PrefetchHooks Function({bool habitId})
    >;
typedef $$HabitLogsTableCreateCompanionBuilder = HabitLogsCompanion Function({
  Value<int> id,
  required int habitId,
  required DateTime loggedAt,
  Value<String?> trigger,
  Value<String?> note,
  Value<DateTime> createdAt,
});
typedef $$HabitLogsTableUpdateCompanionBuilder = HabitLogsCompanion Function({
  Value<int> id,
  Value<int> habitId,
  Value<DateTime> loggedAt,
  Value<String?> trigger,
  Value<String?> note,
  Value<DateTime> createdAt,
});

final class $$HabitLogsTableReferences
    extends BaseReferences<_$AppDatabase, $HabitLogsTable, HabitLogRow> {
  $$HabitLogsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $HabitsTable _habitIdTable(_$AppDatabase db) =>
      db.habits.createAlias('habit_logs__habit_id__habits__id');

  $$HabitsTableProcessedTableManager get habitId {
    final $_column = $_itemColumn<int>('habit_id')!;

    final manager = $$HabitsTableTableManager(
      $_db,
      $_db.habits,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_habitIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

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

  $$HabitsTableFilterComposer get habitId {
    final $$HabitsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.habitId,
      referencedTable: $db.habits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HabitsTableFilterComposer(
            $db: $db,
            $table: $db.habits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
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

  $$HabitsTableOrderingComposer get habitId {
    final $$HabitsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.habitId,
      referencedTable: $db.habits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HabitsTableOrderingComposer(
            $db: $db,
            $table: $db.habits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
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

  GeneratedColumn<String> get trigger =>
      $composableBuilder(column: $table.trigger, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$HabitsTableAnnotationComposer get habitId {
    final $$HabitsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.habitId,
      referencedTable: $db.habits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HabitsTableAnnotationComposer(
            $db: $db,
            $table: $db.habits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
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
          (HabitLogRow, $$HabitLogsTableReferences),
          HabitLogRow,
          PrefetchHooks Function({bool habitId})
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
                Value<int> habitId = const Value.absent(),
                Value<DateTime> loggedAt = const Value.absent(),
                Value<String?> trigger = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => HabitLogsCompanion(
                id: id,
                habitId: habitId,
                loggedAt: loggedAt,
                trigger: trigger,
                note: note,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int habitId,
                required DateTime loggedAt,
                Value<String?> trigger = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => HabitLogsCompanion.insert(
                id: id,
                habitId: habitId,
                loggedAt: loggedAt,
                trigger: trigger,
                note: note,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$HabitLogsTable, HabitLogRow>(table),
                  $$HabitLogsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({habitId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (habitId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.habitId,
                        referencedTable: $$HabitLogsTableReferences
                            ._habitIdTable(db),
                        referencedColumn: $$HabitLogsTableReferences
                            ._habitIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
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
      (HabitLogRow, $$HabitLogsTableReferences),
      HabitLogRow,
      PrefetchHooks Function({bool habitId})
    >;
typedef $$SettingsTableCreateCompanionBuilder = SettingsCompanion Function({
  Value<int> id,
  Value<String?> userName,
  Value<int> dayResetHour,
  Value<String> themePreference,
  Value<int> accentIndex,
  Value<String> appIcon,
  Value<bool> askForTrigger,
  Value<bool> triggerPromptIntroSeen,
  Value<bool> logHintSeen,
  Value<String> currencySymbol,
  Value<int?> wakeMinute,
  Value<int?> bedMinute,
});
typedef $$SettingsTableUpdateCompanionBuilder = SettingsCompanion Function({
  Value<int> id,
  Value<String?> userName,
  Value<int> dayResetHour,
  Value<String> themePreference,
  Value<int> accentIndex,
  Value<String> appIcon,
  Value<bool> askForTrigger,
  Value<bool> triggerPromptIntroSeen,
  Value<bool> logHintSeen,
  Value<String> currencySymbol,
  Value<int?> wakeMinute,
  Value<int?> bedMinute,
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

  ColumnFilters<bool> get askForTrigger => $composableBuilder(
    column: $table.askForTrigger,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get triggerPromptIntroSeen => $composableBuilder(
    column: $table.triggerPromptIntroSeen,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get logHintSeen => $composableBuilder(
    column: $table.logHintSeen,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currencySymbol => $composableBuilder(
    column: $table.currencySymbol,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get wakeMinute => $composableBuilder(
    column: $table.wakeMinute,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get bedMinute => $composableBuilder(
    column: $table.bedMinute,
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

  ColumnOrderings<bool> get askForTrigger => $composableBuilder(
    column: $table.askForTrigger,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get triggerPromptIntroSeen => $composableBuilder(
    column: $table.triggerPromptIntroSeen,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get logHintSeen => $composableBuilder(
    column: $table.logHintSeen,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currencySymbol => $composableBuilder(
    column: $table.currencySymbol,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get wakeMinute => $composableBuilder(
    column: $table.wakeMinute,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get bedMinute => $composableBuilder(
    column: $table.bedMinute,
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

  GeneratedColumn<bool> get askForTrigger => $composableBuilder(
    column: $table.askForTrigger,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get triggerPromptIntroSeen => $composableBuilder(
    column: $table.triggerPromptIntroSeen,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get logHintSeen => $composableBuilder(
    column: $table.logHintSeen,
    builder: (column) => column,
  );

  GeneratedColumn<String> get currencySymbol => $composableBuilder(
    column: $table.currencySymbol,
    builder: (column) => column,
  );

  GeneratedColumn<int> get wakeMinute => $composableBuilder(
    column: $table.wakeMinute,
    builder: (column) => column,
  );

  GeneratedColumn<int> get bedMinute =>
      $composableBuilder(column: $table.bedMinute, builder: (column) => column);
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
                Value<bool> askForTrigger = const Value.absent(),
                Value<bool> triggerPromptIntroSeen = const Value.absent(),
                Value<bool> logHintSeen = const Value.absent(),
                Value<String> currencySymbol = const Value.absent(),
                Value<int?> wakeMinute = const Value.absent(),
                Value<int?> bedMinute = const Value.absent(),
              }) => SettingsCompanion(
                id: id,
                userName: userName,
                dayResetHour: dayResetHour,
                themePreference: themePreference,
                accentIndex: accentIndex,
                appIcon: appIcon,
                askForTrigger: askForTrigger,
                triggerPromptIntroSeen: triggerPromptIntroSeen,
                logHintSeen: logHintSeen,
                currencySymbol: currencySymbol,
                wakeMinute: wakeMinute,
                bedMinute: bedMinute,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> userName = const Value.absent(),
                Value<int> dayResetHour = const Value.absent(),
                Value<String> themePreference = const Value.absent(),
                Value<int> accentIndex = const Value.absent(),
                Value<String> appIcon = const Value.absent(),
                Value<bool> askForTrigger = const Value.absent(),
                Value<bool> triggerPromptIntroSeen = const Value.absent(),
                Value<bool> logHintSeen = const Value.absent(),
                Value<String> currencySymbol = const Value.absent(),
                Value<int?> wakeMinute = const Value.absent(),
                Value<int?> bedMinute = const Value.absent(),
              }) => SettingsCompanion.insert(
                id: id,
                userName: userName,
                dayResetHour: dayResetHour,
                themePreference: themePreference,
                accentIndex: accentIndex,
                appIcon: appIcon,
                askForTrigger: askForTrigger,
                triggerPromptIntroSeen: triggerPromptIntroSeen,
                logHintSeen: logHintSeen,
                currencySymbol: currencySymbol,
                wakeMinute: wakeMinute,
                bedMinute: bedMinute,
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
  $$HabitsTableTableManager get habits =>
      $$HabitsTableTableManager(_db, _db.habits);
  $$PlansTableTableManager get plans =>
      $$PlansTableTableManager(_db, _db.plans);
  $$HabitLogsTableTableManager get habitLogs =>
      $$HabitLogsTableTableManager(_db, _db.habitLogs);
  $$SettingsTableTableManager get settings =>
      $$SettingsTableTableManager(_db, _db.settings);
}
