import 'package:exhale/core/data/storage_guard.dart';
import 'package:exhale/core/di/injection_container.dart';
import 'package:exhale/core/domain/error/failure.dart';
import 'package:exhale/core/domain/result/result.dart';
import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/core/presentation/failure_message.dart';
import 'package:exhale/core/theme/app_spacing.dart';
import 'package:exhale/core/widgets/app_sheet.dart';
import 'package:exhale/features/plan/domain/entities/plan_draft.dart';
import 'package:exhale/features/settings/domain/entities/app_settings.dart';
import 'package:exhale/features/settings/domain/repositories/settings_repository.dart';
import 'package:exhale/features/settings/domain/usecases/save_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fixed_clock.dart';
import '../../helpers/pump_app.dart';

void main() {
  final today = LogicalDay(2026, 10, 29);

  setUp(() => setUpTestDependencies(FixedClock(DateTime(2026, 10, 29, 9))));
  tearDown(InjectionContainer.reset);

  Future<void> openSettings(WidgetTester tester) async {
    await seedHabit(
      PlanDraft(startDay: today, startLimit: 8, quitDay: today.addDays(56)),
    );
    await tester.pumpAppPastSplash();
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
  }

  testWidgets('Your day shows Not set, then the saved times', (tester) async {
    await openSettings(tester);
    expect(find.text('Your day'), findsOneWidget);
    expect(find.text('Not set'), findsOneWidget);

    await tester.scrollAndTap(find.text('Your day'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Not set'), findsNothing);
    expect(find.text('7:30 AM – 11:30 PM'), findsOneWidget);
    await tester.disposeApp();
  });

  testWidgets('the Your day sheet insets its content', (tester) async {
    await openSettings(tester);
    await tester.scrollAndTap(find.text('Your day'));
    await tester.pumpAndSettle();

    final frame = find.byType(AppSheetFrame);
    final save = find.widgetWithText(FilledButton, 'Save');
    expect(
      tester.getTopLeft(save).dx - tester.getTopLeft(frame).dx,
      AppSpacing.lg,
    );
    expect(
      tester.getBottomRight(frame).dy - tester.getBottomRight(save).dy,
      AppSpacing.lg,
    );
    await tester.disposeApp();
  });

  testWidgets('a failed save stays open, says so, and can be retried', (
    tester,
  ) async {
    final real = sl<SettingsRepository>();
    sl
      ..unregister<SaveSettings>()
      ..registerSingleton<SaveSettings>(
        SaveSettings(_FailOnceSettingsRepository(real)),
      );
    await openSettings(tester);
    await tester.scrollAndTap(find.text('Your day'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(AppSheetFrame),
        matching: find.text(failureMessage(const StorageFailure())),
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.byType(AppSheetFrame), findsNothing);
    expect(find.text('7:30 AM – 11:30 PM'), findsOneWidget);
    await tester.disposeApp();
  });

  testWidgets('Your day opens on the stored times', (tester) async {
    final repository = sl<SettingsRepository>();
    final current = await repository.get() as Success<AppSettings>;
    await repository.save(
      current.value.copyWith(wakeMinute: () => 360, bedMinute: () => 60),
    );

    await openSettings(tester);
    expect(find.text('6:00 AM – 1:00 AM'), findsOneWidget);

    await tester.scrollAndTap(find.text('Your day'));
    await tester.pumpAndSettle();

    expect(find.text('6:00 AM'), findsOneWidget);
    expect(find.text('1:00 AM'), findsOneWidget);
    await tester.disposeApp();
  });
}

/// The real repository, except the first [save] fails as storage would.
class _FailOnceSettingsRepository implements SettingsRepository {
  _FailOnceSettingsRepository(this._real);

  final SettingsRepository _real;
  bool _failed = false;

  @override
  Stream<AppSettings> watch() => _real.watch();

  @override
  Future<Result<AppSettings>> get() => _real.get();

  @override
  Future<Result<void>> save(AppSettings settings) {
    if (_failed) return _real.save(settings);
    _failed = true;
    return guardStorage<void>(
      'FailOnceSettingsRepository',
      () async => throw const FormatException('disk full'),
    );
  }
}
