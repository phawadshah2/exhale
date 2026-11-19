import 'package:exhale/core/data/storage_guard.dart';
import 'package:exhale/core/di/injection_container.dart';
import 'package:exhale/core/domain/error/failure.dart';
import 'package:exhale/core/domain/result/result.dart';
import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/core/platform/native_ui.dart';
import 'package:exhale/core/presentation/failure_message.dart';
import 'package:exhale/core/theme/app_palette.dart';
import 'package:exhale/core/theme/app_spacing.dart';
import 'package:exhale/core/widgets/app_sheet.dart';
import 'package:exhale/features/paywall/presentation/paywall_copy.dart';
import 'package:exhale/features/plan/domain/entities/plan_draft.dart';
import 'package:exhale/features/settings/domain/entities/app_links.dart';
import 'package:exhale/features/settings/domain/entities/app_settings.dart';
import 'package:exhale/features/settings/domain/repositories/about_launcher.dart';
import 'package:exhale/features/settings/domain/repositories/settings_repository.dart';
import 'package:exhale/features/settings/domain/usecases/save_settings.dart';
import 'package:exhale/features/settings/presentation/pages/settings_page.dart';
import 'package:exhale/features/settings/presentation/providers/settings_providers.dart';
import 'package:exhale/features/settings/presentation/settings_copy.dart';
import 'package:exhale/features/settings/presentation/widgets/accent_picker.dart';
import 'package:exhale/features/settings/presentation/widgets/settings_row.dart';
import 'package:exhale/features/settings/presentation/widgets/settings_tile.dart';
import 'package:exhale/features/settings/presentation/widgets/theme_preference_control.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_about_launcher.dart';
import '../../helpers/fixed_clock.dart';
import '../../helpers/pump_app.dart';

void main() {
  final today = LogicalDay(2026, 10, 29);

  setUp(() => setUpTestDependencies(FixedClock(DateTime(2026, 10, 29, 9))));
  tearDown(InjectionContainer.reset);

  final links = AboutLinks(
    privacyPolicy: Uri.parse('https://example.com/privacy'),
    terms: Uri.parse('https://example.com/terms'),
    feedbackEmail: 'hello@example.com',
  );

  Future<void> openSettings(
    WidgetTester tester, {
    double width = 390,
    double height = 2400,
    List<Override> overrides = const [],
  }) async {
    await seedHabit(
      PlanDraft(startDay: today, startLimit: 8, quitDay: today.addDays(56)),
    );
    await tester.pumpAppPastSplash(
      width: width,
      height: height,
      overrides: overrides,
    );
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
  }

  FakeAboutLauncher about() => sl<AboutLauncher>() as FakeAboutLauncher;

  Finder row(String label) => find.widgetWithText(SettingsRow, label);

  final awakeNotSet = find.descendant(
    of: row(SettingsCopy.awake),
    matching: find.text('Not set'),
  );

  testWidgets('sections in order', (tester) async {
    await openSettings(tester);
    final labels = [
      'Settings',
      'Smoking plan',
      SettingsCopy.editPlan,
      SettingsCopy.yourDay.toUpperCase(),
      SettingsCopy.logging.toUpperCase(),
      SettingsCopy.lockScreen.toUpperCase(),
      SettingsCopy.appearance.toUpperCase(),
      SettingsCopy.about.toUpperCase(),
      'Exhale 0.1.0',
    ];
    final tops = [for (final l in labels) tester.getTopLeft(find.text(l)).dy];
    for (var i = 1; i < tops.length; i++) {
      expect(tops[i], greaterThan(tops[i - 1]), reason: labels[i]);
    }
    final tiles = find.byType(SettingsTile);
    expect(tiles, findsNWidgets(2));
    expect(tester.getTopLeft(tiles.first).dy, tester.getTopLeft(tiles.last).dy);
    await tester.disposeApp();
  });

  testWidgets('the subscription tile opens the sheet', (tester) async {
    await openSettings(tester);
    await tester.scrollAndTap(find.text(PaywallCopy.yoursForGood));
    await tester.pumpAndSettle();
    expect(find.text(PaywallCopy.lifetimeTitle), findsOneWidget);
    await tester.disposeApp();
  });

  testWidgets('no Restore on the main list', (tester) async {
    await openSettings(tester);
    expect(find.text(PaywallCopy.restorePurchases), findsNothing);
    await tester.disposeApp();
  });

  testWidgets('Awake opens Your day', (tester) async {
    await openSettings(tester);
    expect(awakeNotSet, findsOneWidget);

    await tester.scrollAndTap(row(SettingsCopy.awake));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(awakeNotSet, findsNothing);
    expect(find.text('7:30 AM – 11:30 PM'), findsOneWidget);
    await tester.disposeApp();
  });

  testWidgets('the Your day sheet insets its content', (tester) async {
    await openSettings(tester);
    await tester.scrollAndTap(row(SettingsCopy.awake));
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
    await tester.scrollAndTap(row(SettingsCopy.awake));
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

    await tester.scrollAndTap(row(SettingsCopy.awake));
    await tester.pumpAndSettle();

    expect(find.text('6:00 AM'), findsOneWidget);
    expect(find.text('1:00 AM'), findsOneWidget);
    await tester.disposeApp();
  });

  Future<AppSettings> stored(WidgetTester tester) async {
    final result = await tester.runAsync(sl<SettingsRepository>().get);
    return (result! as Success<AppSettings>).value;
  }

  CupertinoSwitch switchIn(WidgetTester tester, String label) =>
      tester.widget<CupertinoSwitch>(
        find.descendant(of: row(label), matching: find.byType(CupertinoSwitch)),
      );

  testWidgets('ask what set it off is stored', (tester) async {
    await openSettings(tester);
    final before = switchIn(tester, SettingsCopy.askTrigger).value;

    await tester.scrollAndTap(
      find.descendant(
        of: row(SettingsCopy.askTrigger),
        matching: find.byType(CupertinoSwitch),
      ),
    );
    await tester.pumpAndSettle();

    expect(switchIn(tester, SettingsCopy.askTrigger).value, !before);
    expect((await stored(tester)).askForTrigger, !before);
    await tester.disposeApp();
  });

  testWidgets('the Lock Screen switch is stored', (tester) async {
    await openSettings(tester);
    expect(switchIn(tester, SettingsCopy.lockScreenCountdown).value, isTrue);

    await tester.scrollAndTap(
      find.descendant(
        of: row(SettingsCopy.lockScreenCountdown),
        matching: find.byType(CupertinoSwitch),
      ),
    );
    await tester.pumpAndSettle();

    expect(switchIn(tester, SettingsCopy.lockScreenCountdown).value, isFalse);
    expect((await stored(tester)).showLiveActivity, isFalse);
    await tester.disposeApp();
  });

  testWidgets('Appearance rows open one sheet with theme and accent', (
    tester,
  ) async {
    await openSettings(tester);
    expect(
      find.descendant(
        of: row(SettingsCopy.theme),
        matching: find.text('Light'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: row(SettingsCopy.accent),
        matching: find.text(
          AppPalette.accentAt(AppPalette.defaultAccentIndex).name,
        ),
      ),
      findsOneWidget,
    );

    for (final label in [SettingsCopy.theme, SettingsCopy.accent]) {
      await tester.scrollAndTap(row(label));
      await tester.pumpAndSettle();
      final sheet = find.byType(AppSheetFrame);
      expect(
        find.descendant(
          of: sheet,
          matching: find.byType(ThemePreferenceControl),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: sheet, matching: find.byType(AccentPicker)),
        findsOneWidget,
      );
      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();
    }
    await tester.disposeApp();
  });

  testWidgets('about rows hidden without links', (tester) async {
    await openSettings(tester);
    expect(row(SettingsCopy.rate), findsOneWidget);
    expect(row(SettingsCopy.feedback), findsNothing);
    expect(row(SettingsCopy.privacy), findsNothing);
    expect(row(SettingsCopy.terms), findsNothing);
    await tester.disposeApp();
  });

  testWidgets('about links open in the app', (tester) async {
    await openSettings(
      tester,
      overrides: [aboutLinksProvider.overrideWithValue(links)],
    );
    await tester.scrollAndTap(row(SettingsCopy.privacy));
    await tester.scrollAndTap(row(SettingsCopy.terms));
    await tester.runAsync(pumpEventQueue);
    expect(about().opened, [links.privacyPolicy, links.terms]);
    await tester.disposeApp();
  });

  testWidgets('Rate asks for a review', (tester) async {
    await openSettings(tester);
    await tester.scrollAndTap(row(SettingsCopy.rate));
    await tester.runAsync(pumpEventQueue);
    expect(about().reviews, 1);
    await tester.disposeApp();
  });

  testWidgets('feedback opens Mail to the address', (tester) async {
    await openSettings(
      tester,
      overrides: [aboutLinksProvider.overrideWithValue(links)],
    );
    await tester.scrollAndTap(row(SettingsCopy.feedback));
    await tester.runAsync(pumpEventQueue);
    await tester.pump();

    expect(about().mails.single.path, 'hello@example.com');
    expect(about().mails.single.query, contains('Exhale%200.1.0'));
    expect(find.text(SettingsCopy.addressCopied), findsNothing);
    await tester.disposeApp();
  });

  testWidgets('feedback without Mail copies the address', (tester) async {
    await openSettings(
      tester,
      overrides: [aboutLinksProvider.overrideWithValue(links)],
    );
    about().composeMailResult = false;
    await tester.scrollAndTap(row(SettingsCopy.feedback));
    await tester.runAsync(pumpEventQueue);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text(SettingsCopy.addressCopied), findsOneWidget);
    await tester.disposeApp();
  });

  testWidgets('footer shows the version', (tester) async {
    await openSettings(tester);
    expect(find.text('Exhale 0.1.0'), findsOneWidget);
    await tester.disposeApp();
  });

  testWidgets('tiles stack at 200% on a small phone', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await seedHabit(
      PlanDraft(startDay: today, startLimit: 8, quitDay: today.addDays(56)),
    );
    await tester.pumpAppPastSplash(width: 320, height: 2400);
    // Home overflows at this size on its own; only Settings is checked here.
    tester.takeException();
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();

    final tiles = find.byType(SettingsTile);
    expect(tester.getTopLeft(tiles.first).dx, tester.getTopLeft(tiles.last).dx);
    expect(
      tester.getTopLeft(tiles.last).dy,
      greaterThan(tester.getBottomLeft(tiles.first).dy - 1),
    );
    final error = tester.takeException();
    await tester.disposeApp();
    expect(error, isNull);
  });

  testWidgets('reduce transparency renders', (tester) async {
    await openSettings(
      tester,
      overrides: [
        reduceTransparencyProvider.overrideWith((ref) => Stream.value(true)),
      ],
    );
    final page = find.byType(SettingsPage);
    expect(
      find.descendant(of: page, matching: find.byType(BackdropFilter)),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
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
